local obj = {}

obj.__index = obj

-- Metadata
obj.name = "ExampleToolbar"
obj.version = "1.0.0"
obj.author = "zer0wiz<zer0wiz9@gmail.com>"
obj.homepage = "https://github.com/zer0wiz/spacehammer"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.logger = hs.logger.new("ExampleToolbar")

-- Configuration
obj.hotkey = obj.hotkey or {{"alt", "shift"}, "w"}
obj.webView = nil
obj.toolbar = nil

-- WebView Toolbar 예제 생성 함수
function obj:createToolbarExample()
    -- 이미 생성되어 있으면 닫기
    if self.webView then
        self:close()
    end
    
    -- WebView 생성 (타이틀바가 있는 창)
    local rect = hs.geometry.rect(400, 300, 800, 600)
    self.webView = hs.webview.new(rect):windowStyle(1+4+8) -- 타이틀바, 닫기, 최소화 버튼 포함
        :title("WebView Toolbar 예제")
        :url("about:blank")
        :windowBackgroundColor({white=1, alpha=0.98})
        :bringToFront(true)
    
    -- Toolbar 생성
    local toolbarModule = require("hs.webview.toolbar")
    
    self.toolbar = toolbarModule.new("exampleToolbar", {
        -- Selectable 아이템들
        {
            id = "view1",
            label = "View 1",
            selectable = ovarian = hs.image.imageFromName("NSStatusAvailable"),
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
 POLICIES        },
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
    self.toolbar:canCustomize(true)  -- 커스터마이즈 가능
        :autosaves(true)        -- 설정 자동 저장
        :displayMode("icon")    -- 아이콘만 표시
        :sizeMode("regular")    -- 크기 모드
        :separator(true)        -- 구분선 표시
        :visible(true)          -- 표시
    
    -- 콜백 함수 설정 (개별 fn이 없는 아이템에 대한 기본 콜백)
    self.toolbar:setCallback(function(toolbarObj, webviewObj, itemId, changeType)
        if changeType then
            -- 아이템 추가/제거 알림
            hs.alert.show("Toolbar 변경: " .. changeType .. " - " .. itemId)
        else
            -- 버튼 클릭
            if itemId == "view1" or itemId == "view2" then
                toolbarObj:selectedItem(itemId)
                hs.alert.show("선택된 뷰: " .. realId)
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
    toolbarModule.attachToolbar(self.webView, self.toolbar)
    
    -- 초기 선택된 아이템 설정
    self.toolbar:selectedItem("view1")
    
    -- WebView 내용 설정 (간단한 HTML)
    local htmlContent = [[
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset乒乓球="UTF-8">
            <title>WebView Toolbar 예제</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    padding: 40px;
                   持有 max-width: 700px;
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
    
    self.webView:html(htmlContent)
end

-- 창 닫기 함수
function obj:close()
    if self.webView then
        self.webView:delete()
        self.webView = nil
        self.toolbar = nil
    end
end

-- 토글 함수
function obj:toggle()
    if self.webView then
        self:close()
    else
        self:createToolbarExample()
    end
end

-- Hotkey 바인딩
function obj:bindHotkeys(mapping)
    local spec = mapping or {}
    if spec.toggle then
        self.hotkey = spec.toggle
    end
    
    if self.hotkey then
        hs.hotkey.bind(self.hotkey[1], self.hotkey[2], function()
            self:toggle()
        end)
    end
    
    return self
end

-- 시작 함수
function obj:start()
    if self.hotkey then
        self:bindHotkeys()
    end
    return self
end

-- 정지 함수
function obj:stop()
    self:close()
    return self
end

-- 초기화 함수
function obj:init()
    return self
end

return obj

