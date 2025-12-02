-- AutoHotKeys Actions Module
-- Consolidated from execution.lua and playback.lua
local actions = {}

local timer = hs.timer
local winmod = hs.window
local eventtap = hs.eventtap

-- Internal dependencies (to be injected or required)
local utils = require("utils")
local storage = require("storage")

-- ============================================================================
-- Single Action Execution
-- ============================================================================
function actions.perform(obj, ctx, key)
    local config = storage.loadContextConfig(ctx.id)
    local shortcuts = config and config.shortcuts or {}
    local item = shortcuts[key]
    if not item then return end

    if item.type == "click" then
        local win = winmod.frontmostWindow()
        if not win then return end

        local currentPos = hs.mouse.absolutePosition()
        local f = win:frame()
        local x = f.x + (item.position.dx or 0)
        local y = f.y + (item.position.dy or 0)

        local globalConfig = storage.loadConfig()
        local clickColor = globalConfig.clickAnimation and globalConfig.clickAnimation.color

        utils.Visuals.showClickAnimation({ x = x, y = y }, clickColor)
        utils.Input.postMouseClick({ x = x, y = y }, item.button or "left", item.clickCount or 1)
        hs.mouse.absolutePosition(currentPos)
    elseif item.type == "drag" then
        local win = winmod.frontmostWindow()
        if not win then return end

        local currentPos = hs.mouse.absolutePosition()
        local f = win:frame()
        local startX = f.x + (item.startPosition.dx or item.startPosition.x or 0)
        local startY = f.y + (item.startPosition.dy or item.startPosition.y or 0)
        local endX = f.x + (item.endPosition.dx or item.endPosition.x or 0)
        local endY = f.y + (item.endPosition.dy or item.endPosition.y or 0)

        utils.Input.executeDrag(
            { x = startX, y = startY },
            { x = endX, y = endY },
            item.button or "left",
            item.duration or 0.1
        )
        hs.mouse.absolutePosition(currentPos)
    elseif item.type == "mouseMove" then
        local currentPos = hs.mouse.absolutePosition()
        local position = item.position
        if position.dx or position.dy then
            local win = winmod.frontmostWindow()
            if win then
                local f = win:frame()
                position = { x = f.x + (position.dx or 0), y = f.y + (position.dy or 0) }
            end
        end
        hs.mouse.absolutePosition(position)
        hs.mouse.absolutePosition(currentPos)
    elseif item.type == "delay" then
        local ms = tonumber(item.milliseconds or 0) or 0
        timer.usleep(ms * 1000)
    elseif item.type == "key" then
        utils.Input.executeKeyStroke(item.modifiers or {}, item.key or key)
    elseif item.type == "keyCombo" then
        if item.keys then
            local modifiers = {}
            local k = nil
            for _, keyPart in ipairs(item.keys) do
                if keyPart == "cmd" or keyPart == "command" then
                    table.insert(modifiers, "cmd")
                elseif keyPart == "alt" or keyPart == "option" then
                    table.insert(modifiers, "alt")
                elseif keyPart == "shift" then
                    table.insert(modifiers, "shift")
                elseif keyPart == "ctrl" or keyPart == "control" then
                    table.insert(modifiers, "ctrl")
                else
                    k = keyPart
                end
            end
            if k then utils.Input.executeKeyStroke(modifiers, k) end
        end
    elseif item.type == "text" then
        utils.Input.executeTextInput(item.text or "")
    end
end

-- ============================================================================
-- Key Tap Handling
-- ============================================================================
function actions.handleShortcutKey(obj, key)
    if not obj.activeAppShortcuts then return false end
    local shortcut = obj.activeAppShortcuts[key]
    if not shortcut then return false end

    -- Re-use perform logic by constructing a temporary item context?
    -- Or just duplicate logic for now as perform takes ctx/key but here we have direct shortcut object
    -- Let's adapt perform to take item directly if possible, or just copy logic for now to be safe

    if shortcut.type == "click" then
        local win = winmod.frontmostWindow()
        if not win then return false end
        local currentPos = hs.mouse.absolutePosition()
        local f = win:frame()
        local x = f.x + (shortcut.position.dx or 0)
        local y = f.y + (shortcut.position.dy or 0)
        local globalConfig = storage.loadConfig()
        local clickColor = globalConfig.clickAnimation and globalConfig.clickAnimation.color
        utils.Visuals.showClickAnimation({ x = x, y = y }, clickColor)
        utils.Input.postMouseClick({ x = x, y = y }, shortcut.button or "left", shortcut.clickCount or 1)
        hs.mouse.absolutePosition(currentPos)
        return true
    elseif shortcut.type == "drag" then
        local win = winmod.frontmostWindow()
        if not win then return false end
        local currentPos = hs.mouse.absolutePosition()
        local f = win:frame()
        local startX = f.x + (shortcut.startPosition.dx or shortcut.startPosition.x or 0)
        local startY = f.y + (shortcut.startPosition.dy or shortcut.startPosition.y or 0)
        local endX = f.x + (shortcut.endPosition.dx or shortcut.endPosition.x or 0)
        local endY = f.y + (shortcut.endPosition.dy or shortcut.endPosition.y or 0)
        utils.Input.executeDrag({ x = startX, y = startY }, { x = endX, y = endY }, shortcut.button or "left",
            shortcut.duration or 0.1)
        hs.mouse.absolutePosition(currentPos)
        return true
    elseif shortcut.type == "mouseMove" then
        local currentPos = hs.mouse.absolutePosition()
        local position = shortcut.position
        if position.dx or position.dy then
            local win = winmod.frontmostWindow()
            if win then
                local f = win:frame()
                position = { x = f.x + (position.dx or 0), y = f.y + (position.dy or 0) }
            end
        end
        hs.mouse.absolutePosition(position)
        hs.mouse.absolutePosition(currentPos)
        return true
    elseif shortcut.type == "key" then
        utils.Input.executeKeyStroke(shortcut.modifiers or {}, shortcut.key or key)
        return true
    elseif shortcut.type == "keyCombo" then
        if shortcut.keys then
            local modifiers = {}
            local k = nil
            for _, keyPart in ipairs(shortcut.keys) do
                if keyPart == "cmd" or keyPart == "command" then
                    table.insert(modifiers, "cmd")
                elseif keyPart == "alt" or keyPart == "option" then
                    table.insert(modifiers, "alt")
                elseif keyPart == "shift" then
                    table.insert(modifiers, "shift")
                elseif keyPart == "ctrl" or keyPart == "control" then
                    table.insert(modifiers, "ctrl")
                else
                    k = keyPart
                end
            end
            if k then utils.Input.executeKeyStroke(modifiers, k) end
        end
        return true
    elseif shortcut.type == "text" then
        utils.Input.executeTextInput(shortcut.text or "")
        return true
    end
    return false
end

function actions.registerKeyTap(obj)
    if obj.keyTap then return end
    obj.keyTap = eventtap.new({ eventtap.event.types.keyDown }, function(e)
        local flags = e:getFlags()
        if flags.cmd or flags.alt or flags.shift or flags.ctrl then return false end
        if obj.menuShowing then return false end
        if obj.shortcutPreviewCanvas then return false end

        local ch = e:getCharacters(true)
        if not ch then return false end
        ch = ch:lower()

        if actions.handleShortcutKey(obj, ch) then return true end

        local ctx = obj.contextObj
        local config = ctx and storage.loadContextConfig(ctx.id)
        if config and config.shortcuts and config.shortcuts[ch] then
            actions.perform(obj, ctx, ch)
            return true
        end
        return false
    end)
    obj.keyTap:start()
end

function actions.stopKeyTap(obj)
    if obj.keyTap then
        obj.keyTap:stop()
        obj.keyTap = nil
    end
end

-- ============================================================================
-- Playback
-- ============================================================================
local function convertPosition(action, obj)
    if not action.window then return action.position end
    local currentWin = winmod.frontmostWindow()
    if not currentWin then return action.position end

    if action.relativePosition then
        local frame = currentWin:frame()
        local scaleX = action.window.frame.w > 0 and frame.w / action.window.frame.w or 1.0
        local scaleY = action.window.frame.h > 0 and frame.h / action.window.frame.h or 1.0
        return {
            x = frame.x + (action.relativePosition.dx * scaleX),
            y = frame.y + (action.relativePosition.dy * scaleY)
        }
    else
        local scaleX = action.window.frame.w > 0 and currentWin:frame().w / action.window.frame.w or 1.0
        local scaleY = action.window.frame.h > 0 and currentWin:frame().h / action.window.frame.h or 1.0
        return {
            x = action.position.x * scaleX,
            y = action.position.y * scaleY
        }
    end
end

function actions.play(obj, macroName, options)
    options = options or {}
    if actions.isPlaying(obj) then return false, "Already playing" end

    local macro = storage.loadMacro(macroName)
    if not macro then return false, "Macro not found: " .. macroName end

    obj.playback = {
        macro = macro,
        repeatCount = options.repeatCount or 1,
        currentRepeat = 0,
        speed = options.speed or 1.0,
        startTime = timer.absoluteTime(),
        currentActionIndex = 1,
        onComplete = options.onComplete,
        onError = options.onError,
        timer = nil
    }
    actions.playNextAction(obj)
    return true
end

function actions.playNextAction(obj)
    if not actions.isPlaying(obj) then return end
    local pb = obj.playback
    local actionsList = pb.macro.actions

    if pb.currentActionIndex > #actionsList then
        pb.currentRepeat = pb.currentRepeat + 1
        if pb.repeatCount == 0 or pb.currentRepeat < pb.repeatCount then
            pb.currentActionIndex = 1
            pb.startTime = timer.absoluteTime()
            actions.playNextAction(obj)
        else
            actions.stopPlayback(obj)
            if pb.onComplete then pb.onComplete() end
        end
        return
    end

    local action = actionsList[pb.currentActionIndex]
    local previousAction = pb.currentActionIndex > 1 and actionsList[pb.currentActionIndex - 1] or nil
    local delay = previousAction and (action.timestamp - previousAction.timestamp) / pb.speed or
    (action.timestamp / pb.speed)

    pb.timer = timer.doAfter(delay, function()
        if not actions.isPlaying(obj) then return end
        local success, err = pcall(function()
            if action.type == "mouseClick" then
                local position = convertPosition(action, obj)
                utils.Input.postMouseClick(position, action.button or "left")
            elseif action.type == "mouseDrag" then
                local startPos = convertPosition(
                { position = action.startPosition, window = action.window, relativePosition = action
                .startRelativePosition }, obj)
                local endPos = convertPosition(
                { position = action.endPosition, window = action.window, relativePosition = action.endRelativePosition },
                    obj)
                utils.Input.executeDrag(startPos, endPos, action.button or "left", action.duration or 0.1)
            elseif action.type == "mouseMove" then
                local position = convertPosition(action, obj)
                hs.mouse.absolutePosition(position)
            elseif action.type == "keyPress" then
                if action.key then utils.Input.executeKeyStroke(action.modifiers or {}, action.key) end
            elseif action.type == "delay" then
                timer.usleep((action.milliseconds or 0) * 1000)
            end
        end)

        if not success and err then
            if pb.onError then pb.onError(err) end
            actions.stopPlayback(obj)
            return
        end

        pb.currentActionIndex = pb.currentActionIndex + 1
        actions.playNextAction(obj)
    end)
end

function actions.stopPlayback(obj)
    if not actions.isPlaying(obj) then return end
    if obj.playback.timer then
        obj.playback.timer:stop()
        obj.playback.timer = nil
    end
    obj.playback = nil
end

function actions.isPlaying(obj)
    return obj.playback ~= nil
end

return actions
