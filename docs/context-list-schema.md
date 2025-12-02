# context-list.json 스키마 문서

## 개요
`context-list.json`은 AutoHotKeys에서 관리하는 모든 컨텍스트(앱/브라우저)의 중앙 목록을 관리하는 설정 파일입니다.

## 파일 위치
`{Hammerspoon config dir}/autohotkeys/context-list.json`

## 스키마 구조

```json
{
  "version": "1.0",
  "contexts": [
    {
      "id": "app:com.google.Chrome",
      "type": "app",
      "name": "Google Chrome",
      "bundleId": "com.google.Chrome",
      "enabled": true,
      "configPath": "contexts/app_com.google.Chrome.json",
      "createdAt": 1234567890,
      "updatedAt": 1234567890
    },
    {
      "id": "browser:youtube.com",
      "type": "browser",
      "name": "YouTube",
      "domain": "youtube.com",
      "bundleId": "com.google.Chrome",
      "enabled": true,
      "configPath": "contexts/browser_youtube.com.json",
      "createdAt": 1234567890,
      "updatedAt": 1234567890
    }
  ]
}
```

## 필드 설명

### 루트 레벨
- `version` (string, required): 스키마 버전 (현재: "1.0")
- `contexts` (array, required): 컨텍스트 목록

### 컨텍스트 객체
- `id` (string, required): 고유 식별자
  - 앱: `app:{bundleId}` 형식 (예: `app:com.google.Chrome`)
  - 브라우저: `browser:{domain}` 형식 (예: `browser:youtube.com`)
- `type` (string, required): 컨텍스트 타입 (`"app"` 또는 `"browser"`)
- `name` (string, required): 표시 이름
- `bundleId` (string, optional): 앱 번들 ID (브라우저 컨텍스트의 경우 해당 브라우저 앱의 bundleId)
- `domain` (string, optional): 브라우저 도메인 (브라우저 타입인 경우 필수)
- `enabled` (boolean, required): 활성화 여부
- `configPath` (string, required): 개별 설정 파일 경로 (상대 경로)
  - 형식: `contexts/{sanitized_id}.json`
- `createdAt` (number, optional): 생성 타임스탬프 (Unix timestamp)
- `updatedAt` (number, optional): 수정 타임스탬프 (Unix timestamp)

## 파일 구조 예시

```
autohotkeys/
├── config.json              # 전역 설정
├── context-list.json        # 컨텍스트 목록 (이 파일)
├── contexts/                # 컨텍스트별 설정 파일
│   ├── app_com.google.Chrome.json
│   ├── app_com.vivaldi.Vivaldi.json
│   ├── browser_youtube.com.json
│   └── browser_github.com.json
└── _macros/                 # 매크로 저장소
```

## 마이그레이션 전략

기존 개별 앱 설정 파일들을 context-list.json으로 마이그레이션:
1. `autohotkeys/app_*.json` 파일들을 스캔
2. 각 파일을 읽어서 컨텍스트 정보 추출
3. `contexts/` 폴더로 이동
4. `context-list.json`에 항목 추가

## 사용 예시

### 컨텍스트 추가
```lua
storage.addContext({
  id = "app:com.example.App",
  type = "app",
  name = "Example App",
  bundleId = "com.example.App",
  enabled = true
})
```

### 컨텍스트 목록 조회
```lua
local contextList = storage.loadContextList()
for _, ctx in ipairs(contextList.contexts) do
  print(ctx.id, ctx.name, ctx.enabled)
end
```

### 특정 컨텍스트 찾기
```lua
local ctx = storage.findContext("app:com.google.Chrome")
if ctx then
  print("Found:", ctx.name)
end
```

