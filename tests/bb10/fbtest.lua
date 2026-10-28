-- Minimal libscreen test through ffi/bb10: run from the koreader dir.
require("setupkoenv")
local ffi = require("ffi")
local bb10 = require("ffi/bb10")
print("init...")
bb10.init()
print("size", bb10.width, bb10.height, "stride", bb10.stride, "dpi", bb10.dpi, "pixels", bb10.pixels)
-- Three bands, written as bytes {0xFF,0,0,0}, {0,0xFF,0,0}, {0,0,0xFF,0}: tells the byte order.
local p = ffi.cast("uint8_t *", bb10.pixels)
local band = math.floor(bb10.height / 3)
for y = 0, bb10.height - 1 do
    local b = math.min(2, math.floor(y / band))
    local row = p + y * bb10.stride
    for x = 0, bb10.width - 1 do
        row[x * 4], row[x * 4 + 1], row[x * 4 + 2], row[x * 4 + 3] = 0, 0, 0, 0xFF
        row[x * 4 + b] = 0xFF
    end
end
print("post")
bb10.post()
print("battery", bb10.getBatteryInfo())
ffi.C.sleep(4)
bb10.shutdown()
print("RESULT OK")
