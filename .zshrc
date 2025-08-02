# initialize completions {{{
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit
compinit
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# }}}

# PATH {{{
path+=("/opt/nvim/bin")
path+=("/usr/local/go/bin")
path+=("$HOME/Projects/etc/gt")
export PATH
# }}}

# INTERACTIVE SOURCES {{{
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# }}}

# SOURCE ZSH PLUGINS {{{
function zsh-plugins-init() {
  local plugin_dir="${ZDOTDIR:-$HOME}/.zsh_plugins"
  if [[ ! -d "$plugin_dir" ]]; then
    echo "Error: No plugins directory found at $plugin_dir."
    return 1
  fi

  local plugin_path=
  for plugin_path in "$plugin_dir"/*/*; do
    [[ -d "$plugin_dir" ]] || continue

    local plugin=${plugin_path#"$plugin_dir/"} # relative path: e.g. "romaktv/powerlevel10k"
    local found=0
    local initscripts=(
      ${plugin#*/}.zsh
      ${plugin#*/}.plugin.zsh
      ${plugin#*/}.zsh-theme
      ${plugin#*/}.sh
    )
    local initscript=
    for initscript in ${initscripts[@]}; do
      local filepath="$plugin_path/$initscript"
      [[ -f "$filepath" ]] || continue
      source "$filepath"
      found=1
      break
    done
    if [[ $found -eq 0 ]]; then
      echo "Warning: No initialization file found for plugin '$plugin'."
    fi
  done

  # ADDITIONAL SETUP
  if [[ -f ${ZDOTDIR:-$HOME}/.p10k.zsh ]]; then
    source ${ZDOTDIR:-$HOME}/.p10k.zsh
  fi
  return 0
}
zsh-plugins-init
# }}}

# ALIASES {{{
alias lg="lazygit"
alias l="ls"
alias ll="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias v="nvim"
alias v.="nvim ."
alias ..="cd ../."
alias ...="cd ../../."
alias ....="cd ../../../."
alias .....="cd ../../../../."
alias plugpull="find ${ZDOTDIR:-$HOME}/.zsh_plugins -type d -exec test -e \"{}/.git\" \";\" -print0 | xargs -I {} -0 git -C {} pull"
# }}}

# FUNCTIONS {{{
function git-check() {
  git config user.name
  git config user.email
  git config user.signingkey
}
function git-clear() {
  git config user.name ""
  git config user.email ""
  git config user.signingkey ""
}
# assign user.name, user.email, and user.signing key based on remote.origin.url
# expected format: git@<domain>-<username>:<repo owner>/<repo name><optional '.git'>
#                  git@github.com-saltkid:saltkid/dotfiles.git
#
# username is based on parsed <domain>-<username>
# email is based on the ssh file that is named <domain>-<username>
# signingkey is based on username and email
function git-setup() {
  username=$(git config --get user.name)
  email=$(git config --get user.email)
  signingkey=$(git config --get user.signingkey)

  if [[ -n "$username" && -n "$email" && -n "$signingkey" ]]; then
    echo "Git configuration already set:"
    echo "user.name: $username"
    echo "user.email: $email"
    echo "user.signingkey: $signingkey"
    echo "No need to reconfigure. Exiting..."
    unset username email signingkey
    return
  fi

  if [[ -n "$username" ]]; then
    echo "Username already set: $username"
  else
    # get username based on remote.origin.url
    # expected format is like: git@github.com-saltkid:saltkid/dotfiles.git
    ssh_key_id=$(git ls-remote --get-url origin | cut -d@ -f2 | cut -d: -f1)
    username=$(echo "$ssh_key_id" | cut -d- -f2-999)
    if [[ -z "$username" ]]; then
      echo "No username found in remote.origin.url (${git ls-remote --get-url origin})"
      echo 'expected format is "git@domain-username:repo_owner/repo.git" (git@github.com-saltkid:saltkid/dotfiles.git)'
      echo "Please enter a domain (github.com, gitlab.com, etc.):"
      read -r domain
      echo "Please enter a username:"
      read -r username
      ssh_key_id="$domain-$username"
    else
      echo "Username found: $username"
    fi
  fi

  if [[ -n "$email" ]]; then
    echo "Email already set: $email"
  else
    # based on username, get ssh public key since this contains the email.
    ssh_key_file="$HOME/.ssh/$ssh_key_id.pub"
    if [[ -f "$ssh_key_file" ]]; then
      email=$(tail -n 1 "$ssh_key_file" | awk '{print $NF}')
      echo "Email found: $email"
    else
      echo "No SSH public key found for $ssh_key_id. Please enter an email:"
      read -r email
    fi
  fi

  if [[ -n "$signingkey" ]]; then
    echo "Signing key already set: $signingkey"
  else
    # based on username and email, get gpg public key for signing.
    signingkey=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -B 2 "$username.*<$email>" | grep -oP 'rsa4096\/\K[A-F0-9]{16}')
    if [[ -z "$signingkey" ]]; then
      echo "No signing key found for username: '$username' with email: '$email'."
      keys=()
      i=1
      for key in $(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep "\[SC\]" | grep -oP 'rsa4096\/\K[A-F0-9]{16}'); do
        tmpuser=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -A 1 "$key" | grep -oP '(?<=\]\s)[^\s]+')
        echo "$i) $key ($tmpuser)"
        keys+=("$key")
        ((i++))
      done
      if [[ ${#keys[@]} -gt 0 ]]; then
        echo "Please select a signing key by number (1-${#keys[@]}):"
        while true; do
          read -r selected_idx
          if [[ "$selected_idx" =~ ^[0-9]+$ ]] && (( selected_idx >= 1 && selected_idx <= ${#keys[@]} )); then
            selected_idx=$((selected_idx))
            signingkey="${keys[$selected_idx]}"
            echo "Selected signing key: $signingkey"
            break
          else
            echo "Invalid selection ($selected_idx). Please enter a number between 1 and ${#keys[@]}."
          fi
        done
      else
        echo "No available GPG keys found either."
        echo "Consider manually configuring git config or setting up gpg keys."
        echo "Exiting..."
        return
      fi
    else
      echo "Signing key found: $signingkey"
    fi
  fi
  git config user.name "$username"
  git config user.email "$email"
  git config user.signingkey "$signingkey"
  unset username domain ssh_key_id email ssh_key_file signingkey keys i tmpuser selected_idx
}

function __gt_integ() {
  source gt -f
  zle accept-line
}
# }}}

# KEYBINDS {{{
zle -N __gt_integ

bindkey '^F' __gt_integ
bindkey -s '^T' 'tbg run -r -p list-3\n'
# }}}

# WSL SPECIFIC STUFF {{{

if [[ $(rg -i microsoft /proc/version) ]]; then
  if [[ $WSL_DISTRO_NAME == 'archlinux' ]]; then
    TBG_PORT=9545
  elif [[ $WSL_DISTRO_NAME == 'Debian' ]]; then
    TBG_PORT=9544
  else
    echo "WARNING: unknown wsl distro '$WSL_DISTRO_NAME'. Defaulting to port 9540"
    TBG_PORT=9540
  fi
  function __tbg_next_image() {
    tbg.exe next-image -P $TBG_PORT &>/dev/null &!
  }
  zle -N __tbg_next_image
  bindkey '^[^I' __tbg_next_image

  tbg.exe run -p $WSL_DISTRO_NAME -P $TBG_PORT &>/dev/null &!
fi

# }}}

if which fastfetch &>/dev/null; then
  fastfetch --iterm ~/Pictures/nyarch.png --logo-width 40 --logo-padding-top 1 2>/dev/null
elif which uwufetch &>/dev/null && which viu &>/dev/null; then
  uwufetch -i
fi
