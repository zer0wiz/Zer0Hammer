-- UIObjects 모듈 초기화 및 로더
-- 모든 UI 컴포넌트를 쉽게 로드할 수 있도록 제공

local UIObjects = {}

-- 현재 파일의 디렉토리 경로
local currentDir = debug.getinfo(1, "S").source:match("@?(.*/)")
local elementsDir = currentDir .. "elements/"

-- Elements 모듈 로드
UIObjects.Layer = dofile(elementsDir .. "layer.lua")
UIObjects.Text = dofile(elementsDir .. "text.lua")
UIObjects.Title = dofile(elementsDir .. "title.lua")
UIObjects.Divider = dofile(elementsDir .. "divider.lua")
UIObjects.ToggleButton = dofile(elementsDir .. "toggle_button.lua")
UIObjects.Rectangle = dofile(elementsDir .. "rectangle.lua")

return UIObjects

