using System;
using System.Text;
using System.Collections.Generic;
using Erpc;
using test;

namespace bee
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello World!");
            int count = 1000000;
            WriteBuffer wb = new WriteBuffer();
            test.request req = new test.request();
            test.request req2 = new test.request();
            byte[] tb = new byte[4];
            req.a = 100;
            req.b = 123456789;
            req.c = 3.1415F;
            req.d = 123456.789;
            req.e = "Hello";
            req.f = new byte[2];
            req.g = new test.request.inner();
            req.h = new Dictionary<int, string>();
            req.h[1] = "a";
            req.h[2] = "b";
            //req.i = new int[10];
            req.j = new test.request.inner[1];
            for (int i = 0; i < req.j.Length; ++i)
            {
                req.j[i] = new test.request.inner();
                req.j[i].t1 = 77;
                req.j[i].t2 = "w";
            }

            DateTime time1 = DateTime.Now;
            Console.WriteLine("start " + time1.ToString("yyyy-MM-dd HH:mm:ss.fff"));
            for (int i = 0; i < count; ++i)
            {
                wb.Clear();
                req.Encode(wb);
                tb = wb.CopyData();
            }
            DateTime time2 = DateTime.Now;
            TimeSpan span = (TimeSpan)(time2 - time1);
            double span_time = span.Seconds + (double)span.Milliseconds / 1000;
            Console.WriteLine("encode " + time2.ToString("yyyy-MM-dd HH:mm:ss.fff") + " count " + count.ToString() + " cost " + span_time);
            for (int i=0; i < count; ++i)
            {
                req2 = new test.request();
                ReadBuffer rb = new ReadBuffer(tb);
                req2.Decode(rb);
            }
            DateTime time3 = DateTime.Now;
            TimeSpan span2 = (TimeSpan)(time3 - time2);
            double span_time2 = span2.Seconds + (double)span2.Milliseconds / 1000;
            Console.WriteLine("decode " + time3.ToString("yyyy-MM-dd HH:mm:ss.fff") + " count " + count.ToString() + " cost " + span_time2);
            
            Console.WriteLine("Press any key to continue . . . ");
            Console.ReadKey(true);
        }
    }
}
