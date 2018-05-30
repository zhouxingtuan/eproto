// 定义全局变量
// 导出模块函数
window.exportModule = function(name, that, t){
    if("object"==typeof exports&&"undefined"!=typeof module)
        module.exports=t();
    else if("function"==typeof define&&define.amd)
        define([],t);
    else{
        var r;
        r="undefined"!=typeof window?window:"undefined"!=typeof global?global:"undefined"!=typeof self?self:that,r[name]=t()
    }
};
// 加载模块函数
window.importModule = function(name){
    var m;
    if(("object"==typeof exports&&"undefined"!=typeof module) || ("function"==typeof define&&define.amd)){
        m = require(name);
    }else{
        if("undefined"!=typeof window){
            m = window[name];
        }else{
            m = global[name];
        }
    }
    return m;
};

