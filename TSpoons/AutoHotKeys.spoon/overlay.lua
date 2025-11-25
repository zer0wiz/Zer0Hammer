-- AutoHotKeys 오버레이 모듈
-- overlay: ctx 기준의 단축키 활성화 상태 표시용 작은 배지
-- - 단축키 활성화 상태 표시 (작은 "AK" 배지)
-- - 녹화/재생 상태 표시
-- - menu에서 단축키 추가 시 shortcut_preview와 함께 사용됨
-- - shortcut_preview: 단축키 위치 확인 및 추가 시 사용 (단축키 목록의 각 항목 표시)
local overlay = {}

local canvas = hs.canvas
local winmod = hs.window

-- 오버레이 생성
-- ctx 기준의 단축키 활성화 상태 표시용 작은 배지 생성
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
    
    obj.overlayCanvas = canvas.new({x = 0, y = 0, w = 32, h = 24})
    if not obj.overlayCanvas then return end
    
    obj.overlayCanvas:behavior(canvas.windowBehaviors.canJoinAllSpaces)
    obj.overlayCanvas:level(canvas.windowLevels.popUpMenu)
    
    -- 배경
    obj.overlayCanvas[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = {alpha = 0.85, red = 0, green = 0, blue = 0},
        roundedRectRadii = {xRadius = 6, yRadius = 6}
    }
    
    -- 아이콘/텍스트 (상태에 따라 변경됨)
    obj.overlayCanvas[2] = {
        type = "text",
        text = "AK",
        textSize = 12,
        textColor = {white = 1},
        textAlignment = "center",
        frame = {x = 0, y = 0, w = 32, h = 24}
    }
    
    -- 마우스 클릭 이벤트
    obj.overlayCanvas:mouseCallback(function(_, msg)
        if msg == "mouseUp" then
            if obj.menu.toggle then
                obj:menuToggle()
            elseif obj.menu and obj.menu.toggle then
                obj.menu.toggle(obj)
            end
        end
    end)
    
    obj.overlayVisible = false
    obj.overlayCanvas:hide()
end

-- 오버레이 업데이트
-- ctx 기준으로 단축키 활성화 상태를 확인하고 overlay 표시 여부 결정
-- 해당 ctx가 포커스 상태일 때 단축키 사용 가능 여부를 표시
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
    
    -- 토글된 컨텍스트인지 확인
    local isActiveContext = ctx and ctx.id and obj.activeContexts[ctx.id] ~= nil
    
    -- 녹화 중 또는 재생 중 상태 확인
    local isRecording = obj.recorder and obj.recorder.isRecording(obj)
    local isPlaying = obj.playback and obj.playback.isPlaying(obj)
    
    -- 토글된 컨텍스트가 아니고 녹화/재생도 아닌 경우 숨김
    if not isActiveContext and not (isRecording or isPlaying) then
        if obj.overlayVisible then
            obj.overlayCanvas:hide()
            obj.overlayVisible = false
        end
        return
    end
    
    -- 단축키가 없고 녹화/재생도 아닌 경우 숨김
    if not (ctx and (ctx.type == "app" or ctx.type == "browser") and (hasShortcuts or isRecording or isPlaying)) then
        if obj.overlayVisible then
            obj.overlayCanvas:hide()
            obj.overlayVisible = false
        end
        return
    end
    
    -- Hammerspoon이 포커스인 경우 실제 애플리케이션 찾기
    local win = winmod.frontmostWindow()
    if not win then
        if obj.overlayVisible then
            obj.overlayCanvas:hide()
            obj.overlayVisible = false
        end
        return
    end
    
    -- 현재 앱이 Hammerspoon인지 확인
    local app = win:application()
    if app then
        local bundleId = app:bundleID()
        if bundleId == "org.hammerspoon.Hammerspoon" or bundleId == "com.hammerspoon.Hammerspoon" then
            -- Hammerspoon이 포커스인 경우, 이전 포커스된 앱 찾기
            local allWindows = winmod.orderedWindows()
            for i = 2, #allWindows do  -- 첫 번째는 Hammerspoon이므로 두 번째부터
                local prevWin = allWindows[i]
                if prevWin then
                    local prevApp = prevWin:application()
                    if prevApp then
                        local prevBundleId = prevApp:bundleID()
                        if prevBundleId ~= "org.hammerspoon.Hammerspoon" and prevBundleId ~= "com.hammerspoon.Hammerspoon" then
                            win = prevWin
                            break
                        end
                    end
                end
            end
        end
    end
    
    local f = win:frame()
    local x = f.x + f.w - 38
    local y = f.y + 6
    obj.overlayCanvas:topLeft({x = x, y = y})
    
    -- 활성 컨텍스트인지 확인
    local ctxConfig = ctx and obj.storage.findContext(ctx.id)
    local isEnabled = ctxConfig and ctxConfig.enabled or false
    
    -- 상태에 따른 색상 및 텍스트 변경
    if isRecording then
        -- 녹화 중: 빨간색 배경, 빨간 점 아이콘
        obj.overlayCanvas[1].fillColor = {alpha = 0.9, red = 1.0, green = 0.2, blue = 0.2}
        obj.overlayCanvas[2].text = "●"
        obj.overlayCanvas[2].textColor = {white = 1}
        obj.overlayCanvas[2].textSize = 14
    elseif isPlaying then
        -- 재생 중: 파란색 배경, 재생 아이콘
        obj.overlayCanvas[1].fillColor = {alpha = 0.9, red = 0.2, green = 0.4, blue = 1.0}
        local currentMacro = obj.playback and obj.playback.getCurrentMacro(obj)
        obj.overlayCanvas[2].text = "▶"
        obj.overlayCanvas[2].textColor = {white = 1}
        obj.overlayCanvas[2].textSize = 12
    elseif isActiveContext and isEnabled then
        -- 활성 상태: 녹색 배경, 체크 아이콘
        obj.overlayCanvas[1].fillColor = {alpha = 0.9, red = 0.2, green = 0.8, blue = 0.2}
        obj.overlayCanvas[2].text = "✓"
        obj.overlayCanvas[2].textColor = {white = 1}
        obj.overlayCanvas[2].textSize = 14
    elseif isActiveContext and not isEnabled then
        -- 비활성 상태: 회색 배경, X 아이콘
        obj.overlayCanvas[1].fillColor = {alpha = 0.7, white = 0.4}
        obj.overlayCanvas[2].text = "✗"
        obj.overlayCanvas[2].textColor = {white = 0.9}
        obj.overlayCanvas[2].textSize = 12
    else
        -- 기본 상태: 검은색 배경, AK 텍스트
        obj.overlayCanvas[1].fillColor = {alpha = 0.85, red = 0, green = 0, blue = 0}
        obj.overlayCanvas[2].text = "AK"
        obj.overlayCanvas[2].textColor = {white = 1}
        obj.overlayCanvas[2].textSize = 11
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