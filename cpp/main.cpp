
#include <iostream>
#include <chrono>
#include <thread>
#include <time.h>

#include "eproto.hpp"

typedef long long int int64;

inline int64 get_time_ms(void){
	std::chrono::time_point<std::chrono::system_clock> p = std::chrono::system_clock::now();
	return (int64)std::chrono::duration_cast<std::chrono::milliseconds>(p.time_since_epoch()).count();
}

int main(int argc, const char * argv[]) {
	// insert code here...
	std::cout << "Hello, World!\n";

	fprintf(stderr, "start loading main.lua t=%lld\n", get_time_us());

	fprintf(stderr, "end loading main.lua t=%lld\n", get_time_us());

    return 0;
}