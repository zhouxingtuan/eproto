#include "eproto.hpp"

namespace test
{
    class request : public Proto
    {
    public:
        class inner : public Proto
        {
        public:
            int t1;
            std::string t2;
            virtual void Encode(Writer& wb)
            {
                wb.pack_array(wb, 2);
                wb.pack_int(this->t1);
                wb.pack_int(this->t2);
            }
            virtual void Decode(Reader& rb)
            {
                long c = rb.unpack_array();
                if (c <= 0) { return; }
                rb.unpack_int(ref this->t1);
                if (--c <= 0) { return; }
                rb.unpack_int(ref this->t2);
                if (--c <= 0) { return; }
                rb.unpack_discard(c);
            }
            virtual Proto* Create() { return new inner(); }
        }
        int a;
        long long int b;
        float c;
        double d;
        std::string e;
        std::vector<char> f;
        inner g;
        std::unordered_map<int, std::string> h;
        std::vector<int> i;
        std::vector<inner> j;
        std::unordered_map<std::string, inner> k;
        std::unordered_map<std::string, std::vector<char>> l;
        virtual void Encode(Writer& wb)
        {
            wb.pack_array(wb, 12);
            wb.pack_int(this->a);
            wb.pack_int(this->b);
            wb.pack_double(this->c);
            wb.pack_double(this->d);
            wb.pack_int(this->e);
            wb.pack_bytes(this->f);
            if (this->g == null) { wb.pack_nil(); } else { this->g.Encode(wb); }
            if (this->h == null) { wb.pack_nil(); } else {
                wb.pack_map(this->h.size());
                for(auto &i : this->h)
                {
                    wb.pack_int(i.first);
                    wb.pack_int(i.second);
                }
            }
            if (this->i == null) { wb.pack_nil(); } else {
                wb.pack_array(this->i.size());
                for(int i=0; i<this->i.size(); ++i)
                {
                    int v = this->i[i];
                    wb.pack_int(v);
                }
            }
            if (this->j == null) { wb.pack_nil(); } else {
                wb.pack_array(this->j.size());
                for(int i=0; i<this->j.size(); ++i)
                {
                    inner v = this->j[i];
                    if (v == null) { wb.pack_nil(); } else { v.Encode(wb); }
                }
            }
            if (this->k == null) { wb.pack_nil(); } else {
                wb.pack_map(this->k.size());
                for(auto &i : this->k)
                {
                    wb.pack_int(i.first);
                    if (i.second == null) { wb.pack_nil(); } else { i.second.Encode(wb); }
                }
            }
            if (this->l == null) { wb.pack_nil(); } else {
                wb.pack_map(this->l.size());
                for(auto &i : this->l)
                {
                    wb.pack_int(i.first);
                    wb.pack_bytes(i.second);
                }
            }
        }
        virtual void Decode(Reader& rb)
        {
            long c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(ref this->a);
            if (--c <= 0) { return; }
            rb.unpack_int(ref this->b);
            if (--c <= 0) { return; }
            rb.unpack_double(ref this->c);
            if (--c <= 0) { return; }
            rb.unpack_double(ref this->d);
            if (--c <= 0) { return; }
            rb.unpack_int(ref this->e);
            if (--c <= 0) { return; }
            rb.unpack_bytes(ref this->f);
            if (--c <= 0) { return; }
            if (rb.NextIsNil()) { rb.MoveNext(); } else { this->g = new inner(); this->g.Decode(rb); }
            if (--c <= 0) { return; }
            {
                long n = rb.unpack_map();
                if (n < 0) { this->h=null; } else {
                    this->h = new Dictionary<int, std::string>();
                    for(int i=0; i<n; ++i)
                    {
                        int k=0; std::string v=0;
                        rb.unpack_int(ref k);
                        rb.unpack_int(ref v);
                        this->h[k] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long n = rb.unpack_array();
                if (n < 0) { this->i=null; } else {
                    this->i = new int[n];
                    for(int i=0; i<n; ++i)
                    {
                        int v=0;
                        rb.unpack_int(ref v);
                        this->i[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long n = rb.unpack_array();
                if (n < 0) { this->j=null; } else {
                    this->j = new inner[n];
                    for(int i=0; i<n; ++i)
                    {
                        inner v=null;
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { v = new inner(); v.Decode(rb); }
                        this->j[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long n = rb.unpack_map();
                if (n < 0) { this->k=null; } else {
                    this->k = new Dictionary<std::string, inner>();
                    for(int i=0; i<n; ++i)
                    {
                        std::string k=0; inner v=null;
                        rb.unpack_int(ref k);
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { v = new inner(); v.Decode(rb); }
                        this->k[k] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long n = rb.unpack_map();
                if (n < 0) { this->l=null; } else {
                    this->l = new Dictionary<std::string, std::vector<char>>();
                    for(int i=0; i<n; ++i)
                    {
                        std::string k=0; std::vector<char> v=std::vector<char>();
                        rb.unpack_int(ref k);
                        rb.unpack_bytes(ref v);
                        this->l[k] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual Proto* Create() { return new request(); }
    }
    class empty : public Proto
    {
    public:
        virtual void Encode(Writer& wb)
        {
            wb.pack_array(wb, 0);
        }
        virtual void Decode(Reader& rb)
        {
            long c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual Proto* Create() { return new empty(); }
    }
    class response : public Proto
    {
    public:
        int error;
        std::vector<char> buffer;
        virtual void Encode(Writer& wb)
        {
            wb.pack_array(wb, 2);
            wb.pack_int(this->error);
            wb.pack_bytes(this->buffer);
        }
        virtual void Decode(Reader& rb)
        {
            long c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(ref this->error);
            if (--c <= 0) { return; }
            rb.unpack_bytes(ref this->buffer);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual Proto* Create() { return new response(); }
    }

}
