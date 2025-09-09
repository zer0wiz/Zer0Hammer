hs.ipc = require("hs.ipc")

require "extensions"
require "application_window_states"

hs.application = require("hs.application")
hs.dockicon = require("hs.dockicon")
hs.hotkey = require("hs.hotkey")
-- hs.tracker = require("modules.window_tracker")
-- hs.tracker = require("modules.keyboard_grid")

-- hs.console.clearConsole()
-- hs.consoleOnTop(true)

local fnutils = require "hs.fnutils"
each = fnutils.each
filter = fnutils.filter
map = fnutils.map

local ipcResult = hs.ipc.cliInstall()
print(string.format('## ipcResul: %s', ipcResult))

hs.loadSpoon("RecursiveBinder")
-- hs.loadSpoon("Seal")

-- spoon.RecursiveBinder.escapeKey = {{}, 'escape'} -- Press escape to abort
-- local singleKey = spoon.RecursiveBinder.singleKey
-- local keyMap = {
--     [singleKey('b', 'browser')] = function()
--         hs.application.launchOrFocus("Firefox")
--     end,
--     [singleKey('t', 'terminal')] = function()
--         hs.application.launchOrFocus("Terminal")
--     end,
--     [singleKey('d', 'domain+')] = {
--         [singleKey('g', 'github')] = function()
--             hs.urlevent.openURL("github.com")
--         end,
--         [singleKey('y', 'youtube')] = function()
--             hs.urlevent.openURL("youtube.com")
--         end
--     }
-- }
--
local alert = require "hs.alert"

local appName = "Hammerspoon"

menuTestValue = nil

-- local win = hs.window.focusedWindow() -- 현재 활성화된 앱의 윈도우
-- local frame = win:frame()
-- local screen = win:screen():frame()

function delinate()
    dbgf('----------------------------------------')
end

function eventHandler(element, eventName, watcher, includedData)
    dbgf('%s event: %s', elementType(element), eventName)
    describeApplicationState()
    delinate()
end

function globalEventHandler(applicationName, eventType, application)
    dbgf('%s event: %s, app: %s', eventType, eventName, application:title())
    delinate()
end

function checkAppName(app)
    if app:name() == appName then
        return true
    else
        return false
    end
end

function getApplicationList()
    for _, app in pairs(hs.application.runningApplications()) do
        local pidApp = hs.application.applicationForPID(app:pid())
        if pidApp == nil then
            if name == app:name() then
                return app
            end
        end
    end
end

function findApplication(applicationName)

    return hs.fnutils.filter(hs.application.runningApplications(), function(app)
        return result(app, 'title') == applicationName
    end)
end

function getApplicationWindow(app)
    if app and #app then
        windows = app[1]:allWindows()
        window = windows[1]
        return window
    else
        return nil
    end
end

function getWindowFrame(window)
    -- local windowFrame = window:frame()
    -- win:screen():frame()
end

function trakerInit()

    -- Handle opening new apps / closing apps
    appsWatcher = hs.application.watcher.new(handleGlobalAppEvent)
    appsWatcher:start()

    -- Watch any apps that already exist
    local apps = hs.application.runningApplications()

    apps = filter(apps, function(app)
        return app:title() ~= "Hammerspoon"
    end)

    each(apps, function(app)
        -- watchApp(app, true)
    end)
end

function init()

    hs.hotkey.bind({'option'}, 'space', spoon.RecursiveBinder.recursiveBind(keyMap))
    -- spoon.Seal:loadPlugins("")
    -- spoon.Seal:start()

    -- spoon.HSKeybindings:show()
    -- spoon.HSKeybindings:hide()

    -- local app = findApplicationByName(appName)
    -- dbg(app:name())
    -- dbg(app:bundleID())
    local app = findApplication(appName)
    local window = getApplicationWindow(app)
    local state = ApplicationWindowStates;
    state:new();

    dbg(app)
    dbg(window)
    if window then
        local screen = window:screen()
        local frame = window:frame()
    else
        alert(string.format("Not Found Window. [%s]", appName))
    end
    trakerInit()
    startWatchingEvents()

    local createNewGrid = hs.hotkey.modal.new(hyper, "W")

end

init()
