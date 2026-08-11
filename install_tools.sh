#!/bin/bash

set -e

echo "Updating system..."
sudo apt update && sudo apt upgrade -y

echo "Installing basic dependencies..."
sudo apt install -y build-essential curl wget gnupg software-properties-common lsb-release ca-certificates

echo "Installing uv (Rust Python package manager)..."
curl -LsSf https://astral.sh/uv/install.sh | sh

echo "Installing wslview (from wslu)..."
sudo apt install -y wslu

echo "Installing netCDF tools (ncdump, ncview)..."
sudo apt install -y netcdf-bin ncview

echo "Installing CDO (Climate Data Operators)..."
sudo apt install -y cdo

echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

echo "Installing latest Git..."
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt update
sudo apt install -y git

echo "Installing Git LFS..."
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
sudo apt install -y git-lfs
git lfs install

echo "Installing ImageMagick (for convert)..."
sudo apt install -y imagemagick

echo "Installing Zsh..."
sudo apt install -y zsh
echo "Setting Zsh as default shell for current user..."
chsh -s $(which zsh)

echo "Downloading and installing Miniforge..."
MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
wget $MINIFORGE_URL -O Miniforge3.sh
bash Miniforge3.sh -b -p $HOME/miniforge
eval "$($HOME/miniforge/bin/conda shell.bash hook)"

echo "Initializing conda for bash..."
conda init bash

echo "Updating base conda environment to latest Python..."
conda activate base
conda install -y python

echo "Creating Python 3.7 environment..."
conda create -y -n py37 python=3.7

echo "All done!"
echo "To activate the new conda environment, run: conda activate py37"

