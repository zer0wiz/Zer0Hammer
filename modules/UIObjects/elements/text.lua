-- Text UI 객체 모듈
-- 텍스트 요소를 생성하는 모듈
local text = {}

-- 텍스트 요소 생성
-- @param options table - 텍스트 옵션
--   - text: 텍스트 내용 (기본값: "")
--   - fontSize: 폰트 크기 (기본값: 14)
--   - textColor: 글자색 (기본값: {white = 1.0})
--   - backgroundColor: 배경색 (선택사항)
--   - frame: 위치와 크기 {x, y, w, h} (선택사항)
--   - textAlignment: 정렬 ("left", "center", "right", 기본값: "left")
-- @return table - canvas text 요소
function text.create(options)
    options = options or {}
    
    local textContent = options.text or ""
    local fontSize = options.fontSize or 14
    local textColor = options.textColor or {white = 1.0}
    local backgroundColor = options.backgroundColor
    local frame = options.frame or {x = 0, y = 0, w = 100, h = 20}
    local textAlignment = options.textAlignment or "left"
    
    local element = {
        type = "text",
        text = textContent,
        textSize = fontSize,
        textColor = textColor,
        frame = frame,
        textAlignment = textAlignment
    }
    
    -- 배경색이 있으면 배경 요소도 반환 (복합 요소)
    if backgroundColor then
        return {
            background = {
                type = "rectangle",
                action = "fill",
                fillColor = backgroundColor,
                frame = frame
            },
            text = element
        }
    end
    
    return element
end

-- 텍스트 요소 업데이트
-- @param element table - 텍스트 요소
-- @param newText string - 새로운 텍스트
function text.update(element, newText)
    if element and element.type == "text" then
        element.text = newText
    end
end

return text

