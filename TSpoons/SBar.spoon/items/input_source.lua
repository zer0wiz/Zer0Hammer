local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local source_table = {
    kr = {
        label = "한",
    },
    abc = {
        label = "ABC",
    }
}

local input_source = sbar.add("item", "input_source" , {
    position = "right",
    icon = {
        drawing = false,
    },
    label = {
            padding_left = 3,
            padding_right = 0,
            width = 40,
        --     color = colors.white,
        align = "center",
        font = { family = settings.font.numbers },
        string = "??",
    },
    background = {
        padding_right = -1,
        color = colors.bg2,
        border_width = 1,
        --     color = colors.transparent,
        border_color = colors.grey,
    },
    update_freq = 0,
})

-- trigger event from hammerspoon SBar.spoon
-- ~/github/public/spacehammer/TSpoons/SBar.spoon/init.lua
input_source:subscribe("input_source_change", function(result)
    -- print(result.im)
    local source = source_table[result.im]

    input_source:set( {
        label = {
            string = source.label
        }
    })
end)
