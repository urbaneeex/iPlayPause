#!/bin/bash
# iPlayPause installer: sets up Homebrew (if missing), Hammerspoon,
# nowplaying-cli and the Spoon.
# Usage: curl -fsSL https://raw.githubusercontent.com/urbaneeex/iPlayPause/main/install.sh | bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/urbaneeex/iPlayPause/main"
HS_DIR="$HOME/.hammerspoon"
SPOON_DIR="$HS_DIR/Spoons/iPlayPause.spoon"
INIT="$HS_DIR/init.lua"

# Homebrew may be installed but missing from PATH in a non-login shell
load_brew() {
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
}

if ! command -v brew >/dev/null 2>&1 && ! load_brew; then
  echo "Installing Homebrew (it will ask for your Mac password)..."
  # Read from the terminal: this script's own stdin is the curl pipe
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
  if ! load_brew; then
    echo "Homebrew could not be installed. Install it from https://brew.sh and run this again." >&2
    exit 1
  fi
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
  echo "iPlayPause.spoon is a symlink, keeping it."
else
  echo "Installing the iPlayPause Spoon..."
  mkdir -p "$SPOON_DIR"
  curl -fsSL "$REPO_RAW/iPlayPause.spoon/init.lua" -o "$SPOON_DIR/init.lua"
fi

mkdir -p "$HS_DIR"
if [ ! -f "$INIT" ]; then
  # New Hammerspoon setup: also start at login and stay out of the Dock
  cat > "$INIT" <<'LUA'
hs.autoLaunch(true)
hs.dockIcon(false)

hs.loadSpoon("iPlayPause")
spoon.iPlayPause:start()
LUA
elif ! grep -q 'loadSpoon("iPlayPause")' "$INIT"; then
  printf '\nhs.loadSpoon("iPlayPause")\nspoon.iPlayPause:start()\n' >> "$INIT"
fi

# Restart Hammerspoon so it picks up the Spoon
pkill -x Hammerspoon 2>/dev/null || true
sleep 1
open -a Hammerspoon

echo
echo "iPlayPause is installed."
if [ "$fresh_hammerspoon" = true ]; then
  open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
  echo "One step left: enable Hammerspoon under Accessibility in the System Settings"
  echo "window that just opened, then run:  open -a Hammerspoon"
else
  echo "If the key does nothing, enable Hammerspoon in System Settings →"
  echo "Privacy & Security → Accessibility."
fi
