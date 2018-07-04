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

local protobuf_to_csharp = {
    double = "double";
    float = "float";
    int32 = "int";
    int64 = "long";
    uint32 = "uint";
    uint64 = "ulong";
    sint32 = "int";
    sint64 = "long";
    fixed32 = "uint";
    fixed64 = "ulong";
    sfixed32 = "int";
    sfixed64 = "long";
    bool = "bool";
    string = "string";
    bytes = "byte[]";
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

local parser_csharp = class("parser_csharp")

function parser_csharp:ctor(packageName, full_path_info)
    self.m_packageName = packageName
    self.m_full_path_info = full_path_info
end

function parser_csharp:genCode()
    local namespaceMap,defaultNSMap = self:splitNamespace()
    --    dump(namespaceMap)
    --    dump(defaultNSMap)
    local code = [[
using System;
using System.Text;
using System.Collections.Generic;
using Erpc;

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

function parser_csharp:genNamespace(namespace, childMap)
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
function parser_csharp:genClass(className, elementArray, childMap, prettyShow, isPublic)
    --[[
    -- subClasses
    -- params
    -- Encode
    -- Decode
    -- ]]
    local template = [[%sclass %s : Proto
%s{
%s%s%s%s%s
%s}
]]
    local nextPrettyShow = prettyShow..prettyStep
    local beforeClass = prettyShow
    if isPublic then
        beforeClass = beforeClass .. "public "
    end
    local subClasses = ""
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
function parser_csharp:genParams(elementArray, prettyShow)
    local paramCode = ""
    for k,elementInfo in ipairs(elementArray) do
        local name = elementInfo[1]
        local raw_type = elementInfo[2]
        local csharp_type = protobuf_to_csharp[raw_type]
        if csharp_type == nil then
            if raw_type == "array" then
                local raw_key = elementInfo[3]
                local key_type = protobuf_to_csharp[raw_key]
                if key_type == nil then
                    key_type = raw_key
                end
                csharp_type = key_type.."[]"
            elseif raw_type == "map" then
                local raw_key = elementInfo[3]
                local raw_value = elementInfo[4]
                local key_type = protobuf_to_csharp[raw_key]
                if key_type == nil then
                    key_type = raw_key
                end
                local value_type = protobuf_to_csharp[raw_value]
                if value_type == nil then
                    value_type = raw_value
                end
                csharp_type = "Dictionary<"..key_type..", "..value_type..">"
            else
                --                print("unsupport protobuf type to csharp type", raw_type)
                csharp_type = raw_type
            end
        end
        local lineCode = prettyShow .. "public " .. csharp_type .. " " .. name .. ";\n"
        paramCode = paramCode .. lineCode
    end
    return paramCode
end
function parser_csharp:genEncode(elementArray, prettyShow)
    local nextPrettyShow = prettyShow..prettyStep
    local bodyCode = prettyShow .. "override public void Encode(WriteBuffer wb)\n"
    bodyCode = bodyCode .. prettyShow .. "{\n"
    bodyCode = bodyCode .. nextPrettyShow .. string.format("Eproto.PackArray(wb, %s);\n", #elementArray)
    for k,elementInfo in ipairs(elementArray) do
        local name = elementInfo[1]
        local raw_type = elementInfo[2]
        local this_name = "this."..name
        local csharp_type = protobuf_to_csharp[raw_type]
        if csharp_type == nil then
            local nextNextPrettyShow = nextPrettyShow .. prettyStep
            local nextNextNextPrettyShow = nextNextPrettyShow .. prettyStep
            if raw_type == "map" then
                local raw_key = elementInfo[3]
                local raw_value = elementInfo[4]
                local index_name = "i"
                bodyCode = bodyCode .. nextPrettyShow .. string.format("if (%s == null) { Eproto.PackNil(wb); } else {\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("Eproto.PackMap(wb, %s.Count);\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("foreach (var %s in %s)\n", index_name, this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. "{\n"
                local raw_key_csharp_type = protobuf_to_csharp[raw_key]
                local raw_value_csharp_type = protobuf_to_csharp[raw_value]
                local raw_key_name = string.format("%s.Key", index_name)
                if raw_key_csharp_type == nil then
                    -- 自定义对象
                    print("it's not support for self define key for Dictionary")
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByDefine(raw_key_name)
                else
                    -- C#内置数据类型
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByType(raw_key_name, raw_key_csharp_type)
                end
                local raw_value_name = string.format("%s.Value", index_name)
                if raw_value_csharp_type == nil then
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByDefine(raw_value_name)
                else
                    -- C#内置数据类型
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByType(raw_value_name, raw_value_csharp_type)
                end
                bodyCode = bodyCode .. nextNextPrettyShow .. "}\n"
                bodyCode = bodyCode .. nextPrettyShow .. "}\n"
            elseif raw_type == "array" then
                local raw_key = elementInfo[3]
                local index_name = "i"
                local value_name = "v"
                local value_at_index = this_name.."["..index_name.."]"
                bodyCode = bodyCode .. nextPrettyShow .. string.format("if (%s == null) { Eproto.PackNil(wb); } else {\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("Eproto.PackArray(wb, %s.Length);\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("for(int %s=0; %s<%s.Length; ++%s)\n", index_name, index_name, this_name, index_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. "{\n"
                local raw_key_csharp_type = protobuf_to_csharp[raw_key]
                if raw_key_csharp_type == nil then
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s %s = %s;\n", raw_key, value_name, value_at_index)
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByDefine(value_name)
                else
                    -- C#内置数据类型
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s %s = %s;\n", raw_key_csharp_type, value_name, value_at_index)
                    bodyCode = bodyCode .. nextNextPrettyShow .. self:getPackByType(value_name, raw_key_csharp_type)
                end
                bodyCode = bodyCode .. nextNextPrettyShow .. "}\n"
                bodyCode = bodyCode .. nextPrettyShow .. "}\n"
            else
                -- 自定义对象
                bodyCode = bodyCode .. nextPrettyShow .. self:getPackByDefine(this_name)
            end
        else
            -- C#内置数据类型
            bodyCode = bodyCode .. nextPrettyShow .. self:getPackByType(this_name, csharp_type)
        end
    end
    bodyCode = bodyCode .. prettyShow .. "}\n"
    return bodyCode
end
function parser_csharp:getPackByDefine(name)
    return string.format("if (%s == null) { Eproto.PackNil(wb); } else { %s.Encode(wb); }\n", name, name)
end
function parser_csharp:getPackByType(name, csharp_type)
    if csharp_type == "string" then
        return  string.format("Eproto.PackString(wb, %s);\n", name)
    elseif csharp_type == "byte[]" then
        return string.format("Eproto.PackBytes(wb, %s);\n", name)
    elseif csharp_type == "float" or csharp_type == "double" then
        return string.format("Eproto.PackDouble(wb, %s);\n", name)
    elseif csharp_type == "bool" then
        return string.format("Eproto.PackBool(wb, %s);\n", name)
    else
        return string.format("Eproto.PackInteger(wb, %s);\n", name)
    end
end
function parser_csharp:genDecode(elementArray, prettyShow)
    local nextPrettyShow = prettyShow..prettyStep
    local bodyCode = prettyShow .. "override public void Decode(ReadBuffer rb)\n"
    bodyCode = bodyCode .. prettyShow .. "{\n"
    local count_name = "c"
    local count_skip = nextPrettyShow .. string.format("if (--%s <= 0) { return; }\n", count_name)
    bodyCode = bodyCode .. nextPrettyShow .. string.format("long %s = Eproto.UnpackArray(rb);\n", count_name)
    bodyCode = bodyCode .. nextPrettyShow .. string.format("if (%s <= 0) { return; }\n", count_name)
    for k,elementInfo in ipairs(elementArray) do
        local name = elementInfo[1]
        local raw_type = elementInfo[2]
        local this_name = "this."..name
        local csharp_type = protobuf_to_csharp[raw_type]
        if csharp_type == nil then
            local nextNextPrettyShow = nextPrettyShow .. prettyStep
            local nextNextNextPrettyShow = nextNextPrettyShow .. prettyStep
            local nextNextNextNextPrettyShow = nextNextNextPrettyShow .. prettyStep
            if raw_type == "map" then
                local raw_key = elementInfo[3]
                local raw_value = elementInfo[4]
                local index_name = "i"
                local raw_key_csharp_type = protobuf_to_csharp[raw_key]
                local raw_value_csharp_type = protobuf_to_csharp[raw_value]
                local decl_key,decl_value,decl_key_default,decl_value_default
                if raw_key_csharp_type == nil then
                    decl_key = raw_key
                else
                    decl_key = raw_key_csharp_type
                end
                if raw_value_csharp_type == nil then
                    decl_value = raw_value
                else
                    decl_value = raw_value_csharp_type
                end
                decl_key_default = self:getDefaultDeclValue(raw_key_csharp_type)
                decl_value_default = self:getDefaultDeclValue(raw_value_csharp_type)
                csharp_type = "Dictionary<"..decl_key..", "..decl_value..">"
                bodyCode = bodyCode .. nextPrettyShow .. "{\n"
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("long n = Eproto.UnpackMap(rb);\n")
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("if (n < 0) { %s=null; } else {\n", this_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s = new %s();\n", this_name, csharp_type)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("for(int %s=0; %s<n; ++%s)\n", index_name, index_name, index_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. "{\n"
                bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s k=%s; %s v=%s;\n", decl_key, decl_key_default, decl_value, decl_value_default)
                if raw_key_csharp_type == nil then
                    -- 自定义对象
                    print("it's not support for self define key for Dictionary")
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByDefine("k", raw_key)
                else
                    -- C#内置数据类型
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByType("k", raw_key_csharp_type)
                end
                if raw_value_csharp_type == nil then
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByDefine("v", raw_value)
                else
                    -- C#内置数据类型
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByType("v", raw_value_csharp_type)
                end
                if raw_key_csharp_type == "string" then
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
                local raw_key_csharp_type = protobuf_to_csharp[raw_key]
                local decl_key,decl_key_default
                if raw_key_csharp_type == nil then
                    decl_key = raw_key
                else
                    decl_key = raw_key_csharp_type
                end
                csharp_type = decl_key.."[n]"
                bodyCode = bodyCode .. nextPrettyShow .. "{\n"
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("long n = Eproto.UnpackArray(rb);\n")
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("if (n < 0) { %s=null; } else {\n", this_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s = new %s;\n", this_name, csharp_type)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("for(int %s=0; %s<n; ++%s)\n", index_name, index_name, index_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. "{\n"
                decl_key_default = self:getDefaultDeclValue(raw_key_csharp_type)
                bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s v=%s;\n", decl_key, decl_key_default)
                if raw_key_csharp_type == nil then
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByDefine("v", raw_key)
                else
                    -- C#内置数据类型
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByType("v", raw_key_csharp_type)
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
            -- C#内置数据类型
            bodyCode = bodyCode .. nextPrettyShow .. self:getUnpackByType(this_name, csharp_type)
        end
        bodyCode = bodyCode .. count_skip
    end
    bodyCode = bodyCode .. nextPrettyShow .. string.format("Eproto.UnpackDiscard(rb, %s);\n", count_name)
    bodyCode = bodyCode .. prettyShow .. "}\n"
    return bodyCode
end
function parser_csharp:genCreate(className, prettyShow)
    local str = string.format("%soverride public Proto Create() { return new %s(); }", prettyShow, className)
    return str
end
function parser_csharp:getDefaultDeclValue(csharp_type)
    if csharp_type == nil then
        return "null"
    else
        if csharp_type == "string" or csharp_type == "byte[]" then
            return "null"
        elseif csharp_type == "bool" then
            return "false"
        else
            return "0"
        end
    end
end
function parser_csharp:getUnpackByDefine(name, raw_key)
    return string.format("if (rb.NextIsNil()) { rb.MoveNext(); } else { %s = new %s(); %s.Decode(rb); }\n", name, raw_key, name)
end
function parser_csharp:getUnpackByType(name, csharp_type)
    if csharp_type == "string" then
        return  string.format("Eproto.UnpackString(rb, ref %s);\n", name)
    elseif csharp_type == "byte[]" then
        return string.format("Eproto.UnpackBytes(rb, ref %s);\n", name)
    elseif csharp_type == "float" or csharp_type == "double" then
        return string.format("Eproto.UnpackDouble(rb, ref %s);\n", name)
    elseif csharp_type == "bool" then
        return string.format("Eproto.UnpackBool(rb, ref %s);\n", name)
    else
        return string.format("Eproto.UnpackInteger(rb, ref %s);\n", name)
    end
end
function parser_csharp:splitNamespace()
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

return parser_csharp
