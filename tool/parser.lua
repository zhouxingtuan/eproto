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

local protobuf_to_eproto = {
	double = ep_type_float;
	float = ep_type_float;
	int32 = ep_type_int;
	int64 = ep_type_int;
	uint32 = ep_type_int;
	uint64 = ep_type_int;
	sint32 = ep_type_int;
	sint64 = ep_type_int;
	fixed32 = ep_type_int;
	fixed64 = ep_type_int;
	sfixed32 = ep_type_int;
	sfixed64 = ep_type_int;
	bool = ep_type_bool;
	string = ep_type_string;
	bytes = ep_type_string;
}

local print = print
local io = io
local table = table
local ipairs = ipairs
local string = string
local tonumber = tonumber
local class = require("class")
local util = require("util")
local dump = require("dump")
local MessagePack = require("MessagePack")
local json = require("json")

local parser = class("parser")

function parser:ctor(path)
	self.m_path = path
    self.m_package = nil
    self.m_error_code = nil
    self.m_message_stack = {}
    self.m_full_message = {}
    self.m_current_message = {}
end

function parser:parseFile(file, save_file)
	local name = util.getFileName(file)
	if save_file == nil then
		save_file = name..".pb"
	end
	local data = self:getFileData(file)
    -- first 3 byte is something magic
    data = string.sub(data, 4, #data)
--    local b,e  = string.find(data, "package")
--    print("package", b, e)
--    dump(data)
	local protos = self:parseData(data)
	if self.m_error_code ~= nil then
		print("current parse data failed with error code", self.m_error_code)
		return
	end

	local buf = MessagePack.pack(protos)
	self:setFileData(save_file, buf)

	local json_file = name..".json"
	local json_buf = json.encode(protos)
	self:setFileData(json_file, json_buf)

	return protos
end
function parser:parseData(data)
    local lines = self:splitLines(data)
    local linesArr = self:splitEmptyMark(lines)
    dump(linesArr)
    self:findPackage(linesArr)
    self:parseLines(linesArr)
	return self.m_full_message
end
function parser:parseLines(linesArr)
    for _,arr in ipairs(linesArr) do
        self:findAnyThingInLine(arr)
		if self.m_error_code ~= nil then
			return
		end
    end
end
function parser:findAnyThingInLine(arr)
    local first = arr[1]
	first = first:lower()
    if first == "message" then
        self:pushMessage(arr[2], first)
    elseif first == "{" then
		-- message or enum begin
    elseif first == "}" then
        self:popMessage()
	elseif first == "required" then
		self:checkElementSingle(arr)
    elseif first == "optional" then
		self:checkElementSingle(arr)
    elseif first == "repeated" then
		self:checkElementArray(arr)
    elseif first == "map" then
		self:checkElementMap(arr)
    elseif first == "enum" then
		self:pushMessage(arr[2], first)
	elseif first == "package" then
		self.m_package = arr[2]
		print("package_name", self.m_package)
	else
		local info = self:topMessage()
		if info and info.type == "enum" then
			self:pushEnum(arr[1], arr[2])
		else
			print("current first string is not valid", first)
		end
    end
end
function parser:checkElementSingle(arr)
	local info = self:topMessage()
	local type_name = arr[2]
	local name = arr[3]
	local index = tonumber(arr[4])
	if not index then
		print("current message", info.name, "index is not a number", type(index), index)
		self.m_error_code = 1
		return
	end
	local type_fullname
	-- find normal data type
	local data_type = protobuf_to_eproto[type_name]
	if data_type == nil then
		-- find current proto
		local msg_info = self:findMessage(type_name)
		if msg_info ~= nil then
			if msg_info.type == "enum" then
				type_fullname = 0
				data_type = ep_type_int
			else
				type_fullname = msg_info.full_name
				data_type = ep_type_message
			end
		else
			type_fullname = type_name
			data_type = ep_type_message
		end
	else
		-- the last param for normal type data
		type_fullname = 0
	end
	self:pushElement(data_type, index, name, type_fullname)
end
function parser:checkElementArray(arr)
	local info = self:topMessage()
	local type_name = arr[2]
	local name = arr[3]
	local index = tonumber(arr[4])
	if not index then
		print("current message", info.name, "index is not a number", type(index), index)
		self.m_error_code = 2
		return
	end
	local data_type = ep_type_array
	local type_fullname = protobuf_to_eproto[type_name]
	if type_fullname == nil then
		-- find current proto
		local msg_info = self:findMessage(type_name)
		if msg_info ~= nil then
			if msg_info.type == "enum" then
				type_fullname = ep_type_int
			else
				type_fullname = msg_info.full_name
			end
		else
			type_fullname = type_name
		end
	end
	self:pushElement(data_type, index, name, type_fullname)
end
function parser:checkElementMap(arr)
	local info = self:topMessage()
	local key_type = arr[2]
	local value_type = arr[3]
	local name = arr[4]
	local index = tonumber(arr[5])
	if not index then
		print("current map", info.name, "index is not a number", type(index), index)
		self.m_error_code = 3
		return
	end
	local data_type = ep_type_map
	local key = protobuf_to_eproto[key_type]
	if key == nil then
		print("current map", info.name, "key must be a normal type", key)
		self.m_error_code = 4
		return
	end
	local value = protobuf_to_eproto[value_type]
	if value == nil then
		-- find current proto
		local msg_info = self:findMessage(value_type)
		if msg_info ~= nil then
			if msg_info.type == "enum" then
				value = ep_type_int
			else
				value = msg_info.full_name
			end
		else
			value = value_type
		end
	end
	self:pushElement(data_type, index, name, key, value)
end
function parser:pushEnum(key, value)
	local info = self:topMessage()
	value = tonumber(value)
	if not value then
		print("current enum", info.name, "value is not a number", type(value), value)
		self.m_error_code = 5
		return
	end
	-- check data
	if info.name_hash[key] ~= nil then
		print("current enum", info.name, "has the same name for key", key)
		self.m_error_code = 6
		return
	end
	if info.index_hash[value] ~= nil then
		print("current enum", info.name, "has the same index", key, value)
		self.m_error_code = 7
		return
	end
	info.name_hash[key] = value
	info.index_hash[value] = key
	local param = {key, value}
	table.insert(info.elements, param)
end
function parser:pushElement(data_type, index, name, key, value)
    local info = self:topMessage()
	-- check data
	if info.name_hash[name] ~= nil then
		print("current message", info.name, "has the same name for key", name)
		self.m_error_code = 8
		return
	end
	if info.index_hash[index] ~= nil then
		print("current message", info.name, "has the same index", index)
		self.m_error_code = 9
		return
	end
    local param
    if value == nil then
        param = {data_type, index, name, key}
    else
        param = {data_type, index, name, key, value}
	end
	info.name_hash[name] = param
	info.index_hash[index] = param
    table.insert(info.elements, param)
end
function parser:pushMessage(name, type)
    local info = {
		type = type;
        name = name;
        elements = {};
		name_hash = {};
		index_hash = {};
        full_name = nil;
        path_name = nil;
    }
    self:setCurrentMessage(name, info)
    local m_message_stack = self.m_message_stack
    m_message_stack[#m_message_stack+1] = info
end
function parser:popMessage()
    local m_message_stack = self.m_message_stack
    if m_message_stack[#m_message_stack] == nil then
		self.m_error_code = 10
		print("popMessage error current stack is empty")
        return
    end
    m_message_stack[#m_message_stack] = nil
end
function parser:topMessage()
    local m_message_stack = self.m_message_stack
    return m_message_stack[#m_message_stack]
end
function parser:setCurrentMessage(name, info)
    local full_name,path_name = self:getFullName(name, false)
    info.full_name = full_name
    info.path_name = path_name
	if info.type == "message" then
    	self.m_full_message[full_name] = info.elements
	end
    self.m_current_message[path_name] = info
end
function parser:getCurrentMessage()
    local full_name,path_name = self:getFullName(nil, false)
    return self.m_current_message[path_name]
end
function parser:getFullMessage()
    local full_name,path_name = self:getFullName(nil, false)
    return self.m_full_message[full_name]
end
function parser:findMessage(name)
    local full_name,path_name = self:getFullName(name, true)
    return self.m_current_message[path_name]
end
function parser:getFullName(name, skipTop)
    local arr = {}
    local m_message_stack = self.m_message_stack
    local stop_index = #m_message_stack
    if skipTop then
        stop_index = stop_index - 1
    end
    for k=1,stop_index do
        table.insert(arr, m_message_stack[k].name)
    end
    if name and name ~= "" then
        table.insert(arr, name)
    end
    local path_name = table.concat(arr, ".")
    local full_name
    if self.m_package ~= nil then
        full_name = self.m_package.."."..path_name
    end
    return full_name,path_name
end
function parser:splitEmptyMark(lines)
    local linesArr = {}
    for _,line in ipairs(lines) do
        line = string.gsub(line, "<", " ")
        line = string.gsub(line, ">", " ")
        line = string.gsub(line, ",", " ")
        local arr = util.split(line, " ", true)
        if #arr > 0 then
            for k,v in ipairs(arr) do
                arr[k] = util.trim(v)
            end
            table.insert(linesArr, arr)
        end
    end
    return linesArr
end
function parser:splitLines(data)
    local arr = util.split(data, "\n")
    print("total lines", #arr)
    local function find_mark_split(line, mark)
        local la = {}
        local b,e = string.find(line, mark)
        if b and b > 1 then
            local l1 = string.sub(line, 1, b-1)
            local l2 = string.sub(line, b, e)
            local l3 = string.sub(line, e+1, #line)
            if #l1 > 0 then
                table.insert(la, l1)
            end
            if #l2 > 0 then
                table.insert(la, l2)
            end
            if #l3 > 0 then
                table.insert(la, l3)
            end
        end
        return la
    end
    local lines = {}
    for k=1,#arr do
        local line = arr[k]
        -- find // and remove every thing after that
        local b,e = string.find(line, "//")
        if b then
            line = string.sub(line, 1, b-1)
        end
        line = string.gsub(line, "=", "")
        line = string.gsub(line, ";", "")
        line = util.trim(line)
        if #line > 0 then
            local la = find_mark_split(line, "{")
            if #la > 0 then
                for _,s in ipairs(la) do
                    table.insert(lines, s)
                end
            else
                local la = find_mark_split(line, "}")
                if #la > 0 then
                    for _,s in ipairs(la) do
                        table.insert(lines, s)
                    end
                else
                    table.insert(lines, line)
                end
            end
        end
    end
    print("lines trim", #lines)
--    dump(lines)
    return lines
end
function parser:findPackage(linesArr)
    for _,arr in ipairs(linesArr) do
        if arr[1] == "package" then
            self.m_package = arr[2]
            print("package_name", self.m_package)
            return
        end
    end
    print("can not find package name")
end
function parser:setFileData(file, buf)
	local file_path = self.m_path.."/"..file
	print("set file data", file_path)
	local f = io.open(file_path, "wb")
	f:write(buf)
	f:close()
end
function parser:getFileData(file)
	local file_path = self.m_path.."/"..file
	print("get file data", file_path)
	local f = io.open(file_path, "r")
	local data = f:read("*a")
	f:close()
	return data
end

return parser
