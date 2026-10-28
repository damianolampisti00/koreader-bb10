-- Which JIT-compiled construct corrupts memory on BB10? Run: luajit jitbisect.lua <phase>
local ffi = require("ffi")
ffi.cdef[[ int getpid(void); unsigned sleep(unsigned); ]]
local phase = tonumber(arg[1]) or 1
local function out(...) io.stdout:write(table.concat({...}, " "), "\n") io.stdout:flush() end
if phase == 1 then
    -- Plain Lua loop with table writes.
    local t = {}
    for i = 1, 2000000 do t[i % 1000 + 1] = i end
    out("phase1", t[1])
elseif phase == 2 then
    -- uint8_t stores through a pointer.
    local n = 720 * 736 * 4
    local buf = ffi.new("uint8_t[?]", n)
    local p = ffi.cast("uint8_t *", buf)
    for y = 0, 719 do
        local row = p + y * 2944
        for x = 0, 719 do row[x * 4], row[x * 4 + 1], row[x * 4 + 2], row[x * 4 + 3] = 1, 2, 3, 0xFF end
    end
    out("phase2", buf[0], buf[n - 1])
elseif phase == 3 then
    -- ffi.new in a hot loop (allocation + GC).
    local s = 0
    for i = 1, 300000 do local a = ffi.new("int[2]", i, i + 1) s = s + a[1] end
    out("phase3", s)
elseif phase == 4 then
    -- C calls from a hot loop.
    local s = 0
    for i = 1, 300000 do s = s + ffi.C.getpid() % 7 end
    out("phase4", s)
elseif phase == 5 then
    -- Strings & GC.
    local t = {}
    for i = 1, 200000 do t[i % 5000 + 1] = "s" .. i end
    collectgarbage()
    out("phase5", #t)
end
collectgarbage()
out("RESULT OK", phase)
