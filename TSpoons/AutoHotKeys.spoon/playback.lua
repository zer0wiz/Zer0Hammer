-- AutoHotKeys 매크로 재생 모듈
local playback = {}

local timer = hs.timer
local winmod = hs.window
local InputHandler = require("core.InputHandler")

local execution = nil

function playback.setExecution(executionModule)
    execution = executionModule
end

-- 좌표 변환
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

function playback.play(obj, macroName, options)
    options = options or {}
    if playback.isPlaying(obj) then return false, "Already playing" end
    
    local macro = obj.storage.loadMacro(macroName)
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
    
    playback.playNextAction(obj)
    return true
end

function playback.playNextAction(obj)
    if not playback.isPlaying(obj) then return end
    
    local pb = obj.playback
    local actions = pb.macro.actions
    
    if pb.currentActionIndex > #actions then
        pb.currentRepeat = pb.currentRepeat + 1
        if pb.repeatCount == 0 or pb.currentRepeat < pb.repeatCount then
            pb.currentActionIndex = 1
            pb.startTime = timer.absoluteTime()
            playback.playNextAction(obj)
        else
            playback.stop(obj)
            if pb.onComplete then pb.onComplete() end
        end
        return
    end
    
    local action = actions[pb.currentActionIndex]
    local previousAction = pb.currentActionIndex > 1 and actions[pb.currentActionIndex - 1] or nil
    local delay = previousAction and (action.timestamp - previousAction.timestamp) / pb.speed or (action.timestamp / pb.speed)
    
    pb.timer = timer.doAfter(delay, function()
        if not playback.isPlaying(obj) then return end
        
        local success, err = pcall(function()
            if action.type == "mouseClick" then
                local position = convertPosition(action, obj)
                InputHandler.postMouseClick(position, action.button or "left")
                
            elseif action.type == "mouseDrag" then
                local startPos, endPos
                if action.startRelativePosition and action.window then
                    local win = winmod.frontmostWindow()
                    if win then
                        local frame = win:frame()
                        local scaleX = action.window.frame.w > 0 and frame.w / action.window.frame.w or 1.0
                        local scaleY = action.window.frame.h > 0 and frame.h / action.window.frame.h or 1.0
                        startPos = {
                            x = frame.x + (action.startRelativePosition.dx * scaleX),
                            y = frame.y + (action.startRelativePosition.dy * scaleY)
                        }
                        endPos = {
                            x = frame.x + ((action.endRelativePosition and action.endRelativePosition.dx or action.startRelativePosition.dx) * scaleX),
                            y = frame.y + ((action.endRelativePosition and action.endRelativePosition.dy or action.startRelativePosition.dy) * scaleY)
                        }
                    else
                        startPos = convertPosition({position = action.startPosition, window = action.window}, obj)
                        endPos = convertPosition({position = action.endPosition, window = action.window}, obj)
                    end
                else
                    startPos = convertPosition({position = action.startPosition, window = action.window}, obj)
                    endPos = convertPosition({position = action.endPosition, window = action.window}, obj)
                end
                InputHandler.executeDrag(startPos, endPos, action.button or "left", action.duration or 0.1)
                
            elseif action.type == "mouseMove" then
                local position = convertPosition(action, obj)
                hs.mouse.absolutePosition(position)
                
            elseif action.type == "keyPress" then
                if action.key then
                    InputHandler.executeKeyStroke(action.modifiers or {}, action.key)
                end
                
            elseif action.type == "delay" then
                timer.usleep((action.milliseconds or 0) * 1000)
            end
        end)
        
        if not success and err then
            if pb.onError then pb.onError(err) end
            playback.stop(obj)
            return
        end
        
        pb.currentActionIndex = pb.currentActionIndex + 1
        playback.playNextAction(obj)
    end)
end

function playback.stop(obj)
    if not playback.isPlaying(obj) then return end
    if obj.playback.timer then
        obj.playback.timer:stop()
        obj.playback.timer = nil
    end
    obj.playback = nil
end

function playback.isPlaying(obj)
    return obj.playback ~= nil
end

function playback.setSpeed(obj, speed)
    if not playback.isPlaying(obj) then return false end
    obj.playback.speed = math.max(0.1, math.min(2.0, speed))
    return true
end

function playback.getCurrentMacro(obj)
    if not playback.isPlaying(obj) then return nil end
    if not obj.playback.macro then return nil end
    
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
