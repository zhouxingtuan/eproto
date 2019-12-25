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
    float = "double";
    int32 = "int";
    int64 = "int";
    uint32 = "int";
    uint64 = "int";
    sint32 = "int";
    sint64 = "int";
    fixed32 = "int";
    fixed64 = "int";
    sfixed32 = "int";
    sfixed64 = "int";
    bool = "bool";
    string = "String";
    bytes = "Uint8List";
}

local prettyStep = "  "

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

local parser_dart = class("parser_dart")

function parser_dart:ctor(packageName, full_path_info, importPath)
    self.m_packageName = packageName
    self.m_full_path_info = full_path_info
    self.m_importPath = importPath
end

function parser_dart:genCode(dart_file)
    -- namespaceMap 中只有一个元素；也就是一个文件只能使用一个命名空间
    local namespaceMap,defaultNSMap = self:splitNamespace()
    --    dump(namespaceMap)
    --    dump(defaultNSMap)
    local code_template = [[
%s
import 'dart:typed_data';
import 'eproto.dart' as eproto;
%s
%s

]]
    local file_header = string.gsub(dart_file, "%.", "_")
    file_header = "__"..file_header.."__"
    local importHeader = ""
    for _,headerPath in ipairs(self.m_importPath) do
        headerPath = string.gsub(headerPath, ".proto", ".dart")
        headerPath = string.gsub(headerPath, "\"", "'")
        local library
        if next(defaultNSMap.childMap) then
            library = self:findLibrary(headerPath, defaultNSMap.childMap)
        else
            for namespace,info in pairs(namespaceMap) do
                library = self:findLibrary(headerPath, info.childMap)
            end
        end
        importHeader = importHeader .. "import " .. headerPath .. " as ".. library ..";\n"
    end
    local library
    local body
    if next(defaultNSMap.childMap) then
        library = ""
        body = self:genNamespace(nil, defaultNSMap.childMap)
    else
        body = ""
        for namespace,info in pairs(namespaceMap) do
            library = "library " .. namespace .. ";"
            body = body .. self:genNamespace(nil, info.childMap)
        end
    end
    local code = string.format(code_template, library, importHeader, body)
    return code
end

function parser_dart:findLibrary(headerPath, childMap)
    headerPath = string.sub(headerPath, 2, #headerPath-1)
    local headerArr = util.split(headerPath, "%.")
    local headerName = headerArr[1]
    for className,classInfo in pairs(childMap) do
        for k,elementInfo in ipairs(classInfo.elementArray) do
            local selfDefineKey
            local raw_type = elementInfo[2]
            local raw_key = elementInfo[3]
            local raw_value = elementInfo[4]
            local cpp_type = protobuf_to_cpp[raw_type]
            if cpp_type == nil then
                if raw_type == "array" then
                    local key_type = protobuf_to_cpp[raw_key]
                    if key_type == nil then
                        selfDefineKey = raw_key
                    end
                elseif raw_type == "map" then
                    local value_type = protobuf_to_cpp[raw_value]
                    if value_type == nil then
                        selfDefineKey = raw_value
                    end
                else
                    selfDefineKey = raw_type
                end
            end
            --            print("selfDefineKey", selfDefineKey, "raw_type", raw_type, "raw_key", raw_key, "raw_value", raw_value)
            if selfDefineKey and not childMap[selfDefineKey] then
                -- 从外部引入的message
                local arr = util.split(selfDefineKey, "%.")
                local libName = arr[1]
                --                print("selfDefineKey", selfDefineKey, "libName", libName, "headerName", headerName)
                if string.find(headerName, libName) then
                    return libName
                end
            end
        end
    end
    return headerName
end
function parser_dart:genNamespace(namespace, childMap)
    local template
    local frontName
    local prettyShow
    if namespace == nil then
        frontName = ""
        template = [[
%s
%s
]]
        namespace = ""
        prettyShow = ""
    else
        frontName = namespace
        template = [[
namespace %s
{
%s
};
]]
        prettyShow = prettyStep
    end
    local classCode = ""
    --    local prettyShow = prettyStep
    local childArray = self:getChildMapLevel(childMap)
    for _,info in ipairs(childArray) do
        local className = info.className
        local classInfo = info.classInfo
        --    for className,classInfo in pairs(childMap) do
        classCode = classCode .. self:genClass(className, classInfo.elementArray, classInfo.childMap, prettyShow, false, namespace)
    end
    local code = string.format(template, namespace, classCode)
    return code
end
function parser_dart:genClass(className, elementArray, childMap, prettyShow, isPublic, frontName)
    local nextPrettyShow = prettyShow..prettyStep
    local beforeClass = prettyShow
    if isPublic then
        --        beforeClass = beforeClass .. "public "
    end
    local subClasses = ""
    --    local publicLine = prettyShow.."public:\n"
    local publicLine = ""
    subClasses = subClasses .. publicLine
    local childArray = self:getChildMapLevel(childMap)
    for _,info in ipairs(childArray) do
        local name = info.className
        local classInfo = info.classInfo
        subClasses = subClasses .. self:genClass(name, classInfo.elementArray, classInfo.childMap, prettyShow, true, frontName.."."..className)
    end
    local params = self:genParams(elementArray, nextPrettyShow)
    local Encode = self:genEncode(elementArray, nextPrettyShow)
    local Decode = self:genDecode(elementArray, nextPrettyShow)
    local Create = self:genCreate(className, nextPrettyShow)
    local bodyArr = { params, Encode, Decode, Create }
    local bodyStr = table.concat(bodyArr)
    local template = [[%s%sclass %s
%s{
%s
%s}
]]
    local classCode = string.format(template,
        subClasses,
        beforeClass, className,
        prettyShow,
        bodyStr,
        prettyShow)
    return classCode
end
function parser_dart:genParams(elementArray, prettyShow)
    local paramCode = ""
    for k,elementInfo in ipairs(elementArray) do
        local name = elementInfo[1]
        local raw_type = elementInfo[2]
        --        raw_type = string.gsub(raw_type, "%.", "::")
        local cpp_type = protobuf_to_cpp[raw_type]
        if cpp_type == nil then
            if raw_type == "array" then
                local raw_key = elementInfo[3]
                --                raw_key = string.gsub(raw_key, "%.", "::")
                local key_type = protobuf_to_cpp[raw_key]
                if key_type == nil then
                    -- 自定义对象
                    key_type = raw_key..""
                end
                cpp_type = "List<"..key_type..">"
            elseif raw_type == "map" then
                local raw_key = elementInfo[3]
                local raw_value = elementInfo[4]
                --                raw_key = string.gsub(raw_key, "%.", "::")
                --                raw_value = string.gsub(raw_value, "%.", "::")
                local key_type = protobuf_to_cpp[raw_key]
                if key_type == nil then
                    key_type = raw_key
                end
                local value_type = protobuf_to_cpp[raw_value]
                if value_type == nil then
                    -- 自定义对象
                    value_type = raw_value..""
                end
                cpp_type = "Map<"..key_type..", "..value_type..">"
            else
                --                print("unsupport protobuf type to cpp type", raw_type)
                -- 自定义对象
                cpp_type = raw_type..""
            end
        elseif raw_type == "bytes" then

        end
        local default_value = self:getDefaultDeclValue(cpp_type)
        local lineCode = prettyShow .. cpp_type .. " " .. name .. " = "..default_value..";\n"
        paramCode = paramCode .. lineCode
    end
    return paramCode
end
function parser_dart:genEncode(elementArray, prettyShow)
    local nextPrettyShow = prettyShow..prettyStep
    local bodyCode = prettyShow .. "void encode(eproto.DataWriter wb)\n"
    bodyCode = bodyCode .. prettyShow .. "{\n"
    bodyCode = bodyCode .. nextPrettyShow .. string.format("wb.packArrayHead(%s);\n", #elementArray)
    for k,elementInfo in ipairs(elementArray) do
        local name = elementInfo[1]
        local raw_type = elementInfo[2]
        --        raw_type = string.gsub(raw_type, "%.", "::")
        local this_name = "this."..name
        local cpp_type = protobuf_to_cpp[raw_type]
        if cpp_type == nil then
            local nextNextPrettyShow = nextPrettyShow .. prettyStep
            local nextNextNextPrettyShow = nextNextPrettyShow .. prettyStep
            if raw_type == "map" then
                local raw_key = elementInfo[3]
                local raw_value = elementInfo[4]
                --                raw_key = string.gsub(raw_key, "%.", "::")
                --                raw_value = string.gsub(raw_value, "%.", "::")
                bodyCode = bodyCode .. nextPrettyShow .. string.format("{\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("wb.packMapHead(%s.length);\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("%s.forEach((k,v)\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. "{\n"
                local raw_key_cpp_type = protobuf_to_cpp[raw_key]
                local raw_value_cpp_type = protobuf_to_cpp[raw_value]
                local raw_key_name = "k"
                if raw_key_cpp_type == nil then
                    -- 自定义对象
                    print("it's not support for self define key for Dictionary")
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByDefine(raw_key_name)
                else
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByType(raw_key_name, raw_key_cpp_type)
                end
                local raw_value_name = "v"
                if raw_value_cpp_type == nil then
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByDefine(raw_value_name)
                else
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextPrettyShow .. self:getPackByType(raw_value_name, raw_value_cpp_type)
                end
                bodyCode = bodyCode .. nextNextPrettyShow .. "});\n"
                bodyCode = bodyCode .. nextPrettyShow .. "}\n"
            elseif raw_type == "array" then
                local raw_key = elementInfo[3]
                --                raw_key = string.gsub(raw_key, "%.", "::")
                local index_name = "i"
                local value_name = "v"
                local value_at_index = this_name.."["..index_name.."]"
                bodyCode = bodyCode .. nextPrettyShow .. string.format("{\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("wb.packArrayHead(%s.length);\n", this_name)
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("for(int %s=0; %s<%s.length; ++%s)\n", index_name, index_name, this_name, index_name)
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
function parser_dart:getPackByDefine(name)
    return string.format("if (%s == null) { wb.packNil(); } else { %s.encode(wb); }\n", name, name)
end
function parser_dart:getPackByType(name, cpp_type)
    if cpp_type == "String" then
        return string.format("wb.packString(%s);\n", name)
    elseif cpp_type == "Uint8List" then
        return string.format("wb.packBytes(%s);\n", name)
    elseif cpp_type == "float" or cpp_type == "double" then
        return string.format("wb.packDouble(%s);\n", name)
    elseif cpp_type == "bool" then
        return string.format("wb.packBool(%s);\n", name)
    else
        return string.format("wb.packInt(%s);\n", name)
    end
end
function parser_dart:genDecode(elementArray, prettyShow)
    local nextPrettyShow = prettyShow..prettyStep
    local bodyCode = prettyShow .. "void decode(eproto.DataReader rb)\n"
    bodyCode = bodyCode .. prettyShow .. "{\n"
    --    bodyCode = bodyCode .. nextPrettyShow .. "Clear();\n"
    local count_name = "c"
    local count_skip = nextPrettyShow .. string.format("if (--%s <= 0) { return; }\n", count_name)
    bodyCode = bodyCode .. nextPrettyShow .. string.format("int %s = rb.unpackArrayHead();\n", count_name)
    bodyCode = bodyCode .. nextPrettyShow .. string.format("if (%s <= 0) { return; }\n", count_name)
    for k,elementInfo in ipairs(elementArray) do
        local name = elementInfo[1]
        local raw_type = elementInfo[2]
        --        raw_type = string.gsub(raw_type, "%.", "::")
        local this_name = "this."..name
        local cpp_type = protobuf_to_cpp[raw_type]
        if cpp_type == nil then
            local nextNextPrettyShow = nextPrettyShow .. prettyStep
            local nextNextNextPrettyShow = nextNextPrettyShow .. prettyStep
            local nextNextNextNextPrettyShow = nextNextNextPrettyShow .. prettyStep
            if raw_type == "map" then
                local raw_key = elementInfo[3]
                local raw_value = elementInfo[4]
                --                raw_key = string.gsub(raw_key, "%.", "::")
                --                raw_value = string.gsub(raw_value, "%.", "::")
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
                if raw_key_cpp_type == nil then
                    decl_key_default = self:getDefaultDeclValue(raw_key)
                else
                    decl_key_default = self:getDefaultDeclValue(raw_key_cpp_type)
                end
                if raw_value_cpp_type == nil then
                    decl_value_default = self:getDefaultDeclValue(raw_value)
                else
                    decl_value_default = self:getDefaultDeclValue(raw_value_cpp_type)
                end
                --                cpp_type = "Dictionary<"..decl_key..", "..decl_value..">"
                bodyCode = bodyCode .. nextPrettyShow .. "{\n"
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("int n = rb.unpackMapHead();\n")
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("if (n > 0) {\n", this_name)
                --                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s = new %s();\n", this_name, cpp_type)
                --                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s.clear();\n", this_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("for(int %s=0; %s<n; ++%s)\n", index_name, index_name, index_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. "{\n"
                --                bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s k=%s; %s v=%s;\n", decl_key, decl_key_default, decl_value, decl_value_default)
                if raw_key_cpp_type == nil then
                    if decl_key_default then
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s k=%s;\n", decl_key, decl_key_default)
                    else
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s k;\n", decl_key)
                    end
                    -- 自定义对象
                    print("it's not support for self define key for Dictionary")
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByDefine("k", raw_key)
                else
                    if decl_key_default then
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s k=%s;\n", decl_key, decl_key_default)
                    else
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s k;\n", decl_key)
                    end
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByType("k", raw_key_cpp_type)
                end
                if raw_value_cpp_type == nil then
                    if decl_value_default then
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s v=%s;\n", decl_value, decl_value_default)
                    else
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s v;\n", decl_value)
                    end
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByDefine("v", raw_value)
                else
                    if decl_value_default then
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s v=%s;\n", decl_value, decl_value_default)
                    else
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s v;\n", decl_value)
                    end
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByType("v", raw_value_cpp_type)
                end
                bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s[k] = v;\n", this_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. "}\n"
                bodyCode = bodyCode .. nextNextPrettyShow .. "}\n"
                bodyCode = bodyCode .. nextPrettyShow .. "}\n"
            elseif raw_type == "array" then
                local raw_key = elementInfo[3]
                --                raw_key = string.gsub(raw_key, "%.", "::")
                local index_name = "i"
                local value_name = "v"
                local raw_key_cpp_type = protobuf_to_cpp[raw_key]
                local decl_key,decl_key_default
                if raw_key_cpp_type == nil then
                    decl_key = raw_key
                else
                    decl_key = raw_key_cpp_type
                end
                --                cpp_type = decl_key.."[n]"
                bodyCode = bodyCode .. nextPrettyShow .. "{\n"
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("int n = rb.unpackArrayHead();\n")
                bodyCode = bodyCode .. nextNextPrettyShow .. string.format("if (n > 0) {\n", this_name)
                --                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s = new %s;\n", this_name, cpp_type)
                --                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("%s.resize(n);\n", this_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. string.format("for(int %s=0; %s<n; ++%s)\n", index_name, index_name, index_name)
                bodyCode = bodyCode .. nextNextNextPrettyShow .. "{\n"
                if raw_key_cpp_type == nil then
                    decl_key_default = self:getDefaultDeclValue(raw_key)
                else
                    decl_key_default = self:getDefaultDeclValue(raw_key_cpp_type)
                end
                if raw_key_cpp_type == nil then
                    if decl_key_default then
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s v=%s;\n", decl_key, decl_key_default)
                    else
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s v;\n", decl_key)
                    end
                    -- 自定义对象
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByDefine("v", raw_key)
                else
                    if decl_key_default then
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s v=%s;\n", decl_key, decl_key_default)
                    else
                        bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s v;\n", decl_key)
                    end
                    -- C++内置数据类型
                    bodyCode = bodyCode .. nextNextNextNextPrettyShow .. self:getUnpackByType("v", raw_key_cpp_type)
                end
                bodyCode = bodyCode .. nextNextNextNextPrettyShow .. string.format("%s.add(v);\n", this_name)
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
    bodyCode = bodyCode .. nextPrettyShow .. string.format("rb.unpackDiscard(%s);\n", count_name)
    bodyCode = bodyCode .. prettyShow .. "}\n"
    return bodyCode
end
function parser_dart:genCreate(className, prettyShow)
    local str = string.format("%s%s create() { return %s(); }\n", prettyShow, className, className)
    return str
end
function parser_dart:getDefaultDeclValue(cpp_type)
    if cpp_type == nil then
        return
    else
        if cpp_type == "String" then
            return [[""]]
        elseif cpp_type == "Uint8List" then
            return "Uint8List(0)"
        elseif cpp_type == "bool" then
            return "false"
        elseif cpp_type == "double" then
            return "0"
        elseif cpp_type == "int" then
            return "0"
        else
            return cpp_type .. "()"
        end
    end
end
function parser_dart:getUnpackByDefine(name, raw_key)
    --    local clearStr = string.format("%s::Delete(%s);", raw_key, name)
    return string.format("if (rb.nextIsNil()) { rb.moveNext(); } else { %s.decode(rb); }\n", name)
end
function parser_dart:getUnpackByType(name, cpp_type)
    if cpp_type == "String" then
        return  string.format("%s = rb.unpackString();\n", name)
    elseif cpp_type == "Uint8List" then
        return string.format("%s = rb.unpackBytes();\n", name)
    elseif cpp_type == "float" or cpp_type == "double" then
        return string.format("%s = rb.unpackDouble();\n", name)
    elseif cpp_type == "bool" then
        return string.format("%s = rb.unpackBool();\n", name)
    else
        return string.format("%s = rb.unpackInt();\n", name)
    end
end
function parser_dart:getChildMapLevel(childMap)
    for className,classInfo in pairs(childMap) do
        classInfo.protoLevel = 1
    end
    local function loopFindLevel()
        local isFind = false
        for className,classInfo in pairs(childMap) do
            for k,elementInfo in ipairs(classInfo.elementArray) do
                for k=2,#elementInfo do
                    local raw_type = elementInfo[k]
                    local thatInfo = childMap[raw_type]
                    if thatInfo then
                        local protoLevel = thatInfo.protoLevel
                        if classInfo.protoLevel <= thatInfo.protoLevel then
                            classInfo.protoLevel = thatInfo.protoLevel + 1
                            isFind = true
                        end
                    end
                end
            end
        end
        return isFind
    end
    local count = 0
    local isFind = loopFindLevel()
    while isFind do
        count = count + 1
        --        print("loopFindLevel count ", count, "isFind", isFind)
        isFind = loopFindLevel()
    end
    local childArray= {}
    for className,classInfo in pairs(childMap) do
        table.insert(childArray, {className=className, classInfo=classInfo})
    end
    local function sortFunc(a, b)
        if a.classInfo.protoLevel == b.classInfo.protoLevel then
            return a.className < b.className
        else
            return a.classInfo.protoLevel < b.classInfo.protoLevel
        end
    end
    table.sort(childArray, sortFunc)
    --    dump(childArray)
    return childArray
end
function parser_dart:splitNamespace()
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

return parser_dart
