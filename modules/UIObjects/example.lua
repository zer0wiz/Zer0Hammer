-- UIObjects 사용 예제
-- 이 파일을 Hammerspoon에서 로드하여 테스트할 수 있습니다.

local UIObjects = require("modules.UIObjects.init")
local ToggleButton = UIObjects.ToggleButton

-- 또는 직접 로드
-- local ToggleButton = require("modules.UIObjects.toggle_button")

-- 예제 1: 기본 토글 버튼
local toggle1 = ToggleButton.create({
    x = 100,
    y = 100,
    width = 280,
    height = 40,
    label = "안정적인 볼륨",
    value = true,
    callback = function(value)
        hs.alert.show("안정적인 볼륨: " .. (value and "ON" or "OFF"))
    end
})

-- 예제 2: 아이콘이 있는 토글 버튼
local toggle2 = ToggleButton.create({
    x = 100,
    y = 150,
    width = 280,
    height = 40,
    label = "영화 조명",
    value = false,
    callback = function(value)
        hs.alert.show("영화 조명: " .. (value and "ON" or "OFF"))
    end
})

-- 예제 3: 커스텀 색상 토글 버튼
local toggle3 = ToggleButton.create({
    x = 100,
    y = 200,
    width = 280,
    height = 40,
    label = "특수효과",
    value = true,
    onColor = {red = 0.1, green = 0.5, blue = 1.0, alpha = 1.0},  -- 파란색
    callback = function(value)
        hs.alert.show("특수효과: " .. (value and "ON" or "OFF"))
    end
})

-- 모든 토글 버튼 표시
toggle1:show()
toggle2:show()
toggle3:show()

-- 5초 후 모든 토글 버튼 숨기기
hs.timer.doAfter(5, function()
    toggle1:delete()
    toggle2:delete()
    toggle3:delete()
end)

-- 콘솔에서 테스트:
-- ToggleButton.setValue(toggle1, false)
-- print(ToggleButton.getValue(toggle1))

