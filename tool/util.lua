--
-- Created by IntelliJ IDEA.
-- User: AppleTree
-- Date: 16/11/26
-- Time: 下午10:51
-- To change this template use File | Settings | File Templates.
--

local type = type
local pairs = pairs
local ipairs = ipairs
local string = string
local string_find = string.find
local string_sub = string.sub
local string_len = string.len
local string_reverse = string.reverse
local table_insert = table.insert


local util = {}

local shuffle = function(tb)
	if not tb then return end
	local cnt = #tb
	for i=1,cnt do
		local j = math.random(i,cnt)
		tb[i],tb[j] = tb[j],tb[i]
	end
end
util.shuffle = shuffle

local copy = function(res)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for key, value in pairs(object) do
			new_table[_copy(key)] = _copy(value)
		end
		return new_table
	end
	return _copy(res)
end
util.copy = copy

local function trim(s)
    s = string.gsub(s, "\n", "")
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end
util.trim = trim

local split = function(value, mark, skipZeroLength)
	local arr = {}
	local fromn = 1
	local token
	local startn, endn = string_find(value, mark, fromn)
	while startn ~= nil do
		token = string_sub( value, fromn, startn-1 )
        if skipZeroLength and #token == 0 then
            -- skip the empty data
        else
            table_insert(arr, token)
        end
		fromn = endn + 1
		startn, endn = string_find(value, mark, fromn)
	end
	token = string_sub( value, fromn, #value )
	table_insert(arr, token)
	return arr
end
util.split = split
local count = function(tab)
	local c = 0
	for _,_ in pairs(tab) do
		c = c + 1
	end
	return c
end
util.count = count
local isEmpty = function(tab)
	for _,_ in pairs(tab) do
		return false
	end
	return true
end
util.isEmpty = isEmpty

-- 该方法可以将中间有nil值的参数完全解开
local function param_unpack(t, s)
	s = s or 1
	local max = 0
	for i,_ in pairs(t) do
		if i > max then
			max = i
		end
	end
	local function up(t, i)
		if i < max then
			return t[i],up(t,i+1)
		else
			return t[i]
		end
	end
	return up(t,s)
end
util.unpack = param_unpack

local merge = function(des, res)
	local lookup_table = {}
	local _merge, _mergeTable
	_mergeTable = function(des_table, res_table)
		for k, v in pairs(res_table) do
			if type(k) == "table" then
				_merge(des_table, copy(k), v)
			else
				_merge(des_table, k, v)
			end
		end
	end
	_merge = function(dest, key, value)
		if type(value) ~= "table" then
			dest[key] = value
			return
		elseif lookup_table[value] then
			dest[key] = lookup_table[value]
			return
		end
		local dest_table = dest[key]
		if dest_table == nil or type(dest_table) ~= "table" then
			dest_table = {}
			dest[key] = dest_table
		end
		lookup_table[value] = dest_table
		_mergeTable(dest_table, value)
	end
	_mergeTable(des, res)
end
util.merge = merge

local checkType = function(obj, objtype)
	if type(objtype) ~= nil then
		return false
	end

	if type(obj) ~= objtype then
		return false
	end

	return true
end

util.checkType = checkType

--获取文件名
local function getFileName(str)
	local idx = str:match(".+()%.%w+$")
	if(idx) then
		return str:sub(1, idx-1)
	else
		return str
	end
end
util.getFileName = getFileName

--获取扩展名
local function getExtension(str)
	return str:match(".+%.(%w+)$")
end
util.getExtension = getExtension

local getFileNameOrPath = function( strpath, bname)  
    local ts = string_reverse(strpath)  
    local _, param2 = string_find(ts, "/")  -- 这里以"/"为例  
	local len = string_len(strpath) 
    local m = len - param2 + 1     
    local result  
    if bname then  
        result = string_sub(strpath, m+1, len)   
    else  
        result = string_sub(strpath, 1, m-1)   
    end  
  
    return result  
end  
util.getFileNameOrPath = getFileNameOrPath

local existArrayValue = function (tb, value)
	for i,v in ipairs(tb) do
		if v == value then
			return true, i
		end
	end
end
util.existArrayValue = existArrayValue

local existHashValue = function (tb, value)
	for k,v in pairs(tb) do
		if v == value then
			return true, k
		end
	end
end
util.existHashValue = existHashValue

return util
