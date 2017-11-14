# eproto
eproto is base on msgpack. support protobuf description file format (.proto)

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

# How to use the api
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
        eproto.unpack(tab)


