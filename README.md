# dotfiles

Shell, vim and ssh configuration shared across the HPC systems and personal
machines I work on. One repo, symlinked into `$HOME`, with the per-machine
differences resolved at shell startup instead of by keeping separate branches.

## Install

```sh
git clone --recursive git@github.com:mjaehn/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles

./install_tools.sh                    # fresh Debian/Ubuntu/WSL machine only
./install_oh_my_zsh_plugins_theme.sh  # oh-my-zsh + plugins + powerlevel10k
./install.sh                          # symlink everything into $HOME
exec zsh
```

Then run `:PluginInstall` inside vim once to build the vim plugins.

On a cluster without a system zsh (balfrin), run `./install_zsh_user.sh` first
to compile one into `~/local`.

`install.sh` is safe to re-run; it only refreshes symlinks.

## Machines

Host detection lives in `lib/hostinfo.sh` and sets `DOTFILES_HOST` (the machine)
and `DOTFILES_CLUSTER` (the site). Everything else keys off those two variables.

| `DOTFILES_HOST` | `DOTFILES_CLUSTER` | Matched on | Notes |
| --- | --- | --- | --- |
| `santis` | `alps` | `santis*` | CSCS, uenv + Lmod |
| `balfrin` | `alps` | `balfrin*` | CSCS/MeteoSwiss, Tcl modules, locally built zsh |
| `clariden` | `alps` | `clariden*` | CSCS |
| `eiger` | `alps` | `eiger*` | CSCS |
| `euler` | `eth` | `eu*` | ETH; stays in bash, the module command misbehaves under zsh |
| `levante` | `dkrz` | `levante*` | DKRZ; non-interactive sessions stop early |
| `co2` | `iac` | `co2` | ETH IAC server |
| `atmos` | `iac` | `atmos` | ETH IAC server |
| `iac-laptop` | `local` | `iacpc*` | work laptop |
| `home-pc` | `local` | `desktop*` | personal desktop |
| `surface` | `local` | `surfacepro*` | personal laptop, WSL2 on aarch64 |

Hostnames are lowercased before matching, so `SurfacePro11`, `IACPC-42` and
`DESKTOP-ABC` all match. On Alps, `$CLUSTER_NAME` is used as a fallback because
inside a uenv the hostname is generic.

conda is only bootstrapped where it is actually used: `co2`, `atmos`, and the
three `local` machines. The clusters use modules or uenv instead.

## Layout

| Path | Linked to | Purpose |
| --- | --- | --- |
| `lib/hostinfo.sh` | — | host/cluster detection and per-host environment |
| `lib/common.sh` | — | environment, aliases and functions for both shells |
| `lib/conda.sh` | — | conda bootstrap, where conda is used |
| `bashrc` | `~/.bashrc` | bash prompt and the hand-off to zsh |
| `zshrc` | `~/.zshrc` | oh-my-zsh, powerlevel10k, zsh options |
| `aliases.zsh` | `~/.oh-my-zsh/custom/aliases.zsh` | the few zsh-only additions |
| `profile` | `~/.profile` | minimal login-shell setup |
| `vimrc` | `~/.vimrc` | vim configuration |
| `config` | `~/.ssh/config` | ssh hosts, grouped by site |
| `p10k.zsh` | `~/.p10k.zsh` | powerlevel10k prompt, generated |
| `vim-extensions/` | `~/.vim/vim-extensions/` | vim plugins, git submodules |
| `keybindings.json` | not linked | VS Code keybindings, see below |

`lib/` is not symlinked. `bashrc` and `zshrc` resolve their own symlink back to
this repo and source `lib/` from there.

Anything shared between bash and zsh belongs in `lib/`, not in one of the rc
files. That includes the machine-specific aliases, so both shells behave the
same everywhere.

### Shells

`bashrc` execs into zsh on every interactive machine except Euler, and except
inside Slurm jobs. Euler sets `DOTFILES_USE_ZSH=0` because its `module` command
does not work properly under zsh.

Git aliases use the oh-my-zsh names (`gst`, `gco`, `gl`, `gp`, ...). zsh gets
them from the plugin; `lib/common.sh` defines the same ones for bash so the two
shells match. The pretty graph log is `gll`.

### VS Code

`keybindings.json` restores the usual `ctrl+a/c/x/v/z/y/f/h` and tab-indent
behaviour when the Vim extension is active. It is not symlinked, because VS Code
stores its settings outside `$HOME` on WSL. Copy it into your VS Code user
directory by hand.

## Adding a machine

1. Add a case arm to `lib/hostinfo.sh` matching the lowercased hostname, setting
   `DOTFILES_HOST` and `DOTFILES_CLUSTER`.
2. Put machine-specific environment in the per-host `case` further down the same
   file; put machine-specific aliases in the `machine-specific` section of
   `lib/common.sh`.
3. Add it to the conda case in `lib/conda.sh` only if that machine uses conda.
4. Add a row to the table above.
5. Check it:
   ```sh
   zsh -c 'source lib/hostinfo.sh; echo $DOTFILES_HOST $DOTFILES_CLUSTER'
   ```

## License

GPL-3.0, see [LICENSE](LICENSE).
