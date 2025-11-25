-- AutoHotKeys 핫키 충돌 감지 모듈
local validator = {}

local hotkey = hs.hotkey

-- 등록된 핫키 추적
validator.registeredHotkeys = {}

-- 핫키 문자열 생성
local function hotkeyToString(mods, key)
    local modStrings = {}
    for _, mod in ipairs(mods) do
        table.insert(modStrings, mod)
    end
    return table.concat(modStrings, "+") .. "+" .. key
end

-- 핫키 등록
function validator.register(mods, key, fn)
    local keyString = hotkeyToString(mods, key)
    
    -- 이미 등록된 핫키인지 확인
    if validator.registeredHotkeys[keyString] then
        validator.logger = validator.logger or hs.logger.new("HotkeyValidator")
        validator.logger.w("핫키 충돌 감지: " .. keyString .. " (이미 등록됨)")
        return false, "핫키가 이미 등록되어 있습니다: " .. keyString
    end
    
    -- 핫키 등록 시도
    local success, hotkeyObj = pcall(function()
        return hotkey.bind(mods, key, fn)
    end)
    
    if success and hotkeyObj then
        validator.registeredHotkeys[keyString] = {
            mods = mods,
            key = key,
            hotkey = hotkeyObj
        }
        return true, hotkeyObj
    else
        validator.logger = validator.logger or hs.logger.new("HotkeyValidator")
        validator.logger.w("핫키 등록 실패: " .. keyString)
        return false, "핫키 등록 실패: " .. keyString
    end
end

-- 핫키 해제
function validator.unregister(mods, key)
    local keyString = hotkeyToString(mods, key)
    
    if validator.registeredHotkeys[keyString] then
        local hotkeyObj = validator.registeredHotkeys[keyString].hotkey
        if hotkeyObj then
            hotkeyObj:delete()
        end
        validator.registeredHotkeys[keyString] = nil
        return true
    end
    
    return false
end

-- 핫키 충돌 확인
function validator.checkConflict(mods, key)
    local keyString = hotkeyToString(mods, key)
    
    if validator.registeredHotkeys[keyString] then
        return true, "핫키가 이미 등록되어 있습니다: " .. keyString
    end
    
    return false
end

-- 대체 핫키 제안
function validator.suggestAlternatives(mods, key)
    local alternatives = {}
    
    -- 같은 키에 다른 모디파이어 조합 제안
    local modCombinations = {
        {"cmd"},
        {"ctrl"},
        {"shift"},
        {"alt"},
        {"cmd", "ctrl"},
        {"cmd", "shift"},
        {"cmd", "alt"},
        {"ctrl", "shift"},
        {"ctrl", "alt"},
        {"shift", "alt"},
        {"cmd", "ctrl", "shift"},
        {"cmd", "ctrl", "alt"},
        {"cmd", "shift", "alt"},
        {"ctrl", "shift", "alt"}
    }
    
    for _, altMods in ipairs(modCombinations) do
        local altString = hotkeyToString(altMods, key)
        if not validator.registeredHotkeys[altString] then
            table.insert(alternatives, {
                mods = altMods,
                key = key,
                string = altString
            })
        end
    end
    
    return alternatives
end

-- 모든 등록된 핫키 목록
function validator.listRegistered()
    local list = {}
    for keyString, data in pairs(validator.registeredHotkeys) do
        table.insert(list, {
            string = keyString,
            mods = data.mods,
            key = data.key
        })
    end
    return list
end

-- 핫키 초기화 (모든 핫키 해제)
function validator.reset()
    for keyString, data in pairs(validator.registeredHotkeys) do
        if data.hotkey then
            data.hotkey:delete()
        end
    end
    validator.registeredHotkeys = {}
end

return validator

