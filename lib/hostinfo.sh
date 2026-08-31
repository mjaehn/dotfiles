# shellcheck shell=sh
#
# Host and cluster detection, shared by bashrc and zshrc.
#
# POSIX sh only -- this file is sourced by both bash and zsh, so it must not use
# bashisms (arrays, [[ ]], ${var,,}) or zshisms.
#
# Sets and exports:
#   DOTFILES_HOST     short machine id   (santis, euler, surface, ...)
#   DOTFILES_CLUSTER  site grouping      (alps, eth, dkrz, iac, local)
#
# Sets (not exported, read by the caller):
#   DOTFILES_USE_ZSH  0 when the host must stay in bash
#   DOTFILES_ABORT_RC 1 when the caller should stop sourcing its rc file.
#                     A `return` here would only exit this file, not the rc.
#
# BASHRC_HOST, ZSHRC_HOST and CLUSTER are exported as back-compat aliases:
# vimrc reads $BASHRC_HOST, and scripts outside this repo may read them too.

DOTFILES_HOST=''
DOTFILES_CLUSTER=''
DOTFILES_USE_ZSH=1
DOTFILES_ABORT_RC=0

# Lowercase both sources so a single set of patterns covers IACPC/iacpc,
# DESKTOP/desktop and SurfacePro/surfacepro.
_dotfiles_hn="$(hostname 2>/dev/null || printf '%s' "${HOSTNAME:-${HOST:-unknown}}")"
_dotfiles_hn="$(printf '%s' "$_dotfiles_hn" | tr '[:upper:]' '[:lower:]')"
_dotfiles_cn="$(printf '%s' "${CLUSTER_NAME:-}" | tr '[:upper:]' '[:lower:]')"

case "$_dotfiles_hn" in
    santis*)     DOTFILES_HOST='santis';     DOTFILES_CLUSTER='alps'  ;;
    balfrin*)    DOTFILES_HOST='balfrin';    DOTFILES_CLUSTER='alps'  ;;
    clariden*)   DOTFILES_HOST='clariden';   DOTFILES_CLUSTER='alps'  ;;
    eiger*)      DOTFILES_HOST='eiger';      DOTFILES_CLUSTER='alps'  ;;
    eu*)         DOTFILES_HOST='euler';      DOTFILES_CLUSTER='eth'   ;;
    levante*)    DOTFILES_HOST='levante';    DOTFILES_CLUSTER='dkrz'  ;;
    co2)         DOTFILES_HOST='co2';        DOTFILES_CLUSTER='iac'   ;;
    atmos)       DOTFILES_HOST='atmos';      DOTFILES_CLUSTER='iac'   ;;
    iacpc*)      DOTFILES_HOST='iac-laptop'; DOTFILES_CLUSTER='local' ;;
    desktop*)    DOTFILES_HOST='home-pc';    DOTFILES_CLUSTER='local' ;;
    surfacepro*) DOTFILES_HOST='surface';    DOTFILES_CLUSTER='local' ;;
    *)
        # Inside a uenv the hostname is generic, but CLUSTER_NAME still names
        # the Alps system.
        case "$_dotfiles_cn" in
            santis*)   DOTFILES_HOST='santis';   DOTFILES_CLUSTER='alps' ;;
            balfrin*)  DOTFILES_HOST='balfrin';  DOTFILES_CLUSTER='alps' ;;
            clariden*) DOTFILES_HOST='clariden'; DOTFILES_CLUSTER='alps' ;;
            eiger*)    DOTFILES_HOST='eiger';    DOTFILES_CLUSTER='alps' ;;
        esac
        ;;
esac

unset _dotfiles_hn _dotfiles_cn

# Per-host environment
case "$DOTFILES_HOST" in
    santis)
        # VS Code tunnels are per-system, keep their state out of the shared $HOME
        VSCODE_AGENT_FOLDER="$HOME/.vscode-server/${CLUSTER_NAME:-santis}-tunnel/.vscode-server"
        VSCODE_CLI_DATA_DIR="$VSCODE_AGENT_FOLDER/cli"
        export VSCODE_AGENT_FOLDER VSCODE_CLI_DATA_DIR
        ;;
    balfrin)
        MODULEPATH="/mch-environment/v6/modules:${MODULEPATH}"
        export MODULEPATH
        ;;
    euler)
        PATH="/cluster/home/mjaehn/bin:$PATH"
        APPTAINER_CACHEDIR="${SCRATCH:-}/.apptainer"
        APPTAINER_TMPDIR="${TMPDIR:-/tmp}"
        UV_CONFIG_FILE="$HOME/.config/uv/uv.toml"
        export PATH APPTAINER_CACHEDIR APPTAINER_TMPDIR UV_CONFIG_FILE
        DOTFILES_USE_ZSH=0  # the module command misbehaves under zsh here
        ;;
    levante)
        [ -f /sw/etc/profile.levante ] && . /sw/etc/profile.levante
        SCRATCH=/scratch/b/b381473
        export SCRATCH
        if tty -s 2>/dev/null; then
            module load git 2>/dev/null
        else
            DOTFILES_ABORT_RC=1  # non-interactive (Jenkins) sessions stop here
        fi
        ;;
    iac-laptop)
        # Deliberately a full replacement, not a prepend
        PATH="$HOME/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        export PATH
        # Local console only: under ssh -X this would clobber the forwarded
        # DISPLAY and silently break X11 forwarding.
        if [ -z "${SSH_CONNECTION:-}" ]; then
            DISPLAY=:0
            export DISPLAY
        fi
        ;;
esac

# Machine-local binaries installed by install_tools.sh (e.g. delta), keyed by
# uname -m in case $HOME is shared across differing node architectures, as it
# already was for santis before this was generalized to every host.
if [ -d "$HOME/.local/$(uname -m)/bin" ]; then
    PATH="$HOME/.local/$(uname -m)/bin:$PATH"
    export PATH
fi

# $HOME is small and shared on Alps, so keep pip's caches on scratch.
# These used to live inside the (now removed) Alps conda block; they are a pip
# setting, not a conda one.
if [ "$DOTFILES_CLUSTER" = 'alps' ] && [ -n "${SCRATCH:-}" ]; then
    PIP_CACHE_DIR="$SCRATCH/pip_cache"
    TMPDIR="$SCRATCH/pip_temp"
    export PIP_CACHE_DIR TMPDIR
    mkdir -p "$PIP_CACHE_DIR" "$TMPDIR" 2>/dev/null
fi

if [ "$DOTFILES_CLUSTER" = 'local' ] || [ "$DOTFILES_CLUSTER" = 'iac' ]; then
    if [ -d "$HOME/.local/bin" ]; then
        PATH="$HOME/.local/bin:$PATH"
        export PATH
    fi
    # cargo, needed by cscs-key
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    # fnm (Node version manager)
    if [ -d "$HOME/.local/share/fnm" ]; then
        PATH="$HOME/.local/share/fnm:$PATH"
        export PATH
        eval "$(fnm env 2>/dev/null)"
    fi
fi

# uv installs its shim here
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

export DOTFILES_HOST DOTFILES_CLUSTER

# Back-compat aliases for vimrc and for scripts outside this repo
BASHRC_HOST="$DOTFILES_HOST"
ZSHRC_HOST="$DOTFILES_HOST"
CLUSTER="$DOTFILES_CLUSTER"
export BASHRC_HOST ZSHRC_HOST CLUSTER

return 0
