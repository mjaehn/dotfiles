# shellcheck shell=sh
#
# Conda bootstrap, shared by bashrc and zshrc.
#
# POSIX sh only -- sourced by both shells.
#
# Conda is only used on the IAC servers and the personal machines. The Alps
# systems (santis, balfrin, clariden, eiger), Euler and Levante use modules or
# uenv instead, so nothing here runs there.

# Initialise conda from the first prefix that exists.
# Picks the hook shell from the shell actually running, which is what the old
# hand-copied blocks got wrong (they asked for shell.zsh inside .bashrc).
_dotfiles_conda_init() {
    _dcs_hook='bash'
    [ -n "${ZSH_VERSION:-}" ] && _dcs_hook='zsh'

    for _dcs_prefix in "$@"; do
        [ -d "$_dcs_prefix" ] || continue

        if _dcs_setup="$("$_dcs_prefix/bin/conda" shell."$_dcs_hook" hook 2>/dev/null)"; then
            eval "$_dcs_setup"
        elif [ -f "$_dcs_prefix/etc/profile.d/conda.sh" ]; then
            . "$_dcs_prefix/etc/profile.d/conda.sh"
        else
            PATH="$_dcs_prefix/bin:$PATH"
            export PATH
        fi

        unset _dcs_hook _dcs_prefix _dcs_setup
        return 0
    done

    unset _dcs_hook _dcs_prefix _dcs_setup
    return 1
}

# Activate $1 if it exists, otherwise fall back to base.
# Plain `conda activate default` used to error out on machines without that env.
_dotfiles_conda_activate() {
    command -v conda >/dev/null 2>&1 || return 0

    if conda env list 2>/dev/null | awk '{print $1}' | grep -qx -- "$1"; then
        conda activate "$1"
    else
        conda activate base 2>/dev/null
    fi
}

# Only bootstrap conda in interactive shells: activating it in non-interactive
# ones writes to stdout and breaks scp/sftp.
case "$-" in
    *i*) ;;
    *) return 0 ;;
esac

case "$DOTFILES_HOST" in
    atmos)
        _dotfiles_conda_init /usr/local/Miniconda3
        ;;
    co2|surface|home-pc|iac-laptop)
        # Order matters: prefer miniforge3, which is what install_tools.sh sets up
        _dotfiles_conda_init "$HOME/miniforge3" "$HOME/miniforge" "$HOME/miniconda3" \
            && _dotfiles_conda_activate default
        ;;
esac

return 0
