# Zsh-only additions, symlinked into $ZSH_CUSTOM by install.sh and
# auto-sourced by oh-my-zsh.
#
# Everything portable -- environment, aliases, functions, and the
# machine-specific aliases -- lives in lib/common.sh so that bash gets it too.
# Only put things here that genuinely cannot work in POSIX sh.

alias ohmyzsh='vi ~/.oh-my-zsh'

# Long-form squeue: one field per line, easier to read than the packed `sq`.
# Uses $'...' for the embedded newlines.
sq2() {
    squeue -u "$USER" --format=$'%i\nUser: %u\nAccount: %a\nPartition: %P\nJob Name: %j\nState: %T\nPriority: %Q\nTime Used: %M\nTime Limit: %l\nNodes: %D\nCPUs: %C\nMemory: %m\nNode List: %R\nSubmit Time: %V\nStart Time: %S\nDependency: %E\nWork Dir: %Z\n-------------------------'
}
