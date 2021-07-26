#!/bin/bash

mkdir -p ~/.vim

echo "Link bashrc"
ln -s -f bashrc ~/.bashrc

echo "Link vimrc"
ln -s -f vimrc ~/.vimrc
