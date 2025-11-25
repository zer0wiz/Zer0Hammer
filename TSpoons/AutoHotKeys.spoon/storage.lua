-- AutoHotKeys 스토리지 관리 모듈 (Facade)
local storage = {}

local ConfigManager = require("data.ConfigManager")
local ContextManager = require("data.ContextManager")
local MacroRepository = require("data.MacroRepository")

-- 초기화
function storage.init()
    ConfigManager.init()
    ContextManager.init()
    MacroRepository.init()
end

-- ============================================
-- Config 관리
-- ============================================
function storage.loadConfig()
    return ConfigManager.load()
end

function storage.saveConfig(config)
    return ConfigManager.save(config)
end

function storage.getConfigValue(path)
    return ConfigManager.getValue(path)
end

-- ============================================
-- Context 관리
-- ============================================
function storage.loadContextList()
    return ContextManager.loadList()
end

function storage.saveContextList(contextList)
    return ContextManager.saveList(contextList)
end

function storage.findContext(contextId)
    return ContextManager.find(contextId)
end

function storage.addContext(contextData)
    return ContextManager.add(contextData)
end

function storage.updateContext(contextId, updates)
    return ContextManager.update(contextId, updates)
end

function storage.removeContext(contextId)
    return ContextManager.remove(contextId)
end

function storage.loadContextConfig(contextId)
    return ContextManager.loadConfig(contextId)
end

function storage.saveContextConfig(contextId, config)
    return ContextManager.saveConfig(contextId, config)
end

-- 레거시 호환성: 앱별 설정 (ContextConfig로 통합됨)
function storage.loadAppConfig(appId)
    return ContextManager.loadConfig(appId)
end

function storage.saveAppConfig(appId, config)
    return ContextManager.saveConfig(appId, config)
end

function storage.pathForContext(contextId)
    return ContextManager.pathForConfig(contextId)
end

function storage.pathForApp(appId)
    return ContextManager.pathForConfig(appId)
end

-- 컨텍스트 통합 설정 가져오기
function storage.getContextConfig(contextId)
    local ctx = ContextManager.find(contextId)
    if not ctx then return nil end

    local config = ContextManager.loadConfig(contextId)
    if not config then
        config = { context = ctx, shortcuts = {} }
        ContextManager.saveConfig(contextId, config)
    end

    local result = {}
    for k, v in pairs(ctx) do result[k] = v end
    for k, v in pairs(config) do
        if k ~= "context" or not result.context then
            result[k] = v
        end
    end
    return result
end

-- 앱의 enabled 상태 토글
function storage.toggleAppEnabled(contextId, appName, bundleId)
    local contextList = ContextManager.loadList()
    if not contextList or not contextList.contexts then return false end

    for _, ctx in ipairs(contextList.contexts) do
        if ctx.id == contextId then
            ctx.enabled = not ctx.enabled
            ctx.updatedAt = os.time()
            return ContextManager.saveList(contextList)
        end
    end
    return false
end

-- 단축키 로드 (레거시 호환)
function storage.load(contextId)
    local config = ContextManager.loadConfig(contextId)
    return config and config.shortcuts or {}
end

-- 단축키 저장 (레거시 호환)
function storage.save(context, shortcuts)
    local config = ContextManager.loadConfig(context.id) or { context = context, shortcuts = {} }
    config.shortcuts = shortcuts
    return ContextManager.saveConfig(context.id, config)
end

-- 앱 단축키 저장 (shortcut_preview에서 사용)
function storage.saveAppShortcut(contextId, contextType, keyChar, relativePos, appName, bundleId, shortcutData)
    -- 1. 컨텍스트 확인
    local ctx = ContextManager.find(contextId)

    if not ctx then
        -- 컨텍스트가 없으면 생성
        local success, result = ContextManager.add({
            id = contextId,
            type = contextType or "app",
            appName = appName,
            bundleId = bundleId,
            enabled = true
        })

        if not success then
            print("Error creating context: " .. tostring(result))
            return false
        end
        ctx = result
    end

    -- 2. Config 로드
    local config = ContextManager.loadConfig(contextId)
    if not config then
        config = { context = ctx, shortcuts = {} }
    end

    if not config.shortcuts then config.shortcuts = {} end

    -- 3. 단축키 업데이트
    config.shortcuts[keyChar] = shortcutData

    -- 4. 저장
    return ContextManager.saveConfig(contextId, config)
end

-- ============================================
-- Macro 관리
-- ============================================
function storage.saveMacro(macroName, macroData)
    return MacroRepository.save(macroName, macroData)
end

function storage.loadMacro(macroName)
    return MacroRepository.load(macroName)
end

function storage.listMacros()
    return MacroRepository.list()
end

function storage.deleteMacro(macroName)
    return MacroRepository.delete(macroName)
end

-- ============================================
-- 기타
-- ============================================
function storage.clearCache()
    -- 각 매니저의 캐시 초기화 기능이 필요하다면 추가 구현
end

return storage
