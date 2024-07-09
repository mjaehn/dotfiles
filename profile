# Check for interactive shell before sourcing .bashrc
case $- in
    *i*) . ~/.bashrc ;;
esac
