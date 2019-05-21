using System;
using System.Text;
using System.Collections.Generic;
using Erpc;

namespace test
{
    class request : Proto
    {
        public class inner : Proto
        {
            public int t1;
            public string t2;
            override public void Encode(WriteBuffer wb)
            {
                Eproto.PackArray(wb, 2);
                Eproto.PackInteger(wb, this.t1);
                Eproto.PackString(wb, this.t2);
            }
            override public void Decode(ReadBuffer rb)
            {
                long c = Eproto.UnpackArray(rb);
                if (c <= 0) { return; }
                Eproto.UnpackInteger(rb, ref this.t1);
                if (--c <= 0) { return; }
                Eproto.UnpackString(rb, ref this.t2);
                if (--c <= 0) { return; }
                Eproto.UnpackDiscard(rb, c);
            }
            override public Proto Create() { return new inner(); }
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
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 12);
            Eproto.PackInteger(wb, this.a);
            Eproto.PackInteger(wb, this.b);
            Eproto.PackDouble(wb, this.c);
            Eproto.PackDouble(wb, this.d);
            Eproto.PackString(wb, this.e);
            Eproto.PackBytes(wb, this.f);
            if (this.g == null) { Eproto.PackNil(wb); } else { this.g.Encode(wb); }
            if (this.h == null) { Eproto.PackNil(wb); } else {
                Eproto.PackMap(wb, this.h.Count);
                foreach (var i in this.h)
                {
                    Eproto.PackInteger(wb, i.Key);
                    Eproto.PackString(wb, i.Value);
                }
            }
            if (this.i == null) { Eproto.PackNil(wb); } else {
                Eproto.PackArray(wb, this.i.Length);
                for(int i=0; i<this.i.Length; ++i)
                {
                    int v = this.i[i];
                    Eproto.PackInteger(wb, v);
                }
            }
            if (this.j == null) { Eproto.PackNil(wb); } else {
                Eproto.PackArray(wb, this.j.Length);
                for(int i=0; i<this.j.Length; ++i)
                {
                    inner v = this.j[i];
                    if (v == null) { Eproto.PackNil(wb); } else { v.Encode(wb); }
                }
            }
            if (this.k == null) { Eproto.PackNil(wb); } else {
                Eproto.PackMap(wb, this.k.Count);
                foreach (var i in this.k)
                {
                    Eproto.PackString(wb, i.Key);
                    if (i.Value == null) { Eproto.PackNil(wb); } else { i.Value.Encode(wb); }
                }
            }
            if (this.l == null) { Eproto.PackNil(wb); } else {
                Eproto.PackMap(wb, this.l.Count);
                foreach (var i in this.l)
                {
                    Eproto.PackString(wb, i.Key);
                    Eproto.PackBytes(wb, i.Value);
                }
            }
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.a);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.b);
            if (--c <= 0) { return; }
            Eproto.UnpackDouble(rb, ref this.c);
            if (--c <= 0) { return; }
            Eproto.UnpackDouble(rb, ref this.d);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.e);
            if (--c <= 0) { return; }
            Eproto.UnpackBytes(rb, ref this.f);
            if (--c <= 0) { return; }
            if (rb.NextIsNil()) { rb.MoveNext(); } else { this.g = new inner(); this.g.Decode(rb); }
            if (--c <= 0) { return; }
            {
                long n = Eproto.UnpackMap(rb);
                if (n < 0) { this.h=null; } else {
                    this.h = new Dictionary<int, string>();
                    for(int i=0; i<n; ++i)
                    {
                        int k=0; string v=null;
                        Eproto.UnpackInteger(rb, ref k);
                        Eproto.UnpackString(rb, ref v);
                        this.h[k] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long n = Eproto.UnpackArray(rb);
                if (n < 0) { this.i=null; } else {
                    this.i = new int[n];
                    for(int i=0; i<n; ++i)
                    {
                        int v=0;
                        Eproto.UnpackInteger(rb, ref v);
                        this.i[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long n = Eproto.UnpackArray(rb);
                if (n < 0) { this.j=null; } else {
                    this.j = new inner[n];
                    for(int i=0; i<n; ++i)
                    {
                        inner v=null;
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { v = new inner(); v.Decode(rb); }
                        this.j[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long n = Eproto.UnpackMap(rb);
                if (n < 0) { this.k=null; } else {
                    this.k = new Dictionary<string, inner>();
                    for(int i=0; i<n; ++i)
                    {
                        string k=null; inner v=null;
                        Eproto.UnpackString(rb, ref k);
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { v = new inner(); v.Decode(rb); }
                        if (k != null) { this.k[k] = v; }
                    }
                }
            }
            if (--c <= 0) { return; }
            {
                long n = Eproto.UnpackMap(rb);
                if (n < 0) { this.l=null; } else {
                    this.l = new Dictionary<string, byte[]>();
                    for(int i=0; i<n; ++i)
                    {
                        string k=null; byte[] v=null;
                        Eproto.UnpackString(rb, ref k);
                        Eproto.UnpackBytes(rb, ref v);
                        if (k != null) { this.l[k] = v; }
                    }
                }
            }
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new request(); }
    }
    class empty : Proto
    {
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 0);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new empty(); }
    }
    class response : Proto
    {
        public int error;
        public byte[] buffer;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 2);
            Eproto.PackInteger(wb, this.error);
            Eproto.PackBytes(wb, this.buffer);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.error);
            if (--c <= 0) { return; }
            Eproto.UnpackBytes(rb, ref this.buffer);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new response(); }
    }

}
