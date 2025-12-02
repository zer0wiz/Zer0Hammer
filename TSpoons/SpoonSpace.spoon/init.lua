local obj = {}

obj.__index = obj

obj.name = "SpoonSpace"
obj.version = "1.0"
obj.author = "zer0wiz<zer0wiz9@gmail.com>"
obj.homepage = "https://github.com/zer0wiz/SpoonSpace"
obj.license = "MIT"

local modalManager = spoon.ModalMgr

-- 모듈 로드 함수
local function loadModule(moduleName)
    return dofile(hs.spoons.resourcePath(moduleName .. ".lua"))
end

local modal = loadModule("modal")
local keymaps = loadModule("keymaps")
local webview = loadModule("webview")

-- webview 모듈을 외부에서 접근할 수 있도록 노출
obj.webview = webview

-- dbg(obj)

if not modalManager then
    error("ModalMgr spoon을 로드할 수 없습니다")
end

function obj:move_to_space(space_number)
    dbg(hs.window.focusedWindow())
    
     result = hs.spaces.moveWindowToSpace(hs.window.focusedWindow(), space_number, true)
     dbg(result)
  print("Moving to space " .. space_number)
end

-- 특정 윈도우를 다른 화면의 지정된 Space로 이동
function obj:move_to_screen_space(screenIndex, spaceIndex)
    local window = hs.window.focusedWindow()
    local screens = hs.screen.allScreens()
    
    if not window then
        print("Error: 포커스된 윈도우가 없습니다")
        return false
    end
    
    if not screens[screenIndex] then
        print("Error: 화면 " .. screenIndex .. "를 찾을 수 없습니다")
        return false
    end
    
    local targetScreen = screens[screenIndex]
    local spaces = require('hs._asm.undocumented.spaces')
    local screenSpaces = spaces.layout()[targetScreen:spacesUUID()]
    
    if not screenSpaces or not screenSpaces[spaceIndex] then
        print("Error: 대상 화면의 Space " .. spaceIndex .. "를 찾을 수 없습니다")
        return false
    end
    
    local targetSpace = screenSpaces[spaceIndex]
    local success = hs.spaces.moveWindowToSpace(window, targetSpace, true)
    
    if success then
        print(string.format("윈도우 '%s'를 화면 '%s'의 Space %d로 이동했습니다", 
              window:title(), targetScreen:name(), spaceIndex))
        
        -- 윈도우가 대상 화면에 맞게 크기 조정
        local targetFrame = targetScreen:frame()
        window:setFrame(targetFrame)
        
        return true
    else
        print("윈도우 이동에 실패했습니다")
        return false
    end
end

-- 특정 앱의 윈도우를 다른 화면으로 이동
function obj:move_app_to_screen_space(appName, screenIndex, spaceIndex)
    local app = hs.application.find(appName)
    if not app then
        print("앱 '" .. appName .. "'을 찾을 수 없습니다")
        return false
    end
    
    local screens = hs.screen.allScreens()
    if not screens[screenIndex] then
        print("Error: 화면 " .. screenIndex .. "를 찾을 수 없습니다")
        return false
    end
    
    local targetScreen = screens[screenIndex]
    local window = app:focusedWindow() or app:mainWindow()
    
    if window then
        local spaces = require('hs._asm.undocumented.spaces')
        local screenSpaces = spaces.layout()[targetScreen:spacesUUID()]
        
        if not screenSpaces or not screenSpaces[spaceIndex] then
            print("Error: 대상 화면의 Space " .. spaceIndex .. "를 찾을 수 없습니다")
            return false
        end
        
        local targetSpace = screenSpaces[spaceIndex]
        local success = hs.spaces.moveWindowToSpace(window, targetSpace, true)
        
        if success then
            print(string.format("앱 '%s'를 화면 '%s'의 Space %d로 이동했습니다", 
                  appName, targetScreen:name(), spaceIndex))
            
            -- 윈도우가 대상 화면에 맞게 크기 조정
            local targetFrame = targetScreen:frame()
            window:setFrame(targetFrame)
            
            return true
        else
            print("앱 이동에 실패했습니다")
            return false
        end
    else
        print("앱 '" .. appName .. "'의 윈도우를 찾을 수 없습니다")
        return false
    end
end

-- 모든 화면의 Space 정보를 조회하고 출력
function obj:show_screen_spaces_info()
    local spaces = require('hs._asm.undocumented.spaces')
    local layout = spaces.layout()
    local info = {}
    
    print("=== 화면별 Space 정보 ===")
    
    for screenUUID, screenSpaces in pairs(layout) do
        local screen = hs.screen.find(screenUUID)
        if screen then
            info[screen:name()] = {
                screen = screen,
                spaces = screenSpaces,
                activeSpace = spaces.activeSpace()
            }
            
            print(string.format("화면: %s", screen:name()))
            print(string.format("  Space 개수: %d", #screenSpaces))
            print(string.format("  현재 활성 Space: %s", spaces.activeSpace()))
            print("  모든 Space:")
            for i, space in ipairs(screenSpaces) do
                print(string.format("    Space %d: %s", i, space))
            end
            print("---")
        end
    end
    
    return info
end

-- 모니터 정보 출력
function obj:show_monitor_info()
    local screens = hs.screen.allScreens()
    print("=== 현재 모니터 정보 ===")
    for i, screen in ipairs(screens) do
        print(hs.inspect(screen:id()))
        
        -- print(hs.inspect(hs.spaces.spacesForScreen(screen:id())))
        -- print(hs.inspect(hs.spaces.data_managedDisplaySpaces()))
        -- print(hs.inspect(hs.spaces.allSpaces()))
        print(hs.spaces.activeSpaceOnScreen(screen:id()))
        for _, space in ipairs(hs.spaces.activeSpaces()) do
            print(hs.inspect(space))
        end
            -- print(hs.inspect(space))
            -- print(hs.inspect(hs.spaces.spaceForIdentifier(space)))
            -- print(hs.inspect(hs.spaces.spaceForIdentifier(space):id()))
            -- print(hs.inspect(hs.spaces.spaceForIdentifier(space):name()))
            -- print(hs.inspect(hs.spaces.spaceForIdentifier(space):type()))
            -- print(hs.inspect(hs.spaces.spaceForIdentifier(space):typeId()))
            -- print(hs.inspect(hs.spaces.spaceForIdentifier(space):typeId()))
        -- print(string.format("모니터 %d: %s (UUID: %s)", i, screen:name(), screen:spacesUUID()))
        -- print(string.format("  해상도: %dx%d", screen:frame().w, screen:frame().h))
        -- print(string.format("  위치: x=%d, y=%d", screen:frame().x, screen:frame().y))
    end
    print("========================")
end

function obj:bind_key(modal)
    print("SpoonSpace bind_key")
    local spoonSpaceModal = modal
    keymaps.setup(spoonSpaceModal, modalManager, obj)
end

function obj:start(spoonSpaceModal, modalManagerParam)
    print("SpoonSpace start")
    if modalManagerParam then modalManager = modalManagerParam end
    -- 키바인딩 설정
    obj:bind_key(spoonSpaceModal)
end
return obj
