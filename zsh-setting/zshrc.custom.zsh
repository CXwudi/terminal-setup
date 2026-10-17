# Merge section 1 before Oh My Zsh initialization in the generated ~/.zshrc.
# Keep Powerlevel10k's generated instant-prompt block near the top of that file.

# Section 1: before source "$ZSH/oh-my-zsh.sh".
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
  git z dirhistory fzf aliases docker docker-compose common-aliases
  zsh-syntax-highlighting zsh-autosuggestions ohmyzsh-full-autoupdate
)

# Section 2: after source "$ZSH/oh-my-zsh.sh".
unsetopt NOMATCH
alias ls='lsd'
[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"

# Activate project tools and environment in interactive shells.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
