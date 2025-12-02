# UIObjects

재사용 가능한 UI 컴포넌트 라이브러리입니다. Hammerspoon 스푼이나 스크립트에서 사용할 수 있습니다.

## 사용법

```lua
-- 모듈 로드
local UIObjects = require("UIObjects")
local ToggleButton = UIObjects.ToggleButton

-- 또는 직접 로드
local toggle_button = require("modules.UIObjects.toggle_button")
```

## 컴포넌트

### ToggleButton

YouTube 스타일의 토글 버튼을 생성합니다.

#### 기본 사용법

```lua
local ToggleButton = require("modules.UIObjects.toggle_button")

-- 토글 버튼 생성
local toggle = ToggleButton.create({
    x = 100,
    y = 100,
    width = 280,
    height = 40,
    label = "안정적인 볼륨",
    value = true,  -- 초기값
    callback = function(value)
        print("토글 상태:", value)
    end
})

toggle:show()
```

#### 아이콘이 있는 토글 버튼

```lua
local toggle = ToggleButton.create({
    x = 100,
    y = 150,
    width = 280,
    height = 40,
    icon = hs.image.imageFromPath("/path/to/icon.png"),
    label = "영화 조명",
    value = false,
    callback = function(value)
        if value then
            print("영화 조명 켜짐")
        else
            print("영화 조명 꺼짐")
        end
    end
})

toggle:show()
```

#### 색상 커스터마이징

```lua
local toggle = ToggleButton.create({
    x = 100,
    y = 200,
    width = 280,
    height = 40,
    label = "특수효과",
    value = true,
    onColor = {red = 0.1, green = 0.5, blue = 1.0, alpha = 1.0},  -- ON일 때 파란색
    offColor = {white = 0.3, alpha = 1.0},
    trackColor = {white = 0.2, alpha = 1.0},
    thumbColor = {white = 1.0, alpha = 1.0},
    labelColor = {white = 1.0, alpha = 1.0},
    callback = function(value)
        print("특수효과:", value)
    end
})

toggle:show()
```

#### 동적으로 값 변경

```lua
local toggle = ToggleButton.create({
    x = 100,
    y = 250,
    width = 280,
    height = 40,
    label = "설정",
    value = false
})

-- 값 설정
ToggleButton.setValue(toggle, true)

-- 값 가져오기
local currentValue = ToggleButton.getValue(toggle)
print("현재 값:", currentValue)

-- 레이블 변경
ToggleButton.setLabel(toggle, "새 레이블")

-- 콜백 나중에 설정
ToggleButton.setCallback(toggle, function(value)
    print("콜백 호출:", value)
end)
```

## 옵션 파라미터

### ToggleButton.create(options)

- `x` (number): X 좌표 (기본값: 0)
- `y` (number): Y 좌표 (기본값: 0)
- `width` (number): 버튼 너비 (기본값: 200)
- `height` (number): 버튼 높이 (기본값: 30)
- `icon` (string|hs.image): 아이콘 이미지 (선택사항)
  - 문자열: 이미지 파일 경로
  - hs.image 객체: 이미지 객체
- `label` (string): 레이블 텍스트
- `value` (boolean): 초기 값 (기본값: false)
- `onColor` (table): ON 상태 트랙 색상 (기본값: {red = 0.2, green = 0.8, blue = 0.2, alpha = 1.0})
- `offColor` (table): OFF 상태 트랙 색상 (기본값: {white = 0.3, alpha = 1.0})
- `trackColor` (table): 트랙 배경 색상 (기본값: {white = 0.2, alpha = 1.0})
- `thumbColor` (table): 썸(동그라미) 색상 (기본값: {white = 1.0, alpha = 1.0})
- `labelColor` (table): 레이블 텍스트 색상 (기본값: {white = 1.0, alpha = 1.0})
- `labelSize` (number): 레이블 폰트 크기 (기본값: 13)
- `callback` (function): 상태 변경 시 호출될 함수 `function(value)`

## API

### ToggleButton.create(options)

토글 버튼을 생성합니다.

**반환값**: hs.canvas 객체

### ToggleButton.setValue(canvas_obj, value)

토글 버튼의 값을 설정합니다.

- `canvas_obj` (hs.canvas): 토글 버튼 canvas 객체
- `value` (boolean): 설정할 값

**반환값**: canvas 객체

### ToggleButton.getValue(canvas_obj)

토글 버튼의 현재 값을 가져옵니다.

- `canvas_obj` (hs.canvas): 토글 버튼 canvas 객체

**반환값**: boolean 또는 nil

### ToggleButton.setLabel(canvas_obj, label)

토글 버튼의 레이블을 변경합니다.

- `canvas_obj` (hs.canvas): 토글 버튼 canvas 객체
- `label` (string): 새 레이블

**반환값**: canvas 객체

### ToggleButton.setCallback(canvas_obj, callback)

토글 버튼의 콜백을 설정합니다.

- `canvas_obj` (hs.canvas): 토글 버튼 canvas 객체
- `callback` (function): 콜백 함수 `function(value)`

**반환값**: canvas 객체

## 예제

### AutoHotKeys 스푼에서 사용

```lua
-- TSpoons/AutoHotKeys.spoon/menu.lua
local ToggleButton = require("modules.UIObjects.toggle_button")

function menu.show(obj)
    -- ... 기존 코드 ...
    
    -- 오버레이 토글 버튼 추가
    local overlayToggle = ToggleButton.create({
        x = 10,
        y = 100,
        width = 260,
        height = 35,
        label = "오버레이 표시",
        value = obj.storage.loadConfig().overlay.enabled or false,
        callback = function(value)
            local config = obj.storage.loadConfig()
            config.overlay.enabled = value
            obj.storage.saveConfig(config)
            obj.overlay.update(obj)
        end
    })
    
    -- canvas에 토글 버튼 추가 또는 별도로 표시
    overlayToggle:show()
end
```

## 라이선스

이 모듈은 Zer0Hammer 프로젝트의 일부입니다.

