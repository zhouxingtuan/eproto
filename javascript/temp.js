
!function(t){
    if("object"==typeof exports&&"undefined"!=typeof module)
        module.exports=t();
    else if("function"==typeof define&&define.amd)
        define([],t);
    else{
        var r;
        r="undefined"!=typeof window?window:"undefined"!=typeof global?global:"undefined"!=typeof self?self:this,r.temp=t()
    }
}(function () {

    // 私有变量
    var privateVar = 0;

    // 私有函数
    var privateFun = function (foo) {
        console.log(foo);
    };

    return {
        // 私有变量
        publicVar: "foo",

        // 公有函数
        publicFun: function (arg) {

            // 修改私有变量
            privateVar ++;

            // 传入bar调用私有方法
            privateFun(arg);
        }
    };
});