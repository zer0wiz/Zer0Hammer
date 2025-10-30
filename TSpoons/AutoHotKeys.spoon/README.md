# AutoHotKeys.spoon

Windows AutoHotkey 스타일의 매크로 및 단축키 자동화 기능을 제공하는 Hammerspoon Spoon입니다.

## 기능

- **컨텍스트 기반 단축키**: 앱/사이트별로 다른 단축키 설정
- **매크로 녹화/재생**: 마우스/키보드 동작을 녹화하고 반복 실행
- **윈도우 상대 좌표**: 윈도우 크기가 변경되어도 동일한 위치 클릭
- **시각적 피드백**: 오버레이를 통한 녹화/재생 상태 표시

## 설치

1. AutoHotKeys.spoon 폴더를 `~/.hammerspoon/Spoons/` 또는 `~/.hammerspoon/TSpoons/`에 복사
2. `init.lua`에 다음 코드 추가:

```lua
hs.loadSpoon("AutoHotKeys")
spoon.AutoHotKeys:start()
```

## 단축키

- `Ctrl+Cmd+K`: AutoHotKeys 메뉴 열기
- `Ctrl+Cmd+R`: 매크로 녹화 시작/중지
- `Ctrl+Cmd+M`: 저장된 매크로 목록 보기

## 사용법

### 기본 단축키 설정

1. `Ctrl+Cmd+K`로 메뉴 열기
2. "단축키" 버튼 클릭
3. 원하는 키(a-z, 0-9) 입력
4. 클릭할 위치 선택

설정된 단축키는 해당 앱에서 키를 누르면 즉시 실행됩니다.

### 매크로 녹화

1. `Ctrl+Cmd+R`을 눌러 녹화 시작
2. 오버레이가 빨간색 "REC"로 변경됨
3. 마우스 클릭, 드래그, 키보드 입력 등 원하는 동작 수행
4. 다시 `Ctrl+Cmd+R`을 눌러 녹화 중지
5. 매크로 이름 입력 후 저장

### 매크로 재생

1. `Ctrl+Cmd+M`을 눌러 매크로 목록 열기
2. 재생 버튼(▶)을 클릭하여 매크로 실행
3. 오버레이가 파란색으로 변경되고 매크로가 재생됨

### 매크로 관리

매크로 목록 화면에서:
- **재생(▶)**: 매크로를 즉시 실행
- **삭제(✗)**: 매크로를 삭제 (확인 다이얼로그 표시)

## API 문서

### 매크로 녹화 (recorder)

#### `recorder.start(obj, macroName)`
매크로 녹화를 시작합니다.

**파라미터:**
- `obj`: AutoHotKeys 스푼 객체
- `macroName` (선택): 매크로 이름 (기본값: "macro_타임스탬프")

**반환값:**
- `success` (boolean): 녹화 시작 성공 여부
- `error` (string): 실패 시 에러 메시지

**예제:**
```lua
local success, err = spoon.AutoHotKeys.recorder.start(spoon.AutoHotKeys, "my_macro")
if not success then
    hs.alert.show("녹화 실패: " .. err)
end
```

#### `recorder.stop(obj)`
매크로 녹화를 중지하고 결과를 반환합니다.

**반환값:**
- `success` (boolean): 중지 성공 여부
- `macro` (table): 녹화된 매크로 데이터

**매크로 데이터 구조:**
```lua
{
    name = "macro_name",
    createdAt = 1234567890,  -- Unix timestamp
    context = {              -- 녹화 시작 시의 컨텍스트
        kind = "app",
        appName = "Google Chrome",
        bundleId = "com.google.Chrome"
    },
    actions = {
        {
            type = "mouseClick",
            button = "left",
            position = {x = 100, y = 200},
            relativePosition = {dx = 50, dy = 100},
            timestamp = 0.0,
            window = {...}
        },
        -- ... 더 많은 액션
    },
    totalDuration = 1.5      -- 총 시간 (초)
}
```

#### `recorder.pause(obj)`
녹화를 일시정지합니다.

#### `recorder.resume(obj)`
일시정지된 녹화를 재개합니다.

#### `recorder.isRecording(obj)`
현재 녹화 중인지 확인합니다.

**반환값:** `boolean`

---

### 매크로 재생 (playback)

#### `playback.play(obj, macroName, options)`
저장된 매크로를 재생합니다.

**파라미터:**
- `obj`: AutoHotKeys 스푼 객체
- `macroName` (string): 재생할 매크로 이름
- `options` (table, 선택): 재생 옵션

**옵션:**
```lua
{
    repeatCount = 1,        -- 반복 횟수 (0 = 무한)
    speed = 1.0,            -- 재생 속도 (0.5 ~ 2.0)
    onComplete = function() end,  -- 완료 콜백
    onError = function(err) end   -- 에러 콜백
}
```

**예제:**
```lua
-- 기본 재생
spoon.AutoHotKeys.playback.play(spoon.AutoHotKeys, "my_macro")

-- 3번 반복, 2배속
spoon.AutoHotKeys.playback.play(spoon.AutoHotKeys, "my_macro", {
    repeatCount = 3,
    speed = 2.0,
    onComplete = function()
        hs.alert.show("재생 완료!")
    end
})
```

#### `playback.stop(obj)`
현재 재생 중인 매크로를 중지합니다.

#### `playback.isPlaying(obj)`
현재 재생 중인지 확인합니다.

**반환값:** `boolean`

#### `playback.setSpeed(obj, speed)`
재생 속도를 변경합니다.

**파라미터:**
- `speed` (number): 재생 속도 (0.5 ~ 2.0)

---

### 저장소 (storage)

#### `storage.saveMacro(macroName, macroData)`
매크로를 파일에 저장합니다.

**파라미터:**
- `macroName` (string): 매크로 이름
- `macroData` (table): 매크로 데이터

**반환값:** `boolean` - 저장 성공 여부

#### `storage.loadMacro(macroName)`
저장된 매크로를 로드합니다.

**반환값:** `table` - 매크로 데이터 또는 nil

#### `storage.listMacros()`
저장된 모든 매크로 목록을 반환합니다.

**반환값:**
```lua
{
    {name = "macro1", data = {...}},
    {name = "macro2", data = {...}},
    -- ...
}
```

#### `storage.deleteMacro(macroName)`
매크로를 삭제합니다.

**반환값:** `boolean` - 삭제 성공 여부

---

## 저장 위치

매크로와 설정은 다음 위치에 저장됩니다:

```
~/.hammerspoon/autohotkeys/
├── config.json              # 전역 설정
├── app:com.example.json     # 앱별 단축키
├── _macros/                 # 매크로 폴더
│   ├── macro1.json
│   └── macro2.json
```

## 액션 타입

녹화 가능한 액션 타입:

| 타입 | 설명 | 속성 |
|------|------|------|
| `mouseClick` | 마우스 클릭 | `button`, `position`, `relativePosition` |
| `mouseDrag` | 마우스 드래그 | `button`, `startPosition`, `endPosition`, `duration` |
| `mouseMove` | 마우스 이동 | `position` |
| `keyPress` | 키 입력 | `key`, `modifiers` |
| `delay` | 지연 | `milliseconds` |

## 문제 해결

### 매크로가 재생되지 않음
- 녹화 시와 동일한 앱/윈도우에서 재생하고 있는지 확인
- 윈도우 크기가 크게 달라지면 좌표가 맞지 않을 수 있음

### 녹화가 시작되지 않음
- 접근성 권한이 허용되어 있는지 확인 (시스템 환경설정 > 보안 및 개인정보 보호)
- Hammerspoon이 입력 모니터링 권한을 가지고 있는지 확인

### 오버레이가 표시되지 않음
- `obj.overlayCanvas`가 제대로 초기화되었는지 확인
- `overlay.init()`이 호출되었는지 확인

## 라이선스

MIT License

## 크레딧

- Hammerspoon 프로젝트
- Windows AutoHotkey에서 영감을 받음

## 버전

- **0.2.0** - 매크로 녹화/재생 기능 추가
- **0.1.0** - 기본 단축키 기능

## 기여

버그 리포트 및 기능 제안은 이슈로 등록해 주세요.

