# AutoHotKeys.spoon 상세 기능 및 구현 문서

## 목차
1. [개요](#개요)
2. [아키텍처](#아키텍처)
3. [핵심 기능](#핵심-기능)
4. [모듈별 상세 설명](#모듈별-상세-설명)
5. [사용 케이스](#사용-케이스)
6. [데이터 구조](#데이터-구조)
7. [구현 결과 검토](#구현-결과-검토)
8. [개선 사항 및 향후 계획](#개선-사항-및-향후-계획)

---

## 개요

### 목적
AutoHotKeys.spoon은 Windows AutoHotkey 스타일의 매크로 및 단축키 자동화 기능을 macOS에서 제공하는 Hammerspoon Spoon입니다. 앱별/사이트별 컨텍스트를 감지하여 각각 다른 단축키를 설정하고 실행할 수 있으며, 마우스/키보드 동작을 녹화하여 반복 실행하는 매크로 기능을 제공합니다.

### 버전 정보
- **현재 버전**: 0.2.0
- **작성자**: zer0wiz<zer0wiz9@gmail.com>
- **라이선스**: MIT

### 주요 특징
- 컨텍스트 기반 단축키 (앱/사이트별)
- 매크로 녹화 및 재생
- 윈도우 상대 좌표 지원
- 시각적 피드백 (오버레이, 미리보기)
- JSON 기반 설정 관리

---

## 아키텍처

### 모듈 구조
AutoHotKeys.spoon은 다음과 같은 모듈로 구성되어 있습니다:

```
AutoHotKeys.spoon/
├── init.lua              # 메인 모듈 (초기화 및 통합)
├── storage.lua           # 데이터 저장/로드
├── execution.lua         # 단축키 실행 엔진
├── watchers.lua          # 앱/윈도우 변경 감시
├── menu.lua              # 메뉴 UI
├── overlay.lua           # 상태 오버레이
├── hotkeys.lua           # 전역 단축키 바인딩
├── recorder.lua          # 매크로 녹화
├── playback.lua          # 매크로 재생
├── shortcut_preview.lua  # 단축키 미리보기
├── mouse.lua             # 마우스 위치 관리
└── assets/
    └── menu.json         # 메뉴 UI 설정

modules/
└── contextInfo.lua       # 컨텍스트 감지 (앱/사이트)
```

### File 구조

```
Zer0Hammer/ (root)
├──TSpoons/ (개발중인 Spoons)
│  └── AutoHotKeys.spoon/
│      └── init.lua
│          ├── storage.lua (독립)
│          ├── execution.lua (독립)
│          ├── watchers.lua
│          │   ├── modules.contextInfo
│          │   ├── storage.lua
│          │   └── execution.lua
│          ├── menu.lua
│          │   ├── modules.contextInfo
│          │   ├── storage.lua
│          │   └── shortcut_preview.lua
│          ├── overlay.lua
│          │   ├── modules.contextInfo
│          │   ├── storage.lua
│          │   ├── recorder.lua
│          │   └── playback.lua
│          ├── hotkeys.lua
│          │   ├── menu.lua
│          │   ├── recorder.lua
│          │   └── storage.lua
│          ├── recorder.lua (독립)
│          ├── playback.lua
│          │   ├── storage.lua
│          │   └── execution.lua
│          ├── shortcut_preview.lua
│          │   ├── modules.contextInfo
│          │   └── storage.lua
│          └── mouse.lua
│             └── storage.lua
└── modules/ (Hammerspoon 전역 참조 모듈)
    ├── contextInfo.lua     # 컨텍스트 감지 (앱/사이트)
    └── UIObjects/
        ├── elements/
        │   ├── divider.lua
        │   ├── layer.lua
        │   ├── rectangle.lua
        │   ├── text.lua
        │   ├── title.lua
        │   └── toggle_button.lua
        └── init.lua
```

### 초기화 흐름
1. `init()` 호출 → `start()` 자동 실행
2. `storage.init()` - 저장소 디렉터리 생성
3. `watchers.start()` - 앱/윈도우 감시 시작
4. `overlay.init()` - 오버레이 생성
5. `hotkeys.bind()` - 전역 단축키 바인딩

---

## 핵심 기능

### 1. 컨텍스트 감지 (Context Detection)

#### 기능 설명
현재 활성화된 앱 또는 브라우저의 특정 사이트를 감지하여 고유한 컨텍스트 ID를 생성합니다.

#### 작동 방식
- **앱 컨텍스트**: `app:{bundleId}` 형식 (예: `app:com.apple.finder`)
- **사이트 컨텍스트**: `web:{host}` 형식 (예: `web:github.com`)
- 브라우저 앱의 경우 AppleScript를 사용하여 현재 탭의 URL을 가져옴
- URL에서 호스트를 추출하여 사이트 컨텍스트 생성

#### 지원 브라우저
- Safari
- Google Chrome
- Brave Browser
- Microsoft Edge
- Vivaldi
- Opera
- Arc

#### 구현 위치
- `modules/contextInfo.lua`: `context.current()` 함수

#### 사용 케이스
- 앱별로 다른 단축키 설정
- 특정 웹사이트에서만 동작하는 단축키
- 컨텍스트별 매크로 저장

---

### 2. 단축키 설정 및 실행 (Shortcut Management)

#### 기능 설명
앱/사이트별로 키보드 단일 키(a-z, 0-9)를 눌러 특정 위치를 클릭하거나 다른 액션을 실행할 수 있습니다.

#### 작동 방식
1. **단축키 설정**:
   - 메뉴에서 "단축키" 버튼 클릭
   - 단축키 미리보기 레이어 표시
   - Ctrl+클릭으로 위치 선택
   - 키 입력 대기 모달에서 단축키 입력
   - 저장 (앱별 설정 파일에 저장)

2. **단축키 실행**:
   - 앱 활성화 시 컨텍스트 감지
   - 해당 앱의 enabled 상태 확인
   - 활성 컨텍스트 목록(`activeContexts`) 확인
   - 키 입력 감지 (eventtap)
   - 매칭되는 단축키 실행

#### 액션 타입
- `click`: 마우스 클릭 (left/right/middle, 클릭 횟수)
- `drag`: 마우스 드래그 (시작/종료 위치, 버튼, 지속 시간)
- `mouseMove`: 마우스 이동
- `key`: 키 입력 (수정자 키 포함)
- `keyCombo`: 복합 키 입력
- `text`: 텍스트 입력
- `delay`: 지연

#### 좌표 시스템
- **윈도우 상대 좌표**: `{dx, dy}` 형식으로 윈도우 프레임 기준 상대 위치 저장
- 윈도우 크기 변경 시 자동 스케일링
- 절대 좌표도 지원 (하위 호환성)

#### 구현 위치
- `execution.lua`: 단축키 실행 로직
- `shortcut_preview.lua`: 단축키 설정 UI
- `storage.lua`: 앱별 설정 저장/로드

#### 활성화 조건
단축키가 실행되려면 다음 조건을 모두 만족해야 합니다:
1. 앱이 제외 목록에 없음
2. 앱의 `enabled` 상태가 `true`
3. 컨텍스트가 `activeContexts`에 등록됨 (메뉴에서 토글)

---

### 3. 매크로 녹화 및 재생 (Macro Recording & Playback)

#### 기능 설명
마우스 클릭, 드래그, 키보드 입력 등의 동작을 녹화하여 나중에 반복 실행할 수 있습니다.

#### 녹화 기능

**시작/중지**:
- 단축키: `Ctrl+Cmd+R`
- 녹화 시작 시 오버레이가 빨간색 "REC"로 변경
- 녹화 중지 시 매크로 이름 입력 다이얼로그 표시

**녹화되는 이벤트**:
- 마우스 클릭 (left/right/middle)
- 마우스 드래그
- 마우스 이동 (드래그가 아닐 때)
- 키보드 입력 (키 코드, 수정자 키 포함)

**타임스탬프**:
- 각 액션에 상대 타임스탬프 저장 (녹화 시작 기준)
- 일시정지 시간은 제외

**윈도우 정보**:
- 각 액션에 윈도우 정보 저장 (앱 이름, bundleId, 제목, 프레임)
- 상대 좌표 계산 및 저장

#### 재생 기능

**재생 옵션**:
- `repeatCount`: 반복 횟수 (0 = 무한 반복)
- `speed`: 재생 속도 (0.5 ~ 2.0)
- `onComplete`: 완료 콜백
- `onError`: 에러 콜백

**좌표 변환**:
- 녹화 시 윈도우 크기와 현재 윈도우 크기 비교
- 비율에 따라 좌표 자동 스케일링
- 상대 좌표 우선 사용

**재생 중지**:
- `playback.stop()` 호출
- 또는 재생 완료 시 자동 중지

#### 구현 위치
- `recorder.lua`: 녹화 로직
- `playback.lua`: 재생 로직
- `storage.lua`: 매크로 저장/로드

#### 매크로 데이터 구조
```lua
{
    name = "macro_name",
    createdAt = 1234567890,  -- Unix timestamp
    context = {
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
            window = {
                app = "Google Chrome",
                bundleId = "com.google.Chrome",
                title = "Window Title",
                frame = {x = 0, y = 0, w = 1920, h = 1080}
            }
        },
        -- ... 더 많은 액션
    },
    totalDuration = 1.5  -- 총 시간 (초)
}
```

---

### 4. 메뉴 UI (Menu Interface)

#### 기능 설명
현재 앱의 상태를 확인하고 단축키/매크로를 관리할 수 있는 팝업 메뉴를 제공합니다.

#### 메뉴 구성
1. **앱 이름 표시**: 현재 활성 앱 이름
2. **Enabled 토글**: 앱별 단축키 활성화/비활성화
3. **단축키 버튼**: 단축키 설정 화면으로 이동
4. **매크로 버튼**: 매크로 목록 화면으로 이동
5. **오버레이 토글**: 상태 오버레이 표시/숨김

#### 메뉴 위치
- 기본: 마우스 커서 위치
- 드래그 가능: `Ctrl+Cmd+드래그`로 위치 이동
- 위치 저장: 드래그 종료 시 자동 저장

#### 메뉴 닫기 조건
- 키 입력 시 (모든 키)
- 다른 윈도우로 포커스 이동 시
- ESC 키 (단축키 미리보기에서)

#### JSON 기반 UI 구성
- `assets/menu.json`: 메뉴 요소 정의
- 플레이스홀더 치환: `{{변수명}}` 형식
- 수식 계산 지원: `{{w - 80}}` 등

#### 구현 위치
- `menu.lua`: 메뉴 생성 및 이벤트 처리
- `assets/menu.json`: UI 정의

---

### 5. 오버레이 (Status Overlay)

#### 기능 설명
- overlay는 ctx 기준의 단축키 활성화 상태 표시용 작은 배지입니다
- 현재 활성화된 앱의 윈도우 우측 상단에 작은 오버레이를 표시하여 상태를 시각적으로 표시합니다
- 단축키 활성화 상태 표시 (작은 "AK" 배지)
- 녹화/재생 상태 표시
- menu에서 단축키 추가 시 shortcut_preview와 함께 사용됨
- shortcut_preview: 단축키 위치 확인 및 추가 시 사용 (단축키 목록의 각 항목 표시)

#### 표시 조건
다음 조건 중 하나를 만족해야 표시됩니다:
1. 활성 컨텍스트가 있고 단축키가 있음 (해당 ctx가 포커스 상태일 때 단축키 사용 가능)
2. 매크로 녹화 중
3. 매크로 재생 중
4. 오버레이 활성화됨 (`config.overlay.enabled`)

#### 상태 표시
- **기본**: 검은색 배경, "AK" 텍스트 (단축키 활성화 상태 표시)
- **녹화 중**: 빨간색 배경, "REC" 텍스트
- **재생 중**: 파란색 배경, 매크로 이름 (최대 3자)

#### 오버레이 클릭
- 오버레이 클릭 시 메뉴 토글

#### 구현 위치
- `overlay.lua`: 오버레이 생성 및 업데이트 (ctx 기준의 단축키 활성화 상태 표시용 작은 배지)

---

### 6. 단축키 미리보기 (Shortcut Preview)

#### 기능 설명
- shortcut_preview는 ctx 기준의 단축키 위치 확인용 overlay 객체입니다
- menu에서 단축키별 마우스 위치 확인 및 추가시에 사용됩니다
- 오버레이에 단축키 목록의 각 항목이 표시됩니다
- 현재 앱에 설정된 단축키를 시각적으로 표시하고 새로운 단축키를 추가할 수 있는 레이어를 제공합니다

#### 표시 내용
- 그레이 오버레이 (윈도우 전체)
- 각 단축키 위치에 원형 마커
- 단축키 키 표시 (원 중앙)
- 오버레이에 단축키 목록의 각 항목이 표시됨

#### 단축키 추가
1. menu에서 "단축키" 버튼 클릭하여 shortcut_preview 표시
2. `Ctrl+클릭`으로 위치 선택
3. 키 입력 대기 모달 표시
4. 단축키 입력 (수정자 키 포함 가능)
5. 저장 및 미리보기 업데이트

#### 닫기
- ESC 키
- 다른 윈도우로 포커스 이동

#### 구현 위치
- `shortcut_preview.lua`: 미리보기 레이어 생성 및 이벤트 처리
- `menu.lua`: menu에서 "단축키" 버튼 클릭 시 `shortcut_preview.show(obj, ctx)` 호출

---

### 7. 데이터 저장소 (Storage)

#### 단축키 저장 방식
- 각 ctx별로 단축키는 파일(`/autohotkeys/{ctx.id}.json`)로 저장됩니다
- 예: `ctx.id = "app:com.google.Chrome"` → `/autohotkeys/app_com.google.Chrome.json`
- 해당 ctx가 포커스 상태일 때 단축키 사용 가능
- `sanitizeFilename()` 함수로 특수 문자(`:`)를 언더스코어(`_`)로 변환하여 파일명 생성

#### 저장 위치
```
~/.hammerspoon/autohotkeys/
├── config.json              # 전역 설정
├── app_{bundleId}.json      # 앱별 단축키 설정 (ctx.id 기반)
├── browser_{host}.json      # 브라우저별 단축키 설정 (ctx.id 기반)
├── _macros/                  # 매크로 폴더
│   ├── macro1.json
│   └── macro2.json
└── _positions.json           # 저장된 위치 (mouse.lua)
```

**참고**: 파일명은 `sanitizeFilename()` 함수에 의해 변환되므로 `ctx.id`의 `:`가 `_`로 변경됩니다.
- `app:com.google.Chrome` → `app_com.google.Chrome.json`
- `browser:example.com` → `browser_example.com.json`

#### 전역 설정 (config.json)
```json
{
    "shortcutPreview": {
        "circle": {
            "radius": 20,
            "strokeWidth": 2,
            "strokeColor": "#FF5733",
            "fillColor": "#FF5733",
            "fillAlpha": 0.7
        },
        "text": {
            "size": 14,
            "color": "#FFFFFF",
            "font": "Arial Bold"
        },
        "overlay": {
            "color": "#000000",
            "alpha": 0.3
        }
    },
    "menu": {
        "position": {
            "x": null,
            "y": null
        },
        "saved": false
    },
    "overlay": {
        "enabled": false
    },
    "excludedApps": [
        "com.hammerspoon.Hammerspoon"
    ]
}
```

#### 앱별 설정 (app:{bundleId}.json)
```json
{
    "enabled": true,
    "appName": "Google Chrome",
    "bundleId": "com.google.Chrome",
    "shortcuts": {
        "a": {
            "type": "click",
            "position": {
                "dx": 100,
                "dy": 200
            },
            "windowRelative": true
        }
    }
}
```

#### 매크로 파일 (_macros/{name}.json)
매크로 데이터 구조 참조 (위의 매크로 데이터 구조 섹션)

#### 구현 위치
- `storage.lua`: 모든 저장/로드 로직

---

### 8. 감시자 (Watchers)

#### 기능 설명
앱 활성화 및 윈도우 포커스 변경을 감지하여 컨텍스트를 업데이트하고 단축키를 활성화/비활성화합니다.

#### 감시 이벤트
1. **윈도우 포커스 변경**: `hs.window.filter.windowFocused`
2. **앱 활성화**: `hs.application.watcher.activated`

#### 처리 흐름
1. 컨텍스트 감지 (`context.current()`)
2. 제외된 앱 확인
3. 활성 컨텍스트 확인 (`activeContexts`)
4. 앱별 설정 로드
5. 단축키 활성화/비활성화
6. 오버레이 업데이트

#### 구현 위치
- `watchers.lua`: 감시자 설정 및 이벤트 처리

---

## 모듈별 상세 설명

### init.lua
**역할**: 메인 모듈, 모든 하위 모듈을 로드하고 통합

**주요 함수**:
- `start()`: 스푼 시작 (저장소 초기화, 감시자 시작, 오버레이 생성, 단축키 바인딩)
- `stop()`: 스푼 중지 (모든 리소스 정리)
- `menuToggle()`: 메뉴 토글

**상태 관리**:
- `activeContexts`: 토글된 컨텍스트 목록 (컨텍스트 ID를 키로 사용)
- `menuShowing`: 메뉴 표시 상태
- `shortcuts`: 컨텍스트별 단축키 캐시

---

### modules/contextInfo.lua
**역할**: 현재 컨텍스트 감지

**주요 함수**:
- `context.current()`: 현재 컨텍스트 반환

**반환 구조**:
```lua
{
    kind = "app" | "site" | "unknown" | "none",
    id = "app:{bundleId}" | "site:{host}",
    appName = "App Name",
    bundleId = "com.example.app",
    title = "Window Title",
    url = "https://example.com/page",  -- 사이트 컨텍스트만
    host = "example.com",                -- 사이트 컨텍스트만
    winFrame = {x, y, w, h}
}
```

**브라우저 URL 조회**:
- Safari: AppleScript 직접 사용
- Chromium 계열: AppleScript로 활성 탭 URL 가져오기

---

### storage.lua
**역할**: 모든 데이터 저장/로드

**단축키 저장 방식**:
- 각 ctx별로 단축키는 파일(`/autohotkeys/{ctx.id}.json`)로 저장
- 예: `ctx.id = "app:com.google.Chrome"` → `/autohotkeys/app_com.google.Chrome.json`
- 해당 ctx가 포커스 상태일 때 단축키 사용 가능
- `sanitizeFilename()` 함수로 특수 문자(`:`)를 언더스코어(`_`)로 변환하여 파일명 생성

**주요 함수**:
- `init()`: 저장소 디렉터리 생성
- `load(contextId)`: 컨텍스트별 단축키 로드 (`ctx.id`를 기준으로 저장된 단축키 목록을 로드)
- `save(context, shortcuts)`: 컨텍스트별 단축키 저장 (`ctx`별로 단축키 목록을 파일로 저장)
- `pathForContext(contextId)`: 컨텍스트별 저장 경로 생성 (각 ctx별로 단축키는 파일로 저장)
- `loadConfig()`: 전역 설정 로드
- `saveConfig(config)`: 전역 설정 저장
- `loadAppConfig(appId)`: 앱별 설정 로드
- `saveAppConfig(appId, config)`: 앱별 설정 저장
- `saveMacro(name, data)`: 매크로 저장
- `loadMacro(name)`: 매크로 로드
- `listMacros()`: 매크로 목록 반환
- `deleteMacro(name)`: 매크로 삭제
- `toggleAppEnabled(appId, appName, bundleId)`: 앱 활성화 상태 토글

**파일명 안전 처리**:
- 특수 문자를 언더스코어로 치환 (`sanitizeFilename`)

---

### execution.lua
**역할**: 단축키 실행 엔진

**주요 함수**:
- `perform(obj, ctx, key)`: 컨텍스트 기반 단축키 실행 (하위 호환성)
- `handleShortcutKey(obj, key)`: 앱별 단축키 실행
- `enableShortcuts(obj, appId, shortcuts)`: 단축키 활성화
- `disableShortcuts(obj)`: 단축키 비활성화
- `registerKeyTap(obj)`: 키 입력 감지 등록

**지원 액션 타입**:
- `click`: 마우스 클릭
- `drag`: 마우스 드래그
- `mouseMove`: 마우스 이동
- `delay`: 지연
- `key`: 키 입력
- `keyCombo`: 복합 키 입력
- `text`: 텍스트 입력

**키 입력 필터링**:
- 수정자 키만 누른 경우 무시
- 메뉴 표시 중 무시
- 미리보기 레이어 표시 중 무시

---

### watchers.lua
**역할**: 앱/윈도우 변경 감시

**주요 함수**:
- `start(obj)`: 감시자 시작
- `stop(obj)`: 감시자 정지
- `updateAppShortcuts(obj)`: 앱별 단축키 업데이트

**감시 이벤트**:
- 윈도우 포커스 변경
- 앱 활성화

**처리 로직**:
1. 제외된 앱 확인
2. 활성 컨텍스트 확인
3. 단축키 활성화/비활성화
4. 오버레이 업데이트

---

### menu.lua
**역할**: 메뉴 UI 생성 및 이벤트 처리

**주요 함수**:
- `toggle(obj)`: 메뉴 토글
- `show(obj)`: 메뉴 표시
- `hide(obj)`: 메뉴 숨김
- `showMacroList(obj)`: 매크로 목록 표시
- `create(menuName)`: 메뉴 생성 (UIObjects 기반)
- `title(text, options)`: 메뉴 타이틀 설정

**이벤트 처리**:
- Enabled 토글 클릭
- 단축키 버튼 클릭
- 매크로 버튼 클릭
- 오버레이 토글 클릭
- 드래그 모드 (`Ctrl+Cmd+드래그`)

**위치 계산**:
- 마우스 위치 기준
- 화면 경계 체크 및 자동 조정

**JSON UI 렌더링**:
- 플레이스홀더 치환 (`{{변수명}}`)
- 수식 계산 (`{{w - 80}}`)
- 타입 변환 (문자열 → 숫자)

---

### overlay.lua
**역할**: ctx 기준의 단축키 활성화 상태 표시용 작은 배지

**개요**:
- overlay는 ctx 기준의 단축키 활성화 상태를 표시하는 작은 배지입니다
- 단축키 활성화 상태 표시 (작은 "AK" 배지)
- 녹화/재생 상태 표시
- menu에서 단축키 추가 시 shortcut_preview와 함께 사용됨
- shortcut_preview: 단축키 위치 확인 및 추가 시 사용 (단축키 목록의 각 항목 표시)

**주요 함수**:
- `init(obj)`: 오버레이 생성 (ctx 기준의 단축키 활성화 상태 표시용 작은 배지 생성)
- `update(obj)`: 오버레이 업데이트 (ctx 기준으로 단축키 활성화 상태를 확인하고 overlay 표시 여부 결정, 해당 ctx가 포커스 상태일 때 단축키 사용 가능 여부를 표시)
- `stop(obj)`: 오버레이 정지

**표시 조건**:
- 오버레이 활성화됨 (`config.overlay.enabled`)
- 활성 컨텍스트가 있거나 녹화/재생 중
- 단축키가 있거나 녹화/재생 중

**위치**:
- 현재 활성 윈도우 우측 상단
- 윈도우 프레임 기준 상대 위치

---

### hotkeys.lua
**역할**: 전역 단축키 바인딩

**주요 함수**:
- `bind(obj)`: 단축키 바인딩
- `unbind(obj)`: 단축키 해제

**전역 단축키**:
- `Ctrl+Cmd+K`: 메뉴 토글
- `Ctrl+Cmd+R`: 매크로 녹화 시작/중지
- `Ctrl+Cmd+M`: 매크로 목록 표시

---

### recorder.lua
**역할**: 매크로 녹화

**주요 함수**:
- `start(obj, macroName)`: 녹화 시작
- `stop(obj)`: 녹화 중지
- `pause(obj)`: 녹화 일시정지
- `resume(obj)`: 녹화 재개
- `isRecording(obj)`: 녹화 중 여부 확인
- `getCurrentMacro(obj)`: 현재 녹화 중인 매크로 반환

**이벤트 캡처**:
- 마우스 클릭 (left/right/middle)
- 마우스 드래그
- 마우스 이동
- 키보드 입력

**타임스탬프 관리**:
- 녹화 시작 시간 기준 상대 타임스탬프
- 일시정지 시간 제외

**윈도우 정보 저장**:
- 각 액션에 윈도우 정보 저장
- 상대 좌표 계산

---

### playback.lua
**역할**: 매크로 재생

**주요 함수**:
- `play(obj, macroName, options)`: 매크로 재생
- `stop(obj)`: 재생 중지
- `isPlaying(obj)`: 재생 중 여부 확인
- `setSpeed(obj, speed)`: 재생 속도 변경
- `getCurrentMacro(obj)`: 현재 재생 중인 매크로 반환
- `playNextAction(obj)`: 다음 액션 재생

**재생 옵션**:
- `repeatCount`: 반복 횟수
- `speed`: 재생 속도
- `onComplete`: 완료 콜백
- `onError`: 에러 콜백

**좌표 변환**:
- 녹화 시 윈도우 크기와 현재 윈도우 크기 비교
- 비율에 따라 좌표 스케일링
- 상대 좌표 우선 사용

**타이밍**:
- 액션 간 지연 시간 계산 (타임스탬프 기반)
- 재생 속도 적용

---

### shortcut_preview.lua
**역할**: ctx 기준의 단축키 위치 확인용 overlay 객체

**개요**:
- shortcut_preview는 ctx 기준의 단축키 위치 확인용 overlay 객체입니다
- menu에서 단축키별 마우스 위치 확인 및 추가시에 사용됩니다
- 오버레이에 단축키 목록의 각 항목이 표시됩니다
- 각 단축키의 위치에 원과 키 텍스트를 표시합니다

**주요 함수**:
- `show(obj, ctx)`: 미리보기 레이어 표시 (ctx 기준의 단축키 목록을 오버레이에 표시, menu에서 단축키 추가 시 호출되어 단축키별 마우스 위치 확인 및 추가에 사용됨)
- `hide(obj)`: 미리보기 레이어 숨김
- `enableAddMode(obj)`: 단축키 추가 모드 활성화

**미리보기 표시**:
- 윈도우 전체에 그레이 오버레이
- 각 단축키 위치에 원형 마커
- 단축키 키 표시
- 오버레이에 단축키 목록의 각 항목이 표시됨

**단축키 추가**:
- `Ctrl+클릭`으로 위치 선택
- 키 입력 대기 모달 표시
- 단축키 입력 및 저장

**이벤트 처리**:
- ESC 키로 닫기
- 포커스 아웃 감지

**menu.lua와의 연동**:
- menu에서 "단축키" 버튼 클릭 시 `shortcut_preview.show(obj, ctx)` 호출
- ctx 기준의 단축키 위치 확인용 overlay (shortcut_preview) 표시
- menu에서 단축키별 마우스 위치 확인 및 추가시에 사용

---

### mouse.lua
**역할**: 마우스 위치 관리

**주요 함수**:
- `savePosition(obj, name, options)`: 위치 저장
- `getPosition(obj, name)`: 위치 가져오기
- `listPositions(obj)`: 위치 목록
- `deletePosition(obj, name)`: 위치 삭제
- `updatePosition(obj, name, options)`: 위치 업데이트
- `convertToAbsolute(obj, name)`: 상대 → 절대 좌표 변환
- `convertToRelative(obj, name, window)`: 절대 → 상대 좌표 변환
- `findByTag(obj, tag)`: 태그로 위치 검색

**좌표 시스템**:
- 절대 좌표: 화면 기준
- 상대 좌표: 윈도우 프레임 기준
- 화면 해상도 변경 시 자동 스케일링

---

## 사용 케이스

### 케이스 1: 앱별 단축키 설정
**시나리오**: Chrome에서 자주 사용하는 버튼을 키보드로 빠르게 클릭하고 싶음

**절차**:
1. Chrome 실행
2. `Ctrl+Cmd+K`로 메뉴 열기
3. Enabled 토글 ON
4. "단축키" 버튼 클릭
5. 미리보기 레이어에서 `Ctrl+클릭`으로 버튼 위치 선택
6. 키 입력 (예: `a`)
7. 저장 완료

**결과**: Chrome에서 `a` 키를 누르면 해당 버튼이 클릭됨

---

### 케이스 2: 사이트별 단축키
**시나리오**: GitHub에서 특정 버튼을 빠르게 클릭하고 싶음

**절차**:
1. Chrome에서 GitHub 열기
2. `Ctrl+Cmd+K`로 메뉴 열기
3. Enabled 토글 ON
4. "단축키" 버튼 클릭
5. `Ctrl+클릭`으로 버튼 위치 선택
6. 키 입력 (예: `g`)
7. 저장 완료

**결과**: GitHub 사이트에서 `g` 키를 누르면 해당 버튼이 클릭됨 (다른 사이트에서는 동작하지 않음)

---

### 케이스 3: 매크로 녹화 및 재생
**시나리오**: 반복적인 작업을 자동화하고 싶음

**절차**:
1. 작업할 앱 실행
2. `Ctrl+Cmd+R`로 녹화 시작
3. 원하는 동작 수행 (클릭, 드래그, 키 입력 등)
4. `Ctrl+Cmd+R`로 녹화 중지
5. 매크로 이름 입력 (예: "daily_task")
6. 저장 완료
7. `Ctrl+Cmd+M`로 매크로 목록 열기
8. 재생 버튼 클릭

**결과**: 녹화한 동작이 자동으로 반복 실행됨

---

### 케이스 4: 여러 앱에서 다른 단축키 사용
**시나리오**: Chrome에서는 `a`로 버튼 A 클릭, VS Code에서는 `a`로 다른 동작

**절차**:
1. Chrome에서 단축키 설정 (키: `a`, 위치: 버튼 A)
2. VS Code에서 단축키 설정 (키: `a`, 위치: 다른 버튼)
3. 각 앱에서 Enabled 토글 ON

**결과**: 
- Chrome 활성화 시 `a` → 버튼 A 클릭
- VS Code 활성화 시 `a` → 다른 버튼 클릭

---

## 데이터 구조

### 컨텍스트 정보
```lua
{
    kind = "app" | "site" | "unknown" | "none",
    id = "app:{bundleId}" | "site:{host}",
    appName = "App Name",
    bundleId = "com.example.app",
    title = "Window Title",
    url = "https://example.com/page",  -- 사이트만
    host = "example.com",                -- 사이트만
    winFrame = {x = 0, y = 0, w = 1920, h = 1080}
}
```

### 단축키 액션
```lua
{
    type = "click" | "drag" | "mouseMove" | "key" | "keyCombo" | "text" | "delay",
    -- click
    button = "left" | "right" | "middle",
    clickCount = 1,
    position = {dx = 100, dy = 200},  -- 윈도우 상대 좌표
    -- drag
    startPosition = {dx = 100, dy = 200},
    endPosition = {dx = 300, dy = 400},
    duration = 0.1,
    -- key
    key = "a",
    modifiers = {"cmd", "shift"},
    -- keyCombo
    keys = {"cmd", "shift", "a"},
    -- text
    text = "Hello World",
    -- delay
    milliseconds = 100
}
```

### 매크로 액션
```lua
{
    type = "mouseClick" | "mouseDrag" | "mouseMove" | "keyPress",
    button = "left" | "right" | "middle",
    position = {x = 100, y = 200},  -- 절대 좌표
    relativePosition = {dx = 50, dy = 100},  -- 윈도우 상대 좌표
    timestamp = 0.5,  -- 녹화 시작 기준 상대 시간 (초)
    window = {
        app = "App Name",
        bundleId = "com.example.app",
        title = "Window Title",
        frame = {x = 0, y = 0, w = 1920, h = 1080}
    }
}
```

---

## 구현 결과 검토

### 구현된 기능 ✅

1. **컨텍스트 감지**
   - ✅ 앱 컨텍스트 감지
   - ✅ 사이트 컨텍스트 감지 (브라우저 URL 조회)
   - ✅ 컨텍스트 ID 생성

2. **단축키 관리**
   - ✅ 단축키 설정 (미리보기 레이어)
   - ✅ 단축키 실행 (키 입력 감지)
   - ✅ 앱별 단축키 저장/로드
   - ✅ 활성화/비활성화 토글
   - ✅ 윈도우 상대 좌표 지원

3. **매크로 기능**
   - ✅ 매크로 녹화 (마우스/키보드)
   - ✅ 매크로 재생 (반복, 속도 조절)
   - ✅ 매크로 저장/로드
   - ✅ 매크로 목록 표시
   - ✅ 매크로 삭제

4. **UI**
   - ✅ 메뉴 UI (JSON 기반)
   - ✅ 오버레이 표시
   - ✅ 단축키 미리보기
   - ✅ 매크로 목록 UI

5. **데이터 관리**
   - ✅ JSON 기반 저장소
   - ✅ 앱별 설정 관리
   - ✅ 전역 설정 관리
   - ✅ 매크로 파일 관리

### 미구현/불완전한 기능 ⚠️

1. **UIObjects 기반 메뉴**
   - ⚠️ `menu.create()` 함수는 있지만 실제로 사용되지 않음
   - ⚠️ JSON 기반 렌더링만 사용 중
   - ⚠️ UIObjects 레이어 시스템과 통합 필요

2. **매크로 편집**
   - ❌ 매크로 수정 기능 없음
   - ❌ 매크로 이름 변경 기능 없음
   - ❌ 매크로 액션 편집 기능 없음

3. **단축키 편집**
   - ⚠️ 단축키 삭제 기능 없음 (미리보기에서)
   - ⚠️ 단축키 위치 변경 기능 없음
   - ⚠️ 단축키 키 변경 기능 없음

4. **에러 처리**
   - ⚠️ 파일 읽기/쓰기 실패 시 에러 처리 부족
   - ⚠️ AppleScript 실행 실패 시 에러 처리 부족
   - ⚠️ 매크로 재생 실패 시 상세 에러 메시지 부족

5. **성능 최적화**
   - ⚠️ 단축키 캐시는 있지만 최적화 여지 있음
   - ⚠️ 오버레이 업데이트 빈도 조절 필요

6. **접근성**
   - ⚠️ 키보드만으로 모든 기능 사용 불가
   - ⚠️ 스크린 리더 지원 없음

### 버그 및 이슈 ⚠️

1. **메뉴 위치 저장**
   - ⚠️ 드래그 후 위치 저장은 되지만, 다음 메뉴 표시 시 저장된 위치를 사용하지 않음
   - ⚠️ `menu.show()`에서 저장된 위치를 로드하지 않음

2. **컨텍스트 활성화**
   - ⚠️ `activeContexts`에 추가는 되지만, 메뉴 닫을 때 제거되는 로직이 있음 (`menu.hide()`)
   - ⚠️ 앱 전환 시 활성 컨텍스트 유지 여부 불명확

3. **매크로 재생**
   - ⚠️ 윈도우 크기가 크게 달라지면 좌표가 맞지 않을 수 있음
   - ⚠️ 윈도우가 없거나 다른 위치에 있으면 재생 실패 가능

4. **단축키 미리보기**
   - ⚠️ 단축키 삭제 기능 없음
   - ⚠️ 단축키 수정 기능 없음

---

## 개선 사항 및 향후 계획

### 단기 개선 사항

1. **메뉴 위치 저장/로드**
   - 저장된 위치를 다음 메뉴 표시 시 사용
   - `menu.show()`에서 `config.menu.position` 확인

2. **단축키 편집/삭제**
   - 미리보기 레이어에서 단축키 삭제 기능 추가
   - 단축키 수정 기능 추가

3. **에러 처리 강화**
   - 파일 I/O 에러 처리
   - AppleScript 실행 에러 처리
   - 매크로 재생 실패 시 상세 에러 메시지

4. **매크로 편집**
   - 매크로 이름 변경
   - 매크로 액션 편집 (추가/삭제/수정)

### 중기 개선 사항

1. **UIObjects 통합**
   - JSON 기반 UI를 UIObjects로 완전 전환
   - 레이어 시스템 활용

2. **성능 최적화**
   - 단축키 캐시 최적화
   - 오버레이 업데이트 빈도 조절
   - 이벤트 탭 최적화

3. **접근성 개선**
   - 키보드 네비게이션 지원
   - 스크린 리더 지원

### 장기 개선 사항

1. **고급 매크로 기능**
   - 조건부 실행 (if/else)
   - 반복문 (for/while)
   - 변수 지원

2. **단축키 조합**
   - 여러 키 조합 지원 (예: `a` 다음 `b`)
   - 시퀀스 단축키

3. **클라우드 동기화**
   - 설정 및 매크로 클라우드 백업
   - 여러 기기 간 동기화

4. **플러그인 시스템**
   - 커스텀 액션 타입 추가
   - 외부 스크립트 실행

---

## 결론

AutoHotKeys.spoon은 기본적인 기능은 잘 구현되어 있습니다:
- ✅ 컨텍스트 감지 및 단축키 실행
- ✅ 매크로 녹화/재생
- ✅ 기본 UI 제공

하지만 다음과 같은 개선이 필요합니다:
- ⚠️ 메뉴 위치 저장/로드 버그 수정
- ⚠️ 단축키 편집/삭제 기능 추가
- ⚠️ 에러 처리 강화
- ⚠️ UIObjects 통합 완료

전체적으로 안정적인 베이스는 갖추어져 있으며, 위 개선 사항들을 적용하면 더욱 완성도 높은 도구가 될 것입니다.

