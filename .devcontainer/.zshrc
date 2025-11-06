# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme to robbyrussell as base
ZSH_THEME="robbyrussell"

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

# Override the robbyrussell theme prompt to add Azure info
setopt PROMPT_SUBST
PROMPT='%{$fg[green]%}%n@%m%{$reset_color%} %{$fg[cyan]%}~/%{$fg[blue]%}%c%{$reset_color%} $(git_prompt_info)$(azure_account_info) ± '

# Git prompt info (from robbyrussell theme)
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}⚡ "
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✓"

# Aliases
alias ll='ls -lah'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"
