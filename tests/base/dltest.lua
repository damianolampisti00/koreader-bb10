local ffi = require("ffi")
local ok_n, bad = 0, {}
for name in io.popen("ls libs"):lines() do
    if name:match("%.so") then
        local ok, err = pcall(ffi.load, "./libs/" .. name)
        if ok then ok_n = ok_n + 1 else bad[#bad + 1] = name .. ": " .. tostring(err) end
    end
end
package.cpath = "./common/?.so;./common/?/?.so;" .. package.cpath
for _, m in ipairs({"lpeg", "rapidjson", "socket.score", "mime.mcore", "ssl"}) do
    local ok, err = pcall(require, m)
    if ok then ok_n = ok_n + 1 else bad[#bad + 1] = m .. ": " .. tostring(err) end
end
print("loaded", ok_n)
for _, b in ipairs(bad) do print("FAIL", b) end
print(#bad == 0 and "RESULT OK" or "RESULT FAIL")
