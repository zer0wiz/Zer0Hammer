-- Divider UI 객체 모듈
-- 구분선 요소를 생성하는 모듈
local divider = {}

-- 구분선 요소 생성
-- @param options table - 구분선 옵션
--   - color: 색상 (기본값: {white = 0.5})
--   - width: 넓이 (메뉴 기본틀 기준 비율, 100=기본틀넓이, 기본값: 100)
--   - alignment: 정렬 ("left", "center", "right", 기본값: "center")
--   - baseWidth: 기준 너비 (비율 계산용, 기본값: 100)
--   - y: Y 위치 (기본값: 0)
--   - height: 선의 높이 (기본값: 1)
-- @return table - canvas line 요소
function divider.create(options)
    options = options or {}
    
    local color = options.color or {white = 0.5, alpha = 1.0}
    local widthPercent = options.width or 100
    local alignment = options.alignment or "center"
    local baseWidth = options.baseWidth or 100
    local y = options.y or 0
    local height = options.height or 1
    
    -- 비율에 따른 실제 너비 계산
    local actualWidth = (baseWidth * widthPercent) / 100
    
    -- 정렬에 따른 X 위치 계산
    local x = 0
    if alignment == "center" then
        x = (baseWidth - actualWidth) / 2
    elseif alignment == "right" then
        x = baseWidth - actualWidth
    end
    -- "left"인 경우 x = 0 (이미 설정됨)
    
    local element = {
        type = "segments",
        action = "stroke",
        strokeColor = color,
        strokeWidth = height,
        coordinates = {
            {x = x, y = y},
            {x = x + actualWidth, y = y}
        }
    }
    
    return element
end

return divider

