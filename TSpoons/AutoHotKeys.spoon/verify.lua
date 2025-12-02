#!/usr/bin/env lua
-- AutoHotKeys.spoon 리팩토링 검증 스크립트
-- Hammerspoon 콘솔에서 실행: dofile(hs.spoons.resourcePath("AutoHotKeys") .. "/verify.lua")

print("=======================================================")
print("AutoHotKeys.spoon 리팩토링 검증 시작")
print("=======================================================\n")

local errors = {}
local warnings = {}
local success = true

-- 1. 모듈 로드 테스트
print("📦 모듈 로드 테스트...")
local modules = { "utils", "storage", "actions", "recorder", "ui", "hotkeys", "watchers" }
for _, modName in ipairs(modules) do
    local ok, mod = pcall(require, modName)
    if ok then
        print("  ✅ " .. modName .. ".lua 로드 성공")
    else
        print("  ❌ " .. modName .. ".lua 로드 실패: " .. tostring(mod))
        table.insert(errors, modName .. " 로드 실패")
        success = false
    end
end

-- 2. 모듈 구조 검증
print("\n🏗️  모듈 구조 검증...")

-- utils.lua 검증
local ok, utils = pcall(require, "utils")
if ok then
    local required = { "Logger", "Context", "Mouse", "Input", "Visuals" }
    for _, key in ipairs(required) do
        if utils[key] then
            print("  ✅ utils." .. key .. " 존재")
        else
            print("  ❌ utils." .. key .. " 누락")
            table.insert(errors, "utils." .. key .. " 누락")
            success = false
        end
    end
end

-- storage.lua 검증
local ok, storage = pcall(require, "storage")
if ok then
    local required = { "loadConfig", "saveConfig", "loadContextList", "saveMacro", "loadMacro" }
    for _, fn in ipairs(required) do
        if type(storage[fn]) == "function" then
            print("  ✅ storage." .. fn .. "() 존재")
        else
            print("  ❌ storage." .. fn .. "() 누락")
            table.insert(errors, "storage." .. fn .. " 누락")
            success = false
        end
    end
end

-- actions.lua 검증
local ok, actions = pcall(require, "actions")
if ok then
    local required = { "perform", "play", "stop", "handleShortcutKey" }
    for _, fn in ipairs(required) do
        if type(actions[fn]) == "function" then
            print("  ✅ actions." .. fn .. "() 존재")
        else
            print("  ❌ actions." .. fn .. "() 누락")
            table.insert(errors, "actions." .. fn .. " 누락")
            success = false
        end
    end
end

-- ui.lua 검증
local ok, ui = pcall(require, "ui")
if ok then
    local required = { "menu", "overlay", "preview" }
    for _, key in ipairs(required) do
        if ui[key] then
            print("  ✅ ui." .. key .. " 존재")
        else
            print("  ❌ ui." .. key .. " 누락")
            table.insert(errors, "ui." .. key .. " 누락")
            success = false
        end
    end
end

-- 3. 통합된 파일 확인 (삭제되어야 할 파일)
print("\n🗑️  이전 파일 정리 확인...")
local oldFiles = {
    "execution.lua", "playback.lua", "capture.lua", "menu.lua", "overlay.lua",
    "contextInfo.lua", "mouse.lua", "visuals.lua", "shortcut_preview.lua",
    "hotkeyValidator.lua"
}
local oldDirs = { "utils", "core", "data", "ui" }

local fs = hs.fs
local spoonPath = hs.spoons.resourcePath("AutoHotKeys")

for _, file in ipairs(oldFiles) do
    local path = spoonPath .. "/" .. file
    if fs.attributes(path) then
        print("  ⚠️  " .. file .. " 아직 존재 (삭제 권장)")
        table.insert(warnings, file .. " 아직 존재")
    else
        print("  ✅ " .. file .. " 정리됨")
    end
end

for _, dir in ipairs(oldDirs) do
    local path = spoonPath .. "/" .. dir
    if fs.attributes(path, "mode") == "directory" then
        print("  ⚠️  " .. dir .. "/ 디렉토리 아직 존재 (삭제 권장)")
        table.insert(warnings, dir .. "/ 디렉토리 아직 존재")
    else
        print("  ✅ " .. dir .. "/ 디렉토리 정리됨")
    end
end

-- 4. 설정 파일 확인
print("\n⚙️  설정 파일 확인...")
local ok, storage = pcall(require, "storage")
if ok then
    local config = storage.loadConfig()
    if config then
        print("  ✅ 설정 파일 로드 성공")
        print("      - Overlay 활성화: " .. tostring(config.overlay and config.overlay.enabled or false))
        print("      - 클릭 애니메이션 색상: " .. tostring(config.clickAnimation and config.clickAnimation.color or "N/A"))
    else
        print("  ⚠️  설정 파일 로드 실패 (기본값 사용)")
        table.insert(warnings, "설정 파일 없음")
    end
end

-- 결과 요약
print("\n=======================================================")
print("검증 결과 요약")
print("=======================================================")

if #errors > 0 then
    print("\n❌ 오류 (" .. #errors .. "개):")
    for _, err in ipairs(errors) do
        print("  - " .. err)
    end
end

if #warnings > 0 then
    print("\n⚠️  경고 (" .. #warnings .. "개):")
    for _, warn in ipairs(warnings) do
        print("  - " .. warn)
    end
end

if success and #errors == 0 then
    print("\n✅ 리팩토링 검증 성공!")
    print("   모든 모듈이 올바르게 통합되었습니다.")
else
    print("\n❌ 리팩토링 검증 실패")
    print("   위의 오류를 수정해주세요.")
end

print("\n다음 단계:")
print("1. Hammerspoon 재로드: hs.reload()")
print("2. 메뉴 테스트: Ctrl+Cmd+K (또는 설정된 단축키)")
print("3. 오버레이 확인: 앱 전환 시 'AK' 배지 표시")
print("4. 녹화 테스트: Ctrl+Cmd+R로 매크로 녹화")
print("=======================================================\n")
