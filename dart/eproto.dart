library eproto;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// 在对面协议发送null的值过来时，这边解析的默认值，保持和C++的一致
final bool _defaultBool = false;
final int _defaultInt = 0;
final double _defaultDouble = 0;
final String _defaultString = "";
final Uint8List _defaultBytes = Uint8List(0);

final int _kScratchSizeInitial = 128;
final int _kScratchSizeRegular = 1024;

class FormatError implements Exception {
  FormatError(this.message);
  final String message;

  String toString() {
    return "FormatError: $message";
  }
}

class DataWriter
{
  void packNil(){
    _writeUint8(0xc0);
  }
  void packBool(bool b){
    if(b == true){
      _writeUint8(0xc3);
    }else{
      _writeUint8(0xc2);
    }
  }
  void packInt(int n){
    if(n >= 0){
      if (n >= -32) {
        _writeInt8(n);
      } else if (n >= -128) {
        _writeUint8(0xd0);
        _writeInt8(n);
      } else if (n >= -32768) {
        _writeUint8(0xd1);
        _writeInt16(n);
      } else if (n >= -2147483648) {
        _writeUint8(0xd2);
        _writeInt32(n);
      } else {
        _writeUint8(0xd3);
        _writeInt64(n);
      }
    }else{
      if (n <= 127) {
        _writeUint8(n);
      } else if (n <= 0xFF) {
        _writeUint8(0xcc);
        _writeUint8(n);
      } else if (n <= 0xFFFF) {
        _writeUint8(0xcd);
        _writeUint16(n);
      } else if (n <= 0xFFFFFFFF) {
        _writeUint8(0xce);
        _writeUint32(n);
      } else {
        _writeUint8(0xcf);
        _writeUint64(n);
      }
    }
  }
  void packFloat(double n){
    _writeUint8(0xca);
    _writeFloat32(n);
  }
  void packDouble(double n){
    _writeUint8(0xcb);
    _writeFloat64(n);
  }
  void packString(String s){
    final encoded = _codec.encode(s);
    final length = encoded.length;
    if (length <= 31) {
      _writeUint8(0xA0 | length);
    } else if (length <= 0xFF) {
      _writeUint8(0xd9);
      _writeUint8(length);
    } else if (length <= 0xFFFF) {
      _writeUint8(0xda);
      _writeUint16(length);
    } else if (length <= 0xFFFFFFFF) {
      _writeUint8(0xdb);
      _writeUint32(length);
    } else {
      throw FormatError("String is too long to be serialized with msgpack.");
    }
    _writeBytes(encoded);
  }
  void packBytes(Uint8List buffer){
    final length = buffer.length;
    if (length <= 0xFF) {
      _writeUint8(0xc4);
      _writeUint8(length);
    } else if (length <= 0xFFFF) {
      _writeUint8(0xc5);
      _writeUint16(length);
    } else if (length <= 0xFFFFFFFF) {
      _writeUint8(0xc6);
      _writeUint32(length);
    } else {
      throw FormatError("Data is too long to be serialized with msgpack.");
    }
    _writeBytes(buffer);
  }
  void packArrayHead(int length){
    if (length <= 0xF) {
      _writeUint8(0x90 | length);
    } else if (length <= 0xFFFF) {
      _writeUint8(0xdc);
      _writeUint16(length);
    } else if (length <= 0xFFFFFFFF) {
      _writeUint8(0xdd);
      _writeUint32(length);
    } else {
      throw FormatError("Array is too big to be serialized with msgpack");
    }
  }
  void packMapHead(int length){
    if (length <= 0xF) {
      _writeUint8(0x80 | length);
    } else if (length <= 0xFFFF) {
      _writeUint8(0xde);
      _writeUint16(length);
    } else if (length <= 0xFFFFFFFF) {
      _writeUint8(0xdf);
      _writeUint32(length);
    } else {
      throw FormatError("Map is too big to be serialized with msgpack");
    }
  }

  void _writeUint8(int i) {
    _ensureSize(1);
    _scratchData.setUint8(_scratchOffset, i);
    _scratchOffset += 1;
  }
  void _writeInt8(int i) {
    _ensureSize(1);
    _scratchData.setInt8(_scratchOffset, i);
    _scratchOffset += 1;
  }
  void _writeUint16(int i, [Endian endian = Endian.big]) {
    _ensureSize(2);
    _scratchData.setUint16(_scratchOffset, i, endian);
    _scratchOffset += 2;
  }
  void _writeInt16(int i, [Endian endian = Endian.big]) {
    _ensureSize(2);
    _scratchData.setInt16(_scratchOffset, i, endian);
    _scratchOffset += 2;
  }
  void _writeUint32(int i, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _scratchData.setUint32(_scratchOffset, i, endian);
    _scratchOffset += 4;
  }
  void _writeInt32(int i, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _scratchData.setInt32(_scratchOffset, i, endian);
    _scratchOffset += 4;
  }
  void _writeUint64(int i, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _scratchData.setUint64(_scratchOffset, i, endian);
    _scratchOffset += 8;
  }
  void _writeInt64(int i, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _scratchData.setInt64(_scratchOffset, i, endian);
    _scratchOffset += 8;
  }
  void _writeFloat32(double f, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _scratchData.setFloat32(_scratchOffset, f, endian);
    _scratchOffset += 4;
  }
  void _writeFloat64(double f, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _scratchData.setFloat64(_scratchOffset, f, endian);
    _scratchOffset += 8;
  }
  // The list may be retained until takeBytes is called
  void _writeBytes(List<int> bytes) {
    final length = bytes.length;
    if (length == 0) {
      return;
    }
    _ensureSize(length);
    if (_scratchOffset == 0) {
      // we can add it directly
      _builder.add(bytes);
    } else {
      // there is enough room in _scratchBuffer, otherwise _ensureSize
      // would have added _scratchBuffer to _builder and _scratchOffset would
      // be 0
      if (bytes is Uint8List) {
        _scratchBuffer.setRange(_scratchOffset, _scratchOffset + length, bytes);
      } else {
        for (int i = 0; i < length; i++) {
          _scratchBuffer[_scratchOffset + i] = bytes[i];
        }
      }
      _scratchOffset += length;
    }
  }

  // 获取最终写入数据的字符串数组，同时清理
  Uint8List takeBytes() {
    if (_builder.isEmpty) {
      // Just take scratch data
      final res = Uint8List.view(
        _scratchBuffer.buffer,
        _scratchBuffer.offsetInBytes,
        _scratchOffset,
      );
      _scratchOffset = 0;
      _scratchBuffer = null;
      _scratchData = null;
      return res;
    } else {
      _appendScratchBuffer();
      return _builder.takeBytes();
    }
  }

  void _ensureSize(int size) {
    if (_scratchBuffer == null) {
      // start with small scratch buffer, expand to regular later if needed
      _scratchBuffer = Uint8List(_kScratchSizeInitial);
      _scratchData =
          ByteData.view(_scratchBuffer.buffer, _scratchBuffer.offsetInBytes);
    }
    final remaining = _scratchBuffer.length - _scratchOffset;
    if (remaining < size) {
      _appendScratchBuffer();
    }
  }
  void _appendScratchBuffer() {
    if (_scratchOffset > 0) {
      if (_builder.isEmpty) {
        // We're still on small scratch buffer, move it to _builder
        // and create regular one
        _builder.add(Uint8List.view(
          _scratchBuffer.buffer,
          _scratchBuffer.offsetInBytes,
          _scratchOffset,
        ));
        _scratchBuffer = Uint8List(_kScratchSizeRegular);
        _scratchData =
            ByteData.view(_scratchBuffer.buffer, _scratchBuffer.offsetInBytes);
      } else {
        _builder.add(
          Uint8List.fromList(
            Uint8List.view(
              _scratchBuffer.buffer,
              _scratchBuffer.offsetInBytes,
              _scratchOffset,
            ),
          ),
        );
      }
      _scratchOffset = 0;
    }
  }

  final _builder = BytesBuilder(copy: false);
  final _codec = Utf8Codec();

  Uint8List _scratchBuffer;
  ByteData _scratchData;
  int _scratchOffset = 0;
}

class DataReader
{
  DataReader(Uint8List list, {bool copyBinary=true}) :
    _list = list,
    _data = ByteData.view(list.buffer, list.offsetInBytes),
    copyBinaryData = copyBinary;

  bool unpackBool(){
    int t = moveNext();
    switch(t){
      case 0xc0:{ return _defaultBool; }
      case 0xc2:{ return false; }
      case 0xc3:{ return true; }
      default:{
        throw FormatError("unpackBool wrong type t = " + t.toString());
      }
    }
  }
  int unpackInt(){
    int t = moveNext();
    // null
    if(t == 0xc0){
      return _defaultInt;
    }
    // fixint
    if (t < 0x80){
      return t;
    }
    // fixint_negative
    if (t > 0xdf){
      return (256 - t) * -1;
    }
    switch(t){
      // int8
      case 0xd0:{
        if(left() < 1){
          throw FormatError("unpackInt int8 failed t = " + t.toString());
        }
        return _readInt8();
      }
      // int16
      case 0xd1:{
        if(left() < 2){
          throw FormatError("unpackInt int16 failed t = " + t.toString());
        }
        return _readInt16();
      }
      // int32
      case 0xd2:{
        if(left() < 4){
          throw FormatError("unpackInt int32 failed t = " + t.toString());
        }
        return _readInt32();
      }
      // int64
      case 0xd3:{
        if(left() < 8){
          throw FormatError("unpackInt int64 failed t = " + t.toString());
        }
        return _readInt64();
      }
      // uint8
      case 0xcc:{
        if(left() < 1){
          throw FormatError("unpackInt uint8 failed t = " + t.toString());
        }
        return _readUInt8();
      }
      // uint16
      case 0xcd:{
        if(left() < 2){
          throw FormatError("unpackInt uint16 failed t = " + t.toString());
        }
        return _readUInt16();
      }
      // uint
      case 0xce:{
        if(left() < 4){
          throw FormatError("unpackInt uint32 failed t = " + t.toString());
        }
        return _readUInt32();
      }
      // uint64
      case 0xcf:{
        if(left() < 8){
          throw FormatError("unpackInt uint64 failed t = " + t.toString());
        }
        return _readUInt64();
      }
      default:{
        throw FormatError("unknown int t = " + t.toString());
      }
    }
  }
  double unpackDouble(){
    int t = moveNext();
    switch(t){
      // null
      case 0xc0:{
        return _defaultDouble;
      }
      // float
      case 0xca:{
        if(left() < 4){
          throw FormatError("unpackDouble float failed t = " + t.toString());
        }
        return _readFloat();
      }
      case 0xcb:{
        if(left() < 8){
          throw FormatError("unpackDouble double failed t = " + t.toString());
        }
        return _readDouble();
      }
      default:{
        throw FormatError("unpackDouble unknown double t = " + t.toString());
      }
    }
  }
  String unpackString(){
    int t = moveNext();
    if(t == 0xc0){
      return _defaultString;
    }
    // fixed string
    if (t > 0x9f && t < 0xc0){
      int length = t & 0x1f;
      if (left() < length){
        throw FormatError("unpackString fixed string failed t = " + t.toString());
      }
      return _readString(length);
    }
    switch(t){
      // str8
      case 0xd9:{
        if (left() < 1){
          throw FormatError("unpackString str8 length failed t = " + t.toString());
        }
        int length = _readUInt8();
        if(left() < length){
          throw FormatError("unpackString str8 failed t = " + t.toString());
        }
        return _readString(length);
      }
      // str16
      case 0xda:{
        if (left() < 2){
          throw FormatError("unpackString str16 length failed t = " + t.toString());
        }
        int length = _readUInt16();
        if(left() < length){
          throw FormatError("unpackString str16 failed t = " + t.toString());
        }
        return _readString(length);
      }
      // str32
      case 0xdb:{
        if (left() < 4){
          throw FormatError("unpackString str32 length failed t = " + t.toString());
        }
        int length = _readUInt32();
        if(left() < length){
          throw FormatError("unpackString str32 failed t = " + t.toString());
        }
        return _readString(length);
      }
      default:{
        throw FormatError("unpackString unknown t = " + t.toString());
      }
    }
  }
  Uint8List unpackBytes(){
    int t = moveNext();
    if(t == 0xc0){
      if(_defaultBytes == null){
        return null;
      }
      return Uint8List.fromList(_defaultBytes);
    }
    switch(t){
      // bin8
      case 0xc4:{
        if (left() < 1){
          throw FormatError("unpackBytes bin8 length failed t = " + t.toString());
        }
        int length = _readUInt8();
        if(left() < length){
          throw FormatError("unpackBytes bin8 failed t = " + t.toString());
        }
        return _readBuffer(length);
      }
      // bin16
      case 0xc5:{
        if (left() < 2){
          throw FormatError("unpackBytes bin16 length failed t = " + t.toString());
        }
        int length = _readUInt16();
        if(left() < length){
          throw FormatError("unpackBytes bin16 failed t = " + t.toString());
        }
        return _readBuffer(length);
      }
      // bin32
      case 0xc6:{
        if (left() < 4){
          throw FormatError("unpackBytes bin32 length failed t = " + t.toString());
        }
        int length = _readUInt32();
        if(left() < length){
          throw FormatError("unpackBytes bin32 failed t = " + t.toString());
        }
        return _readBuffer(length);
      }
      default:{
        throw FormatError("unpackBytes unknown t = " + t.toString());
      }
    }
  }
  int unpackArrayHead(){
    int t = moveNext();
    if(t == 0xc0){
      return -1;
    }
    if (t > 0x8f && t < 0xa0){
      int length = t & 0xf;
      return length;
    }
    switch(t){
      // array16
      case 0xdc:{
        if (left() < 2){
          throw FormatError("unpackArrayHead array16 length failed t = " + t.toString());
        }
        return _readUInt16();
      }
      // array32
      case 0xdd:{
        if (left() < 4){
          throw FormatError("unpackArrayHead array16 length failed t = " + t.toString());
        }
        return _readUInt32();
      }
      default:{
        throw FormatError("unpackArrayHead unknown t = " + t.toString());
      }
    }
  }
  int unpackMapHead(){
    int t = moveNext();
    if(t == 0xc0){
      return -1;
    }
    if (t > 0x7f && t < 0x90){
      int length = t & 0xf;
      return length;
    }
    switch(t){
      // map16
      case 0xde:{
        if (left() < 2){
          throw FormatError("unpackMapHead map16 length failed t = " + t.toString());
        }
        return _readUInt16();
      }
      // map32
      case 0xdf:{
        if (left() < 4){
          throw FormatError("unpackMapHead map32 length failed t = " + t.toString());
        }
        return _readUInt32();
      }
      default:{
        throw FormatError("unpackMapHead unknown t = " + t.toString());
      }
    }
  }
  void unpackDiscard(int length){
    if(length <= 0){
      return;
    }
    for(int i=0; i<length; ++i){
      discard();
    }
  }
  void discard(){
    if(left() < 1){
      return;
    }
    int t = moveNext();
    // positive fixint
    if (t < 0x80){
      return;
    }
    // fixstr
    if (t > 0x9f && t < 0xc0){
      int length = t & 0x1f;
      if (left() < length)
      {
        throw FormatError("discard fixstr length failed t = " + t.toString());
      }
      _moveOffset(length);
      return;
    }
    // fixmap
    if (t > 0x7f && t < 0x90){
      int length = t & 0xf;
      unpackDiscard(length * 2);
      return;
    }
    // fixarray
    if (t > 0x8f && t < 0xa0){
      int length = t & 0xf;
      unpackDiscard(length);
      return;
    }
    // negative fixint
    if (t > 0xdf){
      return;
    }
    switch(t){
      // null
      case 0xc0:{
        return;
      }
      // false
      case 0xc2:{
        return;
      }
      // true
      case 0xc3:{
        return;
      }
      // uint8
      case 0xcc:{
        _moveOffset(1);
        return;
      }
      // uint16
      case 0xcd:{
        if (left() < 2){
          throw FormatError("discard uint16 length failed t = " + t.toString());
        }
        _moveOffset(2);
        return;
      }
      // uint32
      case 0xce:{
        if (left() < 4){
          throw FormatError("discard uint32 length failed t = " + t.toString());
        }
        _moveOffset(4);
        return;
      }
      // uint64
      case 0xcf:{
        if (left() < 8){
          throw FormatError("discard uint64 length failed t = " + t.toString());
        }
        _moveOffset(8);
        return;
      }
      // int8
      case 0xd0:{
        if (left() < 1){
          throw FormatError("discard int8 length failed t = " + t.toString());
        }
        _moveOffset(1);
        return;
      }
      // int16
      case 0xd1:{
        if (left() < 2){
          throw FormatError("discard int16 length failed t = " + t.toString());
        }
        _moveOffset(2);
        return;
      }
      // int32
      case 0xd2:{
        if (left() < 4){
          throw FormatError("discard int32 length failed t = " + t.toString());
        }
        _moveOffset(4);
        return;
      }
      // int64
      case 0xd3:{
        if (left() < 8){
          throw FormatError("discard int64 length failed t = " + t.toString());
        }
        _moveOffset(8);
        return;
      }
      // str8
      case 0xd9:{
        if (left() < 1){
          throw FormatError("discard str8 length failed t = " + t.toString());
        }
        int length = _readUInt8();
        if (left() < length){
          throw FormatError("discard str8 failed t = " + t.toString());
        }
        _moveOffset(length);
        return;
      }
      // str16
      case 0xda:{
        if (left() < 2){
          throw FormatError("discard str16 length failed t = " + t.toString());
        }
        int length = _readUInt16();
        if (left() < length){
          throw FormatError("discard str16 failed t = " + t.toString());
        }
        _moveOffset(length);
        return;
      }
      // str32
      case 0xdb:{
        if (left() < 4){
          throw FormatError("discard str32 length failed t = " + t.toString());
        }
        int length = _readUInt32();
        if (left() < length){
          throw FormatError("discard str32 failed t = " + t.toString());
        }
        _moveOffset(length);
        return;
      }
      // float
      case 0xca:{
        if (left() < 4){
          throw FormatError("discard float length failed t = " + t.toString());
        }
        _moveOffset(4);
        return;
      }
      // double
      case 0xcb:{
        if (left() < 8){
          throw FormatError("discard double length failed t = " + t.toString());
        }
        _moveOffset(8);
        return;
      }
      // array16
      case 0xdc:{
        if (left() < 2){
          throw FormatError("discard array16 length failed t = " + t.toString());
        }
        int length = _readUInt16();
        unpackDiscard(length);
        return;
      }
      // array32
      case 0xdd:{
        if (left() < 4){
          throw FormatError("discard array32 length failed t = " + t.toString());
        }
        int length = _readUInt32();
        unpackDiscard(length);
        return;
      }
      // map16
      case 0xde:{
        if (left() < 2){
          throw FormatError("discard map16 length failed t = " + t.toString());
        }
        int length = _readUInt16();
        unpackDiscard(length * 2);
        return;
      }
      // map32
      case 0xdf:{
        if (left() < 4){
          throw FormatError("discard map32 length failed t = " + t.toString());
        }
        int length = _readUInt32();
        unpackDiscard(length * 2);
        return;
      }
      // bin8
      case 0xc4:{
        if (left() < 1){
          throw FormatError("discard bin8 length failed t = " + t.toString());
        }
        int length = _readUInt8();
        if (left() < length){
          throw FormatError("discard bin8 failed t = " + t.toString());
        }
        _moveOffset(length);
        return;
      }
      // bin16
      case 0xc5:{
        if (left() < 2){
          throw FormatError("discard bin16 length failed t = " + t.toString());
        }
        int length = _readUInt16();
        if (left() < length){
          throw FormatError("discard bin16 failed t = " + t.toString());
        }
        _moveOffset(length);
        return;
      }
      // bin32
      case 0xc6:{
        if (left() < 4){
          throw FormatError("discard bin32 length failed t = " + t.toString());
        }
        int length = _readUInt32();
        if (left() < length){
          throw FormatError("discard bin32 failed t = " + t.toString());
        }
        _moveOffset(length);
        return;
      }
      default:{
        throw FormatError("discard unknown t = " + t.toString());
      }
    }
  }

  bool nextIsNil(){
    return (_data.getUint8(_offset) == 0xc0);
  }
  int left(){
    return _list.lengthInBytes - _offset;
  }
  int moveNext(){
    return _data.getUint8(_offset++);
  }
  void _moveOffset(int length){
    _offset+= length;
  }
  int _readInt8() {
    return _data.getInt8(_offset++);
  }
  int _readUInt8() {
    return _data.getUint8(_offset++);
  }
  int _readUInt16() {
    final res = _data.getUint16(_offset);
    _offset += 2;
    return res;
  }
  int _readInt16() {
    final res = _data.getInt16(_offset);
    _offset += 2;
    return res;
  }
  int _readUInt32() {
    final res = _data.getUint32(_offset);
    _offset += 4;
    return res;
  }
  int _readInt32() {
    final res = _data.getInt32(_offset);
    _offset += 4;
    return res;
  }
  int _readUInt64() {
    final res = _data.getUint64(_offset);
    _offset += 8;
    return res;
  }
  int _readInt64() {
    final res = _data.getInt64(_offset);
    _offset += 8;
    return res;
  }
  double _readFloat() {
    final res = _data.getFloat32(_offset);
    _offset += 4;
    return res;
  }
  double _readDouble() {
    final res = _data.getFloat64(_offset);
    _offset += 8;
    return res;
  }
  Uint8List _readBuffer(int length) {
    final res = Uint8List.view(_list.buffer, _list.offsetInBytes + _offset, length);
    _offset += length;
    return copyBinaryData ? Uint8List.fromList(res) : res;
  }
  String _readString(int length) {
    final list = _readBuffer(length);
    final len = list.length;
    for (int i = 0; i < len; ++i) {
      if (list[i] > 127) {
        return codec.decode(list);
      }
    }
    return String.fromCharCodes(list);
  }

  final codec = Utf8Codec();
  final Uint8List _list;
  final ByteData _data;
  final bool copyBinaryData;
  int _offset = 0;
}

