-- AutoHotKeys Hotkeys 모듈
local hotkeys = {}

local hotkey = hs.hotkey

-- Hotkeys 바인딩
function hotkeys.bind(obj)
    if obj.menuHotkey then
        obj.menuHotkey:delete()
    end
    
    -- ctrl + cmd + k로 메뉴 토글
    obj.menuHotkey = hotkey.bind({"ctrl", "cmd"}, "k", function()
        obj.menu.toggle(obj)
    end)
    
    -- 매크로 녹화 시작/중지 단축키
    if obj.recordingHotkey then
        obj.recordingHotkey:delete()
    end
    
    obj.recordingHotkey = hotkey.bind({"ctrl", "cmd"}, "r", function()
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
    
    obj.macroListHotkey = hotkey.bind({"ctrl", "cmd"}, "m", function()
        if obj.menu then
            obj.menu.showMacroList(obj)
        end
    end)
end

-- Hotkeys 해제
function hotkeys.unbind(obj)
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
end

return hotkeys

