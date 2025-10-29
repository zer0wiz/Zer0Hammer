-- AutoHotKeys 캡처 모듈
local capture = {}

local eventtap = hs.eventtap
local winmod = hs.window
local dialog = hs.dialog

-- Mouse Tap 등록
function capture.register(obj)
    if obj.mouseTap then return end
    
    obj.mouseTap = eventtap.new({eventtap.event.types.leftMouseDown}, function(e)
        -- Ctrl 키 확인
        if not e:getFlags().ctrl then
            return false
        end
        
        local pt = e:location()
        local win = winmod.frontmostWindow()
        if not win then return false end
        
        local f = win:frame()
        
        -- 위치 저장 확인
        local answer = dialog.blockAlert(
            "현재 위치 저장?",
            string.format("x=%d, y=%d", pt.x, pt.y),
            "Yes",
            "No",
            "informational"
        )
        
        if answer ~= "Yes" then
            return false
        end
        
        -- 단축키 입력
        local _, key = dialog.textPrompt(
            "단축키 입력",
            "한 글자 키를 입력하세요",
            "",
            "OK",
            "Cancel"
        )
        
        if not key or key == "" then
            return true
        end
        
        key = key:sub(1, 1)
        
        -- 컨텍스트 가져오기 (obj.context는 모듈, obj.contextObj는 현재 컨텍스트)
        local ctx = obj.context.current()
        
        -- 상대 좌표 계산
        local dx = pt.x - f.x
        local dy = pt.y - f.y
        
        -- 단축키 저장
        obj.shortcuts = obj.shortcuts or {}
        obj.shortcuts[ctx.id] = obj.shortcuts[ctx.id] or {}
        obj.shortcuts[ctx.id][key] = {
            type = "click",
            event_type = "ctrl_click",
            position = {dx = dx, dy = dy},
            windowRelative = true
        }
        
        -- Storage 저장 (obj.storage 모듈 사용)
        obj.storage.save(ctx, obj.shortcuts[ctx.id])
        
        -- Overlay 업데이트 (obj.overlay 모듈 사용)
        obj.overlay.update(obj)
        
        -- 즉시 실행 (obj.execution 모듈 사용)
        obj.execution.perform(obj, ctx, key)
        
        return true
    end)
    
    obj.mouseTap:start()
end

-- Mouse Tap 정지
function capture.stop(obj)
    if obj.mouseTap then
        obj.mouseTap:stop()
        obj.mouseTap = nil
    end
end

return capture
