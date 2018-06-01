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

-- -------------------------------------------
--  handle double
local luabit
local check_bit = function()
    local res,err = pcall( function() return require "bit" end )
    if not res then
        print("msgpack: no bitops. falling back: load local luabit.")
        ------------------------
        -- bit lib implementions

        local function check_int(n)
            -- checking not float
            if(n - math.floor(n) > 0) then
                error("trying to use bitwise operation on non-integer!")
            end
        end

        local function to_bits(n)
            check_int(n)
            if(n < 0) then
                -- negative
                return to_bits(bit.bnot(math.abs(n)) + 1)
            end
            -- to bits table
            local tbl = {}
            local cnt = 1
            while (n > 0) do
                local last = math.mod(n,2)
                if(last == 1) then
                    tbl[cnt] = 1
                else
                    tbl[cnt] = 0
                end
                n = (n-last)/2
                cnt = cnt + 1
            end

            return tbl
        end

        local function tbl_to_number(tbl)
            local n = table.getn(tbl)

            local rslt = 0
            local power = 1
            for i = 1, n do
                rslt = rslt + tbl[i]*power
                power = power*2
            end

            return rslt
        end

        local function expand(tbl_m, tbl_n)
            local big = {}
            local small = {}
            if(table.getn(tbl_m) > table.getn(tbl_n)) then
                big = tbl_m
                small = tbl_n
            else
                big = tbl_n
                small = tbl_m
            end
            -- expand small
            for i = table.getn(small) + 1, table.getn(big) do
                small[i] = 0
            end

        end

        local function bit_or(m, n)
            local tbl_m = to_bits(m)
            local tbl_n = to_bits(n)
            expand(tbl_m, tbl_n)

            local tbl = {}
            local rslt = math.max(table.getn(tbl_m), table.getn(tbl_n))
            for i = 1, rslt do
                if(tbl_m[i]== 0 and tbl_n[i] == 0) then
                    tbl[i] = 0
                else
                    tbl[i] = 1
                end
            end

            return tbl_to_number(tbl)
        end

        local function bit_and(m, n)
            local tbl_m = to_bits(m)
            local tbl_n = to_bits(n)
            expand(tbl_m, tbl_n)

            local tbl = {}
            local rslt = math.max(table.getn(tbl_m), table.getn(tbl_n))
            for i = 1, rslt do
                if(tbl_m[i]== 0 or tbl_n[i] == 0) then
                    tbl[i] = 0
                else
                    tbl[i] = 1
                end
            end

            return tbl_to_number(tbl)
        end

        local function bit_not(n)

            local tbl = to_bits(n)
            local size = math.max(table.getn(tbl), 32)
            for i = 1, size do
                if(tbl[i] == 1) then
                    tbl[i] = 0
                else
                    tbl[i] = 1
                end
            end
            return tbl_to_number(tbl)
        end

        local function bit_xor(m, n)
            local tbl_m = to_bits(m)
            local tbl_n = to_bits(n)
            expand(tbl_m, tbl_n)

            local tbl = {}
            local rslt = math.max(table.getn(tbl_m), table.getn(tbl_n))
            for i = 1, rslt do
                if(tbl_m[i] ~= tbl_n[i]) then
                    tbl[i] = 1
                else
                    tbl[i] = 0
                end
            end

            --table.foreach(tbl, print)

            return tbl_to_number(tbl)
        end

        local function bit_rshift(n, bits)
            check_int(n)

            local high_bit = 0
            if(n < 0) then
                -- negative
                n = bit_not(math.abs(n)) + 1
                high_bit = 2147483648 -- 0x80000000
            end

            for i=1, bits do
                n = n/2
                n = bit_or(math.floor(n), high_bit)
            end
            return math.floor(n)
        end

        -- logic rightshift assures zero filling shift
        local function bit_logic_rshift(n, bits)
            check_int(n)
            if(n < 0) then
                -- negative
                n = bit_not(math.abs(n)) + 1
            end
            for i=1, bits do
                n = n/2
            end
            return math.floor(n)
        end

        local function bit_lshift(n, bits)
            check_int(n)

            if(n < 0) then
                -- negative
                n = bit_not(math.abs(n)) + 1
            end

            for i=1, bits do
                n = n*2
            end
            return bit_and(n, 4294967295) -- 0xFFFFFFFF
        end

        local function bit_xor2(m, n)
            local rhs = bit_or(bit_not(m), bit_not(n))
            local lhs = bit_or(m, n)
            local rslt = bit_and(lhs, rhs)
            return rslt
        end

        --------------------
        -- bit lib interface

        local bit = {
            -- bit operations
            bnot = bit_not,
            band = bit_and,
            bor  = bit_or,
            bxor = bit_xor,
            brshift = bit_rshift,
            blshift = bit_lshift,
            bxor2 = bit_xor2,
            blogic_rshift = bit_logic_rshift,

            -- utility func
            tobits = to_bits,
            tonumb = tbl_to_number,
        }
        luabit = bit
        --    luabit = require "luabit" -- local
    else
        luabit = require "bit"
    end
    return luabit
end
luabit = check_bit()

-- cache bitops
local bor,band,bxor,rshift = luabit.bor,luabit.band,luabit.bxor,luabit.brshift
if not rshift then -- luajit differ from luabit
    rshift = luabit.rshift
end
-- out little endian
local doubleto8bytes = function(x)
    local function grab_byte(v)
        return math.floor(v / 256), char(math.fmod(math.floor(v), 256))
    end
    local sign = 0
    if x < 0 then sign = 1; x = -x end
    local mantissa, exponent = math.frexp(x)
    if x == 0 then -- zero
        mantissa, exponent = 0, 0
    elseif x == 1/0 then
        mantissa, exponent = 0, 2047
    else
        mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 53)
        exponent = exponent + 1022
    end
    --   print("doubleto8bytes: exp:", exponent, "mantissa:", mantissa , "sign:", sign )

    local v, byte = "",0 -- convert to bytes
    x = mantissa
    for i = 1,6 do
        x, byte = grab_byte(x); v = v..byte -- 47:0
    end
    x, byte = grab_byte(exponent * 16 + x);  v = v..byte -- 55:48
    x, byte = grab_byte(sign * 128 + x); v = v..byte -- 63:56
    return v
end
local function bitstofrac(ary)
    local x = 0
    local cur = 0.5
    for i,v in ipairs(ary) do
        x = x + cur * v
        cur = cur / 2
    end
    return x
end
local function bytestobits(ary)
    local out={}
    for i,v in ipairs(ary) do
        for j=0,7,1 do
            table.insert(out, band( rshift(v,7-j), 1 ) )
        end
    end
    return out
end
local function dumpbits(ary)
    local s=""
    for i,v in ipairs(ary) do
        s = s .. v .. " "
        if (i%8)==0 then s = s .. " " end
    end
    print(s)
end
-- get little endian
local function bytestodouble(v)
    -- sign:1bit
    -- exp: 11bit (2048, bias=1023)
    local sign = math.floor(v:byte(8) / 128)
    local exp = band( v:byte(8), 127 ) * 16 + rshift( v:byte(7), 4 ) - 1023 -- bias
    -- frac: 52 bit
    local fracbytes = {
        band( v:byte(7), 15 ), v:byte(6), v:byte(5), v:byte(4), v:byte(3), v:byte(2), v:byte(1) -- big endian
    }
    local bits = bytestobits(fracbytes)

    for i=1,4 do table.remove(bits,1) end

    --   dumpbits(bits)

    if sign == 1 then sign = -1 else sign = 1 end

    local frac = bitstofrac(bits)
    if exp == -1023 and frac==0 then return 0 end
    if exp == 1024 and frac==0 then return 1/0 *sign end
    local real = math.ldexp(1+frac,exp)

    --   print( "sign:", sign, "exp:", exp,  "frac:", frac, "real:", real, "v:", v:byte(1),v:byte(2),v:byte(3),v:byte(4),v:byte(5),v:byte(6),v:byte(7),v:byte(8) )
    return real * sign
end
-- -------------------------------------------

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
local function pack_map(buffer, tbl, n)
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
    -- 大于一半一上的数字元素，使用array
    if is_map or max > n*2 then
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
local function pack_double(buffer, n)
    local b = doubleto8bytes(n)
    local rb = string.reverse(b)
    buffer[#buffer+1] = char(0xcb)
    buffer[#buffer+1] = rb
--    local sign = 0
--    if n < 0.0 then
--        sign = 0x80
--        n = -n
--    end
--    local mant, expo = frexp(n)
--    if mant ~= mant then
--        buffer[#buffer+1] = char(0xCB,  -- nan
--            0xFF, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
--    elseif mant == huge or expo > 0x400 then
--        if sign == 0 then
--            buffer[#buffer+1] = char(0xCB,      -- inf
--                0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
--        else
--            buffer[#buffer+1] = char(0xCB,      -- -inf
--                0xFF, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
--        end
--    elseif (mant == 0.0 and expo == 0) or expo < -0x3FE then
--        buffer[#buffer+1] = char(0xCB,  -- zero
--            sign, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
--    else
--        expo = expo + 0x3FE
--        mant = floor((mant * 2.0 - 1.0) * ldexp(0.5, 53))
--        buffer[#buffer+1] = char(0xCB,
--            sign + floor(expo / 0x10),
--            (expo % 0x10) * 0x10 + floor(mant / 0x1000000000000),
--            floor(mant / 0x10000000000) % 0x100,
--            floor(mant / 0x100000000) % 0x100,
--            floor(mant / 0x1000000) % 0x100,
--            floor(mant / 0x10000) % 0x100,
--            floor(mant / 0x100) % 0x100,
--            mant % 0x100)
--    end
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

    local s = string.char(b8,b7,b6,b5,b4,b3,b2,b1)
    local n = bytestodouble( s )
    c.i = i+8
    return n
    --    local sign = b1 > 0x7F
--    local expo = (b1 % 0x80) * 0x10 + floor(b2 / 0x10)
--    local mant = ((((((b2 % 0x10) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8
--    if sign then
--        sign = -1
--    else
--        sign = 1
--    end
--    local n
--    if mant == 0 and expo == 0 then
--        n = sign * 0.0
--    elseif expo == 0x7FF then
--        if mant == 0 then
--            n = sign * huge
--        else
--            n = 0.0/0.0
--        end
--    else
--        n = sign * ldexp(1.0 + mant / 4503599627370496.0, expo - 0x3FF)
--    end
--    c.i = i+8
--    return n
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
unpackers = setmetatable({
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
}, {
    __index = function (t, k)
        if k < 0xC0 then
            if k < 0x80 then
                return function (c, val) return val end
            elseif k < 0x90 then
                return function (c, val) return unpack_map(c, val % 0x10) end
            elseif k < 0xA0 then
                return function (c, val) return unpack_array(c, val % 0x10) end
            else
                return function (c, val) return unpack_str(c, val % 0x20) end
            end
        elseif k > 0xDF then
            return function (c, val) return val - 0x100 end
        else
            return function () error("unpack '" .. format('%#x', k) .. "' is unimplemented") end
        end
    end
})

local protos = {};
local eproto = {}

local ep_encode_proto
local ep_encode_proto_normal
local ep_encode_proto_normal_array
local ep_count_map
local ep_copy_table

ep_encode_proto_normal = function(buffer, ep_type, value)
    if ep_type == ep_type_bool then
        pack_bool(buffer, value)
    elseif ep_type == ep_type_float then
        pack_double(buffer, value)
    elseif ep_type == ep_type_int then
        pack_integer(buffer, value)
    elseif ep_type == ep_type_string then
        pack_string(buffer, value)
    elseif ep_type == ep_type_bytes then
        pack_bytes(buffer, value)
    else
        error("encode unknown normal ep_type", ep_type)
    end
end
ep_encode_proto_normal_array = function(buffer, ep_type, value)
    if ep_type == ep_type_bool then
        for _,v in ipairs(value) do
            pack_bool(buffer, value)
        end
    elseif ep_type == ep_type_float then
        for _,v in ipairs(value) do
            pack_double(buffer, value)
        end
    elseif ep_type == ep_type_int then
        for _,v in ipairs(value) do
            pack_integer(buffer, value)
        end
    elseif ep_type == ep_type_string then
        for _,v in ipairs(value) do
            pack_string(buffer, value)
        end
    elseif ep_type == ep_type_bytes then
        for _,v in ipairs(value) do
            pack_bytes(buffer, value)
        end
    else
        error("encode unknown normal ep_type", ep_type)
    end
end
ep_count_map = function(data)
    local count = 0
    for _,_ in pairs(data) do
        count = count + 1
    end
    return count
end
ep_encode_proto = function(buffer, root, data)
    if data == nil then
        pack_nil(buffer)
        return
    end
    local infoData = protos[root]
    local infoMap = infoData.map
    local max_index = infoData.max
    pack_array_head(buffer, max_index)
    for k=1,max_index do
        local info = infoMap[k]
        if info == nil then
            pack_nil(buffer)
        else
            local ep_type = info[1]
            --        local index = info[2] + 1   -- index 从0开始的
            local name = info[3]
            local value = data[name]
            if value == nil then
                pack_nil(buffer)
            elseif ep_type == ep_type_array then
                local arr_type = info[4]
                pack_array_head(buffer, #value)
                if type(arr_type) == "string" then
                    -- proto
                    for _,v in ipairs(value) do
                        ep_encode_proto(buffer, arr_type, v)
                    end
                else
                    ep_encode_proto_normal_array(buffer, ep_type, value)
                end
            elseif ep_type == ep_type_map then
                local key_type = info[4]
                local value_type = info[5]
                local count = ep_count_map(value)
                pack_map_head(buffer, count)
                if type(value_type) == "string" then
                    -- proto
                    for k,v in pairs(value) do
                        ep_encode_proto_normal(buffer, key_type, k)
                        ep_encode_proto(buffer, value_type, v)
                    end
                else
                    for k,v in pairs(value) do
                        ep_encode_proto_normal(buffer, key_type, k)
                        ep_encode_proto_normal(buffer, value_type, v)
                    end
                end
            elseif ep_type == ep_type_message then
                local proto_type = info[4]
                ep_encode_proto(buffer, proto_type, value)
            else
                ep_encode_proto_normal(buffer, ep_type, value)
            end
        end
    end
end
ep_copy_table = function(root, dataArr)
    local tab = {}
    local infoData = protos[root]
    local infoMap = infoData.map
    for _,info in pairs(infoMap) do
        local ep_type = info[1]
        local index = info[2] + 1   -- index 从0开始的
        local name = info[3]
        local value = dataArr[index]
        if value == nil then
            -- do nothing here
        elseif ep_type == ep_type_array then
            local arr_type = info[4]
            if type(arr_type) == "string" then
                -- proto
                local arr = {}
                for k,v in ipairs(value) do
                    arr[k] = ep_copy_table(arr_type, v)
                end
                tab[name] = arr
            else
                tab[name] = value
            end
        elseif ep_type == ep_type_map then
            local key_type = info[4]
            local value_type = info[5]
            if type(value_type) == "string" then
                -- proto
                local a = {}
                for k,v in pairs(value) do
                    a[k] = ep_copy_table(value_type, v)
                end
            else
                tab[name] = value
            end
        elseif ep_type == ep_type_message then
            local proto_type = info[4]
            tab[name] = ep_copy_table(proto_type, value)
        else
            tab[name] = value
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
        local map = {}
        local infoData = {
            map = map;
            max = 0;
        }
        local max_index = 0
        for _,info in ipairs(infoArr) do
            local index = info[2] + 1   -- index 从0开始的
            if index > max_index then
                max_index = index
            end
            map[index] = info
        end
        infoData.max = max_index
        protos[root] = infoData
    end
end
local function register_file(file_path)
    local f = io.open(file_path , "rb")
    local buffer = f:read("*a")
    f:close()
    return register(buffer)
end
local function encode(root, data)
    local buffer = {}
    ep_encode_proto(buffer, root, data)
    return tconcat(buffer)
end
local function decode(root, buffer)
    local dataArr = unpack(buffer)
--    return dataArr
    return ep_copy_table(root, dataArr)
end

eproto.encode = encode
eproto.decode = decode
eproto.pack = pack
eproto.unpack = unpack
eproto.register = register
eproto.register_file = register_file

return eproto
