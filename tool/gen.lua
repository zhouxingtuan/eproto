--
-- Created by IntelliJ IDEA.
-- User: zxt
-- Date: 2017/11/13
-- Time: 11:35
-- To change this template use File | Settings | File Templates.
--

local args = {...}

local info = debug.getinfo(1, "S") -- 第二个参数 "S" 表示仅返回 source,short_src等字段， 其他还可以 "n", "f", "I", "L"等 返回不同的字段信息
for k,v in pairs(info) do
    print(k,v)
end
local path = info.source
path = string.sub(path, 2, -1) -- 去掉开头的"@"
path = string.match(path, "^.*\\") -- 捕获最后一个 "/" 之前的部分 就是我们最终要的目录部分  
print("dir=", path)
path = path or "./"
package.path = package.path..";"..path.."?.lua;"
package.path = package.path..";"..path.."tool/?.lua;"

local file = args[1]
local print_flag = args[2]
local route = args[3]
local output_map = {}
for k=4,#args do
    output_map[args[k]] = true
end
local is_all_output = false
if next(output_map) == nil then
    is_all_output = true
end
print("param", file, print_flag)

local parser = require("parser")

local obj = parser.new(path, route)
obj:parseFile(file, nil, print_flag, is_all_output, output_map)
















