-- AutoHotKeys 오버레이 모듈
local overlay = {}

local canvas = hs.canvas
local winmod = hs.window

-- 오버레이 생성
function overlay.init(obj)
    if obj.overlayCanvas then 
        -- overlay가 이미 존재하면 유효성 확인
        if obj.overlayCanvas.topLeft then
            return -- 유효한 overlay면 그대로 사용
        else
            -- 유효하지 않은 overlay면 삭제하고 재생성
            pcall(function() obj.overlayCanvas:delete() end)
            obj.overlayCanvas = nil
        end
    end
    
    obj.overlayCanvas = canvas.new({x = 0, y = 0, w = 28, h = 20})
    if not obj.overlayCanvas then return end
    
    obj.overlayCanvas:behavior(canvas.windowBehaviors.canJoinAllSpaces)
    obj.overlayCanvas:level(canvas.windowLevels.popUpMenu)
    
    -- 배경
    obj.overlayCanvas[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = {alpha = 0.85, red = 0, green = 0, blue = 0},
        roundedRectRadii = {xRadius = 5, yRadius = 5}
    }
    
    -- 텍스트
    obj.overlayCanvas[2] = {
        type = "text",
        text = "AK",
        textSize = 11,
        textColor = {white = 1},
        textAlignment = "center"
    }
    
    -- 마우스 클릭 이벤트
    obj.overlayCanvas:mouseCallback(function(_, msg)
        if msg == "mouseUp" then
            if obj.menutoggle then
                obj:menutoggle()
            elseif obj.menu and obj.menu.toggle then
                obj.menu.toggle(obj)
            end
        end
    end)
    
    obj.overlayVisible = false
    obj.overlayCanvas:hide()
end

-- 오버레이 업데이트
function overlay.update(obj)
    overlay.init(obj)
    
    -- overlay가 제대로 초기화되지 않았으면 종료
    if not obj.overlayCanvas or not obj.overlayCanvas.topLeft then
        return
    end
    
    -- 오버레이 활성화 여부 확인
    local config = obj.storage.loadConfig()
    local overlayEnabled = config.overlay and config.overlay.enabled or false
    
    -- 오버레이가 비활성화되어 있으면 숨김
    if not overlayEnabled then
        if obj.overlayVisible then
            obj.overlayCanvas:hide()
            obj.overlayVisible = false
        end
        return
    end
    
    local ctx = obj.contextObj
    local hasShortcuts = ctx and obj.shortcuts and obj.shortcuts[ctx.id] and next(obj.shortcuts[ctx.id]) ~= nil
    
    -- 녹화 중 또는 재생 중 상태 확인
    local isRecording = obj.recorder and obj.recorder.isRecording(obj)
    local isPlaying = obj.playback and obj.playback.isPlaying(obj)
    
    -- 단축키가 없고 녹화/재생도 아닌 경우 숨김
    if not (ctx and (ctx.kind == "app" or ctx.kind == "site") and (hasShortcuts or isRecording or isPlaying)) then
        if obj.overlayVisible then
            obj.overlayCanvas:hide()
            obj.overlayVisible = false
        end
        return
    end
    
    local win = winmod.frontmostWindow()
    if not win then
        if obj.overlayVisible then
            obj.overlayCanvas:hide()
            obj.overlayVisible = false
        end
        return
    end
    
    local f = win:frame()
    local x = f.x + f.w - 34
    local y = f.y + 6
    obj.overlayCanvas:topLeft({x = x, y = y})
    
    -- 상태에 따른 색상 및 텍스트 변경
    if isRecording then
        obj.overlayCanvas[1].fillColor = {alpha = 0.85, red = 1.0, green = 0, blue = 0}
        obj.overlayCanvas[2].text = "REC"
    elseif isPlaying then
        obj.overlayCanvas[1].fillColor = {alpha = 0.85, red = 0, green = 0, blue = 1.0}
        local currentMacro = obj.playback and obj.playback.getCurrentMacro(obj)
        obj.overlayCanvas[2].text = currentMacro and (string.sub(currentMacro.name, 1, 3)) or "PLAY"
    else
        obj.overlayCanvas[1].fillColor = {alpha = 0.85, red = 0, green = 0, blue = 0}
        obj.overlayCanvas[2].text = "AK"
    end
    
    obj.overlayCanvas:show()
    obj.overlayVisible = true
end

-- 녹화 상태 표시
function overlay.showRecordingState(obj, isRecording)
    overlay.update(obj)
end

-- 재생 상태 표시
function overlay.showPlaybackState(obj, macroName)
    overlay.update(obj)
end

-- 오버레이 정지
function overlay.stop(obj)
    if obj.overlayCanvas then
        obj.overlayCanvas:delete()
        obj.overlayCanvas = nil
    end
    obj.overlayVisible = false
end

return overlay