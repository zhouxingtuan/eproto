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

function parser_csharp:ctor(packageName, protos, full_path_info)
    self.m_packageName = packageName
    self.m_protos = protos
    self.m_full_path_info = full_path_info
end

function parser_csharp:genCode()
    local namespaceMap,defaultNSMap = self:splitNamespace()
    dump(namespaceMap)
    dump(defaultNSMap)
    return ""
end
function parser_csharp:splitNamespace()
    local m_packageName = self.m_packageName
    local m_full_path_info = self.m_full_path_info
    local protos = self.m_protos
    local namespaceMap = {}
    local defaultNSMap = {}
    for full_path,elementArr in pairs(protos) do
        local arr = util.split(full_path, "%.")
        local packageName = arr[1]
        if #arr > 1 and packageName == m_packageName then
            -- 有外层namespace
            local nsMap = namespaceMap[packageName]
            if nsMap == nil then
                nsMap = {}
                namespaceMap[packageName] = nsMap
            end
            for k=2,#arr do
                local protoName = arr[k]
                local pMap = nsMap[protoName]
                if pMap == nil then
                    pMap = {}
                    nsMap[protoName] = pMap
                end
                if k == #arr then
                    pMap._elementArr = elementArr
                    pMap._rawElements = m_full_path_info[full_path].raw_elements
                end
                nsMap = pMap
            end
        else
            -- 没有外层namespace
            local nsMap = defaultNSMap
            for k=1,#arr do
                local protoName = arr[k]
                local pMap = nsMap[protoName]
                if pMap == nil then
                    pMap = {}
                    nsMap[protoName] = pMap
                end
                if k == #arr then
                    pMap._elementArr = elementArr
                    pMap._rawElements = m_full_path_info[full_path].raw_elements
                end
                nsMap = pMap
            end
        end
    end
    return namespaceMap,defaultNSMap
end

return parser_csharp
