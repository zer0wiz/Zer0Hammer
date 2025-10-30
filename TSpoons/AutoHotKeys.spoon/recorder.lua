-- AutoHotKeys 매크로 녹화 모듈
local recorder = {}

local eventtap = hs.eventtap
local event = eventtap.event
local timer = hs.timer
local winmod = hs.window

-- 녹화 시작
function recorder.start(obj, macroName)
    if recorder.isRecording(obj) then
        return false, "이미 녹화 중입니다"
    end
    
    obj.recording = {
        name = macroName or ("macro_" .. os.time()),
        context = obj.context.current(),
        startTime = timer.absoluteTime(),
        actions = {},
        paused = false,
        pauseStartTime = nil
    }
    
    -- 이벤트 탭 생성
    obj.recordingEventTap = eventtap.new({
        event.types.leftMouseDown,
        event.types.rightMouseDown,
        event.types.otherMouseDown,
        event.types.leftMouseUp,
        event.types.rightMouseUp,
        event.types.otherMouseUp,
        event.types.leftMouseDragged,
        event.types.rightMouseDragged,
        event.types.otherMouseDragged,
        event.types.mouseMoved,
        event.types.keyDown
    }, function(e)
        if not recorder.isRecording(obj) or obj.recording.paused then
            return false
        end
        
        local eventType = e:getType()
        local currentTime = timer.absoluteTime()
        local elapsed = (currentTime - obj.recording.startTime) / 1000000000.0
        
        -- 일시정지 시간 제외
        if obj.recording.pauseTime then
            elapsed = elapsed - obj.recording.pauseTime
        end
        
        -- 마우스 클릭 이벤트
        if eventType == event.types.leftMouseDown or 
           eventType == event.types.rightMouseDown or 
           eventType == event.types.otherMouseDown then
            local position = e:location()
            local win = winmod.windowAtPosition(position)
            
            local action = {
                type = "mouseClick",
                button = eventType == event.types.leftMouseDown and "left" or 
                        (eventType == event.types.rightMouseDown and "right" or "middle"),
                position = {x = position.x, y = position.y},
                timestamp = elapsed,
                window = win and {
                    app = win:application():name(),
                    bundleId = win:application():bundleID(),
                    title = win:title(),
                    frame = {x = win:frame().x, y = win:frame().y, w = win:frame().w, h = win:frame().h}
                } or nil
            }
            
            -- 윈도우 상대 좌표 계산
            if win then
                local frame = win:frame()
                action.relativePosition = {
                    dx = position.x - frame.x,
                    dy = position.y - frame.y
                }
            end
            
            table.insert(obj.recording.actions, action)
            
        -- 마우스 드래그 이벤트
        elseif eventType == event.types.leftMouseDragged or 
               eventType == event.types.rightMouseDragged or 
               eventType == event.types.otherMouseDragged then
            local position = e:location()
            
            -- 드래그 시작 액션이 없으면 추가
            local lastAction = obj.recording.actions[#obj.recording.actions]
            if not lastAction or lastAction.type ~= "mouseDrag" then
                local win = winmod.windowAtPosition(position)
                local action = {
                    type = "mouseDrag",
                    startPosition = {x = position.x, y = position.y},
                    endPosition = {x = position.x, y = position.y},
                    duration = 0,
                    timestamp = elapsed,
                    button = eventType == event.types.leftMouseDragged and "left" or 
                            (eventType == event.types.rightMouseDragged and "right" or "middle"),
                    window = win and {
                        app = win:application():name(),
                        bundleId = win:application():bundleID(),
                        title = win:title(),
                        frame = {x = win:frame().x, y = win:frame().y, w = win:frame().w, h = win:frame().h}
                    } or nil
                }
                table.insert(obj.recording.actions, action)
            else
                -- 드래그 액션 업데이트
                lastAction.endPosition = {x = position.x, y = position.y}
                lastAction.duration = elapsed - lastAction.timestamp
            end
            
        -- 마우스 이동 이벤트 (드래그가 아닐 때만)
        elseif eventType == event.types.mouseMoved then
            local flags = e:getFlags()
            if not flags.left and not flags.right and not flags.other then
                local position = e:location()
                local action = {
                    type = "mouseMove",
                    position = {x = position.x, y = position.y},
                    timestamp = elapsed
                }
                table.insert(obj.recording.actions, action)
            end
            
        -- 키 입력 이벤트
        elseif eventType == event.types.keyDown then
            local keyCode = e:getKeyCode()
            local flags = e:getFlags()
            local characters = e:getCharacters()
            
            local modifiers = {}
            if flags.cmd then table.insert(modifiers, "cmd") end
            if flags.alt then table.insert(modifiers, "alt") end
            if flags.shift then table.insert(modifiers, "shift") end
            if flags.ctrl then table.insert(modifiers, "ctrl") end
            
            local action = {
                type = "keyPress",
                key = characters or hs.keycodes.map[keyCode],
                keyCode = keyCode,
                modifiers = modifiers,
                timestamp = elapsed
            }
            
            table.insert(obj.recording.actions, action)
        end
        
        return false
    end)
    
    obj.recordingEventTap:start()
    
    return true
end

-- 녹화 중지
function recorder.stop(obj)
    if not recorder.isRecording(obj) then
        return false, "녹화 중이 아닙니다"
    end
    
    if obj.recordingEventTap then
        obj.recordingEventTap:stop()
        obj.recordingEventTap = nil
    end
    
    local currentTime = timer.absoluteTime()
    local totalDuration = (currentTime - obj.recording.startTime) / 1000000000.0
    
    -- 일시정지 시간 제외
    if obj.recording.pauseTime then
        totalDuration = totalDuration - obj.recording.pauseTime
    end
    
    local macro = {
        name = obj.recording.name,
        createdAt = os.time(),
        context = obj.recording.context,
        actions = obj.recording.actions,
        totalDuration = totalDuration
    }
    
    local recording = obj.recording
    obj.recording = nil
    
    return true, macro
end

-- 녹화 일시정지
function recorder.pause(obj)
    if not recorder.isRecording(obj) or obj.recording.paused then
        return false
    end
    
    obj.recording.paused = true
    obj.recording.pauseStartTime = timer.absoluteTime()
    
    return true
end

-- 녹화 재개
function recorder.resume(obj)
    if not recorder.isRecording(obj) or not obj.recording.paused then
        return false
    end
    
    if obj.recording.pauseStartTime then
        local pauseDuration = (timer.absoluteTime() - obj.recording.pauseStartTime) / 1000000000.0
        obj.recording.pauseTime = (obj.recording.pauseTime or 0) + pauseDuration
    end
    
    obj.recording.paused = false
    obj.recording.pauseStartTime = nil
    
    return true
end

-- 녹화 중 여부 확인
function recorder.isRecording(obj)
    return obj.recording ~= nil
end

-- 현재 녹화 중인 매크로 반환
function recorder.getCurrentMacro(obj)
    if not recorder.isRecording(obj) then
        return nil
    end
    
    local currentTime = timer.absoluteTime()
    local totalDuration = (currentTime - obj.recording.startTime) / 1000000000.0
    
    if obj.recording.pauseTime then
        totalDuration = totalDuration - obj.recording.pauseTime
    end
    
    return {
        name = obj.recording.name,
        context = obj.recording.context,
        actions = obj.recording.actions,
        totalDuration = totalDuration,
        paused = obj.recording.paused
    }
end

return recorder
