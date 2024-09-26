#!/bin/bash

# Check if Zsh is installed
if ! [ -x "$(command -v zsh)" ]; then
  echo "Error: Zsh is not installed. Please install Zsh first." >&2
  exit 1
fi

# Step 1: Install Oh-My-Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh-My-Zsh is already installed."
fi
cp aliases.zsh $HOME/.oh-my-zsh/custom

# Step 2: Install Zsh Plugins

# Install zsh-completions
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" ]; then
    echo "Installing zsh-completions plugin..."
    git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
else
    echo "zsh-completions plugin is already installed."
fi

# Install zsh-syntax-highlighting
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting plugin..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
else
    echo "zsh-syntax-highlighting plugin is already installed."
fi

# Install zsh-autosuggestions
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
else
    echo "zsh-autosuggestions plugin is already installed."
fi

# Step 3: Install Powerlevel10k Theme
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
else
    echo "Powerlevel10k theme is already installed."
fi

# Step 4: Update .zshrc to enable plugins and theme
ZSHRC="$HOME/.zshrc"

if grep -q "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" "$ZSHRC"; then
    echo "Powerlevel10k theme already set in .zshrc."
else
    echo "Setting Powerlevel10k theme in .zshrc..."
    sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
fi

if grep -q "plugins=(.*zsh-completions.*zsh-syntax-highlighting.*zsh-autosuggestions)" "$ZSHRC"; then
    echo "Plugins already set in .zshrc."
else
    echo "Adding plugins to .zshrc..."
    sed -i 's/plugins=(.*/plugins=(git zsh-completions zsh-syntax-highlighting zsh-autosuggestions)/' "$ZSHRC"
fi


# Step 5: Source .zshrc to apply changes (Remove this block from the script)
# echo "Sourcing .zshrc to apply changes..."
# source "$ZSHRC"

echo "Oh-My-Zsh, plugins, and Powerlevel10k theme installed successfully!"
echo "To apply the changes, run 'exec zsh' or start a new Zsh session."

