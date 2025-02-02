library invitemgr;
import 'dart:typed_data';
import 'eproto.dart' as eproto;


class DataType
{
  1 data_type_nil = 1();
  2 data_type_int = 2();
  3 data_type_string = 3();
  4 data_type_double = 4();
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(4);
    if (this.data_type_nil == null) { wb.packNil(); } else { this.data_type_nil.encode(wb); }
    if (this.data_type_int == null) { wb.packNil(); } else { this.data_type_int.encode(wb); }
    if (this.data_type_string == null) { wb.packNil(); } else { this.data_type_string.encode(wb); }
    if (this.data_type_double == null) { wb.packNil(); } else { this.data_type_double.encode(wb); }
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    if (rb.nextIsNil()) { rb.moveNext(); } else { this.data_type_nil.decode(rb); }
    if (--c <= 0) { return; }
    if (rb.nextIsNil()) { rb.moveNext(); } else { this.data_type_int.decode(rb); }
    if (--c <= 0) { return; }
    if (rb.nextIsNil()) { rb.moveNext(); } else { this.data_type_string.decode(rb); }
    if (--c <= 0) { return; }
    if (rb.nextIsNil()) { rb.moveNext(); } else { this.data_type_double.decode(rb); }
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  DataType create() { return DataType(); }

}
class match_price
{
  int id = 0;
  int type = 0;
  int value = 0;
  String name = "";
  int agent_value = 0;
  String agent_name = "";
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(6);
    wb.packInt(this.id);
    wb.packInt(this.type);
    wb.packInt(this.value);
    wb.packString(this.name);
    wb.packInt(this.agent_value);
    wb.packString(this.agent_name);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.id = rb.unpackInt();
    if (--c <= 0) { return; }
    this.type = rb.unpackInt();
    if (--c <= 0) { return; }
    this.value = rb.unpackInt();
    if (--c <= 0) { return; }
    this.name = rb.unpackString();
    if (--c <= 0) { return; }
    this.agent_value = rb.unpackInt();
    if (--c <= 0) { return; }
    this.agent_name = rb.unpackString();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  match_price create() { return match_price(); }

}
class request_create_match
{
  int region_code = 0;
  int game_id = 0;
  String version = "";
  int owner_uid = 0;
  String owner_name = "";
  String game_info = "";
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(6);
    wb.packInt(this.region_code);
    wb.packInt(this.game_id);
    wb.packString(this.version);
    wb.packInt(this.owner_uid);
    wb.packString(this.owner_name);
    wb.packString(this.game_info);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.region_code = rb.unpackInt();
    if (--c <= 0) { return; }
    this.game_id = rb.unpackInt();
    if (--c <= 0) { return; }
    this.version = rb.unpackString();
    if (--c <= 0) { return; }
    this.owner_uid = rb.unpackInt();
    if (--c <= 0) { return; }
    this.owner_name = rb.unpackString();
    if (--c <= 0) { return; }
    this.game_info = rb.unpackString();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  request_create_match create() { return request_create_match(); }

}
class request_dismiss_match_by_owner
{
  int tid = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(1);
    wb.packInt(this.tid);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  request_dismiss_match_by_owner create() { return request_dismiss_match_by_owner(); }

}
class request_invite_config
{
  int region_code = 0;
  String version = "";
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(2);
    wb.packInt(this.region_code);
    wb.packString(this.version);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.region_code = rb.unpackInt();
    if (--c <= 0) { return; }
    this.version = rb.unpackString();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  request_invite_config create() { return request_invite_config(); }

}
class request_join_match
{
  int tid = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(1);
    wb.packInt(this.tid);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  request_join_match create() { return request_join_match(); }

}
class request_kick_user
{
  int tid = 0;
  int uid = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(2);
    wb.packInt(this.tid);
    wb.packInt(this.uid);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    this.uid = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  request_kick_user create() { return request_kick_user(); }

}
class request_leave_match
{
  int tid = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(1);
    wb.packInt(this.tid);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  request_leave_match create() { return request_leave_match(); }

}
class request_pull_user_matches
{
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(0);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  request_pull_user_matches create() { return request_pull_user_matches(); }

}
class request_query_match
{
  int tid = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(1);
    wb.packInt(this.tid);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  request_query_match create() { return request_query_match(); }

}
class request_start_match
{
  int tid = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(1);
    wb.packInt(this.tid);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  request_start_match create() { return request_start_match(); }

}
class response_dismiss_match_by_owner
{
  int result = 0;
  int tid = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(2);
    wb.packInt(this.result);
    wb.packInt(this.tid);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.result = rb.unpackInt();
    if (--c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  response_dismiss_match_by_owner create() { return response_dismiss_match_by_owner(); }

}
class response_join_match
{
  int result = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(1);
    wb.packInt(this.result);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.result = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  response_join_match create() { return response_join_match(); }

}
class response_kick_user
{
  int result = 0;
  int tid = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(2);
    wb.packInt(this.result);
    wb.packInt(this.tid);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.result = rb.unpackInt();
    if (--c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  response_kick_user create() { return response_kick_user(); }

}
class response_leave_match
{
  int result = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(1);
    wb.packInt(this.result);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.result = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  response_leave_match create() { return response_leave_match(); }

}
class response_query_match
{
  int result = 0;
  int tid = 0;
  int owner_uid = 0;
  int game_id = 0;
  int node_type = 0;
  int node_id = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(6);
    wb.packInt(this.result);
    wb.packInt(this.tid);
    wb.packInt(this.owner_uid);
    wb.packInt(this.game_id);
    wb.packInt(this.node_type);
    wb.packInt(this.node_id);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.result = rb.unpackInt();
    if (--c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    this.owner_uid = rb.unpackInt();
    if (--c <= 0) { return; }
    this.game_id = rb.unpackInt();
    if (--c <= 0) { return; }
    this.node_type = rb.unpackInt();
    if (--c <= 0) { return; }
    this.node_id = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  response_query_match create() { return response_query_match(); }

}
class response_start_match
{
  int result = 0;
  int tid = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(2);
    wb.packInt(this.result);
    wb.packInt(this.tid);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.result = rb.unpackInt();
    if (--c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  response_start_match create() { return response_start_match(); }

}
class invite_game
{
  int game_id = 0;
  String game_name = "";
  int showtag = 0;
  int play_countdown = 0;
  int operate_countdown = 0;
  List<String> showtag2_version = List<String>();
  String game_info = "";
  int player_number = 0;
  int is_new = 0;
  int sort_id = 0;
  List<match_price> price = List<match_price>();
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(11);
    wb.packInt(this.game_id);
    wb.packString(this.game_name);
    wb.packInt(this.showtag);
    wb.packInt(this.play_countdown);
    wb.packInt(this.operate_countdown);
    {
      wb.packArrayHead(this.showtag2_version.length);
      for(int i=0; i<this.showtag2_version.length; ++i)
      {
        String v = this.showtag2_version[i];
        wb.packString(v);
      }
    }
    wb.packString(this.game_info);
    wb.packInt(this.player_number);
    wb.packInt(this.is_new);
    wb.packInt(this.sort_id);
    {
      wb.packArrayHead(this.price.length);
      for(int i=0; i<this.price.length; ++i)
      {
        match_price v = this.price[i];
        if (v == null) { wb.packNil(); } else { v.encode(wb); }
      }
    }
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.game_id = rb.unpackInt();
    if (--c <= 0) { return; }
    this.game_name = rb.unpackString();
    if (--c <= 0) { return; }
    this.showtag = rb.unpackInt();
    if (--c <= 0) { return; }
    this.play_countdown = rb.unpackInt();
    if (--c <= 0) { return; }
    this.operate_countdown = rb.unpackInt();
    if (--c <= 0) { return; }
    {
      int n = rb.unpackArrayHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          String v="";
          v = rb.unpackString();
          this.showtag2_version.add(v);
        }
      }
    }
    if (--c <= 0) { return; }
    this.game_info = rb.unpackString();
    if (--c <= 0) { return; }
    this.player_number = rb.unpackInt();
    if (--c <= 0) { return; }
    this.is_new = rb.unpackInt();
    if (--c <= 0) { return; }
    this.sort_id = rb.unpackInt();
    if (--c <= 0) { return; }
    {
      int n = rb.unpackArrayHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          match_price v=match_price();
          if (rb.nextIsNil()) { rb.moveNext(); } else { v.decode(rb); }
          this.price.add(v);
        }
      }
    }
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  invite_game create() { return invite_game(); }

}
class user_info
{
  int uid = 0;
  int signup_time = 0;
  Map<int, String> data = Map<int, String>();
  DataType dt = DataType();
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(4);
    wb.packInt(this.uid);
    wb.packInt(this.signup_time);
    {
      wb.packMapHead(this.data.length);
      this.data.forEach((k,v)
      {
        wb.packInt(k);
        wb.packString(v);
      });
    }
    if (this.dt == null) { wb.packNil(); } else { this.dt.encode(wb); }
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.uid = rb.unpackInt();
    if (--c <= 0) { return; }
    this.signup_time = rb.unpackInt();
    if (--c <= 0) { return; }
    {
      int n = rb.unpackMapHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          int k=0;
          k = rb.unpackInt();
          String v="";
          v = rb.unpackString();
          this.data[k] = v;
        }
      }
    }
    if (--c <= 0) { return; }
    if (rb.nextIsNil()) { rb.moveNext(); } else { this.dt.decode(rb); }
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  user_info create() { return user_info(); }

}
class response_invite_config
{
  int result = 0;
  int region_code = 0;
  List<invite_game> games = List<invite_game>();
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(3);
    wb.packInt(this.result);
    wb.packInt(this.region_code);
    {
      wb.packArrayHead(this.games.length);
      for(int i=0; i<this.games.length; ++i)
      {
        invite_game v = this.games[i];
        if (v == null) { wb.packNil(); } else { v.encode(wb); }
      }
    }
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.result = rb.unpackInt();
    if (--c <= 0) { return; }
    this.region_code = rb.unpackInt();
    if (--c <= 0) { return; }
    {
      int n = rb.unpackArrayHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          invite_game v=invite_game();
          if (rb.nextIsNil()) { rb.moveNext(); } else { v.decode(rb); }
          this.games.add(v);
        }
      }
    }
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  response_invite_config create() { return response_invite_config(); }

}
class table_info
{
  int game_id = 0;
  String game_name = "";
  int player_number = 0;
  int owner_uid = 0;
  String owner_name = "";
  int tid = 0;
  int create_time = 0;
  int state = 0;
  String game_info = "";
  List<user_info> signup_users = List<user_info>();
  bool ss = false;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(11);
    wb.packInt(this.game_id);
    wb.packString(this.game_name);
    wb.packInt(this.player_number);
    wb.packInt(this.owner_uid);
    wb.packString(this.owner_name);
    wb.packInt(this.tid);
    wb.packInt(this.create_time);
    wb.packInt(this.state);
    wb.packString(this.game_info);
    {
      wb.packArrayHead(this.signup_users.length);
      for(int i=0; i<this.signup_users.length; ++i)
      {
        user_info v = this.signup_users[i];
        if (v == null) { wb.packNil(); } else { v.encode(wb); }
      }
    }
    wb.packBool(this.ss);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.game_id = rb.unpackInt();
    if (--c <= 0) { return; }
    this.game_name = rb.unpackString();
    if (--c <= 0) { return; }
    this.player_number = rb.unpackInt();
    if (--c <= 0) { return; }
    this.owner_uid = rb.unpackInt();
    if (--c <= 0) { return; }
    this.owner_name = rb.unpackString();
    if (--c <= 0) { return; }
    this.tid = rb.unpackInt();
    if (--c <= 0) { return; }
    this.create_time = rb.unpackInt();
    if (--c <= 0) { return; }
    this.state = rb.unpackInt();
    if (--c <= 0) { return; }
    this.game_info = rb.unpackString();
    if (--c <= 0) { return; }
    {
      int n = rb.unpackArrayHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          user_info v=user_info();
          if (rb.nextIsNil()) { rb.moveNext(); } else { v.decode(rb); }
          this.signup_users.add(v);
        }
      }
    }
    if (--c <= 0) { return; }
    this.ss = rb.unpackBool();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  table_info create() { return table_info(); }

}
class response_create_match
{
  int result = 0;
  table_info info = table_info();
  int prop_type = 0;
  int prop_num = 0;
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(4);
    wb.packInt(this.result);
    if (this.info == null) { wb.packNil(); } else { this.info.encode(wb); }
    wb.packInt(this.prop_type);
    wb.packInt(this.prop_num);
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    this.result = rb.unpackInt();
    if (--c <= 0) { return; }
    if (rb.nextIsNil()) { rb.moveNext(); } else { this.info.decode(rb); }
    if (--c <= 0) { return; }
    this.prop_type = rb.unpackInt();
    if (--c <= 0) { return; }
    this.prop_num = rb.unpackInt();
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  response_create_match create() { return response_create_match(); }

}
class response_pull_user_matches
{
  List<table_info> info = List<table_info>();
  void encode(eproto.DataWriter wb)
  {
    wb.packArrayHead(1);
    {
      wb.packArrayHead(this.info.length);
      for(int i=0; i<this.info.length; ++i)
      {
        table_info v = this.info[i];
        if (v == null) { wb.packNil(); } else { v.encode(wb); }
      }
    }
  }
  void decode(eproto.DataReader rb)
  {
    int c = rb.unpackArrayHead();
    if (c <= 0) { return; }
    {
      int n = rb.unpackArrayHead();
      if (n > 0) {
        for(int i=0; i<n; ++i)
        {
          table_info v=table_info();
          if (rb.nextIsNil()) { rb.moveNext(); } else { v.decode(rb); }
          this.info.add(v);
        }
      }
    }
    if (--c <= 0) { return; }
    rb.unpackDiscard(c);
  }
  response_pull_user_matches create() { return response_pull_user_matches(); }

}



