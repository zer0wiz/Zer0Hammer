-- AutoHotKeys 마우스 위치 관리 모듈
local mouse = {}

local winmod = hs.window
local screenmod = hs.screen

-- 좌표 변환: 상대 → 절대
local function convertToAbsolute(relativePosition, windowFrame)
    return {
        x = windowFrame.x + relativePosition.dx,
        y = windowFrame.y + relativePosition.dy
    }
end

-- 좌표 변환: 절대 → 상대
local function convertToRelative(absolutePosition, windowFrame)
    return {
        dx = absolutePosition.x - windowFrame.x,
        dy = absolutePosition.y - windowFrame.y
    }
end

-- 화면 해상도 변경 시 좌표 조정
local function scalePosition(position, originalScreen, currentScreen)
    if not originalScreen or not currentScreen then
        return position
    end
    
    local origFrame = originalScreen:frame()
    local currFrame = currentScreen:frame()
    
    local scaleX = origFrame.w > 0 and currFrame.w / origFrame.w or 1.0
    local scaleY = origFrame.h > 0 and currFrame.h / origFrame.h or 1.0
    
    return {
        x = position.x * scaleX,
        y = position.y * scaleY
    }
end

-- 위치 저장
function mouse.savePosition(obj, name, options)
    options = options or {}
    
    local win = winmod.frontmostWindow()
    if not win then
        return false, "활성 윈도우가 없습니다"
    end
    
    local position = options.position or hs.mouse.absolutePosition()
    local winFrame = win:frame()
    local winApp = win:application()
    
    local screen = win:screen()
    local screenFrame = screen:frame()
    
    local positionData = {
        name = name,
        type = options.type or "relative",  -- "relative" or "absolute"
        position = {x = position.x, y = position.y},
        relativePosition = convertToRelative(position, winFrame),
        window = {
            app = winApp:name(),
            bundleId = winApp:bundleID(),
            title = win:title(),
            frame = {x = winFrame.x, y = winFrame.y, w = winFrame.w, h = winFrame.h}
        },
        screen = {
            id = screen:id(),
            frame = {x = screenFrame.x, y = screenFrame.y, w = screenFrame.w, h = screenFrame.h}
        },
        createdAt = os.time(),
        tags = options.tags or {},
        description = options.description or ""
    }
    
    -- 위치 저장
    local positions = obj.storage.loadPositions() or {}
    positions[name] = positionData
    
    if obj.storage.savePositions(positions) then
        return true, positionData
    else
        return false, "위치 저장 실패"
    end
end

-- 위치 가져오기
function mouse.getPosition(obj, name)
    local positions = obj.storage.loadPositions()
    if not positions or not positions[name] then
        return nil
    end
    
    local posData = positions[name]
    
    -- 현재 화면 정보 가져오기
    local currentScreen = screenmod.primaryScreen()
    if posData.screen and posData.screen.id then
        -- 원본 화면 찾기 시도
        for _, screen in ipairs(screenmod.allScreens()) do
            if screen:id() == posData.screen.id then
                currentScreen = screen
                break
            end
        end
    end
    
    -- 좌표 조정 (화면 해상도 변경 대응)
    local adjustedPosition = scalePosition(posData.position, 
        posData.screen and (function()
            for _, screen in ipairs(screenmod.allScreens()) do
                if screen:id() == posData.screen.id then
                    return screen
                end
            end
            return nil
        end)(),
        currentScreen)
    
    -- 윈도우 기준 좌표로 변환
    if posData.type == "relative" then
        local win = winmod.frontmostWindow()
        if win and win:application():name() == posData.window.app then
            local frame = win:frame()
            -- 상대 좌표 스케일링
            local scaleX = posData.window.frame.w > 0 and frame.w / posData.window.frame.w or 1.0
            local scaleY = posData.window.frame.h > 0 and frame.h / posData.window.frame.h or 1.0
            
            return {
                x = frame.x + (posData.relativePosition.dx * scaleX),
                y = frame.y + (posData.relativePosition.dy * scaleY)
            }
        else
            -- 윈도우를 찾을 수 없으면 절대 좌표 반환
            return adjustedPosition
        end
    else
        -- 절대 좌표
        return adjustedPosition
    end
end

-- 위치 목록
function mouse.listPositions(obj)
    local positions = obj.storage.loadPositions()
    if not positions then
        return {}
    end
    
    local result = {}
    for name, data in pairs(positions) do
        table.insert(result, {
            name = name,
            data = data
        })
    end
    
    -- 이름순 정렬
    table.sort(result, function(a, b)
        return a.name < b.name
    end)
    
    return result
end

-- 위치 삭제
function mouse.deletePosition(obj, name)
    local positions = obj.storage.loadPositions()
    if not positions or not positions[name] then
        return false
    end
    
    positions[name] = nil
    
    return obj.storage.savePositions(positions)
end

-- 위치 업데이트
function mouse.updatePosition(obj, name, options)
    local positions = obj.storage.loadPositions()
    if not positions or not positions[name] then
        return false, "위치를 찾을 수 없습니다"
    end
    
    local positionData = positions[name]
    
    -- 옵션 업데이트
    if options.position then
        positionData.position = options.position
        if positionData.window then
            local win = winmod.frontmostWindow()
            if win then
                local frame = win:frame()
                positionData.relativePosition = convertToRelative(options.position, frame)
            end
        end
    end
    
    if options.type then
        positionData.type = options.type
    end
    
    if options.tags then
        positionData.tags = options.tags
    end
    
    if options.description then
        positionData.description = options.description
    end
    
    positions[name] = positionData
    
    if obj.storage.savePositions(positions) then
        return true, positionData
    else
        return false, "위치 업데이트 실패"
    end
end

-- 상대 좌표 → 절대 좌표 변환
function mouse.convertToAbsolute(obj, name)
    local positions = obj.storage.loadPositions()
    if not positions or not positions[name] then
        return nil
    end
    
    local posData = positions[name]
    
    if posData.type == "absolute" then
        return posData.position
    end
    
    -- 상대 좌표를 절대 좌표로 변환
    if posData.window and posData.relativePosition then
        -- 원본 윈도우 프레임 사용
        local absPos = convertToAbsolute(posData.relativePosition, posData.window.frame)
        return absPos
    end
    
    return posData.position
end

-- 절대 좌표 → 상대 좌표 변환
function mouse.convertToRelative(obj, name, window)
    local positions = obj.storage.loadPositions()
    if not positions or not positions[name] then
        return nil
    end
    
    local posData = positions[name]
    local win = window or winmod.frontmostWindow()
    
    if not win then
        return nil
    end
    
    local frame = win:frame()
    local absPos = posData.position
    
    if posData.type == "relative" and posData.relativePosition then
        -- 이미 상대 좌표인 경우
        return posData.relativePosition
    end
    
    -- 절대 좌표를 상대 좌표로 변환
    return convertToRelative(absPos, frame)
end

-- 태그로 위치 검색
function mouse.findByTag(obj, tag)
    local positions = mouse.listPositions(obj)
    local result = {}
    
    for _, item in ipairs(positions) do
        if item.data.tags then
            for _, t in ipairs(item.data.tags) do
                if t == tag then
                    table.insert(result, item)
                    break
                end
            end
        end
    end
    
    return result
end

return mouse

