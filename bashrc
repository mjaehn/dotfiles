# There are 3 different types of shells in bash: the login shell, normal shell
# and interactive shell. Login shells read ~/.profile and interactive shells
# read ~/.bashrc; in our setup, /etc/profile sources ~/.bashrc - thus all
# settings made here will also take effect in a login shell.
#

test -s ~/.alias && . ~/.alias || true

# determine hostname for later use in all dotfiles
if [[ "${HOSTNAME}" == daint* ]]; then 
    BASHRC_HOST='daint'
elif [[ "${HOSTNAME}" == dom* ]]; then 
    BASHRC_HOST='dom'
elif [[ "${HOSTNAME}" == eu* ]]; then 
    if tty -s; then
        BASHRC_HOST='euler'
    # do nothing for me as Jenkins user
    else
        return
    fi
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
elif [[ "${HOSTNAME}" == DESKTOP* ]]; then 
    BASHRC_HOST='home-pc'
elif [[ "${HOSTNAME}" == co2 ]]; then 
    BASHRC_HOST='co2'
fi
export BASHRC_HOST

# ls colors
export LS_COLORS='di=1;94:fi=0:ln=100;93:pi=5:so=5:bd=5:cd=5:or=101:mi=0:ex=1;31'

# Git settings
export GIT_EDITOR="vim"

# Custom modules/paths/envs for each machine

# daint
if [[ "${BASHRC_HOST}" == "daint" ]]; then
    test -s /etc/bash_completion.d/git.sh && . /etc/bash_completion.d/git.sh || true
    __conda_setup="$('/project/d121/mjaehn/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/project/d121/mjaehn/miniconda3/etc/profile.d/conda.sh" ]; then
          . "/project/d121/mjaehn/miniconda3/etc/profile.d/conda.sh"
        else
          export PATH="/project/d121/mjaehn/miniconda3/bin:$PATH" 
        fi
    fi
    unset __conda_setup

# Euler
elif [[ "${BASHRC_HOST}" == "euler" ]]; then
    export PATH=/cluster/home/mjaehn/bin:$PATH

# iac-laptop / co2
elif [[ "${BASHRC_HOST}" == "co2" || "${BASHRC_HOST}" == "iac-laptop"  ]]; then
    __conda_setup="$('/home/mjaehn/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/home/mjaehn/miniconda3/etc/profile.d/conda.sh" ]; then
          . "/home/mjaehn/miniconda3/etc/profile.d/conda.sh"
        else
          export PATH="/home/mjaehn/miniconda3/bin:$PATH" 
        fi
    fi
    unset __conda_setup
fi

#parse_git_branch() {
#git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
#}

git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
git_commit() {
     git rev-parse --short HEAD 2> /dev/null | sed -e 's/^/ -> /'
}
git_repo() {
     basename -s .git `git config --get remote.origin.url` 2> /dev/null | sed -e 's/^/\n/'
}

# Command prompt
#short_host="${HOSTNAME:0:2}-${HOSTNAME:${#HOSTNAME}-1:${#HOSTNAME}}"
#export PS1="\u@$short_host:\W\[\033[33m\]\$(parse_git_branch)\[\033[00m\]> "
MYHOST='\[\033[02;36m\]\h'; MYHOST=' '$MYHOST
TIME='\[\033[01;31m\]\t \[\033[01;32m\]'
LOCATION=' \[\033[00;96m\]`pwd | sed "s#\(/[^/]\{1,\}/[^/]\{1,\}/[^/]\{1,\}/\).*\(/[^/]\{1,\}/[^/]\{1,\}\)/\{0,1\}#\1_\2#g"`'
REPO='\[\033[00;33m\]$(git_repo)\[\033[00m\]'
BRANCH='\[\033[00;33m\]$(git_branch)\[\033[00m\]'
COMMIT='\[\033[00;97m\]$(git_commit)\[\033[00m\]'
END=' \n\$ '
PS1=$TIME$USER$MYHOST$LOCATION$REPO$BRANCH$COMMIT$END

# Custom modules/paths/envs for each machine

# daint
if [[ "${BASHRC_HOST}" == "daint" ]]; then
    test -s /etc/bash_completion.d/git.sh && . /etc/bash_completion.d/git.sh || true
    export PATH=$PATH:/users/mjaehn/script_utils
    test -s ~/.profile && . ~/.profile || true
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$('/users/mjaehn/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/users/mjaehn/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/users/mjaehn/miniconda3/etc/profile.d/conda.sh"  # commented out by conda initialize
        else
            export PATH="/users/mjaehn/miniconda3/bin:$PATH"  # commented out by conda initialize
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<

# dom
elif [[ "${BASHRC_HOST}" == "dom" ]]; then
    test -s ~/.profile && . ~/.profile || true

# iac-laptop
elif [[ "${BASHRC_HOST}" == "iac-laptop" ]]; then
    __conda_setup="$('/home/mjaehn/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/home/mjaehn/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/home/mjaehn/miniconda3/etc/profile.d/conda.sh"  # commented out by conda initialize
        else
            export PATH="/home/mjaehn/miniconda3/bin:$PATH"  # commented out by conda initialize
        fi
    fi
    unset __conda_setup
    conda activate base

    # Ruby for local gh pages testing
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
fi

# Machine specific aliases

# daint
if [[ "${BASHRC_HOST}" == "daint" ]]; then
    alias srcspack="source $SPACK_ROOT/share/spack/setup-env.sh"
    alias spak="spack  --config-scope=${HOME}/.spack/$BASHRC_HOST"
    alias aall="scancel -u mjaehn"
    alias sq='squeue -u mjaehn'
    alias squ='squeue'
    alias jenkins='cd /scratch/snx3000/jenkins/workspace'
    alias proj="cd /project/d121/mjaehn"
    alias st="cd /store/c2sm/c2sme"
    alias nn="module load daint-gpu NCO ncview"
    alias o="xdg-open"
    alias venv="source /users/mjaehn/venv-jae/bin/activate"
    alias psy=". activate_psyplot"

# dom
elif [[ "${BASHRC_HOST}" == "dom" ]]; then
    alias srcspack="source $SPACK_ROOT/share/spack/setup-env.sh"
    alias spak="spack  --config-scope=${HOME}/.spack/$BASHRC_HOST"
    alias aall="scancel -u mjaehn"
    alias sq='squeue -u mjaehn'
    alias squ='squeue'

# euler
elif [[ "${BASHRC_HOST}" == "euler" ]]; then
    alias srcspack="source $SPACK_ROOT/share/spack/setup-env.sh"
    alias spak="spack  --config-scope=${HOME}/.spack/$BASHRC_HOST"
    alias aall="scancel -u mjaehn"
    alias sq='squeue -u mjaehn'
    alias squ='squeue'

# levante
elif [[ "${BASHRC_HOST}" == "levante" ]]; then
    alias aall="scancel -u b381473"
    alias sq='squeue -u b381473'
    alias squ='squeue'
    alias jenkins='cd /mnt/lustre01/scratch/b/b380729/workspace'
    alias st='cd /pool/data/CLMcom/CCLM/reanalyses'
    export SCRATCH=/scratch/b/b381473

elif [[ "${BASHRC_HOST}" == "iac-laptop" || "${BASHRC_HOST}" == "co2" ]]; then
    alias cscskey="cd /home/mjaehn/git/cscs-keys && ./generate-keys.sh"
fi

# Model specific aliases

# Connect to machines
alias daint="ssh -X mjaehn@daint"
alias euler="ssh -X mjaehn@euler"
alias dom="ssh -X mjaehn@dom"
alias levante="ssh -X levante"

# COSMO
alias ct="cat testsuite.out"
alias tt="tail -f testsuite.out"
alias bu='./test/jenkins/build.sh'
alias vo='vim INPUT_ORG'
alias vp='vim INPUT_PHY'
alias vd='vim INPUT_DYN'
alias vio='vim INPUT_IO'

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
alias gl='git log --graph --format=format:"%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%an%C(reset)%C(bold yellow)%d%C(reset) %C(dim white)- %s%C(reset)" --all'
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
