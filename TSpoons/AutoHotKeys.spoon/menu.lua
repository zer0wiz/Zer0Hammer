-- AutoHotKeys 메뉴 모듈
local menu = {}

local canvas = hs.canvas
local screenmod = hs.screen
local json = hs.json
local fs = hs.fs

local MenuRenderer = require("ui.MenuRenderer")
local MenuEvents = require("ui.MenuEvents")

menu.menuList = {}
menu.config = nil
menu.context = nil
menu.events = nil

-- 메뉴 설정 로드
local function loadMenuConfig()
    if menu.config then return menu.config end

    local spoonPath = hs.configdir .. "/TSpoons/AutoHotKeys.spoon/"
    local configPath = spoonPath .. "assets/menu.json"

    if fs.attributes(configPath) then
        local file = io.open(configPath, "r")
        if file then
            local content = file:read("*a")
            file:close()
            menu.config = json.decode(content)
        end
    end

    if not menu.config then menu.config = {} end
    return menu.config
end

-- 앱 ID 가져오기
local function getAppId(ctx)
    if not ctx then return nil end
    if not menu.context then return ctx.id end
    if ctx.type == menu.context.TYPES.APP then
        return ctx.id
    elseif ctx.type == menu.context.TYPES.WEB then
        return menu.context.TYPES.WEB .. ":" .. ctx.bundleId
    end
    return nil
end

-- 메뉴 토글
function menu.toggle(obj)
    if obj.menuShowing then
        menu.hide(obj)
    else
        menu.show(obj)
    end
end

-- 메뉴 표시
function menu.show(obj)
    if obj.menuShowing and obj.menuCanvas then
        menu.hide(obj)
        return
    end

    if obj.menuCanvas then
        obj.menuCanvas:delete()
        obj.menuCanvas = nil
    end

    if menu.events then
        menu.events:stop()
        menu.events = nil
    end

    local ctx = obj.context.current()
    obj.contextObj = ctx

    -- 제외된 앱 확인
    local config = obj.storage.loadConfig()
    local excludedApps = config.excludedApps or {}
    for _, excludedId in ipairs(excludedApps) do
        if ctx.bundleId == excludedId then
            hs.alert.show("Excluded App", 2.0)
            return
        end
    end

    -- 메뉴 설정 및 위치 계산
    menu.config = loadMenuConfig()
    local mainMenuConfig = menu.config.mainMenu or {}
    local w = mainMenuConfig.size and mainMenuConfig.size.w or 280
    local h = mainMenuConfig.size and mainMenuConfig.size.h or 185

    local mousePos = hs.mouse.absolutePosition()
    local x, y = mousePos.x, mousePos.y

    -- 화면 경계 체크
    local mouseScreen = hs.mouse.getCurrentScreen() or screenmod.primaryScreen()
    local screenFrame = mouseScreen:frame()

    if y + h > screenFrame.y + screenFrame.h then y = (screenFrame.y + screenFrame.h) - h end
    if y < screenFrame.y then y = screenFrame.y end
    if x + w > screenFrame.x + screenFrame.w then x = (screenFrame.x + screenFrame.w) - w end
    if x < screenFrame.x then x = screenFrame.x end

    -- 캔버스 생성
    local c = canvas.new({ x = x, y = y, w = w, h = h }):show()
    c:level(canvas.windowLevels.popUpMenu)
    obj.menuCanvas = c
    obj.menuShowing = true

    -- 렌더링 변수 준비
    local appName = ctx.appName or "Unknown"
    local appId = getAppId(ctx)
    local appConfig = appId and obj.storage.loadAppConfig(appId) or nil
    local ctxConfig = obj.storage.findContext(ctx.id)
    local enabled = ctxConfig and ctxConfig.enabled or false
    local overlayEnabled = config.overlay and config.overlay.enabled or false

    -- 토글 스위치 위치 계산
    local enabledToggleWidth, enabledToggleHeight = 44, 24
    local enabledToggleX = w - enabledToggleWidth - 15
    local enabledToggleY = 10
    local enabledThumbRadius = 10
    local enabledThumbX = enabled and (enabledToggleX + enabledToggleWidth - enabledThumbRadius - 2) or
    (enabledToggleX + enabledThumbRadius + 2)

    local overlayToggleWidth, overlayToggleHeight = 44, 24
    local overlayToggleX = w - overlayToggleWidth - 20
    local overlayToggleY = 120
    local overlayThumbRadius = 10
    local overlayThumbX = overlayEnabled and (overlayToggleX + overlayToggleWidth - overlayThumbRadius - 2) or
    (overlayToggleX + overlayThumbRadius + 2)

    local vars = {
        w = w,
        h = h,
        appName = appName,
        enabledText = enabled and "ON" or "OFF",
        overlayStatus = overlayEnabled and "ON" or "OFF",
        enabledAlpha = enabled and 1.0 or 0.0,
        enabledThumbX = enabledThumbX,
        overlayAlpha = overlayEnabled and 1.0 or 0.0,
        overlayThumbX = overlayThumbX
    }

    -- 렌더링
    MenuRenderer.render(c, mainMenuConfig, vars)

    -- 이벤트 핸들러 설정
    menu.events = MenuEvents.new(obj, c, {
        onClick = function(id, cx, cy)
            -- Enabled 토글
            local isEnabledToggle = (id == "btnToggle" or id == "enabledToggleTrack") or
                (cx >= enabledToggleX and cx <= enabledToggleX + enabledToggleWidth and
                    cy >= enabledToggleY and cy <= enabledToggleY + enabledToggleHeight)

            if isEnabledToggle then
                if appId then
                    obj.storage.toggleAppEnabled(appId, ctx.appName, ctx.bundleId)

                    -- 상태 업데이트 및 리렌더링 (간소화: 메뉴 닫고 다시 열기 대신 상태만 변경하면 좋겠지만,
                    -- 여기서는 단순화를 위해 변수 업데이트 후 렌더링 다시 호출하거나 닫고 열기)
                    -- 사용자 경험을 위해 메뉴를 닫지 않고 UI만 업데이트하는 것이 좋음

                    local newEnabled = not enabled
                    enabled = newEnabled
                    vars.enabledAlpha = newEnabled and 1.0 or 0.0
                    vars.enabledThumbX = newEnabled and (enabledToggleX + enabledToggleWidth - enabledThumbRadius - 2) or
                    (enabledToggleX + enabledThumbRadius + 2)
                    vars.enabledText = newEnabled and "ON" or "OFF"

                    MenuRenderer.render(c, mainMenuConfig, vars)

                    -- 로직 업데이트
                    if newEnabled then
                        obj.activeContexts[ctx.id] = { context = ctx, timestamp = os.time() }
                    else
                        obj.activeContexts[ctx.id] = nil
                    end
                    if obj.watchers and obj.watchers.updateAppShortcuts then
                        obj.watchers.updateAppShortcuts(obj)
                    end
                    obj.overlay.update(obj)
                end
                return true
            end

            -- Overlay 토글
            local isOverlayToggle = (id == "overlayToggle" or id == "overlayToggleTrack") or
                (cx >= overlayToggleX and cx <= overlayToggleX + overlayToggleWidth and
                    cy >= overlayToggleY and cy <= overlayToggleY + overlayToggleHeight)

            if isOverlayToggle then
                local newConfig = obj.storage.loadConfig()
                newConfig.overlay = newConfig.overlay or {}
                newConfig.overlay.enabled = not (newConfig.overlay.enabled or false)
                obj.storage.saveConfig(newConfig)

                local newOverlayEnabled = newConfig.overlay.enabled
                overlayEnabled = newOverlayEnabled
                vars.overlayAlpha = newOverlayEnabled and 1.0 or 0.0
                vars.overlayThumbX = newOverlayEnabled and (overlayToggleX + overlayToggleWidth - overlayThumbRadius - 2) or
                (overlayToggleX + overlayThumbRadius + 2)
                vars.overlayStatus = newOverlayEnabled and "ON" or "OFF"

                MenuRenderer.render(c, mainMenuConfig, vars)
                obj.overlay.update(obj)
                return true
            end

            -- 단축키 메뉴
            if id == "btnShortcuts" then
                menu.hide(obj)
                if obj.shortcutPreview then
                    obj.shortcutPreview.show(obj, ctx)
                else
                    hs.alert.show("Shortcut Preview Not Ready")
                end
                return true
            end

            -- 매크로 목록
            if id == "btnMacros" then
                menu.showMacroList(obj)
                return true
            end

            return false
        end,

        onPositionChanged = function(nx, ny)
            local cfg = obj.storage.loadConfig()
            cfg.menu.position.x = nx
            cfg.menu.position.y = ny
            cfg.menu.saved = true
            obj.storage.saveConfig(cfg)
        end
    })

    c:canvasMouseEvents(true, true, false, false)
end

-- 매크로 목록 표시
function menu.showMacroList(obj)
    if obj.menuCanvas then
        obj.menuCanvas:delete()
        obj.menuCanvas = nil
    end

    if menu.events then
        menu.events:stop()
        menu.events = nil
    end

    -- 매크로 목록 로드
    local macros = obj.storage.listMacros()

    -- 메뉴 설정 및 위치 계산 (기본 크기 유지)
    menu.config = loadMenuConfig()
    local mainMenuConfig = menu.config.mainMenu or {}
    local w = mainMenuConfig.size and mainMenuConfig.size.w or 280
    local h = mainMenuConfig.size and mainMenuConfig.size.h or 185

    -- 저장된 위치 또는 마우스 위치 사용
    local cfg = obj.storage.loadConfig()
    local x, y
    if cfg.menu and cfg.menu.position and cfg.menu.saved then
        x, y = cfg.menu.position.x, cfg.menu.position.y
    else
        local mousePos = hs.mouse.absolutePosition()
        x, y = mousePos.x, mousePos.y
    end

    -- 캔버스 생성
    local c = canvas.new({ x = x, y = y, w = w, h = h }):show()
    c:level(canvas.windowLevels.popUpMenu)
    obj.menuCanvas = c
    obj.menuShowing = true

    -- 동적 메뉴 구성 (매크로 목록)
    local listConfig = {
        elements = {
            bg = {
                index = 1,
                type = "rectangle",
                action = "fill",
                fillColor = { alpha = 0.95, white = 0.08 },
                roundedRectRadii = { xRadius = 8, yRadius = 8 },
                frame = { x = 0, y = 0, w = w, h = h }
            },
            title = {
                index = 2,
                type = "text",
                text = "Saved Macros",
                textSize = 14,
                textColor = { white = 1 },
                textAlignment = "center",
                frame = { x = 0, y = 12, w = w, h = 20 }
            },
            btnBack = {
                index = 3,
                type = "text",
                text = "< Back",
                textSize = 12,
                textColor = { white = 0.7 },
                frame = { x = 15, y = 12, w = 50, h = 20 }
            },
            separator = {
                index = 4,
                type = "rectangle",
                action = "fill",
                fillColor = { white = 0.2 },
                frame = { x = 15, y = 40, w = w - 30, h = 1 }
            }
        }
    }

    -- 매크로 항목 추가
    local startY = 50
    local itemHeight = 25

    if #macros == 0 then
        listConfig.elements["emptyMsg"] = {
            index = 5,
            type = "text",
            text = "No macros saved",
            textSize = 12,
            textColor = { white = 0.5 },
            textAlignment = "center",
            frame = { x = 0, y = startY + 20, w = w, h = 20 }
        }
    else
        for i, macro in ipairs(macros) do
            if i > 5 then break end -- 최대 5개까지만 표시 (스크롤 미구현)

            local itemY = startY + (i - 1) * itemHeight

            -- 매크로 이름
            listConfig.elements["macroName_" .. i] = {
                index = 10 + i * 3,
                type = "text",
                text = macro.name,
                textSize = 12,
                textColor = { white = 0.9 },
                frame = { x = 20, y = itemY, w = w - 80, h = 20 }
            }

            -- 재생 버튼 (텍스트로 대체)
            listConfig.elements["btnPlay_" .. i] = {
                index = 10 + i * 3 + 1,
                type = "text",
                text = "▶",
                textSize = 12,
                textColor = { red = 0.4, green = 0.8, blue = 0.4 },
                frame = { x = w - 60, y = itemY, w = 20, h = 20 },
                textAlignment = "center"
            }

            -- 삭제 버튼 (텍스트로 대체)
            listConfig.elements["btnDelete_" .. i] = {
                index = 10 + i * 3 + 2,
                type = "text",
                text = "x",
                textSize = 12,
                textColor = { red = 0.8, green = 0.4, blue = 0.4 },
                frame = { x = w - 35, y = itemY, w = 20, h = 20 },
                textAlignment = "center"
            }
        end
    end

    -- 렌더링
    MenuRenderer.render(c, listConfig, {})

    -- 이벤트 핸들러 설정
    menu.events = MenuEvents.new(obj, c, {
        onClick = function(id, cx, cy)
            -- 뒤로 가기
            if cx >= 15 and cx <= 65 and cy >= 10 and cy <= 35 then
                menu.show(obj)
                return true
            end

            -- 매크로 항목 클릭 처리
            for i, macro in ipairs(macros) do
                if i > 5 then break end
                local itemY = startY + (i - 1) * itemHeight

                -- 재생 버튼 영역
                if cx >= w - 65 and cx <= w - 40 and cy >= itemY and cy <= itemY + 20 then
                    menu.hide(obj)
                    obj.playback.play(obj, macro.name)
                    obj.overlay.update(obj)
                    return true
                end

                -- 삭제 버튼 영역
                if cx >= w - 40 and cx <= w - 15 and cy >= itemY and cy <= itemY + 20 then
                    local answer = hs.dialog.blockAlert("Delete Macro", "Delete '" .. macro.name .. "'?", "Delete",
                        "Cancel", "critical")
                    if answer == "Delete" then
                        obj.storage.deleteMacro(macro.name)
                        menu.showMacroList(obj) -- 목록 갱신
                    end
                    return true
                end
            end

            return false
        end,

        onPositionChanged = function(nx, ny)
            local cfg = obj.storage.loadConfig()
            cfg.menu.position.x = nx
            cfg.menu.position.y = ny
            cfg.menu.saved = true
            obj.storage.saveConfig(cfg)
        end
    })

    c:canvasMouseEvents(true, true, false, false)
end

-- 메뉴 숨기기
function menu.hide(obj)
    if obj.menuCanvas then
        obj.menuCanvas:delete()
        obj.menuCanvas = nil
    end
    if menu.events then
        menu.events:stop()
        menu.events = nil
    end
    obj.menuShowing = false
end

return menu
