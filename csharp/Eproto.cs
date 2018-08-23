using System;
using System.Text;

namespace Erpc
{
    class Proto
    {
        virtual public void Encode(WriteBuffer wb) { }
        virtual public void Decode(ReadBuffer rb) { }
        virtual public Proto Create() { return null; }
    }

    class WriteBuffer
    {
        public const int WRITE_BUFFER_SIZE = 4096;
        public byte[] buffer;
        public int bufferSize;
        public int offset;
        public WriteBuffer()
        {
            buffer = new byte[WRITE_BUFFER_SIZE];
            bufferSize = WRITE_BUFFER_SIZE;
            offset = 0;
        }
        ~WriteBuffer()
        {

        }
        public byte[] CopyData()
        {
            byte[] b = new byte[offset];
            Array.Copy(buffer, b, offset);
            return b;
        }
        public byte[] Data()
        {
            return buffer;
        }
        public int Size()
        {
            return offset;
        }
        public void Add(byte b)
        {
            AllocBuffer(offset + 1);
            buffer[offset++] = b;
        }
        public void Add(byte b, byte v)
        {
            AllocBuffer(offset + 2);
            buffer[offset++] = b;
            buffer[offset++] = v;
        }
        public void Add(byte b, byte[] v){
            int length = (int)v.Length;
            AllocBuffer(offset + 1 + length);
            buffer[offset++] = b;
            v.CopyTo(buffer, offset);
            offset += length;
	    }
        public void Add(byte b, byte[] l, byte[] v)
        {
            int llength = (int)l.Length;
            int length = (int)v.Length;
            AllocBuffer(offset + llength + length);
            buffer[offset++] = b;
            l.CopyTo(buffer, offset);
            offset += llength;
            v.CopyTo(buffer, offset);
            offset += length;
        }
        public void Clear()
        {
            offset = 0;
        }
        public void AllocBuffer(int size)
        {
            if (size < bufferSize)
            {
                return;
            }
            int new_length = bufferSize + WRITE_BUFFER_SIZE;
            if (new_length < size)
            {
                new_length = size;
            }
            byte[] new_buf = new byte[new_length];
            buffer.CopyTo(new_buf, 0);
            buffer = new_buf;
            bufferSize = new_length;
        }
    }

    class ReadBuffer
    {
        public byte[] buffer;
        public int length;
        public int offset;
        public ReadBuffer(byte[] b)
        {
            buffer = b;
            length = b.Length;
            offset = 0;
        }
        public ReadBuffer(byte[] b, int offset, int length)
        {
            buffer = b;
            this.length = length;
            this.offset = offset;
        }
        public byte[] Data()
        {
            return buffer;
        }
        public void MoveOffset(int len)
        {
            offset += len;
        }
        public bool NextIsNil()
        {
            return buffer[offset] == 0xc0;
        }
        public byte Next()
        {
            return buffer[offset];
        }
        public byte MoveNext()
        {
            return buffer[offset++];
        }
        public int Offset()
        {
            return offset;
        }
        public bool IsOffsetEnd()
        {
            return offset >= length;
        }
        public int Left()
        {
            return length - offset;
        }
        public string CopyString(int count)
        {
            byte[] b = CopyBytes(count);
            return Eproto.BytesToString(b);
        }
        public byte[] CopyBytes(int count)
        {
            byte[] b = new byte[count];
            int stop = offset + count;
            for(int i = offset, j = 0; i < stop; ++i, ++j)
            {
                b[j] = buffer[i];
            }
            return b;
        }
        public void Clear()
        {
            offset = 0;
        }
    }

    static class Eproto
    {

        public static void PackNil(WriteBuffer wb)
        {
            wb.Add(0xc0);
        }
        public static void PackBool(WriteBuffer wb, bool value)
        {
            if (value)
            {
                wb.Add(0xc3);
            }
            else
            {
                wb.Add(0xc2);
            }
        }
        public static void PackInteger(WriteBuffer wb, long value)
        {
            if (value >= 0)
            {
                if (value < 128)
                {
                    wb.Add((byte)value);
                }
                else if (value < 256)
                {
                    wb.Add(0xcc, (byte)value);
                }
                else if (value < 65536)
                {
                    wb.Add(0xcd, ReverseBytes((ushort)value));
                }
                else if (value < 4294967296){
                    wb.Add(0xce, ReverseBytes((uint)value));
                } else {
                    wb.Add(0xcf, ReverseBytes((ulong)value));
                }
            }
            else
            {
                if (value >= -32)
                {
                    byte v = (byte)(0xe0 | (byte)value);
                    wb.Add(v);
                }
                else if (value >= -128)
                {
                    wb.Add(0xd0, (byte)value);
                }
                else if (value >= -32768)
                {
                    wb.Add(0xd1, ReverseBytes((short)(value & 0xffff)));
                }
                else if (value >= -2147483648 ){
                    wb.Add(0xd2, ReverseBytes((int)(value & 0xffffffff)));
                } else{
                    wb.Add(0xd3, ReverseBytes((long)value));
                }
            }
        }
        public static void PackDouble(WriteBuffer wb, float value)
        {
            wb.Add(0xca, ReverseBytes(value));
        }
        public static void PackDouble(WriteBuffer wb, double value)
        {
            wb.Add(0xcb, ReverseBytes(value));
        }
        public static void PackString(WriteBuffer wb, string str)
        {
            if(str == null)
            {
                PackNil(wb);
                return;
            }
            long slen = str.Length;
            byte topbyte = 0;
            if (slen < 32)
            {
                topbyte = (byte)(0xa0 | (byte)slen);
                wb.Add(topbyte, Eproto.StringToBytes(str));
            }
            else if (slen < 256)
            {
                topbyte = 0xd9;
                wb.Add(topbyte, ReverseBytes((byte)slen), Eproto.StringToBytes(str));
            }
            else if (slen < 65536)
            {
                topbyte = 0xda;
                wb.Add(topbyte, ReverseBytes((ushort)slen), Eproto.StringToBytes(str));
            }
            else if (slen < 4294967296 - 1){ // TODO: -1 for avoiding (condition is always true warning)
                topbyte = 0xdb;
                wb.Add(topbyte, ReverseBytes((uint)slen), Eproto.StringToBytes(str));
            } else {
                PackNil(wb);
                Console.WriteLine("PackString length is out of uint " + slen);
            }
        }
        public static void PackBytes(WriteBuffer wb, byte[] buf)
        {
            if(buf == null)
            {
                PackNil(wb);
                return;
            }
            long slen = buf.Length;
            byte topbyte = 0;
            if (slen < 256)
            {
                topbyte = 0xc4;
                wb.Add(topbyte, ReverseBytes((byte)slen), buf);
            }
            else if (slen < 65536)
            {
                topbyte = 0xc5;
                wb.Add(topbyte, ReverseBytes((ushort)slen), buf);
            }
            else if (slen < 4294967296 - 1){ // TODO: -1 for avoiding (condition is always true warning)
                topbyte = 0xc6;
                wb.Add(topbyte, ReverseBytes((uint)slen), buf);
            } else {
                PackNil(wb);
                Console.WriteLine("PackBytes length is out of uint " + slen);
            }
        }
        public static void PackArray(WriteBuffer wb, long length)
        {
            byte topbyte;
            // array!(ignore map part.) 0x90|n , 0xdc+2byte, 0xdd+4byte
            if (length < 16)
            {
                topbyte = (byte)(0x90 | (byte)length);
                wb.Add(topbyte);
            }
            else if (length < 65536)
            {
                topbyte = 0xdc;
                wb.Add(topbyte, ReverseBytes((ushort)length));
            }
            else if (length < 4294967296 - 1){ // TODO: avoid C warn
                topbyte = 0xdd;
                wb.Add(topbyte, ReverseBytes((uint)length));
            }
        }
        public static void PackMap(WriteBuffer wb, long length)
        {
            byte topbyte;
            // map fixmap, 16,32 : 0x80|num, 0xde+2byte, 0xdf+4byte
            if (length < 16)
            {
                topbyte = (byte)(0x80 | (byte)length);
                wb.Add(topbyte);
            }
            else if (length < 65536)
            {
                topbyte = 0xde;
                wb.Add(topbyte, ReverseBytes((ushort)length));
            }
            else if (length < 4294967296 - 1){
                topbyte = 0xdf;
                wb.Add(topbyte, ReverseBytes((uint)length));
            }
        }

        public static bool UnpackBool(ReadBuffer rb, ref bool value)
        {
            byte t = rb.MoveNext();
            switch (t)
            {
                case 0xc0: break;  // nil
                case 0xc2: value = false; break;
                case 0xc3: value = true; break;
                default: Console.WriteLine("UnpackBool Failed"); return false;
            }
            return true;
        }
        public static void UnpackInteger(ReadBuffer rb, ref byte value)
        {
            long v = 0;
            if( UnpackInteger(rb, ref v) )
            {
                value = (byte)v;
            }
        }
        public static void UnpackInteger(ReadBuffer rb, ref ushort value)
        {
            long v = 0;
            if (UnpackInteger(rb, ref v))
            {
                value = (ushort)v;
            }
        }
        public static void UnpackInteger(ReadBuffer rb, ref uint value)
        {
            long v = 0;
            if (UnpackInteger(rb, ref v))
            {
                value = (uint)v;
            }
        }
        public static void UnpackInteger(ReadBuffer rb, ref ulong value)
        {
            long v = 0;
            if (UnpackInteger(rb, ref v))
            {
                value = (ulong)v;
            }
        }
        public static void UnpackInteger(ReadBuffer rb, ref char value)
        {
            long v = 0;
            if (UnpackInteger(rb, ref v))
            {
                value = (char)v;
            }
        }
        public static void UnpackInteger(ReadBuffer rb, ref short value)
        {
            long v = 0;
            if (UnpackInteger(rb, ref v))
            {
                value = (short)v;
            }
        }
        public static void UnpackInteger(ReadBuffer rb, ref int value)
        {
            long v = 0;
            if (UnpackInteger(rb, ref v))
            {
                value = (int)v;
            }
        }
        public static bool UnpackInteger(ReadBuffer rb, ref long value)
        {
            byte t = rb.MoveNext();
            if(t == 0xc0)
            {
                return true;
            }
            if (t < 0x80)// fixint
            {
                value = t;
                return true;
            }
            if (t > 0xdf)// fixint_negative
            {
                value = (256 - t) * -1;
                return true;
            }
            switch (t)
            {
                case 0xcc:// uint8
                {
                    if(rb.Left() < 1)
                    {
                        Console.WriteLine("UnpackInteger uint8 failed");
                        return false;
                    }
                    value = rb.MoveNext();
                    break;
                }
                case 0xcd:// uint16
                {
                    if (rb.Left() < 2)
                    {
                        Console.WriteLine("UnpackInteger uint16 failed");
                        return false;
                    }
                    ushort v = 0;
                    ReadNumber(rb.Data(), rb.Offset(), ref v);
                    value = v;
                    rb.MoveOffset(2);
                    break;
                }
                case 0xce:// uint
                {
                    if (rb.Left() < 4)
                    {
                        Console.WriteLine("UnpackInteger uint failed");
                        return false;
                    }
                    uint v = 0;
                    ReadNumber(rb.Data(), rb.Offset(), ref v);
                    value = v;
                    rb.MoveOffset(4);
                    break;
                }
                case 0xcf:// uint64
                {
                    if (rb.Left() < 8)
                    {
                        Console.WriteLine("UnpackInteger uint64 failed");
                        return false;
                    }
                    ReadNumber(rb.Data(), rb.Offset(), ref value);
                    rb.MoveOffset(8);
                    break;
                }
                case 0xd0:// int8
                {
                    if (rb.Left() < 1)
                    {
                        Console.WriteLine("UnpackInteger int8 failed");
                        return false;
                    }
                    value = (char)rb.MoveNext();
                    break;
                }
                case 0xd1:// int16
                {
                    if (rb.Left() < 2)
                    {
                        Console.WriteLine("UnpackInteger int16 failed");
                        return false;
                    }
                    short v = 0;
                    ReadNumber(rb.Data(), rb.Offset(), ref v);
                    value = v;
                    rb.MoveOffset(2);
                    break;
                }
                case 0xd2:// int32
                {
                    if (rb.Left() < 4)
                    {
                        Console.WriteLine("UnpackInteger int failed");
                        return false;
                    }
                    int v = 0;
                    ReadNumber(rb.Data(), rb.Offset(), ref v);
                    value = v;
                    rb.MoveOffset(4);
                    break;
                }
                case 0xd3:// int64
                {
                    if (rb.Left() < 8)
                    {
                        Console.WriteLine("UnpackInteger int64 failed");
                        return false;
                    }
                    ulong v = 0;
                    ReadNumber(rb.Data(), rb.Offset(), ref v);
                    value = (long)v;
                    rb.MoveOffset(8);
                    break;
                }
                default:
                {
                    Console.WriteLine("UnpackInteger unknown integer type " + t.ToString());
                    return false;
                }
            }
            return true;
        }
        public static void UnpackDouble(ReadBuffer rb, ref float value)
        {
            double v = 0;
            if( UnpackDouble(rb, ref v) )
            {
                value = (float)v;
            }
        }
        public static bool UnpackDouble(ReadBuffer rb, ref double value)
        {
            byte t = rb.MoveNext();
            switch (t)
            {
                case 0xc0: return true;
                case 0xca:
                {
                    if(rb.Left() < 4)
                    {
                        Console.WriteLine("UnpackDouble float failed");
                        return false;
                    }
                    float v = 0;
                    ReadNumber(rb.Data(), rb.Offset(), ref v);
                    value = v;
                    rb.MoveOffset(4);
                    break;
                }
                case 0xcb:
                {
                    if (rb.Left() < 8)
                    {
                        Console.WriteLine("UnpackDouble double failed");
                        return false;
                    }
                    ReadNumber(rb.Data(), rb.Offset(), ref value);
                    rb.MoveOffset(8);
                    break;
                }
                default:
                {
                    Console.WriteLine("UnpackDouble unknown double type " + t.ToString());
                    return false;
                }
            }
            return true;
        }
        public static bool UnpackString(ReadBuffer rb, ref string value)
        {
            byte t = rb.MoveNext();
            if (t == 0xc0)
            {
                value = null;
                return true;
            }
            if (t > 0x9f && t < 0xc0)
            {
                int slen = t & 0x1f;
                if(rb.Left() < slen)
                {
                    Console.WriteLine("UnpackString fixed str failed");
                    return false;
                }
                value = rb.CopyString(slen);
                rb.MoveOffset(slen);
                return true;
            }
            switch (t)
            {
                case 0xd9:// str8
                    {
                        if (rb.Left() < 1)
                        {
                            Console.WriteLine("UnpackString str8 length failed");
                            return false;
                        }
                        byte slen = rb.MoveNext();
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackString str8 failed");
                            return false;
                        }
                        value = rb.CopyString(slen);
                        rb.MoveOffset(slen);
                        break;
                    }
                case 0xda:// str16
                    {
                        ushort slen = 0;
                        if (rb.Left() < 2)
                        {
                            Console.WriteLine("UnpackString str16 length failed");
                            return false;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(2);
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackString str16 failed");
                            return false;
                        }
                        value = rb.CopyString(slen);
                        rb.MoveOffset(slen);
                        break;
                    }
                case 0xdb:// str32
                    {
                        uint slen = 0;
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackString str32 length failed");
                            return false;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(4);
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackString str32 failed");
                            return false;
                        }
                        value = rb.CopyString((int)slen);
                        rb.MoveOffset((int)slen);
                        break;
                    }
                default:
                    {
                        Console.WriteLine("UnpackString unknown type " + t.ToString());
                        return false;
                    }
            }
            return true;
        }
        public static bool UnpackBytes(ReadBuffer rb, ref byte[] value)
        {
            byte t = rb.MoveNext();
            if (t == 0xc0)
            {
                value = null;
                return true;
            }
            switch (t)
            {
                case 0xc4:// bin8
                {
                    if (rb.Left() < 1)
                    {
                        Console.WriteLine("UnpackBytes bin8 length failed");
                        return false;
                    }
                    byte slen = rb.MoveNext();
                    if (rb.Left() < slen)
                    {
                        Console.WriteLine("UnpackBytes bin failed");
                        return false;
                    }
                    value = rb.CopyBytes(slen);
                    rb.MoveOffset(slen);
                    break;
                }
                case 0xc5:// bin16
                    {
                        ushort slen = 0;
                        if (rb.Left() < 2)
                        {
                            Console.WriteLine("UnpackBytes bin16 length failed");
                            return false;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(2);
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackBytes bin16 failed");
                            return false;
                        }
                        value = rb.CopyBytes(slen);
                        rb.MoveOffset(slen);
                        break;
                    }
                case 0xc6:// bin32
                    {
                        uint slen = 0;
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackBytes bin32 length failed");
                            return false;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(4);
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackBytes bin32 failed");
                            return false;
                        }
                        value = rb.CopyBytes((int)slen);
                        rb.MoveOffset((int)slen);
                        break;
                    }
                default:
                    {
                        Console.WriteLine("UnpackBytes unknown type " + t.ToString());
                        return false;
                    }
            }
            return true;
        }
        public static long UnpackArray(ReadBuffer rb)
        {
            byte t = rb.MoveNext();
            if (t == 0xc0)
            {
                return -1;
            }
            if (t > 0x8f && t < 0xa0)
            {
                int arylen = t & 0xf;
                return arylen;
            }
            switch (t)
            {
                case 0xdc:// array16
                    {
                        ushort slen = 0;
                        if (rb.Left() < 2)
                        {
                            Console.WriteLine("UnpackArray array16 length failed");
                            return -3;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(2);
                        return slen;
                    }
                case 0xdd:// array32
                    {
                        uint slen = 0;
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackArray array32 length failed");
                            return -4;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(4);
                        return slen;
                    }
                default:
                    {
                        Console.WriteLine("UnpackArray unknown type " + t.ToString());
                        break;
                    }
            }
            return -2;
        }
        public static long UnpackMap(ReadBuffer rb)
        {
            byte t = rb.MoveNext();
            if (t == 0xc0)
            {
                return -1;
            }
            if (t > 0x7f && t < 0x90)
            {
                int maplen = t & 0xf;
                return maplen;
            }
            switch (t)
            {
                case 0xde:// map16
                    {
                        ushort slen = 0;
                        if (rb.Left() < 2)
                        {
                            Console.WriteLine("UnpackMap array16 length failed");
                            return -3;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(2);
                        return slen;
                    }
                case 0xdf:// map32
                    {
                        uint slen = 0;
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackMap array32 length failed");
                            return -4;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(4);
                        return slen;
                    }
                default:
                    {
                        Console.WriteLine("UnpackMap unknown type " + t.ToString());
                        break;
                    }
            }
            return -2;
        }
        public static void UnpackDiscard(ReadBuffer rb, long count)
        {
            if(count <= 0)
            {
                return;
            }
            for(int i=0; i<count; ++i)
            {
                Discard(rb);
            }
        }
        public static void Discard(ReadBuffer rb)
        {
            if(rb.Left() < 1)
            {
                return;
            }
            byte t = rb.MoveNext();
            // positive fixint
            if (t < 0x80)
            {
                return;
            }
            // fixstr
            if (t > 0x9f && t < 0xc0)
            {
                int slen = t & 0x1f;
                if (rb.Left() < slen)
                {
                    Console.WriteLine("UnpackString fixed str failed");
                    return;
                }
                rb.MoveOffset(slen);
                return;
            }
            // fixmap
            if (t > 0x7f && t < 0x90)
            {
                int maplen = t & 0xf;
                UnpackDiscard(rb, maplen * 2);
                return;
            }
            // fixarray
            if (t > 0x8f && t < 0xa0)
            {
                int arylen = t & 0xf;
                UnpackDiscard(rb, arylen);
                return;
            }
            // negative fixint
            if (t > 0xdf)
            {
                return;
            }
            switch (t)
            {
                case 0xc0:// nil
                    return;
                case 0xc2:// false
                    return;
                case 0xc3:// true
                    return;
                case 0xcc:// uint8
                    rb.MoveNext();
                    return;
                case 0xcd:// uint16
                    {
                        if (rb.Left() < 2)
                        {
                            Console.WriteLine("UnpackInteger uint16 failed");
                            return;
                        }
                        rb.MoveOffset(2);
                        return;
                    }
                case 0xce:// uint32
                    {
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackInteger uint failed");
                            return;
                        }
                        rb.MoveOffset(4);
                        return;
                    }
                case 0xcf:// uint64
                    {
                        if (rb.Left() < 8)
                        {
                            Console.WriteLine("UnpackInteger uint64 failed");
                            return;
                        }
                        rb.MoveOffset(8);
                        return;
                    }
                case 0xd0:// int8
                    {
                        if (rb.Left() < 1)
                        {
                            Console.WriteLine("UnpackInteger int8 failed");
                            return;
                        }
                        rb.MoveNext();
                        return;
                    }
                case 0xd1:// int16
                    {
                        if (rb.Left() < 2)
                        {
                            Console.WriteLine("UnpackInteger int16 failed");
                            return;
                        }
                        rb.MoveOffset(2);
                        return;
                    }
                case 0xd2:// int32
                    {
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackInteger int failed");
                            return;
                        }
                        rb.MoveOffset(4);
                        return;
                    }
                case 0xd3:// int64
                    {
                        if (rb.Left() < 8)
                        {
                            Console.WriteLine("UnpackInteger int64 failed");
                            return;
                        }
                        rb.MoveOffset(8);
                        return;
                    }
                case 0xd9:// str8
                    {
                        if (rb.Left() < 1)
                        {
                            Console.WriteLine("UnpackString str8 length failed");
                            return;
                        }
                        byte slen = rb.MoveNext();
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackString str8 failed");
                            return;
                        }
                        rb.MoveOffset(slen);
                        return;
                    }
                case 0xda:// str16
                    {
                        ushort slen = 0;
                        if (rb.Left() < 2)
                        {
                            Console.WriteLine("UnpackString str16 length failed");
                            return;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(2);
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackString str16 failed");
                            return;
                        }
                        rb.MoveOffset(slen);
                        return;
                    }
                case 0xdb:// str32
                    {
                        uint slen = 0;
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackString str32 length failed");
                            return;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(4);
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackString str32 failed");
                            return;
                        }
                        rb.MoveOffset((int)slen);
                        return;
                    }

                case 0xca:// float
                    {
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackDouble float failed");
                            return;
                        }
                        rb.MoveOffset(4);
                        return;
                    }
                case 0xcb:// double
                    {
                        if (rb.Left() < 8)
                        {
                            Console.WriteLine("UnpackDouble double failed");
                            return;
                        }
                        rb.MoveOffset(8);
                        return;
                    }

                case 0xdc://  array16
                    {
                        ushort slen = 0;
                        if (rb.Left() < 2)
                        {
                            Console.WriteLine("UnpackArray array16 length failed");
                            return;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(2);
                        UnpackDiscard(rb, slen);
                        return;
                    }
                case 0xdd:// array32
                    {
                        uint slen = 0;
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackArray array32 length failed");
                            return;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(4);
                        UnpackDiscard(rb, slen);
                        return;
                    }
                case 0xde:// map16
                    {
                        ushort slen = 0;
                        if (rb.Left() < 2)
                        {
                            Console.WriteLine("UnpackMap array16 length failed");
                            return;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(2);
                        UnpackDiscard(rb, slen * 2);
                        return;
                    }
                case 0xdf:// map32
                    {
                        uint slen = 0;
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackMap array32 length failed");
                            return;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(4);
                        UnpackDiscard(rb, slen * 2);
                        return;
                    }

                case 0xc4:// bin8
                    {
                        if (rb.Left() < 1)
                        {
                            Console.WriteLine("UnpackBytes bin8 length failed");
                            return;
                        }
                        byte slen = rb.MoveNext();
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackBytes bin failed");
                            return;
                        }
                        rb.MoveOffset(slen);
                        return;
                    }
                case 0xc5:// bin16
                    {
                        ushort slen = 0;
                        if (rb.Left() < 2)
                        {
                            Console.WriteLine("UnpackBytes bin16 length failed");
                            return;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(2);
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackBytes bin16 failed");
                            return;
                        }
                        rb.MoveOffset(slen);
                        break;
                    }
                case 0xc6:// bin32
                    {
                        uint slen = 0;
                        if (rb.Left() < 4)
                        {
                            Console.WriteLine("UnpackBytes bin32 length failed");
                            return;
                        }
                        ReadNumber(rb.Data(), rb.Offset(), ref slen);
                        rb.MoveOffset(4);
                        if (rb.Left() < slen)
                        {
                            Console.WriteLine("UnpackBytes bin32 failed");
                            return;
                        }
                        rb.MoveOffset((int)slen);
                        break;
                    }
                default:
                    {
                        Console.WriteLine("Discard unknown type " + t.ToString());
                        break;
                    }
            }
        }

        public static void ReadNumber(byte[] b, int offset, ref ushort value)
        {
            byte[] v = new byte[2];
            for (int i = 1, j = 0; j < 2; --i, ++j)
            {
                v[j] = b[offset + i];
            }
            value = BitConverter.ToUInt16(v, 0);
        }
        public static void ReadNumber(byte[] b, int offset, ref uint value)
        {
            byte[] v = new byte[4];
            for (int i = 3, j = 0; j < 4; --i, ++j)
            {
                v[j] = b[offset + i];
            }
            value = BitConverter.ToUInt32(v, 0);
        }
        public static void ReadNumber(byte[] b, int offset, ref ulong value)
        {
            byte[] v = new byte[8];
            for (int i = 7, j = 0; j < 8; --i, ++j)
            {
                v[j] = b[offset + i];
            }
            value = BitConverter.ToUInt64(v, 0);
        }
        public static void ReadNumber(byte[] b, int offset, ref short value)
        {
            byte[] v = new byte[2];
            for (int i = 1, j = 0; j < 2; --i, ++j)
            {
                v[j] = b[offset + i];
            }
            value = BitConverter.ToInt16(v, 0);
        }
        public static void ReadNumber(byte[] b, int offset, ref int value)
        {
            byte[] v = new byte[4];
            for (int i = 3, j = 0; j < 4; --i, ++j)
            {
                v[j] = b[offset + i];
            }
            value = BitConverter.ToInt32(v, 0);
        }
        public static void ReadNumber(byte[] b, int offset, ref long value)
        {
            byte[] v = new byte[8];
            for (int i = 7, j = 0; j < 8; --i, ++j)
            {
                v[j] = b[offset + i];
            }
            value = BitConverter.ToInt64(v, 0);
        }
        public static void ReadNumber(byte[] b, int offset, ref float value)
        {
            byte[] v = new byte[4];
            for (int i = 3, j = 0; j < 4; --i, ++j)
            {
                v[j] = b[offset + i];
            }
            value = BitConverter.ToSingle(v, 0);
        }
        public static void ReadNumber(byte[] b, int offset, ref double value)
        {
            byte[] v = new byte[8];
            for (int i = 7, j = 0; j < 8; --i, ++j)
            {
                v[j] = b[offset + i];
            }
            value = BitConverter.ToDouble(v, 0);
        }
        
        public static byte[] ReverseBytes(byte value)
        {
            byte[] b = new byte[1];
            b[0] = value;
            return b;
        }
        public static byte[] ReverseBytes(ushort value)
        {
            byte[] b = BitConverter.GetBytes(value);
            Array.Reverse(b);
            return b;
        }
        public static byte[] ReverseBytes(uint value)
        {
            byte[] b = BitConverter.GetBytes(value);
            Array.Reverse(b);
            return b;
        }
        public static byte[] ReverseBytes(ulong value)
        {
            byte[] b = BitConverter.GetBytes(value);
            Array.Reverse(b);
            return b;
        }
        public static byte[] ReverseBytes(short value)
        {
            byte[] b = BitConverter.GetBytes(value);
            Array.Reverse(b);
            return b;
        }
        public static byte[] ReverseBytes(int value)
        {
            byte[] b = BitConverter.GetBytes(value);
            Array.Reverse(b);
            return b;
        }
        public static byte[] ReverseBytes(long value)
        {
            byte[] b = BitConverter.GetBytes(value);
            Array.Reverse(b);
            return b;
        }
        public static byte[] ReverseBytes(float value)
        {
            byte[] b = BitConverter.GetBytes(value);
            Array.Reverse(b);
            return b;
        }
        public static byte[] ReverseBytes(double value)
        {
            byte[] b = BitConverter.GetBytes(value);
            Array.Reverse(b);
            return b;
        }

        public static string BytesPrint(byte[] b)
        {
            string s = "";
            for(int i=0; i<b.Length; ++i)
            {
                s += b[i].ToString() + " ";
            }
            return s;
        }
        public static string BytesPrintHex(byte[] buffer)
        {
            StringBuilder ret = new StringBuilder();
            foreach (byte b in buffer)
            {
                //{0:X2} 大写
                ret.Append("0x");
                ret.AppendFormat("{0:x}", b);
                ret.Append(" ");
            }
            var hex = ret.ToString();
            return hex;
        }
        static public byte[] StringToBytes(string str)
        {
            return Encoding.UTF8.GetBytes(str);
        }
        static public string BytesToString(byte[] b)
        {
            return Encoding.UTF8.GetString(b);
        }
    }
}
