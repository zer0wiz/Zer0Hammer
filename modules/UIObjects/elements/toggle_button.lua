-- Toggle Button UI 객체 모듈
-- Hongsinstall 스타일의 토글 버튼을 생성하는 재사용 가능한 모듈
local toggle_button = {}

local canvas = hs.canvas

-- 토글 버튼 생성
-- @param options table - 토글 버튼 옵션
--   - x, y: 위치
--   - width: 너비 (기본값: 200)
--   - height: 높이 (기본값: 30)
--   - icon: 아이콘 (선택사항, hs.image 또는 이미지 경로)
--   - label: 레이블 텍스트
--   - value: 초기 값 (true/false, 기본값: false)
--   - onColor: ON 상태 색상 (기본값: {red = 0.2, green = 0.8, blue = 0.2})
--   - offColor: OFF 상태 색상 (기본값: {white = 0.3})
--   - trackColor: 트랙 색상 (기본값: {white = 0.2})
--   - thumbColor: 썸(동그라미) 색상 (기본값: {white = 1.0})
--   - labelColor: 레이블 색상 (기본값: {white = 1.0})
--   - labelSize: 레이블 폰트 크기 (기본값: 13)
--   - callback: 상태 변경 시 호출될 함수 function(value)
-- @return canvas 객체
function toggle_button.create(options)
    options = options or {}
    
    local width = options.width or 200
    local height = options.height or 30
    local x = options.x or 0
    local y = options.y or 0
    local label = options.label or ""
    local value = options.value or false
    
    -- 색상 설정
    local onColor = options.onColor or {red = 0.2, green = 0.8, blue = 0.2, alpha = 1.0}
    local offColor = options.offColor or {white = 0.3, alpha = 1.0}
    local trackColor = options.trackColor or {white = 0.2, alpha = 1.0}
    local thumbColor = options.thumbColor or {white = 1.0, alpha = 1.0}
    local labelColor = options.labelColor or {white = 1.0, alpha = 1.0}
    local labelSize = options.labelSize or 13
    local callback = options.callback
    
    -- 아이콘 영역 너비
    local iconSize = options.icon and (height - 8) or 0
    local iconSpacing = options.icon and 8 or 0
    local toggleWidth = 44
    local toggleHeight = 24
    local thumbRadius = 10
    local togglePadding = 2
    
    local c = canvas.new({
        x = x,
        y = y,
        w = width,
        h = height
    })
    
    c:level(canvas.windowLevels.popUpMenu)
    
    local elementIndex = 1
    
    -- 배경 (투명, 클릭 영역 확보)
    c[elementIndex] = {
        type = "rectangle",
        action = "fill",
        fillColor = {alpha = 0},
        frame = {x = 0, y = 0, w = width, h = height}
    }
    elementIndex = elementIndex + 1
    
    -- 아이콘 (있는 경우)
    if options.icon then
        if type(options.icon) == "string" then
            -- 이미지 경로
            c[elementIndex] = {
                type = "image",
                image = options.icon,
                frame = {x = 4, y = 4, w = iconSize, h = iconSize},
                imageScaling = "shrinkToFit",
                imageAlignment = "center"
            }
        else
            -- hs.image 객체
            c[elementIndex] = {
                type = "image",
                image = options.icon,
                frame = {x = 4, y = 4, w = iconSize, h = iconSize},
                imageScaling = "shrinkToFit",
                imageAlignment = "center"
            }
        end
        elementIndex = elementIndex + 1
    end
    
    -- 레이블 텍스트
    local labelX = iconSize + iconSpacing + 4
    c[elementIndex] = {
        id = "label",
        type = "text",
        text = label,
        textSize = labelSize,
        textColor = labelColor,
        frame = {x = labelX, y = 0, w = width - labelX - toggleWidth - 8, h = height},
        textAlignment = "left"
    }
    elementIndex = elementIndex + 1
    
    -- 토글 스위치 배경 (트랙)
    local toggleX = width - toggleWidth - 4
    local toggleY = (height - toggleHeight) / 2
    
    c[elementIndex] = {
        id = "track",
        type = "rectangle",
        action = "fill",
        fillColor = trackColor,
        frame = {x = toggleX, y = toggleY, w = toggleWidth, h = toggleHeight},
        roundedRectRadii = {xRadius = toggleHeight / 2, yRadius = toggleHeight / 2}
    }
    elementIndex = elementIndex + 1
    
    -- 토글 스위치 활성화 영역 (ON일 때만 보이는 색상)
    c[elementIndex] = {
        id = "trackActive",
        type = "rectangle",
        action = "fill",
        fillColor = onColor,
        frame = {x = toggleX, y = toggleY, w = toggleWidth, h = toggleHeight},
        roundedRectRadii = {xRadius = toggleHeight / 2, yRadius = toggleHeight / 2},
        alpha = value and 1.0 or 0.0
    }
    elementIndex = elementIndex + 1
    
    -- 토글 스위치 썸 (동그라미)
    local thumbX = value and (toggleX + toggleWidth - thumbRadius - togglePadding) or (toggleX + thumbRadius + togglePadding)
    local thumbY = toggleY + toggleHeight / 2
    
    c[elementIndex] = {
        id = "thumb",
        type = "circle",
        action = "fill",
        fillColor = thumbColor,
        center = {x = thumbX, y = thumbY},
        radius = thumbRadius
    }
    elementIndex = elementIndex + 1
    
    -- 클릭 영역 확장
    c[elementIndex] = {
        id = "clickArea",
        type = "rectangle",
        action = "fill",
        fillColor = {alpha = 0},
        frame = {x = 0, y = 0, w = width, h = height},
        trackMouseUp = true
    }
    elementIndex = elementIndex + 1
    
    -- 상태 저장 (canvas 객체에 직접 저장하는 대신 rawset 사용)
    rawset(c, "_toggleValue", value)
    rawset(c, "_toggleCallback", callback)
    
    -- 클릭 이벤트
    c:canvasMouseEvents(true, true, false, false)
    c:mouseCallback(function(canvas_obj, msg, id, x, y)
        if msg == "mouseUp" and id == "clickArea" then
            -- 토글 상태 변경
            local currentValue = rawget(canvas_obj, "_toggleValue")
            if currentValue ~= nil then
                local newValue = not currentValue
                toggle_button.setValue(canvas_obj, newValue)
            end
        end
    end)
    
    return c
end

-- 토글 버튼 값 설정
function toggle_button.setValue(canvas_obj, value)
    if not canvas_obj then return end
    
    rawset(canvas_obj, "_toggleValue", value)
    
    -- 썸 위치 업데이트
    local toggleWidth = 44
    local toggleHeight = 24
    local thumbRadius = 10
    local togglePadding = 2
    local width = canvas_obj:frame().w
    local toggleX = width - toggleWidth - 4
    local toggleY = (canvas_obj:frame().h - toggleHeight) / 2
    
    local thumbX = value and (toggleX + toggleWidth - thumbRadius - togglePadding) or (toggleX + thumbRadius + togglePadding)
    local thumbY = toggleY + toggleHeight / 2
    
    -- 썸 위치 업데이트
    if canvas_obj["thumb"] then
        canvas_obj["thumb"].center = {x = thumbX, y = thumbY}
    end
    
    -- 활성화 영역 표시/숨김
    if canvas_obj["trackActive"] then
        canvas_obj["trackActive"].alpha = value and 1.0 or 0.0
    end
    
    -- 콜백 호출
    local callback = rawget(canvas_obj, "_toggleCallback")
    if callback then
        callback(value)
    end
    
    return canvas_obj
end

-- 토글 버튼 값 가져오기
function toggle_button.getValue(canvas_obj)
    if not canvas_obj then return nil end
    return rawget(canvas_obj, "_toggleValue")
end

-- 토글 버튼 레이블 업데이트
function toggle_button.setLabel(canvas_obj, label)
    if not canvas_obj or not canvas_obj["label"] then return end
    canvas_obj["label"].text = label
    return canvas_obj
end

-- 토글 버튼 콜백 설정
function toggle_button.setCallback(canvas_obj, callback)
    if not canvas_obj then return end
    rawset(canvas_obj, "_toggleCallback", callback)
    return canvas_obj
end

return toggle_button

