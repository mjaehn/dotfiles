#!/bin/bash

# Variables
ZSH_VERSION="5.9"  # Specify the Zsh version you want to install
INSTALL_DIR="$HOME/local"  # Directory to install Zsh in
ZSH_INSTALL_DIR="$INSTALL_DIR/zsh-$ZSH_VERSION"
ZSH_BIN="$ZSH_INSTALL_DIR/bin/zsh"
SRC_DIR="$HOME/src"
ZSH_TAR="zsh-$ZSH_VERSION.tar.xz"
ZSH_URL="https://sourceforge.net/projects/zsh/files/zsh/$ZSH_VERSION/$ZSH_TAR"

# Step 1: Create necessary directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$SRC_DIR"

# Step 2: Download Zsh source code
cd "$SRC_DIR"
if [ ! -f "$ZSH_TAR" ]; then
    echo "Downloading Zsh $ZSH_VERSION..."
    wget "$ZSH_URL"
else
    echo "Zsh $ZSH_VERSION source already exists. Skipping download."
fi

# Step 3: Extract Zsh source code
if [ ! -d "zsh-$ZSH_VERSION" ]; then
    echo "Extracting Zsh..."
    tar -xvf "$ZSH_TAR"
else
    echo "Zsh source directory already exists. Skipping extraction."
fi

# Step 4: Compile and install Zsh locally
cd "zsh-$ZSH_VERSION"
./configure --prefix="$ZSH_INSTALL_DIR" --bindir="$ZSH_INSTALL_DIR/bin" --exec-prefix="$ZSH_INSTALL_DIR"
make && make install

# Step 5: Add Zsh to the PATH and set it as the default shell in .bashrc or .profile
if ! grep -q "$ZSH_BIN" "$HOME/.bashrc"; then
    echo "Adding Zsh to PATH and setting it as the default shell in .bashrc..."
    echo "export PATH=\"$ZSH_INSTALL_DIR/bin:\$PATH\"" >> "$HOME/.bashrc"
    echo "export SHELL=\"$ZSH_BIN\"" >> "$HOME/.bashrc"
    echo "exec \"$ZSH_BIN\" -l" >> "$HOME/.bashrc"
else
    echo "Zsh is already configured in .bashrc."
fi

# Step 6: Display success message
echo "Zsh $ZSH_VERSION has been installed locally at $ZSH_INSTALL_DIR."
echo "Please restart your terminal session or source your .bashrc file to start using Zsh."

