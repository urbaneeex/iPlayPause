# PlayPause

Make the Mac **Play/Pause** key control the music app you actually use (YouTube Music, Spotify, TIDAL, Deezer, Amazon Music) instead of launching Apple Music.

It is a [Hammerspoon](https://www.hammerspoon.org) Spoon (a small Lua extension) with a menu bar item.

## How it behaves

The key keeps working exactly like macOS does, with one change: the Apple Music fallback.

| Situation | What happens |
| --- | --- |
| Something is in macOS *Now Playing* (a video, a podcast, your player), playing or paused | Native behavior: the key plays or pauses it |
| *Now Playing* is empty | Your chosen player opens (if closed) and starts playing instead of Apple Music |
| Feature switched off in the menu | Fully native macOS behavior, nothing intercepted |

## Requirements

- macOS (Apple Silicon or Intel)
- [Homebrew](https://brew.sh)
- Your player installed as an app. For YouTube Music see below.

## Install

```sh
brew install --cask hammerspoon
brew install nowplaying-cli

git clone https://github.com/urbaneeex/playpause-apple.git
cd playpause-apple
mkdir -p ~/.hammerspoon/Spoons
ln -s "$PWD/PlayPause.spoon" ~/.hammerspoon/Spoons/PlayPause.spoon
```

Add this to `~/.hammerspoon/init.lua` (create the file if it does not exist):

```lua
hs.loadSpoon("PlayPause")
spoon.PlayPause:start()
```

Then:

1. Open Hammerspoon.
2. Grant it **Accessibility** access: System Settings → Privacy & Security → Accessibility.
3. Quit and reopen Hammerspoon (or choose **Reload Config** from its menu bar icon).
4. In Hammerspoon's preferences, enable **Launch Hammerspoon at login**.

A ♫ icon appears in the menu bar.

## Usage

Click the menu bar icon:

- **Route Play/Pause key**: on or off. Off dims the ♫ icon and restores the native macOS behavior.
- **Players**: pick YouTube Music, Spotify, TIDAL, Deezer or Amazon Music.
- A player that is not installed shows **Install…** with the available options: **Download the Mac app** (opens the official download page) or **Install as a web app (Chrome)** (opens the web player and shows the steps).

Your choices are remembered between restarts.

## YouTube Music

YouTube Music has no native Mac app. Install it from Chrome:

1. Open <https://music.youtube.com> in Chrome.
2. Menu (⋮) → **Cast, save and share** → **Install page as app**.

The app lands in `~/Applications/Chrome Apps.localized`, which the Spoon searches.

Any player installed this way (for example Spotify from <https://open.spotify.com>) works the same: web apps are controlled with the space bar.

## Custom players

Add an entry before calling `start()`. `app` is the app name without `.app`. `toggle` is `"space"` (sends the space bar to the app) or a function:

```lua
hs.loadSpoon("PlayPause")
table.insert(spoon.PlayPause.players, {
  id = "vlc", title = "VLC", app = "VLC", toggle = "space",
})
spoon.PlayPause:start()
```

## Troubleshooting

- **Nothing happens when I press the key**: check that Hammerspoon has Accessibility access and that **Route Play/Pause key** is ticked in the menu.
- **"install nowplaying-cli" alert**: run `brew install nowplaying-cli`, then reload the config.
- **Apple Music still opens**: Hammerspoon is not running or lacks Accessibility permission.
- **It takes a few seconds to start**: the player was closed, so it has to launch and load first. It is instant while the player is open.

## Limitations

- The `"space"` toggle does nothing while a text field (for example search) has focus in the player.
- Tested with YouTube Music and Spotify, both installed as Chrome web apps. The native Spotify app and the other players are untested.
- Relies on `nowplaying-cli` to read macOS *Now Playing*.

## License

MIT, see [LICENSE](LICENSE).
