
#ifndef __eproto_hpp__
#define __eproto_hpp__

#include <math.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <arpa/inet.h>

#include <vector>
#include <string>

namespace erpc{

#define ntohll(x) ( ( (uint64_t)(ntohl( (uint32_t)((x << 32) >> 32) )) << 32) | ntohl( ((uint32_t)(x >> 32)) ) )
#define htonll(x) ntohll(x)

#define WRITE_BUFFER_SIZE 4096

class WriteBuffer{
	unsigned char* buffer;
	unsigned int bufferSize;
	unsigned int offset;

	WriteBuffer(void) : buffer(NULL), bufferSize(0), offset(0){
		buffer = (unsigned char*)malloc(WRITE_BUFFER_SIZE);
		bufferSize = WRITE_BUFFER_SIZE;
	}
	~WriteBuffer(void){
	    if(buffer != NULL){
	        free(buffer);
	        buffer = NULL;
	    }
	}
	inline unsigned char* data(void){ return (unsigned char*)buffer; }
	inline unsigned int size(void) const { return offset; }
	inline void add(unsigned char b){
		allocBuffer(offset + 1);
		buffer[offset++] = b;
	}
	inline void add(unsigned char b, unsigned char v){
		allocBuffer(offset + 2);
		buffer[offset++] = b;
		buffer[offset++] = v;
	}
	inline void add(unsigned char b, const unsigned char* ptr, unsigned int length){
		allocBuffer(offset + 1 + length);
		buffer[offset++] = b;
		memcpy(buffer + offset, ptr, length);
		offset += length;
	}
	inline void add(unsigned char b, unsigned char v, const unsigned char* ptr, unsigned int length){
		allocBuffer(offset + 2 + length);
		buffer[offset++] = b;
		buffer[offset++] = v;
		memcpy(buffer + offset, ptr, length);
		offset += length;
	}
	inline void add(unsigned char b, unsigned short v, const unsigned char* ptr, unsigned int length){
		allocBuffer(offset + 3 + length);
		buffer[offset++] = b;
		*((unsigned short*)(buffer+offset)) = v;
		offset += 2;
		memcpy(buffer + offset, ptr, length);
		offset += length;
	}
	inline void add(unsigned char b, unsigned int v, const unsigned char* ptr, unsigned int length){
		allocBuffer(offset + 5 + length);
		buffer[offset++] = b;
		*((unsigned int*)(buffer+offset)) = v;
		offset += 4;
		memcpy(buffer + offset, ptr, length);
		offset += length;
	}
	inline void clear(void){
		offset = 0;
	}
	inline void allocBuffer(unsigned int size){
		if(size < bufferSize){
			return;
		}
		unsigned int new_length = bufferSize + WRITE_BUFFER_SIZE;
		if(new_length < size){
			new_length = size;
		}
		unsigned char* new_buf = (unsigned char*)realloc(buffer, new_length);
		if(NULL != new_buf){
			buffer = new_buf;
		}else{
			new_buf = (unsigned char*)malloc(new_length);
			memcpy(new_buf, buffer, bufferSize);
			free(buffer);
			buffer = new_buf;
		}
		bufferSize = new_length;
	}
};

class ReadBuffer{
    unsigned char *buffer;
    unsigned int length;
    unsigned int offset;
    ReadBuffer(void) : buffer(NULL), length(0), offset(0){}
    ReadBuffer(unsigned char *p, unsigned int len) : buffer(p), length(len), offset(0){}
    inline unsigned char* data(void){ return buffer; }
    inline void moveOffset(unsigned int len){ offset += len; }
    inline bool nextIsNil() { return buffer[offset] == 0xc0; }
    inline unsigned char next() { return buffer[offset]; }
    inline unsigned char moveNext(void){ return buffer[offset++]; }
    inline unsigned char* offsetPtr(void) { return buffer + offset; }
    inline bool isOffsetEnd(void) const { return offset >= length; }
    inline void clear(void){
        buffer = NULL;
        length = 0;
        offset = 0;
    }
    inline unsigned int left(void) { return length - offset; }
};

};

#endif
