--- KeysWithKeyChain.spoon
--- 키 체인 기능과 함께 키 조합을 관리하는 스푼
--- @author Aaron Lee
--- @copyright 2025

local KeysWithKeyChain = {}

-- 메타 테이블 설정
KeysWithKeyChain.__index = KeysWithKeyChain

-- 기본 설정
local defaultConfig = {
    -- 설정 옵션들이 여기에 들어갑니다
    enabled = true,
    keyChainDelay = 0.5, -- 키 체인 지연 시간 (초)
}

-- 생성자
function KeysWithKeyChain:new(config)
    local instance = setmetatable({}, self)
    
    -- 설정 병합
    instance.config = {}
    for key, value in pairs(defaultConfig) do
        instance.config[key] = config and config[key] or value
    end
    
    -- 내부 상태 초기화
    instance.isEnabled = instance.config.enabled
    instance.keyChain = {}
    instance.keyChainTimer = nil
    
    return instance
end

-- 스푼 시작
function KeysWithKeyChain:start()
    if not self.isEnabled then
        return false
    end
    
    -- 시작 로직 구현
    print("KeysWithKeyChain 스푼이 시작되었습니다")
    
    return true
end

-- 스푼 중지
function KeysWithKeyChain:stop()
    -- 키 체인 타이머 정리
    if self.keyChainTimer then
        self.keyChainTimer:stop()
        self.keyChainTimer = nil
    end
    
    -- 키 체인 초기화
    self.keyChain = {}
    
    print("KeysWithKeyChain 스푼이 중지되었습니다")
end

-- 설정 업데이트
function KeysWithKeyChain:updateConfig(newConfig)
    for key, value in pairs(newConfig) do
        self.config[key] = value
    end
end

-- 키 체인에 키 추가
function KeysWithKeyChain:addToKeyChain(key)
    table.insert(self.keyChain, key)
    
    -- 기존 타이머 재설정
    if self.keyChainTimer then
        self.keyChainTimer:stop()
    end
    
    -- 지연 후 키 체인 실행
    self.keyChainTimer = hs.timer.doAfter(self.config.keyChainDelay, function()
        self:executeKeyChain()
    end)
end

-- 키 체인 실행
function KeysWithKeyChain:executeKeyChain()
    -- TODO: 키 체인 실행 로직 구현
    print("키 체인 실행:", table.concat(self.keyChain, " + "))
    
    -- 키 체인 초기화
    self.keyChain = {}
end

-- 스푼 정보 반환
function KeysWithKeyChain:getInfo()
    return {
        name = "KeysWithKeyChain",
        version = "1.0.0",
        enabled = self.isEnabled,
        config = self.config,
        keyChain = self.keyChain
    }
end

return KeysWithKeyChain












