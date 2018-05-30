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
    dump(namespaceMap)
    dump(defaultNSMap)
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
    for className,classInfo in pairs(childMap) do
        classCode = classCode .. self:genClass(className, classInfo.childMap)
    end
    local code = string.format(template, namespace, classCode)
    return code
end
function parser_csharp:genClass(className, childMap)

    return ""
end
function parser_csharp:genParams()

    return ""
end
function parser_csharp:genMaxLength()

    return ""
end
function parser_csharp:genEncode()

    return ""
end
function parser_csharp:genDecode()

    return ""
end
function parser_csharp:genToString()

    return ""
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
