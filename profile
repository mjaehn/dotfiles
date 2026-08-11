# ~/.profile -- symlinked from this repo by install.sh
#
# Login-shell setup. Kept minimal: the real configuration is in bashrc/zshrc.

# Login shells don't read ~/.bashrc automatically; chain into it so the prompt,
# lib/ and the exec-into-zsh handoff still happen (e.g. WSL terminals, plain
# SSH logins).
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# uv installs its shim here; the guard keeps login shells working on machines
# where uv is not installed.
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi
