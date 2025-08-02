. "$HOME/.local/bin/env" 2>/dev/null

export GT_SEARCH_DIRS="$HOME/Projects/:$HOME/Work/:$HOME/.dotfiles/:$HOME/Source/:$XDG_CONFIG_HOME/waybar:$XDG_CONFIG_HOME/hypr"
export NVM_DIR="$HOME/.nvm"
export GPG_TTY=$(tty)

# WSL SPECIFIC STUFF {{{
if [[ $(rg -i microsoft /proc/version) ]]; then
    GT_SEARCH_DIRS="$GT_SEARCH_DIRS:$USERPROFILE/Projects/:$USERPROFILE/Work/:$USERPROFILE/Documents"
fi
# }}}
