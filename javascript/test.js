
var d = {
	game_id : 100,
	game_info : "Hello World!",
	state : 1,
	ss : false
};

var buf = eproto.encode("invitemgr.table_info", d);

var dd = eproto.decode("invitemgr.table_info", buf);

alert(JSON.stringify(dd));

