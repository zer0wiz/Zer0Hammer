-- AutoHotKeys Watchers Module
local watchers = {}

local appmod = hs.application

-- Internal dependencies
-- We assume obj has: utils, storage, actions, ui

local function isExcludedApp(bundleId, obj)
    if not bundleId then return false end
    local config = obj.storage.loadConfig()
    for _, excludedId in ipairs(config.excludedApps or {}) do
        if bundleId == excludedId then return true end
    end
    return false
end

local function isActiveContext(ctx, obj)
    if not ctx or not ctx.id then return false end
    return obj.activeContexts[ctx.id] ~= nil
end

local function ensureContextExists(ctx, obj)
    if not ctx or not ctx.id then return false end
    local existingContext = obj.storage.findContext(ctx.id)
    if existingContext then return true end

    local contextData = {
        id = ctx.id,
        type = ctx.type,
        name = ctx.name or ctx.appName or ctx.id,
        bundleId = ctx.bundleId,
        enabled = false
    }
    local success, result = obj.storage.addContext(contextData)
    if success then
        obj.logger.i("Auto-added context: " .. ctx.id)
        return true
    else
        obj.logger.w("Failed to add context: " .. ctx.id .. " - " .. (result or "Unknown error"))
        return false
    end
end

local function handleContextActivation(obj)
    ensureContextExists(obj.contextObj, obj)

    local ctx = obj.storage.findContext(obj.contextObj.id)
    local isEnabled = ctx and ctx.enabled or false

    if isEnabled and not isActiveContext(obj.contextObj, obj) then
        obj.activeContexts[obj.contextObj.id] = { context = obj.contextObj, timestamp = os.time() }
    end

    if not isEnabled and not isActiveContext(obj.contextObj, obj) then
        obj.actions.stopKeyTap(obj) -- Disable shortcuts
        obj.ui.overlay.update(obj)
        return false
    end

    obj.ui.overlay.update(obj)
    watchers.updateAppShortcuts(obj)
    return true
end

function watchers.start(obj)
    if obj.winFilter then obj.winFilter:unsubscribeAll() end

    obj.winFilter = hs.window.filter.new():subscribe(hs.window.filter.windowFocused, function()
        if obj.menuShowing then return end

        obj.contextObj = obj.utils.Context.current()
        -- print(string.format("[AutoHotKeys] Focus: %s (%s)", obj.contextObj.appName or "Unknown", obj.contextObj.bundleId or "unknown"))

        if obj.contextObj.bundleId == "org.hammerspoon.Hammerspoon" or obj.contextObj.bundleId == "com.hammerspoon.Hammerspoon" then return end

        if isExcludedApp(obj.contextObj.bundleId, obj) then
            obj.actions.stopKeyTap(obj)
            return
        end

        handleContextActivation(obj)
    end)

    if obj.appWatcher then obj.appWatcher:stop() end
    obj.appWatcher = appmod.watcher.new(function(_, event)
        if event == appmod.watcher.activated then
            if obj.menuShowing then return end

            obj.contextObj = obj.utils.Context.current()
            -- print(string.format("[AutoHotKeys] App Active: %s (%s)", obj.contextObj.appName or "Unknown", obj.contextObj.bundleId or "unknown"))

            if obj.contextObj.bundleId == "org.hammerspoon.Hammerspoon" or obj.contextObj.bundleId == "com.hammerspoon.Hammerspoon" then return end

            if isExcludedApp(obj.contextObj.bundleId, obj) then
                obj.actions.stopKeyTap(obj)
                return
            end

            handleContextActivation(obj)
        end
    end)
    obj.appWatcher:start()

    -- Initial check
    obj.contextObj = obj.utils.Context.current()
    if not isExcludedApp(obj.contextObj.bundleId, obj) then
        handleContextActivation(obj)
    end

    -- Register global key tap (it handles its own filtering)
    obj.actions.registerKeyTap(obj)
end

function watchers.updateAppShortcuts(obj)
    local ctx = obj.contextObj
    if not ctx then
        obj.actions.stopKeyTap(obj)
        return
    end

    if isExcludedApp(ctx.bundleId, obj) then
        obj.actions.stopKeyTap(obj)
        return
    end
    if not isActiveContext(ctx, obj) then
        obj.actions.stopKeyTap(obj)
        return
    end

    local contextConfig = obj.storage.loadContextConfig(ctx.id)
    if contextConfig and contextConfig.shortcuts then
        obj.activeAppShortcuts = contextConfig.shortcuts
        -- KeyTap is already registered in start(), it checks activeAppShortcuts
    else
        obj.activeAppShortcuts = nil
    end
end

function watchers.stop(obj)
    if obj.appWatcher then
        obj.appWatcher:stop()
        obj.appWatcher = nil
    end
    if obj.winFilter then
        obj.winFilter:unsubscribeAll()
        obj.winFilter = nil
    end
end

return watchers
