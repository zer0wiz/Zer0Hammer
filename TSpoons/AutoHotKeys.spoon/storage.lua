-- AutoHotKeys 스토리지 관리 모듈
local storage = {}

local json = hs.json
local fs = hs.fs

-- 저장소 디렉터리
local STORAGE_DIR = hs.configdir .. "/autohotkeys"

-- 파일명 안전 처리
local function sanitizeFilename(s)
    return (s:gsub("[^%w%._-]", "_"))
end

-- 저장소 디렉터리 생성
function storage.init()
    if not fs.attributes(STORAGE_DIR, "mode") then
        fs.mkdir(STORAGE_DIR)
    end
end

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

return storage

