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
    
    local win = winmod.frontmostWindow()
    local base = win and win:frame() or hs.geometry({x = 200, y = 200, w = 400, h = 300})
    local w, h = 260, 180
    
    -- 저장된 위치가 있으면 사용, 없으면 기본 위치
    local x = obj.menuX or (base.x + base.w/2 - w/2)
    local y = obj.menuY or (base.y + 80)
    
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
    
    -- 제목
    c[2] = {
        type = "text",
        text = "AutoHotKeys",
        textSize = 14,
        textColor = {white = 1},
        frame = {x = 0, y = 8, w = w, h = 20},
        textAlignment = "center"
    }
    
    -- 단축키 보기 버튼
    c[3] = {
        id = "btnList",
        type = "text",
        text = "단축키 보기/삭제",
        textSize = 13,
        textColor = {white = 1},
        frame = {x = 20, y = 48, w = w-40, h = 24},
        trackMouseUp = true
    }
    
    -- 닫기 버튼
    c[4] = {
        id = "btnClose",
        type = "text",
        text = "닫기",
        textSize = 12,
        textColor = {alpha = 0.8, white = 1},
        frame = {x = 20, y = 120, w = w-40, h = 20},
        trackMouseUp = true
    }
    
    -- 드래그 모드 상태
    obj.menuDragMode = false
    obj.menuDragStartCanvasX = 0
    obj.menuDragStartCanvasY = 0
    obj.menuDragStartMouseX = 0
    obj.menuDragStartMouseY = 0
    obj.menuDragEventHandler = nil
    
    -- 마우스 이벤트 활성화 (버튼 클릭용)
    c:canvasMouseEvents(true, true, false, false)
    
    -- 마우스 콜백 (버튼 클릭 및 드래그 시작 감지)
    c:mouseCallback(function(canvas_obj, msg, id, x, y)
        -- Ctrl+Cmd+Click 감지 (드래그 모드 시작)
        if msg == "mouseDown" then
            local modifiers = hs.eventtap.checkKeyboardModifiers()
            if modifiers.ctrl and modifiers.cmd then
                -- 드래그 모드 시작
                obj.menuDragMode = true
                local frame = c:frame()
                
                -- 캔버스 위치 저장
                obj.menuDragStartCanvasX = frame.x or 0
                obj.menuDragStartCanvasY = frame.y or 0
                
                -- 마우스 절대 위치 저장
                local mousePos = hs.mouse.absolutePosition()
                obj.menuDragStartMouseX = mousePos.x
                obj.menuDragStartMouseY = mousePos.y
                
                -- 테두리 색상 변경 (노란색)
                c[1].strokeColor = {red = 1.0, green = 0.8, blue = 0.0, alpha = 1.0}
                c[1].strokeWidth = 2
                c[1].action = "strokeAndFill"
                
                -- 드래그 추적용 eventtap 시작
                if obj.menuDragEventHandler then
                    obj.menuDragEventHandler:start()
                    print("Drag mode started, eventtap monitoring started")
                end
                return
            end
        end
        
        -- 버튼 클릭 처리
        if msg == "mouseUp" then
            if id == "btnList" then
                menu.showShortcutList(obj)
            elseif id == "btnClose" then
                menu.hide(obj)
            end
        end
    end)
    
    -- 드래그 추적용 eventtap 생성 (초기에는 시작하지 않음)
    obj.menuDragEventHandler = eventtap.new({
        event.types.leftMouseDragged,  -- 마우스 버튼이 눌린 상태에서의 이동
        event.types.mouseMoved,
        event.types.leftMouseUp,
        event.types.flagsChanged
    }, function(e)
        local eventType = e:getType()
        
        -- 마우스 이동 추적 (드래그 모드일 때만)
        if obj.menuDragMode then
            if eventType == event.types.leftMouseDragged or eventType == event.types.mouseMoved then
                local mousePos = hs.mouse.absolutePosition()
                local deltaX = mousePos.x - obj.menuDragStartMouseX
                local deltaY = mousePos.y - obj.menuDragStartMouseY
                
                -- 캔버스 위치 업데이트
                c:topLeft({
                    x = obj.menuDragStartCanvasX + deltaX,
                    y = obj.menuDragStartCanvasY + deltaY
                })
                
                print("Dragging:", deltaX, deltaY)
                return false
            end
            
            -- Ctrl/Cmd 키가 떼어졌을 때
            if eventType == event.types.flagsChanged then
                local flags = e:getFlags()
                -- Ctrl이나 Cmd가 모두 떼어졌으면 드래그 모드 종료
                if not flags.ctrl or not flags.cmd then
                    -- 드래그 모드 종료
                    obj.menuDragMode = false
                    
                    -- 테두리 색상 복원
                    c[1].strokeColor = nil
                    c[1].strokeWidth = 0
                    c[1].action = "fill"
                    
                    -- 위치 저장
                    local frame = c:frame()
                    obj.menuX = frame.x or 0
                    obj.menuY = frame.y or 0
                    
                    -- eventtap 중지
                    obj.menuDragEventHandler:stop()
                    
                    print("Drag mode ended by key release, saved position:", obj.menuX, obj.menuY)
                end
                return false
            end
            
            -- 마우스 버튼이 떼어졌을 때
            if eventType == event.types.leftMouseUp then
                -- 드래그 모드 종료
                obj.menuDragMode = false
                
                -- 테두리 색상 복원
                c[1].strokeColor = nil
                c[1].strokeWidth = 0
                c[1].action = "fill"
                
                -- 위치 저장
                local frame = c:frame()
                obj.menuX = frame.x or 0
                obj.menuY = frame.y or 0
                
                -- eventtap 중지
                obj.menuDragEventHandler:stop()
                
                print("Drag mode ended by mouse up, saved position:", obj.menuX, obj.menuY)
                
                return false
            end
        end
        
        return false
    end)
    
    -- 초기에는 eventtap을 시작하지 않음 (Ctrl+Cmd+Click 감지 후에만 시작)
    
    obj.menuCanvas = c
    obj.menuShowing = true
end

-- 메뉴 숨김
function menu.hide(obj)
    -- eventtap 정리
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

-- 단축키 목록 표시
function menu.showShortcutList(obj)
    local ctx = obj.contextObj
    if not ctx then return end
    
    local items = obj.shortcuts[ctx.id] or {}
    local keys = {}
    for k, _ in pairs(items) do
        table.insert(keys, k)
    end
    table.sort(keys)
    
    if #keys == 0 then
        hs.alert.show("저장된 단축키가 없습니다.")
        return
    end
    
    local choices = {}
    for _, k in ipairs(keys) do
        local it = items[k]
        local label = string.format("%s → %s (%s,%s)",
            k,
            it.type or "click",
            it.position and it.position.dx or "-",
            it.position and it.position.dy or "-"
        )
        table.insert(choices, label)
    end
    
    local btn, text = dialog.chooseFromList("단축키 선택 후 삭제를 누르세요", choices, "삭제", "취소")
    
    if btn == "삭제" and text and #text > 0 then
        local label = text[1]
        local key = label:match("^(.-) %S+ ") or label
        items[key] = nil
        obj.shortcuts[ctx.id] = items
        obj.storage.save(ctx, items)
        hs.alert.show("삭제되었습니다")
    end
end

return menu

