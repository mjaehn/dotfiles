#!/bin/bash

echo Setup vim-extensions***

vim_plugin_dir=~/.vim/vim-extensions

mkdir -p $vim_plugin_dir

git submodule init &> /dev/null
git submodule update &> /dev/null

cd vim-extensions

for name in *; do
  if [ -d "$name" ] && [ ! -L "$name" ]; then
    echo "   Link $name to $vim_plugin_dir"
    ln -s -f $(pwd)/$name $vim_plugin_dir
  fi
done

echo "   Link colors to ~/.vim/colors"
ln -s -f $(pwd)/colors ~/.vim/.

cd ..

echo "Link profile"
ln -s -f $(pwd)/profile ~/.profile

echo "Link bashrc"
ln -s -f $(pwd)/bashrc ~/.bashrc

echo "Link zshrc"
ln -s -f $(pwd)/zshrc ~/.zshrc

echo "Link p10k.zsh"
ln -s -f $(pwd)/p10k.zsh ~/.p10k.zsh

echo "Link aliases.zsh"
ln -fs $(pwd)/aliases.zsh $HOME/.oh-my-zsh/custom

echo "Link vimrc"
ln -s -f $(pwd)/vimrc ~/.vimrc

echo "Link ssh-config"
ln -s -f $(pwd)/config ~/.ssh/config

echo ""
echo "Run:"
echo ""
echo "source ~/.zshrc"
echo ""
echo ":PluginInstall in Vim"
echo ""
echo "to complete installation"
echo ""
