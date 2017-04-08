# epsilonProto
eproto (epsilonProto) is a protocol use in lua, faster than pbc-lua, and is as small as protobuf. 

link https://github.com/zhouxingtuan/epsilonProto 

# How to use
embedded the code into your program, now support with Lua5.1/LuaJIT only:

	eproto.cpp
	eproto.h
	eproto.lua

the test can be run on Linux

	git clone --recursive https://github.com/zhouxingtuan/epsilonProto 
	cd epsilonProto 
	make

# How to define a proto
you can find the test in main.lua like bellow:

	--[[
	# string : the key name, support lua type (boolean/number/string/table)
    # table :
    	the 1 is the type(1 proto_table/ 2 proto_array),
    	the 2 is the key name,
    	the 3 is the proto name refer to
    --]]
	local eproto = require("eproto")
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
		[5] = {eproto.proto_array, "addrs", "Address"};
	}
	eproto.register("Address", Address)
	eproto.register("HelloWorld", helloProto)

# How to use the api
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
	local str = eproto.encode("HelloWorld", data)
	local len,dt = eproto.decode("HelloWorld", str)

# Something more
eproto is base on msgpack serialization, and is change from https://github.com/kengonakajima/lua-msgpack-native.git 

so, eproto supports msgpack api too.

	eproto.pack or eproto_cpp.pack

	eproto.unpack or eproto_cpp.unpack

# Something you should know
1) the original work by lua-msgpack-native is not support multi threads, now we support it.

2) the maximum pack buffer was limited, you can change the define to suit yourself. define in eproto.cpp
	
	#define MSG_PACK_EXPAND_LENGTH 4194304



