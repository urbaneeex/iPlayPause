#!/bin/bash
# PlayPause uninstaller: removes the Spoon and its lines from init.lua.
# Hammerspoon and nowplaying-cli are left installed.
# Usage: curl -fsSL https://raw.githubusercontent.com/urbaneeex/playpause-apple/main/uninstall.sh | bash
set -euo pipefail

HS_DIR="$HOME/.hammerspoon"
INIT="$HS_DIR/init.lua"

rm -rf "$HS_DIR/Spoons/PlayPause.spoon"
if [ -f "$INIT" ]; then
  sed -i '' -e '/hs\.loadSpoon("PlayPause")/d' -e '/spoon\.PlayPause:start()/d' "$INIT"
fi

if pgrep -x Hammerspoon >/dev/null 2>&1; then
  pkill -x Hammerspoon
  sleep 1
  open -a Hammerspoon
fi

echo "PlayPause removed. The Play/Pause key is back to the macOS default."
echo "To remove the rest: brew uninstall --cask hammerspoon && brew uninstall nowplaying-cli"
