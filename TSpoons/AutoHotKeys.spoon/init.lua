local obj = {}

obj.__index = obj

-- Metadata
obj.name = "AutoHotKeys"
obj.version = "0.2.0"
obj.author = "zer0wiz<zer0wiz9@gmail.com>"
obj.homepage = "https://github.com/zer0wiz/spacehammer"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.logger = hs.logger.new("AutoHotKeys")

-- Configuration
obj.hotkey = obj.hotkey or {{"shift", "cmd"}, "k"}

-- 모듈 로드 함수
local function loadModule(moduleName)
    return dofile(hs.spoons.resourcePath(moduleName .. ".lua"))
end

-- 핵심 모듈 로드
local context = loadModule("context")
local storage = loadModule("storage")
local overlay = loadModule("overlay")
local menu = loadModule("menu")
-- local capture = loadModule("capture")
local execution = loadModule("execution")
local watchers = loadModule("watchers")
local hotkeys = loadModule("hotkeys")

-- 모듈들을 외부에서 접근할 수 있도록 노출
obj.context = context
obj.storage = storage
obj.overlay = overlay
obj.menu = menu
-- obj.capture = capture
obj.execution = execution
obj.watchers = watchers
obj.hotkeys = hotkeys

function obj:start()
    -- Storage 초기화
    storage.init()
    
    -- Watchers 시작
    watchers.start(self)
    
    -- Overlay 생성
    overlay.init(self)
    
    -- Capture 등록
    -- capture.register(self)
    
    -- Hotkeys 바인딩
    hotkeys.bind(self)
    
    return self
end

function obj:stop()
    overlay.stop(self)
    watchers.stop(self)
    -- capture.stop(self)
    hotkeys.unbind(self)
end

function obj:menutoggle()
    menu.toggle(self)
end 

function obj:init()
    obj:start( )
end

return obj