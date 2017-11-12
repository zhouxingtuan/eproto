#ifndef __eproto_h__
#define __eproto_h__

extern "C" {
#include "lua.h"
}

#include <math.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <arpa/inet.h>

#include <vector>
#include <string>
#include <unordered_map>

LUALIB_API int luaopen_eproto(lua_State *L);

namespace eproto{

typedef enum DataType
{
    ep_type_nil = 1,
    ep_type_bool,
    ep_type_float,
    ep_type_double,
    ep_type_int32,
    ep_type_int64,
    ep_type_uint32,
    ep_type_uint64,
    ep_type_string,
    ep_type_bytes,
    ep_type_array,
    ep_type_map,
    ep_type_message,
    ep_type_max,
}DataType;

typedef std::vector<unsigned char> UCharBuffer;
typedef struct WriteBuffer{
    UCharBuffer buffer;
    int err;
    WriteBuffer(void) : buffer(4096), err(0){ buffer.clear(); }
    inline unsigned char* data(void){ return (unsigned char*)buffer.data(); }
    inline unsigned int size(void) const { return buffer.size(); }
    inline void write(const unsigned char* ptr, unsigned int length){
//      unsigned int offset = buffer.size();
//		buffer.resize(offset + length);
//		memcpy(buffer.data() + offset, ptr, length);
		buffer.insert(buffer.end(), ptr, ptr + length);
    }
    inline void rwrite(const unsigned char* ptr, unsigned int length){
        for(int i=(int)length-1; i>=0; --i){
			buffer.push_back(ptr[i]);
        }
    }
    inline void push(unsigned char b){ buffer.push_back(b); }
    inline void add(unsigned char b, unsigned char v){
        push(b);
        push(v);
    }
    inline void add(unsigned char b, const unsigned char* ptr, unsigned int length){
        push(b);
        write(ptr, length);
    }
    inline void radd(unsigned char b, const unsigned char* ptr, unsigned int length){
        push(b);
        rwrite(ptr, length);
    }
    inline void clear(void){
        buffer.clear();
        err = 0;
    }
    inline void setError(int e){ err |= e; }
    inline int getError(void) const { return err; }
}WriteBuffer;

typedef struct ReadBuffer{
    unsigned char *ptr;
    unsigned int length;
    unsigned int offset;
    int err;
    ReadBuffer(void) : ptr(NULL), length(0), offset(0), err(0){}
    ReadBuffer(unsigned char *p, unsigned int len) : ptr(p), length(len), offset(0), err(0){}
    inline unsigned char* data(void){ return ptr; }
    inline void moveOffset(unsigned int length){ offset += length; }
    inline unsigned char moveNext(void){
        return ptr[offset++];
    }
    inline unsigned char* offsetPtr(void) { return ptr + offset; }
    inline bool isOffsetEnd(void) const { return offset >= length; }
    inline void clear(void){
        ptr = NULL;
        length = 0;
        offset = 0;
        err = 0;
    }
    inline void setError(int e){ err |= e; }
    inline int getError(void) const { return err; }
    inline unsigned int left(void) {
        if(offset > length){
            return 0;
        }
        return length - offset;
    }
}ReadBuffer;

typedef struct ProtoElement{
	unsigned int type : 8;
	unsigned int index : 24;
	union{
		// map数据结构
	    struct{
	        unsigned int key : 16;
	        unsigned int value : 16;
	    };
	    // 通用数据，message
        unsigned int id;
	};
	std::string name;
	ProtoElement(void) : type(0), index(0), id(0){}
	inline void set(unsigned int type, unsigned int index, const std::string& name, unsigned int id){
	    this->type = type;
	    this->index = index;
        this->id = id;
        this->name = name;
	}
	inline void set(unsigned int type, unsigned int index, const std::string& name, unsigned int key, unsigned int value){
	    this->type = type;
	    this->index = index;
        this->key = key;
        this->value = value;
        this->name = name;
	}
}ProtoElement;
typedef std::vector<ProtoElement> ProtoElementVector;
typedef std::vector<ProtoElementVector> ProtoVector;
typedef std::unordered_map<std::string, unsigned int> ProtoIndexMap;

class ProtoManager
{
public:
    ProtoVector m_protoVector;
    ProtoIndexMap m_indexMap;
public:
    ProtoManager(void){}
    ~ProtoManager(void){}

    inline ProtoElementVector* findProto(const std::string& path){
        ProtoIndexMap::iterator itCur = m_indexMap.find(path);
        if(itCur != m_indexMap.end()){
            return &(m_protoVector[itCur->second - ep_type_max]);
        }
        return NULL;
    }
    inline ProtoElementVector* findProto(unsigned int id){
        if(id < ep_type_max){
            return NULL;
        }
        id -= ep_type_max;
        if(id < m_protoVector.size()){
            return &(m_protoVector[id]);
        }
        return NULL;
    }
    inline unsigned int findProtoID(const std::string& path){
        ProtoIndexMap::iterator itCur = m_indexMap.find(path);
        if(itCur != m_indexMap.end()){
            return itCur->second;
        }
        return 0;
    }
    inline unsigned int registerProto(const std::string& path){
        unsigned int id = findProtoID(path);
        if(id == 0){
            id = m_protoVector.size() + ep_type_max;
            m_protoVector.push_back(ProtoElementVector());
            m_indexMap.insert(std::make_pair(path, id));
        }
        return id;
    }
    inline ProtoElement* setElement(unsigned int type, unsigned int index, const std::string& name, unsigned int id, ProtoElementVector* pVec){
        if(index == 0){
            return NULL;
        }
        ProtoElement* pe;
        if(index > (unsigned int)pVec->size()){
            pVec->resize(index);
        }
        pe = &((*pVec)[index-1]);
        pe->set(type, index, name, id);
        return pe;
    }
    inline ProtoElement* setElement(unsigned int type, unsigned int index, const std::string& name, unsigned int key, unsigned int value, ProtoElementVector* pVec){
        if(index == 0){
            return NULL;
        }
        ProtoElement* pe;
        if(index > (unsigned int)pVec->size()){
            pVec->resize(index);
        }
        pe = &((*pVec)[index-1]);
        pe->set(type, index, name, key, value);
        return pe;
    }
    // 数据类型是 message
    inline void registerElement(const std::string& path, unsigned int type, unsigned int index, const std::string& name, const std::string& valueName){
		unsigned int valueID = registerProto(valueName);
		registerElement(path, type, index, name, valueID);
    }
    // 数据类型是 常用数据类型
    inline void registerElement(const std::string& path, unsigned int type, unsigned int index, const std::string& name, unsigned int valueID){
        unsigned int protoID = registerProto(path);
        ProtoElementVector* pVec = findProto(protoID);
        setElement(type, index, name, valueID, pVec);
    }
    // 注册map时使用，key为常用数据类型，value为message数据类型
    inline void registerElement(const std::string& path, unsigned int type, unsigned int index, const std::string& name, unsigned int key, const std::string& valueName){
        unsigned int valueID = registerProto(valueName);
        registerElement(path, type, index, name, key, valueID);
    }
    // 注册map时使用，key，value都是常用数据类型
    inline void registerElement(const std::string& path, unsigned int type, unsigned int index, const std::string& name, unsigned int key, unsigned int value){
        unsigned int protoID = registerProto(path);
        ProtoElementVector* pVec = findProto(protoID);
        setElement(type, index, name, key, value, pVec);
    }
};

typedef struct ProtoState{
    WriteBuffer* pWriteBuffer;
    ProtoManager* pManager;
}ProtoState;

}; // end namespace ep

#endif