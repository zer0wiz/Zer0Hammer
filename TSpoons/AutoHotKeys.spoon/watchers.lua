-- AutoHotKeys Watchers 모듈
local watchers = {}

local appmod = hs.application

-- Watchers 시작
function watchers.start(obj)
    -- Window Filter
    if obj.winFilter then
        obj.winFilter:unsubscribeAll()
    end
    
    obj.winFilter = hs.window.filter.new():subscribe(
        hs.window.filter.windowFocused,
        function()
            -- obj.context는 모듈, obj.contextObj는 현재 컨텍스트 데이터
            obj.contextObj = obj.context.current()
            obj.shortcuts = obj.shortcuts or {}
            obj.shortcuts[obj.contextObj.id] = obj.shortcuts[obj.contextObj.id] or obj.storage.load(obj.contextObj.id)
            obj.overlay.update(obj)
        end
    )
    
    -- Application Watcher
    obj.appWatcher = appmod.watcher.new(function(_, event)
        if event == appmod.watcher.activated then
            obj.contextObj = obj.context.current()
            obj.shortcuts = obj.shortcuts or {}
            obj.shortcuts[obj.contextObj.id] = obj.shortcuts[obj.contextObj.id] or obj.storage.load(obj.contextObj.id)
            obj.overlay.update(obj)
        end
    end)
    
    obj.appWatcher:start()
    
    -- Key Tap 시작
    obj.execution.registerKeyTap(obj)
end

-- Watchers 정지
function watchers.stop(obj)
    if obj.keyTap then
        obj.keyTap:stop()
        obj.keyTap = nil
    end
    
    if obj.appWatcher then
        obj.appWatcher:stop()
        obj.appWatcher = nil
    end
    
    if obj.winFilter then
        obj.winFilter:unsubscribeAll()
        obj.winFilter = nil
    end
end

return watchers
