-- Probe the mediaplayer/control "button" message format: print the server's reply per variant.
local ffi = require("ffi")
require("ffi/posix_h")
local C = ffi.C
local variants = {
    'dat:json:{"key":"bn_vup_short","action":"forward"}',
    'dat:json:{"key":"bn_vdown_short","action":"forward"}',
    'dat:json:{"key":"bn_vup_short_nothresh","action":"forward"}',
}
local buf = ffi.new("char[4096]")
local fd = C.open("/pps/services/multimedia/mediaplayer/control", C.O_RDWR)
assert(fd >= 0)
local pfd = ffi.new("struct pollfd[1]")
pfd[0].fd, pfd[0].events = fd, C.POLLIN
for i, dat in ipairs(variants) do
    local msg = string.format("msg::button\nid::%d\n%s\n", i, dat)
    C.write(fd, msg, #msg)
    local reply = "(no reply)"
    if C.poll(pfd, 1, 1500) > 0 then
        local n = C.read(fd, buf, 4095)
        reply = ffi.string(buf, n):gsub("\n", " | ")
    end
    io.stdout:write(i, "  ", dat, "  =>  ", reply, "\n")
end
C.close(fd)
