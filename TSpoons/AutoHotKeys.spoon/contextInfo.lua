-- AutoHotKeys 컨텍스트 감지 모듈
local context = {}

local application = hs.application
local winmod = hs.window
local osascript = hs.osascript

-- 브라우저 앱 이름 목록
BROWSER_URL_SCRIPTS = {
    SAFARI = function() return [[tell application "Safari" to get URL of current tab of front window]] end,
    CHROMIUM = function(appName) return string.format([[tell application "%s" to get URL of active tab of front window]], appName) end,
}
context.TYPES= {
    WEB = "WEB",
    APP = "APP"
}
context.BROWSER_APPS = {
    "Safari",
    "Google Chrome",
    "Brave Browser",
    "Microsoft Edge",
    "Vivaldi",
    "Opera",
    "Arc"
}

context.info = {
    type = "",
    id = "",
    pid = nil,
    appName = nil,
    bundleId = nil,
    title = nil,
    url = nil,
    host = nil,
    winFrame = nil
}

-- 브라우저 URL 조회 (AppleScript)
local function getType(appName)
    for _, name in ipairs(context.BROWSER_APPS) do
        if appName == name then
            return context.TYPES.WEB
        end
    end
    return context.TYPES.APP
end

local function getBrowserActiveURL(appName)
    if not appName then
        return nil
    end
    
    local script = nil
    if appName == "Safari" then
        script = BROWSER_URL_SCRIPTS.SAFARI()
    else
        -- Chromium 계열 브라우저 확인
        for _, name in ipairs(context.BROWSER_APPS) do
            if appName == name and appName ~= "Safari" then
                script = BROWSER_URL_SCRIPTS.CHROMIUM(appName)
                break
            end
        end
    end
    
    if not script then
        return nil
    end
    
    -- osascript.applescript()는 (success, output) 두 개의 값을 반환
    local success, output = osascript.applescript(script)
    
    -- success가 true이고 output이 문자열이면 반환
    if success and type(output) == "string" and output ~= "" then
        return output
    end
    
    return nil
end

-- URL에서 호스트 추출
local function extractHost(url)
    if not url or type(url) ~= "string" then 
        return nil 
    end
    return url:match("^%w+://([^/]+)")
end

-- 현재 컨텍스트 감지
function context.current()
    local frontApp = application.frontmostApplication()
    if not frontApp then return { type = "none", id = "none" } end
    
    local win = winmod.frontmostWindow()
    local winFrame = win and win:frame() or nil
    
    context.info.appName = frontApp:name()
    context.info.pid = frontApp:pid()
    context.info.bundleId = frontApp:bundleID()
    context.info.title = frontApp:title()
    context.info.winFrame = winFrame
    context.info.type = getType(context.info.appName)
    
    -- 브라우저인 경우 URL 확인
    if context.info.type == context.TYPES.WEB then
        context.info.url = getBrowserActiveURL(context.info.appName)
        context.info.host = extractHost(context.info.url)
    else
        context.info.url = nil
        context.info.host = nil
    end

    context.info.id = context.info.type:lower() .. ":" .. context.info.bundleId
    return context.info
end

return context

