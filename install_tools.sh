#!/usr/bin/env bash
#
# Provision a fresh Debian/Ubuntu machine (including WSL) with the tools these
# dotfiles expect. Safe to re-run: every step is guarded.
#
# Run install.sh afterwards to symlink the configuration itself.

set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }

echo "Updating system..."
sudo apt update && sudo apt upgrade -y

echo "Installing base packages..."
sudo apt install -y \
    build-essential ca-certificates cdo curl gnupg imagemagick lsb-release \
    ncview netcdf-bin software-properties-common wget zsh

# wslu provides wslview, only meaningful under WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "Installing wslu (WSL detected)..."
    sudo apt install -y wslu
fi

if ! have uv; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

if ! have node; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
fi

echo "Installing latest Git..."
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt update
sudo apt install -y git

if ! have git-lfs; then
    echo "Installing Git LFS..."
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
    sudo apt install -y git-lfs
    git lfs install
fi

if [[ "$SHELL" != *zsh ]]; then
    echo "Setting zsh as the default shell..."
    chsh -s "$(command -v zsh)"
fi

# Match the prefix lib/conda.sh looks for, and the architecture we run on
# (this repo is used on both x86_64 and aarch64 machines).
CONDA_PREFIX_DIR="$HOME/miniforge3"
if [[ ! -d "$CONDA_PREFIX_DIR" ]]; then
    echo "Installing Miniforge for $(uname -m)..."
    installer="Miniforge3-Linux-$(uname -m).sh"
    wget -q "https://github.com/conda-forge/miniforge/releases/latest/download/$installer" \
        -O "/tmp/$installer"
    bash "/tmp/$installer" -b -p "$CONDA_PREFIX_DIR"
    rm -f "/tmp/$installer"
else
    echo "Miniforge already installed at $CONDA_PREFIX_DIR."
fi

eval "$("$CONDA_PREFIX_DIR/bin/conda" shell.bash hook)"
conda init bash zsh

# The shells activate the "default" environment, not base
if ! conda env list | awk '{print $1}' | grep -qx default; then
    echo "Creating the 'default' conda environment..."
    conda create -y -n default python
else
    echo "Conda environment 'default' already exists."
fi

echo
echo "All done. Now run: ./install.sh"
