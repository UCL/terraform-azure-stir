#!/bin/bash

#sudo apt-get install -y cmake build-essential libinsighttoolkit4-dev \
# libboost-all-dev

mkdir ~/devel
cd ~/devel
git clone http://github.com/UCL/STIR
mkdir -p ~/devel/STIR-BUILD
cd ~/devel/STIR-BUILD
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=. ~/devel/STIR
make -j2 && make test && make install
