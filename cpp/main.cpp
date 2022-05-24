
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
    int count = 10000;
    eproto::Writer wb;
    test::request* req = test::request::New();
    test::request* req2 = test::request::New();
    test::GameOver* req3 = test::GameOver::New();
    req->a = 100;
    req->b = 123456789;
    req->c = 3.1415F;
    req->d = 123456.789;
    req->e = "Hello";
    req->g_New();
    req->h[1] = "a";
    req->h[2] = "b";
    for(size_t i=0; i<1; ++i){
        test::request::inner* p = req->j_New();
        p->t1 = 77;
        p->t2 = "w";
    }
//    req->j.resize(1, NULL);
//    for (size_t i = 0; i < req->j.size(); ++i)
//    {
//        req->j[i] = test::request::inner::New();
//        req->j[i]->t1 = 77;
//        req->j[i]->t2 = "w";
//    }
    wb.clear();
    req->Encode(wb);
    fprintf(stderr, "encode size == %d\n", (int)wb.size());
    eproto::Reader rb(wb.data(), wb.size());
    req2->Decode(rb);
    fprintf(stderr, "decode d = %f\n", req2->d);

    int64 t1 = get_time_us();
	fprintf(stderr, "encode start t=%lld\n", t1);
    for(int i=0; i<count; ++i)
    {
        wb.clear();
        req->Encode(wb);
    }
    int64 t2 = get_time_us();
    double gap1 = (double)(t2-t1)/1000000;
	fprintf(stderr, "encode end t=%lld gap=%f count=%d\n", t2, gap1, count);

    int64 t3 = get_time_us();
	fprintf(stderr, "decode start t=%lld\n", t3);

    for(int i=0; i<count; ++i)
    {
        rb.resetBuffer(wb.data(), wb.size());
        req2->Decode(rb);
    }
    int64 t4 = get_time_us();
    double gap2 = (double)(t4-t3)/1000000;
	fprintf(stderr, "decode end t=%lld gap=%f count=%d\n", t4, gap2, count);

    req3->roomId = 123;
    req3->winMoney = -123423123;
    fprintf(stderr, "before encode winMoney=%lld roomId=%d\n", req3->winMoney, req3->roomId);
    wb.clear();
    req3->Encode(wb);
    rb.resetBuffer(wb.data(), wb.size());
    req3->Decode(rb);
    fprintf(stderr, "decode winMoney=%lld roomId=%d\n", req3->winMoney, req3->roomId);

    test::request::Delete(req);
    test::request::Delete(req2);
    test::GameOver::Delete(req3);
    return 0;
}