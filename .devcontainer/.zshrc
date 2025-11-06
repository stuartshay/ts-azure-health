# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme to minimal for customization
ZSH_THEME=""

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
      echo "[Az: $account]"
    fi
  fi
}

# Function to get git branch
function git_branch_name() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    echo "[$branch]"
  fi
}

# Custom PowerShell-style prompt
setopt PROMPT_SUBST

# Two-line PowerShell-style prompt
# Line 1: PS /path [branch] [Az: account]
# Line 2: PS /path [branch] [Az: account] PS>
PROMPT='%{$fg[cyan]%}PS%{$reset_color%} %{$fg[yellow]%}%~%{$reset_color%} %{$fg[green]%}$(git_branch_name)%{$reset_color%} %{$fg[cyan]%}$(azure_account_info)%{$reset_color%}
%{$fg[cyan]%}PS%{$reset_color%} %{$fg[yellow]%}%~%{$reset_color%} %{$fg[green]%}$(git_branch_name)%{$reset_color%} %{$fg[cyan]%}$(azure_account_info)%{$reset_color%} %{$fg[cyan]%}PS>%{$reset_color%} '

# Aliases
alias ll='ls -lah'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"
