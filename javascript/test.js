
alert(temp.publicVar)
temp.publicFun("Hello World!");

//var value = "abc";
var t = typeof value;
console.log(t+" "+(t === "undefined"));
var arr = [1,2,3,4,5];
var v = arr[8];
console.log((typeof v)+" v === null "+(v === null));


var d = {
	game_id : 100,
	game_info : "Hello World!",
	state : 1,
	ss : false
};

var buf = eproto.encode("invitemgr.table_info", d);

var dd = eproto.decode("invitemgr.table_info", buf);

alert(JSON.stringify(dd));


