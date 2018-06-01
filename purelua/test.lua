--
-- Created by IntelliJ IDEA.
-- User: zxt
-- Date: 2018/6/1
-- Time: 11:33
-- To change this template use File | Settings | File Templates.
--

local info = debug.getinfo(1, "S") -- 第二个参数 "S" 表示仅返回 source,short_src等字段， 其他还可以 "n", "f", "I", "L"等 返回不同的字段信息
for k,v in pairs(info) do
    print(k, ":", v)
end
local path = info.source
path = string.sub(path, 2, -1) -- 去掉开头的"@"
path = string.match(path, "^.*\\") -- 捕获最后一个 "/" 之前的部分 就是我们最终要的目录部分  
path = path or "."
package.path = package.path..";"..path.."/?.lua;"
print("dir=", path)



local error = error
local pairs = pairs
local ipairs = ipairs
local pcall = pcall
local tostring = tostring
local type = type
local string = string
local char = string.char
local format = string.format
local math = math
local floor = math.floor
local tointeger = math.tointeger or floor
local frexp = math.frexp or mathx.frexp
local ldexp = math.ldexp or mathx.ldexp
local huge = math.huge
local table = table
local tconcat = table.concat


local dump = require("dump")
local json = require("json")

local log_debug = function(...)
    local args = {...}
    local arr = {}
    for _,v in ipairs(args) do
        if type(v) == "table" then
            table.insert(arr, json.encode(v))
        else
            table.insert(arr, tostring(v))
        end
    end
    print(table.concat(arr, " "))
end

local eproto = require("eproto")

eproto.register_file("test.pb")

local function testEproto()
    local req = {}
    req.a = 100;
    req.b = 123456789;
    req.c = 3.1415;
    req.d = 123456.789;
    req.e = "Hello";
    req.f = string.char(0, 0);
    req.g = {t1=0, t2=nil};
    req.h = {};
    req.h[1] = "a";
    req.h[2] = "b";
    req.j = {
        {t1=77, t2="w"};
    };
    local buf,err = eproto.encode("test.request", req)
    if not buf then
        log_debug("encode failed", err)
        return
    end
    local str = ""
    for k=1,#buf do
        str = str .. string.byte(buf, k) .. " "
    end
    log_debug("testEproto buffer length", #buf, "byte", str)
    local data = eproto.unpack(buf)

    local time1 = os.clock()
    for k=1,10000 do
        buf = eproto.encode("test.request", req)
    end
    local time2 = os.clock()
    log_debug("encode cost", time2 - time1, "#buf", #buf)
    local r
    for k=1,10000 do
        r = eproto.decode("test.request", buf)
    end
    local time3 = os.clock()
    log_debug("decode cost", time3 - time2)
    dump(r)
--    local arr = {   156, 100, 206, 7, 91, 205, 21, 202, 64, 73,
--        14, 86, 203, 64, 254, 36, 12, 159, 190, 118,
--        201, 165, 72, 101, 108, 108, 111, 196, 2, 0,
--        0, 146, 0, 192, 130, 1, 161, 97, 2, 161,
--        98, 192, 145, 146, 77, 161, 119, 192, 192 }
--    local arrstr = ""
--    for _,b in ipairs(arr) do
--        arrstr = arrstr .. string.char(b)
--    end
--    local data, err = eproto.decode("test.request", arrstr)
--    log_debug("data", err, data)
end

testEproto()
