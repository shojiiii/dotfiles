# =========================
# Locale
# =========================
export LANG=ja_JP.UTF-8

# =========================
# Homebrew
# =========================
eval "$(/opt/homebrew/bin/brew shellenv)"

# =========================
# mise — Node / Python / Go / Java version management
# Per-project override: add .mise.toml to project root
#   e.g.  [tools]
#         java = "temurin-17"
# =========================
eval "$(mise activate zsh)"

# =========================
# Rust (rustup)
# =========================
export PATH="$HOME/.cargo/bin:$PATH"

# =========================
# uv / pipx installed scripts
# =========================
export PATH="$HOME/.local/bin:$PATH"

# =========================
# Go tools (installed via go install)
# =========================
export PATH="$PATH:$HOME/go/bin"

# =========================
# Build flags (for native extension compilation)
# =========================
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"

# =========================
# gcloud
# =========================
export PATH="$PATH:$HOME/google-cloud-sdk/bin"

# =========================
# mysql-client
# =========================
export PATH="$PATH:/opt/homebrew/opt/mysql-client/bin"

# =========================
# Oh My Zsh
# =========================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="cobalt2"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)
source "$ZSH/oh-my-zsh.sh"

# =========================
# History
# =========================
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

# =========================
# Completion
# =========================
autoload -Uz compinit
compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:processes' command 'ps x -o pid,s,args'

if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion zsh)
  compdef _kubectl k
fi

if command -v gcloud >/dev/null 2>&1; then
  GCLOUD_SDK_ROOT="$(gcloud info --format='value(installation.sdk_root)' 2>/dev/null)"
  [ -n "$GCLOUD_SDK_ROOT" ] && [ -f "$GCLOUD_SDK_ROOT/completion.zsh.inc" ] && \
    source "$GCLOUD_SDK_ROOT/completion.zsh.inc"
fi

if command -v terraform >/dev/null 2>&1; then
  autoload -U +X bashcompinit && bashcompinit
  complete -o nospace -C terraform terraform
fi

# =========================
# Shell options
# =========================
setopt print_eight_bit
setopt no_beep
setopt ignore_eof
setopt interactive_comments
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt share_history
setopt extended_glob

# =========================
# Aliases
# =========================
alias ls='ls -FG'
alias ll='ls -alFG'
alias g='git'
alias c='clear'
alias k='kubectl'
alias tf='terraform'
alias rand='cat /dev/urandom | base64 | fold -w 16 | head -n 1'

alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kctx='kubectl config use-context'

alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'

alias release='(){ git tag $1; git push origin $1; gh release create $1 --title $1 }'

# =========================
# peco history search
# =========================
function peco-select-history() {
  local tac_cmd
  if command -v tac >/dev/null 2>&1; then
    tac_cmd="tac"
  else
    tac_cmd="tail -r"
  fi
  BUFFER=$(history -n 1 | eval "$tac_cmd" | peco --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

# =========================
# gcloud config switcher (gx)
# =========================
function gcloud-activate() {
  local name="$1"
  echo "gcloud config configurations activate \"${name}\""
  gcloud config configurations activate "${name}"
}

function gx-complete() {
  _values $(gcloud config configurations list 2>/dev/null | awk 'NR>1 {print $1}')
}

function gx() {
  local name="$1"
  local line project
  if [ -z "$name" ]; then
    line=$(gcloud config configurations list 2>/dev/null | peco)
    name=$(echo "$line" | awk '{print $1}')
  else
    line=$(gcloud config configurations list 2>/dev/null | grep "$name")
  fi
  project=$(echo "$line" | awk '{print $4}')
  gcloud-activate "$name" "$project"
}

compdef gx-complete gx
compdef g=git

# =========================
# direnv / zoxide
# =========================
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# =========================
# Puppeteer
# =========================
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH="/opt/homebrew/bin/chromium"

# =========================
# Machine-specific / project env vars
# (cursor aliases, GCP project IDs, secrets, etc.)
# =========================
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
