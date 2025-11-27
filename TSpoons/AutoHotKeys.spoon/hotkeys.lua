-- AutoHotKeys Hotkeys Module
-- Consolidated from hotkeys.lua and hotkeyValidator.lua
local hotkeys = {}

local hotkey = hs.hotkey
local logger = hs.logger.new("AutoHotKeys")

-- Internal dependencies
local storage = require("storage")
local ui = require("ui")

-- ============================================================================
-- Validator / Registry
-- ============================================================================
hotkeys.registered = {}

local function hotkeyToString(mods, key)
    local modStrings = {}
    for _, mod in ipairs(mods) do table.insert(modStrings, mod) end
    return table.concat(modStrings, "+") .. "+" .. key
end

function hotkeys.checkConflict(mods, key)
    local keyString = hotkeyToString(mods, key)
    if hotkeys.registered[keyString] then
        return true, "Hotkey already registered: " .. keyString
    end
    return false
end

function hotkeys.register(mods, key, fn)
    local keyString = hotkeyToString(mods, key)
    if hotkeys.registered[keyString] then
        logger.w("Hotkey conflict: " .. keyString)
        return false, "Already registered"
    end

    local success, hk = pcall(function() return hotkey.bind(mods, key, fn) end)
    if success and hk then
        hotkeys.registered[keyString] = { mods = mods, key = key, hotkey = hk }
        return true, hk
    else
        logger.w("Failed to bind hotkey: " .. keyString)
        return false, "Bind failed"
    end
end

function hotkeys.unregister(mods, key)
    local keyString = hotkeyToString(mods, key)
    if hotkeys.registered[keyString] then
        if hotkeys.registered[keyString].hotkey then
            hotkeys.registered[keyString].hotkey:delete()
        end
        hotkeys.registered[keyString] = nil
        return true
    end
    return false
end

function hotkeys.reset()
    for _, data in pairs(hotkeys.registered) do
        if data.hotkey then data.hotkey:delete() end
    end
    hotkeys.registered = {}
end

-- ============================================================================
-- Bindings
-- ============================================================================
function hotkeys.bind(obj)
    hotkeys.reset()

    -- Menu Toggle (Ctrl+Cmd+K)
    hotkeys.register({ "ctrl", "cmd" }, "k", function()
        ui.menu.toggle(obj)
    end)

    -- Recording (Ctrl+Cmd+R)
    hotkeys.register({ "ctrl", "cmd" }, "r", function()
        if obj.recorder and obj.recorder.isRecording(obj) then
            local success, macro = obj.recorder.stop(obj)
            if success and macro then
                local script = [[
                    tell application "System Events"
                        display dialog "Enter macro name:" default answer "]] ..
                (macro.name or "") .. [[" buttons {"Cancel", "Save"} default button "Save"
                        set result to button returned of result
                        set name to text returned of result
                    end tell
                    return result & "|" & name
                ]]
                local ok, result = hs.osascript.applescript(script)
                if ok and result then
                    local parts = {}
                    for part in string.gmatch(result, "[^|]+") do table.insert(parts, part) end
                    if parts[1] == "Save" and parts[2] and parts[2] ~= "" then
                        storage.saveMacro(parts[2], macro)
                        hs.alert.show("Macro saved: " .. parts[2], 2.0)
                    end
                end
            end
            ui.overlay.update(obj)
        else
            local success, err = obj.recorder.start(obj)
            if success then
                hs.alert.show("Recording started", 1.0)
                ui.overlay.update(obj)
            else
                hs.alert.show("Failed to start recording: " .. (err or "Unknown"), 2.0)
            end
        end
    end)

    -- Macro List (Ctrl+Cmd+M)
    hotkeys.register({ "ctrl", "cmd" }, "m", function()
        ui.menu.showMacroList(obj)
    end)

    -- Quick Capture (Ctrl+Click) - handled by recorder module, but we can bind a toggle if needed
    -- For now, it's enabled via menu or other means, or we can auto-enable it if configured.
    -- The original code didn't bind a hotkey for this, but had a function to enable it.
end

function hotkeys.unbind(obj)
    hotkeys.reset()
end

return hotkeys
