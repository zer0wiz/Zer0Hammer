# Changelog

All notable changes to AutoHotKeys.spoon will be documented in this file.

## [0.2.0] - 2025-10-30

### Added - Phase 1: 기본 매크로 기능

#### 새로운 모듈
- **recorder.lua**: 마우스/키보드 이벤트 녹화 모듈
  - `hs.eventtap`을 사용한 실시간 이벤트 캡처
  - 마우스 클릭, 드래그, 이동 녹화
  - 키보드 입력 및 수정자 키 녹화
  - 타임스탬프 기반 액션 기록
  - 윈도우 정보 스냅샷 저장
  - 상대/절대 좌표 동시 저장

- **playback.lua**: 매크로 재생 모듈
  - 저장된 매크로 재생
  - 반복 실행 기능 (N회 또는 무한)
  - 재생 속도 조절 (0.5x ~ 2.0x)
  - 윈도우 크기 변경 시 좌표 자동 스케일링
  - 컨텍스트 매칭 기능

#### 기능 확장

- **storage.lua** 확장
  - 매크로 저장/로드 함수 추가
  - `_macros/` 폴더 자동 생성
  - 매크로 목록 조회 기능
  - 매크로 삭제 기능

- **menu.lua** 확장
  - 매크로 목록 화면 추가
  - 매크로 재생/삭제 버튼
  - 매크로 정보 표시 (액션 수, 생성일)

- **overlay.lua** 확장
  - 녹화 중 상태 표시 (빨간색 "REC")
  - 재생 중 상태 표시 (파란색 + 매크로 이름)
  - Canvas 객체 분리 (`overlayCanvas`)

- **hotkeys.lua** 확장
  - `Ctrl+Cmd+R`: 매크로 녹화 시작/중지
  - `Ctrl+Cmd+M`: 매크로 목록 열기
  - AppleScript 기반 매크로 이름 입력 다이얼로그

- **init.lua** 업데이트
  - recorder, playback 모듈 로드
  - 모듈 간 참조 설정

#### API 추가

**Recorder API:**
- `recorder.start(obj, macroName)`: 녹화 시작
- `recorder.stop(obj)`: 녹화 중지 및 매크로 반환
- `recorder.pause(obj)`: 녹화 일시정지
- `recorder.resume(obj)`: 녹화 재개
- `recorder.isRecording(obj)`: 녹화 중 여부 확인
- `recorder.getCurrentMacro(obj)`: 현재 녹화 중인 매크로 정보

**Playback API:**
- `playback.play(obj, macroName, options)`: 매크로 재생
- `playback.stop(obj)`: 재생 중지
- `playback.isPlaying(obj)`: 재생 중 여부 확인
- `playback.setSpeed(obj, speed)`: 재생 속도 변경
- `playback.getCurrentMacro(obj)`: 현재 재생 중인 매크로 정보

**Storage API:**
- `storage.saveMacro(macroName, macroData)`: 매크로 저장
- `storage.loadMacro(macroName)`: 매크로 로드
- `storage.listMacros()`: 매크로 목록 조회
- `storage.deleteMacro(macroName)`: 매크로 삭제

### Changed

- 오버레이 캔버스를 별도 변수(`obj.overlayCanvas`)로 분리
- `roundedRectangle` 타입을 `rectangle`로 변경 (Hammerspoon 호환성)
- 드래그 액션의 `start`/`end`를 `startPosition`/`endPosition`으로 명확화

### Fixed

- Lua 예약어 `end` 사용 오류 수정 (`["end"]`로 변경)
- `overlay.update()` nil 참조 오류 수정
- `playback.getCurrentMacro()` nil 안전성 개선
- Canvas 타입 오류 수정
- 모듈 참조 오류 수정

### Data Structure

**매크로 데이터 형식:**
```lua
{
    name = "macro_name",
    createdAt = 1234567890,
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
            window = {...}
        }
    },
    totalDuration = 1.5
}
```

### Technical Details

- **녹화**: `hs.eventtap`을 사용한 이벤트 캡처
- **타임스탬프**: `hs.timer.absoluteTime()` 사용
- **좌표 변환**: 윈도우 프레임 비율 기반 스케일링
- **저장 형식**: JSON
- **저장 위치**: `~/.hammerspoon/autohotkeys/_macros/`

---

## [0.1.0] - 2024-XX-XX

### Added

- 기본 단축키 시스템
- 컨텍스트 기반 단축키 (앱/사이트별)
- 클릭/키 입력/지연 액션
- 메뉴 UI 시스템
- 오버레이 표시
- 단축키 미리보기

### Features

- 앱별 단축키 활성화/비활성화
- 윈도우 상대 좌표 클릭
- 드래그 가능한 메뉴
- 단축키 캡처 모드

---

## Future Releases

### [0.3.0] - Phase 2: 고급 마우스 제어 (예정)

- mouse.lua 모듈 (위치 저장/관리)
- execution.lua 확장 (다양한 클릭 타입, 텍스트 입력)
- 화면 해상도 변경 대응

### [0.4.0] - Phase 3: 액션 시퀀스 (예정)

- sequence.lua 모듈
- 조건문/반복문 지원
- 변수 시스템

### [0.5.0] - Phase 4: UI 완성 (예정)

- 매크로 편집 인터페이스
- 시퀀스 빌더 UI
- 위치 관리 UI

