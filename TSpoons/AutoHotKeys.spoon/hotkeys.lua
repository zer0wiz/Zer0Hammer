-- AutoHotKeys Hotkeys 모듈
local hotkeys = {}

local hotkey = hs.hotkey

-- Hotkeys 바인딩
function hotkeys.bind(obj)
    if obj.menuHotkey then
        obj.menuHotkey:delete()
    end
    
    -- obj.hotkey 설정이 있으면 사용, 없으면 기본값 사용
    local modifiers, key = table.unpack(obj.hotkey or {{"alt", "shift", "cmd"}, "k"})
    
    obj.menuHotkey = hotkey.bind(modifiers, key, function()
        obj.menu.toggle(obj)
    end)
end

-- Hotkeys 해제
function hotkeys.unbind(obj)
    if obj.menuHotkey then
        obj.menuHotkey:delete()
        obj.menuHotkey = nil
    end
end

return hotkeys

