#!/usr/bin/env bash
#
# Provision a machine with the tools these dotfiles expect. Safe to re-run:
# every step is guarded.
#
#   local (Debian/Ubuntu/WSL) -- everything, including the apt steps
#   iac   (co2, atmos)        -- only the $HOME-local steps; these are centrally
#                                managed machines where we have no root
#
# Run install.sh afterwards to symlink the configuration itself.

set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

have() { command -v "$1" >/dev/null 2>&1; }

# Alps, Euler and Levante are provisioned with modules or uenv, never from here.
# shellcheck source=lib/hostinfo.sh
. "$REPO/lib/hostinfo.sh"
case "$DOTFILES_CLUSTER" in
    local) HAS_ROOT=1 ;;
    iac)   HAS_ROOT=0 ;;
    *)
        echo "install_tools.sh only runs on local and IAC machines" >&2
        echo "(detected host '${DOTFILES_HOST:-unknown}', cluster '${DOTFILES_CLUSTER:-unknown}')" >&2
        exit 1
        ;;
esac

if (( HAS_ROOT )); then
    echo "Updating system..."
    # Two statements, not `a && b`: set -e ignores a failure in the non-final
    # position of an AND-OR list, so a broken apt update would fall through.
    sudo apt update
    sudo apt upgrade -y

    echo "Installing base packages..."
    sudo apt install -y \
        build-essential ca-certificates cdo curl gnupg imagemagick lsb-release \
        ncview netcdf-bin software-properties-common wget zsh

    # wslu provides wslview, only meaningful under WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "Installing wslu (WSL detected)..."
        sudo apt install -y wslu
    fi

    if ! have node; then
        echo "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
    fi

    echo "Installing latest Git..."
    sudo add-apt-repository ppa:git-core/ppa -y
    sudo apt update
    sudo apt install -y git

    if ! have git-lfs; then
        echo "Installing Git LFS..."
        curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
        sudo apt install -y git-lfs
        git lfs install
    fi
else
    echo "No root on $DOTFILES_HOST, skipping the apt steps."
    echo "  zsh, git and git-lfs come from the system there; cdo, nco and ncview"
    echo "  come from the conda environment created below."
fi

# Not a sudo step -- chsh changes your own entry -- but it still fails on the
# LDAP-managed IAC accounts, and set -e would take the whole script down with it.
if [[ "$SHELL" != *zsh ]] && have zsh; then
    echo "Setting zsh as the default shell..."
    chsh -s "$(command -v zsh)" || echo "  chsh failed, ask the admins to change your login shell."
fi

if ! have uv; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Match the prefix lib/conda.sh looks for, and the architecture we run on
# (this repo is used on both x86_64 and aarch64 machines).
CONDA_PREFIX_DIR="$HOME/miniforge3"
if [[ ! -d "$CONDA_PREFIX_DIR" ]]; then
    echo "Installing Miniforge for $(uname -m)..."
    installer="Miniforge3-Linux-$(uname -m).sh"
    wget -q "https://github.com/conda-forge/miniforge/releases/latest/download/$installer" \
        -O "/tmp/$installer"
    bash "/tmp/$installer" -b -p "$CONDA_PREFIX_DIR"
    rm -f "/tmp/$installer"
else
    echo "Miniforge already installed at $CONDA_PREFIX_DIR."
fi

# No `conda init` here on purpose: lib/conda.sh already bootstraps conda in both
# shells, and conda init writes through the symlinks install.sh creates, which
# would append its managed block straight into the repo's bashrc and zshrc.
eval "$("$CONDA_PREFIX_DIR/bin/conda" shell.bash hook)"

# The shells activate the "default" environment, not base
if ! conda env list | awk '{print $1}' | grep -qx default; then
    echo "Creating the 'default' conda environment from conda_packages..."
    # Full path: the shell hook only puts condabin on PATH, not bin/mamba
    "$CONDA_PREFIX_DIR/bin/mamba" create -y -n default -c conda-forge \
        --file "$REPO/conda_packages"
else
    echo "Conda environment 'default' already exists."
    echo "  update it with: mamba install -n default -c conda-forge --file $REPO/conda_packages"
fi

echo
echo "All done. Now run: ./install.sh"
