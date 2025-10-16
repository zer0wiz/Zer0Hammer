-- SpoonSpace 키맵 정의
local keymaps = {}

-- 키맵 설정 함수
function keymaps.setup(spoonSpaceModal, modalManager, obj)
    -- Cheatsheet 토글
    spoonSpaceModal:bind('', 'tab', 'Toggle Cheatsheet', function() 
        modalManager:toggleCheatsheet() 
    end)
    
    -- Space 이동 키맵
    spoonSpaceModal:bind({ "alt", "shift" }, "1", "Move to space 1", function()
        obj:move_to_space(1)
    end)
    
    spoonSpaceModal:bind({ "alt", "shift" }, "2", "Move to space 2", function()
        obj:move_to_space(2)
    end)
    
    spoonSpaceModal:bind({ "alt", "shift" }, "3", "Move to space 3", function()
        obj:move_to_space(3)
    end)
    
    spoonSpaceModal:bind({ "alt", "shift" }, "4", "Move to space 4", function()
        obj:move_to_space(4)
    end)
    
    spoonSpaceModal:bind({ "alt", "shift" }, "5", "Move to space 5", function()
        obj:move_to_space(5)
    end)
    
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
    
    -- 정보 표시
    spoonSpaceModal:bind({ "cmd", "shift" }, "i", "Show Screen Spaces Info", function()
        obj:show_screen_spaces_info()
    end)
    
    -- 종료 키맵
    spoonSpaceModal:bind('', 'escape', 'Exit SpoonSpace', function() 
        modalManager:deactivate({ 'spoonSpace' }) 
    end)
end

-- Supervisor 키맵 설정 함수
function keymaps.setupSupervisor(modalManager, obj)
    modalManager.supervisor:bind('alt', 'o', 'Enter SpoonSpace', function()
        print("### spoonSpace Enter")
        
        -- 모니터 정보 출력
        obj:show_monitor_info()
        
        modalManager:deactivateAll()
        modalManager:activate({ 'spoonSpace' }, '#74BB67', nil, 'SpoonSpace Mode!')
    end)
end

return keymaps
