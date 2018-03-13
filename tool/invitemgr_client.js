!function(t){
    t();
}(function () {
    var eproto;
    if("object"==typeof exports&&"undefined"!=typeof module){
        eproto = require("eproto");
    }else{
        if("undefined"!=typeof window){
            eproto = window.eproto;
        }else{
            eproto = global.eproto;
        }
    }
    var invitemgr_client={"invitemgr.request_create_match":[[4,0,"region_code",0],[4,1,"game_id",0],[5,2,"version",0],[4,3,"owner_uid",0],[5,4,"owner_name",0],[5,5,"game_info",0]],"invitemgr.response_dismiss_match_by_owner":[[4,0,"result",0],[4,1,"tid",0]],"invitemgr.invite_game":[[4,0,"game_id",0],[5,1,"game_name",0],[4,2,"showtag",0],[4,3,"play_countdown",0],[4,4,"operate_countdown",0],[6,5,"showtag2_version",5],[5,6,"game_info",0],[4,7,"player_number",0],[4,8,"is_new",0],[4,9,"sort_id",0],[6,10,"match_price","invitemgr.match_price"]],"invitemgr.request_dismiss_match_by_owner":[[4,0,"tid",0]],"invitemgr.request_start_match":[[4,0,"tid",0]],"invitemgr.request_leave_match":[[4,0,"tid",0]],"invitemgr.response_invite_config":[[4,0,"result",0],[4,1,"region_code",0],[6,2,"games","invitemgr.invite_game"]],"invitemgr.response_query_match":[[4,0,"result",0],[4,1,"tid",0],[4,2,"owner_uid",0],[4,3,"game_id",0],[4,4,"node_type",0],[4,5,"node_id",0]],"invitemgr.request_kick_user":[[4,0,"tid",0],[4,1,"uid",0]],"invitemgr.match_price":[[4,0,"id",0],[4,1,"type",0],[4,2,"value",0],[5,3,"name",0],[4,4,"agent_value",0],[5,5,"agent_name",0]],"invitemgr.response_kick_user":[[4,0,"result",0],[4,1,"tid",0]],"invitemgr.response_start_match":[[4,0,"result",0],[4,1,"tid",0]],"invitemgr.request_invite_config":[[4,0,"region_code",0],[5,1,"version",0]],"invitemgr.response_leave_match":[[4,0,"result",0]],"invitemgr.response_join_match":[[4,0,"result",0]],"invitemgr.response_create_match":[[4,0,"result",0],[8,1,"table_info","invitemgr.table_info"],[4,2,"prop_type",0],[4,3,"prop_num",0]],"invitemgr.user_info":[[4,0,"uid",0],[4,1,"signup_time",0],[7,2,"data",4,5],[4,3,"dt",0]],"invitemgr.request_query_match":[[4,0,"tid",0]],"invitemgr.request_pull_user_matches":[],"invitemgr.response_pull_user_matches":[[6,0,"table_info","invitemgr.table_info"]],"invitemgr.request_join_match":[[4,0,"tid",0]],"invitemgr.table_info":[[4,0,"game_id",0],[5,1,"game_name",0],[4,2,"player_number",0],[4,3,"owner_uid",0],[5,4,"owner_name",0],[4,5,"tid",0],[4,6,"create_time",0],[4,7,"state",0],[5,8,"game_info",0],[6,9,"signup_users","invitemgr.user_info"],[2,10,"ss",0]]};
    for(var name in invitemgr_client){
        eproto.register(name, invitemgr_client[name]);
    }
});