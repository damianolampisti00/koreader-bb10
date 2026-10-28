-- LuaJIT sanity test for the BB10 port.
local ffi = require("ffi")
print("version", jit.version, "os", ffi.os, "arch", ffi.arch, "abi softfp", ffi.abi("softfp"), "hardfp", ffi.abi("hardfp"))
print("jit.status", jit.status())

ffi.cdef[[
size_t strlen(const char *s);
void qsort(void *base, size_t n, size_t sz, int (*cmp)(const void *, const void *));
]]
print("ffi strlen", ffi.C.strlen("bb10-q10"))

local function hot(n)
    local s = 0
    for i = 1, n do s = s + (i % 7) * 0.5 end
    return s
end
local t0 = os.clock()
local r = hot(50000000)
print(string.format("hot loop %.1f in %.2fs", r, os.clock() - t0))

local ok, err = pcall(function()
    local arr = ffi.new("int[5]", {5, 3, 9, 1, 7})
    local cb = ffi.cast("int (*)(const void *, const void *)", function(a, b)
        return ffi.cast("const int *", a)[0] - ffi.cast("const int *", b)[0]
    end)
    ffi.C.qsort(arr, 5, ffi.sizeof("int"), cb)
    cb:free()
    return string.format("%d %d %d %d %d", arr[0], arr[1], arr[2], arr[3], arr[4])
end)
print("ffi callback", ok, err)
print("RESULT OK")
