-- AutoHotKeys 매크로 재생 모듈
local playback = {}

local eventtap = hs.eventtap
local timer = hs.timer
local winmod = hs.window
local execution = nil

-- execution 모듈 참조 설정 (init.lua에서 설정)
function playback.setExecution(executionModule)
    execution = executionModule
end

-- 좌표 변환 (녹화 시 윈도우 크기와 현재 윈도우 크기 비교)
local function convertPosition(action, obj)
    if not action.window then
        return action.position
    end
    
    -- 현재 액티브 윈도우 찾기
    local currentWin = winmod.frontmostWindow()
    if not currentWin then
        return action.position
    end
    
    -- 윈도우 매칭 시도 (앱 이름 및 제목으로)
    local winApp = currentWin:application()
    if winApp:name() ~= action.window.app or 
       currentWin:title() ~= action.window.title then
        -- 매칭되지 않으면 현재 윈도우 사용
    end
    
    if action.relativePosition then
        -- 상대 좌표 사용
        local frame = currentWin:frame()
        local scaleX = action.window.frame.w > 0 and frame.w / action.window.frame.w or 1.0
        local scaleY = action.window.frame.h > 0 and frame.h / action.window.frame.h or 1.0
        
        return {
            x = frame.x + (action.relativePosition.dx * scaleX),
            y = frame.y + (action.relativePosition.dy * scaleY)
        }
    else
        -- 절대 좌표 사용 (스케일링)
        local scaleX = action.window.frame.w > 0 and currentWin:frame().w / action.window.frame.w or 1.0
        local scaleY = action.window.frame.h > 0 and currentWin:frame().h / action.window.frame.h or 1.0
        
        return {
            x = action.position.x * scaleX,
            y = action.position.y * scaleY
        }
    end
end

-- 마우스 클릭 실행
local function executeMouseClick(position, button)
    local buttonType = eventtap.event.types.leftMouseDown
    if button == "right" then
        buttonType = eventtap.event.types.rightMouseDown
    elseif button == "middle" then
        buttonType = eventtap.event.types.otherMouseDown
    end
    
    local down = eventtap.event.newMouseEvent(buttonType, position)
    local up = eventtap.event.newMouseEvent(
        buttonType == eventtap.event.types.leftMouseDown and eventtap.event.types.leftMouseUp or
        (buttonType == eventtap.event.types.rightMouseDown and eventtap.event.types.rightMouseUp or
         eventtap.event.types.otherMouseUp),
        position
    )
    
    down:post()
    up:post()
end

-- 마우스 드래그 실행
local function executeMouseDrag(startPosition, endPosition, button, duration)
    local buttonType = eventtap.event.types.leftMouseDown
    if button == "right" then
        buttonType = eventtap.event.types.rightMouseDown
    elseif button == "middle" then
        buttonType = eventtap.event.types.otherMouseDown
    end
    
    local upType = buttonType == eventtap.event.types.leftMouseDown and eventtap.event.types.leftMouseUp or
                   (buttonType == eventtap.event.types.rightMouseDown and eventtap.event.types.rightMouseUp or
                    eventtap.event.types.otherMouseUp)
    
    local down = eventtap.event.newMouseEvent(buttonType, startPosition)
    down:post()
    
    -- 드래그 경로를 따라 이동
    local steps = math.max(10, math.floor(duration * 60)) -- 60fps 기준
    local stepDelay = (duration / steps) * 1000000 -- 마이크로초
    
    for i = 1, steps do
        local t = i / steps
        local x = startPosition.x + (endPosition.x - startPosition.x) * t
        local y = startPosition.y + (endPosition.y - startPosition.y) * t
        timer.usleep(stepDelay)
        
        local dragEvent = eventtap.event.newMouseEvent(
            buttonType == eventtap.event.types.leftMouseDown and eventtap.event.types.leftMouseDragged or
            (buttonType == eventtap.event.types.rightMouseDown and eventtap.event.types.rightMouseDragged or
             eventtap.event.types.otherMouseDragged),
            {x = x, y = y}
        )
        dragEvent:post()
    end
    
    local up = eventtap.event.newMouseEvent(upType, endPosition)
    up:post()
end

-- 매크로 재생
function playback.play(obj, macroName, options)
    options = options or {}
    
    if playback.isPlaying(obj) then
        return false, "이미 재생 중입니다"
    end
    
    local macro = obj.storage.loadMacro(macroName)
    if not macro then
        return false, "매크로를 찾을 수 없습니다: " .. macroName
    end
    
    local repeatCount = options.repeatCount or 1
    local speed = options.speed or 1.0
    local onComplete = options.onComplete
    local onError = options.onError
    
    obj.playback = {
        macro = macro,
        repeatCount = repeatCount,
        currentRepeat = 0,
        speed = speed,
        startTime = timer.absoluteTime(),
        currentActionIndex = 1,
        onComplete = onComplete,
        onError = onError,
        timer = nil
    }
    
    -- 첫 번째 반복 시작
    playback.playNextAction(obj)
    
    return true
end

-- 다음 액션 재생
function playback.playNextAction(obj)
    if not playback.isPlaying(obj) then
        return
    end
    
    local pb = obj.playback
    local actions = pb.macro.actions
    
    if pb.currentActionIndex > #actions then
        -- 현재 반복 완료
        pb.currentRepeat = pb.currentRepeat + 1
        
        if pb.repeatCount == 0 or pb.currentRepeat < pb.repeatCount then
            -- 다음 반복 시작
            pb.currentActionIndex = 1
            pb.startTime = timer.absoluteTime()
            playback.playNextAction(obj)
        else
            -- 모든 반복 완료
            playback.stop(obj)
            if pb.onComplete then
                pb.onComplete()
            end
        end
        return
    end
    
    local action = actions[pb.currentActionIndex]
    local previousAction = pb.currentActionIndex > 1 and actions[pb.currentActionIndex - 1] or nil
    
    -- 지연 시간 계산
    local delay = 0
    if previousAction then
        delay = (action.timestamp - previousAction.timestamp) / pb.speed
    else
        delay = action.timestamp / pb.speed
    end
    
    -- 지연 타이머 설정
    pb.timer = timer.doAfter(delay, function()
        if not playback.isPlaying(obj) then
            return
        end
        
        -- 액션 실행
        local success, err = pcall(function()
            if action.type == "mouseClick" then
                local position = convertPosition(action, obj)
                executeMouseClick(position, action.button or "left")
                
            elseif action.type == "mouseDrag" then
                local startPosition = convertPosition({position = action.startPosition, window = action.window, relativePosition = nil}, obj)
                local endPosition = convertPosition({position = action.endPosition, window = action.window, relativePosition = nil}, obj)
                executeMouseDrag(startPosition, endPosition, action.button or "left", action.duration or 0.1)
                
            elseif action.type == "mouseMove" then
                local position = convertPosition(action, obj)
                hs.mouse.absolutePosition(position)
                
            elseif action.type == "keyPress" then
                if action.key then
                    hs.eventtap.keyStroke(action.modifiers or {}, action.key, 0)
                end
                
            elseif action.type == "delay" then
                timer.usleep((action.milliseconds or 0) * 1000)
            end
        end)
        
        if not success and err then
            if pb.onError then
                pb.onError(err)
            end
            playback.stop(obj)
            return
        end
        
        -- 다음 액션으로 이동
        pb.currentActionIndex = pb.currentActionIndex + 1
        playback.playNextAction(obj)
    end)
end

-- 재생 중지
function playback.stop(obj)
    if not playback.isPlaying(obj) then
        return
    end
    
    if obj.playback.timer then
        obj.playback.timer:stop()
        obj.playback.timer = nil
    end
    
    obj.playback = nil
end

-- 재생 중 여부 확인
function playback.isPlaying(obj)
    return obj.playback ~= nil
end

-- 재생 속도 설정
function playback.setSpeed(obj, speed)
    if not playback.isPlaying(obj) then
        return false
    end
    
    obj.playback.speed = math.max(0.1, math.min(2.0, speed))
    return true
end

-- 현재 재생 중인 매크로 반환
function playback.getCurrentMacro(obj)
    if not playback.isPlaying(obj) then
        return nil
    end
    
    if not obj.playback.macro then
        return nil
    end
    
    return {
        name = obj.playback.macro.name or "Unknown",
        currentActionIndex = obj.playback.currentActionIndex or 0,
        totalActions = obj.playback.macro.actions and #obj.playback.macro.actions or 0,
        currentRepeat = obj.playback.currentRepeat or 0,
        repeatCount = obj.playback.repeatCount or 0,
        speed = obj.playback.speed or 1.0
    }
end

return playback
