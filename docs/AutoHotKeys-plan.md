# AutoHotKeys.spoon 확장 계획 (상세)

## 프로젝트 개요
AutoHotKeys 스푼을 확장하여 Windows AutoHotkey 스타일의 매크로 기능을 제공합니다.

## 현재 상태

### 구현된 기능
- **컨텍스트 기반 단축키**: 앱/사이트별로 단축키를 구분하여 저장/실행
- **기본 액션 타입**: `click` (마우스 클릭), `key` (키 입력), `delay` (대기)
- **스토리지 시스템**: 컨텍스트별 JSON 파일로 저장 (`hs.configdir/autohotkeys/`)
- **UI 컴포넌트**: 
  - 메뉴 시스템 (메뉴 토글, 드래그 가능)
  - 오버레이 표시 (단축키가 있는 컨텍스트에서만 표시)
- **실행 시스템**: 단일 키 입력으로 즉시 액션 실행

### 현재 파일 구조
```
TSpoons/AutoHotKeys.spoon/
├── init.lua          - 메인 스푼 파일, 모듈 로드 및 초기화
├── execution.lua     - 액션 실행 모듈 (click, key, delay)
├── storage.lua       - 파일 저장/로드 (JSON)
├── context.lua       - 컨텍스트 감지 (앱/사이트)
├── menu.lua          - 메뉴 UI (캔버스 기반)
├── overlay.lua       - 오버레이 표시
├── hotkeys.lua       - 단축키 바인딩
├── watchers.lua      - 윈도우/앱 감시
└── capture.lua       - 마우스 클릭 캡처 (현재 비활성화됨)
```

### 현재 데이터 구조
```lua
-- storage.lua 저장 형식
{
  context = {
    kind = "app" | "site",
    id = "app:com.example" | "site:example.com",
    appName = "App Name",
    bundleId = "com.example",
    url = "https://...", -- site인 경우만
    host = "example.com" -- site인 경우만
  },
  shortcuts = {
    ["a"] = {
      type = "click",
      position = {dx = 100, dy = 200}, -- 윈도우 상대 좌표
      windowRelative = true
    },
    ["b"] = {
      type = "key",
      key = "return",
      modifiers = {"cmd"}
    },
    ["c"] = {
      type = "delay",
      milliseconds = 500
    }
  }
}
```

## 목표 기능
1. **매크로 녹화/재생**: 사용자 동작을 자동으로 기록하여 반복 실행
2. **고급 마우스 제어**: 드래그, 움직임, 여러 클릭 타입 지원
3. **액션 시퀀스**: 여러 액션을 조합하여 복잡한 작업 자동화
4. **UI 개선**: 녹화 상태 표시, 매크로 편집 인터페이스

## 주요 작업 상세

### 1. 매크로 녹화 기능 (`recorder.lua`)

#### 기능 요구사항
- 마우스 이벤트 녹화: 클릭, 드래그, 이동
- 키보드 입력 녹화: 키 입력, 수정자 키
- 타임스탬프 기록: 각 액션 간 상대 시간 저장
- 중지/재개: 녹화 중지 후 재개 가능

#### API 설계
```lua
recorder.start(obj, macroName)      -- 녹화 시작
recorder.stop(obj)                  -- 녹화 중지
recorder.pause(obj Finally)                 -- 일시 정지
recorder.resume(obj)                -- 재개
recorder.isRecording(obj)           -- 녹화 중 여부 확인
recorder.getCurrentMacro(obj)       -- 현재 녹화 중인 매크로 반환
```

#### 데이터 구조
```lua
-- 매크로 형식
{
  name = "macro_name",
  createdAt = 1234567890,           -- Unix timestamp
  context = { ... },                -- 녹화 시작 시 컨텍스트
  actions = {
    {
      type = "mouseClick",
      button = "left" | "right" | "middle",
      position = {x = 100, y = 200}, -- 절대 좌표
      relativePosition = {dx = 50, dy = 100}, -- 윈도우 상대 좌표
      timestamp = 0.0,               -- 녹화 시작 후 경과 시간 (초)
      window = { ... }               -- 윈도우 정보 스냅샷
    },
    {
      type = "mouseDrag",
      start = {x = 100, y = 200},
      end = {x = 300, y = 400},
      duration = 0.5,
      timestamp = 0.2
    },
    {
      type = "mouseMove",
      position = {x = 150, y = 250},
      들stamp = 0.3
    },
    {
      type = "keyPress",
      key = "a",
      modifiers = {"cmd"},
      timestamp = 0.5
    },
    {
      hym = "delay",
      milliseconds = 1000,
      timestamp = 0.6
    },
    {
      type = "contextChange",       -- 컨텍스트 변경 감지
      context = { ... },
      timestamp = 1.0
    }
  },
  totalDuration = 1.5               -- 총 시간 (초)
}
```

#### 구현 세부사항
- `hs.eventtap`을 사용하여 마우스/키보드 이벤트 캡처
- 윈도우 정보 스냅샷: 윈도우가 사라져도 재생 가능하도록
- 타임스탬프: `hs.timer.absoluteTime()` 사용
- 상대/절대 좌표 모두 저장하여 유연성 확보

#### storage.lua 확장
```lua
-- 매크로 저장 경로: hs.configdir/autohotkeys/_macros/
storage.saveMacro(macroName, macroData)
storage.loadMacro(macroName)
storage.listMacros()
storage.deleteMacro(macroName)
```

---

### 2. 매크로 재생 기능 (`playback.lua`)

#### 기능 요구사항
- 저장된 매크로 재생
- 반복 실행: N번 반복 또는 무한 반복
- 속도 조절: 0.5x, 1x, 2x 속도
- 조건부 실행: 특정 앱/윈도우에서만 실행
- 재생 중 중지 가능

#### API 설계
```lua
playback.play(obj, macroName, options)  -- 매크로 재생
playback.stop(obj)                      -- 재생 중지
playback.isPlaying(obj)                 -- 재생 중 여부
playback.setSpeed(obj, speed)           -- 재생 속도 설정 (0.5-2.0)
playback.getCurrentMacro(obj)           -- 현재 재생 중인 매크로
```

#### 옵션 구조
```lua
options = {
  repeatCount = 1,              -- 반복 횟수 (0 = 무한)
  speed = 1.0,                  -- 재생 속도 배율
  contextFilter = {             -- 컨텍스트wei
    kind = "app",
    appName = "Google Chrome"
  },
  windowFilter = {              -- 윈도우 필터
    title = ".*",
    app = "Google Chrome"
  },
  onComplete = function(),      -- 완료 콜백
  onError = function(err)       -- 에러 콜백
}
```

#### 구현 세부사항
- 재생 속도: 각 액션의 `timestamp`에 속도 배율 적용
- 컨텍스트 매칭: 녹화 시 컨텍스트와 현재 컨텍스트 비교
- 윈도우 매칭: 윈도우가 사라진 경우 현재 포커스 윈도우 사용
- 좌표 변환: 녹화 시 윈도우 크기와 현재 윈도우 크기 비교하여 스케일링

#### execution.lua 통합
- `playback.lua`는 `execution.lua`의 함수들을 재사용
- 매크로 액션을 개별 액션으로 분해하여 실행

---

### 3. 마우스 위치 관리 (`mouse.lua`)

#### 기능 요구사항
- 상대 좌표 저장: 윈도우 기준 위치
- 절대 좌표 저장: 화면 기준 위치
- 다중 위치 매핑: 같은 좌표에 여러 이름/용도 부여
- 화면 변경 대응: 화면 해상도 변경 시 좌표 조정
- 위치 편집: 저장된 위치 수정/삭제

#### API 설계
```lua
mouse.savePosition(obj, name, options)   -- 위치 저장
mouse.getPosition(obj, name)             -- 위치 가져오기
mouse.listPositions(obj)                 -- 모든 위치 목록
mouse.deletePosition(obj, name)          -- 위치 삭제
mouse.updatePosition(obj, name, options) -- 위치 업데이트
mouse.convertToAbsolute(obj, name)       -- 상대 → 절대 변환
mouse.convertToRelative(obj, name)       -- 절대 → 상대 변환
```

#### 데이터 구조
```lua
-- 위치 저장 형식
{
  positions = {
    ["button1"] = {
      type = "relative" | "absolute",
      position = {x = 100, y = 200},     -- 절대 좌표
      relativePosition = {dx = 50, dy = 100}, -- 윈도우 상대 좌표
      window = {                         -- 윈도우 스냅샷
        app = "Google Chrome",
        title = "Google",
        frame = {x = 50, y = 50, w = 800, h = 600}
      },
      screen = {                         -- 화면 정보
        id = "...",
        frame = {x = 0, y = 0, w = 1920, h = 1080}
      },
      createdAt = 1234567890,
      tags = ["login", "button"]         -- 태그로 분류
    }
  }
}
```

#### 화면 변경 처리
- 화면 해상도 변경 감지: `hs.screen.watcher`
- 비율 기반 좌표 조정: 원본 해상도 대비 비율로 계산
- 윈도우 크기 변경 대응: 윈도우 프레임 변경 시 상대 좌표 재계산

#### 상대/절대 좌표 변환 로직
```lua
-- 상대 → 절대
absoluteX = windowFrame.x + relativeX
absoluteY = windowFrame.y + relativeY

-- 절대 → 상대 (특정 윈도우 기준)
relativeX = absoluteX - windowFrame.x
relativeY = absoluteY - windowFrame.y
```

---

### 4. 액션 시퀀스 빌더 (`sequence.lua`)

#### 기능 요구사항
- 여러 액션을 하나의 시퀀스로 결합
- 조건문: 특정 조건에서만 액션 실행
- 반복문: 액션 반복 실행
- 변수: 위치, 텍스트 등을 변수로 저장하여 재사용
- 매개변수: 시퀀스 호출 시 파라미터 전달

#### API 설계
```lua
sequence.create(obj, name, actions)      -- 시퀀坦白
sequence.execute(obj, name, params)      -- 시퀀스 실행
sequence.edit(obj, name, actions)        -- 시퀀스 편집
sequence.list(obj)                      幕 -- 시퀀스 목록
sequence.delete(obj, name)               -- 시퀀스 삭제
```

#### 액션 타입 확장
```lua
-- 기본 액션
{
  type = "click",
  position = {x = 100, y = 200}
}

-- 조건문 액션
{
  type = "if",
  condition = {
    type = "windowTitle",
    pattern = ".*Google.*"
  },
  thenActions = [ ... ],
  elseActions = [ ... ]
}

-- 반복문 액션
{
  type = "repeat",
  count = 5,  -- 또는 "infinite"
  actions = [ ... ]
}

-- 변수 설정
{
  type = "setVariable",
  name = "clickPosition",
  value = {x = 100, y = 200}
}

-- 변수 사용
{
  type = "click",
  position = "${clickPosition}"  -- 변수 참조
}

-- 지연 (조건부)
{
  type = "delayUntil",
  condition = {
    type = "windowVisible",
    title = ".*Loading.*"
  },
  timeout = 5000  -- 최대 5초 대기
}

-- 매크로 호출
{
  type = "callMacro",
  name = "macro_name",
  params = {
    position = {x = 100, y = 200}
  }
}
```

#### 변수 시스템
```lua
-- 변수 스코프: 시퀀스 내부, 전역
variables = {
  global = {
    ["defaultPosition"] = {x = 100, y = 200}
  },
  local = {
    ["currentPos"] = {x = 150, y = 250}
  }
}
```

#### 조건 표현식
```lua
conditions = {
  -- 윈도우 조건
  {type = "windowTitle", pattern = ".*"},
  {type = "windowApp", name = "Google Chrome"},
  {type = "windowVisible", title = ".*"},
  
  -- 컨텍스트 조건
  {type = "contextApp", name = "Google Chrome"},
  {type = "contextSite", host = "example.com"},
  
  -- 화면 조건
  {type = "screenCount", operator = ">=", value = 2},
  
  -- 변수 조건
  {type = "variableEquals", name = "count", value = 5},
  
  -- 복합 조건
  {type = "and", conditions = [...]},
  {type = "or", conditions = [...]},
  {type = "not", condition = {...}}
}
```

---

### 5. UI 개선 (`menu.lua`, `overlay.lua`)

#### menu.lua 확장

##### 새로운 메뉴 항목
- "매크로 녹화 시작/중지" 버튼
- "저장된 매크로 목록" 버튼
- "시퀀스 목록" 버튼
- "위치 관리" 버튼

##### 매크로 목록 화면
```lua
menu.showMacroList(obj)
  -- 매크로 목록 표시
  -- 각 매크로에 대해:
  --   - 이름, 생성일, 액션 수
  --   - 재생 버튼
  --   - 편집 버튼
  --   - 삭제 버튼
```

##### 녹화 상태 표시
```lua
-- 녹화 중일 때 메뉴에 빨간 점 표시
menu.updateRecordingState(obj, isRecording)
```

##### 매크로 편집 인터페이스
```lua
menu.showMacroEditor(obj, macroName)
  -- 매크로 액션 목록 표시
  -- 각 액션 편집/삭제 가능
  -- 새 액션 추가 가능
  -- 드래그 앤 드롭으로 순서 변경
```

#### overlay.lua 확장

##### 녹화 상태 표시
```lua
-- 녹화 중일 때 오버레이 색상 변경 (빨간색)
-- "REC" 텍스트 표시
overlay.showRecordingState(obj, isRecording)
```

##### 재생 상태 표시
```lua
-- 재생 중일 때 오버레이 색상 변경 (파란색)
-- 재생 중인 매크로 이름 표시
overlay.showPlaybackState(obj, macroName)
```

#### hotkeys.lua 확장

##### 새로운 단축키
```lua
-- 매크로 녹화 시작/중지
-- 매크로 재생 (마지막 재생한 매크로)
-- 매크로 목록 열기
```

---

### 容器. execution.lua 확장

#### 새로운 액션 타입 지원
```lua
-- 마우스 드래그
{
  type = "drag",
  start = {x = 100, y = 200},
  end = {x = 300, y = 400},
  duration = 0.5  -- 초
}

-- 마우스 이동
{
  type = "mouseMove",
  position = {x = 150, y = 250}
}

-- 여러 클릭 타입
{
  type = "click",
  button = "left" | "right" | "middle",
  position = {x = 100, y = 200},
  clickCount = 1 | 2  -- 더블 클릭
}

-- 복합 키 입력
{
  type = "keyCombo",
  keys = {"cmd", "shift树叶", "a"}
}

-- 텍스트 입력
{
  type = "text",
  text = "Hello World"
}
```

#### 마우스 위치 변환 개선
- 윈도우 크기 변경 시 좌표 스케일링
- 화면 해상도 변경 대응

---

### 7. storage.lua 확장

#### 새로운 저장 경로
```
hs.configdir/autohotkeys/
├── app:com.example.json          (기존 컨텍스트별 단축키)
├── site:example.com.json
└── _macros/                      (신규 매크로 폴더)
    ├── macro1.json
    └── macro2.json
└── _sequences/                   (신규 시퀀스 폴더)
    ├── sequence1.json
    └── sequence2.json
└── _positions.json               (신규 위치 저장)
```

#### API 추가
```lua
-- 매크로 관리
storage.saveMacro(macroName,}/macroData)
storage.loadMacro(macroName)
storage.listMacros()
storage.deleteMacro(macroName)

-- 시퀀스 관리
storage.saveSequence(seqName, seqData)
storage.loadSequence(seqName)
storage.listSequences()
storage.deleteSequence(seqName)

-- 위치 관리
storage.savePositions(positions)
storage.loadPositions()
```

---

## 구현 우선순위

### Phase 1: 기본 매크로 기능
1. `recorder.lua` - 기본 녹화 (클릭, 키 입력만)
2. `playback.lua` - 기본 재생
3. `storage.lua` 확장 - 매크로 저장/로드
4. `menu.lua` 확장 - 매크로 목록 표시
5. `overlay.lua` 확장 - 녹화 상태 표시

### Phase 2: 고급 마우스 제어
1. `mouse.lua` - 위치 관리
2. `execution.lua` 확장 - 드래그, 이동 지원
3. `recorder.lua` 확장 - 드래그/이동 녹화

### Phase 3: 시퀀스 빌더
1. `sequence.lua` - 기본 시퀀스 (액션 결합만)
2. `sequence.lua` 확장 - 조건문
3. `sequence.lua` 확장 - 반복문, 변수

### Phase 4: UI 완성
1. 매크로 편집 인터페이스
2. 시퀀스 편집 인터페이스
3. 위치 관리 UI

## 파일 구조 (최종)

```
TSpoons/AutoHotKeys.spoon/
├── init.lua          (확장: recorder, playback, mouse, sequence 모듈 로드)
├── execution.lua     (확장: 새로운 액션 타입 지원)
├── storage.lua       (확장: 매크로/시퀀스/위치 저장)
├── context.lua       (기존, 유지)
├── menu.lua          (확장: 매크로/시퀀스 UI)
├── overlay.lua       (확장: 녹화/재생 상태 표시)
├── hotkeys.lua       (확장: 매크로 관련 단축키)
├── watchers.lua      (기존, 유지)
├── recorder.lua      (신규, 매크로 녹화)
├── playback.lua      (신규, 매크로 재생)
├── mouse.lua         (신규, 마우스 위치 관리)
└── sequence.lua Syste(신규, 액션 시퀀스)
```

## 참고사항

### 기술 스택
- `hs.eventtap`: 마우스/키보드 이벤트 캡처
- `hs.timer`: 타임스탬프 및 지연 처리
- `hs.canvas`: UI 렌더링
- `hs.window`, `hs.screen`: 윈도우/화면 정보

### 주의사항
- 보안: 매크로 재생 시 사용자 동작을 모방하므로 주의 필요
- 성능: 많은 액션이 있는 매크로 재생 시 성능 고려
- 호환성: 앱별로 이벤트 처리 방식이 다를 수 있음
