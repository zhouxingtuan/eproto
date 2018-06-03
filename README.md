# eproto
eproto is base on msgpack. support protobuf description file format (.proto). can use in Lua(C++/pure lua),javascript and C#.eproto是基于msgpack的序列化协议，支持使用protobuf文件格式来定义协议，目前支持的语言有Lua（C++版本高效，纯Lua版本方便），JavaScript，C#。

link https://github.com/zhouxingtuan/eproto

# How to use
embedded the code into your program, now support with Lua5.1/LuaJIT only:

	eproto.cpp
	eproto.h

the test can be run on Linux

	git clone --recursive https://github.com/zhouxingtuan/eproto
	cd eproto
	make

# How to define a proto
    define the proto just the same as protobuf

# How to use the lua api
    in the tool directory, run command to gen a pb file:
        lua gen.lua xxx.proto
    use the api follow to register a file:
        eproto.register_file("xxx.pb")
    user the api follow to register a buffer from pb file:
        eproto.register(buffer)
    encode:
        eproto.encode("packageName.messageName", tab)
    decode:
        eproto.decode("packageName.messageName", buffer)
    pack:
        eproto.pack(tab)
    unpack:
        eproto.unpack(buf)

# How to use in javascript
	in the tool directory, after run command to gen a pb file, you can find the js file:
		xxx.js
	including the xxx.js into your codes, check the example in index.html:
		<script type="text/javascript" src="eproto.js" ></script>
		<script type="text/javascript" src="invitemgr_client.js" ></script>
	use the api follow:
		var buf = eproto.encode("packageName.messageName", tab);
		var tab = eproto.decode("packageName.messageName", buf);
		var buf = eproto.pack(tab);
		var tab = eproto.unpack(buf);
		
# How to Use in C#
	in the tool directory, after run command to gen a pb file, you can find the cs file:
		xxx.cs
	Copy the Eproto.cs and these proto files to your project:
		 WriteBuffer wb = new WriteBuffer();
		 test.request req = new test.request();
		 wb.Clear();
		 req.Encode(wb);
		 byte[] tb = wb.CopyData();
		 // 
		 ReadBuffer rb = new ReadBuffer(tb);
                 req.Decode(rb);
	    


