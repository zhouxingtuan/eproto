--
-- Created by IntelliJ IDEA.
-- User: zxt
-- Date: 2018/6/1
-- Time: 10:00
-- To change this template use File | Settings | File Templates.
--

local error = error
local pairs = pairs
local ipairs = ipairs
local pcall = pcall
local tostring = tostring
local type = type
local string = string
local char = string.char
local format = string.format
local math = math
local floor = math.floor
local floor = math.floor
local tointeger = math.tointeger or floor
local frexp = math.frexp or mathx.frexp
local ldexp = math.ldexp or mathx.ldexp
local huge = math.huge
local table = table
local tconcat = table.concat

local maxinteger = 9007199254740991
local mininteger = -maxinteger

local ep_type_nil = 1
local ep_type_bool = 2
local ep_type_float = 3
local ep_type_int = 4
local ep_type_string = 5
local ep_type_bytes = 6
local ep_type_array = 7
local ep_type_map = 8
local ep_type_message = 9

local packers = {}

local function pack_nil(buffer)
    buffer[#buffer+1] = char(0xC0)              -- nil
end
local function pack_bool(buffer, bool)
    if bool then
        buffer[#buffer+1] = char(0xC3)          -- true
    else
        buffer[#buffer+1] = char(0xC2)          -- false
    end
end
local function pack_string(buffer, str)
    local n = #str
    if n <= 0x1F then
        buffer[#buffer+1] = char(0xA0 + n)      -- fixstr
    elseif n <= 0xFF then
        buffer[#buffer+1] = char(0xD9,          -- str8
            n)
    elseif n <= 0xFFFF then
        buffer[#buffer+1] = char(0xDA,          -- str16
            floor(n / 0x100),
            n % 0x100)
    elseif n <= 4294967295.0 then
        buffer[#buffer+1] = char(0xDB,          -- str32
            floor(n / 0x1000000),
            floor(n / 0x10000) % 0x100,
            floor(n / 0x100) % 0x100,
            n % 0x100)
    else
        error"overflow in pack 'string'"
    end
    buffer[#buffer+1] = str
end
local function pack_bytes(buffer, str)
    local n = #str
    if n <= 0xFF then
        buffer[#buffer+1] = char(0xC4,          -- bin8
            n)
    elseif n <= 0xFFFF then
        buffer[#buffer+1] = char(0xC5,          -- bin16
            floor(n / 0x100),
            n % 0x100)
    elseif n <= 4294967295.0 then
        buffer[#buffer+1] = char(0xC6,          -- bin32
            floor(n / 0x1000000),
            floor(n / 0x10000) % 0x100,
            floor(n / 0x100) % 0x100,
            n % 0x100)
    else
        error"overflow in pack 'binary'"
    end
    buffer[#buffer+1] = str
end
-- 处理Lua的表
local function pack_map_head(buffer, n)
    if n <= 0x0F then
        buffer[#buffer+1] = char(0x80 + n)      -- fixmap
    elseif n <= 0xFFFF then
        buffer[#buffer+1] = char(0xDE,          -- map16
            floor(n / 0x100),
            n % 0x100)
    elseif n <= 4294967295.0 then
        buffer[#buffer+1] = char(0xDF,          -- map32
            floor(n / 0x1000000),
            floor(n / 0x10000) % 0x100,
            floor(n / 0x100) % 0x100,
            n % 0x100)
    else
        error"overflow in pack 'map'"
    end
end
local function pack_array_head(buffer, n)
    if n <= 0x0F then
        buffer[#buffer+1] = char(0x90 + n)      -- fixarray
    elseif n <= 0xFFFF then
        buffer[#buffer+1] = char(0xDC,          -- array16
            floor(n / 0x100),
            n % 0x100)
    elseif n <= 4294967295.0 then
        buffer[#buffer+1] = char(0xDD,          -- array32
            floor(n / 0x1000000),
            floor(n / 0x10000) % 0x100,
            floor(n / 0x100) % 0x100,
            n % 0x100)
    else
        error"overflow in pack 'array'"
    end
end
local function pack_map(buffer, n)
    pack_map_head(buffer, n)
    for k, v in pairs(tbl) do
        packers[type(k)](buffer, k)
        packers[type(v)](buffer, v)
    end
end
local function pack_array(buffer, tbl, n)
    pack_array_head(buffer, n)
    for i = 1, n do
        local v = tbl[i]
        packers[type(v)](buffer, v)
    end
end
local function pack_table(buffer, tbl)
    local is_map, n, max = false, 0, 0
    for k in pairs(tbl) do
        if type(k) == 'number' and k > 0 then
            if k > max then
                max = k
            end
        else
            is_map = true
        end
        n = n + 1
    end
    if is_map then
        pack_map(buffer, tbl, n)
    else
        pack_array(buffer, tbl, max)
    end
end
-- 处理Lua的数字
local function pack_integer(buffer, n)
    if n >= 0 then
        if n <= 0x7F then
            buffer[#buffer+1] = char(n)         -- fixnum_pos
        elseif n <= 0xFF then
            buffer[#buffer+1] = char(0xCC,      -- uint8
                n)
        elseif n <= 0xFFFF then
            buffer[#buffer+1] = char(0xCD,      -- uint16
                floor(n / 0x100),
                n % 0x100)
        elseif n <= 4294967295.0 then
            buffer[#buffer+1] = char(0xCE,      -- uint32
                floor(n / 0x1000000),
                floor(n / 0x10000) % 0x100,
                floor(n / 0x100) % 0x100,
                n % 0x100)
        else
            buffer[#buffer+1] = char(0xCF,      -- uint64
                0,         -- only 53 bits from double
                floor(n / 0x1000000000000) % 0x100,
                floor(n / 0x10000000000) % 0x100,
                floor(n / 0x100000000) % 0x100,
                floor(n / 0x1000000) % 0x100,
                floor(n / 0x10000) % 0x100,
                floor(n / 0x100) % 0x100,
                n % 0x100)
        end
    else
        if n >= -0x20 then
            buffer[#buffer+1] = char(0x100 + n) -- fixnum_neg
        elseif n >= -0x80 then
            buffer[#buffer+1] = char(0xD0,      -- int8
                0x100 + n)
        elseif n >= -0x8000 then
            n = 0x10000 + n
            buffer[#buffer+1] = char(0xD1,      -- int16
                floor(n / 0x100),
                n % 0x100)
        elseif n >= -0x80000000 then
            n = 4294967296.0 + n
            buffer[#buffer+1] = char(0xD2,      -- int32
                floor(n / 0x1000000),
                floor(n / 0x10000) % 0x100,
                floor(n / 0x100) % 0x100,
                n % 0x100)
        else
            buffer[#buffer+1] = char(0xD3,      -- int64
                0xFF,      -- only 53 bits from double
                floor(n / 0x1000000000000) % 0x100,
                floor(n / 0x10000000000) % 0x100,
                floor(n / 0x100000000) % 0x100,
                floor(n / 0x1000000) % 0x100,
                floor(n / 0x10000) % 0x100,
                floor(n / 0x100) % 0x100,
                n % 0x100)
        end
    end
end
local function pack_float(buffer, n)
    local sign = 0
    if n < 0.0 then
        sign = 0x80
        n = -n
    end
    local mant, expo = frexp(n)
    if mant ~= mant then
        buffer[#buffer+1] = char(0xCA,  -- nan
            0xFF, 0x88, 0x00, 0x00)
    elseif mant == huge or expo > 0x80 then
        if sign == 0 then
            buffer[#buffer+1] = char(0xCA,      -- inf
                0x7F, 0x80, 0x00, 0x00)
        else
            buffer[#buffer+1] = char(0xCA,      -- -inf
                0xFF, 0x80, 0x00, 0x00)
        end
    elseif (mant == 0.0 and expo == 0) or expo < -0x7E then
        buffer[#buffer+1] = char(0xCA,  -- zero
            sign, 0x00, 0x00, 0x00)
    else
        expo = expo + 0x7E
        mant = floor((mant * 2.0 - 1.0) * ldexp(0.5, 24))
        buffer[#buffer+1] = char(0xCA,
            sign + floor(expo / 0x2),
            (expo % 0x2) * 0x80 + floor(mant / 0x10000),
            floor(mant / 0x100) % 0x100,
            mant % 0x100)
    end
end
local function pack_double(buffer, n)
    local sign = 0
    if n < 0.0 then
        sign = 0x80
        n = -n
    end
    local mant, expo = frexp(n)
    if mant ~= mant then
        buffer[#buffer+1] = char(0xCB,  -- nan
            0xFF, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    elseif mant == huge or expo > 0x400 then
        if sign == 0 then
            buffer[#buffer+1] = char(0xCB,      -- inf
                0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
        else
            buffer[#buffer+1] = char(0xCB,      -- -inf
                0xFF, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
        end
    elseif (mant == 0.0 and expo == 0) or expo < -0x3FE then
        buffer[#buffer+1] = char(0xCB,  -- zero
            sign, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    else
        expo = expo + 0x3FE
        mant = floor((mant * 2.0 - 1.0) * ldexp(0.5, 53))
        buffer[#buffer+1] = char(0xCB,
            sign + floor(expo / 0x10),
            (expo % 0x10) * 0x10 + floor(mant / 0x1000000000000),
            floor(mant / 0x10000000000) % 0x100,
            floor(mant / 0x100000000) % 0x100,
            floor(mant / 0x1000000) % 0x100,
            floor(mant / 0x10000) % 0x100,
            floor(mant / 0x100) % 0x100,
            mant % 0x100)
    end
end
local function pack_number(buffer, n)
    if floor(n) == n and n < maxinteger and n > mininteger then
        pack_integer(buffer, n)
    else
        pack_double(buffer, n)
    end
end
packers['nil'] = pack_nil
packers['boolean'] = pack_bool
packers['string'] = pack_string
packers['binary'] = pack_bytes
packers['map'] = pack_map
packers['array'] = pack_array
packers['table'] = pack_table
packers['integer'] = pack_integer
packers['float'] = pack_float
packers['double'] = pack_double
packers['number'] = pack_number

local unpackers

local function cursor_string (str)
    return {
        s = str,
        i = 1,
        j = #str,
        underflow = function ()
            error "missing bytes"
        end,
    }
end
local function unpack_cursor (c)
    local s, i, j = c.s, c.i, c.j
    if i > j then
        c:underflow(i)
        s, i, j = c.s, c.i, c.j
    end
    local val = s:sub(i, i):byte()
    c.i = i+1
    return unpackers[val](c, val)
end
local function unpack_str (c, n)
    local s, i, j = c.s, c.i, c.j
    local e = i+n-1
    if e > j or n < 0 then
        c:underflow(e)
        s, i, j = c.s, c.i, c.j
        e = i+n-1
    end
    c.i = i+n
    return s:sub(i, e)
end
local function unpack_array (c, n)
    local t = {}
    for i = 1, n do
        t[i] = unpack_cursor(c)
    end
    return t
end
local function unpack_map (c, n)
    local t = {}
    for i = 1, n do
        local k = unpack_cursor(c)
        local val = unpack_cursor(c)
        if k == nil or k ~= k then
            k = m.sentinel
        end
        if k ~= nil then
            t[k] = val
        end
    end
    return t
end
local function unpack_float (c)
    local s, i, j = c.s, c.i, c.j
    if i+3 > j then
        c:underflow(i+3)
        s, i, j = c.s, c.i, c.j
    end
    local b1, b2, b3, b4 = s:sub(i, i+3):byte(1, 4)
    local sign = b1 > 0x7F
    local expo = (b1 % 0x80) * 0x2 + floor(b2 / 0x80)
    local mant = ((b2 % 0x80) * 0x100 + b3) * 0x100 + b4
    if sign then
        sign = -1
    else
        sign = 1
    end
    local n
    if mant == 0 and expo == 0 then
        n = sign * 0.0
    elseif expo == 0xFF then
        if mant == 0 then
            n = sign * huge
        else
            n = 0.0/0.0
        end
    else
        n = sign * ldexp(1.0 + mant / 0x800000, expo - 0x7F)
    end
    c.i = i+4
    return n
end
local function unpack_double (c)
    local s, i, j = c.s, c.i, c.j
    if i+7 > j then
        c:underflow(i+7)
        s, i, j = c.s, c.i, c.j
    end
    local b1, b2, b3, b4, b5, b6, b7, b8 = s:sub(i, i+7):byte(1, 8)
    local sign = b1 > 0x7F
    local expo = (b1 % 0x80) * 0x10 + floor(b2 / 0x10)
    local mant = ((((((b2 % 0x10) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8
    if sign then
        sign = -1
    else
        sign = 1
    end
    local n
    if mant == 0 and expo == 0 then
        n = sign * 0.0
    elseif expo == 0x7FF then
        if mant == 0 then
            n = sign * huge
        else
            n = 0.0/0.0
        end
    else
        n = sign * ldexp(1.0 + mant / 4503599627370496.0, expo - 0x3FF)
    end
    c.i = i+8
    return n
end
local function unpack_uint8 (c)
    local s, i, j = c.s, c.i, c.j
    if i > j then
        c:underflow(i)
        s, i, j = c.s, c.i, c.j
    end
    local b1 = s:sub(i, i):byte()
    c.i = i+1
    return b1
end
local function unpack_uint16 (c)
    local s, i, j = c.s, c.i, c.j
    if i+1 > j then
        c:underflow(i+1)
        s, i, j = c.s, c.i, c.j
    end
    local b1, b2 = s:sub(i, i+1):byte(1, 2)
    c.i = i+2
    return b1 * 0x100 + b2
end
local function unpack_uint32 (c)
    local s, i, j = c.s, c.i, c.j
    if i+3 > j then
        c:underflow(i+3)
        s, i, j = c.s, c.i, c.j
    end
    local b1, b2, b3, b4 = s:sub(i, i+3):byte(1, 4)
    c.i = i+4
    return ((b1 * 0x100 + b2) * 0x100 + b3) * 0x100 + b4
end
local function unpack_uint64 (c)
    local s, i, j = c.s, c.i, c.j
    if i+7 > j then
        c:underflow(i+7)
        s, i, j = c.s, c.i, c.j
    end
    local b1, b2, b3, b4, b5, b6, b7, b8 = s:sub(i, i+7):byte(1, 8)
    c.i = i+8
    return ((((((b1 * 0x100 + b2) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8
end
local function unpack_int8 (c)
    local s, i, j = c.s, c.i, c.j
    if i > j then
        c:underflow(i)
        s, i, j = c.s, c.i, c.j
    end
    local b1 = s:sub(i, i):byte()
    c.i = i+1
    if b1 < 0x80 then
        return b1
    else
        return b1 - 0x100
    end
end
local function unpack_int16 (c)
    local s, i, j = c.s, c.i, c.j
    if i+1 > j then
        c:underflow(i+1)
        s, i, j = c.s, c.i, c.j
    end
    local b1, b2 = s:sub(i, i+1):byte(1, 2)
    c.i = i+2
    if b1 < 0x80 then
        return b1 * 0x100 + b2
    else
        return ((b1 - 0xFF) * 0x100 + (b2 - 0xFF)) - 1
    end
end
local function unpack_int32 (c)
    local s, i, j = c.s, c.i, c.j
    if i+3 > j then
        c:underflow(i+3)
        s, i, j = c.s, c.i, c.j
    end
    local b1, b2, b3, b4 = s:sub(i, i+3):byte(1, 4)
    c.i = i+4
    if b1 < 0x80 then
        return ((b1 * 0x100 + b2) * 0x100 + b3) * 0x100 + b4
    else
        return ((((b1 - 0xFF) * 0x100 + (b2 - 0xFF)) * 0x100 + (b3 - 0xFF)) * 0x100 + (b4 - 0xFF)) - 1
    end
end
local function unpack_int64 (c)
    local s, i, j = c.s, c.i, c.j
    if i+7 > j then
        c:underflow(i+7)
        s, i, j = c.s, c.i, c.j
    end
    local b1, b2, b3, b4, b5, b6, b7, b8 = s:sub(i, i+7):byte(1, 8)
    c.i = i+8
    if b1 < 0x80 then
        return ((((((b1 * 0x100 + b2) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8
    else
        return ((((((((b1 - 0xFF) * 0x100 + (b2 - 0xFF)) * 0x100 + (b3 - 0xFF)) * 0x100 + (b4 - 0xFF)) * 0x100 + (b5 - 0xFF)) * 0x100 + (b6 - 0xFF)) * 0x100 + (b7 - 0xFF)) * 0x100 + (b8 - 0xFF)) - 1
    end
end
local function unpack_ext (c, n, tag)
    local s, i, j = c.s, c.i, c.j
    local e = i+n-1
    if e > j or n < 0 then
        c:underflow(e)
        s, i, j = c.s, c.i, c.j
        e = i+n-1
    end
    c.i = i+n
    return m.build_ext(tag, s:sub(i, e))
end
unpackers = {
    [0xC0] = function () return nil end,
    [0xC2] = function () return false end,
    [0xC3] = function () return true end,
    [0xC4] = function (c) return unpack_str(c, unpack_uint8(c)) end,    -- bin8
    [0xC5] = function (c) return unpack_str(c, unpack_uint16(c)) end,   -- bin16
    [0xC6] = function (c) return unpack_str(c, unpack_uint32(c)) end,   -- bin32
    [0xC7] = function (c) return unpack_ext(c, unpack_uint8(c), unpack_int8(c)) end,
    [0xC8] = function (c) return unpack_ext(c, unpack_uint16(c), unpack_int8(c)) end,
    [0xC9] = function (c) return unpack_ext(c, unpack_uint32(c), unpack_int8(c)) end,
    [0xCA] = unpack_float,
    [0xCB] = unpack_double,
    [0xCC] = unpack_uint8,
    [0xCD] = unpack_uint16,
    [0xCE] = unpack_uint32,
    [0xCF] = unpack_uint64,
    [0xD0] = unpack_int8,
    [0xD1] = unpack_int16,
    [0xD2] = unpack_int32,
    [0xD3] = unpack_int64,
    [0xD4] = function (c) return unpack_ext(c, 1, unpack_int8(c)) end,
    [0xD5] = function (c) return unpack_ext(c, 2, unpack_int8(c)) end,
    [0xD6] = function (c) return unpack_ext(c, 4, unpack_int8(c)) end,
    [0xD7] = function (c) return unpack_ext(c, 8, unpack_int8(c)) end,
    [0xD8] = function (c) return unpack_ext(c, 16, unpack_int8(c)) end,
    [0xD9] = function (c) return unpack_str(c, unpack_uint8(c)) end,
    [0xDA] = function (c) return unpack_str(c, unpack_uint16(c)) end,
    [0xDB] = function (c) return unpack_str(c, unpack_uint32(c)) end,
    [0xDC] = function (c) return unpack_array(c, unpack_uint16(c)) end,
    [0xDD] = function (c) return unpack_array(c, unpack_uint32(c)) end,
    [0xDE] = function (c) return unpack_map(c, unpack_uint16(c)) end,
    [0xDF] = function (c) return unpack_map(c, unpack_uint32(c)) end,
}

local protos = {};
local eproto = {}

local ep_encode_proto
local ep_encode_proto_array
local ep_encode_proto_map
local ep_copy_table

ep_encode_proto = function()

end
ep_copy_table = function(root, dataArr)
    local tab = {}
    local infoArr = protos[root]
    for _,info in ipairs(infoArr) do
        local ep_type = info[1]
        local index = info[2] + 1   -- index 从0开始的
        local name = info[3]
        if ep_type == ep_type_array then
            local arr_type = info[4]
            if type(arr_type) == "string" then
                -- proto
                local arr = {}
                for k,value in ipairs(dataArr[index]) do
                    arr[k] = ep_copy_table(arr_type, value)
                end
                tab[name] = arr
            else
                tab[name] = dataArr[index]
            end
        elseif ep_type == ep_type_map then
        elseif ep_type == ep_type_message then
        else
            tab[name] = dataArr[index]
        end
    end
    return tab
end

local function pack(data)
    local buffer = {}
    packers[type(data)](buffer, data)
    return tconcat(buffer)
end
local function unpack(s)
    local cursor = cursor_string(s)
    local data = unpack_cursor(cursor)
    return data, cursor.j-cursor.i
end
local function register(buffer)
    local protoMap = unpack(buffer)
    for root,infoArr in pairs(protoMap) do
        protos[root] = infoArr
    end
end
local function register_file(file_path)
    local f = io.open(file_path , "rb")
    local buffer = f:read("*a")
    f:close()
    return register(buffer)
end
local function encode(root, data)

end
local function decode(root, buffer)
    local dataArr = unpack(buffer)
    return ep_copy_table(root, dataArr)
end

eproto.encode = encode
eproto.decode = decode
eproto.pack = pack
eproto.unpack = unpack
eproto.register = register
eproto.register_file = register_file

return eproto
