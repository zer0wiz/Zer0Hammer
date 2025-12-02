# AutoHotKeys.spoon 리팩토링 제안

HammerSpoon에서 글로벌하게 사용할 수 있는 유틸리티와 AutoHotKeys 전용 로직을 명확히 분리하여, 향후 다른 Spoon 개발 시에도 재사용성을 높이는 구조를 제안합니다.

## 1. 구조 개요

```
AutoHotKeys.spoon/
├── init.lua                # Spoon 진입점 (모듈 로딩 및 초기화)
├── _shared/                # [Global Candidates] 다른 Spoon에서도 쓸 수 있는 범용 유틸리티
│   ├── InputHandler.lua    # 키보드/마우스 입력 시뮬레이션 (의존성 없음)
│   ├── Logger.lua          # 로깅 래퍼
│   ├── MouseUtils.lua      # (구 mouse.lua) 좌표 변환, 스크린 스케일링 등 순수 계산 로직
│   └── Visuals.lua         # (구 visuals.lua) 클릭 애니메이션 등 시각 효과
├── core/                   # [Spoon Core] 이 Spoon의 핵심 기반 로직
│   ├── Context.lua         # (구 contextInfo.lua) 앱 컨텍스트 감지
│   └── Constants.lua       # (신규) 상수 정의
├── data/                   # [Data Layer] 데이터 저장 및 관리
│   ├── Storage.lua         # 데이터 접근 Facade
│   ├── ConfigManager.lua   # 설정 관리
│   ├── ContextManager.lua  # 컨텍스트 데이터 관리
│   └── MacroRepository.lua # 매크로 데이터 관리
└── modules/                # [Features] 기능별 모듈 (비즈니스 로직)
    ├── recorder/           # 녹화 기능
    │   ├── init.lua        # (구 recorder.lua)
    │   └── capture.lua     # 이벤트 캡처
    ├── playback/           # 재생 기능
    │   ├── init.lua        # (구 playback.lua)
    │   └── executor.lua    # (구 execution.lua) 액션 실행기
    ├── ui/                 # UI 관련
    │   ├── menu/           # 메뉴 시스템
    │   │   ├── init.lua    # (구 menu.lua)
    │   │   ├── renderer.lua# (구 ui/MenuRenderer.lua)
    │   │   └── events.lua  # (구 ui/MenuEvents.lua)
    │   ├── overlay.lua     # 상태 오버레이
    │   └── preview.lua     # (구 shortcut_preview.lua)
    └── hotkeys/            # 단축키 관리
        ├── init.lua        # (구 hotkeys.lua)
        └── validator.lua   # (구 hotkeyValidator.lua)
```

## 2. 주요 변경 사항 및 이유

### A. `_shared/` (Global Candidates)
이 폴더의 파일들은 **AutoHotKeys.spoon의 비즈니스 로직에 의존하지 않아야 합니다.**
나중에 `~/.hammerspoon/utils/`로 그대로 옮겨도 작동할 수 있도록 설계합니다.

*   **MouseUtils.lua**: 기존 `mouse.lua`에서 `storage` 의존성을 제거하고, 순수하게 좌표 계산과 변환 로직만 남깁니다. 저장/로드 로직은 `data/` 또는 `modules/recorder/`로 이동합니다.
*   **InputHandler.lua**: 특정 Spoon의 설정에 의존하지 않고, 인자로 받은 명령(클릭, 키 입력)만 충실히 수행하도록 합니다.

### B. `data/` (Data Layer)
데이터의 저장 방식(JSON, SQLite 등)이 바뀌더라도 비즈니스 로직에 영향을 주지 않도록 분리합니다.
*   `Storage.lua`는 여전히 Facade 역할을 하여 다른 모듈들이 복잡한 내부 구조를 몰라도 데이터를 조회할 수 있게 합니다.

### C. `modules/` (Feature Modules)
기능 단위로 폴더를 묶어 응집도를 높입니다.
*   **playback**: 단순히 "재생"하는 로직(`playback.lua`)과 실제 "동작을 수행"하는 로직(`execution.lua`)을 하나의 그룹으로 묶습니다.
*   **ui**: 메뉴, 오버레이, 프리뷰 등 흩어져 있던 UI 관련 파일들을 통합 관리합니다.

## 3. 마이그레이션 단계

1.  **디렉토리 생성**: 제안된 폴더 구조 생성 (`_shared`, `modules/recorder` 등)
2.  **Shared 모듈 이동 및 정제**:
    *   `mouse.lua` -> `_shared/MouseUtils.lua` (의존성 제거 리팩토링 필요)
    *   `visuals.lua` -> `_shared/Visuals.lua`
3.  **Data 모듈 정리**: 기존 `data/` 폴더 유지 및 `storage.lua` 이동
4.  **Feature 모듈 이동**:
    *   각 파일(`recorder.lua`, `execution.lua` 등)을 해당 폴더로 이동하고 `init.lua`로 이름 변경 또는 유지.
5.  **참조 수정 (`require` 경로 업데이트)**:
    *   `init.lua` 및 각 모듈에서 `require` 경로를 새로운 구조에 맞게 일괄 수정.

이 구조로 진행하시겠습니까? 승인하시면 단계별로 리팩토링을 진행하겠습니다.
