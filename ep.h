#ifndef __ep_h__
#define __ep_h__

extern "C" {
#include "lua.h"
}

#include <math.h>
#include <string.h>
#include <assert.h>
#include <arpa/inet.h>

#include <vector>
#include <string>
#include <unordered_map>

LUALIB_API int luaopen_eproto(lua_State *L);

namespace ep{

typedef enum DataType
{
    ep_type_nil = 0,
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
}DataType;

typedef std::vector<char> CharBuffer;
typedef struct WriteBuffer{
    CharBuffer buffer;
    int err;
    WriteBuffer(void) : buffer(4096), err(0){}
    inline char* data(void){ return buffer.data(); }
}WriteBuffer;

typedef struct ReadBuffer{
    unsigned char *ptr;
    unsigned int length;
    unsigned int offset;
    int err;
    ReadBuffer(void) : ptr(NULL), length(0), offset(0), err(0){}
    inline unsigned char* data(void){ return ptr; }
}ReadBuffer;

typedef struct ProtoElement{
	unsigned int type : 8;
	unsigned int index : 24;
	unsigned int id;
	std::string name;
	ProtoElement(void) : type(0), index(0), id(0){}
	inline void set(unsigned int type, unsigned int index, unsigned int id, const std::string& name){
	    this->type = type;
	    this->index = index;
        this->id = id;
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
    ProtoManager(void){ m_protoVector.resize(1); }
    ~ProtoManager(void){}

    ProtoElementVector* findProto(const std::string& path){
        ProtoIndexMap::iterator itCur = m_indexMap.find(path);
        if(itCur != m_indexMap.end()){
            return &(m_protoVector[itCur->second]);
        }
        return NULL;
    }
    ProtoElementVector* findProto(unsigned int id){
        if(id < m_protoVector.size()){
            return &(m_protoVector[id]);
        }
        return NULL;
    }
    unsigned int findProtoID(const std::string& path){
        ProtoIndexMap::iterator itCur = m_indexMap.find(path);
        if(itCur != m_indexMap.end()){
            return itCur->second;
        }
        return 0;
    }
    unsigned int registerProto(const std::string& path){
        unsigned int id = findProtoID(path);
        if(id == 0){
            id = m_protoVector.size();
            m_protoVector.push_back(ProtoElementVector());
            m_indexMap.insert(std::make_pair(path, id));
        }
        return id;
    }
    ProtoElement* setElement(unsigned int type, unsigned int index, unsigned int id, const std::string& name, ProtoElementVector* pVec){
        ProtoElement* pe;
        if(index >= (int)pVec->size()){
            pVec->resize(index + 1);
        }
        pe = &((*pVec)[index]);
        pe->set(type, index, id, name);
        return pe;
    }
};

typedef struct ProtoState{
    WriteBuffer* pWriteBuffer;
    ProtoManager* pManager;
}ProtoState;

}; // end namespace ep

#endif