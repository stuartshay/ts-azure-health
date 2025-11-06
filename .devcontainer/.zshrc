# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme to agnoster
ZSH_THEME="agnoster"

# Disable auto-update prompts
DISABLE_AUTO_UPDATE=true
DISABLE_UPDATE_PROMPT=true

# Plugins
plugins=(git docker azure npm node)

source $ZSH/oh-my-zsh.sh

# Custom prompt configuration
autoload -U colors && colors

# Function to get Azure account info
function azure_account_info() {
  if command -v az &> /dev/null; then
    local account=$(az account show --query name -o tsv 2>/dev/null)
    if [[ -n "$account" ]]; then
      echo " %{$fg[yellow]%}☁ $account%{$reset_color%}"
    fi
  fi
}

# Add Azure info to agnoster prompt
prompt_azure() {
  if command -v az &> /dev/null; then
    local account=$(az account show --query name -o tsv 2>/dev/null)
    if [[ -n "$account" ]]; then
      prompt_segment yellow black "☁ $account"
    fi
  fi
}

# Override agnoster build_prompt to include Azure
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_azure
  prompt_end
}

# Aliases
alias ll='ls -lah'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"
