//
// Created by IntelliJ IDEA.
// User: AppleTree
// Date: 16/5/29
// Time: 上午9:08
// To change this template use File | Settings | File Templates.
//

#ifndef __hive__script__
#define __hive__script__

#include <string>

#include "lua.hpp"
#include "eproto.h"

class Script
{
public:
    Script(void);
    virtual ~Script(void);

	virtual void setState(lua_State* pState);
	inline lua_State * getState( void ) { return m_pState; }
	inline bool requireFile(const std::string& file){
		std::string exec = "require (\"" + file + "\")";
		return executeText(exec.c_str(), exec.length(), NULL);
	}
	inline bool executeFile( const char * script_file_path ){
		if( luaL_loadfile(m_pState, script_file_path ) == 0 ){
			if( lua_resume( m_pState, 0 ) == 0 ){
				return true;
			}
		}
		outputError();
		return false;
	}
	inline bool executeText( const char * script, const int script_length, const char * comment = NULL ){
		if( luaL_loadbuffer( m_pState, script, script_length, comment ) == 0 ){
			if( lua_pcall( m_pState, 0, 0, 0 ) == 0 ){
				return true;
			}
		}
		outputError();
		return false;
	}
    inline void luaCall( int parameter_number, int result_count = 0 ){
        if( lua_pcall( m_pState, parameter_number, result_count, 0 ) != 0 ){
            outputError();
        }
    }
	// 定制C++调用Lua的全局函数
	inline void clearStack(void){
		lua_settop(m_pState, 0);
	}
    inline void callFunction(const char * function_name, int result_count=0){
    	lua_settop(m_pState, 0);
        lua_getglobal(m_pState, function_name);
        luaCall(0, result_count);
    }

	inline void outputError(void){
		const char* msg = lua_tostring( m_pState, -1 );
		if( msg == NULL )
			msg = "(error without message)";
		fprintf(stderr, "%s\n", msg);
	}
protected:
	lua_State* m_pState;
};//end class Script

#endif
