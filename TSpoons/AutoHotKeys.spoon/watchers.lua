-- AutoHotKeys Watchers 모듈
local watchers = {}

local appmod = hs.application

-- 제외된 앱인지 확인
local function isExcludedApp(bundleId, obj)
    if not bundleId then return false end
    
    local config = obj.storage.loadConfig()
    local excludedApps = config.excludedApps or {}
    
    for _, excludedId in ipairs(excludedApps) do
        if bundleId == excludedId then
            return true
        end
    end
    
    return false
end

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
            
            -- 제외된 앱이면 처리하지 않음
            if isExcludedApp(obj.contextObj.bundleId, obj) then
                obj.execution.disableShortcuts(obj)
                return
            end
            
            obj.shortcuts = obj.shortcuts or {}
            obj.shortcuts[obj.contextObj.id] = obj.shortcuts[obj.contextObj.id] or obj.storage.load(obj.contextObj.id)
            obj.overlay.update(obj)
            
            -- 앱별 enabled 상태 확인
            watchers.updateAppShortcuts(obj)
        end
    )
    
    -- Application Watcher
    obj.appWatcher = appmod.watcher.new(function(_, event)
        if event == appmod.watcher.activated then
            obj.contextObj = obj.context.current()
            
            -- 제외된 앱이면 처리하지 않음
            if isExcludedApp(obj.contextObj.bundleId, obj) then
                obj.execution.disableShortcuts(obj)
                return
            end
            
            obj.shortcuts = obj.shortcuts or {}
            obj.shortcuts[obj.contextObj.id] = obj.shortcuts[obj.contextObj.id] or obj.storage.load(obj.contextObj.id)
            obj.overlay.update(obj)
            
            -- 앱별 enabled 상태 확인
            watchers.updateAppShortcuts(obj)
        end
    end)
    
    obj.appWatcher:start()
    
    -- Key Tap 시작
    obj.execution.registerKeyTap(obj)
end

-- 앱별 단축키 활성화/비활성화 업데이트
function watchers.updateAppShortcuts(obj)
    local ctx = obj.contextObj
    if not ctx then
        obj.execution.disableShortcuts(obj)
        return
    end
    
    -- 제외된 앱이면 비활성화
    if isExcludedApp(ctx.bundleId, obj) then
        obj.execution.disableShortcuts(obj)
        return
    end
    
    -- 앱 ID 가져오기
    local appId = "app:" .. ctx.bundleId
    local appConfig = obj.storage.loadAppConfig(appId)
    
    if appConfig and appConfig.enabled and appConfig.shortcuts then
        -- enabled이고 단축키가 있으면 활성화
        obj.execution.enableShortcuts(obj, appId, appConfig.shortcuts)
    else
        -- 비활성화
        obj.execution.disableShortcuts(obj)
    end
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
