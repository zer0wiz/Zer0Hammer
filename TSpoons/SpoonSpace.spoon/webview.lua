-- SpoonSpace WebView 모듈 (범용 텍스트 표시 도구)
local WebView = {}

-- HTML 엔티티 이스케이프 함수
local function escapeHTML(str)
    if not str then return "" end
    return str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&#39;")
end

-- 템플릿 시스템
WebView.templates = {}
WebView.currentTemplate = "default"

-- 템플릿 로드 함수
function WebView.loadTemplate(templateName)
    local templatePath = hs.spoons.resourcePath("template/" .. templateName .. ".lua")
    local success, template = pcall(dofile, templatePath)
    if success and template then
        WebView.templates[templateName] = template
        return template
    else
        print("Failed to load template:", templateName, "from path:", templatePath)
        return nil
    end
end

-- 기본 템플릿 로드
WebView.loadTemplate("default")

-- 템플릿 선택 함수
function WebView.setTemplate(templateName)
    if WebView.templates[templateName] then
        WebView.currentTemplate = templateName
        return true
    else
        local template = WebView.loadTemplate(templateName)
        if template then
            WebView.currentTemplate = templateName
            return true
        end
        return false
    end
end

-- 템플릿으로 HTML 생성
function WebView.generateHTML(templateName, title, content, customStyles)
    local template = WebView.templates[templateName] or WebView.templates[WebView.currentTemplate]
    if not template then
        print("Template not found:", templateName or WebView.currentTemplate)
        -- 기본 HTML 반환
        return string.format([[
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { margin: 0; padding: 16px; background: #1e1e1e; color: #fff; font-family: Menlo, monospace; font-size: 13px; }
        .container { height: 100vh; overflow-y: auto; }
        .title { font-weight: bold; margin-bottom: 16px; padding-bottom: 8px; border-bottom: 1px solid #333; color: #4CAF50; }
        .content { white-space: pre-wrap; word-wrap: break-word; }
    </style>
</head>
<body>
    <div class="container">
        <div class="title">%s</div>
        <div class="content">%s</div>
    </div>
</body>
</html>
]], escapeHTML(title), escapeHTML(content))
    end
    
    local styles = template.styles
    if customStyles then
        for key, value in pairs(customStyles) do
            styles[key] = value
        end
    end
    
    return string.format(template.html,
        styles.backgroundColor,
        styles.textColor,
        styles.fontFamily,
        styles.fontSize,
        styles.cardBackground,
        styles.shadowColor,
        styles.borderColor,
        styles.borderColor,
        styles.borderColor,
        styles.backgroundColor,
        styles.backgroundColor,
        escapeHTML(title),
        escapeHTML(content)
    )
end

-- 스크롤 가능한 텍스트 패널 생성 (템플릿 시스템 사용)
function WebView.createScrollablePanel(title, content, options)
    options = options or {}
    local width = options.width or 900
    local height = options.height or 700
    local templateName = options.template or WebView.currentTemplate
    local customStyles = options.styles
    local alpha = options.alpha or 0.95  -- 기본 투명도 95%
    
    -- 포커스된 화면에 위치 계산
    local focusedWindow = hs.window.focusedWindow()
    local screen = focusedWindow and focusedWindow:screen() or hs.screen.mainScreen()
    local screenFrame = screen:fullFrame()
    local x = screenFrame.x + (screenFrame.w - width) / 2
    local y = screenFrame.y + (screenFrame.h - height) / 2
    
    -- 템플릿으로 HTML 생성
    local html = WebView.generateHTML(templateName, title, content, customStyles)
    
    -- WebView 생성
    local webview = hs.webview.new({
        x = x,
        y = y,
        w = width,
        h = height
    })
    
    -- 설정 - 더 나은 디자인
    webview:windowStyle({"titled", "closable", "resizable", "utility"})
    webview:level(hs.canvas.windowLevels.floating)
    webview:html(html)
    webview:allowGestures(true)
    webview:allowNewWindows(false)
    
    -- 투명도 설정
    webview:alpha(alpha)
    
    -- ESC 키 바인딩
    local escapeHotkey = hs.hotkey.bind({}, "escape", function()
        if webview and webview:isShowing() then
            webview:delete()
            escapeHotkey:delete()
        end
    end)
    
    -- Focus 이벤트 감지 (다른 창으로 포커스가 이동하면 닫기)
    local focusTimer = hs.timer.doEvery(0.5, function()
        if webview and webview:isShowing() then
            local focusedWindow = hs.window.focusedWindow()
            if focusedWindow and focusedWindow:application():name() ~= "Hammerspoon" then
                -- Hammerspoon이 아닌 다른 앱에 포커스가 있으면 webview 닫기
                webview:delete()
                escapeHotkey:delete()
                focusTimer:stop()
            end
        else
            -- webview가 닫혔으면 타이머 정리
            escapeHotkey:delete()
            focusTimer:stop()
        end
    end)
    
    -- webview 표시
    webview:show()
    
    -- 10초 후 자동 정리 (안전장치)
    hs.timer.doAfter(10, function()
        if escapeHotkey then
            escapeHotkey:delete()
        end
        if focusTimer then
            focusTimer:stop()
        end
    end)
    
    return webview
end

-- JSON 데이터를 보기 좋게 포맷팅
function WebView.formatJSON(data)
    if type(data) == "string" then
        local success, parsed = pcall(hs.json.decode, data)
        if success then
            return hs.inspect(parsed, {depth = 10})
        else
            return data
        end
    elseif type(data) == "table" then
        return hs.inspect(data, {depth = 10})
    else
        return tostring(data)
    end
end

-- 범용 텍스트 표시 함수 (ModalMgr의 viewInfoModal 대체)
function WebView.showText(title, content, options)
    options = options or {}
    local webview = WebView.createScrollablePanel(title, content, options)
    webview:show()
    return webview
end

-- JSON 데이터 표시
function WebView.showJSON(title, data, options)
    local content = WebView.formatJSON(data)
    return WebView.showText(title, content, options)
end

-- 커스텀 데이터 표시
function WebView.showCustomData(title, data, options)
    local content
    if options and options.format == "json" then
        content = WebView.formatJSON(data)
    else
        content = tostring(data)
    end
    
    return WebView.showText(title, content, options)
end

-- 비동기 데이터 로딩용 함수 (YabaiM 등에서 사용)
function WebView.showAsyncData(title, loadingText, options)
    options = options or {}
    local webview = WebView.createScrollablePanel(title, loadingText, options)
    webview:show()
    return webview
end

-- 비동기 데이터 업데이트 함수
function WebView.updateContent(webview, title, content, templateName)
    local html = WebView.generateHTML(templateName or WebView.currentTemplate, title, content)
    webview:html(html)
end

-- SpoonSpace 특화 함수들
function WebView.showScreenInfo()
    local screens = hs.screen.allScreens()
    local info = {}
    
    table.insert(info, "=== Screen Information ===")
    table.insert(info, "")
    
    for i, screen in ipairs(screens) do
        table.insert(info, string.format("Screen %d: %s", i, screen:name()))
        table.insert(info, string.format("  ID: %s", screen:id()))
        table.insert(info, string.format("  Frame: %s", hs.inspect(screen:frame())))
        table.insert(info, string.format("  Full Frame: %s", hs.inspect(screen:fullFrame())))
        table.insert(info, string.format("  UUID: %s", screen:spacesUUID()))
        table.insert(info, "")
    end
    
    local content = table.concat(info, "\n")
    local webview = WebView.createScrollablePanel("Screen Information", content)
    webview:show()
    
    return webview
end

function WebView.showSpaceInfo()
    local spaces = require('hs._asm.undocumented.spaces')
    local layout = spaces.layout()
    local info = {}
    
    table.insert(info, "=== Space Information ===")
    table.insert(info, "")
    table.insert(info, string.format("Active Space: %s", spaces.activeSpace()))
    table.insert(info, "")
    
    for screenUUID, screenSpaces in pairs(layout) do
        local screen = hs.screen.find(screenUUID)
        if screen then
            table.insert(info, string.format("Screen: %s", screen:name()))
            table.insert(info, string.format("  UUID: %s", screenUUID))
            table.insert(info, string.format("  Spaces (%d):", #screenSpaces))
            for i, space in ipairs(screenSpaces) do
                table.insert(info, string.format("    Space %d: %s", i, space))
            end
            table.insert(info, "")
        end
    end
    
    local content = table.concat(info, "\n")
    local webview = WebView.createScrollablePanel("Space Information", content)
    webview:show()
    
    return webview
end

function WebView.showWindowInfo()
    local windows = hs.window.allWindows()
    local info = {}
    
    table.insert(info, "=== Window Information ===")
    table.insert(info, "")
    table.insert(info, string.format("Total Windows: %d", #windows))
    table.insert(info, "")
    
    for i, window in ipairs(windows) do
        if window:isVisible() then
            table.insert(info, string.format("Window %d: %s", i, window:title()))
            table.insert(info, string.format("  App: %s", window:application():name()))
            table.insert(info, string.format("  Frame: %s", hs.inspect(window:frame())))
            table.insert(info, string.format("  Screen: %s", window:screen():name()))
            table.insert(info, string.format("  Focused: %s", window:isFocused() and "Yes" or "No"))
            table.insert(info, "")
        end
    end
    
    local content = table.concat(info, "\n")
    local webview = WebView.createScrollablePanel("Window Information", content)
    webview:show()
    
    return webview
end

return WebView
