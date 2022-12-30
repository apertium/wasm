#!/bin/bash
# docker run -it --rm --name wasm --hostname wasm -e LANG=C.UTF-8 -e LC_ALL=C.UTF-8 -e DEBIAN_FRONTEND=noninteractive -e DEBCONF_NONINTERACTIVE_SEEN=true -v /opt:/opt amd64/ubuntu:jammy /bin/bash
# apt-get -qy update
# apt-get -qfy install --no-install-recommends apt-utils
# apt-get -qfy install --no-install-recommends build-essential libboost-dev cmake git python3 wget ca-certificates autoconf libtool pkg-config gawk flex bison automake make libutfcpp-dev libxml2-utils xsltproc

set -eo pipefail
CURDIR=$(cd $(dirname $0);pwd)

cd "$CURDIR"
rm -rf installed
mkdir -pv installed/include
ln -vs /usr/include/boost "$CURDIR/installed/include/boost"
ln -vs /usr/include/utf8 "$CURDIR/installed/include/utf8"
ln -vs /usr/include/utf8.h "$CURDIR/installed/include/utf8.h"
ln -vs /usr/include/utf8cpp "$CURDIR/installed/include/utf8cpp"

git clone --depth 1 https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest

cd "$CURDIR"
wget https://github.com/unicode-org/icu/releases/download/release-72-1/icu4c-72_1-src.tgz -O icu.tar.gz
tar -zxvf icu.tar.gz
cd icu/source/
./configure --disable-shared --enable-static
time make -j8 2>&1 | tee build-native.log

source "$CURDIR/emsdk/emsdk_env.sh"
export CC=emcc CXX=em++
export "PKG_CONFIG_LIBDIR=$CURDIR/installed/lib/pkgconfig"
export "PKG_CONFIG_PATH=$CURDIR/installed/lib/pkgconfig"
export "EM_PKG_CONFIG_LIBDIR=$CURDIR/installed/lib/pkgconfig"
export "EM_PKG_CONFIG_PATH=$CURDIR/installed/lib/pkgconfig"
emconfigure ./configure "--prefix=$CURDIR/installed" --with-cross-build=`pwd` --enable-static=yes --enable-shared=no --target=wasm32-unknown-emscripten --with-data-packaging=static --enable-icu-config --enable-extras=no --enable-tools=no --enable-samples=no --enable-tests=no
make clean
time emmake make -j8 2>&1 | tee build-wasm.log
make install

cd "$CURDIR"
git clone --depth 1 https://github.com/GrammarSoft/cg3
mkdir cg3/build
cd cg3/build
emcmake cmake "-DCMAKE_FIND_ROOT_PATH=$CURDIR/installed" "-DCMAKE_INSTALL_PREFIX=$CURDIR/installed" -DBoost_NO_BOOST_CMAKE=ON "-DBoost_INCLUDE_DIR=$CURDIR/installed/include" ..
time emmake make -j8 V=1 VERBOSE=1 2>&1 | tee build.log
make install
cp -av src/*.js src/*.wasm* "$CURDIR/installed/bin/"

cd "$CURDIR"
wget https://download.gnome.org/sources/libxml2/2.10/libxml2-2.10.3.tar.xz -O libxml2.tar.xz
tar -Jxvf libxml2.tar.gz
cd libxml2-*/
emconfigure ./configure --enable-static --disable-shared --without-python "--prefix=$CURDIR/installed"
time emmake make -j8 2>&1 | tee build.log
make install

cd "$CURDIR"
wget https://zlib.net/zlib-1.2.13.tar.xz -O zlib.tar.xz
tar -Jxvf zlib.tar.xz
cd zlib-*/
emconfigure ./configure --static "--prefix=$CURDIR/installed"
time emmake make -j8 2>&1 | tee build.log
make install

export ICU_CFLAGS=$(pkg-config --cflags icu-i18n icu-io icu-uc)
export ICU_LIBS=$(pkg-config --libs icu-i18n icu-io icu-uc)
export LIBXML_CFLAGS=$(pkg-config --cflags libxml-2.0)
export LIBXML_LIBS=$(pkg-config --libs libxml-2.0)
export "CPPFLAGS=-I$CURDIR/installed/include"

cd "$CURDIR"
git clone --depth 1 https://github.com/apertium/lttoolbox
cd lttoolbox
emconfigure autoreconf -fvi
emconfigure ./configure --enable-static --disable-shared "--prefix=$CURDIR/installed"
time emmake make -j8 2>&1 | tee build.log
make install

cd "$CURDIR"
git clone --depth 1 https://github.com/apertium/apertium
cd apertium
emconfigure autoreconf -fvi
emconfigure ./configure --enable-static --disable-shared "--prefix=$CURDIR/installed"
time emmake make -j8 2>&1 | tee build.log
make install

cd "$CURDIR"
git clone --depth 1 https://github.com/hfst/hfst
cd hfst
emconfigure autoreconf -fvi
emconfigure ./configure --enable-all-tools --with-unicode-handler=icu --enable-static --disable-shared "--prefix=$CURDIR/installed"
time emmake make -j8 2>&1 | tee build.log
make install
