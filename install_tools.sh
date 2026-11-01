#!/usr/bin/env bash
#
# Provision a machine with the tools these dotfiles expect. Safe to re-run:
# every step is guarded.
#
#   every host                -- delta, Neovim, the CLI tools LazyVim uses,
#                                fastfetch, Node.js and the latest tmux, into
#                                $HOME/.local; a recent Git where needed
#   local (Debian/Ubuntu/WSL) -- everything, including the apt steps
#   iac   (co2, atmos)        -- only the $HOME-local steps; these are centrally
#                                managed machines where we have no root
#
# Run install.sh afterwards to symlink the configuration itself.

set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

have() { command -v "$1" >/dev/null 2>&1; }

# shellcheck source=lib/hostinfo.sh
. "$REPO/lib/hostinfo.sh"

# Delta has no package on Alps/Euler/Levante and we have no root there, so it is
# a standalone binary fetched from GitHub releases. Runs on every host, unlike
# everything below it: it needs neither sudo nor the conda env.
install_delta() {
    local arch target version tmp_dir bin_dir stale
    arch="$(uname -m)"

    # Earlier revisions installed to $HOME/.local/$arch/bin, which no host ever
    # put on PATH. Remove any such leftover so the copy below is the only one.
    stale="$HOME/.local/$arch/bin/delta"
    if [[ -e "$stale" ]]; then
        echo "Removing stale delta at $stale..."
        rm -f "$stale"
        rmdir -p "$(dirname "$stale")" 2>/dev/null || true
    fi

    if have delta; then
        echo "delta already installed."
        return
    fi

    echo "Installing delta..."
    case "$arch" in
        # musl is a static build, so it works across the range of glibc
        # versions found on HPC login nodes; no musl target exists for aarch64.
        x86_64)  target="x86_64-unknown-linux-musl" ;;
        aarch64) target="aarch64-unknown-linux-gnu" ;;
        *)
            echo "  No prebuilt delta binary for architecture '$arch', skipping." >&2
            return
            ;;
    esac

    version="$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
        https://github.com/dandavison/delta/releases/latest | sed 's#.*/tag/##')"
    tmp_dir="$(mktemp -d)"
    curl -fsSL -o "$tmp_dir/delta.tar.gz" \
        "https://github.com/dandavison/delta/releases/download/$version/delta-$version-$target.tar.gz"
    tar -xzf "$tmp_dir/delta.tar.gz" -C "$tmp_dir"

    bin_dir="$HOME/.local/bin"
    mkdir -p "$bin_dir"
    install -m 755 "$tmp_dir/delta-$version-$target/delta" "$bin_dir/delta"
    rm -rf "$tmp_dir"
    echo "  Installed delta $version to $bin_dir/delta"
}

install_delta

latest_tag() { # $1 = GitHub owner/repo; resolves the redirect, avoiding the API rate limit
    curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's#.*/tag/##'
}

# Install the executable named $1 from the release archive at URL $2 into $HOME/.local/bin.
install_release_binary() {
    local name="$1" url="$2" tmp_dir
    tmp_dir="$(mktemp -d)"
    curl -fsSL -o "$tmp_dir/archive" "$url"
    case "$url" in
        *.tar.gz) tar -xzf "$tmp_dir/archive" -C "$tmp_dir" ;;
        *.gz)     gunzip -c "$tmp_dir/archive" >"$tmp_dir/$name" ;;
    esac
    mkdir -p "$HOME/.local/bin"
    # Skip share/, where some archives ship a shell-completion file with the same name.
    install -m 755 "$(find "$tmp_dir" -type f -name "$name" ! -path '*/share/*' | head -n1)" "$HOME/.local/bin/$name"
    rm -rf "$tmp_dir"
    echo "  Installed $name to \$HOME/.local/bin/$name"
}

# LazyVim needs Neovim >= 0.11.2, newer than any module or apt package on our
# hosts, so the official build goes to $HOME/.local/opt/nvim on every host.
MIN_NVIM_VERSION="0.11.2"

install_neovim() {
    local arch current nvim_dir tmp_dir repo
    if have nvim; then
        current="$(nvim --version | head -n1 | sed 's/^NVIM v//')"
        if version_ge "$current" "$MIN_NVIM_VERSION"; then
            echo "nvim $current already recent enough (>= $MIN_NVIM_VERSION)."
            return
        fi
    fi

    case "$(uname -m)" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="arm64" ;;
        *)
            echo "  No prebuilt Neovim for architecture '$(uname -m)', skipping." >&2
            return
            ;;
    esac

    nvim_dir="$HOME/.local/opt/nvim"
    # The official build needs a recent glibc; neovim-releases targets older ones (Levante).
    for repo in neovim/neovim neovim/neovim-releases; do
        echo "Installing Neovim from $repo..."
        # Extract beside the target so mv is a rename; a cross-filesystem mv fails on NFS homes.
        mkdir -p "$(dirname "$nvim_dir")"
        tmp_dir="$(mktemp -d "$nvim_dir.XXXXXX")"
        curl -fsSL "https://github.com/$repo/releases/download/$(latest_tag "$repo")/nvim-linux-$arch.tar.gz" |
            tar -xz -C "$tmp_dir"
        rm -rf "$nvim_dir"
        mv "$tmp_dir/nvim-linux-$arch" "$nvim_dir"
        rm -rf "$tmp_dir"
        if "$nvim_dir/bin/nvim" --version >/dev/null 2>&1; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$nvim_dir/bin/nvim" "$HOME/.local/bin/nvim"
            echo "  $("$nvim_dir/bin/nvim" --version | head -n1), symlinked into \$HOME/.local/bin/nvim"
            return
        fi
        echo "  This build does not run here." >&2
    done
    echo "  No Neovim build runs on this host, skipping." >&2
}

# Command-line tools LazyVim relies on: rg and fd for search, lazygit for git,
# fzf for its health check, and tree-sitter to build the syntax parsers.
install_editor_tools() {
    local tag musl fzf_arch lazygit_arch
    # Each project spells the architecture differently in its asset names.
    case "$(uname -m)" in
        x86_64)  musl="x86_64-unknown-linux-musl";  fzf_arch="amd64"; lazygit_arch="x86_64" ;;
        aarch64) musl="aarch64-unknown-linux-musl"; fzf_arch="arm64"; lazygit_arch="arm64" ;;
        *)
            echo "  No prebuilt editor tools for architecture '$(uname -m)', skipping." >&2
            return
            ;;
    esac

    if ! have rg; then
        echo "Installing ripgrep..."
        tag="$(latest_tag BurntSushi/ripgrep)"
        install_release_binary rg "https://github.com/BurntSushi/ripgrep/releases/download/$tag/ripgrep-$tag-$musl.tar.gz"
    fi
    if ! have fd; then
        echo "Installing fd..."
        tag="$(latest_tag sharkdp/fd)"
        install_release_binary fd "https://github.com/sharkdp/fd/releases/download/$tag/fd-$tag-$musl.tar.gz"
    fi
    if ! have fzf; then
        echo "Installing fzf..."
        tag="$(latest_tag junegunn/fzf)"
        install_release_binary fzf "https://github.com/junegunn/fzf/releases/download/$tag/fzf-${tag#v}-linux_$fzf_arch.tar.gz"
    fi
    if ! have lazygit; then
        echo "Installing lazygit..."
        tag="$(latest_tag jesseduffield/lazygit)"
        install_release_binary lazygit "https://github.com/jesseduffield/lazygit/releases/download/$tag/lazygit_${tag#v}_linux_$lazygit_arch.tar.gz"
    fi
    # The upstream release binary requires glibc >= 2.39; conda-forge builds against an older baseline.
    # Running it, rather than only locating it, also replaces a binary that does not run on this host.
    if ! tree-sitter --version >/dev/null 2>&1; then
        echo "Installing tree-sitter CLI..."
        conda_forge_install tree-sitter-cli "$HOME/.local/opt/tree-sitter"
        if [[ -x "$HOME/.local/opt/tree-sitter/bin/tree-sitter" ]]; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$HOME/.local/opt/tree-sitter/bin/tree-sitter" "$HOME/.local/bin/tree-sitter"
        fi
    fi
}

# Some HPC login-node images ship a Git old enough to reject config added by
# newer releases (merge.conflictstyle=zdiff3, added in 2.35, is the one that
# bit us). There is no prebuilt Git binary and, on these clusters, no root to
# install a newer package either, so a recent Git is pulled from conda-forge
# into its own prefix via a throwaway micromamba - the same "no module/apt
# package, so fetch it ourselves" situation install_delta is already in.
# local machines get their upgrade through apt instead (below), so this is
# only called where that is not an option.
MIN_GIT_VERSION="2.35"

version_ge() { # $1 >= $2, both dotted version strings
    [[ "$1" == "$2" ]] && return 0
    [[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" == "$1" ]]
}

# Install conda-forge package $1 into its own prefix $2 via a throwaway micromamba.
# Never call it in an AND-OR list: that disables set -e inside it, so a failed
# download would go unnoticed. Callers check for the binary instead.
conda_forge_install() {
    local pkg="$1" prefix="$2" platform tmp_dir
    case "$(uname -m)" in
        x86_64)  platform="linux-64" ;;
        aarch64) platform="linux-aarch64" ;;
        *)
            echo "  No micromamba build for architecture '$(uname -m)', skipping $pkg." >&2
            return
            ;;
    esac

    tmp_dir="$(mktemp -d)"
    echo "  Fetching micromamba to bootstrap an isolated $pkg environment..."
    curl -fsSL "https://micro.mamba.pm/api/micromamba/$platform/latest" | tar -xj -C "$tmp_dir" bin/micromamba
    echo "  Installing $pkg from conda-forge to $prefix..."
    rm -rf "$prefix"
    mkdir -p "$(dirname "$prefix")"
    "$tmp_dir/bin/micromamba" create -y -r "$tmp_dir/root" -p "$prefix" -c conda-forge "$pkg" >/dev/null
    rm -rf "$tmp_dir"
}

install_recent_git() {
    local current git_dir

    if have git; then
        current="$(git --version | awk '{print $3}')"
        if version_ge "$current" "$MIN_GIT_VERSION"; then
            echo "git $current already recent enough (>= $MIN_GIT_VERSION)."
            return
        fi
        echo "System git $current is older than $MIN_GIT_VERSION; installing a newer one to \$HOME/.local..."
    else
        echo "No git found; installing one to \$HOME/.local..."
    fi

    git_dir="$HOME/.local/opt/git"
    if [[ ! -x "$git_dir/bin/git" ]] || ! version_ge "$("$git_dir/bin/git" --version | awk '{print $3}')" "$MIN_GIT_VERSION"; then
        conda_forge_install git "$git_dir"
    fi
    [[ -x "$git_dir/bin/git" ]] || return 0

    # $HOME/.local/bin is already on PATH for every host (lib/hostinfo.sh), and
    # git resolves its libexec/git-core helpers relative to the real prefix
    # behind a symlink, so a plain symlink here is enough - no PATH surgery,
    # no shell restart required for it to take effect in new shells.
    mkdir -p "$HOME/.local/bin"
    ln -sf "$git_dir/bin/git" "$HOME/.local/bin/git"
    echo "  $("$HOME/.local/bin/git" --version), symlinked into \$HOME/.local/bin/git"
}

# System tmux is old on the clusters (Levante: 2.7, too old for the theme) and
# lags behind on apt, so the latest release comes from conda-forge on every host.
install_tmux() {
    local current latest
    latest="$(latest_tag tmux/tmux)"
    if have tmux; then
        current="$(tmux -V | awk '{print $2}')"
        if version_ge "$current" "$latest"; then
            echo "tmux $current already up to date."
            return
        fi
        echo "tmux $current is older than $latest; installing the latest to \$HOME/.local..."
    else
        echo "No tmux found; installing one to \$HOME/.local..."
    fi

    conda_forge_install tmux "$HOME/.local/opt/tmux"
    [[ -x "$HOME/.local/opt/tmux/bin/tmux" ]] || return 0
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.local/opt/tmux/bin/tmux" "$HOME/.local/bin/tmux"
    echo "  $("$HOME/.local/bin/tmux" -V), symlinked into \$HOME/.local/bin/tmux"
}

# The polyfilled build targets older glibc versions, as found on HPC login nodes.
install_fastfetch() {
    local arch tag
    have fastfetch && return
    case "$(uname -m)" in
        x86_64)  arch="amd64" ;;
        aarch64) arch="aarch64" ;;
        *)
            echo "  No prebuilt fastfetch for architecture '$(uname -m)', skipping." >&2
            return
            ;;
    esac
    echo "Installing fastfetch..."
    tag="$(latest_tag fastfetch-cli/fastfetch)"
    install_release_binary fastfetch "https://github.com/fastfetch-cli/fastfetch/releases/download/$tag/fastfetch-linux-$arch-polyfilled.tar.gz"
}

# Mason installs several language servers (jsonls among them) through npm, and
# the clusters ship no Node.js, so conda-forge's build goes to $HOME/.local/opt/node.
install_node() {
    local tool
    have node && have npm && return
    echo "Installing Node.js..."
    conda_forge_install nodejs "$HOME/.local/opt/node"
    [[ -x "$HOME/.local/opt/node/bin/node" ]] || return 0
    mkdir -p "$HOME/.local/bin"
    for tool in node npm npx; do
        ln -sf "$HOME/.local/opt/node/bin/$tool" "$HOME/.local/bin/$tool"
    done
    echo "  Node.js $("$HOME/.local/bin/node" --version), symlinked into \$HOME/.local/bin"
}

install_neovim
install_editor_tools
install_tmux
install_fastfetch
install_node

# Alps, Euler and Levante are provisioned with modules or uenv, never from here;
# everything below this point is sudo/conda provisioning for local and IAC only.
case "$DOTFILES_CLUSTER" in
    local) HAS_ROOT=1 ;;
    iac)   HAS_ROOT=0 ;;
    *)
        install_recent_git
        echo "Nothing else to provision on $DOTFILES_CLUSTER; it's managed via modules/uenv."
        exit 0
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
        build-essential ca-certificates cdo curl git-delta gnupg imagemagick lsb-release \
        ncview netcdf-bin software-properties-common wget x11-apps x11-utils xauth zsh

    # wslu provides wslview, only meaningful under WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "Installing wslu (WSL detected)..."
        sudo apt install -y wslu
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
    echo "  zsh and git-lfs come from the system there; cdo, nco and ncview come"
    echo "  from the conda environment created below."
    install_recent_git
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
