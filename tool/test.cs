using System;
using System.Text;
using System.Collections.Generic;
using Erpc;

namespace test
{
    class request
    {
        class inner
        {
            public int t1;
            public string t2;

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

    }
    class response
    {
        public int error;
        public byte[] buffer;

    }

}
