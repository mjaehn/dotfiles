# ~/.zshrc -- symlinked from this repo by install.sh
#
# Shared logic lives in lib/; this file holds only what is zsh-specific:
# oh-my-zsh, powerlevel10k and zsh options.

# Enable Powerlevel10k instant prompt. Must stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Resolve the repo through the ~/.zshrc symlink so lib/ can be sourced.
# :A resolves symlinks, :h takes the directory.
DOTFILES_DIR="${${(%):-%x}:A:h}"
export DOTFILES_DIR

# --- host detection ------------------------------------------------------
# Runs before oh-my-zsh because it sets PATH and can abort the rc entirely.

source "$DOTFILES_DIR/lib/hostinfo.sh"
[[ "$DOTFILES_ABORT_RC" == 1 ]] && return

# --- oh-my-zsh -----------------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Add wisely, too many plugins slow down shell startup.
plugins=(git zsh-completions zsh-syntax-highlighting zsh-autosuggestions)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# To customize the prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# --- shared configuration ------------------------------------------------
# Sourced after oh-my-zsh so these definitions win over the plugins'.

source "$DOTFILES_DIR/lib/common.sh"
source "$DOTFILES_DIR/lib/conda.sh"

# --- zsh options ---------------------------------------------------------

# Do not error when a glob matches nothing (same as bash)
setopt nonomatch

export SHELL="$(command -v zsh)"

# --- tooling -------------------------------------------------------------

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# The module systems need their own zsh init: Lmod on santis, Tcl Modules on
# balfrin. Try both, first match wins.
if [[ "$DOTFILES_CLUSTER" == "alps" ]]; then
    if [[ -f /usr/share/lmod/lmod/init/zsh ]]; then
        source /usr/share/lmod/lmod/init/zsh
    elif [[ -f /usr/share/Modules/3.2.10/init/zsh ]]; then
        source /usr/share/Modules/3.2.10/init/zsh
    fi
fi
