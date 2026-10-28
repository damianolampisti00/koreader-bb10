-- Load a generated cdecl file and check every declared function resolves.
-- usage: luajit cdecl_check.lua file.lua [lib ...]
local ffi = require("ffi")
local file = assert(arg[1])
dofile(file)
local libs = { ffi.C }
for i = 2, #arg do libs[#libs + 1] = ffi.load(arg[i]) end
local src = io.open(file):read("*a")
local ok, missing = 0, {}
for name in src:gmatch("\n[%w_ %*]-[%s%*]([%w_]+)%([^\n]*%);") do
    local found = false
    for _, l in ipairs(libs) do
        if pcall(function() return l[name] end) then found = true break end
    end
    if found then ok = ok + 1 else missing[#missing + 1] = name end
end
print("functions ok", ok)
if #missing > 0 then print("MISSING", table.concat(missing, " ")) end
print(#missing == 0 and "RESULT OK" or "RESULT FAIL")
