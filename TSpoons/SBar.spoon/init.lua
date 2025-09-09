package.cpath = package.cpath .. ";" .. os.getenv("HOME") .. "/.local/share/sketchybar_lua/?.so"

package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/sketchybar/?.lua"
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.config/sketchybar/?/init.lua"

require("extensions")

-- Set the bar name, if you are using another bar instance than sketchybar
-- sbar.set_bar_name("bottom_bar")

-- Bundle the entire initial configuration into a single message to sketchybar
sbar.begin_config()
-- require("bar")
-- require("default")
-- require("items")
sbar.end_config()

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
-- sbar.event_loop()
local obj={}
obj.__index = obj

-- Metadata
obj.name = "Sbar"
obj.version = "1.0"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new('SBar')
obj.sketchybarCmd = "/opt/homebrew/bin/sketchybar"

-- Execute a command and return its output with trailing EOLs trimmed. If the command fails, an error message is logged.

subRequire("items")

local function runBrewSerivceRun()
    print("================================================")
    obj.app = getApplication("sketchybar")
    if obj.app then
        print(string.format("Already application :: [%s]-%s",obj.app:pid(), obj.app:name()))
    else
        print("No exist Application [sketchybar]")
        local cmd = string.format("brew services start sketchybar")
        print("### ---" .. cmd)
        -- _exec("/opt/homebrew/bin/sketchybar")
        -- _exec(cmd, "Error runcCheck execute [%s] : %s", cmd)
        sbar.exec(cmd)
		-- os.execute(cmd)
    end
    print("================================================")

end

local function show_input_source()
    -- end the alert function if the alert is the same as the previous one
    if hs.keycodes.currentSourceID() == Last_alerted_IM_ID then return end
    print('changed')
    -- print(hs.keycodes.curreSourceID())

    -- close the previous alert about IM changing
    -- hs.alert.closeSpecific(last_IM_alert_uuid)
    -- print(last_IM_alert_uuid)
    -- last_IM_alert_uuid = hs.alert.show(...)
    Last_alerted_IM_ID = hs.keycodes.currentSourceID()

    local inputEnglish = "com.apple.keylayout.ABC"
    local inputKorean = "com.apple.inputmethod.Korean.2SetKorean"
    local im = "??"

    if (Last_alerted_IM_ID == inputEnglish) then
        -- print('abc')
        -- hs.alert.show('ABC', 5)
        im="abc"
    end
    if (Last_alerted_IM_ID == inputKorean) then
        -- print('kr')
        -- hs.alert.show('2-Set Korean', 5)
        im="kr"
    end
    local cmd = string.format("%s --trigger input_source_change im=%s",obj.sketchybarCmd, im)
    print(cmd)
    -- _exec(cmd, "Err trigger call sbar.")
    sbar.exec(cmd)
end

function obj:init()
    runBrewSerivceRun()
    print("Set inputSourceChanged event ~~")
    hs.keycodes.inputSourceChanged(function ()
        show_input_source()
    end)
end

return obj
