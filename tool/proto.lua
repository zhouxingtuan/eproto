--
-- Created by IntelliJ IDEA.
-- User: zxt
-- Date: 2017/11/13
-- Time: 10:51
-- To change this template use File | Settings | File Templates.
--

local ep_type_nil = 1
local ep_type_bool = 2
local ep_type_float = 3
local ep_type_int = 4
local ep_type_string = 5
local ep_type_array = 6
local ep_type_map = 7
local ep_type_message = 8

local print = print
local io = io
local class = require("class")
local dump = require("dump")
local MessagePack = require("MessagePack")

local ParseProto = class("ParseProto")

function ParseProto:ctor(path)
	self.m_path = path
end

function ParseProto:parseFile(file)
    local file_path = self.m_path.."/"..file
	local data = self:getFileData(file_path)

end
function ParseProto:getFileData(file_path)
    print(file_path)
	local f = io.open(file_path, "rb")
	local data = f:read("*all")
	f:close()
	return data
end

return ParseProto
