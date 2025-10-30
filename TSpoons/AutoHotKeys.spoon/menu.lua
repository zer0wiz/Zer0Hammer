-- AutoHotKeys 메뉴 모듈
local menu = {}

local canvas = hs.canvas
local winmod = hs.window
local dialog = hs.dialog
local eventtap = hs.eventtap
local event = eventtap.event

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
    if obj.menuCanvas then
        obj.menuCanvas:delete()
        obj.menuCanvas = nil
    end
    
    -- 이전 eventtap 정리
    if obj.menuDragEventHandler then
        obj.menuDragEventHandler:stop()
        obj.menuDragEventHandler = nil
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
    local base = win and win:frame() or hs.geometry({x = 200, y = 200, w = 400, h = 300})
    local w, h = 280, 185
    
    -- 저장된 위치가 있으면 사용, 없으면 기본 위치
    local config = obj.storage.loadConfig()
    local x, y
    if config.menu.position.x and config.menu.position.y then
        x = config.menu.position.x
        y = config.menu.position.y
    else
        x = base.x + base.w/2 - w/2
        y = base.y + 80
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
    
    -- 앱 이름 (좌측 상단)
    local appName = ctx.appName or "앱 없음"
    c[2] = {
        type = "text",
        text = appName,
        textSize = 14,
        textColor = {white = 1},
        frame = {x = 15, y = 12, w = w - 80, h = 20},
        textAlignment = "left"
    }
    
    -- Enabled 토글 버튼 (우측 상단)
    local appId = getAppId(ctx)
    local appConfig = appId and obj.storage.loadAppConfig(appId) or nil
    local enabled = appConfig and appConfig.enabled or false
    
    c[3] = {
        id = "btnToggle",
        type = "rectangle",
        action = "fillStroke",
        fillColor = enabled and {alpha = 0.8, red = 0.2, green = 0.8, blue = 0.2} or {alpha = 0.3, white = 0.5},
        strokeColor = {white = 1, alpha = 0.8},
        strokeWidth = 1,
        frame = {x = w - 60, y = 10, w = 45, h = 24},
        roundedRectRadii = {xRadius = 4, yRadius = 4},
        trackMouseUp = true
    }
    
    -- Enabled 텍스트
    c[4] = {
        type = "text",
        text = enabled and "ON" or "OFF",
        textSize = 11,
        textColor = {white = 1},
        frame = {x = w - 60, y = 10, w = 45, h = 24},
        textAlignment = "center"
    }
    
    -- 메뉴 항목: 단축키
    c[5] = {
        id = "btnShortcuts",
        type = "text",
        text = "단축키",
        textSize = 13,
        textColor = {white = 1},
        frame = {x = 20, y = 50, w = w - 40, h = 32},
        trackMouseUp = true
    }
    
    -- 메뉴 항목: 매크로
    c[6] = {
        id = "btnMacros",
        type = "text",
        text = "매크로",
        textSize = 13,
        textColor = {white = 1},
        frame = {x = 20, y = 85, w = w - 40, h = 32},
        trackMouseUp = true
    }
    
    -- 메뉴 항목: 오버레이 표시 토글
    local config = obj.storage.loadConfig()
    local overlayEnabled = config.overlay and config.overlay.enabled or false
    
    c[7] = {
        id = "btnOverlay",
        type = "text",
        text = "오버레이: " .. (overlayEnabled and "ON" or "OFF"),
        textSize = 13,
        textColor = overlayEnabled and {red = 0.2, green = 0.8, blue = 0.2} or {white = 0.7},
        frame = {x = 20, y = 120, w = w - 40, h = 32},
        trackMouseUp = true
    }
    
    -- 구분선
    c[8] = {
        type = "segments",
        action = "stroke",
        strokeColor = {white = 1, alpha = 0.2},
        strokeWidth = 1,
        coordinates = {
            {x = 15, y = 48},
            {x = w - 15, y = 48}
        }
    }
    
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
            if id == "btnToggle" then
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
                if obj.shortcutPreview then
                    obj.shortcutPreview.show(obj, ctx)
                else
                    hs.alert.show("단축키 미리보기 기능이 준비되지 않았습니다")
                end
            elseif id == "btnMacros" then
                -- 매크로 목록 표시
                menu.showMacroList(obj)
            elseif id == "btnOverlay" then
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
    
    obj.menuCanvas = c
    obj.menuShowing = true
end

-- 메뉴 숨김
function menu.hide(obj)
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
    local win = winmod.frontmostWindow()
    local base = win and win:frame() or hs.geometry({x = 200, y = 200, w = 500, h = 400})
    
    local itemHeight = 40
    local headerHeight = 50
    local maxHeight = 500
    local itemCount = math.min(#macros + 1, math.floor((maxHeight - headerHeight) / itemHeight))
    local w = 400
    local h = headerHeight + (itemCount * itemHeight)
    
    local config = obj.storage.loadConfig()
    local x, y
    if config.menu.position.x and config.menu.position.y then
        x = config.menu.position.x
        y = config.menu.position.y
    else
        x = base.x + base.w/2 - w/2
        y = base.y + 80
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
