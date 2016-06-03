#!/bin/bash
# Copyright 2015, Google Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -ex

# change to grpc repo root
cd $(dirname $0)/../..

PYTHON="$1"
VENV="$2"
VENV_RELATIVE_PYTHON="$3"
TOOLCHAIN="$4"

ROOT=`pwd`
export CFLAGS="-I$ROOT/include -std=gnu99 -fno-wrapv"
export GRPC_PYTHON_BUILD_WITH_CYTHON=1

if [ "$CONFIG" = "gcov" ]
then
  export GRPC_PYTHON_ENABLE_CYTHON_TRACING=1
fi

($PYTHON -m virtualenv $VENV || true)
VENV_PYTHON=$VENV/$VENV_RELATIVE_PYTHON

# pip-installs the directory specified. Used because on MSYS the vanilla Windows
# Python gets confused when parsing paths.
pip_install_dir() {
  PWD=`pwd`
  cd $1
  ($VENV_PYTHON setup.py build_ext -c $TOOLCHAIN || true)
  $VENV_PYTHON -m pip install --upgrade --force-reinstall .
  cd $PWD
}

$VENV_PYTHON -m pip install --upgrade pip setuptools
$VENV_PYTHON -m pip install cython
pip_install_dir $ROOT
$VENV_PYTHON $ROOT/tools/distrib/python/make_grpcio_tools.py
pip_install_dir $ROOT/tools/distrib/python/grpcio_tools
$VENV_PYTHON $ROOT/src/python/grpcio_health_checking/setup.py preprocess
pip_install_dir $ROOT/src/python/grpcio_health_checking
$VENV_PYTHON $ROOT/src/python/grpcio_tests/setup.py preprocess
$VENV_PYTHON $ROOT/src/python/grpcio_tests/setup.py build_proto_modules
