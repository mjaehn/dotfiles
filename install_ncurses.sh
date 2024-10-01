#!/bin/bash

cd $HOME/src  # or any directory where you store your source files
curl -O https://invisible-mirror.net/archives/ncurses/ncurses-6.3.tar.gz

rm -fr ncurses-6.3
tar -xzf ncurses-6.3.tar.gz
cd ncurses-6.3

PKG_CONFIG_LIBDIR=/users/mjaehn/local/ncurses/lib/pkgconfig ./configure --prefix=/users/mjaehn/local/ncurses --with-shared --with-termlib --enable-pc-files --without-pkg-config CFLAGS=-fPIC

make
make install

