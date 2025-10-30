-- AutoHotKeys 단축키 미리보기 모듈
local shortcut_preview = {}

local canvas = hs.canvas
local winmod = hs.window
local eventtap = hs.eventtap
local event = eventtap.event
local dialog = hs.dialog

-- 컬러 헥스를 RGB로 변환
local function hexToRGB(hex)
    hex = hex:gsub("#", "")
    local r = tonumber("0x" .. hex:sub(1, 2)) / 255.0
    local g = tonumber("0x" .. hex:sub(3, 4)) / 255.0
    local b = tonumber("0x" .. hex:sub(5, 6)) / 255.0
    return {red = r, green = g, blue = b}
end

-- 미리보기 레이어 표시
function shortcut_preview.show(obj, ctx)
    -- 이미 표시 중이면 숨김
    if obj.shortcutPreviewCanvas then
        shortcut_preview.hide(obj)
        return
    end
    
    local win = winmod.frontmostWindow()
    if not win then
        hs.alert.show("활성화된 윈도우가 없습니다")
        return
    end
    
    local winFrame = win:frame()
    local screen = win:screen()
    local screenFrame = screen:fullFrame()
    
    -- 전체 화면 캔버스 생성
    local c = canvas.new(screenFrame)
    c:level(canvas.windowLevels.overlay)
    c:behavior(canvas.windowBehaviors.canJoinAllSpaces)
    
    -- Config 로드
    local config = obj.storage.loadConfig()
    local previewConfig = config.shortcutPreview
    
    -- 1. 그레이 오버레이
    local overlayColor = hexToRGB(previewConfig.overlay.color)
    c[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = {
            red = overlayColor.red,
            green = overlayColor.green,
            blue = overlayColor.blue,
            alpha = previewConfig.overlay.alpha
        },
        frame = screenFrame
    }
    
    -- 2. 앱별 설정 로드
    local appId = "app:" .. ctx.bundleId
    local appConfig = obj.storage.loadAppConfig(appId)
    local shortcuts = appConfig and appConfig.shortcuts or {}
    
    -- 3. 각 단축키 위치에 원 그리기
    local circleConfig = previewConfig.circle
    local circleColor = hexToRGB(circleConfig.fillColor)
    local textConfig = previewConfig.text
    local textColor = hexToRGB(textConfig.color)
    
    local index = 2
    for key, shortcut in pairs(shortcuts) do
        if shortcut.type == "click" and shortcut.position then
            -- 윈도우 좌표를 화면 좌표로 변환
            local screenX = winFrame.x + shortcut.position.dx
            local screenY = winFrame.y + shortcut.position.dy
            
            -- 원 그리기
            c[index] = {
                type = "circle",
                action = "fillStroke",
                fillColor = {
                    red = circleColor.red,
                    green = circleColor.green,
                    blue = circleColor.blue,
                    alpha = circleConfig.fillAlpha
                },
                strokeColor = hexToRGB(circleConfig.strokeColor),
                strokeWidth = circleConfig.strokeWidth,
                center = {x = screenX, y = screenY},
                radius = circleConfig.radius
            }
            
            -- 텍스트 그리기
            c[index + 1] = {
                type = "text",
                text = key,
                textSize = textConfig.size,
                textColor = textColor,
                textFont = textConfig.font,
                frame = {
                    x = screenX - circleConfig.radius,
                    y = screenY - circleConfig.radius,
                    w = circleConfig.radius * 2,
                    h = circleConfig.radius * 2
                },
                textAlignment = "center"
            }
            
            index = index + 2
        end
    end
    
    -- ESC 키로 닫기
    obj.shortcutPreviewEscapeKey = hs.hotkey.bind({}, "escape", function()
        shortcut_preview.hide(obj)
    end)
    
    -- 외부 클릭으로 닫기 (마우스 이벤트는 나중에 추가)
    
    c:show()
    obj.shortcutPreviewCanvas = c
    obj.shortcutPreviewContext = ctx
    obj.shortcutPreviewWindow = win
    
    -- ctrl+click 모드 활성화
    shortcut_preview.enableAddMode(obj)
end

-- 미리보기 레이어 숨김
function shortcut_preview.hide(obj)
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
    
    obj.shortcutPreviewContext = nil
    obj.shortcutPreviewWindow = nil
end

-- 단축키 추가 모드 활성화
function shortcut_preview.enableAddMode(obj)
    if obj.shortcutPreviewMouseTap then
        obj.shortcutPreviewMouseTap:stop()
    end
    
    obj.shortcutPreviewMouseTap = eventtap.new({
        event.types.leftMouseDown
    }, function(e)
        local flags = e:getFlags()
        if not flags.ctrl then
            return false -- 이벤트 소비하지 않음
        end
        
        -- ctrl+click 감지
        local position = e:location()
        local win = obj.shortcutPreviewWindow
        if not win then return false end
        
        local winFrame = win:frame()
        
        -- 윈도우 내부인지 확인
        if position.x < winFrame.x or position.x > winFrame.x + winFrame.w or
           position.y < winFrame.y or position.y > winFrame.y + winFrame.h then
            -- 외부 클릭이면 레이어 닫기
            shortcut_preview.hide(obj)
            return false
        end
        
        -- 상대 좌표 계산
        local relativePos = {
            dx = position.x - winFrame.x,
            dy = position.y - winFrame.y
        }
        
        -- 단축키 입력 다이얼로그
        local _, key = dialog.textPrompt(
            "단축키 입력",
            "저장할 단축키를 입력하세요 (한 글자)",
            "",
            "OK",
            "Cancel"
        )
        
        if not key or key == "" or #key > 1 then
            return true -- 이벤트 소비
        end
        
        key = key:sub(1, 1):lower()
        
        -- 단축키 저장
        local ctx = obj.shortcutPreviewContext
        local appId = "app:" .. ctx.bundleId
        obj.storage.saveAppShortcut(appId, key, relativePos, ctx.appName, ctx.bundleId)
        
        -- Alert 표시
        hs.alert.show(string.format("단축키 '%s'가 저장되었습니다", key), 3.0)
        
        -- 미리보기 다시 표시
        shortcut_preview.hide(obj)
        hs.timer.doAfter(0.1, function()
            shortcut_preview.show(obj, ctx)
        end)
        
        return true -- 이벤트 소비
    end)
    
    obj.shortcutPreviewMouseTap:start()
end

return shortcut_preview

