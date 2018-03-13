--
-- Created by IntelliJ IDEA.
-- User: AppleTree
-- Date: 17/4/8
-- Time: 下午5:01
-- To change this template use File | Settings | File Templates.
--

local t1,d,dt
local count = 1000000

local dump = require("dump")

local epsilonproto = require("old.epsilonproto")
local Address = {
	[1] = "addr";
	[2] = "num";
	[3] = "phone";
}
local helloProto = {
	[1] = "id";
	[2] = "str";
	[3] = "opt";
	[4] = "time";
	[5] = {epsilonproto.proto_array, "addrs", "Address"};
}
epsilonproto.register("Address", Address)
epsilonproto.register("HelloWorld", helloProto)

-- test data
local addrArray = {
	{
		addr = "广东省深圳市XXX";
		num = 123;
		phone = "123456789";
	};
	{
		addr = "广东省深圳市XXX";
		num = 1234;
		phone = "123456789";
	};
	{
		addr = "广东省深圳市XXX";
		num = 123456;
		phone = "123456789";
	};
}
local data = {
	id = 123;
	str = "你好！HelloWorld！";
	opt = 1234;
	time = os.time();
	addrs = addrArray;
}

local len
t1 = os.clock();
for k=1,count do
	d = epsilonproto.encode("HelloWorld", data)
end
print("data length", #d)
print("count", count, "encode cost", os.clock() - t1)
t1 = os.clock();
for k=1,count do
	dt,len = epsilonproto.decode("HelloWorld", d)
end
print("decode length", len)
print("count", count, "decode cost", os.clock() - t1)
--dump(dt)

local len
t1 = os.clock();
for k=1,count do
	d = epsilonproto.pack(data)
end
print("data length", #d)
print("count", count, "pack cost", os.clock() - t1)
t1 = os.clock();
for k=1,count do
	dt,len = epsilonproto.unpack(d)
end
print("decode length", len)
print("count", count, "unpack cost", os.clock() - t1)

local eproto = require("eproto")
local result = eproto.register_file("tool/invitemgr_client.pb")
print("register_file result", result)

local len
t1 = os.clock();
for k=1,count do
	d = eproto.pack(data)
end
print("data length", #d)
print("count", count, "pack cost", os.clock() - t1)
t1 = os.clock();
for k=1,count do
	dt,len = eproto.unpack(d)
end
print("decode length", len)
print("count", count, "unpack cost", os.clock() - t1)

--dump(dt)

local ep_type_nil = 1
local ep_type_bool = 2
local ep_type_float = 3
local ep_type_int = 4
local ep_type_string = 5
local ep_type_array = 6
local ep_type_map = 7
local ep_type_message = 8
local reg_info = {
	HelloWorld = {
		{ep_type_int, 0, "id", 0};
		{ep_type_string, 1, "str", 0};
		{ep_type_int, 2, "opt", 0};
		{ep_type_int, 3, "time", 0};
		{ep_type_array, 4, "addrs", "Address"};
	};
	Address = {
		{ep_type_string, 0, "addr", 0};
		{ep_type_int, 1, "num", 0};
		{ep_type_string, 2, "phone", 0};
	};
}

local reg_buf = eproto.pack(reg_info)
local result = eproto.register(reg_buf)
print("register result", result)
local infos = eproto.proto()
--dump(infos)

local len
t1 = os.clock();
for k=1,count do
	d = eproto.encode("HelloWorld", data)
end
print("data length", #d)
print("count", count, "encode cost", os.clock() - t1)
t1 = os.clock();
for k=1,count do
	dt,len = eproto.decode("HelloWorld", d)
end
print("decode length", len)
print("count", count, "decode cost", os.clock() - t1)

dump(data)
dump(dt)
