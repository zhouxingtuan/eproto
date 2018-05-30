using System;
using System.Text;
using System.Collections.Generic;
using erpc;

namespace bee
{
    class InnerTest
    {
        public int d;
        public double e;
        public float f;
        public byte[] g;

        public InnerTest()
        {
            d = 0;
            e = 10000.2314;
            f = 3.1415F;
            g = new byte[5];
            for(int i=0; i<g.Length; ++i)
            {
                g[i] = (byte)(i + 9);
            }
        }
        public int MaxLength()
        {
            int length = 0;
            length += sizeof(int) + 1;
            length += sizeof(double) + 1;
            length += sizeof(float) + 1;
            if (g != null)
            {
                length += g.Length + 5;
            }
            return length;
        }
        public void Encode(WriteBuffer wb)
        {
            wb.CheckMaxLength(MaxLength());
            Eproto.PackArray(wb, 4);
            Eproto.PackInteger(wb, d);
            Eproto.PackDouble(wb, e);
            Eproto.PackDouble(wb, f);
            Eproto.PackBytes(wb, g);
        }
        public void Decode(ReadBuffer rb)
        {
            long count = Eproto.UnpackArray(rb);
            Eproto.UnpackInteger(rb, ref d);
            if(--count <= 0)
            {
                return;
            }
            Eproto.UnpackDouble(rb, ref e);
            if (--count <= 0)
            {
                return;
            }
            Eproto.UnpackDouble(rb, ref f);
            if (--count <= 0)
            {
                return;
            }
            Eproto.UnpackBytes(rb, ref g);
            if (--count <= 0)
            {
                return;
            }
            Eproto.UnpackDiscard(rb, count);
        }
        override public string ToString()
        {
            string s = GetType().Name + " Begin\n";
            s += " d " + d.GetType().Name + " " + d.ToString() + "\n";
            s += " e " + e.GetType().Name + " " + e.ToString() + "\n";
            s += " f " + f.GetType().Name + " " + f.ToString() + "\n";
            if(g == null)
            {
                s += " g null\n";
            }
            else
            {
                s += " g " + g.GetType().Name + " " + Eproto.BytesToHex(g) + "\n";
            }
            s += GetType().Name + " End\n";
            return s;
        }
    }
    class Test
    {
        public int a;
        public int b;
        public InnerTest h;
        public string c;
        public Test()
        {
            a = 100;
            b = 1234567;
            c = "hello world!";
            //h = new InnerTest();
        }
        public int MaxLength()
        {
            int length = 0;
            length += sizeof(int) + 1;
            length += sizeof(int) + 1;
            if (h != null)
            {
                length += h.MaxLength() + 4;
            }
            length += c.Length + 5;
            return length;
        }
        public void Encode(WriteBuffer wb)
        {
            wb.CheckMaxLength(MaxLength());
            Eproto.PackArray(wb, 4);
            Eproto.PackInteger(wb, a);
            Eproto.PackInteger(wb, b);
            if (h == null)
            {
                Eproto.PackNil(wb);
            }
            else
            {
                h.Encode(wb);
            }
            Eproto.PackString(wb, c);
        }
        public void Decode(ReadBuffer rb)
        {
            long count = Eproto.UnpackArray(rb);
            Eproto.UnpackInteger(rb, ref a);
            if (--count <= 0)
            {
                return;
            }
            Eproto.UnpackInteger(rb, ref b);
            if (--count <= 0)
            {
                return;
            }
            h = new InnerTest();
            h.Decode(rb);
            if (--count <= 0)
            {
                return;
            }
            Eproto.UnpackString(rb, ref c);
            if (--count <= 0)
            {
                return;
            }
            Eproto.UnpackDiscard(rb, count);
        }
        override public string ToString()
        {
            string s = GetType().Name + " Begin\n";
            s += " a " + a.GetType().Name + " " + a.ToString() + "\n";
            s += " b " + b.GetType().Name + " " + b.ToString() + "\n";
            if(h == null)
            {
                s += " h null\n";
            }
            else
            {
                s += " h " + h.GetType().Name + "\n" + h.ToString();
            }
            s += " c " + c.GetType().Name + " " + c.ToString() + "\n";
            s += GetType().Name + " End\n";
            return s;
        }
        public void Print()
        {
            Console.WriteLine(ToString());
        }
    }
    

    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello World!");
            int ns = 1000;
            byte[] nsb = Eproto.ReverseBytes(ns);
            ns = 0;
            Eproto.ReadNumber(nsb, 0, ref ns);
            Console.WriteLine("number " + ns.ToString() + " " + ns.GetType().Name + " byte length " + nsb.Length.ToString() + " sizeof(int) " + sizeof(int));

            Dictionary<int, string> dict = new Dictionary<int, string>();
            dict.Add(1, "C#");
            dict.Remove(1);
            dict.Add(1, "C++");
            dict.Add(2, "Lua");
            int c = dict.Count;

            Test t = new Test();
            t.Print();
            t.h = new InnerTest();
            t.a = 35667;
            t.h.e = 2345.6789;
            t.Print();
            WriteBuffer wb1 = new WriteBuffer();
            t.Encode(wb1);
            byte[] tb = wb1.CopyData();
            DateTime time1 = DateTime.Now;
            Console.WriteLine("start time " + time1.ToString("yyyy-MM-dd HH:mm:ss.fff"));
            Test t2 = new Test();
            int count = 1000000;
            WriteBuffer wb = new WriteBuffer();
            for (int i = 0; i < count; ++i)
            {
                wb.Clear();
                t.Encode(wb);
                tb = wb.CopyData();
                //t2 = new Test();
                //ReadBuffer rb = new ReadBuffer(tb);
                //t2.Decode(rb);
            }
            DateTime time2 = DateTime.Now;
            TimeSpan span = (TimeSpan)(time2 - time1);
            double span_time = span.Seconds + (double)span.Milliseconds / 1000;
            Console.WriteLine("end time " + time2.ToString("yyyy-MM-dd HH:mm:ss.fff") + " count " + count.ToString() + " cost " + span_time);
            for (int i=0; i < count; ++i)
            {
                //WriteBuffer wb = new WriteBuffer();
                //t.Encode(wb);
                //tb = wb.CopyData();
                t2 = new Test();
                ReadBuffer rb = new ReadBuffer(tb);
                t2.Decode(rb);
            }
            DateTime time3 = DateTime.Now;
            TimeSpan span2 = (TimeSpan)(time3 - time2);
            double span_time2 = span2.Seconds + (double)span2.Milliseconds / 1000;
            Console.WriteLine("end time " + time3.ToString("yyyy-MM-dd HH:mm:ss.fff") + " count " + count.ToString() + " cost " + span_time2);

            t2.Print();

            Console.WriteLine("Press any key to continue . . . ");
            Console.ReadKey(true);
        }
    }
}
