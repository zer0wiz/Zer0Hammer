-- AutoHotKeys Input Handler (Core)
local InputHandler = {}

local eventtap = hs.eventtap
local event = eventtap.event
local timer = hs.timer

-- 마우스 클릭 실행
function InputHandler.postMouseClick(point, button, clickCount)
    button = button or "left"
    clickCount = clickCount or 1
    
    local buttonType
    if button == "right" then
        buttonType = event.types.rightMouseDown
    elseif button == "middle" then
        buttonType = event.types.otherMouseDown
    else
        buttonType = event.types.leftMouseDown
    end
    
    local upType
    if button == "right" then
        upType = event.types.rightMouseUp
    elseif button == "middle" then
        upType = event.types.otherMouseUp
    else
        upType = event.types.leftMouseUp
    end
    
    for i = 1, clickCount do
        local down = event.newMouseEvent(buttonType, point)
        local up = event.newMouseEvent(upType, point)
        down:post()
        up:post()
        
        if i < clickCount then
            timer.usleep(100000) -- 더블 클릭 간격 (100ms)
        end
    end
end

-- 마우스 드래그 실행
function InputHandler.executeDrag(startPosition, endPosition, button, duration)
    button = button or "left"
    duration = duration or 0.1
    
    local buttonType
    if button == "right" then
        buttonType = event.types.rightMouseDown
    elseif button == "middle" then
        buttonType = event.types.otherMouseDown
    else
        buttonType = event.types.leftMouseDown
    end
    
    local upType
    if button == "right" then
        upType = event.types.rightMouseUp
    elseif button == "middle" then
        upType = event.types.otherMouseUp
    else
        upType = event.types.leftMouseUp
    end
    
    local dragType
    if button == "right" then
        dragType = event.types.rightMouseDragged
    elseif button == "middle" then
        dragType = event.types.otherMouseDragged
    else
        dragType = event.types.leftMouseDragged
    end
    
    -- 마우스 다운
    local down = event.newMouseEvent(buttonType, startPosition)
    down:post()
    
    -- 드래그 경로를 따라 이동
    local steps = math.max(10, math.floor(duration * 60)) -- 60fps 기준
    local stepDelay = (duration / steps) * 1000000 -- 마이크로초
    
    for i = 1, steps do
        local t = i / steps
        local x = startPosition.x + (endPosition.x - startPosition.x) * t
        local y = startPosition.y + (endPosition.y - startPosition.y) * t
        timer.usleep(stepDelay)
        
        local dragEvent = event.newMouseEvent(dragType, {x = x, y = y})
        dragEvent:post()
    end
    
    -- 마우스 업
    local up = event.newMouseEvent(upType, endPosition)
    up:post()
end

-- 키 입력 실행
function InputHandler.executeKeyStroke(modifiers, key)
    eventtap.keyStroke(modifiers or {}, key, 0)
end

-- 텍스트 입력 실행
function InputHandler.executeTextInput(text)
    eventtap.keyStrokes(text)
end

return InputHandler
