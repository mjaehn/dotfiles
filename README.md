# dotfiles

Shell, vim and ssh configuration shared across the HPC systems and personal
machines I work on. One repo, symlinked into `$HOME`, with the per-machine
differences resolved at shell startup instead of by keeping separate branches.

## Install

```sh
git clone --recursive git@github.com:mjaehn/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles

./install_tools.sh                    # local + IAC only; skips apt where there is no root
./install_oh_my_zsh_plugins_theme.sh  # oh-my-zsh + plugins + powerlevel10k
./install.sh                          # symlink everything into $HOME
exec zsh
```

Then run `:PluginInstall` inside vim once to build the vim plugins.

On a cluster without a system zsh (balfrin), run `./install_zsh_user.sh` first
to compile one into `~/local`.

`install.sh` is safe to re-run; it only refreshes symlinks.

`install_tools.sh` installs Miniforge into `~/miniforge3` and builds the
`default` conda environment (the one the shells auto-activate) from
`conda_packages`. To pull in new packages afterwards, add them there and run:

```sh
mamba install -n default -c conda-forge --file conda_packages
```

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
three `local` machines. The clusters use modules or uenv instead. All of them
use `$HOME/miniforge3`; since `co2` and `atmos` share a filesystem, running
`install_tools.sh` on either one provisions both.

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

## Vim plugins

Quick cheat sheet for the plugins in `vim-extensions/` (managed via Vundle, see
[vimrc](vimrc) for the full `Plugin` list and custom mappings).

| Plugin | Purpose | Key bindings |
| --- | --- | --- |
| [NERDTree](https://github.com/preservim/nerdtree) | File tree | `ff` toggle/reveal current file (custom); `o` open; `t` new tab; `i`/`s` split/vsplit; `R` refresh |
| [ctrlp.vim](https://github.com/ctrlpvim/ctrlp.vim) | Fuzzy file/buffer finder | `<C-p>` open; `<C-j>`/`<C-k>` navigate; `<C-t>`/`<C-v>`/`<C-s>` open in tab/vsplit/split; `<C-f>`/`<C-b>` switch mode |
| [vim-gitgutter](https://github.com/airblade/vim-gitgutter) | Git diff markers in the sign column | `]c`/`[c` next/prev hunk; `<leader>hs` stage hunk; `<leader>hu` undo hunk; `<leader>hp` preview hunk |
| [indentLine](https://github.com/Yggdroot/indentLine) | Indent guides | `:IndentLinesToggle` |
| [vim-rainbow](https://github.com/frazrepo/vim-rainbow) | Rainbow parentheses | `:RainbowToggle` |
| [lightline.vim](https://github.com/itchyny/lightline.vim) | Status line | none, purely visual |
| [vim-autotag](https://github.com/craigemery/vim-autotag) | Regenerates ctags on save | none, automatic (disabled on Euler/Levante, too slow on those filesystems) |
| [vim-fugitive](https://github.com/tpope/vim-fugitive) | Git wrapper | `:Git`/`:G` status window (`-` stage/unstage, `cc` commit, `dv` diff); `:Gdiffsplit`; `:Git blame` |
| [vim-surround](https://github.com/tpope/vim-surround) | Change surrounding pairs/quotes/tags | `ds<char>` delete; `cs<old><new>` change; `ys<motion><char>` add; `S` wrap visual selection |
| [vim-commentary](https://github.com/tpope/vim-commentary) | Toggle comments | `gcc` current line; `gc` + motion (e.g. `gcap`); `gc` in visual mode |
| [tagbar](https://github.com/majutsushi/tagbar) | ctags sidebar | `tl<space>` toggle (custom); inside: `<CR>`/`o` jump to tag, `p` preview |
| [ale](https://github.com/dense-analysis/ale) | Async lint/build checks | `:ALENext`/`:ALEPrevious` cycle errors; `:ALEFix` run fixers; sign column shows severity |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless vim/tmux pane movement | `<C-h/j/k/l>` move between vim splits and tmux panes; needs matching bindings in `tmux.conf`, not present in this repo |

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
