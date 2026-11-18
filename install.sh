#!/usr/bin/env bash

set -e

# Prevent running as root/sudo directly (makepkg cannot run as root)
if [ "$(id -u)" -eq 0 ]; then
    echo "❌ Error: Do not run this script directly as root or with sudo!"
    echo "Please run it as your regular user: ./install.sh"
    echo "The script will request sudo permissions when needed."
    exit 1
fi

echo "Starting Cipheroot Dotfiles Installation..."

# Detect current directory as dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Using dotfiles from: $DOTFILES_DIR"

# Ask for sudo password upfront
sudo -v

# Keep sudo alive in background and cleanly terminate loop on exit
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_LOOP_PID=$!
trap 'kill "$SUDO_LOOP_PID" 2>/dev/null || true' EXIT

# Helper function to bootstrap an AUR helper if neither yay nor paru exists
install_aur_helper() {
    echo "Neither yay nor paru was found. Automatically bootstrapping yay-bin from AUR..."
    
    # Ensure prerequisite build tools
    sudo pacman -S --needed --noconfirm base-devel git
    
    local tmp_dir
    tmp_dir="$(mktemp -d /tmp/yay-install.XXXXXX)"
    
    echo "Cloning yay-bin repository into $tmp_dir..."
    if git clone https://aur.archlinux.org/yay-bin.git "$tmp_dir"; then
        (
            cd "$tmp_dir"
            makepkg -si --noconfirm
        )
        rm -rf "$tmp_dir"
        AUR_HELPER="yay"
    else
        rm -rf "$tmp_dir"
        echo "Failed to clone yay-bin. Attempting to build yay from source..."
        tmp_dir="$(mktemp -d /tmp/yay-install.XXXXXX)"
        git clone https://aur.archlinux.org/yay.git "$tmp_dir"
        (
            cd "$tmp_dir"
            makepkg -si --noconfirm
        )
        rm -rf "$tmp_dir"
        AUR_HELPER="yay"
    fi
}

# 1. Detect or install AUR helper (yay or paru)
echo "Checking for an AUR helper (yay or paru)..."
if [ -n "$AUR_HELPER" ] && command -v "$AUR_HELPER" &> /dev/null; then
    echo "Using specified AUR helper: $AUR_HELPER"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
elif command -v paru &> /dev/null; then
    AUR_HELPER="paru"
else
    install_aur_helper
fi

if ! command -v "$AUR_HELPER" &> /dev/null; then
    echo "❌ Error: Failed to find or install an AUR helper."
    exit 1
fi
echo "Using AUR helper: $AUR_HELPER"

# Install official packages
echo "Installing official packages via pacman..."
sudo pacman -S --needed --noconfirm \
    base-devel git hyprland waybar ghostty zsh starship eza bat fzf vnstat jq \
    pipewire cava qt6-base qt6-declarative qt6-wayland python python-cryptography imagemagick \
    openssl argon2 tar coreutils age zstd lz4 brotli lzop p7zip gzip bzip2 xz curl cmake make gcc || true

# Install AUR packages
echo "Installing AUR packages via $AUR_HELPER..."
$AUR_HELPER -S --needed --noconfirm \
    quickshell catppuccin-mocha-mauve-cursors grimblast-git ueberzugpp || true

# 2. Make scripts executable
echo "Setting executable permissions..."
chmod +x "$DOTFILES_DIR"/scripts/* 2>/dev/null || true
find "$DOTFILES_DIR/hypr/scripts" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} + 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/dynamic_island/bin/* 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/dynamic_island/open-settings.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/dynamic_island/dynamic-island-config-app 2>/dev/null || true
chmod +x "$DOTFILES_DIR"/waybar/*.sh "$DOTFILES_DIR"/waybar/*.py 2>/dev/null || true

# 3. Backup helper and setup
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
BACKUP_CREATED=0

backup_item() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        # If it's already a symlink pointing to this dotfiles repository, no backup needed
        if [ -L "$target" ]; then
            local link_dest
            link_dest="$(readlink -f "$target" 2>/dev/null || true)"
            if [[ "$link_dest" == "$DOTFILES_DIR"* ]]; then
                rm -rf "$target"
                return 0
            fi
        fi

        mkdir -p "$BACKUP_DIR"
        local rel_path="${target#$HOME/}"
        local dest_path="$BACKUP_DIR/$rel_path"
        mkdir -p "$(dirname "$dest_path")"
        echo "  Backing up: $target -> $dest_path"
        mv "$target" "$dest_path"
        BACKUP_CREATED=1
    fi
}

# 4. Create config directory & symlink configurations
echo "Symlinking configurations (with safe backup)..."
mkdir -p "$HOME/.config"

for app in hypr waybar ghostty cava fastfetch; do
    if [ -d "$DOTFILES_DIR/$app" ]; then
        backup_item "$HOME/.config/$app"
        ln -sfn "$DOTFILES_DIR/$app" "$HOME/.config/$app"
        echo "  Linked: ~/.config/$app -> $DOTFILES_DIR/$app"
    fi
done

# Zsh config
if [ -d "$DOTFILES_DIR/zsh" ]; then
    backup_item "$HOME/.config/zsh"
    ln -sfn "$DOTFILES_DIR/zsh/zsh" "$HOME/.config/zsh"
    echo "  Linked: ~/.config/zsh -> $DOTFILES_DIR/zsh/zsh"
    
    if [ -f "$DOTFILES_DIR/zsh/.zsh" ]; then
        backup_item "$HOME/.zshrc"
        ln -sfn "$DOTFILES_DIR/zsh/.zsh" "$HOME/.zshrc"
        echo "  Linked: ~/.zshrc -> $DOTFILES_DIR/zsh/.zsh"

        backup_item "$HOME/.zsh"
        ln -sfn "$DOTFILES_DIR/zsh/.zsh" "$HOME/.zsh"
        echo "  Linked: ~/.zsh -> $DOTFILES_DIR/zsh/.zsh"
    fi
fi

# Starship
if [ -f "$DOTFILES_DIR/starship/starship.toml" ]; then
    backup_item "$HOME/.config/starship.toml"
    ln -sfn "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
    echo "  Linked: ~/.config/starship.toml -> $DOTFILES_DIR/starship/starship.toml"
fi

# QuickShell (Dynamic Island)
if [ -d "$DOTFILES_DIR/dynamic_island" ]; then
    mkdir -p "$HOME/.config/quickshell"
    backup_item "$HOME/.config/quickshell/dynamic_island"
    ln -sfn "$DOTFILES_DIR/dynamic_island" "$HOME/.config/quickshell/dynamic_island"
    echo "  Linked: ~/.config/quickshell/dynamic_island -> $DOTFILES_DIR/dynamic_island"
fi

# 5. Build C++ backends
echo "Building Dynamic Island C++ plugins..."
if [ -f "$DOTFILES_DIR/dynamic_island/CMakeLists.txt" ]; then
    cmake -B "$DOTFILES_DIR/dynamic_island/build" -S "$DOTFILES_DIR/dynamic_island"
    cmake --build "$DOTFILES_DIR/dynamic_island/build" -j"$(nproc 2>/dev/null || echo 2)" || true
    
    # Ensure config-app binary is in place and executable
    if [ -f "$DOTFILES_DIR/dynamic_island/build/config-app/tide-island-config-app" ]; then
        cp -f "$DOTFILES_DIR/dynamic_island/build/config-app/tide-island-config-app" "$DOTFILES_DIR/dynamic_island/dynamic-island-config-app"
        chmod +x "$DOTFILES_DIR/dynamic_island/dynamic-island-config-app" 2>/dev/null || true
    fi
elif [ -d "$DOTFILES_DIR/dynamic_island/build_backend" ]; then
    (
        cd "$DOTFILES_DIR/dynamic_island/build_backend"
        mkdir -p build && cd build
        cmake ..
        make -j"$(nproc 2>/dev/null || echo 2)" || true
    )
fi

echo ""
echo "Installation complete! 🎉"
if [ "$BACKUP_CREATED" -eq 1 ]; then
    echo "📦 Existing configurations were safely backed up to:"
    echo "   $BACKUP_DIR"
fi
echo "Note: The Omarchy framework must be installed manually at ~/.local/share/omarchy/"
echo "Please set Ghostty as your default terminal and run 'chsh -s $(which zsh)' if you haven't already."
