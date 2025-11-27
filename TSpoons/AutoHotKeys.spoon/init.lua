local obj = {}
obj.__index = obj

-- Metadata
obj.name = "AutoHotKeys"
obj.version = "0.3.0"
obj.author = "zer0wiz<zer0wiz9@gmail.com>"
obj.homepage = "https://github.com/zer0wiz/spacehammer"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.logger = hs.logger.new("AutoHotKeys")

-- Add Spoon path to package.path
local spoonPath = hs.spoons.resourcePath("")
if not string.find(package.path, spoonPath, 1, true) then
    package.path = package.path .. ";" .. spoonPath .. "/?.lua"
end

-- Load Modules
obj.utils = require("utils")
obj.storage = require("storage")
obj.actions = require("actions")
obj.recorder = require("recorder")
obj.ui = require("ui")
obj.hotkeys = require("hotkeys")
obj.watchers = require("watchers")

-- Configuration
obj.hotkey = obj.hotkey or { { "shift", "cmd" }, "k" }
obj.activeContexts = {}

function obj:start()
    -- Watchers
    obj.watchers.start(self)

    -- Initial update
    local ctx = obj.utils.Context.current()
    obj.contextObj = ctx
    obj.ui.overlay.update(obj)

    -- Hotkeys
    obj.hotkeys.bind(self)

    return self
end

function obj:stop()
    obj.watchers.stop(self)
    obj.ui.overlay.stop(self)
    obj.hotkeys.unbind(self)
    obj.actions.stopKeyTap(self)
    return self
end

function obj:menuToggle()
    obj.ui.menu.toggle(self)
end

function obj:init()
    obj:start()
end

return obj
