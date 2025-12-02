-- Layer UI 객체 모듈
-- 테이블 구조의 레이어를 생성하는 모듈
local layer = {}

-- 레이어 생성
-- @param options table - 레이어 옵션
--   - rows: 행 개수 (기본값: 1)
--   - cols: 열 개수 (기본값: 1)
--   - width: 전체 너비 (기본값: 100)
--   - height: 전체 높이 (기본값: 100)
--   - r_width: 행별 기본 너비 배열 (선택사항)
--   - c_height: 열별 기본 높이 배열 (선택사항)
--   - alpha: 투명도 (기본값: 1.0)
--   - backgroundColor: 배경색 (선택사항)
-- @return layer 객체 (테이블 구조)
function layer.create(options)
    options = options or {}
    
    local rows = options.rows or 1
    local cols = options.cols or 1
    local width = options.width or 100
    local height = options.height or 100
    local alpha = options.alpha or 1.0
    local backgroundColor = options.backgroundColor
    
    -- 기본 열 너비 배열 (균등 분배)
    -- r_width는 열(col)별 너비를 의미
    local r_width = options.r_width or {}
    if #r_width == 0 then
        for i = 1, cols do
            r_width[i] = {width = width / cols}
        end
    end
    
    -- 기본 행 높이 배열 (균등 분배)
    -- c_height는 행(row)별 높이를 의미
    local c_height = options.c_height or {}
    if #c_height == 0 then
        for i = 1, rows do
            c_height[i] = height / rows
        end
    end
    
    -- 레이어 객체 생성
    local layerObj = {
        _type = "layer",
        _rows = rows,
        _cols = cols,
        _width = width,
        _height = height,
        _alpha = alpha,
        _backgroundColor = backgroundColor,
        _r_width = r_width,
        _c_height = c_height,
        _elements = {} -- [row][col] = element
    }
    
    -- 메타테이블 설정으로 [row][col] 접근 지원
    setmetatable(layerObj, {
        __index = function(t, k)
            if type(k) == "number" then
                -- 행 접근
                local row = t._elements[k] or {}
                setmetatable(row, {
                    __index = function(row_t, col_k)
                        if type(col_k) == "number" then
                            return row_t[col_k]
                        end
                        return nil
                    end,
                    __newindex = function(row_t, col_k, val)
                        if type(col_k) == "number" then
                            rawset(row_t, col_k, val)
                        else
                            rawset(row_t, col_k, val)
                        end
                    end
                })
                t._elements[k] = row
                return row
            end
            return rawget(t, k)
        end,
        __newindex = function(t, k, v)
            if type(k) == "number" then
                -- 행 할당
                t._elements[k] = v
            else
                rawset(t, k, v)
            end
        end
    })
    
    return layerObj
end

-- 레이어의 특정 셀 위치 계산
-- @param layerObj table - 레이어 객체
-- @param row number - 행 인덱스 (1부터 시작)
-- @param col number - 열 인덱스 (1부터 시작)
-- @return x, y, w, h - 셀의 위치와 크기
function layer.getCellBounds(layerObj, row, col)
    if not layerObj or not layerObj._type == "layer" then
        return nil
    end
    
    if row < 1 or row > layerObj._rows or col < 1 or col > layerObj._cols then
        return nil
    end
    
    local x = 0
    local y = 0
    
    -- X 위치 계산 (이전 열들의 너비 합)
    -- r_width는 열(col)별 너비를 의미
    for c = 1, col - 1 do
        if layerObj._r_width[c] and layerObj._r_width[c].width then
            x = x + layerObj._r_width[c].width
        else
            x = x + (layerObj._width / layerObj._cols)
        end
    end
    
    -- Y 위치 계산 (이전 행들의 높이 합)
    -- c_height는 행(row)별 높이를 의미
    for r = 1, row - 1 do
        if layerObj._c_height[r] and layerObj._c_height[r] then
            y = y + layerObj._c_height[r]
        else
            y = y + (layerObj._height / layerObj._rows)
        end
    end
    
    -- 현재 셀의 크기
    -- r_width[col]은 col번째 열의 너비
    -- c_height[row]는 row번째 행의 높이
    local w = layerObj._r_width[col] and layerObj._r_width[col].width or (layerObj._width / layerObj._cols)
    local h = layerObj._c_height[row] and layerObj._c_height[row] or (layerObj._height / layerObj._rows)
    
    return x, y, w, h
end

-- 레이어를 canvas 요소로 변환
-- @param layerObj table - 레이어 객체
-- @param baseX number - 기본 X 좌표 (기본값: 0)
-- @param baseY number - 기본 Y 좌표 (기본값: 0)
-- @return table - canvas 요소 배열
function layer.toCanvasElements(layerObj, baseX, baseY)
    baseX = baseX or 0
    baseY = baseY or 0
    
    if not layerObj or layerObj._type ~= "layer" then
        return {}
    end
    
    local elements = {}
    local elementIndex = 1
    
    -- 배경색이 있으면 배경 요소 추가
    if layerObj._backgroundColor then
        elements[elementIndex] = {
            type = "rectangle",
            action = "fill",
            fillColor = layerObj._backgroundColor,
            frame = {
                x = baseX,
                y = baseY,
                w = layerObj._width,
                h = layerObj._height
            }
        }
        elementIndex = elementIndex + 1
    end
    
    -- 각 셀의 요소들을 순회하며 canvas 요소 생성
    for row = 1, layerObj._rows do
        for col = 1, layerObj._cols do
            local cellElement = layerObj._elements[row] and layerObj._elements[row][col]
            if cellElement then
                local x, y, w, h = layer.getCellBounds(layerObj, row, col)
                
                -- 셀 요소가 레이어인 경우 재귀적으로 처리
                if cellElement._type == "layer" then
                    local subElements = layer.toCanvasElements(cellElement, baseX + x, baseY + y)
                    for _, subElem in ipairs(subElements) do
                        elements[elementIndex] = subElem
                        elementIndex = elementIndex + 1
                    end
                elseif cellElement._type == "title" then
                    -- title 요소인 경우 _textElement를 사용
                    local titleElement = cellElement._textElement
                    if titleElement then
                        -- 요소의 frame을 셀 위치에 맞게 조정
                        if titleElement.frame then
                            titleElement.frame.x = baseX + x + (titleElement.frame.x or 0)
                            titleElement.frame.y = baseY + y + (titleElement.frame.y or 0)
                        end
                        elements[elementIndex] = titleElement
                        elementIndex = elementIndex + 1
                    end
                else
                    -- 일반 요소인 경우 (text, rectangle 등)
                    -- 요소의 frame을 셀 위치에 맞게 조정
                    if cellElement.frame then
                        cellElement.frame.x = baseX + x + (cellElement.frame.x or 0)
                        cellElement.frame.y = baseY + y + (cellElement.frame.y or 0)
                    elseif cellElement.center then
                        cellElement.center.x = baseX + x + (cellElement.center.x or 0)
                        cellElement.center.y = baseY + y + (cellElement.center.y or 0)
                    end
                    elements[elementIndex] = cellElement
                    elementIndex = elementIndex + 1
                end
            end
        end
    end
    
    return elements
end

return layer

