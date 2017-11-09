
#include "ep.h"

namespace ep{

#define SAFE_DELETE(ptr) if(ptr != NULL){ delete ptr; ptr = NULL; }
#define SAFE_DELETE_ARRAY(ptr) if(ptr != NULL){ delete [] ptr; ptr = NULL; }

#define EP_STATE     "ep.state"
#define ntohll(x) ( ( (uint64_t)(ntohl( (uint32_t)((x << 32) >> 32) )) << 32) | ntohl( ((uint32_t)(x >> 32)) ) )
#define htonll(x) ntohll(x)


static void ep_state_init(ProtoState *ps){
    ps->pWriteBuffer = new WriteBuffer();
    ps->pManager = new ProtoManager();
}
static void ep_state_free(ProtoState *ps){
    SAFE_DELETE(ps->pWriteBuffer);
    SAFE_DELETE(ps->pManager);
}
static int ep_state_delete(lua_State *L){
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
        lua_pushcfunction(L, ep_state_delete);
        lua_setfield(L, -2, "__gc");
        lua_setmetatable(L, -2);
        lua_setfield(L, LUA_REGISTRYINDEX, EP_STATE);
    }
    return ps;
}
static int ep_pack_api(lua_State *L){

    return 1;
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
