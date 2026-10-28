-- Try to "watch" the volume keys like bb::multimedia::MediaKeyWatcher (PPS mediaplayer/control).
-- Run: luajit mediakeys.lua [action] [seconds]   (action: short, short_nothresh, med)
local ffi = require("ffi")
require("ffi/posix_h")
local C = ffi.C
local action = arg[1] or "short"
local seconds = tonumber(arg[2]) or 40
local function out(...) io.stdout:write(table.concat({...}, " "), "\n") io.stdout:flush() end

local fd = C.open("/pps/services/multimedia/mediaplayer/control", C.O_RDWR)
out("open fd", fd, ffi.errno())
assert(fd >= 0)
for _, key in ipairs({"vup", "vdown"}) do
    local msg = string.format('msg::button\nid::%s\ndat:json:{"key":"bn_%s_%s","action":"forward"}\n', key, key, action)
    out("write", key, C.write(fd, msg, #msg), ffi.errno())
end
local buf = ffi.new("char[4096]")
local pfd = ffi.new("struct pollfd[1]")
pfd[0].fd = fd
pfd[0].events = C.POLLIN
local t_end = os.time() + seconds
while os.time() < t_end do
    if C.poll(pfd, 1, 1000) > 0 then
        local n = C.read(fd, buf, 4095)
        if n <= 0 then out("read", n, ffi.errno()) break end
        out("<<", (ffi.string(buf, n):gsub("\n", " | ")))
    end
end
C.close(fd)
out("RESULT done")
