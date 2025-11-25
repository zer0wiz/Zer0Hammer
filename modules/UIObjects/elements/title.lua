-- Title UI 객체 모듈
-- 타이틀 요소를 생성하는 모듈 (text element 기반)
local title = {}

-- text 모듈 로드
local currentDir = debug.getinfo(1, "S").source:match("@?(.*/)")
local text = dofile(currentDir .. "text.lua")

-- 타이틀 요소 생성
-- @param options table - 타이틀 옵션
--   - text: 타이틀 텍스트 (기본값: "")
--   - fontSize: 폰트 크기 (기본값: 16)
--   - textColor: 글자색 (기본값: {white = 1.0})
--   - backgroundColor: 배경색 (선택사항)
--   - width: 타이틀 레이어 넓이 (기본값: 100)
--   - height: 타이틀 레이어 높이 (기본값: 30)
--   - alignment: 정렬 ("left", "center", "right", 기본값: "left")
--   - frame: 위치 {x, y} (선택사항, width와 height는 무시됨)
-- @return table - 타이틀 요소 (text element 포함)
function title.create(options)
    options = options or {}
    
    local titleText = options.text or ""
    local fontSize = options.fontSize or 16
    local textColor = options.textColor or {white = 1.0}
    local backgroundColor = options.backgroundColor
    local width = options.width or 100
    local height = options.height or 30
    local alignment = options.alignment or "left"
    local frame = options.frame or {x = 0, y = 0}
    
    -- 텍스트 요소 생성
    local textElement = text.create({
        text = titleText,
        fontSize = fontSize,
        textColor = textColor,
        backgroundColor = backgroundColor,
        frame = {
            x = frame.x,
            y = frame.y,
            w = width,
            h = height
        },
        textAlignment = alignment
    })
    
    -- 타이틀 객체 반환
    return {
        _type = "title",
        _width = width,
        _height = height,
        _alignment = alignment,
        _textElement = textElement
    }
end

-- 타이틀 텍스트 업데이트
-- @param titleObj table - 타이틀 객체
-- @param newText string - 새로운 텍스트
function title.update(titleObj, newText)
    if titleObj and titleObj._type == "title" and titleObj._textElement then
        text.update(titleObj._textElement, newText)
    end
end

-- 타이틀을 canvas 요소로 변환
-- @param titleObj table - 타이틀 객체
-- @return table - canvas 요소
function title.toCanvasElement(titleObj)
    if not titleObj or titleObj._type ~= "title" then
        return nil
    end
    
    return titleObj._textElement
end

return title

