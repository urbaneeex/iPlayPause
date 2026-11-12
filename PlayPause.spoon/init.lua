--- === PlayPause ===
---
--- Route the Play/Pause media key to the music app of your choice instead of
--- Apple Music. macOS behavior is untouched while something is already
--- queued, so videos and other apps still react to the key natively.
---
--- Requires `nowplaying-cli` (brew install nowplaying-cli).

local obj = {}
obj.__index = obj

obj.name = "PlayPause"
obj.version = "0.1.0"
obj.license = "MIT"

local SETTING_ENABLED = "PlayPause.enabled"
local SETTING_PLAYER = "PlayPause.player"

--- PlayPause.players
--- Variable
--- Known players, in menu order. Add your own before calling `start()`:
--- `app` is the .app name (without extension), `toggle` is either "space"
--- (sends the space bar to the app) or a function(app) that toggles playback.
--- `download` (native Mac app page) and `web` (web player to install from the
--- browser as an app) are optional and feed the menu's install options.
obj.players = {
  {
    id = "ytmusic",
    title = "YouTube Music",
    app = "YouTube Music",
    toggle = "space",
    web = "https://music.youtube.com",
  },
  {
    id = "spotify",
    title = "Spotify",
    app = "Spotify",
    toggle = function()
      hs.osascript.applescript('tell application "Spotify" to playpause')
    end,
    download = "https://www.spotify.com/download/mac/",
    web = "https://open.spotify.com",
  },
  {
    id = "tidal",
    title = "TIDAL",
    app = "TIDAL",
    toggle = "space",
    download = "https://tidal.com/download",
    web = "https://listen.tidal.com",
  },
  {
    id = "deezer",
    title = "Deezer",
    app = "Deezer",
    toggle = "space",
    download = "https://www.deezer.com/download",
    web = "https://www.deezer.com",
  },
  {
    id = "amazonmusic",
    title = "Amazon Music",
    app = "Amazon Music",
    toggle = "space",
    web = "https://music.amazon.com",
  },
}

local SEARCH_DIRS = {
  "/Applications",
  os.getenv("HOME") .. "/Applications",
  os.getenv("HOME") .. "/Applications/Chrome Apps.localized",
}

local function findAppPath(name)
  for _, dir in ipairs(SEARCH_DIRS) do
    local path = dir .. "/" .. name .. ".app"
    if hs.fs.attributes(path) then return path end
  end
end

local function findNowPlayingCli()
  for _, path in ipairs({ "/opt/homebrew/bin/nowplaying-cli", "/usr/local/bin/nowplaying-cli" }) do
    if hs.fs.attributes(path) then return path end
  end
end

local function bundleIDOf(path)
  local info = hs.application.infoForBundlePath(path)
  return info and info.CFBundleIdentifier
end

function obj:_currentPlayer()
  for _, player in ipairs(self.players) do
    if player.id == self.playerID then return player end
  end
end

-- Read one Now Playing field. nowplaying-cli answers in ~0.1s when something
-- is queued but hangs for ~3s when nothing is, so it is cut off early: no
-- answer in time means an empty queue.
local LOOKUP_TIMEOUT_US = 250000

function obj:_nowPlaying(field)
  local cmd = string.format(
    "/usr/bin/perl -MTime::HiRes=ualarm -e 'ualarm %d; exec @ARGV' %s get %s",
    LOOKUP_TIMEOUT_US, self.nowplaying, field
  )
  return (hs.execute(cmd):gsub("%s+$", ""))
end

-- True when macOS has a Now Playing item, even a paused one. That is the
-- "queue" the native key resumes before ever falling back to Apple Music.
function obj:_hasQueue()
  local title = self:_nowPlaying("title")
  return title ~= "" and title ~= "null"
end

-- True when any app is currently playing media
function obj:_isPlaying()
  return (tonumber(self:_nowPlaying("playbackRate")) or 0) > 0
end

-- Browser-installed web apps (Chrome, Edge, Brave) are not scriptable, so
-- they always get the space bar, whatever the player's native toggle is.
local function isWebApp(app)
  local id = app:bundleID() or ""
  return id:find("^com%.google%.Chrome%.app%.") ~= nil
    or id:find("^com%.microsoft%.edgemac%.app%.") ~= nil
    or id:find("^com%.brave%.Browser%.app%.") ~= nil
end

local function toggle(player, app)
  if type(player.toggle) == "function" and not isWebApp(app) then
    player.toggle(app)
  else
    hs.eventtap.event.newKeyEvent("space", true):post(app)
    hs.eventtap.event.newKeyEvent("space", false):post(app)
  end
end

-- Launch the player and press play as soon as it accepts it. The page ignores
-- key presses until it has loaded and gives no signal when it is ready, so
-- the toggle is retried until playback is reported. An accepted toggle shows
-- up within ~0.7s; if a slow start makes a retry pause it again, the next
-- retry resumes it.
local RETRY_SECONDS = 1.0
local GIVE_UP_SECONDS = 30

function obj:_launchAndPlay(player, bundleID)
  hs.application.launchOrFocusByBundleID(bundleID)
  local started, lastSent = hs.timer.secondsSinceEpoch(), nil
  -- Keep a reference: an unreferenced timer is garbage collected mid-wait
  if self.launchTimer then self.launchTimer:stop() end
  self.launchTimer = hs.timer.doEvery(0.1, function(timer)
    local now = hs.timer.secondsSinceEpoch()
    if now - started > GIVE_UP_SECONDS then timer:stop() return end
    local app = hs.application.get(bundleID)
    if not (app and app:mainWindow()) then return end
    if self:_isPlaying() then timer:stop() return end
    if not lastSent or now - lastSent >= RETRY_SECONDS then
      toggle(player, app)
      lastSent = hs.timer.secondsSinceEpoch()
    end
  end)
end

function obj:_takeOver()
  local player = self:_currentPlayer()
  local path = player and findAppPath(player.app)
  local bundleID = path and bundleIDOf(path)
  if not bundleID then
    hs.alert.show(player and (player.title .. " is not installed") or "No player selected")
    return
  end
  local app = hs.application.get(bundleID)
  if not app then
    self:_launchAndPlay(player, bundleID)
    return
  end
  -- Key events do not reach a hidden app, so show it first
  local wasHidden = app:isHidden()
  if wasHidden then app:unhide() end
  hs.timer.doAfter(wasHidden and 0.15 or 0, function() toggle(player, app) end)
end

function obj:_onKey(event)
  local data = event:systemKey()
  if not (data and data.key == "PLAY") then return false end

  -- Decide once per press, on key down; key up and repeats reuse the decision
  -- so the Now Playing lookup never delays the key twice.
  if data.down and not data["repeat"] then
    -- Something is queued (playing or paused): keep native behavior
    self.passThrough = self:_hasQueue()
    if not self.passThrough then self:_takeOver() end
  end
  -- Swallow the event when we took over, so Apple Music never sees it
  return self.passThrough == false
end

local CHROME_ID = "com.google.Chrome"

-- Open the web player in Chrome and tell the user how to install it as an app
local function installWebApp(player)
  if hs.application.pathForBundleID(CHROME_ID) then
    hs.urlevent.openURLWithBundle(player.web, CHROME_ID)
  else
    hs.urlevent.openURL(player.web)
  end
  hs.alert.show(
    "To install " .. player.title .. ": in Chrome open the ⋮ menu → Cast, save and share → Install page as app",
    10
  )
end

-- Install options for a player that is not installed
local function installMenu(player)
  local items = {}
  if player.download then
    table.insert(items, {
      title = "Download the Mac app",
      fn = function() hs.urlevent.openURL(player.download) end,
    })
  end
  if player.web then
    table.insert(items, {
      title = "Install as a web app (Chrome)",
      fn = function() installWebApp(player) end,
    })
  end
  return items
end

function obj:_refreshMenubar()
  -- Dimmed note while switched off
  self.menubar:setTitle(hs.styledtext.new("♫", {
    font = { size = 15 },
    color = { white = 0.5, alpha = self.enabled and 1 or 0.45 },
  }))
  self.menubar:setMenu(function()
    local items = {
      {
        title = "Route Play/Pause key",
        checked = self.enabled,
        fn = function() self:setEnabled(not self.enabled) end,
      },
      { title = "-" },
    }
    for _, player in ipairs(self.players) do
      if findAppPath(player.app) then
        table.insert(items, {
          title = player.title,
          checked = player.id == self.playerID,
          fn = function() self:setPlayer(player.id) end,
        })
      else
        local install = installMenu(player)
        table.insert(items, {
          title = player.title .. " — Install…",
          disabled = #install == 0,
          menu = #install > 0 and install or nil,
        })
      end
    end
    return items
  end)
end

--- PlayPause:setEnabled(enabled)
--- Method
--- Turn the routing on or off. Off restores the native macOS behavior.
function obj:setEnabled(enabled)
  self.enabled = enabled
  hs.settings.set(SETTING_ENABLED, enabled)
  if enabled then self.tap:start() else self.tap:stop() end
  self:_refreshMenubar()
end

--- PlayPause:setPlayer(id)
--- Method
--- Choose the player (an `id` from `PlayPause.players`).
function obj:setPlayer(id)
  self.playerID = id
  hs.settings.set(SETTING_PLAYER, id)
  self:_refreshMenubar()
end

--- PlayPause:start()
--- Method
--- Create the menu bar item and start intercepting the key (if enabled).
function obj:start()
  self.nowplaying = findNowPlayingCli()
  if not self.nowplaying then
    hs.alert.show("PlayPause: install nowplaying-cli (brew install nowplaying-cli)", 6)
    return self
  end

  local enabled = hs.settings.get(SETTING_ENABLED)
  self.enabled = enabled == nil and true or enabled
  self.playerID = hs.settings.get(SETTING_PLAYER) or self.players[1].id

  self.tap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, function(event)
    return self:_onKey(event)
  end)
  self.menubar = hs.menubar.new()
  self:setEnabled(self.enabled)
  return self
end

--- PlayPause:stop()
--- Method
--- Stop intercepting and remove the menu bar item.
function obj:stop()
  if self.tap then self.tap:stop() end
  if self.menubar then self.menubar:delete() self.menubar = nil end
  return self
end

return obj
