local function trim(str)
    -- print(str)
    return str:match("^%s*(.-)%s*$")
end

local function splitCmd(commands)
    args=hs.fnutils.split(trim(commands), " ")
    -- for _, arg in ipairs(args) do
    --     dbgf(":::" .. arg)
    -- end
    return args
end


local function yabai_t(args, completion)
    -- dbg(args)
  local yabai_task = hs.task.new('/opt/homebrew/bin/yabai', function(err, stdout, stderr)
        --
    -- print("t-3::-----")
    -- print('stdout: '.. stdout, 'stderr: ' .. stderr)

    if type(completion) == 'function' then

    -- print("2::-----")
      completion(stdout, stderr)
    end
  end, splitCmd(args))

  yabai_task:start()
end

local function yabai(args, completion)
  local yabai_task = hs.task.new('/opt/homebrew/bin/yabai', function(err, stdout, stderr)
    -- dbgf("### args --- " .. args)
        --
    -- print("3::-----")
    -- print('stdout: '.. stdout, 'stderr: ' .. stderr)

    if type(completion) == 'function' then

    -- print("2::-----")
      completion(stdout, stderr)
    end
  end, args)

  yabai_task:start()
end

local function yabai2(args, completion)
  local yabai_task2 = hs.task.new('/opt/homebrew/bin/yabai', function(err, stdout, stderr)
    -- dbgf("### args --- " .. args)
        --
    -- print("completion type::-----")
    -- print(type(completion))
    -- print(completion)

    if type(completion) == 'function' then

    -- print("2::-----")
      completion(stdout, stderr)
    end
  end, splitCmd(args))

  yabai_task2:start()
end

local function yc(args, completion)
    -- print("1::-----")
    for _, arg in ipairs(args) do
        -- print("4::-----")
        dbg(arg)
    end
  yabai(args, competion)
  spoon.ModalMgr:deactivate({'yabaiM'})
end

-- focus_window () {
--     SPACE_NAME=$(yabai -m query --spaces --space | jq ".label")
--     WINDOW_ID=$(yabai -m query --windows --space | jq ".[] | select (.app=${SPACE_NAME}).id")
--     yabai -m window --focus "${WINDOW_ID}"
-- }
-- # focus window after active space changes
-- yabai -m signal --add event=space_changed action="yabai -m window --focus \$(yabai -m query --windows --space | jq .[0].id)"

-- # focus window after active display changes
-- yabai -m signal --add event=display_changed action="yabai -m window --focus \$(yabai -m query --windows --space | jq .[0].id)"
        -- ##################################################

spoon.ModalMgr:new('yabaiM')
local cmodal = spoon.ModalMgr.modal_list['yabaiM']

local function ycMap(modalStr, mods, key, commands, completion)

    cmodal:bind(mods, key, modalStr, function()
        -- yc(args)
        for _, cmd in ipairs(commands) do
            yabai2(cmd, completion)
        end
    end)
    -- parseCmd = commands
    -- print("#############")
    -- cmodal:bind('', 'e', 'Toggle split type', function() yc({ '-m', 'window', '--toggle', 'split' }) end)
end

local function altMap(key, commands, completion)
    print(#commands)
    hs.hotkey.bind({ "alt" }, key, function()
        if(#commands > 0) then
            for _, cmd in ipairs(commands) do
                yabai_t(cmd, completion)
            end
        else
            completion()
        end
    end)
end

local function yabai_end()
    spoon.ModalMgr:deactivate({'yabaiM'})
end

local function m_window_center()
    -- yaba{ '-m window --move rel:100:-200' })
    local x,y
    yabai_t("-m query --windows --window", function(out, err)
        print("widonw--###########################")
        local json = hs.json.decode(out)
        print(out)
        print("completion::".. json.id)
        dbg(json.frame)
        print(err)
    end)
    yabai_t("-m query --displays --display", function(out, err)
        print("display--###########################")
        local json = hs.json.decode(out)
        print("completion::".. json.id)
        dbg(json.index)
        dbg(json.frame)
        x = json.frame.x
        y = json.frame.y
        print(string.format("#### x,y == {%f, %f}", x, y))
        print(err)
    end)
    yabai_t(string.format("-m window --move abs:%f:%f",x,y), function(out, err)
        print(out)
        print(err)
    end)


   -- yabai2("", )
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
ycMap('Space layout stack', {'alt'},",", { "-m space --layout stack" })
ycMap('Space layout bsp', {'alt'}, '.', { "-m space --layout bsp" })
cmodal:bind('shift', center, 'Balance windows', function() yabai({ '-m', 'space', '--balance' }) end)
cmodal:bind('', 's', 'Stack window', function()
  yc({ '-m', 'query', '--windows', '--window' }, function(stdout, stderr)
    data = hs.json.decode(stdout)
    wid = data.id

    print('found window ' .. wid)
    yabai({ '-m', 'window', 'west', '--stack', tostring(wid) })
  end)
end)



--- focus ---
ycMap('Focus recent space', {'alt'}, '/', { "-m space --focus recent" })
cmodal:bind('', left, 'Focus west', function() yabai({ '-m', 'window', '--focus', 'west' }) end)
cmodal:bind('', down, 'Focus south', function() yabai({ '-m', 'window', '--focus', 'south' }) end)
cmodal:bind('', up, 'Focus north', function() yabai({ '-m', 'window', '--focus', 'north' }) end)
cmodal:bind('', right, 'Focus east', function() yabai({ '-m', 'window', '--focus', 'east' }) end)



--- move --
ycMap('Move display 1', {'alt'}, '1', { "-m window --display 1" }, function(out, err)
    m_window_center()
    yabai_end()
end)
ycMap('Move display 2', {'alt'}, '2', { "-m window --display 2" }, function(out, err)
    m_window_center()
    yabai_end()
end)
ycMap('Move display 3', {'alt'}, '3', { "-m window --display 3" }, function(out, err)
    m_window_center()
    yabai_end()
end)
ycMap('Window move recent display', {'alt'},'r',
    {
        -- "-m window --move abs:100:100",
        -- "-m window --display recent",
        -- "-m window --focus recent",
        -- "-m window --gird 4:4:1:1:2:2",
        "-m query --windows --window"
        }, function(out, err) m_window_center(out, err) end
    -- }, function(out, err)
    --   local json = hs.json.decode(out)
    --     print("completion::".. json.id)
    -- end
)
cmodal:bind('shift', left, 'Move left', function()
  yabai({ '-m', 'window', '--move', 'rel:-20:0' })
end)
cmodal:bind('shift', down, 'Move down', function()
  yabai({ '-m', 'window', '--move', 'rel:0:20' })
end)
cmodal:bind('shift', right, 'Move right', function()
  yabai({ '-m', 'window', '--move', 'rel:20:0' })
end)
cmodal:bind('shift', up, 'Move up', function()
  yabai({ '-m', 'window', '--move', 'rel:0:-20' })
end)



--- toggle ---
ycMap('Toggle split type', {}, 'e',{ "-m window --toggle split" })
-- ycMap('Toggle split type - fouce display all windows', {}, 'e',{ "-m window --toggle split" })
cmodal:bind('', 'tab', 'Toggle Cheatsheet', function() spoon.ModalMgr:toggleCheatsheet() end)
cmodal:bind('', 'd', 'Toggle zoom parent', function() yc({ '-m', 'window', '--toggle', 'zoom-parent' }) end)
cmodal:bind('', 'f', 'Toggle fullscreen', function() yc({ '-m', 'window', '--toggle', 'zoom-fullscreen' }) end)
cmodal:bind('', 'space', 'Toggle float', function()
  yabai({ '-m', 'window', '--toggle', 'float' })
  yabai({ '-m', 'window', '--grid', '1:1:0:0:1:1' })
  spoon.ModalMgr:deactivate({'yabaiM'})
end)

cmodal:bind('shift', 'space', 'Toggle float-Fouce display All', function()
    yabai_t("-m query --windows --window", function(out, err)
    spoon.ModalMgr:viewInfoModal(out)
        print("widonw--###########################")
        local json = hs.json.decode(out)
        print(out)
        print("completion::".. json.id)
        dbg(json.frame)
        print(err)
    end)
end)



-- size & freeset
cmodal:bind('shift', 'f', 'Window full size', function()
  yabai({ '-m', 'window', '--grid', '12:12:0:0:12:12' })
end)
cmodal:bind('shift', '1', 'Window default size', function()
  yabai({ '-m', 'window', '--grid', '12:12:1:1:10:10' })
end)
cmodal:bind('shift', '2', 'Window left half', function()
  yabai({ '-m', 'window', '--grid', '6:12:0:0:6:6' })
end)
cmodal:bind('shift', '3', 'Window right half', function()
  yabai({ '-m', 'window', '--grid', '6:12:6:0:6:6' })
end)



--- swap ---
cmodal:bind('', 'return', 'Swap window to largest region', function() yc({ '-m', 'window', '--swap', 'largest' }) end)
cmodal:bind('ctrl', left, 'Swap west', function() yabai({ '-m', 'window', '--warp', 'west' }) end)
cmodal:bind('ctrl', down, 'Swap south', function() yabai({ '-m', 'window', '--warp', 'south' }) end)
cmodal:bind('ctrl', up, 'Swap north', function() yabai({ '-m', 'window', '--warp', 'north' }) end)
cmodal:bind('ctrl', right, 'Swap east', function() yabai({ '-m', 'window', '--warp', 'east' }) end)



--- grow & shrink ---
cmodal:bind({'shift','cmd'}, right, 'Grow horizontally', function()
  yabai({ '-m', 'window', '--resize', 'left:-20:0' })
  yabai({ '-m', 'window', '--resize', 'right:20:0' })
end)
cmodal:bind({'shift','cmd'}, up, 'Grow vertically', function()
  yabai({ '-m', 'window', '--resize', 'top:0:-20' })
  yabai({ '-m', 'window', '--resize', 'bottom:0:20' })
end)
cmodal:bind({'shift','cmd'}, left, 'Shrink horizontally', function()
  yabai({ '-m', 'window', '--resize', 'left:20:0' })
  yabai({ '-m', 'window', '--resize', 'right:-20:0' })
end)
cmodal:bind({'shift','cmd'}, down, 'Shrink vertically', function()
  yabai({ '-m', 'window', '--resize', 'top:0:20' })
  yabai({ '-m', 'window', '--resize', 'bottom:0:-20' })
end)



--- command ---

cmodal:bind({'shift','cmd'}, 'r', 'Restart Yabai Service', function()
--   hs.task.new('whami ', function(err, stdout, stderr)
--     local json = hs.json.decode(stdout)
--     print(stdout)
--     print("completion::".. json.id)
--     dbg(json.frame)
--     print(stderr)
--   end)

  yabai_t("--restart-service", function(out, err)
    print("### Yabai Service Restart!! ")
    local json = hs.json.decode(out)
    print(out)
    print("completion::".. json.id)
    dbg(json.frame)
    print(err)
  end)
end)

cmodal:bind('', 'escape', 'Exit yabaiM', function() spoon.ModalMgr:deactivate({'yabaiM'}) end)
-- cmodal:bind('', 'e', 'Toggle split type', function() yc({ '-m', 'window', '--toggle', 'split' }) end)
spoon.ModalMgr.supervisor:bind('alt', 'e', 'Enter yabaiM', function()
  spoon.ModalMgr:deactivateAll()
  spoon.ModalMgr:activate({'yabaiM'}, '#74BB67')
end)

altMap("r", {}, function()
    m_window_center()
end)



