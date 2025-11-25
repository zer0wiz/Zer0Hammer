-- AutoHotKeys Hotkeys 모듈
local hotkeys = {}

local hotkey = hs.hotkey

-- 핫키 바인딩 헬퍼 (충돌 감지 포함)
local function bindHotkey(obj, keyName, mods, key, fn)
    -- hotkeyValidator가 있으면 사용
    if obj.hotkeyValidator then
        local conflict, err = obj.hotkeyValidator.checkConflict(mods, key)
        if conflict then
            obj.logger.w("핫키 충돌 감지: " .. keyName .. " - " .. (err or "알 수 없음"))
            -- 충돌이 있어도 기본 방식으로 등록 시도
        end
        
        local success, hotkeyObj = obj.hotkeyValidator.register(mods, key, fn)
        if success then
            return hotkeyObj
        else
            -- validator 실패 시 기본 방식으로 시도
            obj.logger.w("핫키 validator 실패, 기본 방식으로 시도: " .. keyName)
        end
    end
    
    -- 기본 핫키 바인딩
    return hotkey.bind(mods, key, fn)
end
-- Hotkeys 바인딩
function hotkeys.bind(obj)
    if obj.menuHotkey then
        obj.menuHotkey:delete()
    end
    
    -- ctrl + cmd + k로 메뉴 토글
    obj.menuHotkey = bindHotkey(obj, "menuToggle", {"ctrl", "cmd"}, "k", function()
        obj.menu.toggle(obj)
    end)
    
    -- 매크로 녹화 시작/중지 단축키
    if obj.recordingHotkey then
        obj.recordingHotkey:delete()
    end
    
    obj.recordingHotkey = bindHotkey(obj, "recording", {"ctrl", "cmd"}, "r", function()
        if obj.recorder and obj.recorder.isRecording(obj) then
            -- 녹화 중지
            local success, macro = obj.recorder.stop(obj)
            if success and macro then
                -- 간단한 이름 입력 (AppleScript 사용)
                local script = [[
                    tell application "System Events"
                        display dialog "매크로 이름을 입력하세요:" default answer "]] .. (macro.name or "") .. [[" buttons {"취소", "저장"} default button "저장"
                        set result to button returned of result
                        set name to text returned of result
                    end tell
                    return result & "|" & name
                ]]
                
                local ok, result = hs.osascript.applescript(script)
                if ok and result then
                    local parts = {}
                    for part in string.gmatch(result, "[^|]+") do
                        table.insert(parts, part)
                    end
                    if parts[1] == "저장" and parts[2] and parts[2] ~= "" then
                        obj.storage.saveMacro(parts[2], macro)
                        hs.alert.show("매크로 저장됨: " .. parts[2], 2.0)
                    end
                end
            end
            obj.overlay.update(obj)
        else
            -- 녹화 시작
            local success, err = obj.recorder.start(obj)
            if success then
                hs.alert.show("녹화 시작", 1.0)
                obj.overlay.update(obj)
            else
                hs.alert.show("녹화 시작 실패: " .. (err or "알 수 없음"), 2.0)
            end
        end
    end)
    
    -- 매크로 목록 열기 단축키
    if obj.macroListHotkey then
        obj.macroListHotkey:delete()
    end
    
    obj.macroListHotkey = bindHotkey(obj, "macroList", {"ctrl", "cmd"}, "m", function()
        if obj.menu then
            obj.menu.showMacroList(obj)
        end
    end)
    
    -- -- ESC 키로 메뉴 숨기기 (메뉴가 포커스되었을 때만)
    -- if obj.escapeHotkey then
    --     obj.escapeHotkey:delete()
    -- end
    
    -- obj.escapeHotkey = hotkey.bind({}, "escape", function()
    --     -- 메뉴가 포커스되었을 때만 ESC 동작
    --     if obj.menu and obj.menuShowing then
    --         obj.menu.hide(obj)
    --     end
    -- end)
end

-- Hotkeys 해제
function hotkeys.unbind(obj)
    -- hotkeyValidator를 사용한 경우 해제
    if obj.hotkeyValidator then
        obj.hotkeyValidator.unregister({"ctrl", "cmd"}, "k")
        obj.hotkeyValidator.unregister({"ctrl", "cmd"}, "r")
        obj.hotkeyValidator.unregister({"ctrl", "cmd"}, "m")
    end
    
    if obj.menuHotkey then
        obj.menuHotkey:delete()
        obj.menuHotkey = nil
    end
    
    if obj.recordingHotkey then
        obj.recordingHotkey:delete()
        obj.recordingHotkey = nil
    end
    
    if obj.macroListHotkey then
        obj.macroListHotkey:delete()
        obj.macroListHotkey = nil
    end
    
    -- if obj.escapeHotkey then
    --     obj.escapeHotkey:delete()
    --     obj.escapeHotkey = nil
    -- end
end

return hotkeys

