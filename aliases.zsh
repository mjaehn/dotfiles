# General aliases
alias aliases="vi $HOME/.oh-my-zsh/custom/aliases.zsh"
alias c="clear"
alias cscskey="cd ~/git/cscs-keys && ./generate-keys.sh"
alias f="find . -name"
alias ml="module load"
alias nd="ncdump -h"
alias nv="ncview"
alias ohmyzsh="vi ~/.oh-my-zsh"
alias scra="cd ${SCRATCH}"
alias sq="squeue -u mjaehn"
alias vi="vim -p"
alias zshconfig="vi ~/.zshrc"

# Additional aliases
if [[ "${ZSHRC_HOST}" == "todi" ]]; then
    alias uenv_tools="uenv start --view=modules netcdf-tools/2024:v1-rc1"
    alias uenv_icon="uenv start --view=spack icon-wcp/v1:rc4"
fi
if [[ "${ZSHRC_HOST}" == "levante" ]]; then
    alias st="cd /pool/data/CLMcom/CCLM/reanalyses/ERA5"
fi
if [[ "${CLUSTER}" == "iac" ]]; then
    alias ftps="cd /net/iacftp/ftp/pub_read/mjaehn"
fi
