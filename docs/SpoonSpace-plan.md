# SpoonSpace.spoon 확장 계획

## 프로젝트 개요
SpoonSpace 스푼을 확장하여 yabaiM 없이 순수 Hammerspoon API로 윈도우 타일링 및 관리 기능을 제공합니다.

## 현재 상태
- 기본 구조 존재 (`TSpoons/SpoonSpace.spoon/`)
- Space/Window/Display 관련 기본 기능 구현됨
- ModalMgr과 통합되어 있음
- yabaiM 의존성 제거 필요

## 목표 기능
- yabaiM 없이 순수 Hammerspoon API로 타일링 구현
- PaperWM 스타일의 수평 타일링 지원
- Display, Space, Window, App 관리 기능 확장

## 주요 작업

### 1. 타일링 엔진 구현 (`tiling.lua`)
- PaperWM 참고하여 수평 타일링 로직 구현
- `hs.window.tiling` API 활용
- 윈도우 간격(gap) 설정 기능
- 컬럼/행 기반 윈도우 배치

### 2. yabaiM 의존성 제거
- `YabaiM.spoon`의 기능을 Hammerspoon API로 재구현
- 윈도우 이동/크기 조정/포커스 전환 기능
- Space 전환 및 윈도우 Space 간 이동

### 3. Display/Space 관리 강화 (`display.lua`, `space.lua`)
- 다중 화면 지원 개선
- Space 간 윈도우 이동 최적화
- Space별 윈도우 레이아웃 저장/복원

### 4. Window 관리 확장 (`window.lua`)
- 윈도우 그리드 배치 (2x2, 3x3 등)
- 윈도우 스택 관리
- 앱별 윈도우 레이아웃 규칙

### 5. 키바인딩 확장 (`keymaps.lua`)
- 타일링 관련 단축키 추가
- 화면/Space 전환 단축키 보강

## 파일 구조

```
TSpoons/SpoonSpace.spoon/
├── init.lua          (기존, yabaiM 의존성 제거)
├── modal.lua         (기존, 유지)
├── keymaps.lua       (기존, 확장)
├── webview.lua       (기존, 유지)
├── tiling.lua        (신규, 타일링 엔진)
├── display.lua       (신규, Display 관리)
├── space.lua         (신규, Space 관리)
└── window.lua        (신규, Window 관리)
```

## 참고 자료
- PaperWM.spoon: 타일링 로직 참고
- YabaiM.spoon: 기능 분석 및 대체 구현
- ModalMgr.spoon: 모달 시스템 통합
- hs.window, hs.spaces, hs.screen API 문서

