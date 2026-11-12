# PlayPause

Make the Mac **Play/Pause** key control the music app you actually use (YouTube Music, Spotify, TIDAL, Deezer, Amazon Music) instead of launching Apple Music.

It is a [Hammerspoon](https://www.hammerspoon.org) Spoon (a small Lua extension) with a menu bar item.

## How it behaves

The key keeps working exactly like macOS does, with one change: the Apple Music fallback.

| Situation | What happens |
| --- | --- |
| Something is in macOS *Now Playing* (a video, a podcast, your player), playing or paused | Native behavior: the key plays or pauses it |
| *Now Playing* is empty | Your chosen player starts playing instead of Apple Music |
| Feature switched off in the menu | Fully native macOS behavior, nothing intercepted |

To make the first press instant, the chosen player is opened in the background when Hammerspoon starts, played briefly and paused. From then on it sits in *Now Playing* like any native player. This is the **Keep player open in background** option (on by default).

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

A ▶︎ icon appears in the menu bar.

## Usage

Click the menu bar icon:

- **Route Play/Pause key**: on (▶︎) or off (▷). Off restores the native macOS behavior.
- **Keep player open in background**: keeps the player ready for an instant response.
- **Players**: pick YouTube Music, Spotify, TIDAL, Deezer or Amazon Music. Players that are not installed are greyed out.

Your choices are remembered between restarts.

## YouTube Music

YouTube Music has no native Mac app. Install it from Chrome:

1. Open <https://music.youtube.com> in Chrome.
2. Menu (⋮) → **Cast, save and share** → **Install page as app**.

The app lands in `~/Applications/Chrome Apps.localized`, which the Spoon searches.

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

- **Nothing happens when I press the key**: check that Hammerspoon has Accessibility access and that the menu shows ▶︎, not ▷.
- **"install nowplaying-cli" alert**: run `brew install nowplaying-cli`, then reload the config.
- **Apple Music still opens**: Hammerspoon is not running or lacks Accessibility permission.
- **The first press after startup is slow**: the player was closed. Keep **Keep player open in background** enabled and do not quit the player with ⌘Q.

## Limitations

- The `"space"` toggle does nothing while a text field (for example search) has focus in the player.
- Only YouTube Music has been tested. The other players are untested.
- Relies on `nowplaying-cli` to read macOS *Now Playing*.

## License

MIT, see [LICENSE](LICENSE).
