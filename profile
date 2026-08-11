# ~/.profile -- symlinked from this repo by install.sh
#
# Login-shell setup. Kept minimal: the real configuration is in bashrc/zshrc.

# uv installs its shim here; the guard keeps login shells working on machines
# where uv is not installed.
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi
