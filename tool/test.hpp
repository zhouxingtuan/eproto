#ifndef __test_hpp__
#define __test_hpp__

#include "eproto.hpp"

namespace test
{
    class GameOver : public eproto::Proto
    {
    public:
        int roomId;
        long long winMoney;
        GameOver() : eproto::Proto(), roomId(0), winMoney(0) {}
        virtual ~GameOver(){ Clear(); }
        virtual void Clear()
        {
            this->roomId = 0;
            this->winMoney = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(2);
            wb.pack_int(this->roomId);
            wb.pack_int(this->winMoney);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->roomId);
            if (--c <= 0) { return; }
            rb.unpack_int(this->winMoney);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return GameOver::New(); }
        virtual void Destroy() { GameOver::Delete(this); }
        static GameOver* New() { GameOver* p = new GameOver(); p->retain(); return p; }
        static void Delete(GameOver* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "test::GameOver"; }
    };
    class empty : public eproto::Proto
    {
    public:
        empty() : eproto::Proto() {}
        virtual ~empty(){ Clear(); }
        virtual void Clear()
        {
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(0);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return empty::New(); }
        virtual void Destroy() { empty::Delete(this); }
        static empty* New() { empty* p = new empty(); p->retain(); return p; }
        static void Delete(empty* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "test::empty"; }
    };
    class request : public eproto::Proto
    {
    public:
        class inner : public eproto::Proto
        {
        public:
            int t1;
            std::string t2;
            inner() : eproto::Proto(), t1(0) {}
            virtual ~inner(){ Clear(); }
            virtual void Clear()
            {
                this->t1 = 0;
                this->t2 = "";
            }
            virtual void Encode(eproto::Writer& wb)
            {
                wb.pack_array(2);
                wb.pack_int(this->t1);
                wb.pack_string(this->t2);
            }
            virtual void Decode(eproto::Reader& rb)
            {
                long long c = rb.unpack_array();
                if (c <= 0) { return; }
                rb.unpack_int(this->t1);
                if (--c <= 0) { return; }
                rb.unpack_string(this->t2);
                if (--c <= 0) { return; }
                rb.unpack_discard(c);
            }
            virtual eproto::Proto* Create() { return inner::New(); }
            virtual void Destroy() { inner::Delete(this); }
            static inner* New() { inner* p = new inner(); p->retain(); return p; }
            static void Delete(inner* p) { if(NULL != p){ p->release(); } }
            virtual std::string ClassName() { return "test::request::inner"; }
        };
        int a;
        long long b;
        float c;
        double d;
        std::string e;
        std::vector<char> f;
        inner* g;
        std::unordered_map<int, std::string> h;
        std::vector<int> i;
        std::vector<inner*> j;
        std::unordered_map<std::string, inner*> k;
        std::unordered_map<std::string, std::vector<char>> l;
        request() : eproto::Proto(), a(0), b(0), c(0), d(0), g(NULL) {}
        virtual ~request(){ Clear(); }
        void f_Append(void* p, size_t len){ int offset=(int)this->f.size(); this->f.resize(offset+len); memcpy(this->f.data()+offset, (char*)p, len); }
        inner* g_New(){ inner::Delete(this->g); this->g = inner::New(); return this->g; }
        void g_Set(inner* p){ if(NULL!=p){p->retain();} inner::Delete(this->g); this->g = p; }
        void j_Add(inner* p){ if(NULL!=p){p->retain();} this->j.push_back(p); }
        inner* j_New(){ inner* p = inner::New(); this->j.push_back(p); return p; }
        void k_Add(const std::string& k, inner* v){ if(NULL!=v){v->retain();} auto it = this->k.find(k); if(it!=this->k.end()){ inner::Delete(it->second); it->second = v; }else{ this->k.insert(std::make_pair(k, v)); } }
        inner* k_New(const std::string& k){ inner* v = inner::New(); auto it = this->k.find(k); if(it!=this->k.end()){ inner::Delete(it->second); it->second = v; }else{ this->k.insert(std::make_pair(k, v)); } return v; }
        virtual void Clear()
        {
            this->a = 0;
            this->b = 0;
            this->c = 0;
            this->d = 0;
            this->e = "";
            this->f.clear();
            if(NULL!=this->g){ inner::Delete(this->g); this->g=NULL; }
            this->h.clear();
            this->i.clear();
            {
                for(size_t i=0; i<this->j.size(); ++i)
                {
                    inner* v = this->j[i];
                    inner::Delete(v);
                }
                this->j.clear();
            }
            {
                for(auto &i : this->k)
                {
                    inner::Delete(i.second);
                }
                this->k.clear();
            }
            this->l.clear();
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(12);
            wb.pack_int(this->a);
            wb.pack_int(this->b);
            wb.pack_double(this->c);
            wb.pack_double(this->d);
            wb.pack_string(this->e);
            wb.pack_bytes(this->f);
            if (this->g == NULL) { wb.pack_nil(); } else { this->g->Encode(wb); }
            {
                wb.pack_map(this->h.size());
                for(auto &i : this->h)
                {
                    wb.pack_int(i.first);
                    wb.pack_string(i.second);
                }
            }
            {
                wb.pack_array(this->i.size());
                for(size_t i=0; i<this->i.size(); ++i)
                {
                    int v = this->i[i];
                    wb.pack_int(v);
                }
            }
            {
                wb.pack_array(this->j.size());
                for(size_t i=0; i<this->j.size(); ++i)
                {
                    inner* v = this->j[i];
                    if (v == NULL) { wb.pack_nil(); } else { v->Encode(wb); }
                }
            }
            {
                wb.pack_map(this->k.size());
                for(auto &i : this->k)
                {
                    wb.pack_string(i.first);
                    if (i.second == NULL) { wb.pack_nil(); } else { i.second->Encode(wb); }
                }
            }
            {
                wb.pack_map(this->l.size());
                for(auto &i : this->l)
                {
                    wb.pack_string(i.first);
                    wb.pack_bytes(i.second);
                }
            }
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->a);
            if (--c <= 0) { return; }
            rb.unpack_int(this->b);
            if (--c <= 0) { return; }
            rb.unpack_double(this->c);
            if (--c <= 0) { return; }
            rb.unpack_double(this->d);
            if (--c <= 0) { return; }
            rb.unpack_string(this->e);
            if (--c <= 0) { return; }
            rb.unpack_bytes(this->f);
            if (--c <= 0) { return; }
            if (rb.nextIsNil()) { rb.moveNext(); } else { inner::Delete(this->g); this->g = inner::New(); this->g->Decode(rb); }
            if (--c <= 0) { return; }
            {
                long long n = rb.unpack_map();
                if (n > 0) {
                    for(long long i=0; i<n; ++i)
                    {
                        int k=0;
                        rb.unpack_int(k);
                        std::string v;
                        rb.unpack_string(v);
                        this->h[k] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long long n = rb.unpack_array();
                if (n > 0) {
                    this->i.resize(n);
                    for(long long i=0; i<n; ++i)
                    {
                        int v=0;
                        rb.unpack_int(v);
                        this->i[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long long n = rb.unpack_array();
                if (n > 0) {
                    this->j.resize(n);
                    for(long long i=0; i<n; ++i)
                    {
                        inner* v=NULL;
                        if (rb.nextIsNil()) { rb.moveNext(); } else { inner::Delete(v); v = inner::New(); v->Decode(rb); }
                        this->j[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long long n = rb.unpack_map();
                if (n > 0) {
                    for(long long i=0; i<n; ++i)
                    {
                        std::string k;
                        rb.unpack_string(k);
                        inner* v=NULL;
                        if (rb.nextIsNil()) { rb.moveNext(); } else { inner::Delete(v); v = inner::New(); v->Decode(rb); }
                        this->k[k] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long long n = rb.unpack_map();
                if (n > 0) {
                    for(long long i=0; i<n; ++i)
                    {
                        std::string k;
                        rb.unpack_string(k);
                        std::vector<char> v;
                        rb.unpack_bytes(v);
                        this->l[k] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return request::New(); }
        virtual void Destroy() { request::Delete(this); }
        static request* New() { request* p = new request(); p->retain(); return p; }
        static void Delete(request* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "test::request"; }
    };
    class response : public eproto::Proto
    {
    public:
        int error;
        std::vector<char> buffer;
        response() : eproto::Proto(), error(0) {}
        virtual ~response(){ Clear(); }
        void buffer_Append(void* p, size_t len){ int offset=(int)this->buffer.size(); this->buffer.resize(offset+len); memcpy(this->buffer.data()+offset, (char*)p, len); }
        virtual void Clear()
        {
            this->error = 0;
            this->buffer.clear();
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(2);
            wb.pack_int(this->error);
            wb.pack_bytes(this->buffer);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->error);
            if (--c <= 0) { return; }
            rb.unpack_bytes(this->buffer);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return response::New(); }
        virtual void Destroy() { response::Delete(this); }
        static response* New() { response* p = new response(); p->retain(); return p; }
        static void Delete(response* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "test::response"; }
    };

};


#endif
