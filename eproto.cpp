
#include "eproto.h"
extern "C" {
#include "lua.h"
#include "lauxlib.h"
}

namespace eproto{

#if LUA_VERSION_NUM >= 503
# define lua53_getfield lua_getfield
//# define lua53_rawgeti  lua_rawgeti
#else
static int lua53_getfield(lua_State *L, int idx, const char *field)
{ lua_getfield(L, idx, field); return lua_type(L, -1); }
//static int lua53_rawgeti(lua_State *L, int idx, lua_Integer i)
//{ lua_rawgeti(L, idx, i); return lua_type(L, -1); }
#endif

#define SAFE_DELETE(ptr) if(ptr != NULL){ delete ptr; ptr = NULL; }
#define SAFE_DELETE_ARRAY(ptr) if(ptr != NULL){ delete [] ptr; ptr = NULL; }

#define EP_STATE     "eproto.state"
#define ntohll(x) ( ( (uint64_t)(ntohl( (uint32_t)((x << 32) >> 32) )) << 32) | ntohl( ((uint32_t)(x >> 32)) ) )
#define htonll(x) ntohll(x)

#define ERRORBIT_BUFNOLEFT 1
#define ERRORBIT_STRINGLEN 2
#define ERRORBIT_TYPE_LIGHTUSERDATA 4
#define ERRORBIT_TYPE_FUNCTION 8
#define ERRORBIT_TYPE_USERDATA 16
#define ERRORBIT_TYPE_THREAD 32
#define ERRORBIT_TYPE_UNKNOWN 64
#define ERRORBIT_TYPE_NO_PROTO 128
#define ERRORBIT_TYPE_WRONG_PROTO 256

//typedef void(*ep_unpack_function)(ReadBuffer* prb, lua_State *L, unsigned char t);
//ep_unpack_function g_unpack_function[256] = {0};

// lua pack 前置声明
static void ep_pack_anytype(WriteBuffer* pwb, lua_State *L, int index);
// lua pack 方法
inline void ep_rcopy( unsigned char *dest, unsigned char*from, size_t l ){
    size_t i;
    for(i=0;i<l;i++){
        dest[l-i-1]=from[i];
    }
}
inline void ep_pack_nil(WriteBuffer* pwb){
    pwb->push(0xc0);
}
inline void ep_pack_bool(WriteBuffer* pwb, bool b){
	if(b){
		pwb->push(0xc3);
	}else{
		pwb->push(0xc2);
	}
}
inline void ep_pack_int(WriteBuffer* pwb, long long lv){
	if(lv>=0){
	    if(lv<128){
	        pwb->push((char)lv);
	    } else if(lv<256){
	        unsigned char v = (char)lv;
	        pwb->add(0xcc, v);
	    } else if(lv<65536){
	        short v = htons((short)lv);
	        pwb->add(0xcd, (unsigned char*)&v, 2);
	    } else if(lv<4294967296LL){
	        long v = htonl((long)lv);
	        pwb->add(0xce, (unsigned char*)&v, 4);
	    } else {
	        long long v = htonll((long long)lv);
	        pwb->add(0xcf, (unsigned char*)&v, 8);
	    }
	} else {
	    if(lv >= -32){
	        unsigned char v = 0xe0 | (char)lv;
	        pwb->push(v);
	    } else if( lv >= -128 ){
	        unsigned char v = (unsigned char)lv;
	        pwb->add(0xd0, v);
	    } else if( lv >= -32768 ){
	        short v = htons(lv&0xffff);
	        pwb->add(0xd1, (unsigned char*)&v, 2);
	    } else if( lv >= -2147483648LL ){
	        int v = htonl(lv&0xffffffff);
	        pwb->add(0xd2, (unsigned char*)&v, 4);
	    } else{
	        long long v = htonll(lv);
	        pwb->add(0xd3, (unsigned char*)&v, 8);
	    }
	}
}
inline void ep_pack_float(WriteBuffer* pwb, lua_Number n){
	float f = (float)n;
	if((double)f == n){
		pwb->radd(0xca, (unsigned char*)&f, 4);
	}else{
		pwb->radd(0xcb, (unsigned char*)&n, 8);
	}
}
inline void ep_pack_string(WriteBuffer* pwb, const unsigned char *sval, size_t slen){
    unsigned char topbyte = 0;
    if(slen<32){
        topbyte = 0xa0 | (char)slen;
        pwb->add(topbyte, sval, slen);
    }else if(slen<256){
        topbyte = 0xd9;
        unsigned char l = slen;
        pwb->push(topbyte);
        pwb->push(l);
		pwb->write(sval, slen);
    } else if(slen<65536){
        topbyte = 0xda;
        unsigned short l = htons(slen);
        pwb->push(topbyte);
        pwb->write((unsigned char*)&l, 2);
		pwb->write(sval, slen);
    } else if(slen<4294967296LL-1){ // TODO: -1 for avoiding (condition is always true warning)
        topbyte = 0xdb;
        unsigned int l = htonl(slen);
        pwb->push(topbyte);
        pwb->write((unsigned char*)&l, 4);
        pwb->write(sval, slen);
    } else {
        pwb->setError(ERRORBIT_STRINGLEN);
    }
}
inline void ep_pack_number(WriteBuffer* pwb, lua_Number n){
//    if( isinf(n) ){
//        unsigned char buf[9];
//        buf[0] = 0xcb; // double
//        if(n>0){
//            buf[1] = 0x7f;
//            buf[2] = 0xf0;
//        } else {
//            buf[1] = 0xff;
//            buf[2] = 0xf0;
//        }
//        buf[3] = buf[4] = buf[5] = buf[6] = buf[7] = buf[8] = 0;
//        pwb->write(buf, 9);
//    } else if( isnan(n) ) {
//        unsigned char buf[9];
//        buf[0] = 0xcb;
//        buf[1] = 0xff;
//        buf[2] = 0xf8;
//        buf[3] = buf[4] = buf[5] = buf[6] = buf[7] = buf[8] = 0;
//        pwb->write(buf, 9);
//    } else
    if(floor(n)==n){
        long long lv = (long long)n;
        ep_pack_int(pwb, lv);
    } else { // floating point!
		ep_pack_float(pwb, n);
    }
}
// lua pack 静态方法，迭代
static void ep_pack_table(WriteBuffer* pwb, lua_State *L, int index){
    size_t nstack = lua_gettop(L);
    size_t l = lua_objlen(L,index);

    // try array first, and then map.
    if(l>0){
        unsigned char topbyte;
        // array!(ignore map part.) 0x90|n , 0xdc+2byte, 0xdd+4byte
        if(l<16){
            topbyte = 0x90 | (unsigned char)l;
            pwb->push(topbyte);
        } else if( l<65536){
            topbyte = 0xdc;
            unsigned short elemnum = htons(l);
            pwb->add(topbyte, (unsigned char*)&elemnum, 2);
        } else if( l<4294967296LL-1){ // TODO: avoid C warn
            topbyte = 0xdd;
            unsigned int elemnum = htonl(l);
            pwb->add(topbyte, (unsigned char*)&elemnum, 4);
        }
        int i;
        for(i=1;i<=(int)l;i++){
            lua_rawgeti(L, index, i); // push table value to stack
            ep_pack_anytype(pwb, L, nstack+1);
            lua_pop(L, 1); // repair stack
        }
    } else {
        // map!
        l=0;
        lua_pushnil(L);
        while(lua_next(L,index)){
            l++;
            lua_pop(L,1);
        }
        // map fixmap, 16,32 : 0x80|num, 0xde+2byte, 0xdf+4byte
        unsigned char topbyte=0;
        if(l<16){
            topbyte = 0x80 | (char)l;
            pwb->push(topbyte);
        }else if(l<65536){
            topbyte = 0xde;
            unsigned short elemnum = htons(l);
            pwb->add(topbyte, (unsigned char*)&elemnum, 2);
        }else if(l<4294967296LL-1){
            topbyte = 0xdf;
            unsigned int elemnum = htonl(l);
            pwb->add(topbyte, (unsigned char*)&elemnum, 4);
        }
        lua_pushnil(L); // nil for first iteration on lua_next
        while( lua_next(L,index)){
            ep_pack_anytype(pwb, L, nstack+1); // -2:key
            ep_pack_anytype(pwb, L, nstack+2); // -1:value
            lua_pop(L,1); // remove value and keep key for next iteration
        }
    }
}
static void ep_pack_anytype(WriteBuffer* pwb, lua_State *L, int index){
    int t = lua_type(L,index);
    switch(t){
    case LUA_TNUMBER:
        {
            lua_Number nv = lua_tonumber(L,index);
            ep_pack_number(pwb, nv);
            return;
        }
        break;
    case LUA_TSTRING:
        {
            size_t slen;
            const char *sval = lua_tolstring(L, index, &slen);
//            const char *sval = luaL_checklstring(L, index, &slen);
			ep_pack_string(pwb, (const unsigned char*)sval, slen);
            return;
        }
        break;
    case LUA_TNIL:
        ep_pack_nil(pwb);
		return;
    case LUA_TBOOLEAN:
        {
            int iv = lua_toboolean(L, index);
            ep_pack_bool(pwb, iv);
            return;
        }
    case LUA_TTABLE:
        ep_pack_table(pwb, L, index );
        return;
//    case LUA_TLIGHTUSERDATA:
//        pwb->setError(ERRORBIT_TYPE_LIGHTUSERDATA);
//        break;
//    case LUA_TFUNCTION:
//        pwb->setError(ERRORBIT_TYPE_FUNCTION);
//        break;
//    case LUA_TUSERDATA:
//        pwb->setError(ERRORBIT_TYPE_USERDATA);
//        break;
//    case LUA_TTHREAD:
//        pwb->setError(ERRORBIT_TYPE_THREAD);
//        break;
//    default:
//        pwb->setError(ERRORBIT_TYPE_UNKNOWN);
//        break;
	default:
		ep_pack_nil(pwb);
		break;
    }
}

// unpack前置声明
static void ep_unpack_anytype(ReadBuffer* prb, lua_State *L);
static void ep_unpack_map(ReadBuffer* prb, lua_State *L, int maplen);
static void ep_unpack_array(ReadBuffer* prb, lua_State *L, int maplen);
// unpack 方法
inline void ep_unpack_fixint(ReadBuffer* prb, lua_State *L, unsigned char t){
    lua_pushnumber(L,(lua_Number)t);
}
inline void ep_unpack_fixmap(ReadBuffer* prb, lua_State *L, unsigned char t){
    size_t maplen = t & 0xf;
    ep_unpack_map(prb, L, maplen);
}
inline void ep_unpack_fixarray(ReadBuffer* prb, lua_State *L, unsigned char t){
    size_t arylen = t & 0xf;
    ep_unpack_array(prb, L, arylen);
}
inline void ep_unpack_fixstr(ReadBuffer* prb, lua_State *L, unsigned char t){
    size_t slen = t & 0x1f;
    if( prb->left() < slen ){
        prb->setError(1);
        return;
    }
    lua_pushlstring(L,(const char*)prb->offsetPtr(),slen);
    prb->moveOffset(slen);
}
inline void ep_unpack_fixint_negative(ReadBuffer* prb, lua_State *L, unsigned char t){
    unsigned char ut = t;
    lua_Number n = ( 256 - ut ) * -1;
    lua_pushnumber(L,n);
}
inline void ep_unpack_nil(ReadBuffer* prb, lua_State *L, unsigned char t){
    lua_pushnil(L);
}
inline void ep_unpack_false(ReadBuffer* prb, lua_State *L, unsigned char t){
    lua_pushboolean(L,0);
}
inline void ep_unpack_true(ReadBuffer* prb, lua_State *L, unsigned char t){
    lua_pushboolean(L,1);
}
inline void ep_unpack_bin8(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 1){
        prb->setError(1);
        return;
    }
    size_t slen = prb->moveNext();
    if(prb->left() < slen){
        prb->setError(1);
        return;
    }
    lua_pushlstring(L, (const char*)prb->offsetPtr(), slen);
    prb->moveOffset(slen);
}
inline void ep_unpack_bin16(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 2){
        prb->setError(1);
        return;
    }
    size_t slen = ntohs(*((unsigned short*)(prb->offsetPtr())));
    prb->moveOffset(2);
    if(prb->left() < slen){
        prb->setError(1);
        return;
    }
    lua_pushlstring(L, (const char*)prb->offsetPtr(), slen);
    prb->moveOffset(slen);
}
inline void ep_unpack_bin32(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 4){
        prb->setError(1);
        return;
    }
    size_t slen = ntohl(*((unsigned int*)(prb->offsetPtr())));
    prb->moveOffset(4);
    if(prb->left() < slen){
        prb->setError(1);
        return;
    }
    lua_pushlstring(L, (const char*)prb->offsetPtr(), slen);
    prb->moveOffset(slen);
}
inline void ep_unpack_float(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 4){
        prb->setError(1);
        return;
    }
    float f;
    ep_rcopy( (unsigned char*)(&f), prb->offsetPtr(), 4); // endianness
    lua_pushnumber(L, f);
    prb->moveOffset(4);
}
inline void ep_unpack_double(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 8){
        prb->setError(1);
        return;
    }
    double v;
    ep_rcopy( (unsigned char*)(&v), prb->offsetPtr(), 8); // endianness
    lua_pushnumber(L, v);
    prb->moveOffset(8);
}
inline void ep_unpack_uint8(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 1){
        prb->setError(1);
        return;
    }
    unsigned char v = prb->moveNext();
    lua_pushnumber(L, v);
}
inline void ep_unpack_uint16(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 2){
        prb->setError(1);
        return;
    }
    unsigned short v = ntohs( *(short*)(prb->offsetPtr()) );
    lua_pushnumber(L, v);
    prb->moveOffset(2);
}
inline void ep_unpack_uint32(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 4){
        prb->setError(1);
        return;
    }
    unsigned long v = ntohl( *(long*)(prb->offsetPtr()) );
    lua_pushnumber(L,v);
    prb->moveOffset(4);
}
inline void ep_unpack_uint64(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 8){
        prb->setError(1);
        return;
    }
    long long v = *(long long*)(prb->offsetPtr());
    v = ntohll(v);
    lua_pushnumber(L, v);
    prb->moveOffset(8);
}
inline void ep_unpack_int8(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 1){
        prb->setError(1);
        return;
    }
    char v = (char)prb->moveNext();
    lua_pushnumber(L, v);
}
inline void ep_unpack_int16(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 2){
        prb->setError(1);
        return;
    }
    short v = ntohs( *(short*)(prb->offsetPtr()) );
    lua_pushnumber(L, v);
    prb->moveOffset(2);
}
inline void ep_unpack_int32(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 4){
        prb->setError(1);
        return;
    }
    long v = ntohl( *(long*)(prb->offsetPtr()) );
    lua_pushnumber(L,v);
    prb->moveOffset(4);
}
inline void ep_unpack_int64(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 8){
        prb->setError(1);
        return;
    }
    long long v = *(long long*)(prb->offsetPtr());
    v = ntohll(v);
    lua_pushnumber(L, v);
    prb->moveOffset(8);
}
inline void ep_unpack_str8(ReadBuffer* prb, lua_State *L, unsigned char t){
    ep_unpack_bin8(prb, L, t);
}
inline void ep_unpack_str16(ReadBuffer* prb, lua_State *L, unsigned char t){
    ep_unpack_bin16(prb, L, t);
}
inline void ep_unpack_str32(ReadBuffer* prb, lua_State *L, unsigned char t){
    ep_unpack_bin32(prb, L, t);
}
inline void ep_unpack_array16(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 2){
        prb->setError(1);
        return;
    }
    unsigned short arylen = ntohs( *((unsigned short*)(prb->offsetPtr()) ) );
    prb->moveOffset(2);
    ep_unpack_array(prb, L, arylen);
}
inline void ep_unpack_array32(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 4){
        prb->setError(1);
        return;
    }
    unsigned int arylen = ntohl( *((unsigned int*)(prb->offsetPtr())));
    prb->moveOffset(4);
    ep_unpack_array(prb, L, arylen);
}
inline void ep_unpack_map16(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 2){
        prb->setError(1);
        return;
    }
    unsigned short maplen = ntohs( *((unsigned short*)(prb->offsetPtr()) ) );
    prb->moveOffset(2);
    ep_unpack_map(prb, L, maplen);
}
inline void ep_unpack_map32(ReadBuffer* prb, lua_State *L, unsigned char t){
    if(prb->left() < 4){
        prb->setError(1);
        return;
    }
    unsigned int maplen = ntohl( *((unsigned int*)(prb->offsetPtr())));
    prb->moveOffset(4);
    ep_unpack_map(prb, L, maplen);
}
// 静态unpack方法
static void ep_unpack_array(ReadBuffer* prb, lua_State *L, int arylen) {
    lua_createtable(L, arylen, 0);
    int i;
    for(i=0;i<arylen;i++){
        ep_unpack_anytype(prb, L); // array element
        if(prb->getError()) break;
        lua_rawseti(L, -2, i+1);
    }
}
static void ep_unpack_map(ReadBuffer* prb, lua_State *L, int maplen) {
    lua_createtable(L, 0, maplen);
    int i;
    for(i=0;i<maplen;i++){
        ep_unpack_anytype(prb, L); // key
        ep_unpack_anytype(prb, L); // value
        lua_rawset(L,-3);
    }
}
static void ep_unpack_anytype(ReadBuffer* prb, lua_State *L){
    if( prb->left() < 1){
        prb->setError(1);
        return;
    }
    unsigned char t = prb->moveNext();
    if(t >= 0xc0 && t <=0xdf){
        switch(t){
        case 0xc0: ep_unpack_nil(prb, L, t); return;
        case 0xc2: ep_unpack_false(prb, L, t); return;
        case 0xc3: ep_unpack_true(prb, L, t); return;
        case 0xc4: ep_unpack_bin8(prb, L, t); return;
        case 0xc5: ep_unpack_bin16(prb, L, t); return;
        case 0xc6: ep_unpack_bin32(prb, L, t); return;
        case 0xca: ep_unpack_float(prb, L, t); return;
        case 0xcb: ep_unpack_double(prb, L, t); return;
        case 0xcc: ep_unpack_uint8(prb, L, t); return;
        case 0xcd: ep_unpack_uint16(prb, L, t); return;
        case 0xce: ep_unpack_uint32(prb, L, t); return;
        case 0xcf: ep_unpack_uint64(prb, L, t); return;
        case 0xd0: ep_unpack_int8(prb, L, t); return;
        case 0xd1: ep_unpack_int16(prb, L, t); return;
        case 0xd2: ep_unpack_int32(prb, L, t); return;
        case 0xd3: ep_unpack_int64(prb, L, t); return;
        case 0xd9: ep_unpack_str8(prb, L, t); return;
        case 0xda: ep_unpack_str16(prb, L, t); return;
        case 0xdb: ep_unpack_str32(prb, L, t); return;
        case 0xdc: ep_unpack_array16(prb, L, t); return;
        case 0xdd: ep_unpack_array32(prb, L, t); return;
        case 0xde: ep_unpack_map16(prb, L, t); return;
        case 0xdf: ep_unpack_map32(prb, L, t); return;
        default: prb->setError(1); break;
        }
        return;
    }
    if(t <= 0x7f){
        ep_unpack_fixint(prb, L, t);
        return;
    }
    if(t >= 0x80 && t <= 0x8f){
        ep_unpack_fixmap(prb, L, t);
        return;
    }
    if(t >= 0x90 && t <= 0x9f){
        ep_unpack_fixarray(prb, L, t);
        return;
    }
    if(t >= 0xa0 && t <= 0xbf){
        ep_unpack_fixstr(prb, L, t);
        return;
    }
    if(t >= 0xe0){
        ep_unpack_fixint_negative(prb, L, t);
        return;
    }
    prb->setError(1);
}

static void ep_state_init(ProtoState *ps){
    ps->pWriteBuffer = new WriteBuffer();
    ps->pManager = new ProtoManager();
}
static void ep_state_free(ProtoState *ps){
    SAFE_DELETE(ps->pWriteBuffer);
    SAFE_DELETE(ps->pManager);
}
static int delete_ep_state(lua_State *L){
    ProtoState *ps;
    if (lua53_getfield(L, LUA_REGISTRYINDEX, EP_STATE) != LUA_TUSERDATA)
        return 0;
    ps = (ProtoState*)lua_touserdata(L, -1);
    if (ps != NULL) {
        ep_state_free(ps);
        lua_pushnil(L);
        lua_setfield(L, LUA_REGISTRYINDEX, EP_STATE);
    }
    return 0;
}
static ProtoState* default_ep_state(lua_State *L){
    ProtoState *ps;
    if (lua53_getfield(L, LUA_REGISTRYINDEX, EP_STATE) == LUA_TUSERDATA) {
        ps = (ProtoState*)lua_touserdata(L, -1);
        lua_pop(L, 1);
    }
    else {
        ps = (ProtoState*)lua_newuserdata(L, sizeof(ProtoState));
        ep_state_init(ps);
        lua_createtable(L, 0, 1);
        lua_pushcfunction(L, delete_ep_state);
        lua_setfield(L, -2, "__gc");
        lua_setmetatable(L, -2);
        lua_setfield(L, LUA_REGISTRYINDEX, EP_STATE);
    }
    return ps;
}
static int ep_pack_api(lua_State *L){
	ProtoState* ps = default_ep_state(L);
	WriteBuffer* pws = ps->pWriteBuffer;
	pws->clear();
	ep_pack_anytype(pws, L, 1);
	if(pws->getError() == 0){
		lua_pushlstring(L, (const char*)(pws->data()), pws->size());
		return 1;
	}else{
		fprintf(stderr, "eproto pack error = %d\n", pws->getError());
	}
    return 0;
}
static int ep_unpack_api(lua_State *L){
    size_t len;
    const char * s = lua_tolstring(L, 1, &len);
//    const char * s = luaL_checklstring(L,1,&len);
    if(!s){
        lua_pushstring(L,"arg must be a string");
        lua_error(L);
        lua_pushnil(L);
        lua_replace(L,1);
        return 2;
    }
    if(len==0){
        lua_pushnil(L);
        lua_pushnil(L);
        lua_replace(L,1);
        return 2;
    }
    ReadBuffer rb((unsigned char*)s, len);
    ep_unpack_anytype(&rb, L);
    if(rb.err==0){
        lua_pushnumber(L, rb.offset);
        return 2;
    } else{
        lua_pushnil(L);
        lua_pushnil(L);
        lua_replace(L,1);
        return 2;
    }
}
static unsigned int ep_register_get_number(lua_State *L, int nstack, int index){
	lua_rawgeti(L, nstack, 1); // push table value to stack
	unsigned int v = (unsigned int)lua_tonumber(L, -1);
	lua_pop(L, 1); // repair stack
	return v;
}
static std::string ep_register_get_string(lua_State *L, int nstack, int index){
	lua_rawgeti(L, nstack, index); // push table value to stack
	std::string v = lua_tostring(L, -1);
	lua_pop(L, 1); // repair stack
	return v;
}
static bool ep_register_element(ProtoState* ps, lua_State *L, const std::string& path){
	int nstack = lua_gettop(L);
    size_t l = lua_objlen(L, nstack);
    if(l==4){
		// normal element
		unsigned int type = ep_register_get_number(L, nstack, 1);
		if(type < ep_type_nil || type >= ep_type_max){
			fprintf(stderr, "wrong element type = %d \n", type);
			return false;
		}
		unsigned int index = ep_register_get_number(L, nstack, 2);
		std::string name = ep_register_get_string(L, nstack, 3);
		lua_rawgeti(L, nstack, 4); // push table value to stack
		if(lua_type(L,-1) == LUA_TNUMBER){
			unsigned int value = (unsigned int)lua_tonumber(L, -1);
			ps->pManager->registerElement(path, type, index, name, value);
		}else{
			std::string valueName = lua_tostring(L, -1);
			ps->pManager->registerElement(path, type, index, name, valueName);
		}
		lua_pop(L, 1); // repair stack
    }else if(l==5){
		// map element
		unsigned int type = ep_register_get_number(L, nstack, 1);
		if(type != ep_type_map){
			fprintf(stderr, "5 param element but type != ep_type_map \n");
			return false;
		}
		unsigned int index = ep_register_get_number(L, nstack, 2);
		std::string name = ep_register_get_string(L, nstack, 3);
		unsigned int key = ep_register_get_number(L, nstack, 4);
		lua_rawgeti(L, nstack, 5); // push table value to stack
		if(lua_type(L,-1) == LUA_TNUMBER){
			unsigned int value = (unsigned int)lua_tonumber(L, -1);
			ps->pManager->registerElement(path, type, index, name, key, value);
		}else{
			std::string valueName = lua_tostring(L, -1);
			ps->pManager->registerElement(path, type, index, name, key, valueName);
		}
		lua_pop(L, 1); // repair stack
    }else{
        fprintf(stderr, "wrong element param number\n");
        return false;
    }
    return true;
}
static int ep_register_api(lua_State *L){
	ProtoState* ps = default_ep_state(L);
	lua_settop(L, 1);
	ep_unpack_api(L);
	lua_pop(L, 1); // pop unpack len
	int t = lua_type(L,1);
	if(t != LUA_TTABLE){
		lua_pushboolean(L, 0);
		return 1;
	}
	int nstack = lua_gettop(L);
    lua_pushnil(L); // nil for first iteration on lua_next
    while( lua_next(L, nstack) ){
		t = lua_type(L, nstack+2);
		if(t != LUA_TTABLE){
			lua_pushboolean(L, 0);
			return 1;
		}
		std::string path = lua_tostring(L, nstack+1);   // -2:key
		// register element
		if( !ep_register_element(ps, L, path) ){        // -1:value
			lua_pushboolean(L, 0);
			return 1;
		}
        lua_pop(L,1); // remove value and keep key for next iteration
    }
	lua_pushboolean(L, 1);
    return 1;
}
static int ep_register_file_api(lua_State *L){
	lua_settop(L, 1);
	const char* filepath = lua_tostring(L, 1);
	// read file data
	FILE* pFile = fopen(filepath, "rb");
	if(pFile == NULL){
		lua_pushboolean(L, 0);
		return 1;
	}
	fseek(pFile, 0, SEEK_END);
	long long len = ftell(pFile);
	char* buf = new char[len];
	fseek(pFile, 0, SEEK_SET);
	fread(buf, 1, len, pFile);

	lua_pushlstring(L, buf, len);
	lua_replace(L, 1);

	delete [] buf;
	fclose(pFile);
	// register buffer now
	return ep_register_api(L);
}
static int ep_proto_api(lua_State *L){

	return 1;
}
static int ep_encode_api(lua_State *L){

    return 1;
}
static int ep_decode_api(lua_State *L){

    return 1;
}
};  // end namespace eproto
using namespace eproto;

static const luaL_Reg eproto_f[] = {
    { "pack",           ep_pack_api },          // table        -> buffer
    { "unpack",         ep_unpack_api },        // buffer       -> table,len
    { "encode",         ep_encode_api },        // path,table   -> buffer
    { "decode",         ep_decode_api },        // path,buffer  -> table,len
    { "register",       ep_register_api },      // buffer       -> bool
    { "register_file",  ep_register_file_api }, // filepath     -> bool
    { "proto",          ep_proto_api },         // none         -> table
    {NULL,NULL}
};
LUALIB_API int luaopen_eproto(lua_State *L){
//    for(int i=0x00; i<=0x7f; ++i){
//        g_unpack_function[i] = ep_unpack_fixint;
//    }
//    for(int i=0x80; i<=0x8f; ++i){
//        g_unpack_function[i] = ep_unpack_fixmap;
//    }
//    for(int i=0x90; i<=0x9f; ++i){
//        g_unpack_function[i] = ep_unpack_fixarray;
//    }
//    for(int i=0xa0; i<=0xbf; ++i){
//        g_unpack_function[i] = ep_unpack_fixstr;
//    }
//    g_unpack_function[0xc0] = ep_unpack_nil;
//    g_unpack_function[0xc2] = ep_unpack_false;
//    g_unpack_function[0xc3] = ep_unpack_true;
//    g_unpack_function[0xc4] = ep_unpack_bin8;
//    g_unpack_function[0xc5] = ep_unpack_bin16;
//    g_unpack_function[0xc6] = ep_unpack_bin32;
//    g_unpack_function[0xca] = ep_unpack_float;
//    g_unpack_function[0xcb] = ep_unpack_double;
//    g_unpack_function[0xcc] = ep_unpack_uint8;
//    g_unpack_function[0xcd] = ep_unpack_uint16;
//    g_unpack_function[0xce] = ep_unpack_uint32;
//    g_unpack_function[0xcf] = ep_unpack_uint64;
//    g_unpack_function[0xd0] = ep_unpack_int8;
//    g_unpack_function[0xd1] = ep_unpack_int16;
//    g_unpack_function[0xd2] = ep_unpack_int32;
//    g_unpack_function[0xd3] = ep_unpack_int64;
//    g_unpack_function[0xd9] = ep_unpack_str8;
//    g_unpack_function[0xda] = ep_unpack_str16;
//    g_unpack_function[0xdb] = ep_unpack_str32;
//    g_unpack_function[0xdc] = ep_unpack_array16;
//    g_unpack_function[0xdd] = ep_unpack_array32;
//    g_unpack_function[0xde] = ep_unpack_map16;
//    g_unpack_function[0xdf] = ep_unpack_map32;
//    for(int i=0xe0; i<=0xff; ++i){
//        g_unpack_function[i] = ep_unpack_fixint_negative;
//    }

    luaL_openlib(L, "eproto", eproto_f, 0);
    return 1;
}
