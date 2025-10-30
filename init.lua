require("hs.ipc")
hs.ipc.cliInstall("/opt/homebrew")

hs.console.clearConsole()

-- Support upcoming 5.4 release and also use luarocks' local path
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.4/?.lua;" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.4/?/init.lua"
package.cpath = package.cpath .. ";" .. os.getenv("HOME") .. "/.luarocks/lib/lua/5.4/?.so"
package.path = package.path .. ";" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.3/?.lua;" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.3/?/init.lua"
package.cpath = package.cpath .. ";" .. os.getenv("HOME") .. "/.luarocks/lib/lua/5.3/?.so"

package.path = package.path .. ";" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.3/?.lua;" .. os.getenv("HOME") .. "/.luarocks/share/lua/5.3/?/init.lua"

-- User Dev & Test Spoon
package.path = package.path .. ";" .. hs.configdir .. "/TSpoons/?.spoon/init.lua"

fennel = require("fennel")
spoon = require("hs.spoons")
table.insert(package.loaders or package.searchers, fennel.searcher)

core = require "core"

require 'luarocks.loader'

-------------------------------------------------
require "extensions"
require "modules.customModule"
require "plugins.sbar.helpers"

local uielement = require("hs.libuielement")
uielement.watcher = require("hs.libuielementwatcher")
local appWatcher = require "hs.application.watcher"


------------ Console Setting -------------------
-- hs.consoleOnTop(true)
hs.logger.defaultLogLevel = 'debug'

--------------- sketchybar load -------------------
sbar = require("sketchybar")

------------ elogger Setting -------------------
Elogger = require("elogger")
Elogger.setGlobalConfig({
    traceLogLevel = Elogger.toLogLevel("verbose"),
    debugLogLevel = Elogger.toLogLevel("verbose")
})

hs.loadSpoon("FocusHighlight")
spoon.FocusHighlight:start()
spoon.FocusHighlight.color = "#E9FF21"
spoon.FocusHighlight.windowFilter = hs.window.filter.default
spoon.FocusHighlight.arrowSize = 256
spoon.FocusHighlight.arrowFadeOutDuration = 1
spoon.FocusHighlight.highlightFadeOutDuration = 1.25
spoon.FocusHighlight.highlightFillAlpha = 0.01

-- local trackPadKeys = hs.loadSpoon("TrackpadKeys")

-- hs.hotkey.bind({"fn", "cmd"}, "\\", function()
--     hs.alert("TrackPad Key")
--     trackPadKeys.toggle()
-- end)

local hotkeyTools = hs.loadSpoon("HotkeyTools")
-- hs.hotkey.bind({"cmd", "shift"}, "\\", function()
--     hotkeyTools.toggle()
-- end)
-- hs.hotkey.bind(hyper, "S", function()
--   hs.window.focusedWindow():moveToScreen(cycleScreens())
-- end)
-- print("Capture Keys --")
-- captureKeys(1, function(firstKey)
--   print(firstKey)
-- end)
--
-- captureKeys(1, function(keys)
--     for _, key in ipairs(keys) do
--         print(key)
--     end
-- end)

-- for _, key in ipairs(hs.settings.getKeys()) do
--     dbg(key)
-- end

-- WinWin = hs.loadSpoon("WinWin")
-- hs.hotkey.bind({"ctrl", "alt"}, "left", function()
--     WinWin:stepMove("left")
-- end)
-- hs.hotkey.bind({"ctrl", "alt"}, "right", function()
--     WinWin:stepMove("right")
-- end)

-- hs.hotkey.bind({"cmd", "shift"}, "/", function()
--     WinWin:stepMove("right")
-- end)

hs.loadSpoon('SpoonInstall')
spoon.SpoonInstall:andUse('ModalMgr')

-- spoon.ModalMgr.supervisor:bind('alt', 'L', 'Lock Screen', function() hs.caffeinate.lockScreen() end)
spoon.ModalMgr.supervisor:bind('alt', 'Z', 'Toggle Hammerspoon Console', function() hs.toggleConsole() end)

KSheet = hs.loadSpoon("KSheet")
hs.hotkey.bind({"alt", "shift"}, "\\", function()
KSheet:toggle()
end)

-- dbg(package.path)
Sbar = hs.loadSpoon('SBar')


-- EnhancedSpaces = hs.loadSpoon('EnhancedSpaces')
-- EnhancedSpaces:new({
--   mSpaces = { '1', '2', '3', 'E', 'T' }, -- default { '1', '2', '3' }
--   startmSpace = 'E', -- default 2
-- })

AutoHotKeys = hs.loadSpoon('AutoHotKeys')
hs.hotkey.bind({"shift", "cmd"}, "k", function()
    AutoHotKeys:menutoggle()
end)

-- WebView Toolbar 예제
local toolbarWebView = nil
local toolbar = nil

local function createToolbarExample()
    -- 이미 생성되어 있으면 닫기
    if toolbarWebView then
        toolbarWebView:delete()
        toolbarWebView = nil
        toolbar = nil
    end
    
    -- WebView 생성 (타이틀바가 있는 창)
    local rect = hs.geometry.rect(400, 300, 800, 600)
    toolbarWebView = hs.webview.new(rect):windowStyle(1+4+8) -- 타이틀바, 닫기, 최소화 버튼 포함
        :title("WebView Toolbar 예제")
        :url("about:blank")
        :windowBackgroundColor({white=1, alpha=0.98})
        :bringToFront(true)
    
    -- Toolbar 생성
    local toolbarModule = require("hs.webview.toolbar")
    
    toolbar = toolbarModule.new("exampleToolbar", {
        -- Selectable 아이템들
        {
            id = "view1",
            label = "View 1",
            selectable = true,
            image = hs.image.imageFromName("NSStatusAvailable"),
            tooltip = "View Mode 1"
        },
        {
            id = "view2",
            label = "View 2",
            selectable = true,
            image = hs.image.imageFromName("NSStatusUnavailable"),
            tooltip = "View Mode 2"
        },
        
        -- 시스템 스페이서
        { id = "NSToolbarSpaceItem" },
        
        -- 검색 필드
        {
            id = "searchField",
            label = "검색",
            searchfield = true,
            placeholderText = "검색어를 입력하세요",
            tooltip = "검색 필드"
        },
        
        -- 유연한 스페이서
        { id = "NSToolbarFlexibleSpaceItem" },
        
        -- 그룹 아이템 (네비게이션)
        {
            id = "navGroup",
            label = "네비게이션",
            groupMembers = { "navBack", "navForward" }
        },
        {
            id = "navBack",
            label = "뒤로",
            image = hs.image.imageFromName("NSGoLeftTemplate"),
            allowedAlone = false,
            tooltip = "뒤로 가기",
            fn = function()
                hs.alert.show("뒤로 가기 클릭")
            end
        },
        {
            id = "navForward",
            label = "앞으로",
            image = hs.image.imageFromName("NSGoRightTemplate"),
            allowedAlone = false,
            tooltip = "앞으로 가기",
            fn = function()
                hs.alert.show("앞으로 가기 클릭")
            end
        },
        
        { id = "NSToolbarFlexibleSpaceItem" },
        
        -- 액션 버튼들
        {
            id = "refresh",
            label = "새로고침",
            image = hs.image.imageFromName("NSRefreshTemplate"),
            tooltip = "페이지 새로고침",
            fn = function()
                hs.alert.show("새로고침")
            end
        },
        {
            id = "settings",
            label = "설정",
            image = hs.image.imageFromName("NSAdvanced"),
            tooltip = "설정 열기",
            fn = function()
                hs.alert.show("설정 열기")
            end
        },
        
        -- 기본적으로 표시하지 않을 아이템
        {
            id = "hiddenItem",
            label = "숨김 아이템",
            default = false,
            image = hs.image.imageFromName("NSBonjour"),
            tooltip = "이 아이템은 기본적으로 숨겨져 있습니다"
        },
        
        -- 커스터마이즈 패널 열기 버튼
        {
            id = "customize",
            label = "커스터마이즈",
            image = hs.image.imageFromName("NSAdvanced"),
            tooltip = "툴바 커스터마이즈",
            fn = function(t, w)
                t:customizePanel()
            end
        }
    })
    
    -- Toolbar 설정
    toolbar:canCustomize(true)  -- 커스터마이즈 가능
        :autosaves(true)        -- 설정 자동 저장
        :displayMode("icon")    -- 아이콘만 표시
        :sizeMode("regular")    -- 크기 모드
        :separator(true)        -- 구분선 표시
        :visible(true)          -- 표시
    
    -- 콜백 함수 설정 (개별 fn이 없는 아이템에 대한 기본 콜백)
    toolbar:setCallback(function(toolbarObj, webviewObj, itemId, changeType)
        if changeType then
            -- 아이템 추가/제거 알림
            hs.alert.show("Toolbar 변경: " .. changeType .. " - " .. itemId)
        else
            -- 버튼 클릭
            if itemId == "view1" or itemId == "view2" then
                toolbarObj:selectedItem(itemId)
                hs.alert.show("선택된 뷰: " .. itemId)
            elseif itemId == "searchField" then
                local itemDetails = toolbarObj:itemDetails(itemId)
                if itemDetails then
                    hs.alert.show("검색어: " .. (itemDetails.searchText or ""))
                end
            else
                hs.alert.show("클릭된 아이템: " .. itemId)
            end
        end
    end)
    
    -- WebView에 Toolbar 연결
    toolbarModule.attachToolbar(toolbarWebView, toolbar)
    
    -- 초기 선택된 아이템 설정
    toolbar:selectedItem("view1")
    
    -- WebView 내용 설정 (간단한 HTML)
    local htmlContent = [[
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>WebView Toolbar 예제</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    padding: 40px;
                    max-width: 700px;
                    margin: 0 auto;
                    line-height: 1.6;
                }
                h1 { color: #333; }
                .info { 
                    background: #f0f0f0; 
                    padding: 20px; 
                    border-radius: 8px; 
                    margin: 20px 0;
                }
                code {
                    background: #e8e8e8;
                    padding: 2px 6px;
                    border-radius: 3px;
                    font-family: 'Monaco', monospace;
                }
            </style>
        </head>
        <body>
            <h1>WebView Toolbar 예제</h1>
            <div class="info">
                <p><strong>사용 가능한 기능:</strong></p>
                <ul>
                    <li>Selectable 아이템 (View 1, View 2) - 선택 상태 표시</li>
                    <li>검색 필드 - 텍스트 입력 가능</li>
                    <li>네비게이션 그룹 - 뒤로/앞으로 버튼</li>
                    <li>액션 버튼 - 새로고침, 설정</li>
                    <li>커스터마이즈 - 툴바 항목 재배치 가능</li>
                </ul>
                <p>툴바 버튼을 클릭하면 알림이 표시됩니다.</p>
                <p><code>Alt + Shift + W</code>를 다시 누르면 창이 닫힙니다.</p>
            </div>
        </body>
        </html>
    ]]
    
    toolbarWebView:html(htmlContent)
end

-- Alt + Shift + W로 툴바 예제 실행
hs.hotkey.bind({"alt", "shift"}, "w", function()
    if toolbarWebView then
        -- 이미 열려있으면 닫기
        toolbarWebView:delete()
        toolbarWebView = nil
        toolbar = nil
    else
        -- 새로 열기
        createToolbarExample()
    end
end)
-- function setWindowTransparency(appName, opacity)
--     local script = string.format([[
--         tell application "System Events"
--             set frontApp to first process whose name is "%s"
--             tell frontApp
--                 set alpha value to %f
--             end tell
--         end tell
--     ]], appName, opacity)
--
--     hs.osascript.applescript(script)
-- end
--
-- setWindowTransparency("Finder", 0.5) -- Finder 창을 50% 투명하게 설정

-- https://github.com/mogenson/PaperWM.spoon
-- use three finger swipe to focus nearby window
-- https://github.com/mogenson/Swipe.spoon
-- Swipe = hs.loadSpoon("Swipe")

-- Swipe:start(4, function(direction, distance, id)
--     if id == current_id then
--         if distance > threshold then
--             threshold = math.huge -- trigger once per swipe

--             -- use "natural" scrolling
--             if direction == "left" then
--                 actions.focus_right()
--             elseif direction == "right" then
--                 actions.focus_left()
--             elseif direction == "up" then
--                 actions.focus_down()
--             elseif direction == "down" then
--                 actions.focus_up()
--             end
--         end
--     else
--         current_id = id
--         threshold = 0.2 -- swipe distance > 20% of trackpad size
--     end
-- end)

-- https://github.com/mogenson/ActiveSpace.spoon
-- ActiveSpace = hs.loadSpoon("ActiveSpace")
-- ActiveSpace.compact = true
-- ActiveSpace:start()

-- https://github.com/mogenson/WarpMouse.spoon
-- WarpMouse = hs.loadSpoon("WarpMouse")
-- WarpMouse.margin = 2  -- optionally set how far past a screen edge the mouse should warp, default is 2 pixels
-- WarpMouse:start()


YabaiM = hs.loadSpoon("YabaiM")

SpoonSpace = hs.loadSpoon("SpoonSpace")

-- spoon.SpoonInstall:andUse('PaperWM')
-- PaperWM = hs.loadSpoon("PaperWM")

-------------------------------------------------
-- 모달 생성 및 각 스푼에 전달
local spoonSpaceModal = spoon.ModalMgr:new('spoonSpace')
local yabaiModal = spoon.ModalMgr:new('yabaiM')
-- local paperWMModal = spoon.ModalMgr:new('paperWM')

-- 각 스푼 시작 (modal 주입)
if SpoonSpace and SpoonSpace.start then SpoonSpace:start(spoonSpaceModal, spoon.ModalMgr) end
if YabaiM and YabaiM.start then YabaiM:start(yabaiModal, spoon.ModalMgr) end
-- if PaperWM and PaperWM.start then PaperWM:start(paperWMModal, spoon.ModalMgr) end

-- supervisor 바인딩 (root에서 통합)
spoon.ModalMgr.supervisor:bind('alt', 'o', 'Enter SpoonSpace', function()
    print("### spoonSpace Enter")
    spoon.ModalMgr:deactivateAll()
    spoon.ModalMgr:activate({ 'spoonSpace' }, '#74BB67', nil, 'SpoonSpace Mode!')
    spoon.ModalMgr:modalListInfo('spoonSpace')
end)

spoon.ModalMgr.supervisor:bind('alt', 'y', 'Enter yabaiM', function()
    print("### YabaiM Enter")
    spoon.ModalMgr:deactivateAll()
    spoon.ModalMgr:activate({ 'yabaiM' }, '#74BB67', nil, 'Yabai Control Mode!')
    spoon.ModalMgr:modalListInfo('yabaiM')
end)

-- spoon.ModalMgr.supervisor:bind('alt', 'p', 'Enter PaperWM', function()
--     print("### PaperWM Enter")
--     spoon.ModalMgr:deactivateAll()
--     spoon.ModalMgr:activate({'paperWM'}, '#74BB67', nil, 'PaperWM Mode!')
--     spoon.ModalMgr:modalListInfo('paperWM')
--     PaperWM:bindHotkeys(paperWMModal, PaperWM.default_hotkeys)
-- end)
-- paperWMModal:bind('', 'escape', 'Exit PaperWM', function() 
--     print("### PaperWM Exit")
--     spoon.ModalMgr:deactivateAll()
-- end)

-- 종료 키맵
-- paperWMModal:bind('', 'escape', 'Exit PaperWM', function() 
--     print("### PaperWM Exit"                                                    )
--     spoon.ModalMgr.hide_all_notifications()
--     spoon.ModalMgr:deactivateAll()
-- end)
-- use ⌘ Enter as hyper key to enter modal layer, press Escape to exit
-- local modal = hs.hotkey.modal.new({ "cmd" }, "return")

-------------------------------------------------
spoon.ModalMgr.supervisor:enter()


print("### Loding Completed. ###")

hs.alert.show("Spacehammer config loaded")
hs.notify.show("HS Config Loding Completed.","","") -- undecided on this line

