require("hs.ipc")
hs.ipc.cliInstall("/opt/homebrew")

-- Support upcoming 5.4 release and also use luarocks' local path
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.4/?.lua;" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.4/?/init.lua"
package.cpath = package.cpath .. ";" .. os.getenv("HOME") .. "/.luarocks/lib/lua/5.4/?.so"
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.3/?.lua;" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.3/?/init.lua"
package.cpath = package.cpath .. ";" .. os.getenv("HOME") .. "/.luarocks/lib/lua/5.3/?.so"

package.path = package.path .. ";" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.3/?.lua;" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.3/?/init.lua"

-- User Dev & Test Spoon
package.path = package.path .. ";" .. hs.configdir .. "/TSpoons/?.spoon/init.lua"

fennel = require("fennel")
spoon = require("hs.spoons")
table.insert(package.loaders or package.searchers, fennel.searcher)

core = require "core"

require 'luarocks.loader'

-------------------------------------------------
require "extensions"
require "modules.customModule"
require "plugins.sbar.helpers"

local uielement = require("hs.libuielement")
uielement.watcher = require("hs.libuielementwatcher")
local appWatcher = require "hs.application.watcher"


------------ Console Setting -------------------
-- hs.consoleOnTop(true)
hs.logger.defaultLogLevel = 'debug'

--------------- sketchybar load -------------------
sbar = require("sketchybar")

------------ elogger Setting -------------------
Elogger = require("elogger")
Elogger.setGlobalConfig({
    traceLogLevel = Elogger.toLogLevel("verbose"),
    debugLogLevel = Elogger.toLogLevel("verbose")
})

hs.loadSpoon("FocusHighlight")
spoon.FocusHighlight:start()
spoon.FocusHighlight.color = "#E9FF21"
spoon.FocusHighlight.windowFilter = hs.window.filter.default
spoon.FocusHighlight.arrowSize = 256
spoon.FocusHighlight.arrowFadeOutDuration = 1
spoon.FocusHighlight.highlightFadeOutDuration = 1.25
spoon.FocusHighlight.highlightFillAlpha = 0.01

-- local trackPadKeys = hs.loadSpoon("TrackpadKeys")

-- hs.hotkey.bind({"fn", "cmd"}, "\\", function()
--     hs.alert("TrackPad Key")
--     trackPadKeys.toggle()
-- end)

local hotkeyTools = hs.loadSpoon("HotkeyTools")
-- hs.hotkey.bind({"cmd", "shift"}, "\\", function()
--     hotkeyTools.toggle()
-- end)
-- hs.hotkey.bind(hyper, "S", function()
--   hs.window.focusedWindow():moveToScreen(cycleScreens())
-- end)
print("Capture Keys --")
-- captureKeys(1, function(firstKey)
--   print(firstKey)
-- end)
--
-- captureKeys(1, function(keys)
--     for _, key in ipairs(keys) do
--         print(key)
--     end
-- end)

-- for _, key in ipairs(hs.settings.getKeys()) do
--     dbg(key)
-- end

-- WinWin = hs.loadSpoon("WinWin")
-- hs.hotkey.bind({"ctrl", "alt"}, "left", function()
--     WinWin:stepMove("left")
-- end)
-- hs.hotkey.bind({"ctrl", "alt"}, "right", function()
--     WinWin:stepMove("right")
-- end)

-- hs.hotkey.bind({"cmd", "shift"}, "/", function()
--     WinWin:stepMove("right")
-- end)

hs.loadSpoon('SpoonInstall')
spoon.SpoonInstall:andUse('ModalMgr')

-- spoon.ModalMgr.supervisor:bind('alt', 'L', 'Lock Screen', function() hs.caffeinate.lockScreen() end)
spoon.ModalMgr.supervisor:bind('alt', 'Z', 'Toggle Hammerspoon Console', function() hs.toggleConsole() end)

require("YabaiM")

spoon.ModalMgr.supervisor:enter()

KSheet = hs.loadSpoon("KSheet")
hs.hotkey.bind({"alt", "shift"}, "\\", function()
KSheet:toggle()
end)

-- dbg(package.path)
Sbar = hs.loadSpoon('SBar')
-- hs.keycodes.inputSourceChanged(function ()
    -- Sbar:show_input_source()
-- end)

-- hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
--     local keyCode = e:getKeyCode()
--     dbg(keyCode)
--     dbg(e)
-- end):start()

-- EnhancedSpaces = hs.loadSpoon('EnhancedSpaces')
-- EnhancedSpaces:new({
--   mSpaces = { '1', '2', '3', 'E', 'T' }, -- default { '1', '2', '3' }
--   startmSpace = 'E', -- default 2
-- })

-- AutoHotKeys = hs.loadSpoon('AutoHotKeys')

-- function setWindowTransparency(appName, opacity)
--     local script = string.format([[
--         tell application "System Events"
--             set frontApp to first process whose name is "%s"
--             tell frontApp
--                 set alpha value to %f
--             end tell
--         end tell
--     ]], appName, opacity)
--
--     hs.osascript.applescript(script)
-- end
--
-- setWindowTransparency("Finder", 0.5) -- Finder 창을 50% 투명하게 설정

print("### Loding Completed. ###")

hs.alert.show("Spacehammer config loaded")
hs.notify.show("HS Config Loding Completed.","","") -- undecided on this line

