require("hs.ipc")
hs.ipc.cliInstall("/opt/homebrew")

hs.console.clearConsole()

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
-- print("Capture Keys --")
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

KSheet = hs.loadSpoon("KSheet")
hs.hotkey.bind({"alt", "shift"}, "\\", function()
KSheet:toggle()
end)

-- dbg(package.path)
Sbar = hs.loadSpoon('SBar')


-- EnhancedSpaces = hs.loadSpoon('EnhancedSpaces')
-- EnhancedSpaces:new({
--   mSpaces = { '1', '2', '3', 'E', 'T' }, -- default { '1', '2', '3' }
--   startmSpace = 'E', -- default 2
-- })

AutoHotKeys = hs.loadSpoon('AutoHotKeys')
hs.hotkey.bind({"shift", "cmd"}, "k", function()
    AutoHotKeys:menuToggle()
end)


-- ExampleToolbar Spoon 로드 및 시작
ExampleToolbar = hs.loadSpoon('ExampleToolbar')
if ExampleToolbar then
    ExampleToolbar:start()
    hs.printf("ExampleToolbar loaded and started. Press Alt+Shift+W to toggle.\n")
else
    hs.printf("ERROR: ExampleToolbar failed to load!\n")
end
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

-- https://github.com/mogenson/PaperWM.spoon
-- use three finger swipe to focus nearby window
-- https://github.com/mogenson/Swipe.spoon
-- Swipe = hs.loadSpoon("Swipe")

-- Swipe:start(4, function(direction, distance, id)
--     if id == current_id then
--         if distance > threshold then
--             threshold = math.huge -- trigger once per swipe

--             -- use "natural" scrolling
--             if direction == "left" then
--                 actions.focus_right()
--             elseif direction == "right" then
--                 actions.focus_left()
--             elseif direction == "up" then
--                 actions.focus_down()
--             elseif direction == "down" then
--                 actions.focus_up()
--             end
--         end
--     else
--         current_id = id
--         threshold = 0.2 -- swipe distance > 20% of trackpad size
--     end
-- end)

-- https://github.com/mogenson/ActiveSpace.spoon
-- ActiveSpace = hs.loadSpoon("ActiveSpace")
-- ActiveSpace.compact = true
-- ActiveSpace:start()

-- https://github.com/mogenson/WarpMouse.spoon
-- WarpMouse = hs.loadSpoon("WarpMouse")
-- WarpMouse.margin = 2  -- optionally set how far past a screen edge the mouse should warp, default is 2 pixels
-- WarpMouse:start()


YabaiM = hs.loadSpoon("YabaiM")

SpoonSpace = hs.loadSpoon("SpoonSpace")

-- spoon.SpoonInstall:andUse('PaperWM')
-- PaperWM = hs.loadSpoon("PaperWM")

-------------------------------------------------
-- 모달 생성 및 각 스푼에 전달
local spoonSpaceModal = spoon.ModalMgr:new('spoonSpace')
local yabaiModal = spoon.ModalMgr:new('yabaiM')
-- local paperWMModal = spoon.ModalMgr:new('paperWM')

-- 각 스푼 시작 (modal 주입)
if SpoonSpace and SpoonSpace.start then SpoonSpace:start(spoonSpaceModal, spoon.ModalMgr) end
if YabaiM and YabaiM.start then YabaiM:start(yabaiModal, spoon.ModalMgr) end
-- if PaperWM and PaperWM.start then PaperWM:start(paperWMModal, spoon.ModalMgr) end

-- supervisor 바인딩 (root에서 통합)
spoon.ModalMgr.supervisor:bind('alt', 'o', 'Enter SpoonSpace', function()
    print("### spoonSpace Enter")
    spoon.ModalMgr:deactivateAll()
    spoon.ModalMgr:activate({ 'spoonSpace' }, '#74BB67', nil, 'SpoonSpace Mode!')
    spoon.ModalMgr:modalListInfo('spoonSpace')
end)

spoon.ModalMgr.supervisor:bind('alt', 'y', 'Enter yabaiM', function()
    print("### YabaiM Enter")
    spoon.ModalMgr:deactivateAll()
    spoon.ModalMgr:activate({ 'yabaiM' }, '#74BB67', nil, 'Yabai Control Mode!')
    spoon.ModalMgr:modalListInfo('yabaiM')
end)

-- spoon.ModalMgr.supervisor:bind('alt', 'p', 'Enter PaperWM', function()
--     print("### PaperWM Enter")
--     spoon.ModalMgr:deactivateAll()
--     spoon.ModalMgr:activate({'paperWM'}, '#74BB67', nil, 'PaperWM Mode!')
--     spoon.ModalMgr:modalListInfo('paperWM')
--     PaperWM:bindHotkeys(paperWMModal, PaperWM.default_hotkeys)
-- end)
-- paperWMModal:bind('', 'escape', 'Exit PaperWM', function() 
--     print("### PaperWM Exit")
--     spoon.ModalMgr:deactivateAll()
-- end)

-- 종료 키맵
-- paperWMModal:bind('', 'escape', 'Exit PaperWM', function() 
--     print("### PaperWM Exit"                                                    )
--     spoon.ModalMgr.hide_all_notifications()
--     spoon.ModalMgr:deactivateAll()
-- end)
-- use ⌘ Enter as hyper key to enter modal layer, press Escape to exit
-- local modal = hs.hotkey.modal.new({ "cmd" }, "return")

-------------------------------------------------
spoon.ModalMgr.supervisor:enter()


print("### Loding Completed. ###")

hs.alert.show("Spacehammer config loaded")
hs.notify.show("HS Config Loding Completed.","","") -- undecided on this line

