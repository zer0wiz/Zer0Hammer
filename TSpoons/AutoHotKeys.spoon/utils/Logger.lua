-- AutoHotKeys Logger Utility
local Logger = {}
Logger.__index = Logger

function Logger.new(tag)
    local self = setmetatable({}, Logger)
    self.logger = hs.logger.new(tag, 'debug')
    return self
end

function Logger:d(msg) self.logger.d(msg) end
function Logger:i(msg) self.logger.i(msg) end
function Logger:w(msg) self.logger.w(msg) end
function Logger:e(msg) self.logger.e(msg) end
function Logger:v(msg) self.logger.v(msg) end

return Logger
