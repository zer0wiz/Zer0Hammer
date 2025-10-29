-- AutoHotKeys 오버레이 모듈
local overlay = {}

local canvas = hs.canvas
local winmod = hs.window

-- 오버레이 생성
function overlay.init(obj)
    if obj.overlay then return end
    
    obj.overlay = canvas.new({x = 0, y = 0, w = 28, h = 20}):show()
    obj.overlay:behavior(canvas.windowBehaviors.canJoinAllSpaces)
    obj.overlay:level(canvas.windowLevels.popUpMenu)
    
    -- 배경
    obj.overlay[1] = {
        type = "roundedRectangle",
        action = "fill",
        fillColor = {alpha = 0.85, red = 0, green = 0, blue = 0},
        roundedRectRadii = {xRadius = 5, yRadius = 5}
    }
    
    -- 텍스트
    obj.overlay[2] = {
        type = "text",
        text = "AK",
        textSize = 11,
        textColor = {white = 1},
        textAlignment = "center"
    }
    
    -- 마우스 클릭 이벤트
    obj.overlay:mouseCallback(function(_, msg)
        if msg == "mouseUp" then
            obj:toggleMenu()
        end
    end)
    
    obj.overlayVisible = false
    obj.overlay:hide()
end

-- 오버레이 업데이트
function overlay.update(obj)
    overlay.init(obj)
    
    local ctx = obj.contextObj
    local hasShortcuts = ctx and obj.shortcuts[ctx.id] and next(obj.shortcuts[ctx.id]) ~= nil
    
    -- 단축키가 없는 경우 숨김
    if not (ctx and (ctx.kind == "app" or ctx.kind == "site") and hasShortcuts) then
        if obj.overlayVisible then
            obj.overlay:hide()
            obj.overlayVisible = false
        end
        return
    end
    
    local win = winmod.frontmostWindow()
    if not win then
        if obj.overlayVisible then
            obj.overlay:hide()
            obj.overlayVisible = false
        end
        return
    end
    
    local f = win:frame()
    local x = f.x + f.w - 34
    local y = f.y + 6
    obj.overlay:topLeft({x = x, y = y})
    
    if not obj.overlayVisible then
        obj.overlay:show()
        obj.overlayVisible = true
    end
end

-- 오버레이 정지
function overlay.stop(obj)
    if obj.overlay then
        obj.overlay:delete()
        obj.overlay = nil
    end
    obj.overlayVisible = false
end

return overlay

