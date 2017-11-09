
#include "ep.h"

namespace ep{

#define SAFE_DELETE(ptr) if(ptr != NULL){ delete ptr; ptr = NULL; }
#define SAFE_DELETE_ARRAY(ptr) if(ptr != NULL){ delete [] ptr; ptr = NULL; }

#define EP_STATE     "ep.state"
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
static void ep_pack_number(WriteBuffer* pwb, lua_Number n){
    if( isinf(n) ){
        unsigned char buf[9];
        buf[0] = 0xcb; // double
        if(n>0){
            buf[1] = 0x7f;
            buf[2] = 0xf0;
        } else {
            buf[1] = 0xff;
            buf[2] = 0xf0;
        }
        buf[3] = buf[4] = buf[5] = buf[6] = buf[7] = buf[8] = 0;
        pwb->write(buf, 9);
    } else if( isnan(n) ) {
        unsigned char buf[9];
        buf[0] = 0xcb;
        buf[1] = 0xff;
        buf[2] = 0xf8;
        buf[3] = buf[4] = buf[5] = buf[6] = buf[7] = buf[8] = 0;
        pwb->write(buf, 9);
    } else if(floor(n)==n){
        long long lv = (long long)n;
        if(lv>=0){
            if(lv<128){
                pwb->push((unsigned char)lv);
            } else if(lv<256){
                unsigned char v = (char)lv;
                pwb->add(0xcc, v);
            } else if(lv<65536){
                short v = htons((short)lv);
                pwb->add(0xcd, (unsigned char*)&v, sizeof(v));
            } else if(lv<4294967296LL){
                long v = htonl((long)lv);
                pwb->add(0xce, (unsigned char*)&v, sizeof(v));
            } else {
                long long v = htonll((long long)lv);
                pwb->add(0xcf, (unsigned char*)&v, sizeof(v));
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
                pwb->add(0xd1, (unsigned char*)&v, sizeof(v));
            } else if( lv >= -2147483648LL ){
                int v = htonl(lv&0xffffffff);
                pwb->add(0xd2, (unsigned char*)&v, sizeof(v));
            } else{
                long long v = htonll(lv);
                pwb->add(0xd3, (unsigned char*)&v, sizeof(v));
            }
        }
    } else { // floating point!
		float f = (float)n;
		if((double)f == n){
			pwb->radd(0xca, (unsigned char*)&f, sizeof(float));
		}else{
			pwb->radd(0xcb, (unsigned char*)&n, sizeof(double));
		}
    }
}
static void ep_pack_string(WriteBuffer* pwb, const unsigned char *sval, size_t slen){
    unsigned char topbyte = 0;
    if(slen<32){
        topbyte = 0xa0 | (char)slen;
        pwb->add(topbyte, sval, slen);
    } else if(slen<65536){
        topbyte = 0xda;
        unsigned short l = htons(slen);
        pwb->push(topbyte);
        pwb->write((unsigned char*)&l, sizeof(l));
		pwb->write(sval, slen);
    } else if(slen<4294967296LL-1){ // TODO: -1 for avoiding (condition is always true warning)
        topbyte = 0xdb;
        unsigned int l = htonl(slen);
        pwb->push(topbyte);
        pwb->write((unsigned char*)&l, sizeof(l));
        pwb->write(sval, slen);
    } else {
        pwb->setError(ERRORBIT_STRINGLEN);
    }
}
static void ep_pack_anytype(WriteBuffer* pwb, lua_State *L, int index);
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
            pwb->add(topbyte, (unsigned char*)&elemnum, sizeof(elemnum));
        } else if( l<4294967296LL-1){ // TODO: avoid C warn
            topbyte = 0xdd;
            unsigned int elemnum = htonl(l);
            pwb->add(topbyte, (unsigned char*)&elemnum, sizeof(elemnum));
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
            pwb->add(topbyte, (unsigned char*)&elemnum, sizeof(elemnum));
        }else if(l<4294967296LL-1){
            topbyte = 0xdf;
            unsigned int elemnum = htonl(l);
            pwb->add(topbyte, (unsigned char*)&elemnum, sizeof(elemnum));
        }
        lua_pushnil(L); // nil for first iteration on lua_next
        while( lua_next(L,index)){
            ep_pack_anytype(b,L,nstack+1); // -2:key
            ep_pack_anytype(b,L,nstack+2); // -1:value
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
        ep_pack_nil(pwd);
		return
    case LUA_TBOOLEAN:
        {
            int iv = lua_toboolean(L, index);
            ep_pack_bool(pwb, iv);
            return;
        }
    case LUA_TTABLE:
        ep_pack_table(pwd, L, index );
        return;
//    case LUA_TLIGHTUSERDATA:
//        pwd->setError(ERRORBIT_TYPE_LIGHTUSERDATA);
//        break;
//    case LUA_TFUNCTION:
//        pwd->setError(ERRORBIT_TYPE_FUNCTION);
//        break;
//    case LUA_TUSERDATA:
//        pwd->setError(ERRORBIT_TYPE_USERDATA);
//        break;
//    case LUA_TTHREAD:
//        pwd->setError(ERRORBIT_TYPE_THREAD);
//        break;
//    default:
//        pwd->setError(ERRORBIT_TYPE_UNKNOWN);
//        break;
	default:
		ep_pack_nil(pwb);
		break;
    }
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
    if (lua53_getfield(L, LUA_REGISTRYINDEX, PB_STATE) != LUA_TUSERDATA)
        return 0;
    ps = (ProtoState*)lua_touserdata(L, -1);
    if (ps != NULL) {
        ep_state_free(ps);
        lua_pushnil(L);
        lua_setfield(L, LUA_REGISTRYINDEX, EP_STATE);
    }
    return 0;
}
static ProtoState *default_ep_state(lua_State *L){
    ProtoState *ps;
    if (lua_getfield(L, LUA_REGISTRYINDEX, EP_STATE) == LUA_TUSERDATA) {
        ps = (ProtoState*)lua_touserdata(L, -1);
        lua_pop(L, 1);
    }
    else {
        ps = lua_newuserdata(L, sizeof(ProtoState));
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

    return 1;
}
static int ep_register_api(lua_State *L){

    return 1;
}
static int ep_encode_api(lua_State *L){

    return 1;
}
static int ep_decode_api(lua_State *L){

    return 1;
}
};  // end namespace ep
using namespace ep;

static const luaL_reg ep_f[] = {
    { "pack",           ep_pack_api },
    { "unpack",         ep_unpack_api },
    { "register",       ep_register_api },
    { "encode",         ep_encode_api },
    { "decode",         ep_decode_api },
    {NULL,NULL}
};
LUALIB_API int luaopen_eproto(lua_State *L){
    luaL_openlib(L, "eproto", ep_f, 0);
    return 1;
}
