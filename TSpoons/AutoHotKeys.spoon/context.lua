-- AutoHotKeys 컨텍스트 감지 모듈
local context = {}

local appmod = hs.application
local winmod = hs.window
local osascript = hs.osascript

-- 브라우저 앱 이름 목록
context.BROWSER_APPS = {
    "Safari",
    "Google Chrome",
    "Brave Browser",
    "Microsoft Edge",
    "Arc"
}

-- 브라우저 URL 조회 (AppleScript)
local function getBrowserActiveURL(appName)
    if appName == "Safari" then
        local script = [[tell application "Safari" to get URL of current tab of front window]]
        local ok, result = osascript.applescript(script)
        return ok and result or nil
    end
    
    -- Chromium 계열 브라우저
    for _, name in ipairs(context.BROWSER_APPS) do
        if appName == name then
            local script = string.format([[tell application "%s" to get URL of active tab of front window]], appName)
            local ok, result = osascript.applescript(script)
            return ok and result or nil
        end
    end
    
    return nil
end

-- URL에서 호스트 추출
local function extractHost(url)
    if not url then return nil end
    return url:match("^%w+://([^/]+)")
end

-- 현재 컨텍스트 감지
function context.current()
    local frontApp = appmod.frontmostApplication()
    if not frontApp then return { kind = "none", id = "none" } end
    
    local appName = frontApp:name()
    local bundleId = frontApp:bundleID() or appName
    local win = winmod.frontmostWindow()
    local winFrame = win and win:frame() or {x = 0, y = 0, w = 0, h = 0}
    
    -- 브라우저인 경우 URL 확인
    local url = getBrowserActiveURL(appName)
    if url then
        local host = extractHost(url)
        if host then
            return {
                kind = "site",
                id = "site:" .. host,
                appName = appName,
                bundleId = bundleId,
                url = url,
                host = host,
                winFrame = winFrame
            }
        end
    end
    
    -- 일반 앱
    return {
        kind = "app",
        id = "app:" .. bundleId,
        appName = appName,
        bundleId = bundleId,
        url = nil,
        host = nil,
        winFrame = winFrame
    }
end

return context

