#!/usr/bin/env bash

# Define paths (Creating the target folder if it doesn't exist)
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/screenshot_$(date +%Y%m%d_%H%M%S).png"

# Run grim and slurp together for region selection
if slurp | grim -g - "$FILE"; then
    # Copy to clipboard and send a clean system notification
    wl-copy < "$FILE"
    notify-send "📸 Screenshot Captured" "Saved to ~/Pictures/Screenshots\nand copied to clipboard!" -i image-x-generic
else
    # Handle user canceling the screenshot (hitting Escape)
    notify-send "Screenshot Canceled" "No region selected." -i dialog-information
fi
