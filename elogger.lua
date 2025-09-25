local date,time = os.date,os.time
local min,max,tmove=math.min,math.max,table.move
local sformat,ssub,slower,srep,sfind=string.format,string.sub,string.lower,string.rep,string.find
local type,select,rawget,rawset,print,printf=type,select,rawget,rawset,print,hs.printf

local ERROR,WARNING,INFO,DEBUG,VERBOSE=1,2,3,4,5
local MAXLEVEL=VERBOSE
local LEVELS={nothing=0,error=ERROR,warning=WARNING,info=INFO,debug=DEBUG,verbose=VERBOSE}

local LEVELFMT={{'ERROR:',''},{'** Warning:',''},{'',''},{'','    '},{'','        '}}
local lasttime,lastid=0
local idlen,idf,idempty=10,'%10.10s:','           '
local timeempty='        '

-- require "extensions"
local logger = require "hs.logger"
local functional = require "lib.functional"
local merge = functional.merge

local elogger = {
    config = {
        defaultLogLevel = WARNING,
        traceLogLevel = ERROR,
        debugLogLevel = DEBUG,
    }
}
local originLogger = {}
local instances=setmetatable({},{__mode='kv'})

local function toLevelString(lvl)
    for key, val in pairs(LEVELS) do
        if lvl == val then
            return key
        end
    end
    return elogger.config.defaultLogLevel
end

-- Check log level and return true if logging should proceed
local function invalidLevelCheck(loglevel, requiredLevel)
    -- print("loglevel::"..loglevel)
    -- print("requiredLevel::"..requiredLevel)
    -- If the log level is sufficient, return true
    return loglevel < max(requiredLevel, elogger.config.debugLogLevel)
end

elogger.toLogLevel = function(lvl)
  if type(lvl)=='string' then
    return LEVELS[slower(lvl)] or error('invalid log level',3)
  elseif type(lvl)=='number' then
    return max(0,min(MAXLEVEL,lvl))
  else error('loglevel must be a string or a number',3) end
end

elogger.getLogLevelString = function(loglevel)
    return toLevelString(loglevel or elogger.config.defaultLogLevel)
end


-- elogger.setGlobalLogLevel=function(lvl)
--   lvl=toLogLevel(lvl)
--   for log in pairs(instances) do
--     log.setLogLevel(lvl)
--   end
-- end

elogger.setModulesLogLevel=function(lvl)
  for ext,mod in pairs(package.loaded) do
    if string.sub(ext,1,3)=='hs.' and mod~=hs then
      if mod.setLogLevel then mod.setLogLevel(lvl) end
    end
  end
end


local history={}
local histIndex,histSize=0,0
--- hs.logger.historySize([size]) -> number
--- Function
--- Sets or gets the global log history size
---
--- Parameters:
---  * size - (optional) the desired number of log entries to keep in the history;
---    if omitted, will return the current size; the starting value is 0 (disabled)
---
--- Returns:
---  * the current or new history size
---
--- Notes:
---  * if you change history size (other than from 0) after creating any logger instances, things will likely break
elogger.historySize=function(sz)
  if sz==nil then return histSize end
  if type(sz)~='number' then error('size must be a number')end
  sz=min(sz,10000) histSize=sz
  return sz
end
local function store(s)
  histIndex=histIndex+1
  if histIndex>histSize then histIndex=1 end
  history[histIndex]=s
end

--- hs.logger.history() -> list of log entries
--- Function
--- Returns the global log history
---
--- Parameters:
---  * None
---
--- Returns:
---  * a list of (at most `hs.logger.historySize()`) log entries produced by all the logger instances, in chronological order;
---    each entry is a table with the following fields:
---    * time - timestamp in seconds since the epoch
---    * level - a number between 1 (error) and 5 (verbose)
---    * id - a string containing the id of the logger instance that produced this entry
---    * message - a string containing the logged message
elogger.history=function()
  local start=histIndex+1
  if not history[start] then return history end
  if start>histSize then start=1
  else tmove(history,1,start-1,histSize+1) end -- append
  tmove(history,start,histSize+start,1) --shift down
  tmove(history,histSize*2+1,histSize*2+start,histSize+1) --cleanup
  histIndex=histSize
  return history
end

local formatID = function(theID)
  if utf8.len(theID) > idlen then
    if elogger.truncateID == "head" then
      theID = ssub(theID, -idlen)
      if elogger.truncateIDWithEllipsis then
          theID = "…" .. ssub(theID, 2)
      end
    else
      theID = ssub(theID, 1, idlen)
      if elogger.truncateIDWithEllipsis then
          theID = ssub(theID, 1, idlen - 1) .. "…"
      end
    end
    theID = theID .. ":"
  else
    theID = sformat(idf,theID)
  end
  return theID
end

--- hs.elogger.printHistory([entries[, level[, filter[, caseSensitive]]]])
--- Function
--- Prints the global log history to the console
---
--- Parameters:
---  * entries - (optional) the maximum number of entries to print; if omitted, all entries in the history will be printed
---  * level - (optional) the desired log level (see `hs.logger.setLogLevel()`); if omitted, defaults to `verbose`
---  * filter - (optional) a string to filter the entries (by logger id or message) via `string.find` plain matching
---  * caseSensitive - (optional) if true, filtering is case sensitive
---
--- Returns:
---  * None
elogger.printHistory=function(entries,lvl,flt,case)
  entries=entries or histSize
  local hist=elogger.history()
  local filt=hist
  if flt and not case then flt=slower(flt) end
  if lvl or flt then
    lvl=toLogLevel(lvl or 5)
    filt={}
    for _,e in ipairs(hist) do
      if e.level<=lvl and (not flt or sfind(case and e.id or slower(e.id),flt,1,true) or sfind(case and e.message or slower(e.message),flt,1,true)) then
        filt[#filt+1]=e
      end
    end
  end
  for i=max(1,#filt-entries+1),#filt do
    local e=filt[i]
    printf('%s %s%s %s%s',date('%X',e.time),LEVELFMT[e.level][1],formatID(e.id),LEVELFMT[e.level][2],e.message)
--     printf('%s %s%s %s%s',date('%X',e.time),LEVELFMT[e.level][1],sformat(idf,e.id),LEVELFMT[e.level][2],e.message)
  end
end

-- logger
local lf = function(loglevel,lvl,id,fmt,...)
  if histSize<=0 and loglevel<lvl then return end
  local ct = time()
  local msg=sformat(fmt,...)
  if histSize>0 then store({time=ct,level=lvl,id=id,message=msg}) end
  if loglevel<lvl then return end
  id=formatID(id)
--   id=sformat(idf,id)
  local stime = timeempty
  if ct-lasttime>0 or lvl<3 then stime=date('%X') lasttime=ct end
  if id==lastid and lvl>3 then id=idempty else lastid=id end
  if lvl==ERROR then print'********' end
  printf('%s %s%s %s%s',stime,LEVELFMT[lvl][1],id,LEVELFMT[lvl][2],msg)
  if lvl==ERROR then print'********' end
end
local l = function(loglevel,lvl,id,...)
  if histSize>0 or loglevel>=lvl then return lf(loglevel,lvl,id,srep('%s',select('#',...),' '),...) end
end

elogger.idLength=function(len)
  if len==nil then return idlen end
  if type(len)~='number' or len<4 then error('len must be a number >=4',2)end
  len=min(len,40) idlen=len
  idf='%'..len..'.'..len..'s:'
  idempty=srep(' ',len+1)
end

elogger.truncateID = "tail"
elogger.truncateIDWithEllipsis = false

--- hs.logger.defaultLogLevel
--- Variable
--- Default log level for new logger instances.
---
--- The starting value is 'warning'; set this (to e.g. 'info') at the top of your `init.lua` to affect
--- all logger instances created without specifying a `loglevel` parameter
--- logger functions
local function dbglf(loglevel, lvl, id, fmt, ...)
    if invalidLevelCheck(loglevel, lvl) then return end
    local state = debug.getinfo(2)
    local tag = state.short_src..":"..state.currentline.." ["..id.."] "

    if select('#',...) < 2 then
        fmt = safeFormat(fmt, ...)
    else
        local vals = table.pack(...)
        for k = 1, vals.n do
            fmt = safeFormat(fmt, vals[k])
        end
    end
    print(tag..fmt)
end


local function dbgls(loglevel, lvl, id, tag)
    -- print(elogger.getLogLevel())
    -- print(logger.defaultLogLevel)
    if invalidLevelCheck(loglevel, lvl) then return end
    local t = "\n"
            .."\n################# ["..elogger.getLogLevelString(loglevel).."] trace ####################"
            .."\n######### ["..id.."] - "..tag
            .."\n####################################################"
            .."\n"..debug.traceback()
            .."\n#################################### trace END #####"
            .."\n"
    print(t)

    -- print(hs.inspect(...))
end

elogger.dbg = function(...)
    print(hs.inspect(...))
end

elogger.dbdf = function (depth, ...)
  local state = debug.getinfo(depth)
  local tag = state.short_src..":"..state.currentline.." "
  return dbg(tag..string.format(...))
end


function tap (a)
  dbg(a)
  return a
end

elogger.setGlobalConfig = function(config)
    for log in pairs(instances) do
        log.setConfig(config)
    end
end

local function setConfig(loglevel, id, config)
    local result = merge(elogger.config, config)
    dbglf(loglevel, DEBUG, id, "\n##### input config ##### \n%s"
                     .."\n##### orgin config ::: %s #####"
                     .."\n##### merge config ::: %s #####"
                       , config, elogger.config, result)
end


function elogger.new(id,loglevel)
    originLogger = logger.new(id, loglevel)

    local function setLogLevel(lvl)loglevel=elogger.toLogLevel(lvl)end
    setLogLevel(loglevel or elogger.config.defaultLogLevel)
    local r = {
        id = id,
        setLogLevel = setLogLevel,
        getLogLevel = function()return loglevel end,
        setConfig = function(config) return setConfig(loglevel, id, config) end,
        e = function(...) return l(loglevel,ERROR,id,...) end,
        w = function(...) return l(loglevel,WARNING,id,...) end,
        i = function(...) return l(loglevel,INFO,id,...) end,
        d = function(...) return l(loglevel,DEBUG,id,...) end,
        v = function(...) return l(loglevel,VERBOSE,id,...) end,

        ef = function(fmt,...) return lf(loglevel,ERROR,id,fmt,...) end,
        wf = function(fmt,...) return lf(loglevel,WARNING,id,fmt,...) end,
        f = function(fmt,...) return lf(loglevel,INFO,id,fmt,...) end,
        df = function(fmt,...) return lf(loglevel,DEBUG,id,fmt,...) end,
        vf = function(fmt,...) return lf(loglevel,VERBOSE,id,fmt,...) end,
        gs = function(fmt) return dbgls(loglevel,INFO,id,fmt) end,
        dbgs = function(fmt) return dbgls(loglevel,DEBUG,id,fmt) end,
        vgs = function(fmt) return dbgls(loglevel,VERBOSE,id,fmt) end,
        gf = function(fmt,...) return dbglf(loglevel,INFO,id,fmt,...) end,
        dbgf = function(fmt,...) return dbglf(loglevel,DEBUG,id,fmt,...) end,
        vgf = function(fmt,...) return dbglf(loglevel,VERBOSE,id,fmt,...) end,
    }
    r.log=r.i r.logf=r.f
    r = merge(r,elogger, originLogger)

    r.dbgf("#######################################")
    r.dbgf("###### id :: %s", id)
    r.dbgf("###### loglevel :: %s", loglevel)
    r.dbgf("###### elogger :: %s", r.config)
    r.dbgf("#######################################")

    instances[r]=true
    return setmetatable(r,{
        __index=function(t,k)
        return k=='level' and loglevel or rawget(t,k)
        end,
        __newindex=function(t,k,v)
        if k=='level' then return setLogLevel(v) else return rawset(t,k,v) end
        end
    })
    -- return r
end


return elogger

