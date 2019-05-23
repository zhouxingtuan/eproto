# eproto
eproto is base on msgpack. support protobuf description file format (.proto). can use in Lua(C++/pure lua),javascript and C#, C++.eproto是基于msgpack的序列化协议，支持使用protobuf文件格式来定义协议，目前支持的语言有Lua（C++版本高效，纯Lua版本方便），JavaScript，C#，C++。

link https://github.com/zhouxingtuan/eproto

# How to define a proto
    define the proto just the same as protobuf

# How to generate a proto file
    in the tool directory, run command to gen a pb file:
        lua gen.lua xxx.proto

# How to use the lua api
    embedded the code into your program, now support with Lua5.1/LuaJIT only:
        eproto.cpp
        eproto.h
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
	    
# How to Use in C++
	in the tool directory, after run command to gen a pb file, you can find the hpp file:
		 xxx.hpp    
    Copy eproto.hpp and these proto files to your project, and include them:
		 test::request* req = test::request::New();
		 eproto::Writer wb;
		 wb.clear();
		 req->Encode(wb);
		 //
		 eproto::Reader rb(wb.data(), wb.size());
		 req->Decode(rb);
		 test::request::Delete(req);
    You can find some simple test in main.cpp
    Note: C++中的message对象采用的是裸指针，需要显式New和Delete，挂载到另一个message里面的message会被连带释放，
		 可以看生成源代码中的Clear函数；由于C++中对数字、字符串、map、vector等没有nil的概念，所以和Lua中的nil
		 会不一致，C++中会给默认值，分别是数字（0）、字符串（空""）、map（空表）、vector（长度为0空数组）。
		 只有message对象使用指针，NULL和nil保持了一致。这里采用了完全public的class模式（类似struct），对新手
		 不友好，容易造成内存泄漏，注意使用。
    
    
    