-- AutoHotKeys Menu Renderer
local MenuRenderer = {}

local canvas = hs.canvas
local UIObjects = require("modules.UIObjects")

-- 플레이스홀더 치환 헬퍼 함수
local function resolvePlaceholder(value, vars)
    if type(value) == "string" then
        -- {{변수명}} 패턴 치환
        local result = value:gsub("{{([^}]+)}}", function(expr)
            local trimmed = expr:match("^%s*(.-)%s*$")
            if vars[trimmed] ~= nil then return vars[trimmed] end
            
            if trimmed:match("^[%w%s%-%+%*%/%(%)%.]+$") then
                local exprWithVars = trimmed:gsub("([%w_][%w_]*)", function(var)
                    if vars[var] ~= nil then return tostring(vars[var]) end
                    return var
                end)
                local func = load("return " .. exprWithVars)
                if func then
                    local ok, result = pcall(func)
                    if ok then return result end
                end
            end
            return ""
        end)
        
        if type(result) == "string" and result:match("^%s*%-?%d+%.?%d*%s*$") then
            local num = tonumber(result)
            if num then return num end
        end
        return result
    elseif type(value) == "table" then
        local result = {}
        for k, v in pairs(value) do
            local newKey = resolvePlaceholder(k, vars)
            local newValue = resolvePlaceholder(v, vars)
            if type(k) == "number" then result[k] = newValue else result[newKey] = newValue end
        end
        return result
    end
    return value
end

-- JSON 요소를 canvas 요소로 변환
local function createCanvasElement(elementDef, vars)
    local element = {}
    for k, v in pairs(elementDef) do
        if k ~= "index" and k ~= "template" then
            local resolved = resolvePlaceholder(v, vars)
            
            -- 숫자 변환 로직 (frame, roundedRectRadii, coordinates, center, fillColor 등)
            if k == "frame" or k == "roundedRectRadii" or k == "center" or k == "fillColor" then
                if type(resolved) == "table" then
                    for sk, sv in pairs(resolved) do
                        if type(sv) == "string" then
                            local num = tonumber(sv)
                            if num then resolved[sk] = num end
                        end
                    end
                end
            elseif k == "coordinates" and type(resolved) == "table" then
                for i, coord in ipairs(resolved) do
                    if type(coord) == "table" then
                        for ck, cv in pairs(coord) do
                            if type(cv) == "string" then
                                local num = tonumber(cv)
                                if num then coord[ck] = num end
                            end
                        end
                    end
                end
            elseif (k == "textSize" or k == "strokeWidth" or k == "radius") and type(resolved) == "string" then
                local num = tonumber(resolved)
                if num then resolved = num end
            end
            
            element[k] = resolved
        end
    end
    
    if not element.type then return nil end
    return element
end

function MenuRenderer.render(c, menuConfig, vars)
    local elements = menuConfig.elements or {}
    if not elements or next(elements) == nil then
        -- 기본 렌더링 (Fallback)
        c[1] = {
            type = "rectangle",
            action = "fill",
            fillColor = {alpha = 0.95, white = 0.08},
            roundedRectRadii = {xRadius = 8, yRadius = 8}
        }
        c[2] = {
            type = "text",
            text = vars.appName or "Unknown",
            textSize = 14,
            textColor = {white = 1},
            frame = {x = 15, y = 12, w = vars.w - 80, h = 20},
            textAlignment = "left"
        }
        return
    end
    
    -- JSON 기반 렌더링
    local sortedElements = {}
    for elementName, elementDef in pairs(elements) do
        if elementDef and elementDef.index then
            local idx = tonumber(elementDef.index)
            if idx and idx > 0 then
                table.insert(sortedElements, {name = elementName, def = elementDef, index = idx})
            end
        end
    end
    table.sort(sortedElements, function(a, b) return a.index < b.index end)
    
    for _, item in ipairs(sortedElements) do
        local canvasElement = createCanvasElement(item.def, vars)
        if canvasElement and canvasElement.type then
            -- 동적 속성 적용
            if item.name == "enabledToggleActive" and canvasElement.fillColor then
                canvasElement.fillColor.alpha = vars.enabledAlpha
            elseif item.name == "overlayToggleActive" and canvasElement.fillColor then
                canvasElement.fillColor.alpha = vars.overlayAlpha
            end
            if item.name == "enabledToggleThumb" and canvasElement.center then
                canvasElement.center.x = vars.enabledThumbX
            elseif item.name == "overlayToggleThumb" and canvasElement.center then
                canvasElement.center.x = vars.overlayThumbX
            end
            
            pcall(function() c[item.index] = canvasElement end)
        end
    end
end

return MenuRenderer
