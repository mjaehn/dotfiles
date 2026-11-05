# dotfiles

Shell, vim, Neovim, tmux and ssh configuration shared across the HPC systems and personal
machines I work on. One repo, symlinked into `$HOME`, with the per-machine
differences resolved at shell startup instead of by keeping separate branches.

## Install

```sh
git clone --recursive git@github.com:mjaehn/dotfiles.git ~/git/dotfiles
cd ~/git/dotfiles

./install_tools.sh                    # Neovim + CLI tools everywhere; apt/conda on local + IAC only
./install_oh_my_zsh_plugins_theme.sh  # oh-my-zsh + plugins + powerlevel10k
./install.sh                          # symlink everything into $HOME
exec zsh
```

Then run `:PluginInstall` inside vim once to build the vim plugins. Neovim
installs its plugins by itself on the first start of `nvim`.

On a cluster without a system zsh (balfrin), run `./install_zsh_user.sh` first
to compile one into `~/local`.

`install.sh` is safe to re-run; it only refreshes symlinks.

`install_tools.sh` installs `fastfetch` into `~/.local/bin` on every host where
it is not already on `PATH`.

`install_tools.sh` installs JetBrainsMono Nerd Font into `~/.local/share/fonts`
on the machines you sit at (the `local` hosts and any host `lib/hostinfo.sh` does
not recognise, if it has fontconfig). The clusters do not need it, because your
local terminal draws the symbols. Two things stay manual: select the font in your
terminal's settings, and under WSL install it on the Windows side.

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

### Caches on Alps

On Alps, `$HOME` is small and `$SCRATCH` (capstor) has a 1 million inode quota
that cache-heavy tools exhaust by themselves: a uv cache is ~80k files, a GT4Py
build cache ~25k. `lib/hostinfo.sh` therefore points every cache at the
flash-backed iopsstor scratch, which has no inode limit and is the right
filesystem for many small files:

```
/iopsstor/scratch/cscs/$USER/cache   # $DOTFILES_CACHE_ROOT, = $XDG_CACHE_HOME
├── pip  uv  hatch  matplotlib  numba  cupy  gt4py
└── tmp                                        # $TMPDIR
```

`XDG_CACHE_HOME` covers everything that follows the spec (`gh`, `fontconfig`,
`pyright`, the Claude CLI); `PIP_CACHE_DIR`, `UV_CACHE_DIR`, `HATCH_DATA_DIR`, `MPLCONFIGDIR`,
`NUMBA_CACHE_DIR`, `CUPY_CACHE_DIR`, `GT4PY_BUILD_CACHE_DIR` and `TMPDIR` are
set individually because those tools ignore it. Export `DOTFILES_CACHE_ROOT`
before the rc file runs to put the whole tree somewhere else.

Scratch is subject to the CSCS cleanup policy, so everything under that root
must be regenerable. Check the quota that motivates this with `quota`.

uv tool environments and uv-managed Pythons are not caches, but they are too
inode-heavy for `$HOME`. They are kept on the project store instead
(`UV_TOOL_DIR`, `UV_PYTHON_INSTALL_DIR` under
`/capstor/store/cscs/userlab/cwd01/$USER/uv`). Their entry points remain in
`~/.local/bin`. `UV_LINK_MODE=copy` is set because the cache is on a different
filesystem and hardlinks cannot work.

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
| `nvim/` | `~/.config/nvim` | Neovim configuration (LazyVim) |
| `tmux.conf` | `~/.tmux.conf` | tmux configuration and plugins |
| `tmux-theme.conf` | `~/.tmux/theme.conf` | Catppuccin status bar, tmux 3.2+ only |
| `gitconfig` | `~/.gitconfig` | git config: delta pager, LFS filters, push defaults |
| `condarc` | `~/.condarc` | conda settings, conda-forge as the only channel |
| `config` | `~/.ssh/config` | ssh hosts, grouped by site |
| `p10k.zsh` | `~/.p10k.zsh` | powerlevel10k prompt, generated |
| `vim-extensions/` | `~/.vim/vim-extensions/` | vim plugins, git submodules |
| `keybindings.json` | not linked | VS Code keybindings, see below |

`lib/` is not symlinked. `bashrc` and `zshrc` resolve their own symlink back to
this repo and source `lib/` from there.

Anything shared between bash and zsh belongs in `lib/`, not in one of the rc
files. That includes the machine-specific aliases, so both shells behave the
same everywhere.

### Git

`gitconfig` holds everything that is the same everywhere. The identity is not in
it: the last line includes `~/.gitconfig.local`, which is per machine and not
tracked, so the work and personal machines can commit under different addresses.
Write it by hand on a new machine, git silently ignores a missing include:

```sh
cat > ~/.gitconfig.local <<'EOF'
[user]
    email = you@example.com
    name = Your Name
EOF
```

The pager is `delta || less`, because delta is not installed on the clusters and
an unconditional `pager = delta` breaks `git log` there. `install_tools.sh`
installs delta into `~/.local/bin` on every host where it runs.

### Shells

`bashrc` execs into zsh on every interactive machine except Euler, and except
inside Slurm jobs. Euler sets `DOTFILES_USE_ZSH=0` because its `module` command
does not work properly under zsh.

Git aliases use the oh-my-zsh names (`gst`, `gco`, `gl`, `gp`, ...). zsh gets
them from the plugin; `lib/common.sh` defines the same ones for bash so the two
shells match. The pretty graph log is `gll`.

### tmux

The status bar sits at the top, away from the shell prompt, and uses the
[Catppuccin](https://github.com/catppuccin/tmux) theme
(mocha) with session, weather, CPU, RAM, load, host, battery (laptops only) and
date widgets. The icons need a Nerd Font (v3, e.g. JetBrainsMono Nerd Font) set in
the local terminal; it renders them for remote hosts too.
Weather comes from [wttr.in](https://wttr.in) for Zurich, refreshed every 15
minutes; change `@tmux-weather-location` in `tmux.conf` for another place.

`install.sh` clones Catppuccin to `~/.tmux/catppuccin`, outside TPM: the theme has
to load before the status line is built, which TPM cannot guarantee. On tmux
older than 3.2 the theme is skipped and the default bar stays.

`install_tools.sh` installs the latest tmux release from conda-forge into
`~/.local/opt/tmux` on every host where the system tmux is older (Levante ships
2.7), and symlinks it into `~/.local/bin`. Restart a running tmux server
(`tmux kill-server`) after an upgrade, since an old server rejects the new client.

| Key | Action |
| --- | --- |
| `<C-h/j/k/l>` | move between tmux panes and vim/Neovim splits (vim-tmux-navigator) |
| `<prefix> <C-l>` | clear the screen, since `<C-l>` alone moves right |
| `<C-v>` | paste the system clipboard (Wayland); Vim, and Claude Code when the clipboard holds an image, still receive the key |
| `<prefix> <C-v>` | send a literal `<C-v>`, e.g. for the shell's quoted insert |
| `v`, `<C-v>`, `y` | in copy mode: select, rectangle select, copy to the system clipboard |
| `<prefix> I` / `<prefix> U` | install / update the TPM plugins |
| `<prefix> R` | reload `~/.tmux.conf` (tmux-sensible) |

### Neovim

`nvim/` is the [LazyVim](https://www.lazyvim.org) starter plus one plugin spec,
`lua/plugins/tmux-navigator.lua`, so `<C-h/j/k/l>` crosses between Neovim splits
and tmux panes. `install_tools.sh` installs Neovim into `~/.local/opt/nvim` and
`rg`, `fd`, `fzf`, `lazygit` and the `tree-sitter` CLI into `~/.local/bin` on
every host, since no module or apt package is recent enough. Where the official
build does not run (too old a glibc), it falls back to the builds from
`neovim/neovim-releases`.

| File | Contents |
| --- | --- |
| `init.lua` | entry point, loads `lua/config/lazy.lua` |
| `lua/config/lazy.lua` | bootstraps lazy.nvim and LazyVim, as in the starter |
| `lua/config/{options,keymaps,autocmds}.lua` | personal overrides of the LazyVim defaults, empty for now |
| `lua/plugins/*.lua` | additional plugins and plugin overrides, one spec file each |
| `lazyvim.json` | extras enabled with `:LazyExtras`, written by Neovim |
| `lazy-lock.json` | pinned plugin commits, written by Neovim |

Enabled extras: `lang.json`. Add language support with `:LazyExtras` (move to
an entry, press `x`, restart) rather than configuring language servers by hand;
Mason then installs the servers into `~/.local/share/nvim/mason`.

`lazy-lock.json` and `lazyvim.json` are written through the symlink into this
repo and are tracked, so every machine runs the same plugin set. Commit them
after `:Lazy update` or `:LazyExtras`; on another machine, `:Lazy restore`
matches the lock file.

The first start of `nvim` clones the plugins and compiles the treesitter
parsers, so it needs internet access and a C compiler. `:checkhealth lazyvim`
lists anything missing. The icons need the same Nerd Font as the prompt and the
tmux status bar. Some language servers that
Mason installs (jsonls among them) need Node.js, which the clusters do not
provide; `install_tools.sh` puts conda-forge's build into `~/.local/opt/node`.

Plugins, parsers and Mason servers live in `~/.local/share/nvim` (about 16k
files and 250 MB with the defaults), Neovim itself in `~/.local/opt/nvim`
(about 2k files, 40 MB). The Neovim cache follows `XDG_CACHE_HOME`, so on Alps
it already lands on iopsstor. Everything there is regenerable: removing
`~/.local/share/nvim` and starting `nvim` reinstalls it.

The classic vim setup (`vimrc`, `vim-extensions/`) stays unchanged; `vim`,
`vi` and `GIT_EDITOR` still start vim.

Leader is `<Space>`; press it and wait for the which-key menu.

| Key | Action |
| --- | --- |
| `<Space><Space>` / `<Space>fr` | find file / recent files |
| `<Space>/` | grep the project |
| `<Space>sr` | search and replace across the project |
| `<Space>e` | file explorer |
| `<S-h>` / `<S-l>`, `<Space>,` | previous / next buffer, buffer list |
| `<Space>bd` | close buffer |
| `gd` / `gr` / `K` | definition / references / hover docs |
| `<Space>cr` / `<Space>ca` / `<Space>cf` | rename / code action / format |
| `<Space>xx` | diagnostics list |
| `gcc` | toggle comment |
| `<C-/>` | toggle terminal |
| `<Space>gg` | lazygit |
| `<Space>sk` | search all keymaps |

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
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless vim/tmux pane movement | `<C-h/j/k/l>` move between vim splits and tmux panes; the tmux side is set up in [tmux.conf](tmux.conf) |

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
