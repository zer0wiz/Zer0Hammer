-- AutoHotKeys Config Manager
local ConfigManager = {}

local json = hs.json
local fs = hs.fs

local STORAGE_DIR = hs.configdir .. "/autohotkeys"
local CONFIG_FILE = STORAGE_DIR .. "/config.json"

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
        enabled = false
    },
    excludedApps = {
        "com.hammerspoon.Hammerspoon"
    },
    clickAnimation = {
        color = "#FF5733"
    }
}

local cache = {
    config = nil,
    lastModified = 0
}

local function getFileModifiedTime(filePath)
    local attrs = fs.attributes(filePath)
    if attrs and attrs.modification then
        return attrs.modification
    end
    return 0
end

function ConfigManager.init()
    if not fs.attributes(STORAGE_DIR, "mode") then
        fs.mkdir(STORAGE_DIR)
    end
end

function ConfigManager.load()
    ConfigManager.init()

    local modifiedTime = getFileModifiedTime(CONFIG_FILE)
    if cache.config and cache.lastModified == modifiedTime then
        return cache.config
    end

    if not fs.attributes(CONFIG_FILE) then
        ConfigManager.save(defaultConfig)
        cache.config = defaultConfig
        cache.lastModified = modifiedTime
        return defaultConfig
    end

    local fh = io.open(CONFIG_FILE, "r")
    if not fh then
        cache.config = defaultConfig
        return defaultConfig
    end

    local content = fh:read("*a")
    fh:close()

    local ok, data = pcall(function() return json.decode(content) end)
    if ok and type(data) == "table" then
        local merged = {}
        for k, v in pairs(defaultConfig) do
            merged[k] = data[k] or v
        end
        cache.config = merged
        cache.lastModified = modifiedTime
        return merged
    end

    cache.config = defaultConfig
    return defaultConfig
end

function ConfigManager.save(config)
    ConfigManager.init()

    local fh = io.open(CONFIG_FILE, "w")
    if not fh then return false end

    fh:write(json.encode(config, true))
    fh:close()

    cache.config = config
    cache.lastModified = getFileModifiedTime(CONFIG_FILE)

    return true
end

function ConfigManager.getValue(path)
    local config = ConfigManager.load()
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

return ConfigManager
