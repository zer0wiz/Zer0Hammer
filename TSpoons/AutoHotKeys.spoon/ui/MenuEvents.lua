-- AutoHotKeys Menu Events
local MenuEvents = {}

local eventtap = hs.eventtap
local event = eventtap.event

function MenuEvents.new(obj, canvas, callbacks)
    local self = setmetatable({}, {__index = MenuEvents})
    self.obj = obj
    self.canvas = canvas
    self.callbacks = callbacks or {}
    self.dragMode = false
    self.dragStartCanvasX = 0
    self.dragStartCanvasY = 0
    self.dragStartMouseX = 0
    self.dragStartMouseY = 0
    self.dragEventHandler = nil
    
    -- 캔버스 마우스 콜백 설정
    self.canvas:mouseCallback(function(c, msg, id, x, y)
        return self:handleCanvasEvent(c, msg, id, x, y)
    end)
    
    return self
end

function MenuEvents:handleCanvasEvent(c, msg, id, x, y)
    if msg == "mouseDown" then
        local modifiers = eventtap.checkKeyboardModifiers()
        if modifiers.ctrl and modifiers.cmd then
            self:startDrag()
            return true
        end
    elseif msg == "mouseUp" then
        if self.callbacks.onClick then
            return self.callbacks.onClick(id, x, y)
        end
    end
    return false
end

function MenuEvents:startDrag()
    self.dragMode = true
    local frame = self.canvas:frame()
    self.dragStartCanvasX = frame.x or 0
    self.dragStartCanvasY = frame.y or 0
    
    local mousePos = hs.mouse.absolutePosition()
    self.dragStartMouseX = mousePos.x
    self.dragStartMouseY = mousePos.y
    
    -- 드래그 시각적 피드백
    if self.canvas[1] then
        self.canvas[1].strokeColor = {red = 1.0, green = 0.8, blue = 0.0, alpha = 1.0}
        self.canvas[1].strokeWidth = 2
        self.canvas[1].action = "strokeAndFill"
    end
    
    -- 드래그 이벤트 핸들러 시작
    if self.dragEventHandler then self.dragEventHandler:stop() end
    
    self.dragEventHandler = eventtap.new({
        event.types.leftMouseDragged,
        event.types.mouseMoved,
        event.types.leftMouseUp,
        event.types.flagsChanged
    }, function(e)
        return self:handleDragEvent(e)
    end)
    self.dragEventHandler:start()
end

function MenuEvents:handleDragEvent(e)
    local eventType = e:getType()
    
    if self.dragMode then
        if eventType == event.types.leftMouseDragged or eventType == event.types.mouseMoved then
            local mousePos = hs.mouse.absolutePosition()
            local deltaX = mousePos.x - self.dragStartMouseX
            local deltaY = mousePos.y - self.dragStartMouseY
            
            self.canvas:topLeft({
                x = self.dragStartCanvasX + deltaX,
                y = self.dragStartCanvasY + deltaY
            })
            return false
        end
        
        if eventType == event.types.flagsChanged then
            local flags = e:getFlags()
            if not flags.ctrl or not flags.cmd then
                self:stopDrag()
                return false
            end
        end
        
        if eventType == event.types.leftMouseUp then
            self:stopDrag()
            return false
        end
    end
    return false
end

function MenuEvents:stopDrag()
    self.dragMode = false
    
    -- 시각적 피드백 제거
    if self.canvas[1] then
        self.canvas[1].strokeColor = nil
        self.canvas[1].strokeWidth = 0
        self.canvas[1].action = "fill"
    end
    
    if self.dragEventHandler then
        self.dragEventHandler:stop()
        self.dragEventHandler = nil
    end
    
    -- 위치 저장 콜백
    local frame = self.canvas:frame()
    if self.callbacks.onPositionChanged then
        self.callbacks.onPositionChanged(frame.x, frame.y)
    end
end

function MenuEvents:stop()
    if self.dragEventHandler then
        self.dragEventHandler:stop()
        self.dragEventHandler = nil
    end
end

return MenuEvents
