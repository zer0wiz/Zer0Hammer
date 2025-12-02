-- SpoonSpace 키맵 정의
local keymaps = {}
local webview = loadModule("webview")

-- 키맵 설정 함수
function keymaps.setup(spoonSpaceModal, modalManager, obj)
    -- Cheatsheet 토글
    spoonSpaceModal:bind('', 'tab', 'Toggle Cheatsheet', function() 
        modalManager:toggleCheatsheet() 
    end)
    
    -- -- Space 이동 키맵
    -- spoonSpaceModal:bind({ "alt", "shift" }, "1", "Move to space 1", function()
    --     obj:move_to_space(1)
    -- end)
    
    -- spoonSpaceModal:bind({ "alt", "shift" }, "2", "Move to space 2", function()
    --     obj:move_to_space(2)
    -- end)
    
    -- spoonSpaceModal:bind({ "alt", "shift" }, "3", "Move to space 3", function()
    --     obj:move_to_space(3)
    -- end)
    
    -- spoonSpaceModal:bind({ "alt", "shift" }, "4", "Move to space 4", function()
    --     obj:move_to_space(4)
    -- end)
    
    -- spoonSpaceModal:bind({ "alt", "shift" }, "5", "Move to space 5", function()
    --     obj:move_to_space(5)
    -- end)
    
    -- 고급 Space 이동 기능들
    spoonSpaceModal:bind({ "cmd", "shift" }, "1", "Move to Screen 1 Space 1", function()
        obj:move_to_screen_space(1, 1)
    end)
    
    spoonSpaceModal:bind({ "cmd", "shift" }, "2", "Move to Screen 2 Space 1", function()
        obj:move_to_screen_space(2, 1)
    end)
    
    spoonSpaceModal:bind({ "cmd", "shift" }, "3", "Move to Screen 3 Space 1", function()
        obj:move_to_screen_space(3, 1)
    end)
    
    spoonSpaceModal:bind({ "cmd", "shift" }, "4", "Move to Screen 1 Space 2", function()
        obj:move_to_screen_space(1, 2)
    end)
    
    spoonSpaceModal:bind({ "cmd", "shift" }, "5", "Move to Screen 2 Space 2", function()
        obj:move_to_screen_space(2, 2)
    end)
    
    -- 앱별 이동 기능
    spoonSpaceModal:bind({ "cmd", "alt" }, "c", "Move Chrome to Screen 1", function()
        obj:move_app_to_screen_space("Google Chrome", 1, 1)
    end)
    
    spoonSpaceModal:bind({ "cmd", "alt" }, "s", "Move Safari to Screen 2", function()
        obj:move_app_to_screen_space("Safari", 2, 1)
    end)
    
    -- 정보 표시 기능들
    spoonSpaceModal:bind({ "cmd", "shift" }, "s", "Show Screen Info (WebView)", function()
        webview.showScreenInfo()
    end)
    
    spoonSpaceModal:bind({ "cmd", "shift" }, "p", "Show Space Info (WebView)", function()
        webview.showSpaceInfo()
    end)
    
    spoonSpaceModal:bind({ "cmd", "shift" }, "w", "Show Window Info (WebView)", function()
        webview.showWindowInfo()
    end)
    
    -- 커스텀 데이터 표시 예시
    spoonSpaceModal:bind({ "cmd", "alt" }, "i", "Show Monitor Info (WebView)", function()
        local info = {}
        table.insert(info, "=== Monitor Information ===")
        table.insert(info, "")
        obj:show_monitor_info()
        -- show_monitor_info는 print로 출력하므로 콘솔에서 확인
        webview.showCustomData("Monitor Info", "Check console for detailed monitor information")
    end)
    
    -- 알림 테스트 기능들
    spoonSpaceModal:bind({ "cmd", "alt" }, "n", "Test Notification Main Screen", function()
        modalManager.notification_modal("메인 화면 알림 테스트", nil, 2.0)
    end)
    
    spoonSpaceModal:bind({ "cmd", "alt" }, "a", "Test Notification All Screens", function()
        modalManager.notification_all_screens("모든 화면 알림 테스트", 2.0)
    end)
    
    spoonSpaceModal:bind({ "cmd", "alt" }, "1", "Test Notification Screen 1", function()
        local screens = hs.screen.allScreens()
        if screens[1] then
            modalManager.notification_modal("화면 1 알림 테스트", screens[1]:id(), 2.0)
        end
    end)
    
    spoonSpaceModal:bind({ "cmd", "alt" }, "2", "Test Notification Screen 2", function()
        local screens = hs.screen.allScreens()
        if screens[2] then
            modalManager.notification_modal("화면 2 알림 테스트", screens[2]:id(), 2.0)
        end
    end)
    
    spoonSpaceModal:bind({ "cmd", "alt" }, "h", "Test Simple Alert", function()
        modalManager.alert_modal("간단한 알림 테스트", 2.0)
    end)
    
    spoonSpaceModal:bind({ "cmd", "alt" }, "d", "Show Screen IDs", function()
        modalManager.show_screen_ids(3.0)
    end)
    
    -- 알림 숨기기 기능들
    spoonSpaceModal:bind({ "cmd", "alt" }, "x", "Hide All Notifications", function()
        modalManager.hide_all_notifications()
    end)
    
    spoonSpaceModal:bind({ "cmd", "alt" }, "q", "Hide Screen 1 Notification", function()
        local screens = hs.screen.allScreens()
        if screens[1] then
            modalManager.hide_notification(screens[1]:id())
        end
    end)
    
    spoonSpaceModal:bind({ "cmd", "alt" }, "w", "Hide Screen 2 Notification", function()
        local screens = hs.screen.allScreens()
        if screens[2] then
            modalManager.hide_notification(screens[2]:id())
        end
    end)
    
    spoonSpaceModal:bind({ "cmd", "alt" }, "s", "Check Notification Status", function()
        local visibleNotifications = modalManager.get_visible_notifications()
        print("현재 표시 중인 알림:", #visibleNotifications, "개")
        for _, screenId in ipairs(visibleNotifications) do
            print("  - Screen ID:", screenId)
        end
    end)
    
    -- 종료 키맵
    spoonSpaceModal:bind('', 'escape', 'Exit SpoonSpace', function() 
        modalManager.hide_all_notifications()
        modalManager:deactivateAll()
    end)
end

-- Supervisor 키맵 설정 함수
function keymaps.setupSupervisor(modalManager, obj)
    modalManager.supervisor:bind('alt', 'o', 'Enter SpoonSpace', function()
        print("### spoonSpace Enter")
        
        -- 모니터 정보 출력
        obj:show_monitor_info()
        
        -- 모든 화면에 Screen ID 표시
        modalManager.show_screen_ids()
        
        modalManager:deactivateAll()
        modalManager:activate({ 'spoonSpace' }, '#74BB67', nil, 'SpoonSpace Mode!')
    end)
end

return keymaps
