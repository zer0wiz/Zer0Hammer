local obj = {}

obj.__index = obj

-- Metadata
obj.name = "AutoHotKeys"
obj.version = "0.2.0"
obj.author = "zer0wiz<zer0wiz9@gmail.com>"
obj.homepage = "https://github.com/zer0wiz/spacehammer"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.logger = hs.logger.new("AutoHotKeys")

-- Add Spoon path to package.path to allow requiring internal modules
local spoonPath = hs.spoons.resourcePath("")
if not string.find(package.path, spoonPath, 1, true) then
    package.path = package.path .. ";" .. spoonPath .. "/?.lua"
end

-- Configuration
obj.hotkey = obj.hotkey or {{"shift", "cmd"}, "k"}

-- 모듈 로드 함수
local function loadModule(moduleName)
    return dofile(hs.spoons.resourcePath(moduleName .. ".lua"))
end

-- 핵심 모듈 로드
obj.menu = loadModule("menu")
obj.context = loadModule("contextInfo")
obj.storage = loadModule("storage")
obj.overlay = loadModule("overlay")
obj.execution = loadModule("execution")
obj.watchers = loadModule("watchers")
obj.hotkeys = loadModule("hotkeys")
obj.shortcutPreview = loadModule("shortcut_preview")
obj.recorder = loadModule("recorder")
obj.playback = loadModule("playback")
obj.mouse = loadModule("mouse")
obj.hotkeyValidator = loadModule("hotkeyValidator")

-- 모듈 간 참조 설정
obj.menu.context = obj.context


-- 토글된 컨텍스트 추적 (컨텍스트 ID를 키로 사용)
obj.activeContexts = {}

-- 모듈들을 외부에서 접근할 수 있도록 노출
-- obj.capture = capture

-- playback 모듈에 execution 참조 설정
obj.playback.setExecution(obj.execution)

function obj:start()
    -- Storage 초기화
    obj.storage.init()
    
    -- 기존 설정 파일 마이그레이션 (최초 1회만 실행)
    local contextList = obj.storage.loadContextList()
    print('#### contextList')
    dbg(contextList)
    
    -- Watchers 시작
    obj.watchers.start(self)
    
    -- Overlay 생성
    obj.overlay.init(self)
    
    -- Capture 등록
    -- capture.register(self)
    
    -- Hotkeys 바인딩
    obj.hotkeys.bind(self)
    
    return self
end

function obj:stop()
    obj.overlay.stop(self)
    obj.watchers.stop(self)
    -- capture.stop(self)
    obj.hotkeys.unbind(self)
end

function obj:menuToggle()
    local ctx = obj.context.current()
    dbg(ctx)
    -- obj.menu.create("TestMenu")
    dbg(obj.menu.menuList)
    
    obj.menu.toggle(self)
end 

function obj:init()
    obj:start( )
end

return obj