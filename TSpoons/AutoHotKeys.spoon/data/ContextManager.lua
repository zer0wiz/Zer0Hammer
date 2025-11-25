-- AutoHotKeys Context Manager
local ContextManager = {}

local json = hs.json
local fs = hs.fs

local STORAGE_DIR = hs.configdir .. "/autohotkeys"
local CONTEXTS_DIR = STORAGE_DIR .. "/contexts"
local CONTEXT_LIST_FILE = STORAGE_DIR .. "/context-list.json"

local cache = {
    contextList = nil,
    contextConfigs = {},
    lastModified = {}
}

local function sanitizeFilename(s)
    return (s:gsub("[^%w%._-]", "_"))
end

local function getFileModifiedTime(filePath)
    local attrs = fs.attributes(filePath)
    if attrs and attrs.modification then
        return attrs.modification
    end
    return 0
end

local function defaultContextList()
    return {
        version = "1.0",
        contexts = {}
    }
end

function ContextManager.init()
    if not fs.attributes(STORAGE_DIR, "mode") then
        fs.mkdir(STORAGE_DIR)
    end
    if not fs.attributes(CONTEXTS_DIR, "mode") then
        fs.mkdir(CONTEXTS_DIR)
    end
end

function ContextManager.loadList()
    ContextManager.init()
    
    local modifiedTime = getFileModifiedTime(CONTEXT_LIST_FILE)
    if cache.contextList and cache.lastModified[CONTEXT_LIST_FILE] == modifiedTime then
        return cache.contextList
    end
    
    if not fs.attributes(CONTEXT_LIST_FILE) then
        local default = defaultContextList()
        ContextManager.saveList(default)
        cache.contextList = default
        cache.lastModified[CONTEXT_LIST_FILE] = modifiedTime
        return default
    end
    
    local fh = io.open(CONTEXT_LIST_FILE, "r")
    if not fh then 
        local default = defaultContextList()
        cache.contextList = default
        return default 
    end
    
    local content = fh:read("*a")
    fh:close()
    
    local ok, data = pcall(function() return json.decode(content) end)
    if ok and type(data) == "table" then
        if not data.version then data.version = "1.0" end
        if not data.contexts then data.contexts = {} end
        cache.contextList = data
        cache.lastModified[CONTEXT_LIST_FILE] = modifiedTime
        return data
    end
    
    local default = defaultContextList()
    cache.contextList = default
    return default
end

function ContextManager.saveList(contextList)
    ContextManager.init()
    
    local fh = io.open(CONTEXT_LIST_FILE, "w")
    if not fh then return false end
    
    fh:write(json.encode(contextList or defaultContextList(), true))
    fh:close()
    
    cache.contextList = contextList
    cache.lastModified[CONTEXT_LIST_FILE] = getFileModifiedTime(CONTEXT_LIST_FILE)
    
    return true
end

function ContextManager.find(contextId)
    local contextList = ContextManager.loadList()
    if not contextList or not contextList.contexts then
        return nil
    end
    
    for _, ctx in ipairs(contextList.contexts) do
        if ctx.id == contextId then
            return ctx
        end
    end
    
    return nil
end

function ContextManager.pathForConfig(contextId)
    ContextManager.init()
    local filename = sanitizeFilename(contextId) .. ".json"
    return string.format("%s/%s", CONTEXTS_DIR, filename)
end

function ContextManager.loadConfig(contextId)
    local ctx = ContextManager.find(contextId)
    if not ctx then return nil end
    
    local configPath = ContextManager.pathForConfig(contextId)
    if not fs.attributes(configPath) then return nil end
    
    local modifiedTime = getFileModifiedTime(configPath)
    if cache.contextConfigs[contextId] and cache.lastModified[configPath] == modifiedTime then
        return cache.contextConfigs[contextId]
    end
    
    local fh = io.open(configPath, "r")
    if not fh then return nil end
    
    local content = fh:read("*a")
    fh:close()
    
    local ok, data = pcall(function() return json.decode(content) end)
    if ok and type(data) == "table" then
        cache.contextConfigs[contextId] = data
        cache.lastModified[configPath] = modifiedTime
        return data
    end
    
    return nil
end

function ContextManager.saveConfig(contextId, config)
    ContextManager.init()
    
    local configPath = ContextManager.pathForConfig(contextId)
    local fh = io.open(configPath, "w")
    if not fh then return false end
    
    fh:write(json.encode(config or {}, true))
    fh:close()
    
    cache.contextConfigs[contextId] = config
    cache.lastModified[configPath] = getFileModifiedTime(configPath)
    
    return true
end

function ContextManager.add(contextData)
    if not contextData or not contextData.id then
        return false, "Context ID required"
    end
    
    if ContextManager.find(contextData.id) then
        return false, "Context already exists: " .. contextData.id
    end
    
    local contextList = ContextManager.loadList()
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
    
    table.insert(contextList.contexts, newContext)
    
    if ContextManager.saveList(contextList) then
        ContextManager.saveConfig(contextData.id, {
            context = newContext,
            shortcuts = {}
        })
        return true, newContext
    else
        return false, "Failed to save context list"
    end
end

function ContextManager.update(contextId, updates)
    local contextList = ContextManager.loadList()
    for _, ctx in ipairs(contextList.contexts) do
        if ctx.id == contextId then
            for key, value in pairs(updates) do
                if key ~= "id" and key ~= "createdAt" then
                    ctx[key] = value
                end
            end
            ctx.updatedAt = os.time()
            
            if ContextManager.saveList(contextList) then
                return true, ctx
            else
                return false, "Failed to save context list"
            end
        end
    end
    return false, "Context not found"
end

function ContextManager.remove(contextId)
    local contextList = ContextManager.loadList()
    for i, ctx in ipairs(contextList.contexts) do
        if ctx.id == contextId then
            table.remove(contextList.contexts, i)
            
            local configPath = ContextManager.pathForConfig(contextId)
            if fs.attributes(configPath) then
                os.remove(configPath)
            end
            
            if ContextManager.saveList(contextList) then
                return true
            else
                return false, "Failed to save context list"
            end
        end
    end
    return false, "Context not found"
end

return ContextManager
