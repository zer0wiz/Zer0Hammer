-- AutoHotKeys Macro Repository
local MacroRepository = {}

local json = hs.json
local fs = hs.fs

local STORAGE_DIR = hs.configdir .. "/autohotkeys"
local MACROS_DIR = STORAGE_DIR .. "/_macros"

local function sanitizeFilename(s)
    return (s:gsub("[^%w%._-]", "_"))
end

function MacroRepository.init()
    if not fs.attributes(STORAGE_DIR, "mode") then
        fs.mkdir(STORAGE_DIR)
    end
    if not fs.attributes(MACROS_DIR, "mode") then
        fs.mkdir(MACROS_DIR)
    end
end

function MacroRepository.save(macroName, macroData)
    MacroRepository.init()
    
    local filename = sanitizeFilename(macroName) .. ".json"
    local path = MACROS_DIR .. "/" .. filename
    
    local fh = io.open(path, "w")
    if not fh then return false end
    
    fh:write(json.encode(macroData, true))
    fh:close()
    return true
end

function MacroRepository.load(macroName)
    MacroRepository.init()
    
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

function MacroRepository.list()
    MacroRepository.init()
    
    local macros = {}
    if not fs.attributes(MACROS_DIR, "mode") then
        return macros
    end
    
    for file in fs.dir(MACROS_DIR) do
        if file:match("%.json$") then
            local macroName = file:gsub("%.json$", "")
            local macro = MacroRepository.load(macroName)
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

function MacroRepository.delete(macroName)
    MacroRepository.init()
    
    local filename = sanitizeFilename(macroName) .. ".json"
    local path = MACROS_DIR .. "/" .. filename
    
    if fs.attributes(path) then
        os.remove(path)
        return true
    end
    
    return false
end

return MacroRepository
