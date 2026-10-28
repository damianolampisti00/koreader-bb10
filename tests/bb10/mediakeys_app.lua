-- Experiment, loaded by the app at startup: register the volume keys on
-- /pps/services/multimedia/mediaplayer/control from the app's own process, and log the replies.
local ffi = require("ffi")
require("ffi/posix_h")
local C = ffi.C
local logger = require("logger")
local variants = {
    "key::bn_vup\naction::short",
    'dat:json:{"key":"bn_vup","action":"short"}',
    "key::bn_vdown\naction::short",
}
local fd = C.open("/pps/services/multimedia/mediaplayer/control", C.O_RDWR)
logger.info("MEDIAKEYS open", fd, ffi.errno())
if fd < 0 then return end
local buf = ffi.new("char[4096]")
local pfd = ffi.new("struct pollfd[1]")
pfd[0].fd, pfd[0].events = fd, C.POLLIN
for i, v in ipairs(variants) do
    local msg = string.format("msg::button\nid::%d\n%s\n", i, v)
    C.write(fd, msg, #msg)
    local reply = "(no reply)"
    if C.poll(pfd, 1, 1500) > 0 then
        local n = C.read(fd, buf, 4095)
        reply = ffi.string(buf, n):gsub("\n", " | ")
    end
    logger.info("MEDIAKEYS", i, v:gsub("\n", " "), "=>", reply)
end
-- Keep fd open (registrations may be tied to it).
_G.MEDIAKEYS_FD = fd
