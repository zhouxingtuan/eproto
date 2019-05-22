#include "eproto.hpp"

namespace test
{
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
            void Clear()
            {
            }
            virtual void Encode(eproto::Writer& wb)
            {
                wb.pack_array(2);
                wb.pack_int(this->t1);
                wb.pack_string(this->t2);
            }
            virtual void Decode(eproto::Reader& rb)
            {
                Clear();
                long long int c = rb.unpack_array();
                if (c <= 0) { return; }
                rb.unpack_int(this->t1);
                if (--c <= 0) { return; }
                rb.unpack_string(this->t2);
                if (--c <= 0) { return; }
                rb.unpack_discard(c);
            }
            virtual eproto::Proto* Create() { return new inner(); }
            static inner* New() { return new inner(); }
            static void Delete(inner* p) { if(NULL != p){ delete p; }; }
        };
        int a;
        long long int b;
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
        void Clear()
        {
            if(NULL!=this->g){ inner::Delete(this->g); this->g=NULL; }
            {
                for(size_t i=0; i<this->j.size(); ++i)
                {
                    inner* v = this->j[i];
                    if(NULL!=v){ inner::Delete(v); }
                }
                this->j.clear();
            }
            {
                for(auto &i : this->k)
                {
                    if(NULL!=i.second){ inner::Delete(i.second); }
                }
                this->k.clear();
            }
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
            Clear();
            long long int c = rb.unpack_array();
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
            if (rb.NextIsNil()) { rb.MoveNext(); } else { this->g = inner::New(); this->g->Decode(rb); }
            if (--c <= 0) { return; }
            {
                long long int n = rb.unpack_map();
                if (n > 0) {
                    this->h->clear();
                    for(long long int i=0; i<n; ++i)
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
                long long int n = rb.unpack_array();
                if (n > 0) {
                    this->i->resize(n);
                    for(long long int i=0; i<n; ++i)
                    {
                        int v=0;
                        rb.unpack_int(v);
                        this->i[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long long int n = rb.unpack_array();
                if (n > 0) {
                    this->j->resize(n);
                    for(long long int i=0; i<n; ++i)
                    {
                        inner* v=NULL;
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { v = inner::New(); v->Decode(rb); }
                        this->j[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long long int n = rb.unpack_map();
                if (n > 0) {
                    this->k->clear();
                    for(long long int i=0; i<n; ++i)
                    {
                        std::string k;
                        rb.unpack_string(k);
                        inner* v=NULL;
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { v = inner::New(); v->Decode(rb); }
                        if (k != NULL) { this->k[k] = v; }
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long long int n = rb.unpack_map();
                if (n > 0) {
                    this->l->clear();
                    for(long long int i=0; i<n; ++i)
                    {
                        std::string k;
                        rb.unpack_string(k);
                        std::vector<char> v;
                        rb.unpack_bytes(v);
                        if (k != NULL) { this->l[k] = v; }
                    }
                }
            }
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return new request(); }
        static request* New() { return new request(); }
        static void Delete(request* p) { if(NULL != p){ delete p; }; }
    };
    class empty : public eproto::Proto
    {
    public:
        empty() : eproto::Proto() {}
        virtual ~empty(){ Clear(); }
        void Clear()
        {
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(0);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            Clear();
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return new empty(); }
        static empty* New() { return new empty(); }
        static void Delete(empty* p) { if(NULL != p){ delete p; }; }
    };
    class response : public eproto::Proto
    {
    public:
        int error;
        std::vector<char> buffer;
        response() : eproto::Proto(), error(0) {}
        virtual ~response(){ Clear(); }
        void Clear()
        {
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(2);
            wb.pack_int(this->error);
            wb.pack_bytes(this->buffer);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            Clear();
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->error);
            if (--c <= 0) { return; }
            rb.unpack_bytes(this->buffer);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return new response(); }
        static response* New() { return new response(); }
        static void Delete(response* p) { if(NULL != p){ delete p; }; }
    };

};
