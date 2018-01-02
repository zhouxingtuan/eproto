
var eproto = {
	infos: {},
	register: function(name, info){
		this.infos[name] = info;
	},
	pack: function(tab){
		return msgpack.encode(tab);
	},
	unpack: function(buf){
		return msgpack.decode(buf);
	},
	encode: function(name, tab){
		try{
			var arr = this.copyArr(name, tab);
			return msgpack.encode(arr);
		}catch(e){
			throw e;
		}
	},
	decode: function(name, data){
		try{
			var arr = msgpack.decode(data);
			return this.copyTable(name, arr);
		}catch(e){
			throw e;
		}
	},
	copyArr: function(name, tab){
		var info = this.infos[name];
		if (info === undefined){
			throw new Error("can not find proto "+name);
		}
		var arr = new Array(info.length);
		// 获取info中的所以数据，保存到数组中
		for(var i=0; i<info.length; ++i){
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
	                        for(var j=0; j<value.length; ++j){
	                            a[j] = this.copyArr(key[3], value[j]);
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
								a[j] = this.copyArr(key[4], value[j]);
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
                        arr[key[1]] = this.copyArr(key[3], value);
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
	},
	copyTable: function(name, arr){
		var info = this.infos[name];
		if (info === undefined){
			throw new Error("can not find proto "+name);
		}
		var tab = {};
		for(var i=0; i<info.length; ++i){
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
	                        for(var j=0; j<value.length; ++j){
	                            a[j] = this.copyTable(key3, value[j]);
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
								a[j] = this.copyTable(key4, value[j]);
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
                        tab[key[2]] = this.copyTable(key[3], value);
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
};
