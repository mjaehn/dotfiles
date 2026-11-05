#!/bin/sh
#
# Ctrl+V in tmux: paste the system clipboard into the pane, as a bracketed paste.
# Usage: tmux-paste.sh <pane id> <pane tty>
#
# The key goes through unchanged when the pane runs Vim (block select), when the
# clipboard holds no text (Claude Code reads an image from it on Ctrl+V), and on
# machines where wl-paste cannot reach a clipboard (clusters, SSH sessions).

pane=$1
tty=$2

in_vim() {
    ps -o state= -o comm= -t "$tty" \
        | grep -iqE '^[^TXZ ]+ +(\S+/)?(g?\.?(view|l?n?vim?x?)(diff)?(-wrapped)?)$'
}

has_text() {
    wl-paste --list-types 2>/dev/null | grep -qE '^(text/plain|UTF8_STRING|STRING|TEXT)'
}

if in_vim || ! has_text; then
    exec tmux send-keys -t "$pane" C-v
fi

# -n: wl-paste would otherwise add a newline, which submits the line in a shell
# that has bracketed paste off.
wl-paste --no-newline --type text | tmux load-buffer -b ctrl-v-paste - \
    && tmux paste-buffer -dp -b ctrl-v-paste -t "$pane"
