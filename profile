# ~/.profile -- symlinked from this repo by install.sh
#
# Login-shell setup. Kept minimal: the real configuration is in bashrc/zshrc.

# Login shells don't read ~/.bashrc automatically; chain into it so the prompt,
# lib/ and the exec-into-zsh handoff still happen (e.g. WSL terminals, plain
# SSH logins).
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# uv and other user-local tools live here. uv's own ~/.local/bin/env is not
# sourced: it spells the path as ~/.local/share/../bin, which defeats duplicate checks.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) [ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH" && export PATH ;;
esac
