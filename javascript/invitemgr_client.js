!function(t){
    t();
}(function () {
    var invitemgr_client={"invitemgr.request_create_match":[[4,1,"region_code",0],[4,2,"game_id",0],[5,3,"version",0],[4,4,"owner_uid",0],[5,5,"owner_name",0],[5,6,"game_info",0]],"invitemgr.response_dismiss_match_by_owner":[[4,1,"result",0],[4,2,"tid",0]],"invitemgr.invite_game":[[4,1,"game_id",0],[5,2,"game_name",0],[4,3,"showtag",0],[4,4,"play_countdown",0],[4,5,"operate_countdown",0],[6,6,"showtag2_version",5],[5,7,"game_info",0],[4,8,"player_number",0],[4,9,"is_new",0],[4,10,"sort_id",0],[6,11,"match_price","invitemgr.match_price"]],"invitemgr.request_dismiss_match_by_owner":[[4,1,"tid",0]],"invitemgr.request_start_match":[[4,1,"tid",0]],"invitemgr.request_leave_match":[[4,1,"tid",0]],"invitemgr.response_invite_config":[[4,1,"result",0],[4,2,"region_code",0],[6,3,"games","invitemgr.invite_game"]],"invitemgr.response_query_match":[[4,1,"result",0],[4,2,"tid",0],[4,3,"owner_uid",0],[4,4,"game_id",0],[4,5,"node_type",0],[4,6,"node_id",0]],"invitemgr.request_kick_user":[[4,1,"tid",0],[4,2,"uid",0]],"invitemgr.match_price":[[4,1,"id",0],[4,2,"type",0],[4,3,"value",0],[5,4,"name",0],[4,5,"agent_value",0],[5,6,"agent_name",0]],"invitemgr.response_kick_user":[[4,1,"result",0],[4,2,"tid",0]],"invitemgr.response_start_match":[[4,1,"result",0],[4,2,"tid",0]],"invitemgr.request_invite_config":[[4,1,"region_code",0],[5,2,"version",0]],"invitemgr.response_leave_match":[[4,1,"result",0]],"invitemgr.response_join_match":[[4,1,"result",0]],"invitemgr.response_create_match":[[4,1,"result",0],[8,2,"table_info","invitemgr.table_info"],[4,3,"prop_type",0],[4,4,"prop_num",0]],"invitemgr.user_info":[[4,1,"uid",0],[4,2,"signup_time",0],[7,3,"data",4,5],[4,4,"dt",0]],"invitemgr.request_query_match":[[4,1,"tid",0]],"invitemgr.request_pull_user_matches":[],"invitemgr.response_pull_user_matches":[[6,1,"table_info","invitemgr.table_info"]],"invitemgr.request_join_match":[[4,1,"tid",0]],"invitemgr.table_info":[[4,1,"game_id",0],[5,2,"game_name",0],[4,3,"player_number",0],[4,4,"owner_uid",0],[5,5,"owner_name",0],[4,6,"tid",0],[4,7,"create_time",0],[4,8,"state",0],[5,9,"game_info",0],[6,10,"signup_users","invitemgr.user_info"],[2,11,"ss",0]]};
    for(var name in invitemgr_client){
        eproto.register(name, invitemgr_client[name]);
    }
});
