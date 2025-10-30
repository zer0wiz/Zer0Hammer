-- AutoHotKeys 실행 모듈
local execution = {}

local eventtap = hs.eventtap
local winmod = hs.window
local timer = hs.timer

-- 좌클릭 발생
local function postLeftClick(point)
    local down = eventtap.event.newMouseEvent(eventtap.event.types.leftMouseDown, point)
    local up = eventtap.event.newMouseEvent(eventtap.event.types.leftMouseUp, point)
    down:post()
    up:post()
end

-- 액션 수행
function execution.perform(obj, ctx, key)
    if not obj.shortcuts then
        obj.shortcuts = {}
    end
    local item = obj.shortcuts[ctx.id] and obj.shortcuts[ctx.id][key]
    if not item then return end
    
    if item.type == "click" then
        local win = winmod.frontmostWindow()
        if not win then return end
        
        local f = win:frame()
        local x = f.x + (item.position.dx or 0)
        local y = f.y + (item.position.dy or 0)
        
        postLeftClick({x = x, y = y})
        
    elseif item.type == "delay" then
        local ms = tonumber(item.milliseconds or 0) or 0
        timer.usleep(ms * 1000)
        
    elseif item.type == "key" then
        local k = item.key or key
        hs.eventtap.keyStroke(item.modifiers or {}, k, 0)
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
    if not obj.activeAppShortcuts then
        return false
    end
    
    local shortcut = obj.activeAppShortcuts[key]
    if not shortcut then
        return false
    end
    
    if shortcut.type == "click" then
        local win = winmod.frontmostWindow()
        if not win then return false end
        
        local frame = win:frame()
        local x = frame.x + (shortcut.position.dx or 0)
        local y = frame.y + (shortcut.position.dy or 0)
        
        postLeftClick({x = x, y = y})
        return true
    end
    
    return false
end

-- Key Tap 등록
function execution.registerKeyTap(obj)
    if obj.keyTap then return end
    
    obj.keyTap = eventtap.new({eventtap.event.types.keyDown}, function(e)
        local flags = e:getFlags()
        
        -- 수정자 키 체크
        if flags.cmd or flags.alt or flags.shift or flags.ctrl then
            return false
        end
        
        -- 메뉴 표시 중 체크
        if obj.menuShowing then
            return false
        end
        
        -- 미리보기 레이어 표시 중 체크
        if obj.shortcutPreviewCanvas then
            return false
        end
        
        local ch = e:getCharacters(true)
        if not ch then return false end
        ch = ch:lower()
        
        -- 활성화된 앱의 단축키 처리
        if execution.handleShortcutKey(obj, ch) then
            return true -- 이벤트 소비
        end
        
        -- 기존 컨텍스트 기반 단축키 처리 (하위 호환성)
        local ctx = obj.contextObj
        if ctx and obj.shortcuts and obj.shortcuts[ctx.id] and obj.shortcuts[ctx.id][ch] then
            execution.perform(obj, ctx, ch)
            return true
        end
        
        return false
    end)
    
    obj.keyTap:start()
end

-- Key Tap 정지
function execution.stop(obj)
    if obj.keyTap then
        obj.keyTap:stop()
        obj.keyTap = nil
    end
end

return execution

