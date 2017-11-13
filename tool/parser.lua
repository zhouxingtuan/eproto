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
local table = table
local ipairs = ipairs
local string = string
local class = require("class")
local util = require("util")
local dump = require("dump")
local MessagePack = require("MessagePack")

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
	if save_file == nil then
		local name = util.getFileName(file)
		save_file = name..".pb"
	end
	local data = self:getFileData(file)
    -- first 3 byte is something magic
    data = string.sub(data, 4, #data)
--    local b,e  = string.find(data, "package")
--    print("package", b, e)
--    dump(data)
	local protos = self:parseData(data)
	local buf = MessagePack.pack(protos)
	self:setFileData(save_file, buf)
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
    end
end
function parser:findAnyThingInLine(arr)
    local first = arr[1]
    if first == "message" then
        self:pushMessage(arr[2])
    elseif first == "{" then

    elseif first == "}" then
        self:popMessage()
    elseif first == "optional" then

    elseif first == "repeated" then

    elseif first == "required" then

    elseif first == "map" then

    end
end
function parser:pushElement(data_type, index, name, key, value)
    local info = self:topMessage()
    local param
    if value == nil then
        param = {data_type, index, name, key}
    else
        param = {data_type, index, name, key, value}
    end
    table.insert(info.elements, param)
end
function parser:pushMessage(name)
    local info = {
        name = name;
        elements = {};
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
    self.m_full_message[full_name] = info.elements
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
