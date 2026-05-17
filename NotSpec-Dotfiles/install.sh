#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure gum is installed before running
if ! command -v gum &> /dev/null; then
    echo "❌ Error: 'gum' is required to run this installer."
    echo "   Please install it via your package manager (e.g., pacman -S gum)."
    exit 1
fi

clear

# --- 1. True Block ASCII Art & Welcome ---
gum style --foreground 39 "
  ███╗   ██╗ ██████╗ ████████╗███████╗██████╗ ███████╗ ██████╗ 
  ████╗  ██║██╔═══██╗╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔════╝ 
  ██╔██╗ ██║██║   ██║   ██║   ███████╗██████╔╝█████╗  ██║      
  ██║╚██╗██║██║   ██║   ██║   ╚════██║██╔═══╝ ██╔══╝  ██║      
  ██║ ╚████║╚██████╔╝   ██║   ███████║██║     ███████╗╚██████╗ 
  ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝     ╚══════╝ ╚═════╝ 
        ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗  
        ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝  
        ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗    
        ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝    
        ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗  
        ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝  
"
gum style --foreground 212 --bold --align center "✨ Symlink Dotfiles Installer ✨"
echo ""

# --- 2. Interactive Selection ---
gum style --foreground 45 "Select deployment steps:"
CHOICES=$(gum choose --no-limit \
    "📁 Create Destination Directories" \
    "🔗 Symlink Bash & Tool Configs (~/.config)" \
    "⚙️  Symlink Local Binaries (~/.local/bin)")

# Define target paths
CONFIG_DIR="$HOME/.config"
LOCAL_BIN_DIR="$HOME/.local/bin"
STATE_DIR="$HOME/.local/state"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""

# --- 3. Step 1: Directory Setup ---
if echo "$CHOICES" | grep -q "Create Destination Directories"; then
    gum spin --spinner line --title "Ensuring base folders exist..." -- sleep 0.5
    
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOCAL_BIN_DIR"
    mkdir -p "$STATE_DIR/bash" # Keeps your bash history out of home root
    
    gum style --foreground 82 "✔ Target directory structures verified."
fi

# --- 4. Core Symlink Function ---
link_item() {
    local source_path="$1"
    local target_path="$2"

    # If the target exists and is already linked to the right spot, do nothing
    if [ -L "$target_path" ] && [ "$(readlink -f "$target_path")" == "$(readlink -f "$source_path")" ]; then
        return
    fi

    # If something else exists there, move it to a backup file
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        mv "$target_path" "${target_path}.bak"
    fi

    # Create the symbolic link
    ln -sf "$source_path" "$target_path"
}

# --- 5. Step 2: Symlink Core Configs ---
if echo "$CHOICES" | grep -q "Symlink Bash & Tool Configs"; then
    if gum confirm "Create symlinks for your configurations?"; then
        
        # Symlink Bash files directly to home root where login expects them
        if [ -f "$REPO_DIR/config/bash/.bashrc" ]; then
            link_item "$REPO_DIR/config/bash/.bashrc" "$HOME/.bashrc"
        fi
        if [ -f "$REPO_DIR/config/bash/.bash_profile" ]; then
            link_item "$REPO_DIR/config/bash/.bash_profile" "$HOME/.bash_profile"
        fi
        
        # Symlink full application folders into ~/.config
        for app in nvim hypr waybar rofi kitty; do
            if [ -d "$REPO_DIR/config/$app" ]; then
                link_item "$REPO_DIR/config/$app" "$CONFIG_DIR/$app"
                echo "🔗 Linked: ~/.config/$app -> repo/config/$app"
            fi
        done
        
        gum style --foreground 82 "✔ All configuration symlinks established."
    else
        gum style --foreground 208 "⚠️  Skipped Symlinking Configs."
    fi
fi

# --- 6. Step 3: Symlink Local Binaries ---
if echo "$CHOICES" | grep -q "Symlink Local Binaries"; then
    if gum confirm "Symlink individual scripts into ~/.local/bin?"; then
        
        if [ -d "$REPO_DIR/local_share/bin" ]; then
            for script in "$REPO_DIR/local_share/bin"/*; do
                if [ -f "$script" ]; then
                    filename=$(basename "$script")
                    link_item "$script" "$LOCAL_BIN_DIR/$filename"
                    echo "🔗 Linked executable: ~/.local/bin/$filename"
                fi
            done
        fi
        
        gum style --foreground 82 "✔ Script symlinks established."
    else
        gum style --foreground 208 "⚠️  Skipped Script Symlinking."
    fi
fi

# --- 7. Grand Finale ---
echo ""
gum style --border double --margin "1 2" --padding "1 2" --border-foreground 39 \
    --foreground 82 "🎉 Symlinking Complete! Run 'source ~/.bashrc' to apply."
