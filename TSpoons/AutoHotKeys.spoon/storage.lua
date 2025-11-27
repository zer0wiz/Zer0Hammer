-- AutoHotKeys Storage Module
-- Consolidated from ConfigManager, ContextManager, MacroRepository
local storage = {}

local json = hs.json
local fs = hs.fs

local STORAGE_DIR = hs.configdir .. "/autohotkeys"
local CONTEXTS_DIR = STORAGE_DIR .. "/contexts"
local MACROS_DIR = STORAGE_DIR .. "/_macros"
local CONFIG_FILE = STORAGE_DIR .. "/config.json"
local CONTEXT_LIST_FILE = STORAGE_DIR .. "/context-list.json"

-- Ensure directories exist
local function ensureDirs()
    if not fs.attributes(STORAGE_DIR, "mode") then fs.mkdir(STORAGE_DIR) end
    if not fs.attributes(CONTEXTS_DIR, "mode") then fs.mkdir(CONTEXTS_DIR) end
    if not fs.attributes(MACROS_DIR, "mode") then fs.mkdir(MACROS_DIR) end
end

local function sanitizeFilename(s)
    return (s:gsub("[^%w%._-]", "_"))
end

local function loadJson(path, default)
    if not fs.attributes(path) then return default end
    local fh = io.open(path, "r")
    if not fh then return default end
    local content = fh:read("*a")
    fh:close()
    local ok, data = pcall(function() return json.decode(content) end)
    return (ok and type(data) == "table") and data or default
end

local function saveJson(path, data)
    ensureDirs()
    local fh = io.open(path, "w")
    if not fh then return false end
    fh:write(json.encode(data, true))
    fh:close()
    return true
end

-- ============================================================================
-- Configuration
-- ============================================================================
local defaultConfig = {
    shortcutPreview = {
        circle = { radius = 20, strokeWidth = 2, strokeColor = "#FF5733", fillColor = "#FF5733", fillAlpha = 0.7 },
        text = { size = 14, color = "#FFFFFF", font = "Arial Bold" },
        overlay = { color = "#000000", alpha = 0.3 }
    },
    menu = { position = { x = nil, y = nil }, saved = false },
    overlay = { enabled = false },
    excludedApps = { "com.hammerspoon.Hammerspoon" },
    clickAnimation = { color = "#FF5733" }
}

function storage.loadConfig()
    local config = loadJson(CONFIG_FILE, defaultConfig)
    -- Merge defaults
    for k, v in pairs(defaultConfig) do
        if config[k] == nil then config[k] = v end
    end
    return config
end

function storage.saveConfig(config)
    return saveJson(CONFIG_FILE, config)
end

-- ============================================================================
-- Contexts
-- ============================================================================
function storage.loadContextList()
    return loadJson(CONTEXT_LIST_FILE, { version = "1.0", contexts = {} })
end

function storage.saveContextList(list)
    return saveJson(CONTEXT_LIST_FILE, list)
end

function storage.findContext(contextId)
    local list = storage.loadContextList()
    for _, ctx in ipairs(list.contexts) do
        if ctx.id == contextId then return ctx end
    end
    return nil
end

function storage.loadContextConfig(contextId)
    local filename = sanitizeFilename(contextId) .. ".json"
    return loadJson(CONTEXTS_DIR .. "/" .. filename, nil)
end

function storage.saveContextConfig(contextId, config)
    local filename = sanitizeFilename(contextId) .. ".json"
    return saveJson(CONTEXTS_DIR .. "/" .. filename, config)
end

function storage.addContext(contextData)
    if not contextData.id then return false, "ID required" end
    local list = storage.loadContextList()
    for _, ctx in ipairs(list.contexts) do
        if ctx.id == contextData.id then return false, "Context exists" end
    end

    local newContext = {
        id = contextData.id,
        type = contextData.type,
        appName = contextData.appName,
        bundleId = contextData.bundleId,
        domain = contextData.domain,
        enabled = contextData.enabled or false,
        configPath = "contexts/" .. sanitizeFilename(contextData.id) .. ".json",
        createdAt = os.time(),
        updatedAt = os.time()
    }
    table.insert(list.contexts, newContext)

    if storage.saveContextList(list) then
        storage.saveContextConfig(contextData.id, { context = newContext, shortcuts = {} })
        return true, newContext
    end
    return false, "Save failed"
end

function storage.toggleAppEnabled(contextId)
    local list = storage.loadContextList()
    for _, ctx in ipairs(list.contexts) do
        if ctx.id == contextId then
            ctx.enabled = not ctx.enabled
            ctx.updatedAt = os.time()
            storage.saveContextList(list)
            return true
        end
    end
    return false
end

-- ============================================================================
-- Macros
-- ============================================================================
function storage.saveMacro(name, data)
    local filename = sanitizeFilename(name) .. ".json"
    return saveJson(MACROS_DIR .. "/" .. filename, data)
end

function storage.loadMacro(name)
    local filename = sanitizeFilename(name) .. ".json"
    return loadJson(MACROS_DIR .. "/" .. filename, nil)
end

function storage.listMacros()
    ensureDirs()
    local macros = {}
    for file in fs.dir(MACROS_DIR) do
        if file:match("%.json$") then
            local name = file:gsub("%.json$", "")
            local data = storage.loadMacro(name)
            if data then table.insert(macros, { name = name, data = data }) end
        end
    end
    return macros
end

function storage.deleteMacro(name)
    local filename = sanitizeFilename(name) .. ".json"
    local path = MACROS_DIR .. "/" .. filename
    if fs.attributes(path) then
        os.remove(path); return true
    end
    return false
end

-- ============================================================================
-- Legacy / Compatibility
-- ============================================================================
function storage.loadAppConfig(appId) return storage.loadContextConfig(appId) end

function storage.saveAppConfig(appId, config) return storage.saveContextConfig(appId, config) end

return storage
