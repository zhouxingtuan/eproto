using System;
using System.Text;
using System.Collections.Generic;
using Erpc;

namespace test
{
    class request
    {
        public class inner
        {
            public int t1;
            public string t2;
            public void Encode(WriteBuffer wb)
            {
                Eproto.PackArray(wb, 2);
                Eproto.PackInteger(wb, t1);
                Eproto.PackString(wb, t2);
            }
            public void Decode(ReadBuffer rb)
            {
                long _c_ = Eproto.UnpackArray(rb);
                if (_c_ <= 0) { return; }
                Eproto.UnpackInteger(rb, ref t1);
                if (--_c_ <= 0) { return; }
                Eproto.UnpackString(rb, ref t2);
                if (--_c_ <= 0) { return; }
                Eproto.UnpackDiscard(rb, _c_);
            }

        }
        public int a;
        public long b;
        public float c;
        public double d;
        public string e;
        public byte[] f;
        public inner g;
        public Dictionary<int, string> h;
        public int[] i;
        public inner[] j;
        public Dictionary<string, inner> k;
        public Dictionary<string, byte[]> l;
        public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 12);
            Eproto.PackInteger(wb, a);
            Eproto.PackInteger(wb, b);
            Eproto.PackDouble(wb, c);
            Eproto.PackDouble(wb, d);
            Eproto.PackString(wb, e);
            Eproto.PackBytes(wb, f);
            if (g == null) { Eproto.PackNil(wb); } else { g.Encode(wb); }
            if (h == null) { Eproto.PackNil(wb); } else {
                Eproto.PackMap(wb, h.Count);
                foreach (var i in h)
                {
                    Eproto.PackInteger(wb, i.Key);
                    Eproto.PackString(wb, i.Value);
                }
            }
            if (i == null) { Eproto.PackNil(wb); } else {
                Eproto.PackArray(wb, i.Length);
                for(int _i_=0; _i_<i.Length; ++_i_)
                {
                    int _v_ = i[_i_];
                Eproto.PackInteger(wb, _v_);
                }
            }
            if (j == null) { Eproto.PackNil(wb); } else {
                Eproto.PackArray(wb, j.Length);
                for(int _i_=0; _i_<j.Length; ++_i_)
                {
                    inner _v_ = j[_i_];
                    if (_v_ == null) { Eproto.PackNil(wb); } else { _v_.Encode(wb); }
                }
            }
            if (k == null) { Eproto.PackNil(wb); } else {
                Eproto.PackMap(wb, k.Count);
                foreach (var i in k)
                {
                    Eproto.PackString(wb, i.Key);
                    if (i.Value == null) { Eproto.PackNil(wb); } else { i.Value.Encode(wb); }
                }
            }
            if (l == null) { Eproto.PackNil(wb); } else {
                Eproto.PackMap(wb, l.Count);
                foreach (var i in l)
                {
                    Eproto.PackString(wb, i.Key);
                    Eproto.PackBytes(wb, i.Value);
                }
            }
        }
        public void Decode(ReadBuffer rb)
        {
            long _c_ = Eproto.UnpackArray(rb);
            if (_c_ <= 0) { return; }
            Eproto.UnpackInteger(rb, ref a);
            if (--_c_ <= 0) { return; }
            Eproto.UnpackInteger(rb, ref b);
            if (--_c_ <= 0) { return; }
            Eproto.UnpackDouble(rb, ref c);
            if (--_c_ <= 0) { return; }
            Eproto.UnpackDouble(rb, ref d);
            if (--_c_ <= 0) { return; }
            Eproto.UnpackString(rb, ref e);
            if (--_c_ <= 0) { return; }
            Eproto.UnpackBytes(rb, ref f);
            if (--_c_ <= 0) { return; }
            if (rb.NextIsNil()) { rb.MoveNext(); } else { g = new inner(); g.Decode(rb); }
            if (--_c_ <= 0) { return; }
            {
                long _n_ = Eproto.UnpackMap(rb);
                if (_n_ < 0) { h=null; } else {
                    h = new Dictionary<int, string>();
                    for(int _i_=0; _i_<_n_; ++_i_)
                    {
                        int _k_=0; string _v_=null;
                        Eproto.UnpackInteger(rb, ref _k_);
                        Eproto.UnpackString(rb, ref _v_);
                        h[_k_] = _v_;
                    }
                }
            }
            if (--_c_ <= 0) { return; }
            {
                long _n_ = Eproto.UnpackArray(rb);
                if (_n_ < 0) { i=null; } else {
                    i = new int[_n_];
                    for(int _i_=0; _i_<_n_; ++_i_)
                    {
                        int _v_=0;
                        Eproto.UnpackInteger(rb, ref _v_);
                        i[_i_] = _v_;
                    }
                }
            }
            if (--_c_ <= 0) { return; }
            {
                long _n_ = Eproto.UnpackArray(rb);
                if (_n_ < 0) { j=null; } else {
                    j = new inner[_n_];
                    for(int _i_=0; _i_<_n_; ++_i_)
                    {
                        inner _v_=null;
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { _v_ = new inner(); _v_.Decode(rb); }
                        j[_i_] = _v_;
                    }
                }
            }
            if (--_c_ <= 0) { return; }
            {
                long _n_ = Eproto.UnpackMap(rb);
                if (_n_ < 0) { k=null; } else {
                    k = new Dictionary<string, inner>();
                    for(int _i_=0; _i_<_n_; ++_i_)
                    {
                        string _k_=null; inner _v_=null;
                        Eproto.UnpackString(rb, ref _k_);
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { _v_ = new inner(); _v_.Decode(rb); }
                        if (_k_ != null) { k[_k_] = _v_; }
                    }
                }
            }
            if (--_c_ <= 0) { return; }
            {
                long _n_ = Eproto.UnpackMap(rb);
                if (_n_ < 0) { l=null; } else {
                    l = new Dictionary<string, byte[]>();
                    for(int _i_=0; _i_<_n_; ++_i_)
                    {
                        string _k_=null; byte[] _v_=null;
                        Eproto.UnpackString(rb, ref _k_);
                        Eproto.UnpackBytes(rb, ref _v_);
                        if (_k_ != null) { l[_k_] = _v_; }
                    }
                }
            }
            if (--_c_ <= 0) { return; }
            Eproto.UnpackDiscard(rb, _c_);
        }

    }
    class empty
    {
        public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 0);
        }
        public void Decode(ReadBuffer rb)
        {
            long _c_ = Eproto.UnpackArray(rb);
            if (_c_ <= 0) { return; }
            Eproto.UnpackDiscard(rb, _c_);
        }

    }
    class response
    {
        public int error;
        public byte[] buffer;
        public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 2);
            Eproto.PackInteger(wb, error);
            Eproto.PackBytes(wb, buffer);
        }
        public void Decode(ReadBuffer rb)
        {
            long _c_ = Eproto.UnpackArray(rb);
            if (_c_ <= 0) { return; }
            Eproto.UnpackInteger(rb, ref error);
            if (--_c_ <= 0) { return; }
            Eproto.UnpackBytes(rb, ref buffer);
            if (--_c_ <= 0) { return; }
            Eproto.UnpackDiscard(rb, _c_);
        }

    }

}
