#!/usr/bin/env bash

set -e

echo "Starting Cipheroot Dotfiles Installation..."

# Detect current directory as dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Using dotfiles from: $DOTFILES_DIR"

# 1. Install dependencies
echo "Installing dependencies (Requires yay)..."
if ! command -v yay &> /dev/null; then
    echo "yay is not installed. Please install yay first."
    exit 1
fi

# Ask for sudo password upfront
sudo -v

# Keep sudo alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

sudo pacman -S --needed --noconfirm \
    hyprland waybar ghostty zsh starship eza bat fzf vnstat jq \
    pipewire cava qt6-base qt6-declarative qt6-wayland python python-cryptography imagemagick \
    openssl argon2 tar coreutils age zstd lz4 brotli lzop p7zip gzip bzip2 xz curl cmake make gcc || true

yay -S --needed --noconfirm \
    quickshell catppuccin-mocha-mauve-cursors grimblast-git ueberzugpp || true

# 2. Make scripts executable
echo "Setting executable permissions..."
chmod +x "$DOTFILES_DIR/scripts/enc" "$DOTFILES_DIR/scripts/dec" 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/hypr/scripts/*.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/dynamic_island/bin/* 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/waybar/scripts/* 2>/dev/null || true

# 3. Create config directory
mkdir -p "$HOME/.config"

# 4. Symlink configurations
echo "Symlinking configurations..."
for app in hypr waybar ghostty cava fastfetch; do
    if [ -d "$DOTFILES_DIR/$app" ]; then
        rm -rf "$HOME/.config/$app"
        ln -sfn "$DOTFILES_DIR/$app" "$HOME/.config/$app"
    fi
done

# Zsh config
if [ -d "$DOTFILES_DIR/zsh" ]; then
    rm -rf "$HOME/.config/zsh"
    ln -sfn "$DOTFILES_DIR/zsh/zsh" "$HOME/.config/zsh"
    
    rm -rf "$HOME/.zsh"
    if [ -d "$DOTFILES_DIR/zsh/.zsh" ]; then
        ln -sfn "$DOTFILES_DIR/zsh/.zsh" "$HOME/.zsh"
    fi
fi

# Starship
if [ -f "$DOTFILES_DIR/starship/starship.toml" ]; then
    ln -sfn "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
fi

# QuickShell (Dynamic Island)
if [ -d "$DOTFILES_DIR/dynamic_island" ]; then
    mkdir -p "$HOME/.config/quickshell"
    rm -rf "$HOME/.config/quickshell/dynamic_island"
    ln -sfn "$DOTFILES_DIR/dynamic_island" "$HOME/.config/quickshell/dynamic_island"
fi

# 5. Build C++ backends
echo "Building Dynamic Island C++ plugins..."
if [ -d "$DOTFILES_DIR/dynamic_island/build_backend" ]; then
    cd "$DOTFILES_DIR/dynamic_island/build_backend"
    mkdir -p build
    cd build
    cmake ..
    make
fi

echo ""
echo "Installation complete! 🎉"
echo "Note: The Omarchy framework must be installed manually at ~/.local/share/omarchy/"
echo "Please set Ghostty as your default terminal and run 'chsh -s $(which zsh)' if you haven't already."
