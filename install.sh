#!/bin/bash
# PlayPause installer: sets up Hammerspoon, nowplaying-cli and the Spoon.
# Usage: curl -fsSL https://raw.githubusercontent.com/urbaneeex/playpause-apple/main/install.sh | bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/urbaneeex/playpause-apple/main"
HS_DIR="$HOME/.hammerspoon"
SPOON_DIR="$HS_DIR/Spoons/PlayPause.spoon"
INIT="$HS_DIR/init.lua"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it from https://brew.sh and run this again." >&2
  exit 1
fi

fresh_hammerspoon=false
if [ ! -d "/Applications/Hammerspoon.app" ]; then
  echo "Installing Hammerspoon..."
  brew install --cask hammerspoon
  fresh_hammerspoon=true
fi

if ! command -v nowplaying-cli >/dev/null 2>&1; then
  echo "Installing nowplaying-cli..."
  brew install nowplaying-cli
fi

# A symlinked Spoon is a development checkout: leave it alone
if [ -L "$SPOON_DIR" ]; then
  echo "PlayPause.spoon is a symlink, keeping it."
else
  echo "Installing the PlayPause Spoon..."
  mkdir -p "$SPOON_DIR"
  curl -fsSL "$REPO_RAW/PlayPause.spoon/init.lua" -o "$SPOON_DIR/init.lua"
fi

mkdir -p "$HS_DIR"
if [ ! -f "$INIT" ]; then
  # New Hammerspoon setup: also start at login and stay out of the Dock
  cat > "$INIT" <<'LUA'
hs.autoLaunch(true)
hs.dockIcon(false)

hs.loadSpoon("PlayPause")
spoon.PlayPause:start()
LUA
elif ! grep -q 'loadSpoon("PlayPause")' "$INIT"; then
  printf '\nhs.loadSpoon("PlayPause")\nspoon.PlayPause:start()\n' >> "$INIT"
fi

# Restart Hammerspoon so it picks up the Spoon
pkill -x Hammerspoon 2>/dev/null || true
sleep 1
open -a Hammerspoon

echo
echo "PlayPause is installed."
if [ "$fresh_hammerspoon" = true ]; then
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
  echo "One step left: enable Hammerspoon under Accessibility in the System Settings"
  echo "window that just opened, then run:  open -a Hammerspoon"
else
  echo "If the key does nothing, enable Hammerspoon in System Settings →"
  echo "Privacy & Security → Accessibility."
fi
