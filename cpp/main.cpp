
#include <iostream>
#include <chrono>
#include <thread>
#include <time.h>

#include "eproto.hpp"
#include "test.hpp"

typedef long long int int64;

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
    int count = 1000000;
    eproto::Writer wb;
    test::request* req = test::request::New();
    test::request* req2 = test::request::New();
    req->a = 100;
    req->b = 123456789;
    req->c = 3.1415F;
    req->d = 123456.789;
    req->e = "Hello";
    req->g = test::request::inner::New();
    req->h[1] = "a";
    req->h[2] = "b";
    //req->i = new int[10];
    req->j.resize(1);
    for (size_t i = 0; i < req->j.size(); ++i)
    {
        req->j[i] = test::request::inner::New();
        req->j[i]->t1 = 77;
        req->j[i]->t2 = "w";
    }
    wb.clear();
    req->Encode(wb);
    std::cout << wb.size() << std::endl;
	fprintf(stderr, "start  t=%lld\n", get_time_us());



	fprintf(stderr, "end    t=%lld\n", get_time_us());

    return 0;
}