-- AutoHotKeys Utilities Module
-- Consolidated from Logger, Context, Mouse, InputHandler, Visuals
local utils = {}

local application = hs.application
local winmod = hs.window
local osascript = hs.osascript
local eventtap = hs.eventtap
local event = eventtap.event
local timer = hs.timer
local canvas = hs.canvas
local screenmod = hs.screen

-- ============================================================================
-- Logger
-- ============================================================================
utils.Logger = {}
utils.Logger.__index = utils.Logger

function utils.Logger.new(tag)
    local self = setmetatable({}, utils.Logger)
    self.logger = hs.logger.new(tag, 'debug')
    return self
end

function utils.Logger:d(msg) self.logger.d(msg) end

function utils.Logger:i(msg) self.logger.i(msg) end

function utils.Logger:w(msg) self.logger.w(msg) end

function utils.Logger:e(msg) self.logger.e(msg) end

function utils.Logger:v(msg) self.logger.v(msg) end

-- ============================================================================
-- Context (Browser & App Detection)
-- ============================================================================
utils.Context = {}
utils.Context.TYPES = { WEB = "WEB", APP = "APP" }
utils.Context.BROWSER_APPS = {
    "Safari", "Google Chrome", "Brave Browser", "Microsoft Edge", "Vivaldi", "Opera", "Arc"
}

local BROWSER_URL_SCRIPTS = {
    SAFARI = function() return [[tell application "Safari" to get URL of current tab of front window]] end,
    CHROMIUM = function(appName) return string.format([[tell application "%s" to get URL of active tab of front window]],
            appName) end,
}

local function getBrowserActiveURL(appName)
    if not appName then return nil end
    local script = nil
    if appName == "Safari" then
        script = BROWSER_URL_SCRIPTS.SAFARI()
    else
        for _, name in ipairs(utils.Context.BROWSER_APPS) do
            if appName == name and appName ~= "Safari" then
                script = BROWSER_URL_SCRIPTS.CHROMIUM(appName)
                break
            end
        end
    end
    if not script then return nil end
    local success, output = osascript.applescript(script)
    if success and type(output) == "string" and output ~= "" then return output end
    return nil
end

function utils.Context.current()
    local frontApp = application.frontmostApplication()
    if not frontApp then return { type = "none", id = "none" } end

    local win = winmod.frontmostWindow()
    local winFrame = win and win:frame() or nil

    local info = {
        appName = frontApp:name(),
        pid = frontApp:pid(),
        bundleId = frontApp:bundleID(),
        title = frontApp:title(),
        winFrame = winFrame
    }

    info.type = utils.Context.TYPES.APP
    for _, name in ipairs(utils.Context.BROWSER_APPS) do
        if info.appName == name then
            info.type = utils.Context.TYPES.WEB
            break
        end
    end

    if info.type == utils.Context.TYPES.WEB then
        info.url = getBrowserActiveURL(info.appName)
        info.host = info.url and info.url:match("^%w+://([^/]+)")
    end

    info.id = info.type:lower() .. ":" .. info.bundleId
    return info
end

-- ============================================================================
-- Mouse Utils (Coordinate Conversion)
-- ============================================================================
utils.Mouse = {}

function utils.Mouse.convertToAbsolute(relativePosition, windowFrame)
    return {
        x = windowFrame.x + relativePosition.dx,
        y = windowFrame.y + relativePosition.dy
    }
end

function utils.Mouse.convertToRelative(absolutePosition, windowFrame)
    return {
        dx = absolutePosition.x - windowFrame.x,
        dy = absolutePosition.y - windowFrame.y
    }
end

function utils.Mouse.scalePosition(position, originalScreen, currentScreen)
    if not originalScreen or not currentScreen then return position end
    local origFrame = originalScreen:frame()
    local currFrame = currentScreen:frame()
    local scaleX = origFrame.w > 0 and currFrame.w / origFrame.w or 1.0
    local scaleY = origFrame.h > 0 and currFrame.h / origFrame.h or 1.0
    return { x = position.x * scaleX, y = position.y * scaleY }
end

-- ============================================================================
-- Input Handler (Simulation)
-- ============================================================================
utils.Input = {}

function utils.Input.postMouseClick(point, button, clickCount)
    button = button or "left"
    clickCount = clickCount or 1

    local buttonType, upType
    if button == "right" then
        buttonType = event.types.rightMouseDown
        upType = event.types.rightMouseUp
    elseif button == "middle" then
        buttonType = event.types.otherMouseDown
        upType = event.types.otherMouseUp
    else
        buttonType = event.types.leftMouseDown
        upType = event.types.leftMouseUp
    end

    for i = 1, clickCount do
        event.newMouseEvent(buttonType, point):post()
        event.newMouseEvent(upType, point):post()
        if i < clickCount then timer.usleep(100000) end
    end
end

function utils.Input.executeDrag(startPosition, endPosition, button, duration)
    button = button or "left"
    duration = duration or 0.1

    local buttonType, upType, dragType
    if button == "right" then
        buttonType = event.types.rightMouseDown
        upType = event.types.rightMouseUp
        dragType = event.types.rightMouseDragged
    elseif button == "middle" then
        buttonType = event.types.otherMouseDown
        upType = event.types.otherMouseUp
        dragType = event.types.otherMouseDragged
    else
        buttonType = event.types.leftMouseDown
        upType = event.types.leftMouseUp
        dragType = event.types.leftMouseDragged
    end

    event.newMouseEvent(buttonType, startPosition):post()

    local steps = math.max(10, math.floor(duration * 60))
    local stepDelay = (duration / steps) * 1000000

    for i = 1, steps do
        local t = i / steps
        local x = startPosition.x + (endPosition.x - startPosition.x) * t
        local y = startPosition.y + (endPosition.y - startPosition.y) * t
        timer.usleep(stepDelay)
        event.newMouseEvent(dragType, { x = x, y = y }):post()
    end

    event.newMouseEvent(upType, endPosition):post()
end

function utils.Input.executeKeyStroke(modifiers, key)
    eventtap.keyStroke(modifiers or {}, key, 0)
end

function utils.Input.executeTextInput(text)
    eventtap.keyStrokes(text)
end

-- ============================================================================
-- Visuals (Effects)
-- ============================================================================
utils.Visuals = {}

function utils.Visuals.showClickAnimation(point, color)
    local initialSize = 10
    local finalSize = 60
    local duration = 0.5

    local function hexToRGB(hex)
        hex = hex:gsub("#", "")
        return {
            red = tonumber("0x" .. hex:sub(1, 2)) / 255,
            green = tonumber("0x" .. hex:sub(3, 4)) / 255,
            blue = tonumber("0x" .. hex:sub(5, 6)) / 255,
            alpha = 1.0
        }
    end

    local strokeColor = { red = 1, green = 0.2, blue = 0.2, alpha = 1 }
    if color then
        if type(color) == "string" then
            strokeColor = hexToRGB(color)
        elseif type(color) == "table" then
            strokeColor = color
        end
    end

    local c = canvas.new({
        x = point.x - initialSize / 2,
        y = point.y - initialSize / 2,
        w = initialSize,
        h = initialSize
    }):behavior(canvas.windowBehaviors.canJoinAllSpaces):level(canvas.windowLevels.cursor)

    c[1] = {
        type = "circle",
        action = "stroke",
        strokeColor = strokeColor,
        strokeWidth = 3,
    }
    c:show()

    local startTime = timer.secondsSinceEpoch()
    local animTimer
    animTimer = timer.doEvery(0.02, function()
        local timePassed = timer.secondsSinceEpoch() - startTime
        if timePassed >= duration then
            if c then c:delete() end
            if animTimer then animTimer:stop() end
            return
        end

        local progress = timePassed / duration
        progress = 1 - (1 - progress) * (1 - progress) -- Ease out quad

        local currentSize = initialSize + ((finalSize - initialSize) * progress)
        local currentAlpha = 1 - progress

        if c then
            c:frame({
                x = point.x - currentSize / 2,
                y = point.y - currentSize / 2,
                w = currentSize,
                h = currentSize
            })
            c[1].strokeColor.alpha = currentAlpha
        end
    end)
end

return utils
