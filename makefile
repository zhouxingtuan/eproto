
LUAJIT_STATICLIB := ./LuaJIT/src/libluajit.a
LUAJIT_INC := ./LuaJIT/src/

# 静态库的引用需要注意顺序，最底层的静态库放在后面
STATIC_LIB := $(LUAJIT_STATICLIB)

# static的依赖库要放在static的后面，比如luasocket依赖openssl
LIBPATH = -L/usr/local/lib
LIBS = -lssl -lcrypto -lz -lrt -lstdc++ -ldl -lm

INCLUDES = -I$(LUAJIT_INC)

# 注意，这里的 -ldl 需要放在flag的最后才能生效
CFLAGS = -O2 -Wall -Wstrict-overflow=3 -pthread -std=c++11 $(INCLUDES) $(LIBPATH) $(LIBS)

CC = gcc
DEBUG= -g -ggdb
RM = rm -f
BIN = .
TARGET = main

OBJS = epsilonproto.o eproto.o script.o

$(TARGET): main.o $(OBJS)
	$(MAKE) -C ./LuaJIT
	$(CC) $(DEBUG) main.o $(OBJS) $(STATIC_LIB) -o $(BIN)/$(TARGET) $(CFLAGS)

$(OBJS): %.o:%.cpp %.h
	$(CC) $(DEBUG) -c $< -o $@ $(CFLAGS)

main.o:main.cpp
	$(CC) $(DEBUG) -c $< -o $@ $(CFLAGS)

clean:
	-$(RM) $(BIN)/$(TARGET)
	-$(RM) *.o



