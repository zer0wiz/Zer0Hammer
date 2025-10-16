local obj = {}
local modalmgr = hs.loadSpoon("ModalMgr")

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
  args = hs.fnutils.split(trim(commands), " ")
  return args
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
function obj:init()
  print("Init yabaiM")
  modalmgr:new('yabaiM')
  local cmodal = modalmgr.modal_list['yabaiM']

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
  cmodal:bind('', 'd', 'Toggle zoom parent',
    function() sendMsg_and_exit_modal({ '-m', 'window', '--toggle', 'zoom-parent' }) end)
  cmodal:bind('', 'f', 'Toggle fullscreen',
    function() sendMsg_and_exit_modal({ '-m', 'window', '--toggle', 'zoom-fullscreen' }) end)
  cmodal:bind('', 'space', 'Toggle float', function()
    sendMsg("-m window --toggle float")
    sendMsg("-m window --grid 1:1:0:0:1:1")
    modalmgr:deactivate({ 'yabaiM' })
  end)

  cmodal:bind('shift', 'space', 'Toggle float-Fouce display All', function()
    sendMsg("-m query --windows --window", function(out, err)
      modalmgr:viewInfoModal(out)
      print("widonw--###########################")
      local json = hs.json.decode(out)
      print(out)
      print("completion::" .. json.id)
      dbg(json.frame)
      print(err)
    end)
  end)



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



  --- command ---

  cmodal:bind('alt', 'r', 'Restart Yabai Service', function()
    sendMsg("--restart-service", function(out, err)
      print("### Yabai Service Restart!! ")
      print(out)
      local json = hs.json.decode(out)
      print("completion::" .. json.id)
      dbg(json.frame)
      print(err)
    end)
  end)

  cmodal:bind('', 'escape', 'Exit yabaiM', function() modalmgr:deactivate({ 'yabaiM' }) end)
  -- cmodal:bind('', 'e', 'Toggle split type', function() sendMsg_and_exit_modal({ '-m', 'window', '--toggle', 'split' }) end)

  modalmgr.supervisor:bind('alt', 'y', 'Enter yabaiM', function()
    print("### YabaiM Enter")
    modalmgr:deactivateAll()
    modalmgr:activate({ 'yabaiM' }, '#74BB67', nil, 'Yabai Control Mode!')
  end)

  altMap("r", {}, function()
    m_window_center()
  end)
end

function obj:window_focused_event(windowId)
  print("### Test" .. windowId)
end

return obj
