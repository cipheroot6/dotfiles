# Navigation
alias home="cd ~"
alias trash="cd ~/.trash"
alias aliass="nvim ~/.config/zsh/aliases.zsh"

# Zsh config
alias zsh="nvim ~/.zshrc"
alias catz="cat ~/.zshrc"
alias s="source ~/.zshrc"

# File manager
alias fm="nautilus . &"

# System
alias gparted="sudo WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000 gparted"

# Development
alias run="npm run dev"
alias py="python"

# CLI replacements
alias neofetch="fastfetch"

alias ls="eza --icons --group-directories-first"
alias ll="eza -lah --icons --git"
alias tree="eza --tree --icons"

# git
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"

# Custom
alias falias="alias | fzf"
alias h="history | fzf"
alias oc="opencode"
alias fr="cd frontend"
alias bc="cd backend"
alias rfr="cd frontend && npm i && run"
alias rbc="cd backend && npm i && run"
alias fzf='nvim $(fzf --preview="bat --color=always {}")'
alias wallpaper='cd /home/cipheroot/.config/omarchy/backgrounds/ayaka'
alias fff=nvim\ /home/cipheroot/.config/fastfetch/config.jsonc
alias kw='kwybars-daemon'
alias pacman='sudo pacman'
alias i='sudo pacman -S '
alias r='sudo pacman -Rns'
alias icat='chafa'
alias qwen='ollama run jaahas/qwen3.5-uncensored:2b'
alias mount='sudo ~/.mount.sh'
alias kali=' ssh cipheroot@192.168.1.48 -y'
alias ff='/home/cipheroot/allcode/dotfiles/scripts/fuzyfinder.sh'
alias phone='ssh -p 8022 u0_a341@100.123.21.124 -y'
alias ub='ssh cipheroot@192.168.1.35 -y'
alias nd='cd frontend && rm -rf node_modules && cd .. && cd backend && rm -rf node_modules && cd ..'
