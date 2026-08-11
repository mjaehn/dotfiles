# ~/.bashrc -- symlinked from this repo by install.sh
#
# Shared logic lives in lib/; this file holds only what is bash-specific:
# the prompt and the hand-off to zsh.

# Skip everything for SCP, SFTP and VS Code Remote SSH
if [[ -z "$SSH_TTY" ]] && [[ "$-" != *i* ]]; then
    return
fi

# Resolve the repo through the ~/.bashrc symlink so lib/ can be sourced
DOTFILES_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd)"
export DOTFILES_DIR

# --- shared configuration ------------------------------------------------

source "$DOTFILES_DIR/lib/hostinfo.sh"
[[ "$DOTFILES_ABORT_RC" == 1 ]] && return

source "$DOTFILES_DIR/lib/common.sh"
source "$DOTFILES_DIR/lib/conda.sh"

[[ -s "$HOME/.alias" ]] && source "$HOME/.alias"

# --- prompt --------------------------------------------------------------

git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}
git_commit() {
    git rev-parse --short HEAD 2>/dev/null
}
git_repo() {
    basename -s .git "$(git config --get remote.origin.url)" 2>/dev/null | sed -e 's/^/\n/'
}

PROMPT_TIME='\[\033[38;5;208m\]\t '
PROMPT_USER_HOST='\[\033[38;5;39m\]\u \[\033[38;5;244m\]@ \h\[\033[00m\]'
PROMPT_LOCATION=' \[\033[38;5;76m\]`pwd | sed "s#\(/[^/]\{1,\}/[^/]\{1,\}/[^/]\{1,\}/\).*\(/[^/]\{1,\}/[^/]\{1,\}\)/\{0,1\}#\1_\2#g"`\[\033[00m\]'
PROMPT_REPO='\[\033[38;5;220m\]$(git_repo)\[\033[00m\]'
PROMPT_BRANCH='\[\033[38;5;45m\]$(git_branch)\[\033[00m\]'
PROMPT_COMMIT='\[\033[38;5;213m\]$(git_commit)\[\033[00m\]'
PROMPT_END='\[\033[38;5;240m\] \n\342\224\224\342\224\200 \[\033[00m\]'

PS1="${PROMPT_TIME}${PROMPT_USER_HOST}${PROMPT_LOCATION}${PROMPT_REPO}${PROMPT_BRANCH} ${PROMPT_COMMIT}${PROMPT_END}"

# --- FancyGit ------------------------------------------------------------
#
# Website: https://github.com/diogocavilha/fancy-git
# Install: curl -sS https://raw.githubusercontent.com/diogocavilha/fancy-git/master/install.sh | sh -s -- --nofontconfig
# Icons:   https://www.nerdfonts.com/cheat-sheet --> search 'nf-fa-'

export FANCYGIT_ICON_GIT_REPO=""              # path is a git repository
export FANCYGIT_ICON_LOCAL_BRANCH=""          # local-only branch
export FANCYGIT_ICON_LOCAL_REMOTE_BRANCH=""   # tracked branch
export FANCYGIT_ICON_MERGED_BRANCH=""         # merged branch
export FANCYGIT_ICON_HAS_STASHES=" "         # stashes
export FANCYGIT_ICON_HAS_UNTRACKED_FILES=" " # untracked files
export FANCYGIT_ICON_HAS_CHANGED_FILES=" "   # changed files
export FANCYGIT_ICON_HAS_ADDED_FILES=" "     # added files
export FANCYGIT_ICON_HAS_UNPUSHED_COMMITS=" "# unpushed commits
export FANCYGIT_ICON_VENV=" "                # python virtual environment

if [[ "$-" == *i* && -f "$HOME/.fancy-git/prompt.sh" ]]; then
    source "$HOME/.fancy-git/prompt.sh"
    fancygit --color-scheme-batman 2>/dev/null
    fancygit --disable-full-path 2>/dev/null
    fancygit --enable-host-name 2>/dev/null
    fancygit --enable-show-user-at-machine 2>/dev/null
    fancygit --enable-double-line 2>/dev/null
fi

# --- hand off to zsh -----------------------------------------------------

# balfrin has no system zsh, use the locally built one (install_zsh_user.sh)
if [[ "$DOTFILES_HOST" == "balfrin" && -x "$HOME/local/zsh-5.9/bin/zsh" ]]; then
    export PATH="$HOME/local/zsh-5.9/bin:$PATH"
    export SHELL="$HOME/local/zsh-5.9/bin/zsh"
    exec "$HOME/local/zsh-5.9/bin/zsh" -l
fi

if [[ "$DOTFILES_USE_ZSH" == 1 && "$-" == *i* && -z "$SLURM_JOB_ID" && -z "$ZSH_VERSION" ]]; then
    command -v zsh >/dev/null 2>&1 && exec zsh
fi
