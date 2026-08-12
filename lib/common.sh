# shellcheck shell=bash
#
# Environment, aliases and functions shared by bashrc and zshrc.
#
# Portable across bash and zsh. Otherwise POSIX, with one exception: the
# cscs-key function name contains a hyphen, which bash and zsh accept but
# strict POSIX shells (dash) reject. It must keep that name to shadow the
# cscs-key binary, so this file is not dash-clean. lib/hostinfo.sh and
# lib/conda.sh are.

# --- environment ---------------------------------------------------------

export GIT_EDITOR='vim'

export LS_COLORS='di=1;94:fi=0:ln=100;93:pi=5:so=5:bd=5:cd=5:or=101:mi=0:ex=1;31'

squeue_format='%.7i %.22j %.6u %.6a %.2t %.10M %.9l %.5D %24R'

# --- navigation ----------------------------------------------------------

alias ..='cd ..'
alias ...='cd ../..'
alias cd..='cd ..'   # catches the common typo
alias c='clear'
alias scra='cd "${SCRATCH}"'

# --- listing and search --------------------------------------------------

alias f='find . -name'
alias fp='find "$PWD" -name'
alias g='grep -i'
alias h='history | grep'
alias l='ls -al'
alias la='ls -A'
alias ll='ls -al'
alias ls='ls --color'
alias t='tail -f'

# --- editing -------------------------------------------------------------

alias aliases='vi "$HOME/.oh-my-zsh/custom/aliases.zsh"'
alias bashconfig='vi ~/.bashrc'
alias src='source'
alias vi='vim -p'
alias zshconfig='vi ~/.zshrc'

# Reload the rc file of whichever shell is running
if [ -n "${ZSH_VERSION:-}" ]; then
    alias srcrc='source ~/.zshrc'
else
    alias srcrc='source ~/.bashrc'
fi

# --- git -----------------------------------------------------------------
#
# Names and meanings deliberately match the oh-my-zsh git plugin, so bash and
# zsh behave identically. In zsh the plugin defines these too (with the same
# values) plus ~180 more; this block is what makes them available in bash.

alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gcam='git commit --all --message'
alias gcb='git checkout -b'
alias gcmsg='git commit --message'
alias gco='git checkout'
alias gd='git diff'
alias gdca='git diff --cached'
alias gf='git fetch'
alias gl='git pull'
alias glgga='git log --graph --decorate --all'
alias gp='git push'
alias gst='git status'
alias gsw='git switch'

# Not in oh-my-zsh: the pretty graph log formerly bound to `gl` in bashrc
alias gll='git log --graph --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%an%C(reset)%C(bold yellow)%d%C(reset) %C(dim white)- %s%C(reset)"'

# Not in oh-my-zsh: submodule shorthands
alias gsi='git submodule init'
alias gsu='git submodule update'
alias gsui='git submodule update --init'
alias gsuir='git submodule update --init --recursive'

# --- modules and Slurm ---------------------------------------------------

alias ml='module load'
alias aall='scancel -u "$USER"'
alias sq="squeue -u \"\$USER\" -o \"${squeue_format}\""
alias sqw="watch -x -n 60 squeue -u \"\$USER\" -o \"${squeue_format}\""

# --- netCDF and models ---------------------------------------------------

alias nd='ncdump -h'
alias nv='ncview'
alias lsL='ls -ltr LOG*'
alias tL='tail -f LOG*'

# --- misc ----------------------------------------------------------------

alias lsC='ctags -R'
alias account='sacctmgr show assoc user="$USER" format=account%20'

# Renew the CSCS key/certificate, then mirror it into the Windows home so that
# VS Code Remote-SSH (which runs as a Windows process) sees the fresh certificate.
cscs-key() {
    command cscs-key "$@" && "$HOME/git/cscs-keys/sync-windows.sh"
}
alias cscskey='cscs-key'

# --- machine-specific ----------------------------------------------------
#
# `st` is "the data store on this machine" everywhere, so muscle memory carries
# across hosts even though the path does not.

case "$DOTFILES_HOST" in
    santis)
        alias st='cd /capstor/store/cscs/c2sm/c2sme'
        alias clm='cd /capstor/store/cscs/userlab/cwp06/mjaehn/ICON-CLM'
        alias cws='cd /capstor/store/cscs/userlab/cws01'
        alias cwd='cd /capstor/store/cscs/userlab/cwd01'
        alias nn='module load netcdf-c/4.9.2 ncview/2.1.9 && echo "Loading ncdump and ncview."'
        alias uenv_tools='uenv start netcdf-tools/2025:v1 --view=netcdf'
        alias uenv_icon='uenv start icon-wcp/v1:rc4'
        alias climtools='uenv start climtools --view=climtools'
        ;;
    balfrin)
        alias st='cd /capstor/store/cscs/c2sm'
        alias nn='module load netcdf-c/4.8.1-gcc && echo "Loading ncdump."'
        ;;
    euler)
        alias st='cd /cluster/work/climate/icon_testing_input'
        alias scra='cd "/cluster/scratch/$USER"'
        alias modules='module load stack/2025-06 openmpi/4.1.7 cdo/2.4.4 nco/5.2.4 netcdf-c/4.9.2 python/3.13.0 ncview/2.1.9'
        ;;
    levante)
        alias st='cd /pool/data/CLMcom/CCLM/reanalyses/ERA5'
        alias jenkins='cd /mnt/lustre01/scratch/b/b380729/workspace'
        ;;
    co2)
        alias json='cd /net/co2/c2sm-data/jenkins/zephyr/file_index'
        ;;
esac

if [ "$DOTFILES_CLUSTER" = 'iac' ]; then
    alias ftps='cd /net/iacftp/ftp/pub_read/mjaehn'
fi

if [ "$DOTFILES_CLUSTER" = 'local' ]; then
    alias callGraph='perl "$HOME/git/callGraph/callGraph"'
fi

return 0
