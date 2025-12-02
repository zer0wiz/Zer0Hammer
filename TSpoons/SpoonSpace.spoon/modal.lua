-- SpoonSpace Modal 관리 모듈
local modal = {}

-- ModalMgr 확장 기능들
modal.extensions = {}

-- ModalMgr에 새로운 기능 추가
function modal.extensions.addSpaceMovement(modalManager, obj)
    -- Space 이동 기능을 ModalMgr에 추가
    modalManager.moveToSpace = function(spaceNumber)
        return obj:move_to_space(spaceNumber)
    end
    
    modalManager.moveToScreenSpace = function(screenIndex, spaceIndex)
        return obj:move_to_screen_space(screenIndex, spaceIndex)
    end
    
    modalManager.moveAppToScreenSpace = function(appName, screenIndex, spaceIndex)
        return obj:move_app_to_screen_space(appName, screenIndex, spaceIndex)
    end
    
    modalManager.showScreenSpacesInfo = function()
        return obj:show_screen_spaces_info()
    end
    
    modalManager.showMonitorInfo = function()
        return obj:show_monitor_info()
    end
end

-- ModalMgr에 디버깅 기능 추가
function modal.extensions.addDebugging(modalManager)
    modalManager.debugInfo = function()
        print("=== ModalMgr Debug Info ===")
        print("Modal List:", hs.inspect(modalManager.modal_list))
        print("Active List:", hs.inspect(modalManager.active_list))
        print("Supervisor:", modalManager.supervisor)
        print("==========================")
    end
    
    modalManager.getActiveModals = function()
        local activeModals = {}
        for name, modal in pairs(modalManager.active_list) do
            table.insert(activeModals, name)
        end
        return activeModals
    end
end

-- ModalMgr에 유틸리티 기능 추가
function modal.extensions.addUtilities(modalManager)
    modalManager.isModalActive = function(modalName)
        return modalManager.active_list[modalName] ~= nil
    end
    
    modalManager.getModalCount = function()
        local count = 0
        for _ in pairs(modalManager.modal_list) do
            count = count + 1
        end
        return count
    end
    
    modalManager.listAllModals = function()
        local modals = {}
        for name, _ in pairs(modalManager.modal_list) do
            table.insert(modals, name)
        end
        return modals
    end
end

-- 커스텀 알림 트레이 생성 함수 (ModalMgr의 toggleInfoModalTray 기반)
local function createNotificationTray(screen, trayColor, text)
    local cres = screen:fullFrame()
    -- tray 설정
    local tray_width = 500
    local tray_height = 200
    local tray_padding_top = 200
    local tray_padding_left = 0
    local tray_alpha = 0.9
    local tray_color = trayColor or "#74BB67"
    local tray_margin_top = 0
    local tray_margin_left = 0
    local font_size = 20

    -- 트레이 프레임 설정
    local trayFrame = {
        w = tray_width,
        h = tray_height,
        x = cres.x + tray_padding_left + ((cres.w - tray_width) / 2),
        y = cres.y + tray_padding_top
    }

    -- 캔버스 생성
    local tray = hs.canvas.new(trayFrame)
    tray:level(hs.canvas.windowLevels.floating)
    
    -- 배경
    tray[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = {hex = tray_color, alpha = tray_alpha},
        roundedRectRadii = {xRadius = 15, yRadius = 15}
    }
    
    -- 테두리
    tray[2] = {
        type = "rectangle",
        action = "stroke",
        strokeColor = {hex = "#FFFFFF", alpha = 1.0},
        strokeWidth = 2,
        roundedRectRadii = {xRadius = 15, yRadius = 15}
    }
    
    -- 텍스트
    tray[3] = {
        type = "text",
        text = text,
        textFont = "Helvetica-Bold",
        textSize = font_size,
        textColor = {hex = "#FFFFFF", alpha = 1.0},
        textAlignment = "center",
        frame = {
            x = tray_margin_left + 20,
            y = tray_margin_top + ((tray_height - (font_size * 1.2)) / 2),
            w = tray_width - 40,
            h = tray_height - 20
        }
    }
    
    return tray
end

-- ModalMgr에 알림 기능 추가
function modal.extensions.addNotification(modalManager)
    -- 알림 트레이 리스트 초기화
    modalManager.notification_modal_list = {}
    
    -- 지정된 화면에 알림 표시
    modalManager.notification_modal = function(message, targetScreenId, duration)
        duration = duration or 3.0
        
        local screens = hs.screen.allScreens()
        local targetScreen = nil
        
        -- targetScreenId가 지정된 경우 해당 화면 찾기
        if targetScreenId then
            for _, screen in ipairs(screens) do
                if screen:id() == targetScreenId then
                    targetScreen = screen
                    break
                end
            end
        else
            -- 지정되지 않은 경우 메인 화면 사용
            targetScreen = hs.screen.mainScreen()
        end
        
        if not targetScreen then
            print("Error: 지정된 화면을 찾을 수 없습니다")
            return false
        end
        
        -- 해당 화면의 트레이 가져오기
        local screenId = targetScreen:id()
        local tray = modalManager.notification_modal_list[screenId]
        
        if tray then
            -- 기존 트레이의 텍스트 업데이트
            tray[3].text = message
            tray:show()
            
            -- 지정된 시간 후 자동 숨김
            if duration then
                hs.timer.doAfter(duration, function()
                    tray:hide()
                end)
            end
        end
        
        print(string.format("알림 표시: '%s' (화면: %s, 지속시간: %.1f초)", 
              message, targetScreen:name(), duration or 0))
        
        return true
    end
    
    -- 모든 화면에 알림 표시
    modalManager.notification_all_screens = function(message, duration)
        duration = duration or 3.0
        local screens = hs.screen.allScreens()
        
        -- 모든 화면에 동시에 알림 표시
        for i, screen in ipairs(screens) do
            local screenId = screen:id()
            local tray = modalManager.notification_modal_list[screenId]
            
            if tray then
                tray[3].text = message
                tray:show()
            end
        end
        
        -- 모든 알림을 지정된 시간 후 숨김
        if duration then
            hs.timer.doAfter(duration, function()
                for _, tray in pairs(modalManager.notification_modal_list) do
                    tray:hide()
                end
            end)
        end
        
        print(string.format("모든 화면에 알림 표시: '%s' (%d개 화면, 지속시간: %.1f초)", 
              message, #screens, duration or 0))
        
        return true
    end
    
    -- 간단한 텍스트 알림 (hs.alert 사용)
    modalManager.alert_modal = function(message, duration)
        duration = duration or 2.0
        hs.alert.show(message, duration)
        print(string.format("간단 알림: '%s' (지속시간: %.1f초)", message, duration))
        return true
    end
    
    -- 모든 화면에 Screen ID 표시
    modalManager.show_screen_ids = function(duration)
        local screens = hs.screen.allScreens()
        
        for i, screen in ipairs(screens) do
            local screenId = screen:id()
            local screenName = screen:name()
            local message = string.format("Screen %d\n%s\nID: %s", i, screenName, screenId)
            
            -- 해당 화면의 트레이에 메시지 표시
            local tray = modalManager.notification_modal_list[screenId]
            if tray then
                tray[3].text = message
                tray:show()
            end
        end
        
        -- 모든 알림을 지정된 시간 후 숨김
        if duration then
            hs.timer.doAfter(duration, function()
                for _, tray in pairs(modalManager.notification_modal_list) do
                    tray:hide()
                end
            end)
        end
        
        print(string.format("모든 화면에 Screen ID 표시 (%d개 화면, 지속시간: %.1f초)", #screens, duration or 0))
        return true
    end
    
    -- 알림 트레이 초기화 (모든 화면에 대해)
    modalManager.init_notification_trays = function()
        local screens = hs.screen.allScreens()
        
        for i, screen in ipairs(screens) do
            local screenId = screen:id()
            local screenName = screen:name()
            local initialMessage = string.format("Screen %d\n%s\nID: %s", i, screenName, screenId)
            
            -- 각 화면에 대한 트레이 생성
            local tray = createNotificationTray(screen, "#74BB67", initialMessage)
            tray:hide()  -- 초기에는 숨김 상태
            
            modalManager.notification_modal_list[screenId] = tray
            print(string.format("알림 트레이 생성: Screen %d (%s)", i, screenName))
        end
        
        print(string.format("총 %d개 알림 트레이 초기화 완료", #screens))
    end
    
    -- 특정 화면의 알림 숨기기
    modalManager.hide_notification = function(targetScreenId)
        local screens = hs.screen.allScreens()
        local targetScreen = nil
        
        -- targetScreenId가 지정된 경우 해당 화면 찾기
        if targetScreenId then
            for _, screen in ipairs(screens) do
                if screen:id() == targetScreenId then
                    targetScreen = screen
                    break
                end
            end
        else
            -- 지정되지 않은 경우 메인 화면 사용
            targetScreen = hs.screen.mainScreen()
        end
        
        if not targetScreen then
            print("Error: 지정된 화면을 찾을 수 없습니다")
            return false
        end
        
        -- 해당 화면의 트레이 숨기기
        local screenId = targetScreen:id()
        local tray = modalManager.notification_modal_list[screenId]
        
        if tray then
            tray:hide()
            print(string.format("알림 숨김: 화면 %s", targetScreen:name()))
            return true
        else
            print("Error: 해당 화면의 알림 트레이를 찾을 수 없습니다")
            return false
        end
    end
    
    -- 모든 화면의 알림 숨기기
    modalManager.hide_all_notifications = function()
        local hiddenCount = 0
        
        for screenId, tray in pairs(modalManager.notification_modal_list) do
            if tray then
                tray:hide()
                hiddenCount = hiddenCount + 1
            end
        end
        
        print(string.format("모든 알림 숨김 완료: %d개 화면", hiddenCount))
        return hiddenCount > 0
    end
    
    -- 알림 상태 확인
    modalManager.is_notification_visible = function(targetScreenId)
        local screens = hs.screen.allScreens()
        local targetScreen = nil
        
        -- targetScreenId가 지정된 경우 해당 화면 찾기
        if targetScreenId then
            for _, screen in ipairs(screens) do
                if screen:id() == targetScreenId then
                    targetScreen = screen
                    break
                end
            end
        else
            -- 지정되지 않은 경우 메인 화면 사용
            targetScreen = hs.screen.mainScreen()
        end
        
        if not targetScreen then
            return false
        end
        
        local screenId = targetScreen:id()
        local tray = modalManager.notification_modal_list[screenId]
        
        if tray then
            return tray:isShowing()
        end
        
        return false
    end
    
    -- 모든 알림 상태 확인
    modalManager.get_visible_notifications = function()
        local visibleNotifications = {}
        
        for screenId, tray in pairs(modalManager.notification_modal_list) do
            if tray and tray:isShowing() then
                table.insert(visibleNotifications, screenId)
            end
        end
        
        return visibleNotifications
    end
end

-- Modal 초기화 및 설정
function modal.init(modalManager, obj)
    -- ModalMgr 확장 기능들 추가
    modal.extensions.addSpaceMovement(modalManager, obj)
    modal.extensions.addDebugging(modalManager)
    modal.extensions.addUtilities(modalManager)
    modal.extensions.addNotification(modalManager)
    
    -- 알림 트레이 초기화
    modalManager.init_notification_trays()
    
    -- 모니터 개수만큼 모달 생성
    local screens = hs.screen.allScreens()
    for i, screen in ipairs(screens) do
        local modalName = "spaceSpoon_screen_" .. screen:id()
        modalManager:new(modalName)
        print(string.format("모니터 %d 모달 생성: %s", i, modalName))
    end
    dbg(modalManager)
    
    print("SpoonSpace Modal 초기화 완료")
    print("사용 가능한 확장 기능:")
    print("- moveToSpace(spaceNumber)")
    print("- moveToScreenSpace(screenIndex, spaceIndex)")
    print("- moveAppToScreenSpace(appName, screenIndex, spaceIndex)")
    print("- showScreenSpacesInfo()")
    print("- showMonitorInfo()")
    print("- debugInfo()")
    print("- getActiveModals()")
    print("- isModalActive(modalName)")
    print("- getModalCount()")
    print("- listAllModals()")
    print("- notification_modal(message, screenId, duration)")
    print("- notification_all_screens(message, duration)")
    print("- show_screen_ids(duration)")
    print("- hide_notification(screenId)")
    print("- hide_all_notifications()")
    print("- is_notification_visible(screenId)")
    print("- get_visible_notifications()")
    print("- init_notification_trays()")
    print(string.format("총 %d개 모니터 모달 생성됨", #screens))
end

-- Modal 생성 및 설정
function modal.create(modalManager, modalName)
    modalManager:new(modalName)
    
    return modalManager.modal_list[modalName]
end

-- Modal 활성화 래퍼
function modal.activate(modalManager, modalName, color, showKeys, text)
    modalManager:activate({modalName}, color, showKeys, text)
end

-- Modal 비활성화 래퍼
function modal.deactivate(modalManager, modalName)
    modalManager:deactivate({modalName})
end

return modal
