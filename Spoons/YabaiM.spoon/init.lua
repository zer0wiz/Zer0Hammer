local obj = {}
local modalmgr = hs.loadSpoon("ModalMgr")
local spoonSpace = hs.loadSpoon("SpoonSpace")

-- Metadata
obj.name = "YabaiM"
obj.version = "1.0"
obj.author = "unknown <unknown@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.yabaiCmd = "/opt/homebrew/bin/yabai"

local function trim(str)
  return str:match("^%s*(.-)%s*$")
end

local function splitCmd(commands)
  if type(commands) == "table" then
    -- 이미 테이블인 경우 그대로 반환
    return commands
  elseif type(commands) == "string" then
    -- 문자열인 경우 공백으로 분할
    return hs.fnutils.split(trim(commands), " ")
  else
    -- 다른 타입인 경우 빈 테이블 반환
    return {}
  end
end

local function log(msg, args)
  print("### YabaiM: " .. msg)
  dbg(args)
end


local function sendMsg(args, completion)
  log("sendMsg", args)
  local yabai_task = hs.task.new(obj.yabaiCmd, function(err, stdout, stderr)
    if type(completion) == 'function' then
      completion(stdout, stderr)
    end
  end, splitCmd(args))

  yabai_task:start()
end

local function sendMsg_and_exit_modal(args, completion)
  sendMsg(args, completion)
  obj:deactivate()
end

function obj:deactivate()
  modalmgr:deactivate({ 'yabaiM' })
end
-- local function focus_window () {
--     SPACE_NAME=$(yabai -m query --spaces --space | jq ".label")
--     WINDOW_ID=$(yabai -m query --windows --space | jq ".[] | select (.app=${SPACE_NAME}).id")
--     yabai -m window --focus "${WINDOW_ID}"
-- }
-- # focus window after active space changes
-- yabai -m signal --add event=space_changed action="yabai -m window --focus \$(yabai -m query --windows --space | jq .[0].id)"

-- # focus window after active display changes
-- yabai -m signal --add event=display_changed action="yabai -m window --focus \$(yabai -m query --windows --space | jq .[0].id)"
-- ##################################################
function obj:start(modal, modalManager)
  print("Start yabaiM")
  local cmodal = modal
  if modalManager then modalmgr = modalManager end

  local function ycMap(modalStr, mods, key, commands, completion)
    cmodal:bind(mods, key, modalStr, function()
      -- sendMsg_and_exit_modal(args)
      for _, cmd in ipairs(commands) do
        sendMsg(cmd, completion)
      end
    end)
    -- parseCmd = commands
    -- print("#############")
    -- cmodal:bind('', 'e', 'Toggle split type', function() sendMsg_and_exit_modal({ '-m', 'window', '--toggle', 'split' }) end)
  end

  local function altMap(key, commands, completion)
    hs.hotkey.bind({ "alt" }, key, function()
      if (#commands > 0) then
        for _, cmd in ipairs(commands) do
          sendMsg(cmd, completion)
        end
      else
        completion()
      end
    end)
  end


  local function m_window_center()
    local x, y, windowJson, displayJson
    sendMsg("-m query --windows --window", function(out, err)
      windowJson = hs.json.decode(out)
      print(windowJson)
    end)
    sendMsg("-m query --displays --display", function(out, err)
      displayJson = hs.json.decode(out)
      x = json.frame.x
      y = json.frame.y
    end)
    -- sendMsg(string.format("-m window --move abs:%f:%f", x, y), function(out, err) end)
    print(json)
  end


  local left = 'h'
  local right = 'l'
  local center = 'c'
  local up = 'k'
  local down = 'j'


  ---------------------------
  ----- Command Setting -----
  ---------------------------

  --- layout ---
  ycMap('Space layout stack', { 'alt' }, ",", { "-m space --layout stack" })
  ycMap('Space layout bsp', { 'alt' }, '.', { "-m space --layout bsp" })
  cmodal:bind('shift', center, 'Balance windows', function() sendMsg("-m space --balance") end)
  cmodal:bind('', 's', 'Stack window', function()
    sendMsg_and_exit_modal({ '-m', 'query', '--windows', '--window' }, function(stdout, stderr)
      data = hs.json.decode(stdout)
      wid = data.id

      print('found window ' .. wid)
      sendMsg("-m window west --stack " .. tostring(wid))
    end)
  end)



  --- focus ---
  ycMap('Focus recent space', { 'alt' }, '/', { "-m space --focus recent" })
  cmodal:bind('', left, 'Focus west', function() sendMsg("-m window --focus west") end)
  cmodal:bind('', down, 'Focus south', function() sendMsg("-m window --focus south") end)
  cmodal:bind('', up, 'Focus north', function() sendMsg("-m window --focus north") end)
  cmodal:bind('', right, 'Focus east', function() sendMsg("-m window --focus east") end)



  --- move --
  ycMap('Move display 1', { 'alt' }, '1', { "-m window --display 1" }, function(out, err)
    m_window_center()
    obj:yabai_end()
  end)
  ycMap('Move display 2', { 'alt' }, '2', { "-m window --display 2" }, function(out, err)
    m_window_center()
    obj:yabai_end()
  end)
  ycMap('Move display 3', { 'alt' }, '3', { "-m window --display 3" }, function(out, err)
    m_window_center()
    obj:yabai_end()
  end)
  -- ycMap('Window move recent display', { 'alt' }, 'r',
  --   {
  --     -- "-m window --move abs:100:100",
  --     -- "-m window --display recent",
  --     -- "-m window --focus recent",
  --     -- "-m window --gird 4:4:1:1:2:2",
  --     "-m query --windows --window"
  --   }, function(out, err) m_window_center(out, err) end
  -- )
  cmodal:bind('shift', left, 'Move left', function()
    print("left")
    sendMsg("-m window --move rel:-20:0")
  end)
  cmodal:bind('shift', down, 'Move down', function()
    print("down")
    sendMsg("-m window --move rel:0:20")
  end)
  cmodal:bind('shift', right, 'Move right', function()
    print("right")
    sendMsg("-m window --move rel:20:0")
  end)
  cmodal:bind('shift', up, 'Move up', function()
    print("up")
    sendMsg("-m window --move rel:0:-20")
  end)
  cmodal:bind('shift', 'c', 'Move Center', function()
    m_window_center()
    obj:yabai_end()
  end)

  --- toggle ---
  ycMap('Toggle split type', {}, 'e', { "-m window --toggle split" })
  -- ycMap('Toggle split type - fouce display all windows', {}, 'e',{ "-m window --toggle split" })
  cmodal:bind('', 'tab', 'Toggle Cheatsheet', function() modalmgr:toggleCheatsheet() end)
 
  -- 기존 정보 표시 기능들
  cmodal:bind('', 'd', 'Toggle zoom parent',
    function() sendMsg_and_exit_modal({ '-m', 'window', '--toggle', 'zoom-parent' }) end)
  cmodal:bind('', 'f', 'Toggle fullscreen',
    function() sendMsg_and_exit_modal({ '-m', 'window', '--toggle', 'zoom-fullscreen' }) end)
  cmodal:bind('', 'space', 'Toggle float', function(out, err)
    sendMsg("-m window --toggle float")
    sendMsg("-m window --grid 1:1:0:0:1:1")
    sendMsg("-m query --windows --window", function(out, err)
      print("out: " .. out)
    local data = hs.json.decode(out)
    if type(data) == "table" then
      local isFloating = data["is-floating"]  -- 점 표기 불가, 대괄호+문자열 키 사용
      print("is-floating:", isFloating and "true" or "false")
      alert("floating: " .. tostring(isFloating))
    else
      print("decode failed", err)
    end
  end)
    modalmgr:deactivate({ 'yabaiM' })
  end)

  -- cmodal:bind('shift', 'space', 'Toggle float-Fouce display All', function()
  --   sendMsg("-m query --windows --window", function(out, err)
  --     -- modalmgr:viewInfoModal(out)
  --     print("widonw--###########################")
  --     local json = hs.json.decode(out)
  --     print("completion::" .. json.id)
  --     dbg(json.frame)
  --     print(err)
  --   end)
  -- end)



  -- size & freeset
  cmodal:bind('shift', 'f', 'Window full size', function()
    sendMsg("-m window --grid 12:12:0:0:12:12")
  end)
  cmodal:bind('shift', '1', 'Window default size', function()
    sendMsg("-m window --grid 12:12:1:1:10:10")
  end)
  cmodal:bind('shift', '2', 'Window left half', function()
    sendMsg("-m window --grid 6:12:0:0:6:6")
  end)
  cmodal:bind('shift', '3', 'Window right half', function()
    sendMsg("-m window --grid 6:12:6:0:6:6")
  end)



  --- swap ---
  cmodal:bind('', 'return', 'Swap window to largest region',
    function() sendMsg_and_exit_modal({ '-m', 'window', '--swap', 'largest' }) end)
  cmodal:bind('ctrl', left, 'Swap west', function() sendMsg("-m window --warp west") end)
  cmodal:bind('ctrl', down, 'Swap south', function() sendMsg("-m window --warp south") end)
  cmodal:bind('ctrl', up, 'Swap north', function() sendMsg("-m window --warp north") end)
  cmodal:bind('ctrl', right, 'Swap east', function() sendMsg("-m window --warp east") end)



  --- grow & shrink ---
  cmodal:bind({ 'shift', 'cmd' }, right, 'Grow horizontally', function()
    sendMsg("-m window --resize left:-20:0")
    sendMsg("-m window --resize right:20:0")
  end)
  cmodal:bind({ 'shift', 'cmd' }, up, 'Grow vertically', function()
    sendMsg("-m window --resize top:0:-20")
    sendMsg("-m window --resize bottom:0:20")
  end)
  cmodal:bind({ 'shift', 'cmd' }, left, 'Shrink horizontally', function()
    sendMsg("-m window --resize left:20:0")
    sendMsg("-m window --resize right:-20:0")
  end)
  cmodal:bind({ 'shift', 'cmd' }, down, 'Shrink vertically', function()
    sendMsg("-m window --resize top:0:20")
    sendMsg("-m window --resize bottom:0:-20")
  end)


    --- query ---
  -- [추가] alt+i → 1/2/3 선택 서브 모달
  cmodal:bind({ 'alt' }, 'i', 'Current Info Query (Console Output)', function()
    local sid = 'yabaiM_info'
    if not modalmgr.modal_list[sid] then
      local smodal = modalmgr:new(sid)
      smodal = modalmgr.modal_list[sid]

      smodal:bind('', '1', 'Displays info', function()
        sendMsg("-m query --displays --display", function(out) 
          modalmgr:deactivate({ sid })
          print(out) 
          obj:showYabaiInfo("Yabai Displays", out)
        end)
      end)

      smodal:bind('', '2', 'Spaces info', function()
        sendMsg("-m query --spaces --space", function(out) 
          modalmgr:deactivate({ sid })
          print(out) 
          obj:showYabaiInfo("Yabai Spaces", out)
        end)
      end)

      smodal:bind('', '3', 'Windows info', function()
        sendMsg("-m query --windows --window", function(out) 
          modalmgr:deactivate({ sid })
          print(out) 
          obj:showYabaiInfo("Yabai Windows", out)
        end)
      end)

      smodal:bind('', 'escape', 'Cancel', function()
        modalmgr:deactivate({ sid })
      end)
    end

    -- 정보 선택 모달
    modalmgr:viewInfoModal({ sid }, '1:Displays  2:Spaces  3:Windows', { 
                                              width = 600, height = 100,
                                              alpha = 0.9, color = '#F0F0F0',
                                              padding_top = 400, padding_left = 0, 
                                              margin_top = 0, margin_left = 0, 
                                              font_size = 18, show_webview = true })
  end)


  --- command ---

  cmodal:bind('alt', 'r', 'Restart Yabai Service', function()
    sendMsg("--restart-service", function(out, err)
      print("### Yabai Service Restart!! ")
    end)
  end)

  cmodal:bind('', 'escape', 'Exit yabaiM', function() modalmgr:deactivate({ 'yabaiM' }) end)

  altMap("r", {}, function()
    m_window_center()
  end)
end

function obj:init()
  print("Init yabaiM")
end

-- Yabai 정보 표시 통합 함수 (데이터를 직접 받아서 처리)
function obj:showYabaiInfo(displayName, data, options)
  if not spoonSpace or not spoonSpace.webview then
    print("SpoonSpace webview not available")
    return
  end
  
  -- 기본 옵션 설정 (투명도 포함)
  options = options or {}
  options.alpha = options.alpha or 0.9  -- 기본 투명도 90%
  
  local webview = spoonSpace.webview.showAsyncData(displayName, "Loading info...", options)
  
  -- 받은 데이터를 즉시 처리
  if data and data ~= "" then
    local content = spoonSpace.webview.formatJSON(data)
    spoonSpace.webview.updateContent(webview, displayName, content)
    -- 콘솔에도 출력
    print("=== " .. displayName .. " ===")
    print(data)
  else
    spoonSpace.webview.updateContent(webview, displayName, "No data available")
    print("No data available")
  end
  
  return webview
end

function obj:window_focused_event(windowId)
  print("### Test" .. windowId)
end

return obj
