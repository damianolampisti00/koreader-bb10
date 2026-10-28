-- Bisect the exit crash after ffi/bb10 use. Run: luajit initbisect.lua <step>
require("setupkoenv")
local ffi = require("ffi")
local bb10 = require("ffi/bb10")
local step = tonumber(arg[1]) or 1
bb10.init()
io.stdout:write("init ", bb10.width, "x", bb10.height, " stride ", bb10.stride, "\n") io.stdout:flush()
if step >= 2 then bb10.post() end
if step >= 3 then bb10.getBatteryInfo() end
if step >= 4 then bb10.shutdown() end
io.stdout:write("RESULT OK ", step, "\n") io.stdout:flush()
if step == 5 then os.exit(0, false) end
