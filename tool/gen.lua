--
-- Created by IntelliJ IDEA.
-- User: zxt
-- Date: 2017/11/13
-- Time: 11:35
-- To change this template use File | Settings | File Templates.
--

local info = debug.getinfo(1, "S") -- 第二个参数 "S" 表示仅返回 source,short_src等字段， 其他还可以 "n", "f", "I", "L"等 返回不同的字段信息
local path = info.source
path = string.sub(path, 2, -1) -- 去掉开头的"@"
path = string.match(path, "^.*\\") -- 捕获最后一个 "/" 之前的部分 就是我们最终要的目录部分  
print("dir=", path)
package.path = package.path..";"..path.."?.lua;"


local MessagePack = require("MessagePack")

local ep_type_nil = 1
local ep_type_bool = 2
local ep_type_float = 3
local ep_type_int = 4
local ep_type_string = 5
local ep_type_array = 6
local ep_type_map = 7
local ep_type_message = 8
local reg_info = {
    HelloWorld = {
        {ep_type_int, 1, "id", 0};
        {ep_type_string, 2, "str", 0};
        {ep_type_int, 3, "opt", 0};
        {ep_type_int, 4, "time", 0};
        {ep_type_array, 5, "addrs", "Address"};
    };
    Address = {
        {ep_type_string, 1, "addr", 0};
        {ep_type_int, 2, "num", 0};
        {ep_type_string, 3, "phone", 0};
    };
}

local buf = MessagePack.pack(reg_info)

print("buf len", #buf)

local json = require("json")

local buf = json.encode(reg_info)

print("buf len", #buf, buf)

local parser = require("parser")

local obj = parser.new(path)
obj:parseFile("invitemgr_client.proto")
















