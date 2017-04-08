--
-- Created by IntelliJ IDEA.
-- User: AppleTree
-- Date: 17/4/8
-- Time: 下午5:01
-- To change this template use File | Settings | File Templates.
--

local t1,d,dt
local count = 1000000

local eproto = require("eproto")
local Address = {
	[1] = "addr";
	[2] = "name";
	[3] = "phone";
}
local helloProto = {
	[1] = "id";
	[2] = "str";
	[3] = "opt";
	[4] = "time";
	[5] = {eproto.proto_array, "addrs", "Address"};
}
eproto.register("Address", Address)
eproto.register("HelloWorld", helloProto)

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
	d = eproto.encode("HelloWorld", data)
end
print("data length", #d)
print("count", count, "encode cost", os.clock() - t1)
t1 = os.clock();
for k=1,count do
	len,dt = eproto.decode("HelloWorld", d)
end
print("count", count, "decode cost", os.clock() - t1)

