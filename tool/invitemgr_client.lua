local data = {
  invitemgr.request_create_match = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "region_code";
      [4] = 0;
    };
    [2] = {
      [1] = 4;
      [2] = 1;
      [3] = "game_id";
      [4] = 0;
    };
    [3] = {
      [1] = 5;
      [2] = 2;
      [3] = "version";
      [4] = 0;
    };
    [4] = {
      [1] = 4;
      [2] = 3;
      [3] = "owner_uid";
      [4] = 0;
    };
    [5] = {
      [1] = 5;
      [2] = 4;
      [3] = "owner_name";
      [4] = 0;
    };
    [6] = {
      [1] = 5;
      [2] = 5;
      [3] = "game_info";
      [4] = 0;
    };
  };
  invitemgr.response_dismiss_match_by_owner = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "result";
      [4] = 0;
    };
    [2] = {
      [1] = 4;
      [2] = 1;
      [3] = "tid";
      [4] = 0;
    };
  };
  invitemgr.invite_game = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "game_id";
      [4] = 0;
    };
    [2] = {
      [1] = 5;
      [2] = 1;
      [3] = "game_name";
      [4] = 0;
    };
    [3] = {
      [1] = 4;
      [2] = 2;
      [3] = "showtag";
      [4] = 0;
    };
    [4] = {
      [1] = 4;
      [2] = 3;
      [3] = "play_countdown";
      [4] = 0;
    };
    [5] = {
      [1] = 4;
      [2] = 4;
      [3] = "operate_countdown";
      [4] = 0;
    };
    [6] = {
      [1] = 7;
      [2] = 5;
      [3] = "showtag2_version";
      [4] = 5;
    };
    [7] = {
      [1] = 5;
      [2] = 6;
      [3] = "game_info";
      [4] = 0;
    };
    [8] = {
      [1] = 4;
      [2] = 7;
      [3] = "player_number";
      [4] = 0;
    };
    [9] = {
      [1] = 4;
      [2] = 8;
      [3] = "is_new";
      [4] = 0;
    };
    [10] = {
      [1] = 4;
      [2] = 9;
      [3] = "sort_id";
      [4] = 0;
    };
    [11] = {
      [1] = 7;
      [2] = 10;
      [3] = "price";
      [4] = "invitemgr.match_price";
    };
  };
  invitemgr.request_dismiss_match_by_owner = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "tid";
      [4] = 0;
    };
  };
  invitemgr.request_start_match = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "tid";
      [4] = 0;
    };
  };
  invitemgr.request_leave_match = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "tid";
      [4] = 0;
    };
  };
  invitemgr.response_invite_config = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "result";
      [4] = 0;
    };
    [2] = {
      [1] = 4;
      [2] = 1;
      [3] = "region_code";
      [4] = 0;
    };
    [3] = {
      [1] = 7;
      [2] = 2;
      [3] = "games";
      [4] = "invitemgr.invite_game";
    };
  };
  invitemgr.response_query_match = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "result";
      [4] = 0;
    };
    [2] = {
      [1] = 4;
      [2] = 1;
      [3] = "tid";
      [4] = 0;
    };
    [3] = {
      [1] = 4;
      [2] = 2;
      [3] = "owner_uid";
      [4] = 0;
    };
    [4] = {
      [1] = 4;
      [2] = 3;
      [3] = "game_id";
      [4] = 0;
    };
    [5] = {
      [1] = 4;
      [2] = 4;
      [3] = "node_type";
      [4] = 0;
    };
    [6] = {
      [1] = 4;
      [2] = 5;
      [3] = "node_id";
      [4] = 0;
    };
  };
  invitemgr.request_kick_user = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "tid";
      [4] = 0;
    };
    [2] = {
      [1] = 4;
      [2] = 1;
      [3] = "uid";
      [4] = 0;
    };
  };
  invitemgr.match_price = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "id";
      [4] = 0;
    };
    [2] = {
      [1] = 4;
      [2] = 1;
      [3] = "type";
      [4] = 0;
    };
    [3] = {
      [1] = 4;
      [2] = 2;
      [3] = "value";
      [4] = 0;
    };
    [4] = {
      [1] = 5;
      [2] = 3;
      [3] = "name";
      [4] = 0;
    };
    [5] = {
      [1] = 4;
      [2] = 4;
      [3] = "agent_value";
      [4] = 0;
    };
    [6] = {
      [1] = 5;
      [2] = 5;
      [3] = "agent_name";
      [4] = 0;
    };
  };
  invitemgr.response_kick_user = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "result";
      [4] = 0;
    };
    [2] = {
      [1] = 4;
      [2] = 1;
      [3] = "tid";
      [4] = 0;
    };
  };
  invitemgr.response_start_match = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "result";
      [4] = 0;
    };
    [2] = {
      [1] = 4;
      [2] = 1;
      [3] = "tid";
      [4] = 0;
    };
  };
  invitemgr.request_invite_config = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "region_code";
      [4] = 0;
    };
    [2] = {
      [1] = 5;
      [2] = 1;
      [3] = "version";
      [4] = 0;
    };
  };
  invitemgr.response_leave_match = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "result";
      [4] = 0;
    };
  };
  invitemgr.response_join_match = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "result";
      [4] = 0;
    };
  };
  invitemgr.response_create_match = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "result";
      [4] = 0;
    };
    [2] = {
      [1] = 9;
      [2] = 1;
      [3] = "info";
      [4] = "invitemgr.table_info";
    };
    [3] = {
      [1] = 4;
      [2] = 2;
      [3] = "prop_type";
      [4] = 0;
    };
    [4] = {
      [1] = 4;
      [2] = 3;
      [3] = "prop_num";
      [4] = 0;
    };
  };
  invitemgr.user_info = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "uid";
      [4] = 0;
    };
    [2] = {
      [1] = 4;
      [2] = 1;
      [3] = "signup_time";
      [4] = 0;
    };
    [3] = {
      [1] = 8;
      [2] = 2;
      [3] = "data";
      [4] = 4;
      [5] = 5;
    };
    [4] = {
      [1] = 4;
      [2] = 3;
      [3] = "dt";
      [4] = 0;
    };
  };
  invitemgr.request_query_match = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "tid";
      [4] = 0;
    };
  };
  invitemgr.request_pull_user_matches = {
    
  };
  invitemgr.response_pull_user_matches = {
    [1] = {
      [1] = 7;
      [2] = 0;
      [3] = "info";
      [4] = "invitemgr.table_info";
    };
  };
  invitemgr.request_join_match = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "tid";
      [4] = 0;
    };
  };
  invitemgr.table_info = {
    [1] = {
      [1] = 4;
      [2] = 0;
      [3] = "game_id";
      [4] = 0;
    };
    [2] = {
      [1] = 5;
      [2] = 1;
      [3] = "game_name";
      [4] = 0;
    };
    [3] = {
      [1] = 4;
      [2] = 2;
      [3] = "player_number";
      [4] = 0;
    };
    [4] = {
      [1] = 4;
      [2] = 3;
      [3] = "owner_uid";
      [4] = 0;
    };
    [5] = {
      [1] = 5;
      [2] = 4;
      [3] = "owner_name";
      [4] = 0;
    };
    [6] = {
      [1] = 4;
      [2] = 5;
      [3] = "tid";
      [4] = 0;
    };
    [7] = {
      [1] = 4;
      [2] = 6;
      [3] = "create_time";
      [4] = 0;
    };
    [8] = {
      [1] = 4;
      [2] = 7;
      [3] = "state";
      [4] = 0;
    };
    [9] = {
      [1] = 5;
      [2] = 8;
      [3] = "game_info";
      [4] = 0;
    };
    [10] = {
      [1] = 7;
      [2] = 9;
      [3] = "signup_users";
      [4] = "invitemgr.user_info";
    };
    [11] = {
      [1] = 2;
      [2] = 10;
      [3] = "ss";
      [4] = 0;
    };
  };
}
return data
