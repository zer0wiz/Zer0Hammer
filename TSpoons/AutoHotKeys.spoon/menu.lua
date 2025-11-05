-- AutoHotKeys 메뉴 모듈
local menu = {}

local canvas = hs.canvas
local winmod = hs.window
local dialog = hs.dialog
local eventtap = hs.eventtap
local event = eventtap.event
local screenmod = hs.screen
local json = hs.json
local fs = hs.fs

menu.menuList = {}

-- 메뉴 설정 로드
local menuConfig = nil
local function loadMenuConfig()
    if menuConfig then
        return menuConfig
    end
    
    -- Spoon 디렉토리 찾기
    local spoonPath = debug.getinfo(2, "S").source:match("@(.*/AutoHotKeys%.spoon/)")
    if not spoonPath then
        -- 대안: 상대 경로로 찾기
        spoonPath = hs.configdir .. "/TSpoons/AutoHotKeys.spoon/"
    end
    
    local configPath = spoonPath .. "assets/menu.json"
    if fs.attributes(configPath) then
        local file = io.open(configPath, "r")
        if file then
            local content = file:read("*a")
            file:close()
            menuConfig = json.decode(content)
        end
    end
    
    -- 기본값 반환 (JSON 파일이 없을 경우)
    if not menuConfig then
        menuConfig = {}
    end
    
    return menuConfig
end

-- 플레이스홀더 치환 헬퍼 함수
local function resolvePlaceholder(value, vars)
    if type(value) == "string" then
        -- {{변수명}} 패턴 치환
        local result = value:gsub("{{([^}]+)}}", function(expr)
            -- 수식 계산 (예: w - 80)
            local trimmed = expr:match("^%s*(.-)%s*$")
            -- 먼저 직접 변수 참조 확인
            if vars[trimmed] ~= nil then
                return vars[trimmed]
            end
            -- 수식이 있는 경우
            if trimmed:match("^[%w%s%-%+%*%/%(%)%.]+$") then
                -- 변수 치환
                local exprWithVars = trimmed:gsub("([%w_][%w_]*)", function(var)
                    if vars[var] ~= nil then
                        return tostring(vars[var])
                    end
                    return var
                end)
                -- 수식 평가
                local func = load("return " .. exprWithVars)
                if func then
                    local ok, result = pcall(func)
                    if ok then
                        -- 숫자는 숫자로, 문자열은 문자열로 반환
                        return result
                    end
                end
            end
            -- 치환 실패 시 빈 문자열 반환 (원래 값을 반환하면 플레이스홀더가 그대로 남음)
            return ""
        end)
        -- 전체가 숫자 문자열인 경우에만 숫자로 변환
        if type(result) == "string" and result:match("^%s*%-?%d+%.?%d*%s*$") then
            local num = tonumber(result)
            if num then
                return num
            end
        end
        return result
    elseif type(value) == "table" then
        local result = {}
        for k, v in pairs(value) do
            local newKey = resolvePlaceholder(k, vars)
            local newValue = resolvePlaceholder(v, vars)
            -- 숫자 키는 그대로 유지
            if type(k) == "number" then
                result[k] = newValue
            else
                result[newKey] = newValue
            end
        end
        return result
    end
    return value
end

-- JSON 요소를 canvas 요소로 변환
local function createCanvasElement(elementDef, vars)
    local element = {}
    
    for k, v in pairs(elementDef) do
        if k == "index" then
            -- index는 건너뛰기 (나중에 사용)
        elseif k == "template" then
            -- template은 건너뛰기
        else
            local resolved = resolvePlaceholder(v, vars)
            
            -- frame의 숫자 값이 문자열로 남아있는지 확인 및 변환
            if k == "frame" and type(resolved) == "table" then
                for fk, fv in pairs(resolved) do
                    if type(fv) == "string" then
                        local num = tonumber(fv)
                        if num then
                            resolved[fk] = num
                        end
                    end
                end
            end
            
            -- roundedRectRadii의 숫자 값 확인 및 변환
            if k == "roundedRectRadii" and type(resolved) == "table" then
                for rk, rv in pairs(resolved) do
                    if type(rv) == "string" then
                        local num = tonumber(rv)
                        if num then
                            resolved[rk] = num
                        end
                    end
                end
            end
            
            -- coordinates 배열의 숫자 값 확인 및 변환
            if k == "coordinates" and type(resolved) == "table" then
                for i, coord in ipairs(resolved) do
                    if type(coord) == "table" then
                        for ck, cv in pairs(coord) do
                            if type(cv) == "string" then
                                local num = tonumber(cv)
                                if num then
                                    coord[ck] = num
                                end
                            end
                        end
                    end
                end
            end
            
            -- 숫자 필드들 확인 및 변환
            if k == "textSize" or k == "strokeWidth" or k == "radius" then
                if type(resolved) == "string" then
                    local num = tonumber(resolved)
                    if num then
                        resolved = num
                    end
                end
            end
            
            -- center의 숫자 값 확인 및 변환
            if k == "center" and type(resolved) == "table" then
                for ck, cv in pairs(resolved) do
                    if type(cv) == "string" then
                        local num = tonumber(cv)
                        if num then
                            resolved[ck] = num
                        end
                    end
                end
            end
            
            -- fillColor의 alpha 값 확인 및 변환
            if k == "fillColor" and type(resolved) == "table" then
                for fck, fcv in pairs(resolved) do
                    if fck == "alpha" and type(fcv) == "string" then
                        local num = tonumber(fcv)
                        if num then
                            resolved[fck] = num
                        end
                    elseif type(fcv) == "string" then
                        local num = tonumber(fcv)
                        if num then
                            resolved[fck] = num
                        end
                    end
                end
            end
            
            element[k] = resolved
        end
    end
    
    -- 필수 필드 확인
    if not element.type then
        return nil -- 타입이 없으면 유효하지 않은 요소
    end
    
    return element
end

-- 메뉴 토글
function menu.toggle(obj)
    if obj.menuShowing then
        menu.hide(obj)
    else
        menu.show(obj)
    end
end

-- 앱 ID 가져오기
local function getAppId(ctx)
    if not ctx then return nil end
    if ctx.kind == "app" then
        return ctx.id
    elseif ctx.kind == "site" then
        -- 사이트는 앱 이름으로 저장
        return "app:" .. ctx.bundleId
    end
    return nil
end

-- 메뉴 표시
function menu.show(obj)
    -- 이미 메뉴가 표시되어 있으면 토글 (숨기기)
    if obj.menuShowing and obj.menuCanvas then
        menu.hide(obj)
        return
    end
    
    if obj.menuCanvas then
        obj.menuCanvas:delete()
        obj.menuCanvas = nil
    end
    
    -- 이전 eventtap 정리
    if obj.menuDragEventHandler then
        obj.menuDragEventHandler:stop()
        obj.menuDragEventHandler = nil
    end
    
    -- 이전 포커스 감지 정리
    if obj.menuFocusWatcher then
        obj.menuFocusWatcher:stop()
        obj.menuFocusWatcher = nil
    end
    
    -- 현재 컨텍스트 가져오기
    local ctx = obj.context.current()
    obj.contextObj = ctx
    
    -- 제외된 앱이면 메뉴 표시하지 않음
    local config = obj.storage.loadConfig()
    local excludedApps = config.excludedApps or {}
    for _, excludedId in ipairs(excludedApps) do
        if ctx.bundleId == excludedId then
            hs.alert.show("이 앱은 AutoHotKeys에서 제외되었습니다", 2.0)
            return
        end
    end
    
    local win = winmod.frontmostWindow()
    local menuConfig = loadMenuConfig()
    local mainMenuConfig = menuConfig.mainMenu or {}
    local w = mainMenuConfig.size and mainMenuConfig.size.w or 280
    local h = mainMenuConfig.size and mainMenuConfig.size.h or 185
    
    -- 항상 현재 마우스 위치를 왼쪽 상단 모서리로 사용
    local mousePos = hs.mouse.absolutePosition()
    local x = mousePos.x
    local y = mousePos.y
    
    -- 마우스가 있는 화면 찾기
    local mouseScreen = hs.mouse.getCurrentScreen()
    if not mouseScreen then
        mouseScreen = screenmod.primaryScreen()
    end
    local screenFrame = mouseScreen:frame()
    
    -- 화면 하단을 넘지 않도록 Y 위치 조정
    -- y + h가 화면 하단(screenFrame.y + screenFrame.h)을 넘지 않도록
    local maxY = (screenFrame.y + screenFrame.h) - h
    if y > maxY then
        y = maxY
    end
    
    -- 화면 상단을 넘지 않도록 (안전장치)
    local minY = screenFrame.y
    if y < minY then
        y = minY
    end
    
    -- 화면 우측을 넘지 않도록 X 위치도 조정
    local maxX = (screenFrame.x + screenFrame.w) - w
    if x > maxX then
        x = maxX
    end
    
    -- 화면 좌측을 넘지 않도록 (안전장치)
    local minX = screenFrame.x
    if x < minX then
        x = minX
    end
    
    local c = canvas.new({
        x = x,
        y = y,
        w = w,
        h = h
    }):show()
    
    c:level(canvas.windowLevels.popUpMenu)
    
    -- 변수 준비
    local appName = ctx.appName or "앱 없음"
    local appId = getAppId(ctx)
    local appConfig = appId and obj.storage.loadAppConfig(appId) or nil
    local enabled = appConfig and appConfig.enabled or false
    local storageConfig = obj.storage.loadConfig()
    local overlayEnabled = storageConfig.overlay and storageConfig.overlay.enabled or false
    
    -- 토글 스위치 계산 변수
    local enabledToggleWidth = 44
    local enabledToggleHeight = 24
    local enabledToggleX = w - enabledToggleWidth - 15
    local enabledToggleY = 10
    local enabledThumbRadius = 10
    local enabledTogglePadding = 2
    local enabledThumbX = enabled and (enabledToggleX + enabledToggleWidth - enabledThumbRadius - enabledTogglePadding) or (enabledToggleX + enabledThumbRadius + enabledTogglePadding)
    local enabledThumbY = enabledToggleY + enabledToggleHeight / 2
    
    local overlayToggleWidth = 44
    local overlayToggleHeight = 24
    local overlayToggleX = w - overlayToggleWidth - 20
    local overlayToggleY = 120
    local overlayThumbRadius = 10
    local overlayTogglePadding = 2
    local overlayThumbX = overlayEnabled and (overlayToggleX + overlayToggleWidth - overlayThumbRadius - overlayTogglePadding) or (overlayToggleX + overlayThumbRadius + overlayTogglePadding)
    local overlayThumbY = overlayToggleY + overlayToggleHeight / 2
    
    local vars = {
        w = w,
        h = h,
        appName = appName,
        enabledText = enabled and "ON" or "OFF",
        overlayStatus = overlayEnabled and "ON" or "OFF",
        enabledAlpha = enabled and 1.0 or 0.0,
        enabledThumbX = enabledThumbX,
        overlayAlpha = overlayEnabled and 1.0 or 0.0,
        overlayThumbX = overlayThumbX
    }
    
    -- JSON에서 요소 생성
    local elements = mainMenuConfig.elements or {}
    if not elements or next(elements) == nil then
        -- JSON 로드 실패 시 기본 canvas 요소 생성
        c[1] = {
            type = "rectangle",
            action = "fill",
            fillColor = {alpha = 0.95, white = 0.08},
            roundedRectRadii = {xRadius = 8, yRadius = 8}
        }
        c[2] = {
            type = "text",
            text = appName,
            textSize = 14,
            textColor = {white = 1},
            frame = {x = 15, y = 12, w = w - 80, h = 20},
            textAlignment = "left"
        }
    else
        -- JSON에서 요소 생성
        -- 인덱스 순서대로 정렬하여 할당 (canvas는 연속된 인덱스를 요구함)
        local sortedElements = {}
        for elementName, elementDef in pairs(elements) do
            if elementDef and elementDef.index then
                local idx = tonumber(elementDef.index)
                if idx and idx > 0 then
                    table.insert(sortedElements, {name = elementName, def = elementDef, index = idx})
                end
            end
        end
        
        -- 인덱스 순서대로 정렬
        table.sort(sortedElements, function(a, b) return a.index < b.index end)
        
        -- 순차적으로 할당
        for _, item in ipairs(sortedElements) do
            local canvasElement = createCanvasElement(item.def, vars)
            -- 유효한 요소인지 확인
            if canvasElement and canvasElement.type then
                -- fillColor alpha 처리 (enabledToggleActive, overlayToggleActive)
                if item.name == "enabledToggleActive" and canvasElement.fillColor then
                    canvasElement.fillColor.alpha = enabled and 1.0 or 0.0
                elseif item.name == "overlayToggleActive" and canvasElement.fillColor then
                    canvasElement.fillColor.alpha = overlayEnabled and 1.0 or 0.0
                end
                -- center x 처리 (enabledToggleThumb, overlayToggleThumb)
                if item.name == "enabledToggleThumb" and canvasElement.center then
                    canvasElement.center.x = enabledThumbX
                elseif item.name == "overlayToggleThumb" and canvasElement.center then
                    canvasElement.center.x = overlayThumbX
                end
                -- canvas 요소 할당 (안전하게)
                local success, err = pcall(function()
                    c[item.index] = canvasElement
                end)
                if not success then
                    hs.alert.show("Canvas 요소 생성 실패: " .. (item.name or "unknown") .. " (index: " .. item.index .. ") - " .. (tostring(err) or "알 수 없는 오류"), 2.0)
                end
            end
        end
    end
    
    -- 드래그 모드 상태
    obj.menuDragMode = false
    obj.menuDragStartCanvasX = 0
    obj.menuDragStartCanvasY = 0
    obj.menuDragStartMouseX = 0
    obj.menuDragStartMouseY = 0
    obj.menuDragEventHandler = nil
    
    -- 마우스 이벤트 활성화
    c:canvasMouseEvents(true, true, false, false)
    
    -- 마우스 콜백
    c:mouseCallback(function(canvas_obj, msg, id, x, y)
        if msg == "mouseDown" then
            local modifiers = hs.eventtap.checkKeyboardModifiers()
            if modifiers.ctrl and modifiers.cmd then
                -- 드래그 모드 시작
                obj.menuDragMode = true
                local frame = c:frame()
                
                obj.menuDragStartCanvasX = frame.x or 0
                obj.menuDragStartCanvasY = frame.y or 0
                
                local mousePos = hs.mouse.absolutePosition()
                obj.menuDragStartMouseX = mousePos.x
                obj.menuDragStartMouseY = mousePos.y
                
                c[1].strokeColor = {red = 1.0, green = 0.8, blue = 0.0, alpha = 1.0}
                c[1].strokeWidth = 2
                c[1].action = "strokeAndFill"
                
                if obj.menuDragEventHandler then
                    obj.menuDragEventHandler:start()
                end
                return
            end
        end
        
        if msg == "mouseUp" then
            if id == "btnToggle" or id == "enabledToggleTrack" then
                -- Enabled 토글
                local appId = getAppId(ctx)
                if appId then
                    obj.storage.toggleAppEnabled(appId, ctx.appName, ctx.bundleId)
                    -- 메뉴 다시 표시
                    menu.hide(obj)
                    menu.show(obj)
                end
            elseif id == "btnShortcuts" then
                -- 단축키 메뉴
                menu.hide(obj) -- 메뉴 닫기
                if obj.shortcutPreview then
                    obj.shortcutPreview.show(obj, ctx)
                else
                    hs.alert.show("단축키 미리보기 기능이 준비되지 않았습니다")
                end
            elseif id == "btnMacros" then
                -- 매크로 목록 표시
                menu.showMacroList(obj)
            elseif id == "overlayToggle" or id == "overlayToggleTrack" then
                -- 오버레이 토글
                local config = obj.storage.loadConfig()
                config.overlay = config.overlay or {}
                config.overlay.enabled = not (config.overlay.enabled or false)
                obj.storage.saveConfig(config)
                
                -- 오버레이 업데이트
                obj.overlay.update(obj)
                
                -- 메뉴 다시 표시
                menu.hide(obj)
                menu.show(obj)
            end
        end
    end)
    
    -- 드래그 추적용 eventtap
    obj.menuDragEventHandler = eventtap.new({
        event.types.leftMouseDragged,
        event.types.mouseMoved,
        event.types.leftMouseUp,
        event.types.flagsChanged
    }, function(e)
        local eventType = e:getType()
        
        if obj.menuDragMode then
            if eventType == event.types.leftMouseDragged or eventType == event.types.mouseMoved then
                local mousePos = hs.mouse.absolutePosition()
                local deltaX = mousePos.x - obj.menuDragStartMouseX
                local deltaY = mousePos.y - obj.menuDragStartMouseY
                
                c:topLeft({
                    x = obj.menuDragStartCanvasX + deltaX,
                    y = obj.menuDragStartCanvasY + deltaY
                })
                return false
            end
            
            if eventType == event.types.flagsChanged then
                local flags = e:getFlags()
                if not flags.ctrl or not flags.cmd then
                    obj.menuDragMode = false
                    c[1].strokeColor = nil
                    c[1].strokeWidth = 0
                    c[1].action = "fill"
                    
                    local frame = c:frame()
                    local config = obj.storage.loadConfig()
                    config.menu.position.x = frame.x
                    config.menu.position.y = frame.y
                    config.menu.saved = true
                    obj.storage.saveConfig(config)
                    
                    if obj.menuDragEventHandler then
                        obj.menuDragEventHandler:stop()
                    end
                end
                return false
            end
            
            if eventType == event.types.leftMouseUp then
                obj.menuDragMode = false
                c[1].strokeColor = nil
                c[1].strokeWidth = 0
                c[1].action = "fill"
                
                local frame = c:frame()
                local config = obj.storage.loadConfig()
                config.menu.position.x = frame.x
                config.menu.position.y = frame.y
                config.menu.saved = true
                obj.storage.saveConfig(config)
                
                if obj.menuDragEventHandler then
                    obj.menuDragEventHandler:stop()
                end
                return false
            end
        end
        
        return false
    end)
    
    -- 키 입력 감지하여 메뉴 닫기
    c:canvasKeyEvents(true)
    c:keyCallback(function(canvas_obj, msg, id)
        if msg == "keyDown" then
            menu.hide(obj) -- 메뉴 즉시 닫기
        end
    end)
    
    -- 포커스 손실 감지하여 메뉴 닫기
    obj.menuFocusWatcher = hs.window.filter.new()
    obj.menuFocusWatcher:subscribe(hs.window.filter.windowFocused, function(_, _, _)
        -- 다른 윈도우로 포커스 이동 시 메뉴 닫기
        -- canvas는 일반적으로 포커스를 받지 않으므로
        -- 어떤 윈도우든 포커스를 받으면 메뉴를 닫음
        hs.timer.doAfter(0.05, function()
            if obj.menuCanvas and obj.menuCanvas:isShowing() then
                local frontmost = winmod.frontmostWindow()
                if frontmost then
                    -- 메뉴가 표시되어 있지만 다른 윈도우가 포커스를 받으면 닫기
                    menu.hide(obj)
                end
            end
        end)
    end)
    
    obj.menuCanvas = c
    obj.menuShowing = true
end

-- 메뉴 숨김
function menu.hideAll()
    for _, menu in ipairs(menu.menuList) do
        menu.hide(menu)
    end
end

-- 메뉴 숨김
function menu.hide(obj)
    -- 포커스 감지 정리
    if obj.menuFocusWatcher then
        obj.menuFocusWatcher:stop()
        obj.menuFocusWatcher = nil
    end
    
    if obj.menuDragEventHandler then
        obj.menuDragEventHandler:stop()
        obj.menuDragEventHandler = nil
    end
    
    if obj.menuCanvas then
        obj.menuCanvas:delete()
        obj.menuCanvas = nil
    end
    obj.menuShowing = false
    obj.menuDragMode = false
end

-- 매크로 목록 표시
function menu.showMacroList(obj)
    menu.hide(obj)
    
    local macros = obj.storage.listMacros()
    
    local itemHeight = 40
    local headerHeight = 50
    local maxHeight = 500
    local itemCount = math.min(#macros + 1, math.floor((maxHeight - headerHeight) / itemHeight))
    local w = 400
    local h = headerHeight + (itemCount * itemHeight)
    
    -- 항상 현재 마우스 위치를 왼쪽 상단 모서리로 사용
    local mousePos = hs.mouse.absolutePosition()
    local x = mousePos.x
    local y = mousePos.y
    
    -- 마우스가 있는 화면 찾기
    local mouseScreen = hs.mouse.getCurrentScreen()
    if not mouseScreen then
        mouseScreen = screenmod.primaryScreen()
    end
    local screenFrame = mouseScreen:frame()
    
    -- 화면 하단을 넘지 않도록 Y 위치 조정
    -- y + h가 화면 하단(screenFrame.y + screenFrame.h)을 넘지 않도록
    local maxY = (screenFrame.y + screenFrame.h) - h
    if y > maxY then
        y = maxY
    end
    
    -- 화면 상단을 넘지 않도록 (안전장치)
    local minY = screenFrame.y
    if y < minY then
        y = minY
    end
    
    -- 화면 우측을 넘지 않도록 X 위치도 조정
    local maxX = (screenFrame.x + screenFrame.w) - w
    if x > maxX then
        x = maxX
    end
    
    -- 화면 좌측을 넘지 않도록 (안전장치)
    local minX = screenFrame.x
    if x < minX then
        x = minX
    end
    
    local c = canvas.new({
        x = x,
        y = y,
        w = w,
        h = h
    }):show()
    
    c:level(canvas.windowLevels.popUpMenu)
    
    -- 배경
    c[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = {alpha = 0.95, white = 0.08},
        roundedRectRadii = {xRadius = 8, yRadius = 8}
    }
    
    -- 헤더
    c[2] = {
        type = "text",
        text = "매크로 목록",
        textSize = 16,
        textColor = {white = 1},
        frame = {x = 15, y = 15, w = w - 80, h = 30},
        textAlignment = "left"
    }
    
    -- 닫기 버튼
    c[3] = {
        id = "btnClose",
        type = "rectangle",
        action = "fillStroke",
        fillColor = {alpha = 0.3, white = 0.5},
        strokeColor = {white = 1, alpha = 0.8},
        strokeWidth = 1,
        frame = {x = w - 60, y = 12, w = 45, h = 26},
        roundedRectRadii = {xRadius = 4, yRadius = 4},
        trackMouseUp = true
    }
    
    c[4] = {
        type = "text",
        text = "닫기",
        textSize = 11,
        textColor = {white = 1},
            frame = {x = w - 60, y = 12, w = 45, h = 26},
        textAlignment = "center"
    }
    
    -- 매크로 항목
    local startIdx = 1
    for i = startIdx, math.min(startIdx + itemCount - 2, #macros) do
        local macro = macros[i]
        local yPos = headerHeight + ((i - startIdx) * itemHeight)
        
        local actionCount = macro.data.actions and #macro.data.actions or 0
        local createdAt = macro.data.createdAt and os.date("%Y-%m-%d %H:%M", macro.data.createdAt) or "알 수 없음"
        
        -- 항목 배경
        c[#c + 1] = {
            id = "macro_" .. i,
            type = "rectangle",
            action = "fillStroke",
            fillColor = {alpha = 0.1, white = 0.1},
            strokeColor = {white = 1, alpha = 0.1},
            strokeWidth = 1,
            frame = {x = 15, y = yPos, w = w - 30, h = itemHeight - 5},
            roundedRectRadii = {xRadius = 4, yRadius = 4},
            trackMouseUp = true
        }
        
        -- 매크로 이름
        c[#c + 1] = {
            type = "text",
            text = macro.name,
            textSize = 13,
            textColor = {white = 1},
            frame = {x = 25, y = yPos + 5, w = w - 200, h = 18},
            textAlignment = "left"
        }
        
        -- 정보 텍스트
        c[#c + 1] = {
            type = "text",
            text = actionCount .. " 액션 | " .. createdAt,
            textSize = 10,
            textColor = {white = 0.7},
            frame = {x = 25, y = yPos + 22, w = w - 200, h = 12},
            textAlignment = "left"
        }
        
        -- 재생 버튼
        c[#c + 1] = {
            id = "play_" .. i,
            type = "rectangle",
            action = "fillStroke",
            fillColor = {alpha = 0.8, red = 0.2, green = 0.8, blue = 0.2},
            strokeColor = {white = 1, alpha = 0.8},
            strokeWidth = 1,
            frame = {x = w - 110, y = yPos + 8, w = 35, h = 24},
            roundedRectRadii = {xRadius = 4, yRadius = 4},
            trackMouseUp = true
        }
        
        c[#c + 1] = {
            type = "text",
            text = "▶",
            textSize = 12,
            textColor = {white = 1},
            frame = {x = w - 110, y = yPos + 8, w = 35, h = 24},
            textAlignment = "center"
        }
        
        -- 삭제 버튼
        c[#c + 1] = {
            id = "delete_" .. i,
            type = "rectangle",
            action = "fillStroke",
            fillColor = {alpha = 0.8, red = 0.8, green = 0.2, blue = 0.2},
            strokeColor = {white = 1, alpha = 0.8},
            strokeWidth = 1,
            frame = {x = w - 65, y = yPos + 8, w = 35, h = 24},
            roundedRectRadii = {xRadius = 4, yRadius = 4},
            trackMouseUp = true
        }
        
        c[#c + 1] = {
            type = "text",
            text = "✗",
            textSize = 12,
            textColor = {white = 1},
            frame = {x = w - 65, y = yPos + 8, w = 35, h = 24},
            textAlignment = "center"
        }
    end
    
    -- 마우스 이벤트
    c:canvasMouseEvents(true, true, false, false)
    
    c:mouseCallback(function(canvas_obj, msg, id, x, y)
        if msg == "mouseUp" then
            if id == "btnClose" then
                menu.hide(obj)
            elseif id and id:match("^play_") then
                local idx = tonumber(id:match("^play_(%d+)$"))
                if idx and macros[idx] then
                    -- 매크로 재생
                    local success, err = obj.playback.play(obj, macros[idx].name)
                    if success then
                        hs.alert.show("매크로 재생 시작: " .. macros[idx].name, 1.0)
                        menu.hide(obj)
                        obj.overlay.update(obj)
                    else
                        hs.alert.show("재생 실패: " .. (err or "알 수 없음"), 2.0)
                    end
                end
            elseif id and id:match("^delete_") then
                local idx = tonumber(id:match("^delete_(%d+)$"))
                if idx and macros[idx] then
                    -- 매크로 삭제 확인
                    local script = string.format([[
                        tell application "System Events"
                            display dialog "매크로 '%s'를 삭제하시겠습니까?" buttons {"취소", "삭제"} default button "취소" with icon caution
                            return button returned of result
                        end tell
                    ]], macros[idx].name)
                    
                    local ok, result = hs.osascript.applescript(script)
                    if ok and result == "삭제" then
                        obj.storage.deleteMacro(macros[idx].name)
                        hs.alert.show("매크로 삭제됨: " .. macros[idx].name, 1.0)
                        menu.showMacroList(obj)
                    end
                end
            end
        end
    end)
    
    obj.menuCanvas = c
    obj.menuShowing = true
end

return menu
