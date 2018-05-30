!function(t){
    t();
}(function () {
    var eproto = importModule("eproto");
    var test={"test.request.inner":[[4,0,"t1",0],[5,1,"t2",0]],"test.request":[[4,0,"a",0],[4,1,"b",0],[3,2,"c",0],[3,3,"d",0],[5,4,"e",0],[6,5,"f",0],[9,6,"g","inner"],[8,7,"h",4,5],[7,8,"i",4],[7,9,"j","inner"]],"test.response":[[4,0,"error",0],[6,1,"buffer",0]]};
    for(var name in test){
        eproto.register(name, test[name]);
    }
});
