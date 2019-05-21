--
-- Created by IntelliJ IDEA.
-- User: zxt
-- Date: 2018/5/30
-- Time: 16:07
-- To change this template use File | Settings | File Templates.
--

local ep_type_nil = 1
local ep_type_bool = 2
local ep_type_float = 3
local ep_type_int = 4
local ep_type_string = 5
local ep_type_bytes = 6
local ep_type_array = 7
local ep_type_map = 8
local ep_type_message = 9

local protobuf_to_cpp = {
    double = "double";
    float = "float";
    int32 = "int";
    int64 = "long long int";
    uint32 = "unsigned int";
    uint64 = "unsigned long long int";
    sint32 = "int";
    sint64 = "long long int";
    fixed32 = "unsigned int";
    fixed64 = "unsigned long long int";
    sfixed32 = "int";
    sfixed64 = "long long int";
    bool = "bool";
    string = "std::string";
    bytes = "std::vector<char>";
}

local prettyStep = "    "

local print = print
local io = io
local table = table
local pairs = pairs
local ipairs = ipairs
local string = string
local tonumber = tonumber
local class = require("class")
local util = require("util")
local dump = require("dump")

local parser_cpp = class("parser_cpp")

function parser_cpp:ctor(packageName, full_path_info)
    self.m_packageName = packageName
    self.m_full_path_info = full_path_info
end

function parser_cpp:genCode()
    local namespaceMap,defaultNSMap = self:splitNamespace()
    --    dump(namespaceMap)
    --    dump(defaultNSMap)
    local code = [[
#include "eproto.hpp"

]]
    if next(defaultNSMap.childMap) then
        code = code .. self:genNamespace(nil, defaultNSMap.childMap)
    else
        for namespace,info in pairs(namespaceMap) do
            code = code .. self:genNamespace(namespace, info.childMap)
        end
    end
    return code
end

function parser_cpp:genNamespace(namespace, childMap)
    local template
    if namespace == nil then
        template = [[
%s
%s
]]
        namespace = "\n"
    else
        template = [[
namespace %s
{
%s
}
]]
    end
    local classCode = ""
    local prettyShow = prettyStep
    for className,classInfo in pairs(childMap) do
        classCode = classCode .. self:genClass(className, classInfo.elementArray, classInfo.childMap, prettyShow, false)
    end
    local code = string.format(template, namespace, classCode)
    return code
end
function parser_cpp:genClass(className, elementArray, childMap, prettyShow, isPublic)
    --[[
    -- subClasses
    -- params
    -- Encode
    -- Decode
    -- ]]
    local template = [[%sclass %s : public Proto
%s{
%s%s%s%s%s
%s}
]]
    local nextPrettyShow = prettyShow..prettyStep
    local beforeClass = prettyShow
    if isPublic then
--        beforeClass = beforeClass .. "public "
    end
    local subClasses = ""
    local publicLine = prettyShow.."public:\n"
    subClasses = subClasses .. publicLine
    for name,info in pairs(childMap) do
        subClasses = subClasses .. self:genClass(name, info.elementArray, info.childMap, nextPrettyShow, true)
    end
    local params = self:genParams(elementArray, nextPrettyShow)
    local Encode = self:genEncode(elementArray, nextPrettyShow)
    local Decode = self:genDecode(elementArray, nextPrettyShow)
    local Create = self:genCreate(className, nextPrettyShow)
    local classCode = string.format(template,
        beforeClass, className,
        prettyShow,
        subClasses, params, Encode, Decode, Create,
        prettyShow)
    return classCode
end
function parser_cpp:genParams(elementArray, prettyShow)
    local paramCode = ""
    for k,elementInfo in ipairs(elementArray) do
        local name = elementInfo[1]
        local raw_type = elementInfo[2]
        local cpp_type = protobuf_to_cpp[raw_type]
        if cpp_type == nil then
            if raw_type == "array" then
                local raw_key = elementInfo[3]
                local key_type = protobuf_to_cpp[raw_key]
                if key_type == nil then
                    key_type = raw_key
                end
                cpp_type = "std::vector<"..key_type..">"
            elseif raw_type == "map" then
                local raw_key = elementInfo[3]
                local raw_value = elementInfo[4]
                local key_type = protobuf_to_cpp[raw_key]
                if key_type == nil then
                    key_type = raw_key
                end
                local value_type = protobuf_to_cpp[raw_value]
                if value_type == nil then
                    value_type = raw_value
                end
                cpp_type = "std::unordered_map<"..key_type..", "..value_type..">"
            else
                --                print("unsupport protobuf type to cpp type", raw_type)
                cpp_type = raw_type
            end
        end
        local lineCode = prettyShow .. cpp_type .. " " .. name .. ";\n"
        paramCode = paramCode .. lineCode
    end
    return paramCode
end
function parser_cpp:genEncode(elementArray, prettyShow)
    local nextPrettyShow = prettyShow..prettyStep
    local bodyCode = prettyShow .. "virtual void Encode(Writer& wb)\n"
    bodyCode = bodyCode .. prettyShow .. "{\n"
    bodyCode = bodyCode .. nextPrettyShow .. string.format("wb.pack_array(wb, %s);\n", #elementArray)
    for k,elementInfo in ipairs(elementArray) do
        local name = elementInfo[1]
        local raw_type = elementInfo[2]
        local this_name = "this->"..name
        local cpp_type = protobuf_to_cpp[raw_type]
        if cpp_type == nil then
            local nextNextPrettyShow = nextPrettyShow .. prettyStep
            local nextNextNextPrettyShow = nextNextPrettyShow .. prettyStep
            if raw_type == "map" then
                local raw_key = elementInfo[3]
                local raw_value = elementInfo[4]
                local index_name = "i"
                bodyCode = bodyCode .. nextPrettyShow .. string.format("if (%s == null) { wb.pack_nil(); } else {\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("wb.pack_map(%s.size());\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("for(auto &%s : %s)\n", index_name, this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. "{\n"
                local raw_key_cpp_type = protobuf_to_cpp[raw_key]
                local raw_value_cpp_type = protobuf_to_cpp[raw_value]
                local raw_key_name = string.format("%s.first", index_name)
                if raw_key_cpp_type == nil then
                    -- 自定义对象
                    print("it's not support for self define key for Dictionary")
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByDefine(raw_key_name)
                else
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByType(raw_key_name, raw_key_cpp_type)
                end
                local raw_value_name = string.format("%s.second", index_name)
                if raw_value_cpp_type == nil then
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByDefine(raw_value_name)
                else
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByType(raw_value_name, raw_value_cpp_type)
                end
                bodyCode = bodyCode .. nextNextPrettyShow .. "}\n"
                bodyCode = bodyCode .. nextPrettyShow .. "}\n"
            elseif raw_type == "array" then
                local raw_key = elementInfo[3]
                local index_name = "i"
                local value_name = "v"
                local value_at_index = this_name.."["..index_name.."]"
                bodyCode = bodyCode .. nextPrettyShow .. string.format("if (%s == null) { wb.pack_nil(); } else {\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("wb.pack_array(%s.size());\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("for(int %s=0; %s<%s.size(); ++%s)\n", index_name, index_name, this_name, index_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. "{\n"
                local raw_key_cpp_type = protobuf_to_cpp[raw_key]
                if raw_key_cpp_type == nil then
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s %s = %s;\n", raw_key, value_name, value_at_index)
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByDefine(value_name)
                else
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s %s = %s;\n", raw_key_cpp_type, value_name, value_at_index)
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByType(value_name, raw_key_cpp_type)
                end
                bodyCode = bodyCode .. nextNextPrettyShow .. "}\n"
                bodyCode = bodyCode .. nextPrettyShow .. "}\n"
            else
                -- 自定义对象
                bodyCode = bodyCode .. nextPrettyShow .. self:getPackByDefine(this_name)
            end
        else
            -- C++内置数据类型
            bodyCode = bodyCode .. nextPrettyShow .. self:getPackByType(this_name, cpp_type)
        end
    end
    bodyCode = bodyCode .. prettyShow .. "}\n"
    return bodyCode
end
function parser_cpp:getPackByDefine(name)
    return string.format("if (%s == null) { wb.pack_nil(); } else { %s.Encode(wb); }\n", name, name)
end
function parser_cpp:getPackByType(name, cpp_type)
    if cpp_type == "string" then
        return string.format("wb.pack_string(%s);\n", name)
    elseif cpp_type == "std::vector<char>" then
        return string.format("wb.pack_bytes(%s);\n", name)
    elseif cpp_type == "float" or cpp_type == "double" then
        return string.format("wb.pack_double(%s);\n", name)
    elseif cpp_type == "bool" then
        return string.format("wb.pack_bool(%s);\n", name)
    else
        return string.format("wb.pack_int(%s);\n", name)
    end
end
function parser_cpp:genDecode(elementArray, prettyShow)
    local nextPrettyShow = prettyShow..prettyStep
    local bodyCode = prettyShow .. "virtual void Decode(Reader& rb)\n"
    bodyCode = bodyCode .. prettyShow .. "{\n"
    local count_name = "c"
    local count_skip = nextPrettyShow .. string.format("if (--%s <= 0) { return; }\n", count_name)
    bodyCode = bodyCode .. nextPrettyShow .. string.format("long %s = rb.unpack_array();\n", count_name)
    bodyCode = bodyCode .. nextPrettyShow .. string.format("if (%s <= 0) { return; }\n", count_name)
    for k,elementInfo in ipairs(elementArray) do
        local name = elementInfo[1]
        local raw_type = elementInfo[2]
        local this_name = "this->"..name
        local cpp_type = protobuf_to_cpp[raw_type]
        if cpp_type == nil then
            local nextNextPrettyShow = nextPrettyShow .. prettyStep
            local nextNextNextPrettyShow = nextNextPrettyShow .. prettyStep
            local nextNextNextNextPrettyShow = nextNextNextPrettyShow .. prettyStep
            if raw_type == "map" then
                local raw_key = elementInfo[3]
                local raw_value = elementInfo[4]
                local index_name = "i"
                local raw_key_cpp_type = protobuf_to_cpp[raw_key]
                local raw_value_cpp_type = protobuf_to_cpp[raw_value]
                local decl_key,decl_value,decl_key_default,decl_value_default
                if raw_key_cpp_type == nil then
                    decl_key = raw_key
                else
                    decl_key = raw_key_cpp_type
                end
                if raw_value_cpp_type == nil then
                    decl_value = raw_value
                else
                    decl_value = raw_value_cpp_type
                end
                decl_key_default = self:getDefaultDeclValue(raw_key_cpp_type)
                decl_value_default = self:getDefaultDeclValue(raw_value_cpp_type)
                cpp_type = "Dictionary<"..decl_key..", "..decl_value..">"
                bodyCode = bodyCode .. nextPrettyShow .. "{\n"
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("long n = rb.unpack_map();\n")
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("if (n < 0) { %s=null; } else {\n", this_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s = new %s();\n", this_name, cpp_type)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("for(int %s=0; %s<n; ++%s)\n", index_name, index_name, index_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. "{\n"
                bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s k=%s; %s v=%s;\n", decl_key, decl_key_default, decl_value, decl_value_default)
                if raw_key_cpp_type == nil then
                    -- 自定义对象
                    print("it's not support for self define key for Dictionary")
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByDefine("k", raw_key)
                else
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByType("k", raw_key_cpp_type)
                end
                if raw_value_cpp_type == nil then
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByDefine("v", raw_value)
                else
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByType("v", raw_value_cpp_type)
                end
                if raw_key_cpp_type == "string" then
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("if (k != null) { %s[k] = v; }\n", this_name)
                else
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s[k] = v;\n", this_name)
                end
                bodyCode = bodyCode .. nextNextNextPrettyShow .. "}\n"
                bodyCode = bodyCode .. nextNextPrettyShow .. "}\n"
                bodyCode = bodyCode .. nextPrettyShow .. "}\n"
            elseif raw_type == "array" then
                local raw_key = elementInfo[3]
                local index_name = "i"
                local value_name = "v"
                local raw_key_cpp_type = protobuf_to_cpp[raw_key]
                local decl_key,decl_key_default
                if raw_key_cpp_type == nil then
                    decl_key = raw_key
                else
                    decl_key = raw_key_cpp_type
                end
                cpp_type = decl_key.."[n]"
                bodyCode = bodyCode .. nextPrettyShow .. "{\n"
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("long n = rb.unpack_array();\n")
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("if (n < 0) { %s=null; } else {\n", this_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s = new %s;\n", this_name, cpp_type)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("for(int %s=0; %s<n; ++%s)\n", index_name, index_name, index_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. "{\n"
                decl_key_default = self:getDefaultDeclValue(raw_key_cpp_type)
                bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s v=%s;\n", decl_key, decl_key_default)
                if raw_key_cpp_type == nil then
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByDefine("v", raw_key)
                else
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByType("v", raw_key_cpp_type)
                end
                bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s[%s] = v;\n", this_name, index_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. "}\n"
                bodyCode = bodyCode .. nextNextPrettyShow .. "}\n"
                bodyCode = bodyCode .. nextPrettyShow .. "}\n"
            else
                -- 自定义对象
                bodyCode = bodyCode .. nextPrettyShow .. self:getUnpackByDefine(this_name, raw_type)
            end
        else
            -- C++内置数据类型
            bodyCode = bodyCode .. nextPrettyShow .. self:getUnpackByType(this_name, cpp_type)
        end
        bodyCode = bodyCode .. count_skip
    end
    bodyCode = bodyCode .. nextPrettyShow .. string.format("rb.unpack_discard(%s);\n", count_name)
    bodyCode = bodyCode .. prettyShow .. "}\n"
    return bodyCode
end
function parser_cpp:genCreate(className, prettyShow)
    local str = string.format("%svirtual Proto* Create() { return new %s(); }", prettyShow, className)
    return str
end
function parser_cpp:getDefaultDeclValue(cpp_type)
    if cpp_type == nil then
        return "null"
    else
        if cpp_type == "string" then
            return "null"
        elseif cpp_type == "std::vector<char>" then
            return "std::vector<char>()"
        elseif cpp_type == "bool" then
            return "false"
        else
            return "0"
        end
    end
end
function parser_cpp:getUnpackByDefine(name, raw_key)
    return string.format("if (rb.NextIsNil()) { rb.MoveNext(); } else { %s = new %s(); %s.Decode(rb); }\n", name, raw_key, name)
end
function parser_cpp:getUnpackByType(name, cpp_type)
    if cpp_type == "string" then
        return  string.format("rb.unpack_string(ref %s);\n", name)
    elseif cpp_type == "std::vector<char>" then
        return string.format("rb.unpack_bytes(ref %s);\n", name)
    elseif cpp_type == "float" or cpp_type == "double" then
        return string.format("rb.unpack_double(ref %s);\n", name)
    elseif cpp_type == "bool" then
        return string.format("rb.unpack_bool(ref %s);\n", name)
    else
        return string.format("rb.unpack_int(ref %s);\n", name)
    end
end
function parser_cpp:splitNamespace()
    local m_packageName = self.m_packageName
    local m_full_path_info = self.m_full_path_info
    local namespaceMap = {}
    local defaultNSMap = {
        childMap = {};
    }
    for full_path,info in pairs(m_full_path_info) do
        local arr = util.split(full_path, "%.")
        local packageName = arr[1]
        if #arr > 1 and packageName == m_packageName then
            -- 有外层namespace
            local nsMap = namespaceMap[packageName]
            if nsMap == nil then
                nsMap = {
                    childMap = {};
                }
                namespaceMap[packageName] = nsMap
            end
            for k=2,#arr do
                local protoName = arr[k]
                local pMap = nsMap.childMap[protoName]
                if pMap == nil then
                    pMap = {
                        childMap = {};
                    }
                    nsMap.childMap[protoName] = pMap
                end
                if k == #arr then
                    pMap.elementArray = info.raw_elements
                end
                nsMap = pMap
            end
        else
            -- 没有外层namespace
            local nsMap = defaultNSMap
            for k=1,#arr do
                local protoName = arr[k]
                local pMap = nsMap.childMap[protoName]
                if pMap == nil then
                    pMap = {
                        childMap = {};
                    }
                    nsMap.childMap[protoName] = pMap
                end
                if k == #arr then
                    pMap.elementArray = info.raw_elements
                end
                nsMap = pMap
            end
        end
    end
    return namespaceMap,defaultNSMap
end

return parser_cpp
