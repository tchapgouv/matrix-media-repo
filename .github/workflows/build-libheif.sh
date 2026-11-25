#!/bin/bash
set -ex
sudo apt-get install -y git cmake make pkg-config libx265-dev libde265-dev libjpeg-dev libtool
libheif_version=$(go list -m -f '{{.Version}}' github.com/strukturag/libheif)
git clone --depth 1 --branch "$libheif_version" https://github.com/strukturag/libheif.git
cd libheif
mkdir build
cd build
cmake --preset=release ..
make
sudo make install
sudo ldconfig
