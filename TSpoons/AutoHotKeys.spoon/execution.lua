-- AutoHotKeys 실행 모듈
local execution = {}

local eventtap = hs.eventtap
local winmod = hs.window
local timer = hs.timer

local InputHandler = require("core.InputHandler")
local visuals = require("visuals")

-- 액션 수행
function execution.perform(obj, ctx, key)
    if not obj.shortcuts then obj.shortcuts = {} end
    local item = obj.shortcuts[ctx.id] and obj.shortcuts[ctx.id][key]
    if not item then return end

    if item.type == "click" then
        local win = winmod.frontmostWindow()
        if not win then return end

        local currentPos = hs.mouse.absolutePosition()
        local f = win:frame()
        local x = f.x + (item.position.dx or 0)
        local y = f.y + (item.position.dy or 0)

        local config = obj.storage.loadConfig()
        local clickColor = config.clickAnimation and config.clickAnimation.color

        visuals.showClickAnimation({ x = x, y = y }, clickColor)
        InputHandler.postMouseClick({ x = x, y = y }, item.button or "left", item.clickCount or 1)
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

        InputHandler.executeDrag(
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
        InputHandler.executeKeyStroke(item.modifiers or {}, item.key or key)
    elseif item.type == "keyCombo" then
        -- executeKeyCombo 로직은 InputHandler로 이동 고려 가능하지만,
        -- 여기서는 InputHandler.executeKeyStroke를 반복 호출하는 방식으로 구현하거나
        -- InputHandler에 executeKeyCombo 추가
        -- 일단 기존 로직 유지하되 InputHandler 사용
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
            if k then InputHandler.executeKeyStroke(modifiers, k) end
        end
    elseif item.type == "text" then
        InputHandler.executeTextInput(item.text or "")
    end
end

-- 단축키 활성화
function execution.enableShortcuts(obj, appId, shortcuts)
    obj.activeAppShortcuts = shortcuts
    obj.activeAppId = appId
end

-- 단축키 비활성화
function execution.disableShortcuts(obj)
    obj.activeAppShortcuts = nil
    obj.activeAppId = nil
end

-- 단축키 키 처리
function execution.handleShortcutKey(obj, key)
    if not obj.activeAppShortcuts then return false end

    local shortcut = obj.activeAppShortcuts[key]
    if not shortcut then return false end

    if shortcut.type == "click" then
        local win = winmod.frontmostWindow()
        if not win then return false end

        local currentPos = hs.mouse.absolutePosition()
        local frame = win:frame()
        local x = frame.x + (shortcut.position.dx or 0)
        local y = frame.y + (shortcut.position.dy or 0)

        local config = obj.storage.loadConfig()
        local clickColor = config.clickAnimation and config.clickAnimation.color

        visuals.showClickAnimation({ x = x, y = y }, clickColor)
        InputHandler.postMouseClick({ x = x, y = y }, shortcut.button or "left", shortcut.clickCount or 1)
        hs.mouse.absolutePosition(currentPos)
        return true
    elseif shortcut.type == "drag" then
        local win = winmod.frontmostWindow()
        if not win then return false end

        local currentPos = hs.mouse.absolutePosition()
        local frame = win:frame()
        local startX = frame.x + (shortcut.startPosition.dx or shortcut.startPosition.x or 0)
        local startY = frame.y + (shortcut.startPosition.dy or shortcut.startPosition.y or 0)
        local endX = frame.x + (shortcut.endPosition.dx or shortcut.endPosition.x or 0)
        local endY = frame.y + (shortcut.endPosition.dy or shortcut.endPosition.y or 0)

        InputHandler.executeDrag(
            { x = startX, y = startY },
            { x = endX, y = endY },
            shortcut.button or "left",
            shortcut.duration or 0.1
        )
        hs.mouse.absolutePosition(currentPos)
        return true
    elseif shortcut.type == "mouseMove" then
        local currentPos = hs.mouse.absolutePosition()
        local position = shortcut.position
        if position.dx or position.dy then
            local win = winmod.frontmostWindow()
            if win then
                local frame = win:frame()
                position = { x = frame.x + (position.dx or 0), y = frame.y + (position.dy or 0) }
            end
        end
        hs.mouse.absolutePosition(position)
        hs.mouse.absolutePosition(currentPos)
        return true
    elseif shortcut.type == "key" then
        InputHandler.executeKeyStroke(shortcut.modifiers or {}, shortcut.key or key)
        return true
    elseif shortcut.type == "keyCombo" then
        -- 위와 동일한 로직
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
            if k then InputHandler.executeKeyStroke(modifiers, k) end
        end
        return true
    elseif shortcut.type == "text" then
        InputHandler.executeTextInput(shortcut.text or "")
        return true
    end

    return false
end

-- Key Tap 등록
function execution.registerKeyTap(obj)
    if obj.keyTap then return end

    obj.keyTap = eventtap.new({ eventtap.event.types.keyDown }, function(e)
        local flags = e:getFlags()
        if flags.cmd or flags.alt or flags.shift or flags.ctrl then return false end
        if obj.menuShowing then return false end
        if obj.shortcutPreviewCanvas then return false end

        local ch = e:getCharacters(true)
        if not ch then return false end
        ch = ch:lower()

        if execution.handleShortcutKey(obj, ch) then return true end

        local ctx = obj.contextObj
        if ctx and obj.shortcuts and obj.shortcuts[ctx.id] and obj.shortcuts[ctx.id][ch] then
            execution.perform(obj, ctx, ch)
            return true
        end

        return false
    end)

    obj.keyTap:start()
end

function execution.stop(obj)
    if obj.keyTap then
        obj.keyTap:stop()
        obj.keyTap = nil
    end
end

return execution
