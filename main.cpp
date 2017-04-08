//
//  main.cpp
//  test
//
//  Created by AppleTree on 17/2/26.
//  Copyright © 2017年 AppleTree. All rights reserved.
//

#include <iostream>
#include <chrono>
#include <thread>
#include <time.h>
#include "eproto.h"
#include "script.h"

inline int64 get_time_us(void){
	std::chrono::time_point<std::chrono::system_clock> p = std::chrono::system_clock::now();
	return (int64)std::chrono::duration_cast<std::chrono::microseconds>(p.time_since_epoch()).count();
}
inline int64 get_time_ms(void){
	std::chrono::time_point<std::chrono::system_clock> p = std::chrono::system_clock::now();
	return (int64)std::chrono::duration_cast<std::chrono::milliseconds>(p.time_since_epoch()).count();
}

int main(int argc, const char * argv[]) {
	// insert code here...
	std::cout << "Hello, World!\n";

	Script script;
	script.setState(NULL);

	fprintf(stderr, "start loading main.lua t=%lld", get_time_us());

	script.executeFile("main.lua");

	fprintf(stderr, "end loading main.lua t=%lld", get_time_us());

    return 0;
}
