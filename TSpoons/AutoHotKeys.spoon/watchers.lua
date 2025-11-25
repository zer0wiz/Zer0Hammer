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

-- 토글된 컨텍스트인지 확인
local function isActiveContext(ctx, obj)
    if not ctx or not ctx.id then return false end
    return obj.activeContexts[ctx.id] ~= nil
end

-- 새 컨텍스트 자동 감지 및 추가
local function ensureContextExists(ctx, obj)
    if not ctx or not ctx.id then return false end
    
    -- context-list.json에서 확인
    local existingContext = obj.storage.findContext(ctx.id)
    if existingContext then
        return true
    end
    
    -- 새 컨텍스트 추가
    local contextData = {
        id = ctx.id,
        type = ctx.type,
        name = ctx.name or ctx.appName or ctx.id,  -- ctx.name 우선 사용
        bundleId = ctx.bundleId,
        enabled = false  -- 기본값은 비활성화
    }
    
    local success, result = obj.storage.addContext(contextData)
    if success then
        obj.logger.i("새 컨텍스트 자동 추가: " .. ctx.id)
        return true
    else
        obj.logger.w("컨텍스트 추가 실패: " .. ctx.id .. " - " .. (result or "알 수 없는 오류"))
        return false
    end
end

-- 컨텍스트 활성화 처리
local function handleContextActivation(obj)
    -- 컨텍스트가 context-list.json에 존재하는지 확인하고 없으면 추가
    ensureContextExists(obj.contextObj, obj)
    
    -- enabled 상태 확인
    local ctx = obj.storage.findContext(obj.contextObj.id)
    local isEnabled = ctx and ctx.enabled or false
    
    -- enabled가 true이면 자동으로 activeContexts에 추가
    if isEnabled and not isActiveContext(obj.contextObj, obj) then
        obj.activeContexts[obj.contextObj.id] = {
            context = obj.contextObj,
            timestamp = os.time()
        }
    end
    
    -- enabled가 false이거나 토글되지 않은 컨텍스트면 처리하지 않음
    if not isEnabled and not isActiveContext(obj.contextObj, obj) then
        obj.execution.disableShortcuts(obj)
        obj.overlay.update(obj)
        return false
    end
    
    obj.shortcuts = obj.shortcuts or {}
    obj.shortcuts[obj.contextObj.id] = obj.shortcuts[obj.contextObj.id] or obj.storage.load(obj.contextObj.id)
    obj.overlay.update(obj)
    
    -- 앱별 enabled 상태 확인
    watchers.updateAppShortcuts(obj)
    return true
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
            -- 메뉴가 표시되어 있으면 포커스 변경 무시
            if obj.menuShowing then
                return
            end
            
            -- obj.context는 모듈, obj.contextObj는 현재 컨텍스트 데이터
            obj.contextObj = obj.context.current()
            
            print(string.format("[AutoHotKeys] 윈도우 포커스: %s (%s)", obj.contextObj.appName or "Unknown", obj.contextObj.bundleId or "unknown"))
            
            -- Hammerspoon이면 처리하지 않음 (팝업 메뉴 등)
            if obj.contextObj.bundleId == "org.hammerspoon.Hammerspoon" or obj.contextObj.bundleId == "com.hammerspoon.Hammerspoon" then
                return
            end
            
            -- 제외된 앱이면 처리하지 않음
            if isExcludedApp(obj.contextObj.bundleId, obj) then
                obj.execution.disableShortcuts(obj)
                return
            end
            
            -- 컨텍스트 활성화 처리
            handleContextActivation(obj)
        end
    )
    
    -- Application Watcher
    obj.appWatcher = appmod.watcher.new(function(_, event)
        if event == appmod.watcher.activated then
            -- 메뉴가 표시되어 있으면 활성화 이벤트 무시
            if obj.menuShowing then
                return
            end
            
            obj.contextObj = obj.context.current()
            
            print(string.format("[AutoHotKeys] 앱 활성화: %s (%s)", obj.contextObj.appName or "Unknown", obj.contextObj.bundleId or "unknown"))
            
            -- Hammerspoon이면 처리하지 않음 (팝업 메뉴 등)
            if obj.contextObj.bundleId == "org.hammerspoon.Hammerspoon" or obj.contextObj.bundleId == "com.hammerspoon.Hammerspoon" then
                return
            end
            
            -- 제외된 앱이면 처리하지 않음
            if isExcludedApp(obj.contextObj.bundleId, obj) then
                obj.execution.disableShortcuts(obj)
                return
            end
            
            -- 컨텍스트 활성화 처리
            handleContextActivation(obj)
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
    
    -- 토글된 컨텍스트가 아니면 비활성화
    if not isActiveContext(ctx, obj) then
        obj.execution.disableShortcuts(obj)
        return
    end
    
    -- 앱 ID 가져오기 및 설정 파일 경로 출력
    local configPath = obj.storage.pathForContext(ctx.id)
    print(string.format("[AutoHotKeys] 설정 파일: %s", configPath))
    
    local contextConfig = obj.storage.loadAppConfig(ctx.id)
    
    if contextConfig and contextConfig.shortcuts then
        -- 단축키가 있으면 활성화
        print(string.format("[AutoHotKeys] 활성화된 단축키 목록 (%s):", ctx.id))
        local shortcutCount = 0
        for key, shortcut in pairs(contextConfig.shortcuts) do
            shortcutCount = shortcutCount + 1
            local desc = shortcut.description or "설명 없음"
            local actionType = shortcut.type or "unknown"
            local actionInfo = ""
            
            if actionType == "text" then
                actionInfo = string.format("텍스트: %s", shortcut.text or "")
            elseif actionType == "keypress" then
                actionInfo = string.format("키 입력: %s", shortcut.keys or "")
            elseif actionType == "macro" then
                actionInfo = string.format("매크로: %s", shortcut.macro or "")
            elseif actionType == "command" then
                actionInfo = string.format("명령: %s", shortcut.command or "")
            end
            
            print(string.format("  [%d] %s → %s (%s)", shortcutCount, key, actionInfo, desc))
        end
        print(string.format("[AutoHotKeys] 총 %d개의 단축키 활성화됨", shortcutCount))
        obj.execution.enableShortcuts(obj, ctx.id, contextConfig.shortcuts)
    else
        -- 비활성화
        print(string.format("[AutoHotKeys] 활성화된 단축키 없음"))
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
