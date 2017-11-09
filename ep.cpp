
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

void ep_rcopy( unsigned char *dest, unsigned char*from, size_t l ){
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
}
inline void ep_pack_float(WriteBuffer* pwb, lua_Number n){
	float f = (float)n;
	if((double)f == n){
		pwb->radd(0xca, (unsigned char*)&f, sizeof(float));
	}else{
		pwb->radd(0xcb, (unsigned char*)&n, sizeof(double));
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
        ep_pack_int(pwb, lv);
    } else { // floating point!
		ep_pack_float(pwb, n);
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

static void ep_unpack_anytype(ReadBuffer* prb, lua_State *L);
static void ep_unpack_array(ReadBuffer* prb, lua_State *L, int arylen) {
    lua_createtable(L, arylen, 0);
    int i;
    for(i=0;i<arylen;i++){
        ep_unpack_anytype(prb, L); // array element
        if(b->err) break;
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
static void ep_unpack_anytype(ReadBuffer* prb, lua_State *L) {
    if( prb->left() < 1){
        prb->setError(1);
        return;
    }
    unsigned char t = prb->moveNext();

    if(t<0x80){ // fixed num
        lua_pushnumber(L,(lua_Number)t);
        return;
    }

    unsigned char *s = prb->offsetPtr();

    if(t>=0x80 && t <=0x8f){ // fixed map
        size_t maplen = t & 0xf;
        ep_unpack_map(prb, L, maplen);
        return;
    }
    if(t>=0x90 && t <=0x9f){ // fixed array
        size_t arylen = t & 0xf;
        ep_unpack_array(prb, L, arylen);
        return;
    }
    if(t>=0xa0 && t<=0xbf){ // fixed string
        size_t slen = t & 0x1f;
        if( prb->left() < slen ){
            b->err |= 1;
            return;
        }
        lua_pushlstring(L,(const char*)s,slen);
        prb->moveOffset(slen);
        return;
    }
    if(t>0xdf){ // fixnum_neg (-32 ~ -1)
        unsigned char ut = t;
        lua_Number n = ( 256 - ut ) * -1;
        lua_pushnumber(L,n);
        return;
    }

    switch(t){
    case 0xc0: // nil
        lua_pushnil(L);
        return;
    case 0xc2: // false
        lua_pushboolean(L,0);
        return;
    case 0xc3: // true
        lua_pushboolean(L,1);
        return;

    case 0xca: // float
        if(prb->left() >= 4){
            float f;
            ep_rcopy( (unsigned char*)(&f), s,4); // endianness
            lua_pushnumber(L,f);
            prb->moveOffset(4);
            return;
        }
        break;
    case 0xcb: // double
        if(prb->left() >= 8){
            double v;
            ep_rcopy( (unsigned char*)(&v), s,8); // endianness
            lua_pushnumber(L,v);
            prb->moveOffset(8);
            return;
        }
        break;

    case 0xcc: // 8bit large posi int
        if(prb->left() >= 1){
            lua_pushnumber(L,(unsigned char) s[0] );
            prb->moveOffset(1);
            return;
        }
        break;
    case 0xcd: // 16bit posi int
        if(prb->left() >= 2){
            unsigned short v = ntohs( *(short*)(s) );
            lua_pushnumber(L,v);
            prb->moveOffset(2);
            return;
        }
        break;
    case 0xce: // 32bit posi int
        if(prb->left()>=4){
            unsigned long v = ntohl( *(long*)(s) );
            lua_pushnumber(L,v);
            prb->moveOffset(4);
            return;
        }
        break;
    case 0xcf: // 64bit posi int
        if(prb->left()>=8){
            unsigned long long v = ntohll( *(long long*)(s));
            lua_pushnumber(L,v);
            prb->moveOffset(8);
            return;
        }
        break;
    case 0xd0: // 8bit neg int
        if(prb->left()>=1){
            lua_pushnumber(L, (signed char) s[0] );
            prb->moveOffset(1);
            return;
        }
        break;
    case 0xd1: // 16bit neg int
        if(prb->left()>=2){
            short v = *(short*)(s);
            v = ntohs(v);
            lua_pushnumber(L,v);
            prb->moveOffset(2);
            return;
        }
        break;
    case 0xd2: // 32bit neg int
        if(prb->left()>=4){
            int v = *(long*)(s);
            v = ntohl(v);
            lua_pushnumber(L,v);
            prb->moveOffset(4);
            return;
        }
        break;
    case 0xd3: // 64bit neg int
        if(prb->left()>=8){
            long long v = *(long long*)(s);
            v = ntohll(v);
            lua_pushnumber(L,v);
            prb->moveOffset(8);
            return;
        }
        break;
    case 0xda: // long string len<65536
        if(prb->left()>=2){
            size_t slen = ntohs(*((unsigned short*)(s)));
            prb->moveOffset(2);
            if(prb->left()>=slen){
                lua_pushlstring(L,(const char*)b->data+b->ofs,slen);
                prb->moveOffset(slen);
                return;
            }
        }
        break;
    case 0xdb: // longer string
        if(prb->left()>=4){
            size_t slen = ntohl(*((unsigned int*)(s)));
            prb->moveOffset(4);
            if(prb->left()>=slen){
                lua_pushlstring(L,(const char*)b->data+b->ofs,slen);
                prb->moveOffset(slen);
                return;
            }
        }

        break;

    case 0xdc: // ary16
        if(prb->left()>=2){
            unsigned short elemnum = ntohs( *((unsigned short*)(b->data+b->ofs) ) );
            prb->moveOffset(2);
            ep_unpack_array(b,L,elemnum);
            return;
        }
        break;
    case 0xdd: // ary32
        if(prb->left()>=4){
            unsigned int elemnum = ntohl( *((unsigned int*)(b->data+b->ofs)));
            prb->moveOffset(4);
            ep_unpack_array(b,L,elemnum);
            return;
        }
        break;
    case 0xde: // map16
        if(prb->left()>=2){
            unsigned short elemnum = ntohs( *((unsigned short*)(b->data+b->ofs)));
            prb->moveOffset(2);
            ep_unpack_map(b,L,elemnum);
            return;
        }
        break;
    case 0xdf: // map32
        if(prb->left()>=4){
            unsigned int elemnum = ntohl( *((unsigned int*)(b->data+b->ofs)));
            prb->moveOffset(4);
            ep_unpack_map(b,L,elemnum);
            return;
        }
        break;
    default:
        break;
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
    size_t len;
    const char * s = luaL_checklstring(L,1,&len);
    if(!s){
        lua_pushstring(L,"arg must be a string");
        lua_error(L);
        return 2;
    }
    if(len==0){
        lua_pushnil(L);
        return 1;
    }
    ReadBuffer rb;
    ep_unpack_anytype(&rb, L);
    if(rb.err==0){
        lua_pushnumber(L, rb.offset);
        return 2;
    } else{
        lua_pushnil(L);
        lua_pushnil(L);
        lua_replace(L,-2);
        return 2;
    }
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
