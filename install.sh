#!/usr/bin/env bash
#
# Symlink the dotfiles in this repo into $HOME. Safe to re-run.

set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local src="$REPO/$1" dest="$2"
    if [[ ! -e "$src" ]]; then
        echo "  skip $1 (missing in repo)"
        return
    fi
    mkdir -p "$(dirname -- "$dest")"
    ln -sfn -- "$src" "$dest"
    echo "  ${dest/#$HOME/\~} -> $1"
}

echo "Setting up vim extensions..."
git -C "$REPO" submodule update --init --recursive >/dev/null

mkdir -p "$HOME/.vim/vim-extensions"
for path in "$REPO"/vim-extensions/*/; do
    name="$(basename -- "$path")"
    [[ "$name" == "colors" ]] && continue
    ln -sfn -- "${path%/}" "$HOME/.vim/vim-extensions/$name"
    echo "  ~/.vim/vim-extensions/$name"
done
ln -sfn -- "$REPO/vim-extensions/colors" "$HOME/.vim/colors"
echo "  ~/.vim/colors"

echo "Linking dotfiles..."
link profile "$HOME/.profile"
link bashrc "$HOME/.bashrc"
link zshrc "$HOME/.zshrc"
link p10k.zsh "$HOME/.p10k.zsh"
link vimrc "$HOME/.vimrc"
link gitconfig "$HOME/.gitconfig"
link config "$HOME/.ssh/config"

if [[ ! -e "$HOME/.gitconfig.local" ]]; then
    if [[ -t 0 ]]; then
        echo "  ~/.gitconfig.local not found; it holds your git identity and is not tracked"
        read -r -p "  git user.name: " git_name
        read -r -p "  git user.email: " git_email
        cat >"$HOME/.gitconfig.local" <<EOF
[user]
    name = $git_name
    email = $git_email
EOF
        echo "  wrote ~/.gitconfig.local"
    else
        echo "  note: ~/.gitconfig.local not found; git has no user.email/user.name here"
        echo "        write it by hand, gitconfig includes it and is not tracked"
    fi
fi

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    link aliases.zsh "$HOME/.oh-my-zsh/custom/aliases.zsh"
else
    echo "  skip aliases.zsh: ~/.oh-my-zsh not found"
    echo "       run ./install_oh_my_zsh_plugins_theme.sh first, then re-run this script"
fi

# lib/ is not linked: bashrc and zshrc resolve their own symlink to find it.

cat <<'EOF'

Done. To finish:

  exec zsh          reload the shell
  :PluginInstall    install the vim plugins (from inside vim)

keybindings.json is for VS Code and is not linked automatically. Copy it to
your VS Code user directory by hand (on WSL that lives on the Windows side).
EOF
