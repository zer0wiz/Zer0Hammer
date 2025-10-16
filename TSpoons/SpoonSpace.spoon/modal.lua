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

-- Modal 초기화 및 설정
function modal.init(modalManager, obj)
    -- ModalMgr 확장 기능들 추가
    modal.extensions.addSpaceMovement(modalManager, obj)
    modal.extensions.addDebugging(modalManager)
    modal.extensions.addUtilities(modalManager)
    
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
