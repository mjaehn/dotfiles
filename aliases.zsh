# Squeue format
squeue_format="%.7i %.22j %.6u %.6a %.2t %.10M %.9l %.5D %24R"

# General aliases
alias aliases="vi $HOME/.oh-my-zsh/custom/aliases.zsh"
alias bashconfig="vi ~/.bashrc"
alias c="clear"
alias cscskey="cd ~/git/cscs-keys && ./generate-keys.sh"
alias f="find . -name"
alias gsi='git submodule init'
alias gsu='git submodule update'
alias gsui='git submodule update --init'
alias gsuir='git submodule update --init --recursive'
alias ml="module load"
alias nd="ncdump -h"
alias nv="ncview"
alias ohmyzsh="vi ~/.oh-my-zsh"
alias scra="cd ${SCRATCH}"
alias sq="squeue -u $USER -o \"${squeue_format}\""
alias sqw="watch -x -n 60 squeue -u $USER -o \"${squeue_format}\""
alias vi="vim -p"
alias zshconfig="vi ~/.zshrc"

unalias sq2 2>/dev/null  # Ensure no conflicting alias exists
sq2() {
    squeue -u "$USER" --format=$'%i\nUser: %u\nAccount: %a\nPartition: %P\nJob Name: %j\nState: %T\nPriority: %Q\nTime Used: %M\nTime Limit: %l\nNodes: %D\nCPUs: %C\nMemory: %m\nNode List: %R\nSubmit Time: %V\nStart Time: %S\nDependency: %E\nWork Dir: %Z\n-------------------------'
}


# Machine-dependent aliases
if [[ "${ZSHRC_HOST}" == "todi" || "${ZSHRC_HOST}" == "santis" ]]; then
    alias uenv_tools="uenv start --view=modules netcdf-tools/2024:v1"
    alias uenv_icon="uenv start icon-wcp/v1:rc4"
    alias nn="module load netcdf-c/4.9.2 ncview/2.1.9 && echo Loading ncdump and ncview."
    alias st="cd /capstor/store/cscs/c2sm/c2sme"
fi
if [[ "${ZSHRC_HOST}" == "balfrin" ]]; then
    alias nn="module load netcdf-c/4.8.1-gcc && echo Loading ncdump."
    alias st="cd /capstor/store/cscs/c2sm"
fi
if [[ "${ZSHRC_HOST}" == "levante" ]]; then
    alias st="cd /pool/data/CLMcom/CCLM/reanalyses/ERA5"
fi
if [[ "${CLUSTER}" == "iac" ]]; then
    alias ftps="cd /net/iacftp/ftp/pub_read/mjaehn"
fi
if [[ "${ZSHRC_HOST}" == "euler" ]]; then
    alias st="cd /cluster/work/climate/icon_testing_input"
    alias scra="cd /cluster/scratch/$USER" 
fi
