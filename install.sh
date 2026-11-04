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
link nvim "$HOME/.config/nvim"
link tmux.conf "$HOME/.tmux.conf"
link tmux-theme.conf "$HOME/.tmux/theme.conf"
link gitconfig "$HOME/.gitconfig"
link condarc "$HOME/.condarc"
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

echo "Setting up tmux plugin manager..."
tpm_dir="$HOME/.tmux/plugins/tpm"
if [[ -d "$tpm_dir/.git" ]]; then
    git -C "$tpm_dir" pull --quiet --ff-only || echo "  tpm: update skipped"
    echo "  ~/.tmux/plugins/tpm"
else
    git clone --quiet https://github.com/tmux-plugins/tpm "$tpm_dir"
    echo "  ~/.tmux/plugins/tpm (cloned)"
fi

# Catppuccin is installed outside TPM: it must load before the status line is
# set, and TPM's clean_plugins would delete it from ~/.tmux/plugins.
catppuccin_version="v2.3.2"
catppuccin_dir="$HOME/.tmux/catppuccin"
if [[ "$(git -C "$catppuccin_dir" describe --tags 2>/dev/null)" != "$catppuccin_version" ]]; then
    rm -rf -- "$catppuccin_dir"
    git -c advice.detachedHead=false clone --quiet --depth 1 -b "$catppuccin_version" \
        https://github.com/catppuccin/tmux "$catppuccin_dir"
fi
echo "  ~/.tmux/catppuccin ($catppuccin_version)"

# Without these the status bar's weather, CPU and RAM modules render empty.
if command -v tmux >/dev/null 2>&1; then
    "$tpm_dir/bin/install_plugins" | sed 's/^/  /' \
        || echo "  tmux plugins: install failed, run <prefix> + I inside tmux"
else
    echo "  skip tmux plugins: tmux not found, re-run this script once it is installed"
fi

# Windows Terminal sends Shift+Enter as a plain Enter; merge in a binding that sends Alt+Enter.
if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "Setting up Windows Terminal..."
    for wt in /mnt/c/Users/*/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json; do
        [[ -f "$wt" ]] || continue
        python3 - "$REPO/windows-terminal.json" "$wt" <<'PY' || echo "  skip ${wt}: not plain JSON, merge windows-terminal.json by hand"
import json, sys
src, dest = (json.load(open(p, encoding="utf-8")) for p in sys.argv[1:])
for key, items in src.items():
    ids = {i["id"] for i in items}
    dest[key] = [i for i in dest.get(key, []) if i.get("id") not in ids] + items
json.dump(dest, open(sys.argv[2], "w", encoding="utf-8"), indent=4, ensure_ascii=False)
print("  " + sys.argv[2])
PY
    done
fi

# lib/ is not linked: bashrc and zshrc resolve their own symlink to find it.

cat <<'EOF'

Done. To finish:

  exec zsh          reload the shell
  :PluginInstall    install the vim plugins (from inside vim)
  nvim              first start installs the Neovim plugins by itself

keybindings.json is for VS Code and is not linked automatically. Copy it to
your VS Code user directory by hand (on WSL that lives on the Windows side).
EOF
