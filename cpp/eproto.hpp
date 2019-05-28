
#ifndef __eproto_hpp__
#define __eproto_hpp__

#include <math.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#ifdef _WIN32
#include <windows.h>
#pragma comment(lib, "wsock32.lib")
#else
#include <arpa/inet.h>
#endif

#include <vector>
#include <string>
#include <unordered_map>
#include <atomic>

namespace eproto{

#define ntohll(x) ( ( (uint64_t)(ntohl( (uint32_t)((x << 32) >> 32) )) << 32) | ntohl( ((uint32_t)(x >> 32)) ) )
#define htonll(x) ntohll(x)

#define WRITE_BUFFER_SIZE 4096

class Writer{
public:
	unsigned char* buffer;
	unsigned int bufferSize;
	unsigned int offset;

	Writer(void) : buffer(NULL), bufferSize(0), offset(0){
		buffer = (unsigned char*)malloc(WRITE_BUFFER_SIZE);
		bufferSize = WRITE_BUFFER_SIZE;
	}
	~Writer(void){
	    if(buffer != NULL){
	        free(buffer);
	        buffer = NULL;
	    }
	}
	inline unsigned char* data(void){ return (unsigned char*)buffer; }
	inline unsigned int size(void) const { return offset; }

    inline void pack_nil(void){
        add(0xc0);
    }
	inline void pack_bool(bool b){
	    if(b){
	        add(0xc3);
	    }else{
	        add(0xc2);
	    }
	}
	inline void pack_int(long long int lv){
        if(lv>=0){
            if(lv<128){
                add((unsigned char)lv);
            } else if(lv<256){
                unsigned char v = (unsigned char)lv;
                add(0xcc, v);
            } else if(lv<65536){
                unsigned short v = htons((short)lv);
                add(0xcd, (unsigned char*)&v, 2);
            } else if(lv<4294967296LL){
                long v = htonl((long)lv);
                add(0xce, (unsigned char*)&v, 4);
            } else {
                long long int v = htonll((long long int)lv);
                add(0xcf, (unsigned char*)&v, 8);
            }
        } else {
            if(lv >= -32){
                unsigned char v = 0xe0 | (char)lv;
                add(v);
            } else if( lv >= -128 ){
                unsigned char v = (unsigned char)lv;
                add(0xd0, v);
            } else if( lv >= -32768 ){
                short v = htons(lv&0xffff);
                add(0xd1, (unsigned char*)&v, 2);
            } else if( lv >= -2147483648LL ){
                int v = htonl(lv&0xffffffff);
                add(0xd2, (unsigned char*)&v, 4);
            } else{
                long long int v = htonll(lv);
                add(0xd3, (unsigned char*)&v, 8);
            }
        }
	}
	inline void pack_double(float value){
	    radd(0xca, (unsigned char*)&value, 4);
	}
	inline void pack_double(double value){
	    radd(0xcb, (unsigned char*)&value, 8);
	}
	inline void pack_string(const std::string &str){
	    const unsigned char *sval = (unsigned char*)str.c_str();
	    size_t slen = str.length();
        unsigned char topbyte = 0;
        if(slen<32){
            topbyte = 0xa0 | (char)slen;
            add(topbyte, sval, slen);
        }else if(slen<256){
            topbyte = 0xd9;
            unsigned char l = slen;
            add8(topbyte, l, sval);
        } else if(slen<65536){
            topbyte = 0xda;
            unsigned short l = htons(slen);
            add16(topbyte, l, sval);
        } else if(slen<4294967296LL-1){ // TODO: -1 for avoiding (condition is always true warning)
            topbyte = 0xdb;
            unsigned int l = htonl(slen);
            add32(topbyte, l, sval);
        } else {
            fprintf(stderr, "pack_string length is out of range\n");
        }
	}
    inline void pack_bytes(const std::vector<char> &arr){
        const unsigned char *sval = (unsigned char*)arr.data();
        size_t slen = arr.size();
        unsigned char topbyte = 0;
        if(slen<256){
            topbyte = 0xc4;
            unsigned char l = slen;
            add8(topbyte, l, sval);
        } else if(slen<65536){
            topbyte = 0xc5;
            unsigned short l = htons(slen);
            add16(topbyte, l, sval);
        } else if(slen<4294967296LL-1){ // TODO: -1 for avoiding (condition is always true warning)
            topbyte = 0xc6;
            unsigned int l = htonl(slen);
            add32(topbyte, l, sval);
        } else {
            fprintf(stderr, "pack_bytes length is out of range\n");
        }
    }
    inline void pack_array(size_t l){
        unsigned char topbyte;
        // array!(ignore map part.) 0x90|n , 0xdc+2byte, 0xdd+4byte
        if(l<16){
            topbyte = 0x90 | (unsigned char)l;
            add(topbyte);
        } else if( l<65536){
            topbyte = 0xdc;
            unsigned short elemnum = htons(l);
            add(topbyte, (unsigned char*)&elemnum, 2);
        } else if( l<4294967296LL-1){ // TODO: avoid C warn
            topbyte = 0xdd;
            unsigned int elemnum = htonl(l);
            add(topbyte, (unsigned char*)&elemnum, 4);
        }
    }
    inline void pack_map(size_t l){
    	unsigned char topbyte;
        // map fixmap, 16,32 : 0x80|num, 0xde+2byte, 0xdf+4byte
        if(l<16){
            topbyte = 0x80 | (char)l;
            add(topbyte);
        }else if(l<65536){
            topbyte = 0xde;
            unsigned short elemnum = htons(l);
            add(topbyte, (unsigned char*)&elemnum, 2);
        }else if(l<4294967296LL-1){
            topbyte = 0xdf;
            unsigned int elemnum = htonl(l);
            add(topbyte, (unsigned char*)&elemnum, 4);
        }
    }

	inline void add(unsigned char b){
		allocBuffer(offset + 1);
		buffer[offset++] = b;
	}
	inline void add(unsigned char b, unsigned char v){
		allocBuffer(offset + 2);
		buffer[offset++] = b;
		buffer[offset++] = v;
	}
	inline void add(unsigned char b, const unsigned char *ptr, unsigned int length){
		allocBuffer(offset + 1 + length);
		buffer[offset++] = b;
		memcpy(buffer + offset, ptr, length);
		offset += length;
	}
	inline void add8(unsigned char b, unsigned char length, const unsigned char *ptr){
		allocBuffer(offset + 2 + length);
		buffer[offset++] = b;
		buffer[offset++] = length;
		memcpy(buffer + offset, ptr, length);
		offset += length;
	}
	inline void add16(unsigned char b, unsigned short length, const unsigned char *ptr){
	    unsigned short v = (unsigned short)htons(length);
		allocBuffer(offset + 3 + length);
		buffer[offset++] = b;
		*((unsigned short*)(buffer+offset)) = v;
		offset += 2;
		memcpy(buffer + offset, ptr, length);
		offset += length;
	}
	inline void add32(unsigned char b, unsigned int length, const unsigned char *ptr){
	    unsigned int v = (unsigned int)htonl(length);
		allocBuffer(offset + 5 + length);
		buffer[offset++] = b;
		*((unsigned int*)(buffer+offset)) = v;
		offset += 4;
		memcpy(buffer + offset, ptr, length);
		offset += length;
	}
	inline void radd(unsigned char b, const unsigned char *ptr, unsigned int length){
		allocBuffer(offset + 1 + length);
		buffer[offset++] = b;
		for(int i=(int)length-1; i>=0; --i){
			buffer[offset++] = ptr[i];
		}
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

class Reader{
public:
    unsigned char *buffer;
    unsigned int length;
    unsigned int offset;
    Reader(void) : buffer(NULL), length(0), offset(0){}
    Reader(unsigned char *p, unsigned int len) : buffer(p), length(len), offset(0){}
    inline void resetBuffer(unsigned char *p, unsigned int len){
        buffer = p;
        length = len;
        offset = 0;
    }
    inline unsigned char* data(void){ return buffer; }
    inline void moveOffset(unsigned int len){ offset += len; }
    inline bool nextIsNil(void) { return buffer[offset] == 0xc0; }
    inline unsigned char next(void) { return buffer[offset]; }
    inline unsigned char moveNext(void){ return buffer[offset++]; }
    inline unsigned char* offsetPtr(void) { return buffer + offset; }
    inline bool isOffsetEnd(void) const { return offset >= length; }
    inline void clear(void){
        buffer = NULL;
        length = 0;
        offset = 0;
    }
    inline unsigned int left(void) { return length - offset; }
    inline void rcopy(unsigned char *dest, size_t l){
        unsigned char *from = offsetPtr();
        size_t i;
        for(i=0;i<l;i++){
            dest[l-i-1]=from[i];
        }
    }

    inline void unpack_bool(bool &value){
        unsigned char t = moveNext();
        switch(t){
            case 0xc0: break;  // nil
            case 0xc2: value = false; break;
            case 0xc3: value = true; break;
            default:
                fprintf(stderr, "unpack_bool failed\n");
                break;
        }
    }
    inline void unpack_int(unsigned char &value){
        long long int v = 0;
        if(unpack_int(v)){
            value = (unsigned char)v;
        }
    }
    inline void unpack_int(unsigned short &value){
        long long int v = 0;
        if(unpack_int(v)){
            value = (unsigned short)v;
        }
    }
    inline void unpack_int(unsigned int &value){
        long long int v = 0;
        if(unpack_int(v)){
            value = (unsigned int)v;
        }
    }
    inline void unpack_int(unsigned long long int &value){
        long long int v = 0;
        if(unpack_int(v)){
            value = (unsigned long long int)v;
        }
    }
    inline void unpack_int(char &value){
        long long int v = 0;
        if(unpack_int(v)){
            value = (char)v;
        }
    }
    inline void unpack_int(short &value){
        long long int v = 0;
        if(unpack_int(v)){
            value = (short)v;
        }
    }
    inline void unpack_int(int &value){
        long long int v = 0;
        if(unpack_int(v)){
            value = (int)v;
        }
    }
    inline bool unpack_int(long long int &value){
        unsigned char t = moveNext();
        if(t == 0xc0)
        {
            return true;
        }
        if (t < 0x80)// fixint
        {
            value = t;
            return true;
        }
        if (t > 0xdf)// fixint_negative
        {
            value = (256 - t) * -1;
            return true;
        }
        switch (t)
        {
            case 0xcc:// uint8
            {
                if(left() < 1)
                {
                    fprintf(stderr, "unpack_int uint8 failed\n");
                    return false;
                }
                value = moveNext();
                break;
            }
            case 0xcd:// uint16
            {
                if (left() < 2)
                {
                    fprintf(stderr, "unpack_int uint16 failed\n");
                    return false;
                }
                value = ntohs( *(short*)(offsetPtr()) );
                moveOffset(2);
                break;
            }
            case 0xce:// uint
            {
                if (left() < 4)
                {
                    fprintf(stderr, "unpack_int uint failed\n");
                    return false;
                }
                value = ntohl( *(long*)(offsetPtr()) );
                moveOffset(4);
                break;
            }
            case 0xcf:// uint64
            {
                if (left() < 8)
                {
                    fprintf(stderr, "unpack_int uint64 failed\n");
                    return false;
                }
                value = ntohll(*(long long int*)(offsetPtr()));
                moveOffset(8);
                break;
            }
            case 0xd0:// int8
            {
                if (left() < 1)
                {
                    fprintf(stderr, "unpack_int int8 failed\n");
                    return false;
                }
                value = moveNext();
                break;
            }
            case 0xd1:// int16
            {
                if (left() < 2)
                {
                    fprintf(stderr, "unpack_int int16 failed\n");
                    return false;
                }
                value = ntohs( *(short*)(offsetPtr()) );
                moveOffset(2);
                break;
            }
            case 0xd2:// int32
            {
                if (left() < 4)
                {
                    fprintf(stderr, "unpack_int int32 failed\n");
                    return false;
                }
                value = ntohl( *(long*)(offsetPtr()) );
                moveOffset(4);
                break;
            }
            case 0xd3:// int64
            {
                if (left() < 8)
                {
                    fprintf(stderr, "unpack_int int64 failed\n");
                    return false;
                }
                value = ntohll(*(long long int*)(offsetPtr()));
                moveOffset(8);
                break;
            }
            default:
            {
                fprintf(stderr, "unknown int type=0x%x\n", t);
                return false;
            }
        }
        return true;
    }
    inline void unpack_double(float &value){
        double v = 0;
        if( unpack_double(v) )
        {
            value = (float)v;
        }
    }
    inline bool unpack_double(double &value){
        unsigned char t = moveNext();
        switch (t)
        {
            case 0xc0: return true;
            case 0xca:
            {
                if(left() < 4)
                {
                    fprintf(stderr, "unpack_double float failed\n");
                    return false;
                }
                float v = 0;
                rcopy((unsigned char*)(&v), 4);
                value = v;
                moveOffset(4);
                break;
            }
            case 0xcb:
            {
                if (left() < 8)
                {
                    fprintf(stderr, "unpack_double double failed\n");
                    return false;
                }
                rcopy((unsigned char*)(&value), 8);
                moveOffset(8);
                break;
            }
            default:
            {
                fprintf(stderr, "unknown double type=0x%x\n", t);
                return false;
            }
            return true;
        }
        return true;
    }
    inline bool unpack_string(std::string &value){
//        value.clear();
        unsigned char t = moveNext();
        if (t == 0xc0)
        {
            return true;
        }
        if (t > 0x9f && t < 0xc0)
        {
            int slen = t & 0x1f;
            if (left() < (unsigned int)slen)
            {
                fprintf(stderr, "unpack_string fixed str failed\n");
                return false;
            }
            value.append((char*)offsetPtr(), slen);
            moveOffset(slen);
            return true;
        }
        switch (t)
        {
            case 0xd9:// str8
                {
                    if (left() < 1)
                    {
                        fprintf(stderr, "unpack_string str8 length failed\n");
                        return false;
                    }
                    unsigned char slen = moveNext();
                    if (left() < slen)
                    {
                        fprintf(stderr, "unpack_string str8 failed\n");
                        return false;
                    }
                    value.append((char*)offsetPtr(), slen);
                    moveOffset(slen);
                    break;
                }
            case 0xda:// str16
                {
                    unsigned short slen = 0;
                    if (left() < 2)
                    {
                        fprintf(stderr, "unpack_string str16 length failed\n");
                        return false;
                    }
                    slen = ntohs( *(short*)(offsetPtr()) );
                    moveOffset(2);
                    if (left() < slen)
                    {
                        fprintf(stderr, "unpack_string str16 failed\n");
                        return false;
                    }
                    value.append((char*)offsetPtr(), slen);
                    moveOffset(slen);
                    break;
                }
            case 0xdb:// str32
                {
                    unsigned int slen = 0;
                    if (left() < 4)
                    {
                        fprintf(stderr, "unpack_string str32 length failed\n");
                        return false;
                    }
                    slen = ntohl( *(long*)(offsetPtr()) );
                    moveOffset(4);
                    if (left() < slen)
                    {
                        fprintf(stderr, "unpack_string str32 failed\n");
                        return false;
                    }
                    value.append((char*)offsetPtr(), slen);
                    moveOffset(slen);
                    break;
                }
            default:
                {
                    fprintf(stderr, "unpack_string unknown type=0x%x\n", t);
                    return false;
                }
        }
        return true;
    }
    inline bool unpack_bytes(std::vector<char> &value){
//        value.clear();
        unsigned char t = moveNext();
        if (t == 0xc0)
        {
            return true;
        }
        switch (t)
        {
            case 0xc4:// bin8
            {
                if (left() < 1)
                {
                    fprintf(stderr, "unpack_bytes bin8 length failed\n");
                    return false;
                }
                unsigned char slen = moveNext();
                if (left() < slen)
                {
                    fprintf(stderr, "unpack_bytes bin failed\n");
                    return false;
                }
                value.resize(slen);
                memcpy(value.data(), (char*)offsetPtr(), slen);
                moveOffset(slen);
                break;
            }
            case 0xc5:// bin16
                {
                    unsigned short slen = 0;
                    if (left() < 2)
                    {
                        fprintf(stderr, "unpack_bytes bin16 length failed\n");
                        return false;
                    }
                    slen = ntohs( *(short*)(offsetPtr()) );
                    moveOffset(2);
                    if (left() < slen)
                    {
                        fprintf(stderr, "unpack_bytes bin16 failed\n");
                        return false;
                    }
                    value.resize(slen);
                    memcpy(value.data(), (char*)offsetPtr(), slen);
                    moveOffset(slen);
                    break;
                }
            case 0xc6:// bin32
                {
                    unsigned int slen = 0;
                    if (left() < 4)
                    {
                        fprintf(stderr, "unpack_bytes bin32 length failed\n");
                        return false;
                    }
                    slen = ntohl( *(long*)(offsetPtr()) );
                    moveOffset(4);
                    if (left() < slen)
                    {
                        fprintf(stderr, "unpack_bytes bin32 failed\n");
                        return false;
                    }
                    value.resize(slen);
                    memcpy(value.data(), (char*)offsetPtr(), slen);
                    moveOffset(slen);
                    break;
                }
            default:
                {
                    fprintf(stderr, "unpack_bytes unknown type0x=%x\n", t);
                    return false;
                }
        }
        return true;
    }
    inline long long int unpack_array(void){
        unsigned char t = moveNext();
        if (t == 0xc0)
        {
            return -1;
        }
        if (t > 0x8f && t < 0xa0)
        {
            int arylen = t & 0xf;
            return arylen;
        }
        switch (t)
        {
            case 0xdc:// array16
                {
                    unsigned short slen = 0;
                    if (left() < 2)
                    {
                        fprintf(stderr, "unpack_array array16 length failed\n");
                        return -3;
                    }
                    slen = ntohs( *(short*)(offsetPtr()) );
                    moveOffset(2);
                    return slen;
                }
            case 0xdd:// array32
                {
                    unsigned int slen = 0;
                    if (left() < 4)
                    {
                        fprintf(stderr, "unpack_array array32 length failed\n");
                        return -4;
                    }
                    slen = ntohl( *(long*)(offsetPtr()) );
                    moveOffset(4);
                    return slen;
                }
            default:
                {
                    fprintf(stderr, "unpack_array unknown type=0x%x\n", t);
                    break;
                }
        }
        return -2;
    }
    inline long long int unpack_map(void){
        unsigned char t = moveNext();
        if (t == 0xc0)
        {
            return -1;
        }
        if (t > 0x7f && t < 0x90)
        {
            int maplen = t & 0xf;
            return maplen;
        }
        switch (t)
        {
            case 0xde:// map16
                {
                    unsigned short slen = 0;
                    if (left() < 2)
                    {
                        fprintf(stderr, "unpack_map map16 length failed\n");
                        return -3;
                    }
                    slen = ntohs( *(short*)(offsetPtr()) );
                    moveOffset(2);
                    return slen;
                }
            case 0xdf:// map32
                {
                    unsigned int slen = 0;
                    if (left() < 4)
                    {
                        fprintf(stderr, "unpack_map map32 length failed\n");
                        return -4;
                    }
                    slen = ntohl( *(long*)(offsetPtr()) );
                    moveOffset(4);
                    return slen;
                }
            default:
                {
                    fprintf(stderr, "unpack_map unknown type=0x%x\n", t);
                    break;
                }
        }
        return -2;
    }
    void unpack_discard(long long int count){
        if(count <= 0)
        {
            return;
        }
        for(long long int i=0; i<count; ++i)
        {
            discard();
        }
    }
    void discard(){
        if(left() < 1)
        {
            return;
        }
        unsigned char t = moveNext();
        // positive fixint
        if (t < 0x80)
        {
            return;
        }
        // fixstr
        if (t > 0x9f && t < 0xc0)
        {
            int slen = t & 0x1f;
            if (left() < (unsigned int)slen)
            {
                fprintf(stderr, "discard fixed str failed\n");
                return;
            }
            moveOffset(slen);
            return;
        }
        // fixmap
        if (t > 0x7f && t < 0x90)
        {
            int maplen = t & 0xf;
            unpack_discard(maplen * 2);
            return;
        }
        // fixarray
        if (t > 0x8f && t < 0xa0)
        {
            int arylen = t & 0xf;
            unpack_discard(arylen);
            return;
        }
        // negative fixint
        if (t > 0xdf)
        {
            return;
        }
        switch (t)
        {
            case 0xc0:// nil
                return;
            case 0xc2:// false
                return;
            case 0xc3:// true
                return;
            case 0xcc:// uint8
                moveNext();
                return;
            case 0xcd:// uint16
                {
                    if (left() < 2)
                    {
                        fprintf(stderr, "discard uint16 failed\n");
                        return;
                    }
                    moveOffset(2);
                    return;
                }
            case 0xce:// uint32
                {
                    if (left() < 4)
                    {
                        fprintf(stderr, "discard uint failed\n");
                        return;
                    }
                    moveOffset(4);
                    return;
                }
            case 0xcf:// uint64
                {
                    if (left() < 8)
                    {
                        fprintf(stderr, "discard uint64 failed\n");
                        return;
                    }
                    moveOffset(8);
                    return;
                }
            case 0xd0:// int8
                {
                    if (left() < 1)
                    {
                        fprintf(stderr, "discard int8 failed\n");
                        return;
                    }
                    moveNext();
                    return;
                }
            case 0xd1:// int16
                {
                    if (left() < 2)
                    {
                        fprintf(stderr, "discard int16 failed\n");
                        return;
                    }
                    moveOffset(2);
                    return;
                }
            case 0xd2:// int32
                {
                    if (left() < 4)
                    {
                        fprintf(stderr, "discard int failed\n");
                        return;
                    }
                    moveOffset(4);
                    return;
                }
            case 0xd3:// int64
                {
                    if (left() < 8)
                    {
                        fprintf(stderr, "discard int64 failed\n");
                        return;
                    }
                    moveOffset(8);
                    return;
                }
            case 0xd9:// str8
                {
                    if (left() < 1)
                    {
                        fprintf(stderr, "discard str8 length failed\n");
                        return;
                    }
                    unsigned char slen = moveNext();
                    if (left() < slen)
                    {
                        fprintf(stderr, "discard str8 failed\n");
                        return;
                    }
                    moveOffset(slen);
                    return;
                }
            case 0xda:// str16
                {
                    unsigned short slen = 0;
                    if (left() < 2)
                    {
                        fprintf(stderr, "discard str16 length failed\n");
                        return;
                    }
                    slen = ntohs( *(short*)(offsetPtr()) );
                    moveOffset(2);
                    if (left() < slen)
                    {
                        fprintf(stderr, "discard str16 failed\n");
                        return;
                    }
                    moveOffset(slen);
                    return;
                }
            case 0xdb:// str32
                {
                    unsigned int slen = 0;
                    if (left() < 4)
                    {
                        fprintf(stderr, "discard str32 length failed\n");
                        return;
                    }
                    slen = ntohl( *(long*)(offsetPtr()) );
                    moveOffset(4);
                    if (left() < slen)
                    {
                        fprintf(stderr, "discard str32 failed\n");
                        return;
                    }
                    moveOffset((int)slen);
                    return;
                }

            case 0xca:// float
                {
                    if (left() < 4)
                    {
                        fprintf(stderr, "discard float failed\n");
                        return;
                    }
                    moveOffset(4);
                    return;
                }
            case 0xcb:// double
                {
                    if (left() < 8)
                    {
                        fprintf(stderr, "discard double failed\n");
                        return;
                    }
                    moveOffset(8);
                    return;
                }

            case 0xdc://  array16
                {
                    unsigned short slen = 0;
                    if (left() < 2)
                    {
                        fprintf(stderr, "discard array16 length failed\n");
                        return;
                    }
                    slen = ntohs( *(short*)(offsetPtr()) );
                    moveOffset(2);
                    unpack_discard(slen);
                    return;
                }
            case 0xdd:// array32
                {
                    unsigned int slen = 0;
                    if (left() < 4)
                    {
                        fprintf(stderr, "discard array32 length failed\n");
                        return;
                    }
                    slen = ntohl( *(long*)(offsetPtr()) );
                    moveOffset(4);
                    unpack_discard(slen);
                    return;
                }
            case 0xde:// map16
                {
                    unsigned short slen = 0;
                    if (left() < 2)
                    {
                        fprintf(stderr, "discard array16 length failed\n");
                        return;
                    }
                    slen = ntohs( *(short*)(offsetPtr()) );
                    moveOffset(2);
                    unpack_discard(slen * 2);
                    return;
                }
            case 0xdf:// map32
                {
                    unsigned int slen = 0;
                    if (left() < 4)
                    {
                        fprintf(stderr, "discard array32 length failed\n");
                        return;
                    }
                    slen = ntohl( *(long*)(offsetPtr()) );
                    moveOffset(4);
                    unpack_discard(slen * 2);
                    return;
                }

            case 0xc4:// bin8
                {
                    if (left() < 1)
                    {
                        fprintf(stderr, "discard bin8 length failed\n");
                        return;
                    }
                    unsigned char slen = moveNext();
                    if (left() < slen)
                    {
                        fprintf(stderr, "discard bin failed\n");
                        return;
                    }
                    moveOffset(slen);
                    return;
                }
            case 0xc5:// bin16
                {
                    unsigned short slen = 0;
                    if (left() < 2)
                    {
                        fprintf(stderr, "discard bin16 length failed\n");
                        return;
                    }
                    slen = ntohs( *(short*)(offsetPtr()) );
                    moveOffset(2);
                    if (left() < slen)
                    {
                        fprintf(stderr, "discard bin16 failed\n");
                        return;
                    }
                    moveOffset(slen);
                    break;
                }
            case 0xc6:// bin32
                {
                    unsigned int slen = 0;
                    if (left() < 4)
                    {
                        fprintf(stderr, "discard bin32 length failed\n");
                        return;
                    }
                    slen = ntohl( *(long*)(offsetPtr()) );
                    moveOffset(4);
                    if (left() < slen)
                    {
                        fprintf(stderr, "discard bin32 failed\n");
                        return;
                    }
                    moveOffset((int)slen);
                    break;
                }
            default:
                {
                    fprintf(stderr, "discard unknown type=0x%x\n", t);
                    break;
                }
        }
    }
};

class Proto
{
protected:
    std::atomic<int> m_referenceCount;
public:
    Proto() : m_referenceCount(0) {}
    virtual ~Proto(){}
	inline void release(void){
		if( std::atomic_fetch_sub_explicit(&m_referenceCount, 1, std::memory_order_relaxed) == 1 ){
			delete this;
		}
	}
	inline void retain(void){
		std::atomic_fetch_add_explicit(&m_referenceCount, 1, std::memory_order_relaxed);
	}
	inline int getRefCount(void){ return (int)m_referenceCount; }

    virtual void Encode(Writer& wb) { }
    virtual void Decode(Reader& rb) { }
    virtual Proto* Create() { return NULL; }
    virtual void Destroy() { }
};

};

#endif
