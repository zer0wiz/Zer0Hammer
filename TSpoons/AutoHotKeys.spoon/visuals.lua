local visuals = {}
local canvas = hs.canvas
local timer = hs.timer
local drawing = hs.drawing

-- 클릭 애니메이션 표시
function visuals.showClickAnimation(point, color)
    local initialSize = 10
    local finalSize = 60
    local duration = 0.5

    local function hexToRGB(hex)
        hex = hex:gsub("#", "")
        return {
            red = tonumber("0x" .. hex:sub(1, 2)) / 255,
            green = tonumber("0x" .. hex:sub(3, 4)) / 255,
            blue = tonumber("0x" .. hex:sub(5, 6)) / 255,
            alpha = 1.0
        }
    end

    local strokeColor = { red = 1, green = 0.2, blue = 0.2, alpha = 1 }
    if color then
        if type(color) == "string" then
            strokeColor = hexToRGB(color)
        elseif type(color) == "table" then
            strokeColor = color
        end
    end

    local c = canvas.new({
        x = point.x - initialSize / 2,
        y = point.y - initialSize / 2,
        w = initialSize,
        h = initialSize
    })

    if not c then return end

    c:behavior(canvas.windowBehaviors.canJoinAllSpaces)
    c:level(canvas.windowLevels.cursor)

    c[1] = {
        type = "circle",
        action = "stroke",
        strokeColor = strokeColor,
        strokeWidth = 3,
    }

    c:show()

    local startTime = timer.secondsSinceEpoch()

    local animTimer
    animTimer = timer.doEvery(0.02, function()
        local timePassed = timer.secondsSinceEpoch() - startTime
        if timePassed >= duration then
            if c then c:delete() end
            if animTimer then animTimer:stop() end
            return
        end

        local progress = timePassed / duration
        -- Ease out quad
        progress = 1 - (1 - progress) * (1 - progress)

        local currentSize = initialSize + ((finalSize - initialSize) * progress)
        local currentAlpha = 1 - progress

        if c then
            c:frame({
                x = point.x - currentSize / 2,
                y = point.y - currentSize / 2,
                w = currentSize,
                h = currentSize
            })

            c[1].strokeColor.alpha = currentAlpha
        end
    end)
end

return visuals
