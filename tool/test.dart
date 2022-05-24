library test;
import 'dart:typed_data';
import 'eproto.dart' as eproto;


class GameOver
{
  int roomId = 0;
  int winMoney = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(2);
    wb.packInt(this.roomId);
    wb.packInt(this.winMoney);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.roomId = rb.unpackInt();
    if (--c <= 0) { return; }
    this.winMoney = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  GameOver create() { return GameOver(); }

}
class empty
{
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(0);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  empty create() { return empty(); }

}
class inner
{
  int t1 = 0;
  String t2 = "";
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(2);
    wb.packInt(this.t1);
    wb.packString(this.t2);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.t1 = rb.unpackInt();
    if (--c <= 0) { return; }
    this.t2 = rb.unpackString();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  inner create() { return inner(); }

}
class request
{
  int a = 0;
  int b = 0;
  double c = 0;
  double d = 0;
  String e = "";
  Uint8List f = Uint8List(0);
  inner g = inner();
  Map<int, String> h = Map<int, String>();
  List<int> i = List<int>();
  List<inner> j = List<inner>();
  Map<String, inner> k = Map<String, inner>();
  Map<String, Uint8List> l = Map<String, Uint8List>();
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(12);
    wb.packInt(this.a);
    wb.packInt(this.b);
    wb.packDouble(this.c);
    wb.packDouble(this.d);
    wb.packString(this.e);
    wb.packBytes(this.f);
    if (this.g == null) { wb.packNil(); } else { this.g.encode(wb); }
    {
      wb.packMapHead(this.h.length);
      this.h.forEach((k,v)
      {
        wb.packInt(k);
        wb.packString(v);
      });
    }
    {
      wb.packArrayHead(this.i.length);
      for(int i=0; i<this.i.length; ++i)
      {
        int v = this.i[i];
        wb.packInt(v);
      }
    }
    {
      wb.packArrayHead(this.j.length);
      for(int i=0; i<this.j.length; ++i)
      {
        inner v = this.j[i];
        if (v == null) { wb.packNil(); } else { v.encode(wb); }
      }
    }
    {
      wb.packMapHead(this.k.length);
      this.k.forEach((k,v)
      {
        wb.packString(k);
        if (v == null) { wb.packNil(); } else { v.encode(wb); }
      });
    }
    {
      wb.packMapHead(this.l.length);
      this.l.forEach((k,v)
      {
        wb.packString(k);
        wb.packBytes(v);
      });
    }
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.a = rb.unpackInt();
    if (--c <= 0) { return; }
    this.b = rb.unpackInt();
    if (--c <= 0) { return; }
    this.c = rb.unpackDouble();
    if (--c <= 0) { return; }
    this.d = rb.unpackDouble();
    if (--c <= 0) { return; }
    this.e = rb.unpackString();
    if (--c <= 0) { return; }
    this.f = rb.unpackBytes();
    if (--c <= 0) { return; }
    if (rb.nextIsNil()) { rb.moveNext(); } else { this.g.decode(rb); }
    if (--c <= 0) { return; }
    {
      int n = rb.unpackMapHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          int k=0;
          k = rb.unpackInt();
          String v="";
          v = rb.unpackString();
          this.h[k] = v;
        }
      }
    }
    if (--c <= 0) { return; }
    {
      int n = rb.unpackArrayHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          int v=0;
          v = rb.unpackInt();
          this.i.add(v);
        }
      }
    }
    if (--c <= 0) { return; }
    {
      int n = rb.unpackArrayHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          inner v=inner();
          if (rb.nextIsNil()) { rb.moveNext(); } else { v.decode(rb); }
          this.j.add(v);
        }
      }
    }
    if (--c <= 0) { return; }
    {
      int n = rb.unpackMapHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          String k="";
          k = rb.unpackString();
          inner v=inner();
          if (rb.nextIsNil()) { rb.moveNext(); } else { v.decode(rb); }
          this.k[k] = v;
        }
      }
    }
    if (--c <= 0) { return; }
    {
      int n = rb.unpackMapHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          String k="";
          k = rb.unpackString();
          Uint8List v=Uint8List(0);
          v = rb.unpackBytes();
          this.l[k] = v;
        }
      }
    }
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  request create() { return request(); }

}
class response
{
  int error = 0;
  Uint8List buffer = Uint8List(0);
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(2);
    wb.packInt(this.error);
    wb.packBytes(this.buffer);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.error = rb.unpackInt();
    if (--c <= 0) { return; }
    this.buffer = rb.unpackBytes();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  response create() { return response(); }

}



