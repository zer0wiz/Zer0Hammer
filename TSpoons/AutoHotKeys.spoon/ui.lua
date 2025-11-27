-- AutoHotKeys UI Module
-- Consolidated from menu.lua, overlay.lua, shortcut_preview.lua, ui/MenuRenderer.lua, ui/MenuEvents.lua
local ui = {}

local canvas = hs.canvas
local screenmod = hs.screen
local json = hs.json
local fs = hs.fs
local winmod = hs.window
local appmod = hs.application
local eventtap = hs.eventtap
local event = eventtap.event
local dialog = hs.dialog

-- Internal dependencies
local utils = require("utils")
local storage = require("storage")

-- ============================================================================
-- Helper: MenuRenderer
-- ============================================================================
local MenuRenderer = {}

local function resolvePlaceholder(value, vars)
    if type(value) == "string" then
        local result = value:gsub("{{([^}]+)}}", function(expr)
            local trimmed = expr:match("^%s*(.-)%s*$")
            if vars[trimmed] ~= nil then return vars[trimmed] end
            return ""
        end)
        if type(result) == "string" and result:match("^%s*%-?%d+%.?%d*%s*$") then
            return tonumber(result)
        end
        return result
    elseif type(value) == "table" then
        local result = {}
        for k, v in pairs(value) do
            local newKey = resolvePlaceholder(k, vars)
            local newValue = resolvePlaceholder(v, vars)
            if type(k) == "number" then result[k] = newValue else result[newKey] = newValue end
        end
        return result
    end
    return value
end

local function createCanvasElement(elementDef, vars)
    local element = {}
    for k, v in pairs(elementDef) do
        if k ~= "index" and k ~= "template" then
            local resolved = resolvePlaceholder(v, vars)
            if k == "frame" or k == "roundedRectRadii" or k == "center" or k == "fillColor" then
                if type(resolved) == "table" then
                    for sk, sv in pairs(resolved) do
                        if type(sv) == "string" then resolved[sk] = tonumber(sv) or sv end
                    end
                end
            elseif (k == "textSize" or k == "strokeWidth" or k == "radius") and type(resolved) == "string" then
                resolved = tonumber(resolved) or resolved
            end
            element[k] = resolved
        end
    end
    return element.type and element or nil
end

function MenuRenderer.render(c, menuConfig, vars)
    local elements = menuConfig.elements or {}
    if not elements or next(elements) == nil then
        c[1] = { type = "rectangle", action = "fill", fillColor = { alpha = 0.95, white = 0.08 }, roundedRectRadii = { xRadius = 8, yRadius = 8 } }
        c[2] = { type = "text", text = vars.appName or "Unknown", textSize = 14, textColor = { white = 1 }, frame = { x = 15, y = 12, w = vars.w - 80, h = 20 }, textAlignment =
        "left" }
        return
    end

    local sortedElements = {}
    for elementName, elementDef in pairs(elements) do
        if elementDef and elementDef.index then
            table.insert(sortedElements, { name = elementName, def = elementDef, index = tonumber(elementDef.index) })
        end
    end
    table.sort(sortedElements, function(a, b) return a.index < b.index end)

    for _, item in ipairs(sortedElements) do
        local canvasElement = createCanvasElement(item.def, vars)
        if canvasElement then
            if item.name == "enabledToggleActive" and canvasElement.fillColor then canvasElement.fillColor.alpha = vars
                .enabledAlpha end
            if item.name == "overlayToggleActive" and canvasElement.fillColor then canvasElement.fillColor.alpha = vars
                .overlayAlpha end
            if item.name == "enabledToggleThumb" and canvasElement.center then canvasElement.center.x = vars
                .enabledThumbX end
            if item.name == "overlayToggleThumb" and canvasElement.center then canvasElement.center.x = vars
                .overlayThumbX end
            pcall(function() c[item.index] = canvasElement end)
        end
    end
end

-- ============================================================================
-- Helper: MenuEvents
-- ============================================================================
local MenuEvents = {}
function MenuEvents.new(obj, canvas, callbacks)
    local self = setmetatable({}, { __index = MenuEvents })
    self.obj = obj
    self.canvas = canvas
    self.callbacks = callbacks or {}
    self.dragMode = false

    self.canvas:mouseCallback(function(c, msg, id, x, y)
        if msg == "mouseDown" then
            local modifiers = eventtap.checkKeyboardModifiers()
            if modifiers.ctrl and modifiers.cmd then
                self:startDrag()
                return true
            end
        elseif msg == "mouseUp" then
            if self.callbacks.onClick then return self.callbacks.onClick(id, x, y) end
        end
        return false
    end)
    return self
end

function MenuEvents:startDrag()
    self.dragMode = true
    local frame = self.canvas:frame()
    self.dragStartCanvasX, self.dragStartCanvasY = frame.x or 0, frame.y or 0
    local mousePos = hs.mouse.absolutePosition()
    self.dragStartMouseX, self.dragStartMouseY = mousePos.x, mousePos.y

    if self.canvas[1] then
        self.canvas[1].strokeColor = { red = 1.0, green = 0.8, blue = 0.0, alpha = 1.0 }
        self.canvas[1].strokeWidth = 2
        self.canvas[1].action = "strokeAndFill"
    end

    if self.dragEventHandler then self.dragEventHandler:stop() end
    self.dragEventHandler = eventtap.new(
    { event.types.leftMouseDragged, event.types.mouseMoved, event.types.leftMouseUp, event.types.flagsChanged },
        function(e)
            local eventType = e:getType()
            if self.dragMode then
                if eventType == event.types.leftMouseDragged or eventType == event.types.mouseMoved then
                    local mousePos = hs.mouse.absolutePosition()
                    self.canvas:topLeft({
                        x = self.dragStartCanvasX + (mousePos.x - self.dragStartMouseX),
                        y = self.dragStartCanvasY + (mousePos.y - self.dragStartMouseY)
                    })
                    return false
                elseif eventType == event.types.flagsChanged then
                    local flags = e:getFlags()
                    if not flags.ctrl or not flags.cmd then
                        self:stopDrag()
                        return false
                    end
                elseif eventType == event.types.leftMouseUp then
                    self:stopDrag()
                    return false
                end
            end
            return false
        end)
    self.dragEventHandler:start()
end

function MenuEvents:stopDrag()
    self.dragMode = false
    if self.canvas[1] then
        self.canvas[1].strokeColor = nil
        self.canvas[1].strokeWidth = 0
        self.canvas[1].action = "fill"
    end
    if self.dragEventHandler then
        self.dragEventHandler:stop()
        self.dragEventHandler = nil
    end
    local frame = self.canvas:frame()
    if self.callbacks.onPositionChanged then self.callbacks.onPositionChanged(frame.x, frame.y) end
end

function MenuEvents:stop()
    if self.dragEventHandler then
        self.dragEventHandler:stop()
        self.dragEventHandler = nil
    end
end

-- ============================================================================
-- UI.Menu
-- ============================================================================
ui.menu = {}
ui.menu.menuList = {}
ui.menu.config = nil
ui.menu.events = nil

local function loadMenuConfig()
    if ui.menu.config then return ui.menu.config end
    local configPath = hs.spoons.resourcePath("assets/menu.json")
    if fs.attributes(configPath) then
        local file = io.open(configPath, "r")
        if file then
            local content = file:read("*a")
            file:close()
            ui.menu.config = json.decode(content)
        end
    end
    if not ui.menu.config then ui.menu.config = {} end
    return ui.menu.config
end

function ui.menu.toggle(obj)
    if obj.menuShowing then ui.menu.hide(obj) else ui.menu.show(obj) end
end

function ui.menu.show(obj)
    if obj.menuShowing and obj.menuCanvas then
        ui.menu.hide(obj)
        return
    end
    if obj.menuCanvas then
        obj.menuCanvas:delete()
        obj.menuCanvas = nil
    end
    if ui.menu.events then
        ui.menu.events:stop()
        ui.menu.events = nil
    end

    local ctx = utils.Context.current()
    obj.contextObj = ctx

    local config = storage.loadConfig()
    for _, excludedId in ipairs(config.excludedApps or {}) do
        if ctx.bundleId == excludedId then
            hs.alert.show("Excluded App", 2.0)
            return
        end
    end

    ui.menu.config = loadMenuConfig()
    local mainMenuConfig = ui.menu.config.mainMenu or {}
    local w, h = mainMenuConfig.size and mainMenuConfig.size.w or 280,
        mainMenuConfig.size and mainMenuConfig.size.h or 185

    local mousePos = hs.mouse.absolutePosition()
    local x, y = mousePos.x, mousePos.y
    local screenFrame = (hs.mouse.getCurrentScreen() or screenmod.primaryScreen()):frame()
    if y + h > screenFrame.y + screenFrame.h then y = (screenFrame.y + screenFrame.h) - h end
    if y < screenFrame.y then y = screenFrame.y end
    if x + w > screenFrame.x + screenFrame.w then x = (screenFrame.x + screenFrame.w) - w end
    if x < screenFrame.x then x = screenFrame.x end

    local c = canvas.new({ x = x, y = y, w = w, h = h }):show()
    c:level(canvas.windowLevels.popUpMenu)
    obj.menuCanvas = c
    obj.menuShowing = true

    local appId = ctx.id
    local ctxConfig = storage.findContext(ctx.id)
    local enabled = ctxConfig and ctxConfig.enabled or false
    local overlayEnabled = config.overlay and config.overlay.enabled or false

    local vars = {
        w = w,
        h = h,
        appName = ctx.appName or "Unknown",
        enabledText = enabled and "ON" or "OFF",
        overlayStatus = overlayEnabled and "ON" or "OFF",
        enabledAlpha = enabled and 1.0 or 0.0,
        overlayAlpha = overlayEnabled and 1.0 or 0.0,
        enabledThumbX = enabled and 37 or 12,
        overlayThumbX = overlayEnabled and 37 or 12                                       -- Simplified calc
    }

    MenuRenderer.render(c, mainMenuConfig, vars)

    ui.menu.events = MenuEvents.new(obj, c, {
        onClick = function(id, cx, cy)
            if id == "btnToggle" or id == "enabledToggleTrack" or (cx >= 221 and cx <= 265 and cy >= 10 and cy <= 34) then
                storage.toggleAppEnabled(ctx.id)
                ui.menu.show(obj) -- Re-render
                if obj.activeContexts then
                    if not enabled then
                        obj.activeContexts[ctx.id] = { context = ctx, timestamp = os.time() }
                    else
                        obj.activeContexts[ctx.id] = nil
                    end
                end
                ui.overlay.update(obj)
                return true
            end
            if id == "overlayToggle" or id == "overlayToggleTrack" or (cx >= 216 and cx <= 260 and cy >= 120 and cy <= 144) then
                local newConfig = storage.loadConfig()
                newConfig.overlay = newConfig.overlay or {}
                newConfig.overlay.enabled = not (newConfig.overlay.enabled or false)
                storage.saveConfig(newConfig)
                ui.menu.show(obj)
                ui.overlay.update(obj)
                return true
            end
            if id == "btnShortcuts" then
                ui.menu.hide(obj)
                ui.preview.show(obj, ctx)
                return true
            end
            if id == "btnMacros" then
                ui.menu.showMacroList(obj)
                return true
            end
            return false
        end,
        onPositionChanged = function(nx, ny)
            local cfg = storage.loadConfig()
            cfg.menu.position.x = nx
            cfg.menu.position.y = ny
            cfg.menu.saved = true
            storage.saveConfig(cfg)
        end
    })
    c:canvasMouseEvents(true, true, false, false)
end

function ui.menu.showMacroList(obj)
    if obj.menuCanvas then
        obj.menuCanvas:delete()
        obj.menuCanvas = nil
    end
    if ui.menu.events then
        ui.menu.events:stop()
        ui.menu.events = nil
    end

    local macros = storage.listMacros()
    local w, h = 280, 185
    local mousePos = hs.mouse.absolutePosition()
    local c = canvas.new({ x = mousePos.x, y = mousePos.y, w = w, h = h }):show()
    c:level(canvas.windowLevels.popUpMenu)
    obj.menuCanvas = c
    obj.menuShowing = true

    -- Simple list rendering
    c[1] = { type = "rectangle", action = "fill", fillColor = { alpha = 0.95, white = 0.08 }, roundedRectRadii = { xRadius = 8, yRadius = 8 } }
    c[2] = { type = "text", text = "Saved Macros", textSize = 14, textColor = { white = 1 }, textAlignment = "center", frame = { x = 0, y = 12, w = w, h = 20 } }
    c[3] = { type = "text", text = "< Back", textSize = 12, textColor = { white = 0.7 }, frame = { x = 15, y = 12, w = 50, h = 20 } }

    local startY = 50
    for i, macro in ipairs(macros) do
        if i > 5 then break end
        local itemY = startY + (i - 1) * 25
        c[10 + i] = { type = "text", text = macro.name, textSize = 12, textColor = { white = 0.9 }, frame = { x = 20, y = itemY, w = w - 80, h = 20 } }
        c[20 + i] = { type = "text", text = "▶", textSize = 12, textColor = { red = 0.4, green = 0.8, blue = 0.4 }, frame = { x = w - 60, y = itemY, w = 20, h = 20 } }
        c[30 + i] = { type = "text", text = "x", textSize = 12, textColor = { red = 0.8, green = 0.4, blue = 0.4 }, frame = { x = w - 35, y = itemY, w = 20, h = 20 } }
    end

    ui.menu.events = MenuEvents.new(obj, c, {
        onClick = function(id, cx, cy)
            if cx >= 15 and cx <= 65 and cy >= 10 and cy <= 35 then
                ui.menu.show(obj)
                return true
            end
            for i, macro in ipairs(macros) do
                if i > 5 then break end
                local itemY = startY + (i - 1) * 25
                if cx >= w - 65 and cx <= w - 40 and cy >= itemY and cy <= itemY + 20 then
                    ui.menu.hide(obj)
                    require("actions").play(obj, macro.name)
                    ui.overlay.update(obj)
                    return true
                end
                if cx >= w - 40 and cx <= w - 15 and cy >= itemY and cy <= itemY + 20 then
                    storage.deleteMacro(macro.name)
                    ui.menu.showMacroList(obj)
                    return true
                end
            end
            return false
        end
    })
    c:canvasMouseEvents(true, true, false, false)
end

function ui.menu.hide(obj)
    if obj.menuCanvas then
        obj.menuCanvas:delete()
        obj.menuCanvas = nil
    end
    if ui.menu.events then
        ui.menu.events:stop()
        ui.menu.events = nil
    end
    obj.menuShowing = false
end

-- ============================================================================
-- UI.Overlay
-- ============================================================================
ui.overlay = {}

function ui.overlay.update(obj)
    if obj.overlayCanvas then
        obj.overlayCanvas:delete()
        obj.overlayCanvas = nil
    end

    local config = storage.loadConfig()
    if not (config.overlay and config.overlay.enabled) then return end

    local ctx = obj.contextObj or utils.Context.current()
    local isActive = ctx and ctx.id and obj.activeContexts and obj.activeContexts[ctx.id]
    local isRecording = obj.recorder and obj.recorder.isRecording(obj)
    local isPlaying = require("actions").isPlaying(obj)

    if not (isActive or isRecording or isPlaying) then return end

    local win = winmod.frontmostWindow()
    if not win then return end
    local f = win:frame()

    obj.overlayCanvas = canvas.new({ x = f.x + f.w - 38, y = f.y + 6, w = 32, h = 24 })
    obj.overlayCanvas:behavior(canvas.windowBehaviors.canJoinAllSpaces):level(canvas.windowLevels.popUpMenu)

    local bgColor = { alpha = 0.85, red = 0, green = 0, blue = 0 }
    local text = "AK"
    local textSize = 11

    if isRecording then
        bgColor = { alpha = 0.9, red = 1.0, green = 0.2, blue = 0.2 }
        text = "●"
        textSize = 14
    elseif isPlaying then
        bgColor = { alpha = 0.9, red = 0.2, green = 0.4, blue = 1.0 }
        text = "▶"
        textSize = 12
    elseif isActive then
        local ctxConfig = storage.findContext(ctx.id)
        if ctxConfig and ctxConfig.enabled then
            bgColor = { alpha = 0.9, red = 0.2, green = 0.8, blue = 0.2 }
            text = "✓"
            textSize = 14
        else
            bgColor = { alpha = 0.7, white = 0.4 }
            text = "✗"
            textSize = 12
        end
    end

    obj.overlayCanvas[1] = { type = "rectangle", action = "fill", fillColor = bgColor, roundedRectRadii = { xRadius = 6, yRadius = 6 } }
    obj.overlayCanvas[2] = { type = "text", text = text, textSize = textSize, textColor = { white = 1 }, textAlignment =
    "center", frame = { x = 0, y = 0, w = 32, h = 24 } }

    obj.overlayCanvas:mouseCallback(function(_, msg)
        if msg == "mouseUp" then ui.menu.toggle(obj) end
    end)

    obj.overlayCanvas:show()
    obj.overlayVisible = true
end

function ui.overlay.stop(obj)
    if obj.overlayCanvas then
        obj.overlayCanvas:delete()
        obj.overlayCanvas = nil
    end
    obj.overlayVisible = false
end

-- ============================================================================
-- UI.Preview
-- ============================================================================
ui.preview = {}

local function hexToRGB(hex)
    hex = hex:gsub("#", "")
    return { red = tonumber("0x" .. hex:sub(1, 2)) / 255, green = tonumber("0x" .. hex:sub(3, 4)) / 255, blue = tonumber(
    "0x" .. hex:sub(5, 6)) / 255 }
end

function ui.preview.show(obj, ctx)
    if obj.shortcutPreviewCanvas then
        ui.preview.hide(obj)
        return
    end

    local win = winmod.frontmostWindow()
    if not win then
        hs.alert.show("No active window")
        return
    end
    local winFrame = win:frame()

    local c = canvas.new(winFrame):level(canvas.windowLevels.overlay):behavior(canvas.windowBehaviors.canJoinAllSpaces)

    local config = storage.loadConfig()
    local overlayColor = hexToRGB(config.shortcutPreview.overlay.color)
    c[1] = { type = "rectangle", action = "fill", fillColor = { red = overlayColor.red, green = overlayColor.green, blue = overlayColor.blue, alpha = config.shortcutPreview.overlay.alpha }, frame = { x = 0, y = 0, w = winFrame.w, h = winFrame.h } }

    local appConfig = storage.loadContextConfig(ctx.id)
    local shortcuts = appConfig and appConfig.shortcuts or {}
    local circleConfig = config.shortcutPreview.circle
    local circleColor = hexToRGB(circleConfig.fillColor)
    local textColor = hexToRGB(config.shortcutPreview.text.color)

    local index = 2
    for key, shortcut in pairs(shortcuts) do
        if shortcut.type == "click" and shortcut.position then
            c[index] = {
                type = "circle",
                action = "strokeAndFill",
                fillColor = { red = circleColor.red, green = circleColor.green, blue = circleColor.blue, alpha = circleConfig.fillAlpha },
                strokeColor = hexToRGB(circleConfig.strokeColor),
                strokeWidth = circleConfig.strokeWidth,
                center = { x = shortcut.position.dx, y = shortcut.position.dy },
                radius = circleConfig.radius
            }
            c[index + 1] = {
                type = "text",
                text = key,
                textSize = config.shortcutPreview.text.size,
                textColor = textColor,
                frame = { x = shortcut.position.dx - circleConfig.radius, y = shortcut.position.dy - circleConfig.radius, w = circleConfig.radius * 2, h = circleConfig.radius * 2 },
                textAlignment = "center"
            }
            index = index + 2
        end
    end

    obj.shortcutPreviewEscapeKey = hs.hotkey.bind({}, "escape", function() ui.preview.hide(obj) end)

    c:show()
    obj.shortcutPreviewCanvas = c
    obj.shortcutPreviewContext = ctx
    obj.shortcutPreviewWindow = win

    ui.preview.enableAddMode(obj)
end

function ui.preview.hide(obj)
    if obj.shortcutPreviewCanvas then
        obj.shortcutPreviewCanvas:delete()
        obj.shortcutPreviewCanvas = nil
    end
    if obj.shortcutPreviewEscapeKey then
        obj.shortcutPreviewEscapeKey:delete()
        obj.shortcutPreviewEscapeKey = nil
    end
    if obj.shortcutPreviewMouseTap then
        obj.shortcutPreviewMouseTap:stop()
        obj.shortcutPreviewMouseTap = nil
    end
    if obj.shortcutPreviewKeyboardTap then
        obj.shortcutPreviewKeyboardTap:stop()
        obj.shortcutPreviewKeyboardTap = nil
    end
    obj.shortcutPreviewContext = nil
    obj.shortcutPreviewWindow = nil
end

function ui.preview.enableAddMode(obj)
    if obj.shortcutPreviewMouseTap then obj.shortcutPreviewMouseTap:stop() end
    obj.shortcutPreviewMouseTap = eventtap.new({ event.types.leftMouseDown }, function(e)
        if not e:getFlags().ctrl then return false end
        local pos = e:location()
        local win = obj.shortcutPreviewWindow
        if not win then return false end
        local f = win:frame()
        if pos.x < f.x or pos.x > f.x + f.w or pos.y < f.y or pos.y > f.y + f.h then
            ui.preview.hide(obj)
            return false
        end

        local relativePos = { dx = pos.x - f.x, dy = pos.y - f.y }

        -- Simple key capture logic (simplified for brevity)
        hs.alert.show("Press a key to bind...", 1)
        obj.shortcutPreviewKeyboardTap = eventtap.new({ event.types.keyDown }, function(ke)
            local code = ke:getKeyCode()
            local char = ke:getCharacters()
            if code == 53 then
                ui.preview.hide(obj)
                return true
            end                                                     -- ESC
            if char and char ~= "" then
                local ctx = obj.shortcutPreviewContext
                local config = storage.loadContextConfig(ctx.id) or { context = ctx, shortcuts = {} }
                config.shortcuts[char] = { type = "click", position = relativePos, windowRelative = true, keyCode = code }
                storage.saveContextConfig(ctx.id, config)
                hs.alert.show("Bound to " .. char)
                ui.preview.hide(obj)
                hs.timer.doAfter(0.1, function() ui.preview.show(obj, ctx) end)
                return true
            end
            return false
        end):start()

        return true
    end):start()
end

return ui
