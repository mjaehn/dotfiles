# Skip certain configurations for SCP, SFTP, and VS Code Remote SSH
if [[ "$SSH_TTY" == "" ]] && [[ "$-" != *i* ]]; then
    return
fi

test -s ~/.alias && . ~/.alias || true

USE_ZSH=1
# determine hostname for later use in all dotfiles
if [[ "${HOSTNAME}" == balfrin* ]]; then 
    BASHRC_HOST='balfrin'
elif [[ "${HOSTNAME}" == todi* ]]; then 
    BASHRC_HOST='todi'
elif [[ "${HOSTNAME}" == santis* ]]; then 
    BASHRC_HOST='santis'
elif [[ "${HOSTNAME}" == eu* ]]; then 
    BASHRC_HOST='euler'
    module load stack eth_proxy
elif [[ "${HOSTNAME}" == levante* ]]; then 
    source /sw/etc/profile.levante
    if tty -s; then
        BASHRC_HOST='levante'
        module load git
    # load java and git as Jenkins user
    else
        return
    fi
elif [[ "${HOSTNAME}" == IACPC* ]]; then 
    BASHRC_HOST='iac-laptop'
elif [[ "${HOSTNAME}" == DESKTOP* || "${HOST}" == SurfacePro* ]]; then
    BASHRC_HOST='home-pc'
elif [[ "${HOSTNAME}" == co2 ]]; then 
    BASHRC_HOST='co2'
    USE_ZSH=0
elif [[ "${HOSTNAME}" == atmos ]]; then 
    BASHRC_HOST='atmos'
fi
export BASHRC_HOST

# ls colors
unset LS_COLORS
export LS_COLORS='di=1;94:fi=0:ln=100;93:pi=5:so=5:bd=5:cd=5:or=101:mi=0:ex=1;31'


# Git settings
export GIT_EDITOR="vim"

# Custom modules/paths/envs for each machine

#parse_git_branch() {
#git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
#}

git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1/'
}
git_commit() {
     git rev-parse --short HEAD 2> /dev/null
}
git_repo() {
     basename -s .git `git config --get remote.origin.url` 2> /dev/null | sed -e 's/^/\n/'
}

# Command prompt
TIME='\[\033[01;31m\]\t \[\033[01;32m\]'
USER_HOST='\[\033[01;33m\]\u @ \h\[\033[00m\]'
LOCATION=' \[\033[00;96m\]`pwd | sed "s#\(/[^/]\{1,\}/[^/]\{1,\}/[^/]\{1,\}/\).*\(/[^/]\{1,\}/[^/]\{1,\}\)/\{0,1\}#\1_\2#g"`'
REPO='\[\033[00;33m\]$(git_repo)\[\033[00m\]'
BRANCH='\[\033[01;36m\]$(git_branch) \[\033[00m\]'
COMMIT='\[\033[01;34m\]$(git_commit)\[\033[00m\]'
END=' \n\342\224\224\342\224\200 '

# Combine all components for the prompt
PS1=$TIME$USER_HOST$LOCATION$REPO$BRANCH$COMMIT$END$TREEBRANCH

# FancyGit settings
# Website: https://github.com/diogocavilha/fancy-git
# Install: curl -sS https://raw.githubusercontent.com/diogocavilha/fancy-git/master/install.sh | sh -s -- --nofontconfig
# Icons:   https://www.nerdfonts.com/cheat-sheet --> search 'nf-fa-'

# Path is a git repository
export FANCYGIT_ICON_GIT_REPO=""

# Only local branch icon.
export FANCYGIT_ICON_LOCAL_BRANCH=""

# Branch icon.
export FANCYGIT_ICON_LOCAL_REMOTE_BRANCH=""

# Merged branch icon.
export FANCYGIT_ICON_MERGED_BRANCH=""

# Staged files.
export FANCYGIT_ICON_HAS_STASHES=" "

# Untracked files.
export FANCYGIT_ICON_HAS_UNTRACKED_FILES=" "

# Changed files.
export FANCYGIT_ICON_HAS_CHANGED_FILES=" "

# Added files.
export FANCYGIT_ICON_HAS_ADDED_FILES=" "

# Unpushed commits.
export FANCYGIT_ICON_HAS_UNPUSHED_COMMITS=" "

# Path is a python virtual environment
export FANCYGIT_ICON_VENV=" "

# Check for interactive shell
if [[ $- == *i* ]]; then
    # Source the prompt
    . ~/.fancy-git/prompt.sh 2>/dev/null
    # Settings
    fancygit --color-scheme-batman 2>/dev/null
    fancygit --disable-full-path 2>/dev/null
    fancygit --enable-host-name 2>/dev/null
    fancygit --enable-show-user-at-machine 2>/dev/null
    fancygit --enable-double-line 2>/dev/null
fi

# Custom modules/paths/envs for each machine

# alps
if [[ "${BASHRC_HOST}" == "todi" || "${BASHRC_HOST}" == "santis" || "${BASHRC_HOST}" == "balfrin" ]]; then
    # >>> conda initialize >>>
    __conda_setup="$('/users/mjaehn/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/users/mjaehn/miniconda3/etc/profile.d/conda.sh" ]; then
            :  # no-op placeholder, old line intentionally ignored
        else
            export PATH="/users/mjaehn/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<
elif [[ "${BASHRC_HOST}" == "iac-laptop" || "${BASHRC_HOST}" == "home-pc" || "${BASHRC_HOST}" == "co2" ]]; then
    # Only enable Conda in interactive shells (avoid breaking SCP)
    if [[ "$-" == *i* ]]; then
        if [ -d "/home/mjaehn/miniconda3" ]; then
            __conda_setup="$('/home/mjaehn/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
            if [ $? -eq 0 ]; then
                eval "$__conda_setup"
            elif [ -f "/home/mjaehn/miniconda3/etc/profile.d/conda.sh" ]; then
                :
            else
                export PATH="/home/mjaehn/miniconda3/bin:$PATH"
            fi
        elif [ -d "/home/mjaehn/miniforge3" ]; then
            __conda_setup="$('/home/mjaehn/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
            if [ $? -eq 0 ]; then
                eval "$__conda_setup"
            elif [ -f "/home/mjaehn/miniforge3/etc/profile.d/conda.sh" ]; then
                :
            else
                : # export PATH="/home/mjaehn/miniforge3/bin:$PATH"  # commented out by conda initialize
            fi
        fi
        unset __conda_setup
        # Use default environment instead of base
        conda activate default
    fi
elif [[ "${BASHRC_HOST}" == "atmos" ]]; then
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$('/usr/local/Miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/usr/local/Miniconda3/etc/profile.d/conda.sh" ]; then
            : # . "/usr/local/Miniconda3/etc/profile.d/conda.sh"  # commented out by conda initialize
        else
            export PATH="/usr/local/Miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<
fi

# balfrin
if [[ "${BASHRC_HOST}" == "balfrin" ]]; then
    export MODULEPATH=/mch-environment/v6/modules:${MODULEPATH}
fi


# Machine specific aliases
#
# Squeue format
squeue_format="%.7i %.24j %.8u %.2t %.10M %.6D %R"

# alps
if [[ "${BASHRC_HOST}" == "balfrin" || "${BASHRC_HOST}" == "todi" || "${BASHRC_HOST}" == "santis" ]]; then
    alias aall="scancel -u mjaehn"
    alias sq="squeue -u mjaehn -o \"${squeue_format}\""
    alias sqw="watch -x -n 60 squeue -u mjaehn -o \"${squeue_format}\""

# co2
elif [[ "${BASHRC_HOST}" == "co2" ]]; then
    alias json='cd /net/co2/c2sm-data/jenkins/zephyr/file_index'

# euler
elif [[ "${BASHRC_HOST}" == "euler" ]]; then
    alias aall="scancel -u mjaehn"
    alias sq="squeue -u mjaehn -o \"${squeue_format}\""
    alias sqw="watch -x -n 60 squeue -u mjaehn -o \"${squeue_format}\""

# levante
elif [[ "${BASHRC_HOST}" == "levante" ]]; then
    alias aall="scancel -u b381473"
    alias sq="squeue -u b381473 -o \"${squeue_format}\""
    alias sqw="watch -x -n 60 squeue -u b381473 -o \"${squeue_format}\""
    alias jenkins='cd /mnt/lustre01/scratch/b/b380729/workspace'
    alias st='cd /pool/data/CLMcom/'
    export SCRATCH=/scratch/b/b381473

elif [[ "${BASHRC_HOST}" == "iac-laptop" || "${BASHRC_HOST}" == "co2" || "${BASHRC_HOST}" == "home-pc" ]]; then
    # fnm
    if [ -d "/home/mjaehn/.local/share/fnm" ]; then
        export PATH="/home/mjaehn/.local/share/fnm:$PATH"
        eval "$(fnm env)"
    fi
fi

# Additional aliases for Alps
if [[ "${BASHRC_HOST}" == "todi" || "${BASHRC_HOST}" == "santis" ]]; then
    alias uenv_tools="uenv start --view=modules netcdf-tools/2024:v1-rc1"
    alias uenv_icon="uenv start --view=spack icon-wcp/v1:rc4"
    alias nn="module load netcdf-c/4.9.2 ncview/2.1.9 && echo Loading ncdump and ncview."
    alias st="cd /store/migration/store/c2sm/c2sme/"
fi
if [[ "${BASHRC_HOST}" == "balfrin" ]]; then
    alias nn="module load netcdf-c/4.8.1-gcc && echo Loading ncdump."
fi


# Model specific aliases

# ICON
alias lsL='ls -ltr LOG*' 
alias tL='tail -f LOG*'

# General aliases
alias ls="ls --color"
alias ll="ls -al"
alias la='ls -A'
alias l="ls -al"
alias scra='cd ${SCRATCH}'
alias c="clear"
alias g='grep -i'
alias h='history | grep'
alias t='tail -f'
alias dc="cd"
alias ..='cd ..'
alias l..='cd ..'
alias cd..="cd .."
alias ml='module load'
alias src='source'
alias ...='cd ../..'
alias lsC='ctags -R'
alias srcrc='source ~/.bashrc'
alias rcvim='vim ~/.bashrc'
alias gt='git status'
alias ga='git add'
alias gsi='git submodule init'
alias gsu='git submodule update'
alias gsui='git submodule update --init'
alias gsuir='git submodule update --init --recursive'
#alias gl='git log --pretty=format:"%h - %an, %ar : %s"'
alias gl='git log --graph --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%an%C(reset)%C(bold yellow)%d%C(reset) %C(dim white)- %s%C(reset)"'
alias nd='ncdump -h'
alias nv='ncview'
alias fp='find "$PWD" -name'
alias lcd="cd"
alias lvi="vi"
alias vi="vim -p"
alias nd="ncdump -h"
alias nv="ncview"
alias ftps="cd /net/iacftp/ftp/pub_read/mjaehn"
alias f="find . -name"
alias ml="module load"
alias callGraph="perl /home/mjaehn/git/callGraph/callGraph"
alias cscskey="cd ~/git/cscs-keys && ./generate-keys.sh"

# Use local zsh installation on balfrin
if [[ "${BASHRC_HOST}" == "balfrin" ]]; then
    export PATH="${HOME}/local/zsh-5.9/bin:$PATH"
    export SHELL="${HOME}/local/zsh-5.9/bin/zsh"
    exec "${HOME}/local/zsh-5.9/bin/zsh" -l
fi

if [[ "$USE_ZSH" == "1" && $- == *i* && -z "$SLURM_JOB_ID" && -z "$ZSH_VERSION" ]]; then
    exec zsh
fi

. "$HOME/.local/bin/env"
