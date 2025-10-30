-- AutoHotKeys 스토리지 관리 모듈
local storage = {}

local json = hs.json
local fs = hs.fs

-- 저장소 디렉터리
local STORAGE_DIR = hs.configdir .. "/autohotkeys"
local CONFIG_FILE = STORAGE_DIR .. "/config.json"
local MACROS_DIR = STORAGE_DIR .. "/_macros"

-- 파일명 안전 처리
local function sanitizeFilename(s)
    return (s:gsub("[^%w%._-]", "_"))
end

-- 저장소 디렉터리 생성
function storage.init()
    if not fs.attributes(STORAGE_DIR, "mode") then
        fs.mkdir(STORAGE_DIR)
    end
    if not fs.attributes(MACROS_DIR, "mode") then
        fs.mkdir(MACROS_DIR)
    end
end

-- 기본 config 설정
local defaultConfig = {
    shortcutPreview = {
        circle = {
            radius = 20,
            strokeWidth = 2,
            strokeColor = "#FF5733",
            fillColor = "#FF5733",
            fillAlpha = 0.7
        },
        text = {
            size = 14,
            color = "#FFFFFF",
            font = "Arial Bold"
        },
        overlay = {
            color = "#000000",
            alpha = 0.3
        }
    },
    menu = {
        position = {
            x = nil,
            y = nil
        },
        saved = false
    },
    overlay = {
        enabled = false  -- 오버레이 기본값: 숨김
    },
    excludedApps = {
        "com.hammerspoon.Hammerspoon"  -- Hammerspoon 자체는 제외
    }
}

-- 컨텍스트별 저장 경로
function storage.pathForContext(contextId)
    storage.init()
    return string.format("%s/%s.json", STORAGE_DIR, sanitizeFilename(contextId))
end

-- 단축키 로드
function storage.load(contextId)
    local path = storage.pathForContext(contextId)
    if not fs.attributes(path) then return {} end
    
    local fh = io.open(path, "r")
    if not fh then return {} end
    
    local content = fh:read("*a")
    fh:close()
    
    local ok, data = pcall(function() return json.decode(content) end)
    if ok and type(data) == "table" and type(data.shortcuts) == "table" then
        return data.shortcuts
    end
    return {}
end

-- 단축키 저장
function storage.save(context, shortcuts)
    local path = storage.pathForContext(context.id)
    local payload = {
        context = context,
        shortcuts = shortcuts or {}
    }
    
    local fh = io.open(path, "w")
    if not fh then return false end
    
    fh:write(json.encode(payload, true))
    fh:close()
    return true
end

-- Config 파일 관리
function storage.loadConfig()
    storage.init()
    
    if not fs.attributes(CONFIG_FILE) then
        storage.saveConfig(defaultConfig)
        return defaultConfig
    end
    
    local fh = io.open(CONFIG_FILE, "r")
    if not fh then return defaultConfig end
    
    local content = fh:read("*a")
    fh:close()
    
    local ok, data = pcall(function() return json.decode(content) end)
    if ok and type(data) == "table" then
        -- 기본값과 병합
        local merged = {}
        for k, v in pairs(defaultConfig) do
            merged[k] = data[k] or v
        end
        return merged
    end
    
    return defaultConfig
end

function storage.saveConfig(config)
    storage.init()
    
    local fh = io.open(CONFIG_FILE, "w")
    if not fh then return false end
    
    fh:write(json.encode(config, true))
    fh:close()
    return true
end

function storage.getConfigValue(path)
    local config = storage.loadConfig()
    local parts = {}
    for part in string.gmatch(path, "([^.]+)") do
        table.insert(parts, part)
    end
    
    local value = config
    for _, part in ipairs(parts) do
        if type(value) == "table" then
            value = value[part]
        else
            return nil
        end
    end
    
    return value
end

-- 앱별 설정 파일 경로
function storage.pathForApp(appId)
    storage.init()
    return string.format("%s/%s.json", STORAGE_DIR, sanitizeFilename(appId))
end

-- 앱별 설정 로드 (enabled, shortcuts 포함)
function storage.loadAppConfig(appId)
    local path = storage.pathForApp(appId)
    
    if not fs.attributes(path) then
        return nil
    end
    
    local fh = io.open(path, "r")
    if not fh then return nil end
    
    local content = fh:read("*a")
    fh:close()
    
    local ok, data = pcall(function() return json.decode(content) end)
    if ok and type(data) == "table" then
        return data
    end
    
    return nil
end

-- 앱별 설정 저장
function storage.saveAppConfig(appId, config)
    local path = storage.pathForApp(appId)
    
    local fh = io.open(path, "w")
    if not fh then return false end
    
    fh:write(json.encode(config, true))
    fh:close()
    return true
end

-- 앱별 단축키 저장
function storage.saveAppShortcut(appId, key, position, appName, bundleId)
    local config = storage.loadAppConfig(appId) or {
        enabled = true,
        appName = appName or "",
        bundleId = bundleId or appId,
        shortcuts = {}
    }
    
    config.shortcuts = config.shortcuts or {}
    config.shortcuts[key] = {
        type = "click",
        position = position,
        windowRelative = true
    }
    
    return storage.saveAppConfig(appId, config)
end

-- 앱의 enabled 상태 토글
function storage.toggleAppEnabled(appId, appName, bundleId)
    local config = storage.loadAppConfig(appId) or {
        enabled = false,
        appName = appName or "",
        bundleId = bundleId or appId,
        shortcuts = {}
    }
    
    config.enabled = not config.enabled
    config.appName = appName or config.appName
    config.bundleId = bundleId or config.bundleId
    
    return storage.saveAppConfig(appId, config)
end

-- 매크로 저장
function storage.saveMacro(macroName, macroData)
    storage.init()
    
    local filename = sanitizeFilename(macroName) .. ".json"
    local path = MACROS_DIR .. "/" .. filename
    
    local fh = io.open(path, "w")
    if not fh then return false end
    
    fh:write(json.encode(macroData, true))
    fh:close()
    return true
end

-- 매크로 로드
function storage.loadMacro(macroName)
    storage.init()
    
    local filename = sanitizeFilename(macroName) .. ".json"
    local path = MACROS_DIR .. "/" .. filename
    
    if not fs.attributes(path) then return nil end
    
    local fh = io.open(path, "r")
    if not fh then return nil end
    
    local content = fh:read("*a")
    fh:close()
    
    local ok, data = pcall(function() return json.decode(content) end)
    if ok and type(data) == "table" then
        return data
    end
    
    return nil
end

-- 매크로 목록
function storage.listMacros()
    storage.init()
    
    local macros = {}
    if not fs.attributes(MACROS_DIR, "mode") then
        return macros
    end
    
    for file in fs.dir(MACROS_DIR) do
        if file:match("%.json$") then
            local macroName = file:gsub("%.json$", "")
            local macro = storage.loadMacro(macroName)
            if macro then
                table.insert(macros, {
                    name = macroName,
                    data = macro
                })
            end
        end
    end
    
    return macros
end

-- 매크로 삭제
function storage.deleteMacro(macroName)
    storage.init()
    
    local filename = sanitizeFilename(macroName) .. ".json"
    local path = MACROS_DIR .. "/" .. filename
    
    if fs.attributes(path) then
        os.remove(path)
        return true
    end
    
    return false
end

return storage

