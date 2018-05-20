/*!{id:eproto.js,ver:1.05,license:"MIT",author:"uupaa.js@gmail.com"}*/

// === eproto ===
// MessagePack -> http://eproto.sourceforge.net/

this.eproto || (function(globalScope) {

globalScope.eproto = {
    pack:       eprotopack,     // eproto.pack(data:Mix,
                                //              toString:Boolean = false):ByteArray/ByteString/false
                                //  [1][mix to String]    eproto.pack({}, true) -> "..."
                                //  [2][mix to ByteArray] eproto.pack({})       -> [...]
    unpack:     eprotounpack,   // eproto.unpack(data:BinaryString/ByteArray):Mix
                                //  [1][String to mix]    eproto.unpack("...") -> {}
                                //  [2][ByteArray to mix] eproto.unpack([...]) -> {}
    register:   eprotoregister,
    encode:     eprotoencode,
    decode:     eprotodecode,
};

var _ie         = /MSIE/.test(navigator.userAgent),
    _bin2num    = {}, // BinaryStringToNumber   { "\00": 0, ... "\ff": 255 }
    _num2bin    = {}, // NumberToBinaryString   { 0: "\00", ... 255: "\ff" }
    _num2b64    = ("ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
                   "abcdefghijklmnopqrstuvwxyz0123456789+/").split(""),
    _buf        = [], // decode buffer
    _idx        = 0,  // decode buffer[index]
    _error      = 0,  // eproto.pack() error code. 1 = CYCLIC_REFERENCE_ERROR
    _isArray    = Array.isArray || (function(mix) {
                    return Object.prototype.toString.call(mix) === "[object Array]";
                  }),
    _isArrayBuffer = function(mix){
                    return Object.prototype.toString.call(mix) === "[object ArrayBuffer]";
                },
    _isUint8Array = function(mix) {
                    return Object.prototype.toString.call(mix) === "[object Uint8Array]";
                  },
    _toString   = String.fromCharCode, // CharCode/ByteArray to String
    _proto      = {},
    _MAX_DEPTH  = 512;

function eprotoregister(name, info){
	_proto[name] = info;
}

function eprotoencode(name, tab){
     var arr = copyArray(name, tab);
     return eprotopack(arr);
}
function eprotodecode(name, buf){
	var arr = eprotounpack(buf);
    return copyTable(name, arr);
}

function copyArray(name, tab){
    var info = _proto[name];
    if (typeof info === "undefined"){
        throw new Error("can not find proto "+name);
    }
    var arr = new Array(info.length);
    // 获取info中的所以数据，保存到数组中
    for(var i=0,il=info.length; i<il; ++i){
        var key = info[i];  // 0type,1index,2name,3type/proto name,4map value
        var value = tab[key[2]];
        var t = typeof value;
        if(t === "undefined"){
            arr[key[1]] = null;
            continue;
        }
        switch(key[0]){
//				case 1:{    // ep_type_nil
//					break;
//				}
            case 2:{    // ep_type_bool
                if(t === "boolean"){
                    arr[key[1]] = value;
                }else{
                    throw new Error("type error boolean in proto "+name+" "+key[2]+" get "+t);
                }
                break;
            }
            case 3:     // ep_type_float
            case 4:{    // ep_type_int
                if(t === "number"){
                    arr[key[1]] = value;
                }else{
                    throw new Error("type error number in proto "+name+" "+key[2]+" get "+t);
                }
                break;
            }
            case 5:{    // ep_type_string
                if(t === "string"){
                    arr[key[1]] = value;
                }else{
                    throw new Error("type error string in proto "+name+" "+key[2]+" get "+t);
                }
                break;
            }
            case 6:{    // ep_type_array
                if(t === "object"){
                    if(typeof key[3] === "string"){   // proto
                        var a = new Array(value.length);
                        for(var j=0,vl=value.length; j<vl; ++j){
                            a[j] = copyArray(key[3], value[j]);
                        }
                        arr[key[1]] = a;
                    }else{
                        arr[key[1]] = value;
                    }
                }else{
                    throw new Error("type error array in proto "+name+" "+key[2]+" get "+t);
                }
                break;
            }
            case 7:{    // ep_type_map
                if(t === "object"){
                    if(typeof key[4] === "string"){   // proto
                        var a = {};
                        for(var j in value){
                            a[j] = copyArray(key[4], value[j]);
                        }
                        arr[key[1]] = a;
                    }else{
                        arr[key[1]] = value;
                    }
                }else{
                    throw new Error("type error map in proto "+name+" "+key[2]+" get "+t);
                }
                break;
            }
            case 8:{    // ep_type_message
                if(t === "object"){
				    arr[key[1]] = copyArray(key[3], value);
				}else{
				    throw new Error("type error message in proto "+name+" "+key[2]+" get "+t);
				}
                break;
            }
            default:{
                throw new Error("unknown type in proto "+name+" "+key[2]+" get "+key[0]);
            }
        }
    }
    return arr;
}

function copyTable(name, arr){
    var info = _proto[name];
    if (typeof info === "undefined"){
        throw new Error("can not find proto "+name);
    }
    var tab = {};
    for(var i=0,il=info.length; i<il; ++i){
        var key = info[i];  // 0type,1index,2name,3type/proto name,4map value
        var value = arr[key[1]];
        var t = typeof value;
        if(t === "undefined" || value === null){
            continue;
        }
        switch(key[0]){
//				case 1:{    // ep_type_nil
//					break;
//				}
            case 2:{    // ep_type_bool
                if(t === "boolean"){
                    tab[key[2]] = value;
                }else{
                    throw new Error("type error boolean in proto "+name+" "+key[2]+" get "+t);
                }
                break;
            }
            case 3:     // ep_type_float
            case 4:{    // ep_type_int
                if(t === "number"){
                    tab[key[2]] = value;
                }else{
                    throw new Error("type error number in proto "+name+" "+key[2]+" get "+t);
                }
                break;
            }
            case 5:{    // ep_type_string
                if(t === "string"){
                    tab[key[2]] = value;
                }else{
                    throw new Error("type error string in proto "+name+" "+key[2]+" get "+t);
                }
                break;
            }
            case 6:{    // ep_type_array
                if(t === "object"){
                    var key3 = key[3];
                    if(typeof key3 === "string"){   // proto
                        var a = new Array(value.length);
                        for(var j=0,vl=value.length; j<vl; ++j){
                            a[j] = copyTable(key3, value[j]);
                        }
                        tab[key[2]] = a;
                    }else{
                        tab[key[2]] = value;
                    }
                 }else{
                     throw new Error("type error array in proto "+name+" "+key[2]+" get "+t);
                 }
                break;
            }
            case 7:{    // ep_type_map
                if(t === "object"){
                    var key4 = key[4];
                    if(typeof key4 === "string"){   // proto
                        var a = {};
                        for(var j in value){
                            a[j] = copyTable(key4, value[j]);
                        }
                        tab[key[2]] = a;
                    }else{
                        tab[key[2]] = value;
                    }
                 }else{
                     throw new Error("type error map in proto "+name+" "+key[2]+" get "+t);
                 }
                break;
            }
            case 8:{    // ep_type_message
                if(t === "object"){
                     tab[key[2]] = copyTable(key[3], value);
                 }else{
                     throw new Error("type error message in proto "+name+" "+key[2]+" get "+t);
                 }
                break;
            }
            default:{
                throw new Error("unknown type in proto "+name+" "+key[2]+" get "+key[0]);
            }
        }
    }
    return tab;
}

// eproto.pack
function eprotopack(data,       // @param Mix:
                     toString) { // @param Boolean(= false):
                                 // @return ByteArray/BinaryString/false:
                                 //     false is error return
    //  [1][mix to String]    eproto.pack({}, true) -> "..."
    //  [2][mix to ByteArray] eproto.pack({})       -> [...]

    _error = 0;

    var byteArray = encode([], data, 0);

    return _error ? false
                  : toString ? byteArrayToByteString(byteArray)
                             : byteArrayToUint8Array(byteArray);
}

// eproto.unpack
function eprotounpack(data) { // @param BinaryString/ByteArray:
                               // @return Mix/undefined:
                               //       undefined is error return
    //  [1][String to mix]    eproto.unpack("...") -> {}
    //  [2][ByteArray to mix] eproto.unpack([...]) -> {}
    _buf = typeof data === "string" ? toByteArray(data) : toUint8Array(data);
    _idx = -1;
    return decode(); // mix or undefined
}

// inner - encoder
function encode(rv,      // @param ByteArray: result
                mix,     // @param Mix: source data
                depth) { // @param Number: depth
    var size, i, iz, c, pos,        // for UTF8.encode, Array.encode, Hash.encode
        high, low, sign, exp, frac; // for IEEE754

    if (mix == null) { // null or undefined -> 0xc0 ( null )
        rv.push(0xc0);
    } else if (mix === false) { // false -> 0xc2 ( false )
        rv.push(0xc2);
    } else if (mix === true) {  // true  -> 0xc3 ( true  )
        rv.push(0xc3);
    } else {
        switch (typeof mix) {
        case "number":
            if (mix !== mix) { // isNaN
                rv.push(0xcb, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff); // quiet NaN
            } else if (mix === Infinity) {
                rv.push(0xcb, 0x7f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00); // positive infinity
            } else if (Math.floor(mix) === mix) { // int or uint
                if (mix < 0) {
                    // int
                    if (mix >= -32) { // negative fixnum
                        rv.push(0xe0 + mix + 32);
                    } else if (mix > -0x80) {
                        rv.push(0xd0, mix + 0x100);
                    } else if (mix > -0x8000) {
                        mix += 0x10000;
                        rv.push(0xd1, mix >> 8, mix & 0xff);
                    } else if (mix > -0x80000000) {
                        mix += 0x100000000;
                        rv.push(0xd2, mix >>> 24, (mix >> 16) & 0xff,
                                                  (mix >>  8) & 0xff, mix & 0xff);
                    } else {
                        high = Math.floor(mix / 0x100000000);
                        low  = mix & 0xffffffff;
                        rv.push(0xd3, (high >> 24) & 0xff, (high >> 16) & 0xff,
                                      (high >>  8) & 0xff,         high & 0xff,
                                      (low  >> 24) & 0xff, (low  >> 16) & 0xff,
                                      (low  >>  8) & 0xff,          low & 0xff);
                    }
                } else {
                    // uint
                    if (mix < 0x80) {
                        rv.push(mix); // positive fixnum
                    } else if (mix < 0x100) { // uint 8
                        rv.push(0xcc, mix);
                    } else if (mix < 0x10000) { // uint 16
                        rv.push(0xcd, mix >> 8, mix & 0xff);
                    } else if (mix < 0x100000000) { // uint 32
                        rv.push(0xce, mix >>> 24, (mix >> 16) & 0xff,
                                                  (mix >>  8) & 0xff, mix & 0xff);
                    } else {
                        high = Math.floor(mix / 0x100000000);
                        low  = mix & 0xffffffff;
                        rv.push(0xcf, (high >> 24) & 0xff, (high >> 16) & 0xff,
                                      (high >>  8) & 0xff,         high & 0xff,
                                      (low  >> 24) & 0xff, (low  >> 16) & 0xff,
                                      (low  >>  8) & 0xff,          low & 0xff);
                    }
                }
            } else { // double
                // THX!! @edvakf
                // http://javascript.g.hatena.ne.jp/edvakf/20101128/1291000731
                sign = mix < 0;
                sign && (mix *= -1);

                // add offset 1023 to ensure positive
                // 0.6931471805599453 = Math.LN2;
                exp  = ((Math.log(mix) / 0.6931471805599453) + 1023) | 0;

                // shift 52 - (exp - 1023) bits to make integer part exactly 53 bits,
                // then throw away trash less than decimal point
                frac = mix * Math.pow(2, 52 + 1023 - exp);

                //  S+-Exp(11)--++-----------------Fraction(52bits)-----------------------+
                //  ||          ||                                                        |
                //  v+----------++--------------------------------------------------------+
                //  00000000|00000000|00000000|00000000|00000000|00000000|00000000|00000000
                //  6      5    55  4        4        3        2        1        8        0
                //  3      6    21  8        0        2        4        6
                //
                //  +----------high(32bits)-----------+ +----------low(32bits)------------+
                //  |                                 | |                                 |
                //  +---------------------------------+ +---------------------------------+
                //  3      2    21  1        8        0
                //  1      4    09  6
                low  = frac & 0xffffffff;
                sign && (exp |= 0x800);
                high = ((frac / 0x100000000) & 0xfffff) | (exp << 20);

                rv.push(0xcb, (high >> 24) & 0xff, (high >> 16) & 0xff,
                              (high >>  8) & 0xff,  high        & 0xff,
                              (low  >> 24) & 0xff, (low  >> 16) & 0xff,
                              (low  >>  8) & 0xff,  low         & 0xff);
            }
            break;
        case "string":
            // http://d.hatena.ne.jp/uupaa/20101128
            iz = mix.length;
            pos = rv.length; // keep rewrite position

            rv.push(0); // placeholder

            // utf8.encode
            for (i = 0; i < iz; ++i) {
                c = mix.charCodeAt(i);
                if (c < 0x80) { // ASCII(0x00 ~ 0x7f)
                    rv.push(c & 0x7f);
                } else if (c < 0x0800) {
                    rv.push(((c >>>  6) & 0x1f) | 0xc0, (c & 0x3f) | 0x80);
                } else if (c < 0x10000) {
                    rv.push(((c >>> 12) & 0x0f) | 0xe0,
                            ((c >>>  6) & 0x3f) | 0x80, (c & 0x3f) | 0x80);
                }
            }
            size = rv.length - pos - 1;

            if (size < 32) {
                rv[pos] = 0xa0 + size; // rewrite
            } else if (size < 0x100) { // 8
                rv.splice(pos, 1, 0xd9, size);
            } else if (size < 0x10000) { // 16
                rv.splice(pos, 1, 0xda, size >> 8, size & 0xff);
            } else if (size < 0x100000000) { // 32
                rv.splice(pos, 1, 0xdb,
                          size >>> 24, (size >> 16) & 0xff,
                                       (size >>  8) & 0xff, size & 0xff);
            }
            break;
        default: // array, hash, or Uint8Array
            if (_isUint8Array(mix)) {
                size = mix.length;

                if (size < 0x100) { // 8
                    rv.push(0xc4, size);
                } else if (size < 0x10000) { // 16
                    rv.push(0xc5, size >> 8, size & 0xff);
                } else if (size < 0x100000000) { // 32
                    rv.push(0xc6, size >>> 24, (size >> 16) & 0xff,
                            (size >>  8) & 0xff, size & 0xff);
                }
                Array.prototype.push.apply(rv, mix);
                break;
            }
            if (++depth >= _MAX_DEPTH) {
                _error = 1; // CYCLIC_REFERENCE_ERROR
                return rv = []; // clear
            }
            if (_isArray(mix)) {
                size = mix.length;
                if (size < 16) {
                    rv.push(0x90 + size);
                } else if (size < 0x10000) { // 16
                    rv.push(0xdc, size >> 8, size & 0xff);
                } else if (size < 0x100000000) { // 32
                    rv.push(0xdd, size >>> 24, (size >> 16) & 0xff,
                                               (size >>  8) & 0xff, size & 0xff);
                }
                for (i = 0; i < size; ++i) {
                    encode(rv, mix[i], depth);
                }
            } else { // hash
                // http://d.hatena.ne.jp/uupaa/20101129
                pos = rv.length; // keep rewrite position
                rv.push(0); // placeholder
                size = 0;
                for (i in mix) {
                    ++size;
                    encode(rv, i,      depth);
                    encode(rv, mix[i], depth);
                }
                if (size < 16) {
                    rv[pos] = 0x80 + size; // rewrite
                } else if (size < 0x10000) { // 16
                    rv.splice(pos, 1, 0xde, size >> 8, size & 0xff);
                } else if (size < 0x100000000) { // 32
                    rv.splice(pos, 1, 0xdf,
                              size >>> 24, (size >> 16) & 0xff,
                                           (size >>  8) & 0xff, size & 0xff);
                }
            }
        }
    }
    return rv;
}

// inner - decoder
function decode() { // @return Mix:
    var size, i, iz, c, num = 0,
        sign, exp, frac, ary, hash,
        buf = _buf, type = buf[++_idx];

    if (type >= 0xe0) {             // Negative FixNum (111x xxxx) (-32 ~ -1)
        return type - 0x100;
    }
    if (type < 0xc0) {
        if (type < 0x80) {          // Positive FixNum (0xxx xxxx) (0 ~ 127)
            return type;
        }
        if (type < 0x90) {          // FixMap (1000 xxxx)
            num  = type - 0x80;
            type = 0x80;
        } else if (type < 0xa0) {   // FixArray (1001 xxxx)
            num  = type - 0x90;
            type = 0x90;
        } else { // if (type < 0xc0) {   // FixRaw (101x xxxx)
            num  = type - 0xa0;
            type = 0xa0;
        }
    }
    switch (type) {
    case 0xc0:  return null;
    case 0xc2:  return false;
    case 0xc3:  return true;
    case 0xca:  // float
                num = buf[++_idx] * 0x1000000 + (buf[++_idx] << 16) +
                                                (buf[++_idx] <<  8) + buf[++_idx];
                sign =  num & 0x80000000;    //  1bit
                exp  = (num >> 23) & 0xff;   //  8bits
                frac =  num & 0x7fffff;      // 23bits
                if (!num || num === 0x80000000) { // 0.0 or -0.0
                    return 0;
                }
                if (exp === 0xff) { // NaN or Infinity
                    return frac ? NaN : Infinity;
                }
                return (sign ? -1 : 1) *
                            (frac | 0x800000) * Math.pow(2, exp - 127 - 23); // 127: bias
    case 0xcb:  // double
                num = buf[++_idx] * 0x1000000 + (buf[++_idx] << 16) +
                                                (buf[++_idx] <<  8) + buf[++_idx];
                sign =  num & 0x80000000;    //  1bit
                exp  = (num >> 20) & 0x7ff;  // 11bits
                frac =  num & 0xfffff;       // 52bits - 32bits (high word)
                if (!num || num === 0x80000000) { // 0.0 or -0.0
                    _idx += 4;
                    return 0;
                }
                if (exp === 0x7ff) { // NaN or Infinity
                    _idx += 4;
                    return frac ? NaN : Infinity;
                }
                num = buf[++_idx] * 0x1000000 + (buf[++_idx] << 16) +
                                                (buf[++_idx] <<  8) + buf[++_idx];
                return (sign ? -1 : 1) *
                            ((frac | 0x100000) * Math.pow(2, exp - 1023 - 20) // 1023: bias
                             + num * Math.pow(2, exp - 1023 - 52));
    // 0xcf: uint64, 0xce: uint32, 0xcd: uint16
    case 0xcf:  num =  buf[++_idx] * 0x1000000 + (buf[++_idx] << 16) +
                                                 (buf[++_idx] <<  8) + buf[++_idx];
                return num * 0x100000000 +
                       buf[++_idx] * 0x1000000 + (buf[++_idx] << 16) +
                                                 (buf[++_idx] <<  8) + buf[++_idx];
    case 0xce:  num += buf[++_idx] * 0x1000000 + (buf[++_idx] << 16);
    case 0xcd:  num += buf[++_idx] << 8;
    case 0xcc:  return num + buf[++_idx];
    // 0xd3: int64, 0xd2: int32, 0xd1: int16, 0xd0: int8
    case 0xd3:  num = buf[++_idx];
                if (num & 0x80) { // sign -> avoid overflow
                    return ((num         ^ 0xff) * 0x100000000000000 +
                            (buf[++_idx] ^ 0xff) *   0x1000000000000 +
                            (buf[++_idx] ^ 0xff) *     0x10000000000 +
                            (buf[++_idx] ^ 0xff) *       0x100000000 +
                            (buf[++_idx] ^ 0xff) *         0x1000000 +
                            (buf[++_idx] ^ 0xff) *           0x10000 +
                            (buf[++_idx] ^ 0xff) *             0x100 +
                            (buf[++_idx] ^ 0xff) + 1) * -1;
                }
                return num         * 0x100000000000000 +
                       buf[++_idx] *   0x1000000000000 +
                       buf[++_idx] *     0x10000000000 +
                       buf[++_idx] *       0x100000000 +
                       buf[++_idx] *         0x1000000 +
                       buf[++_idx] *           0x10000 +
                       buf[++_idx] *             0x100 +
                       buf[++_idx];
    case 0xd2:  num  =  buf[++_idx] * 0x1000000 + (buf[++_idx] << 16) +
                       (buf[++_idx] << 8) + buf[++_idx];
                return num < 0x80000000 ? num : num - 0x100000000; // 0x80000000 * 2
    case 0xd1:  num  = (buf[++_idx] << 8) + buf[++_idx];
                return num < 0x8000 ? num : num - 0x10000; // 0x8000 * 2
    case 0xd0:  num  =  buf[++_idx];
                return num < 0x80 ? num : num - 0x100; // 0x80 * 2
    // 0xdb: str32, 0xda: str16, 0xd9: str8, 0xa0: fixstr
    case 0xdb:  num += buf[++_idx] * 0x1000000 + (buf[++_idx] << 16);
    case 0xda:  num += buf[++_idx] << 8;
    case 0xd9:  num += buf[++_idx];
    case 0xa0:  // utf8.decode
                for (ary = [], i = _idx, iz = i + num; i < iz; ) {
                    c = buf[++i]; // lead byte
                    ary.push(c < 0x80 ? c : // ASCII(0x00 ~ 0x7f)
                             c < 0xe0 ? ((c & 0x1f) <<  6 | (buf[++i] & 0x3f)) :
                                        ((c & 0x0f) << 12 | (buf[++i] & 0x3f) << 6
                                                          | (buf[++i] & 0x3f)));
                }
                _idx = i;
                return ary.length < 10240 ? _toString.apply(null, ary)
                                          : byteArrayToByteString(ary);
    // 0xc6: bin32, 0xc5: bin16, 0xc4: bin8
    case 0xc6:  num += buf[++_idx] * 0x1000000 + (buf[++_idx] << 16);
    case 0xc5:  num += buf[++_idx] << 8;
    case 0xc4:  num += buf[++_idx];
                var end = ++_idx + num
                var ret = buf.slice(_idx, end);
                _idx += num;
                return ret;
    // 0xdf: map32, 0xde: map16, 0x80: map
    case 0xdf:  num +=  buf[++_idx] * 0x1000000 + (buf[++_idx] << 16);
    case 0xde:  num += (buf[++_idx] << 8)       +  buf[++_idx];
    case 0x80:  hash = {};
                while (num--) {
                    // make key/value pair
                    size = buf[++_idx] - 0xa0;

                    for (ary = [], i = _idx, iz = i + size; i < iz; ) {
                        c = buf[++i]; // lead byte
                        ary.push(c < 0x80 ? c : // ASCII(0x00 ~ 0x7f)
                                 c < 0xe0 ? ((c & 0x1f) <<  6 | (buf[++i] & 0x3f)) :
                                            ((c & 0x0f) << 12 | (buf[++i] & 0x3f) << 6
                                                              | (buf[++i] & 0x3f)));
                    }
                    _idx = i;
                    hash[_toString.apply(null, ary)] = decode();
                }
                return hash;
    // 0xdd: array32, 0xdc: array16, 0x90: array
    case 0xdd:  num +=  buf[++_idx] * 0x1000000 + (buf[++_idx] << 16);
    case 0xdc:  num += (buf[++_idx] << 8)       +  buf[++_idx];
    case 0x90:  ary = [];
                while (num--) {
                    ary.push(decode());
                }
                return ary;
    }
    return;
}

function byteArrayToUint8Array(byteArray){
	if( _isArray(byteArray) ){
		var i=0, bl = byteArray.length;
		var ui8 = new Uint8Array(bl);
		for(; i<bl; ++i){
			ui8[i] = byteArray[i];
		}
		return ui8;
	}
	return byteArray;
}

// inner - byteArray To ByteString
function byteArrayToByteString(byteArray) { // @param ByteArray
                                            // @return String
    // http://d.hatena.ne.jp/uupaa/20101128
    try {
        return _toString.apply(this, byteArray); // toString
    } catch(err) {
        ; // avoid "Maximum call stack size exceeded"
    }
    var rv = [], i = 0, iz = byteArray.length, num2bin = _num2bin;

    for (; i < iz; ++i) {
        rv[i] = num2bin[byteArray[i]];
    }
    return rv.join("");
}

function toUint8Array(data){
    if( _isArrayBuffer(data) ){
        return new Uint8Array(data);
    }
    return data;
}

// inner - BinaryString To ByteArray
function toByteArray(data) { // @param BinaryString: "\00\01"
                             // @return ByteArray: [0x00, 0x01]
    var rv = [], bin2num = _bin2num, remain,
        ary = data.split(""),
        i = -1, iz;

    iz = ary.length;
    remain = iz % 8;

    while (remain--) {
        ++i;
        rv[i] = bin2num[ary[i]];
    }
    remain = iz >> 3;
    while (remain--) {
        rv.push(bin2num[ary[++i]], bin2num[ary[++i]],
                bin2num[ary[++i]], bin2num[ary[++i]],
                bin2num[ary[++i]], bin2num[ary[++i]],
                bin2num[ary[++i]], bin2num[ary[++i]]);
    }
    return rv;
}

// inner - BinaryString to ByteArray
function toByteArrayIE(xhr) {
    var rv = [], data, remain,
        charCodeAt = "charCodeAt",
        loop, v0, v1, v2, v3, v4, v5, v6, v7,
        i = -1, iz;

    iz = vblen(xhr);
    data = vbstr(xhr);
    loop = Math.ceil(iz / 2);
    remain = loop % 8;

    while (remain--) {
        v0 = data[charCodeAt](++i); // 0x00,0x01 -> 0x0100
        rv.push(v0 & 0xff, v0 >> 8);
    }
    remain = loop >> 3;
    while (remain--) {
        v0 = data[charCodeAt](++i);
        v1 = data[charCodeAt](++i);
        v2 = data[charCodeAt](++i);
        v3 = data[charCodeAt](++i);
        v4 = data[charCodeAt](++i);
        v5 = data[charCodeAt](++i);
        v6 = data[charCodeAt](++i);
        v7 = data[charCodeAt](++i);
        rv.push(v0 & 0xff, v0 >> 8, v1 & 0xff, v1 >> 8,
                v2 & 0xff, v2 >> 8, v3 & 0xff, v3 >> 8,
                v4 & 0xff, v4 >> 8, v5 & 0xff, v5 >> 8,
                v6 & 0xff, v6 >> 8, v7 & 0xff, v7 >> 8);
    }
    iz % 2 && rv.pop();

    return rv;
}

// --- init ---
(function() {
    var i = 0, v;

    for (; i < 0x100; ++i) {
        v = _toString(i);
        _bin2num[v] = i; // "\00" -> 0x00
        _num2bin[i] = v; //     0 -> "\00"
    }
    // http://twitter.com/edvakf/statuses/15576483807
    for (i = 0x80; i < 0x100; ++i) { // [Webkit][Gecko]
        _bin2num[_toString(0xf700 + i)] = i; // "\f780" -> 0x80
    }
})();

_ie && document.write('<script type="text/vbscript">\
Function vblen(b)vblen=LenB(b.responseBody)End Function\n\
Function vbstr(b)vbstr=CStr(b.responseBody)+chr(0)End Function</'+'script>');

})(this);
