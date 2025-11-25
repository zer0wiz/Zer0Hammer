-- AutoHotKeys 단축키 미리보기 모듈
-- shortcut_preview: ctx 기준의 단축키 위치 확인용 overlay 객체
-- - menu에서 단축키별 마우스 위치 확인 및 추가시에 사용
-- - 오버레이에 단축키 목록의 각 항목이 표시됨
-- - 각 단축키의 위치에 원과 키 텍스트를 표시
local shortcut_preview = {}

local canvas = hs.canvas
local winmod = hs.window
local appmod = hs.application
local eventtap = hs.eventtap
local event = eventtap.event
local dialog = hs.dialog

-- 컬러 헥스를 RGB로 변환
local function hexToRGB(hex)
    hex = hex:gsub("#", "")
    local r = tonumber("0x" .. hex:sub(1, 2)) / 255.0
    local g = tonumber("0x" .. hex:sub(3, 4)) / 255.0
    local b = tonumber("0x" .. hex:sub(5, 6)) / 255.0
    return { red = r, green = g, blue = b }
end

-- 미리보기 레이어 표시
-- ctx 기준의 단축키 목록을 오버레이에 표시
-- menu에서 단축키 추가 시 호출되어 단축키별 마우스 위치 확인 및 추가에 사용됨
function shortcut_preview.show(obj, ctx)
    -- 이미 표시 중이면 숨김
    if obj.shortcutPreviewCanvas then
        shortcut_preview.hide(obj)
        return
    end

    -- 컨텍스트의 앱 윈도우 찾기 (메뉴에 표시된 앱)
    local win = nil
    if ctx and ctx.bundleId then
        local app = appmod.find(ctx.bundleId)
        if app then
            -- 앱의 메인 윈도우 또는 포커스된 윈도우 찾기
            local windows = app:allWindows()
            if #windows > 0 then
                -- 메인 윈도우 우선, 없으면 첫 번째 윈도우
                win = app:mainWindow() or windows[1]
            end
        end
    end

    -- 앱을 찾지 못한 경우 현재 포커스된 윈도우 사용
    if not win then
        win = winmod.frontmostWindow()
    end

    -- Hammerspoon이 포커스인 경우 실제 애플리케이션 찾기
    if win then
        local app = win:application()
        if app then
            local bundleId = app:bundleID()
            if bundleId == "org.hammerspoon.Hammerspoon" or bundleId == "com.hammerspoon.Hammerspoon" then
                -- Hammerspoon이 포커스인 경우, 이전 포커스된 앱 찾기
                local allWindows = winmod.orderedWindows()
                for i = 2, #allWindows do -- 첫 번째는 Hammerspoon이므로 두 번째부터
                    local prevWin = allWindows[i]
                    if prevWin then
                        local prevApp = prevWin:application()
                        if prevApp then
                            local prevBundleId = prevApp:bundleID()
                            if prevBundleId ~= "org.hammerspoon.Hammerspoon" and prevBundleId ~= "com.hammerspoon.Hammerspoon" then
                                win = prevWin
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if not win then
        hs.alert.show("활성화된 윈도우가 없습니다")
        return
    end

    local winFrame = win:frame()

    -- 윈도우 크기 캔버스 생성 (전체 화면이 아닌 현재 윈도우만)
    local c = canvas.new(winFrame)
    c:level(canvas.windowLevels.overlay)
    c:behavior(canvas.windowBehaviors.canJoinAllSpaces)

    -- Config 로드
    local config = obj.storage.loadConfig()
    local previewConfig = config.shortcutPreview

    -- 1. 그레이 오버레이 (윈도우 프레임 크기)
    local overlayColor = hexToRGB(previewConfig.overlay.color)
    c[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = {
            red = overlayColor.red,
            green = overlayColor.green,
            blue = overlayColor.blue,
            alpha = previewConfig.overlay.alpha
        },
        frame = { x = 0, y = 0, w = winFrame.w, h = winFrame.h }
    }

    -- 2. 앱별 설정 로드
    local appId = ctx.id
    local appConfig = obj.storage.loadAppConfig(appId)
    local shortcuts = appConfig and appConfig.shortcuts or {}

    -- 3. 각 단축키 위치에 원 그리기
    local circleConfig = previewConfig.circle
    local circleColor = hexToRGB(circleConfig.fillColor)
    local textConfig = previewConfig.text
    local textColor = hexToRGB(textConfig.color)

    local index = 2
    for key, shortcut in pairs(shortcuts) do
        if shortcut.type == "click" and shortcut.position then
            -- 윈도우 상대 좌표 사용 (캔버스가 윈도우 프레임 기준이므로)
            local relativeX = shortcut.position.dx
            local relativeY = shortcut.position.dy

            -- 원 그리기
            c[index] = {
                type = "circle",
                action = "strokeAndFill",
                fillColor = {
                    red = circleColor.red,
                    green = circleColor.green,
                    blue = circleColor.blue,
                    alpha = circleConfig.fillAlpha
                },
                strokeColor = hexToRGB(circleConfig.strokeColor),
                strokeWidth = circleConfig.strokeWidth,
                center = { x = relativeX, y = relativeY },
                radius = circleConfig.radius
            }

            -- 텍스트 그리기
            c[index + 1] = {
                type = "text",
                text = key,
                textSize = textConfig.size,
                textColor = textColor,
                textFont = textConfig.font,
                frame = {
                    x = relativeX - circleConfig.radius,
                    y = relativeY - circleConfig.radius,
                    w = circleConfig.radius * 2,
                    h = circleConfig.radius * 2
                },
                textAlignment = "center"
            }

            index = index + 2
        end
    end

    -- ESC 키로 닫기
    obj.shortcutPreviewEscapeKey = hs.hotkey.bind({}, "escape", function()
        shortcut_preview.hide(obj)
    end)

    -- 외부 클릭으로 닫기 (마우스 이벤트는 나중에 추가)

    c:show()
    obj.shortcutPreviewCanvas = c
    obj.shortcutPreviewContext = ctx
    obj.shortcutPreviewWindow = win

    -- ctrl+click 모드 활성화
    shortcut_preview.enableAddMode(obj)

    -- 포커스 아웃 감지
    obj.previewFocusWatcher = hs.window.filter.new()
        :setOverrideFilter {
            allowScreens = 'any',
            allowRoles = 'any'
        }
        :subscribe(hs.window.filter.windowFocused, function(_, _, _)
            -- 다른 윈도우로 포커스 이동 시 레이어 닫기
            shortcut_preview.hide(obj)
        end)
end

-- 미리보기 레이어 숨김
function shortcut_preview.hide(obj)
    if obj.previewFocusWatcher then
        obj.previewFocusWatcher:unsubscribeAll()
        obj.previewFocusWatcher = nil
    end

    if obj.shortcutPreviewCanvas then
        obj.shortcutPreviewCanvas:delete()
        obj.shortcutPreviewCanvas = nil
    end

    if obj.shortcutPreviewEscapeKey then
        obj.shortcutPreviewEscapeKey:delete()
        obj.shortcutPreviewEscapeKey = nil
    end

    if obj.shortcutPreviewMouseTap then
        obj.shortcutPreviewMouseTap:stop()
        obj.shortcutPreviewMouseTap = nil
    end

    if obj.shortcutPreviewKeyboardTap then
        obj.shortcutPreviewKeyboardTap:stop()
        obj.shortcutPreviewKeyboardTap = nil
    end

    if obj.shortcutPreviewMessageModal then
        obj.shortcutPreviewMessageModal:delete()
        obj.shortcutPreviewMessageModal = nil
    end

    obj.shortcutPreviewContext = nil
    obj.shortcutPreviewWindow = nil
end

-- 메시지 모달 생성 (SpoonSpace 스타일)
local function createMessageModal(screen, message)
    local screenFrame = screen:fullFrame()
    local modalWidth = 400
    local modalHeight = 120
    local modalX = screenFrame.x + (screenFrame.w - modalWidth) / 2
    local modalY = screenFrame.y + (screenFrame.h - modalHeight) / 2

    local modal = canvas.new({
        x = modalX,
        y = modalY,
        w = modalWidth,
        h = modalHeight
    })

    modal:level(canvas.windowLevels.floating)
    modal:behavior(canvas.windowBehaviors.canJoinAllSpaces)

    -- 배경
    modal[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0.1, green = 0.1, blue = 0.1, alpha = 0.9 },
        roundedRectRadii = { xRadius = 15, yRadius = 15 }
    }

    -- 테두리
    modal[2] = {
        type = "rectangle",
        action = "stroke",
        strokeColor = { white = 1.0, alpha = 1.0 },
        strokeWidth = 2,
        roundedRectRadii = { xRadius = 15, yRadius = 15 }
    }

    -- 메시지 텍스트
    modal[3] = {
        type = "text",
        text = message,
        textFont = "Helvetica-Bold",
        textSize = 18,
        textColor = { white = 1.0, alpha = 1.0 },
        textAlignment = "center",
        frame = {
            x = 20,
            y = 20,
            w = modalWidth - 40,
            h = modalHeight - 40
        }
    }

    return modal
end

-- 키보드 이벤트 캡처로 단축키 입력 받기
local function waitForKeyInput(obj, relativePos)
    local ctx = obj.shortcutPreviewContext
    local win = obj.shortcutPreviewWindow
    if not win or not ctx then return end

    -- 메시지 모달 표시
    local screen = win:screen()
    local messageModal = createMessageModal(screen, "단축키를 입력하세요...")
    messageModal:show()

    -- 키 상태 추적
    local pressedKeys = {}
    local modifiers = {}
    local keyCode = nil
    local keyChar = nil
    local keyboardTap = nil -- 먼저 선언

    -- 키보드 이벤트 캡처
    keyboardTap = eventtap.new({
        event.types.keyDown,
        event.types.keyUp,
        event.types.flagsChanged
    }, function(e)
        local eventType = e:getType()

        if eventType == event.types.keyDown then
            local code = e:getKeyCode()
            local chars = e:getCharacters()

            -- ESC 키로 취소
            if code == 53 then -- ESC key code
                messageModal:delete()
                keyboardTap:stop()
                obj.shortcutPreviewKeyboardTap = nil
                obj.shortcutPreviewMessageModal = nil
                return true
            end

            -- 수정자 키가 아닌 일반 키
            if chars and chars ~= "" then
                keyCode = code
                keyChar = chars:lower()
                pressedKeys[code] = true

                -- 현재 수정자 키 상태 저장
                local flags = e:getFlags()
                modifiers = {}
                if flags.ctrl then table.insert(modifiers, "ctrl") end
                if flags.cmd then table.insert(modifiers, "cmd") end
                if flags.shift then table.insert(modifiers, "shift") end
                if flags.alt then table.insert(modifiers, "alt") end

                -- 단축키가 눌렸을 때 메시지 모달 닫기 (저장은 키 업에서 처리)
                messageModal:delete()
                obj.shortcutPreviewMessageModal = nil
            end
        elseif eventType == event.types.keyUp then
            local code = e:getKeyCode()

            -- ESC 키로 취소
            if code == 53 then -- ESC key code
                messageModal:delete()
                keyboardTap:stop()
                obj.shortcutPreviewKeyboardTap = nil
                obj.shortcutPreviewMessageModal = nil
                return true
            end

            -- 키가 떼어짐
            if pressedKeys[code] then
                pressedKeys[code] = nil

                -- 모든 키가 떼어졌는지 확인
                local allReleased = true
                for _, _ in pairs(pressedKeys) do
                    allReleased = false
                    break
                end

                if allReleased and keyCode and keyChar then
                    -- 단축키 저장
                    local appId = ctx.id
                    local shortcutData = {
                        type = "click",
                        position = relativePos,
                        windowRelative = true,
                        modifiers = modifiers,
                        keyCode = keyCode
                    }

                    obj.storage.saveAppShortcut(appId, ctx.type, keyChar, relativePos, ctx.appName, ctx.bundleId,
                        shortcutData)

                    -- Alert 표시
                    local modStr = #modifiers > 0 and (table.concat(modifiers, "+") .. "+") or ""
                    hs.alert.show(string.format("단축키 '%s%s'가 저장되었습니다", modStr, keyChar), 2.0)

                    -- 메시지 모달 닫기
                    messageModal:delete()
                    keyboardTap:stop()
                    obj.shortcutPreviewKeyboardTap = nil
                    obj.shortcutPreviewMessageModal = nil

                    -- 미리보기 다시 표시
                    shortcut_preview.hide(obj)
                    hs.timer.doAfter(0.1, function()
                        shortcut_preview.show(obj, ctx)
                    end)

                    return true
                end
            end
        elseif eventType == event.types.flagsChanged then
            -- 수정자 키 상태 변경
            local flags = e:getFlags()
            modifiers = {}
            if flags.ctrl then table.insert(modifiers, "ctrl") end
            if flags.cmd then table.insert(modifiers, "cmd") end
            if flags.shift then table.insert(modifiers, "shift") end
            if flags.alt then table.insert(modifiers, "alt") end
        end

        return false
    end)

    keyboardTap:start()
    obj.shortcutPreviewKeyboardTap = keyboardTap
    obj.shortcutPreviewMessageModal = messageModal
end

-- 단축키 추가 모드 활성화
function shortcut_preview.enableAddMode(obj)
    if obj.shortcutPreviewMouseTap then
        obj.shortcutPreviewMouseTap:stop()
    end

    obj.shortcutPreviewMouseTap = eventtap.new({
        event.types.leftMouseDown
    }, function(e)
        local flags = e:getFlags()
        if not flags.ctrl then
            return false -- 이벤트 소비하지 않음
        end

        -- ctrl+click 감지
        local position = e:location()
        local win = obj.shortcutPreviewWindow
        if not win then return false end

        local winFrame = win:frame()

        -- 윈도우 내부인지 확인
        if position.x < winFrame.x or position.x > winFrame.x + winFrame.w or
            position.y < winFrame.y or position.y > winFrame.y + winFrame.h then
            -- 외부 클릭이면 레이어 닫기
            shortcut_preview.hide(obj)
            return false
        end

        -- 상대 좌표 계산
        local relativePos = {
            dx = position.x - winFrame.x,
            dy = position.y - winFrame.y
        }

        -- 키보드 입력 대기
        waitForKeyInput(obj, relativePos)

        return true -- 이벤트 소비
    end)

    obj.shortcutPreviewMouseTap:start()
end

return shortcut_preview
