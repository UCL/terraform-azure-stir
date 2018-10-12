#!/bin/bash

#sudo apt-get install -y cmake build-essential libinsighttoolkit4-dev \
# libboost-all-dev

NOCORES=`nproc`
echo Using $NOCORES cores
mkdir ~/devel
cd ~/devel
git clone http://github.com/UCL/STIR
mkdir -p ~/devel/STIR-BUILD
cd ~/devel/STIR-BUILD
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=. -DBUILD_SWIG_PYTHON=ON -DSTIR_OPENMP=ON ~/devel/STIR
make -j${NOCORES} && make test && make install
