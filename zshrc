# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-completions zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Machine-specific settings
#
# Determine hostname for later use in all dotfiles
if [[ "${HOSTNAME}" == daint* ]]; then
    ZSHRC_HOST='daint'
    CLUSTER='alps'
elif [[ "${HOSTNAME}" == santis* ]]; then
    ZSHRC_HOST='santis'
    CLUSTER='alps'
elif [[ "${HOSTNAME}" == balfrin* ]]; then
    ZSHRC_HOST='balfrin'
    CLUSTER='alps'
elif [[ "${CLUSTER_NAME}" == todi* ]]; then
    ZSHRC_HOST='todi'
    CLUSTER='alps'
elif [[ "${CLUSTER_NAME}" == santis* ]]; then
    ZSHRC_HOST='santis'
    CLUSTER='alps'
elif [[ "${HOSTNAME}" == eu* ]]; then
    if tty -s; then
        ZSHRC_HOST='euler'
        CLUSTER='eth'
    else
        return
    fi
elif [[ "${HOSTNAME}" == levante* ]]; then
    source /sw/etc/profile.levante
    if tty -s; then
        ZSHRC_HOST='levante'
        CLUSTER='dkrz'
        module load git
    else
        return
    fi
elif [[ "${HOSTNAME}" == IACPC* ]]; then
    ZSHRC_HOST='iac-laptop'
    CLUSTER='local'
elif [[ "${HOSTNAME}" == DESKTOP* ]]; then
    ZSHRC_HOST='home-pc'
    CLUSTER='local'
elif [[ "${HOSTNAME}" == co2 ]]; then
    ZSHRC_HOST='co2'
    CLUSTER='iac'
fi

export ZSHRC_HOST
export CLUSTER

# Set default Git editor
export GIT_EDITOR="vim"

# Custom modules/paths/envs for each machine
#
# Euler
if [[ "${ZSHRC_HOST}" == "euler" ]]; then
    export PATH=/cluster/home/mjaehn/bin:$PATH
# Balfrin
elif [[ "${ZSHRC_HOST}" == "balfrin" ]]; then
    export MODULEPATH=/mch-environment/v6/modules:${MODULEPATH}
    source /usr/share/Modules/3.2.10/init/zsh
fi

# Conda settings
if [[ "${CLUSTER}" == "alps" ]]; then
    __conda_setup="$('/users/mjaehn/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/users/mjaehn/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/users/mjaehn/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="/users/mjaehn/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
elif [[ "${ZSHRC_HOST}" == "iac-laptop" || "${ZSHRC_HOST}" == "home-pc" || "${ZSHRC_HOST}" == "co2" ]]; then
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
    # Use default environment instead of base
    conda activate default
fi

# Source aliases file
source $HOME/.oh-my-zsh/custom/aliases.zsh

