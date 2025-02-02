using System;
using System.Text;
using System.Collections.Generic;
using Erpc;

namespace invitemgr
{
    class request_query_match : Proto
    {
        public int tid;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 1);
            Eproto.PackInteger(wb, this.tid);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new request_query_match(); }
    }
    class request_invite_config : Proto
    {
        public int region_code;
        public string version;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 2);
            Eproto.PackInteger(wb, this.region_code);
            Eproto.PackString(wb, this.version);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.region_code);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.version);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new request_invite_config(); }
    }
    class response_query_match : Proto
    {
        public int result;
        public int tid;
        public int owner_uid;
        public int game_id;
        public int node_type;
        public int node_id;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 6);
            Eproto.PackInteger(wb, this.result);
            Eproto.PackInteger(wb, this.tid);
            Eproto.PackInteger(wb, this.owner_uid);
            Eproto.PackInteger(wb, this.game_id);
            Eproto.PackInteger(wb, this.node_type);
            Eproto.PackInteger(wb, this.node_id);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.result);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.owner_uid);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.game_id);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.node_type);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.node_id);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new response_query_match(); }
    }
    class request_kick_user : Proto
    {
        public int tid;
        public int uid;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 2);
            Eproto.PackInteger(wb, this.tid);
            Eproto.PackInteger(wb, this.uid);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.uid);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new request_kick_user(); }
    }
    class response_invite_config : Proto
    {
        public int result;
        public int region_code;
        public invite_game[] games;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 3);
            Eproto.PackInteger(wb, this.result);
            Eproto.PackInteger(wb, this.region_code);
            if (this.games == null) { Eproto.PackNil(wb); } else {
                Eproto.PackArray(wb, this.games.Length);
                for(int i=0; i<this.games.Length; ++i)
                {
                    invite_game v = this.games[i];
                    if (v == null) { Eproto.PackNil(wb); } else { v.Encode(wb); }
                }
            }
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.result);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.region_code);
            if (--c <= 0) { return; }
            {
                long n = Eproto.UnpackArray(rb);
                if (n < 0) { this.games=null; } else {
                    this.games = new invite_game[n];
                    for(int i=0; i<n; ++i)
                    {
                        invite_game v=null;
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { v = new invite_game(); v.Decode(rb); }
                        this.games[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new response_invite_config(); }
    }
    class request_create_match : Proto
    {
        public int region_code;
        public int game_id;
        public string version;
        public int owner_uid;
        public string owner_name;
        public string game_info;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 6);
            Eproto.PackInteger(wb, this.region_code);
            Eproto.PackInteger(wb, this.game_id);
            Eproto.PackString(wb, this.version);
            Eproto.PackInteger(wb, this.owner_uid);
            Eproto.PackString(wb, this.owner_name);
            Eproto.PackString(wb, this.game_info);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.region_code);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.game_id);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.version);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.owner_uid);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.owner_name);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.game_info);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new request_create_match(); }
    }
    class response_dismiss_match_by_owner : Proto
    {
        public int result;
        public int tid;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 2);
            Eproto.PackInteger(wb, this.result);
            Eproto.PackInteger(wb, this.tid);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.result);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new response_dismiss_match_by_owner(); }
    }
    class match_price : Proto
    {
        public int id;
        public int type;
        public int value;
        public string name;
        public int agent_value;
        public string agent_name;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 6);
            Eproto.PackInteger(wb, this.id);
            Eproto.PackInteger(wb, this.type);
            Eproto.PackInteger(wb, this.value);
            Eproto.PackString(wb, this.name);
            Eproto.PackInteger(wb, this.agent_value);
            Eproto.PackString(wb, this.agent_name);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.id);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.type);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.value);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.name);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.agent_value);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.agent_name);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new match_price(); }
    }
    class request_leave_match : Proto
    {
        public int tid;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 1);
            Eproto.PackInteger(wb, this.tid);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new request_leave_match(); }
    }
    class response_leave_match : Proto
    {
        public int result;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 1);
            Eproto.PackInteger(wb, this.result);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.result);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new response_leave_match(); }
    }
    class request_pull_user_matches : Proto
    {
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 0);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new request_pull_user_matches(); }
    }
    class response_start_match : Proto
    {
        public int result;
        public int tid;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 2);
            Eproto.PackInteger(wb, this.result);
            Eproto.PackInteger(wb, this.tid);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.result);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new response_start_match(); }
    }
    class request_join_match : Proto
    {
        public int tid;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 1);
            Eproto.PackInteger(wb, this.tid);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new request_join_match(); }
    }
    class request_start_match : Proto
    {
        public int tid;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 1);
            Eproto.PackInteger(wb, this.tid);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new request_start_match(); }
    }
    class response_create_match : Proto
    {
        public int result;
        public table_info info;
        public int prop_type;
        public int prop_num;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 4);
            Eproto.PackInteger(wb, this.result);
            if (this.info == null) { Eproto.PackNil(wb); } else { this.info.Encode(wb); }
            Eproto.PackInteger(wb, this.prop_type);
            Eproto.PackInteger(wb, this.prop_num);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.result);
            if (--c <= 0) { return; }
            if (rb.NextIsNil()) { rb.MoveNext(); } else { this.info = new table_info(); this.info.Decode(rb); }
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.prop_type);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.prop_num);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new response_create_match(); }
    }
    class response_pull_user_matches : Proto
    {
        public table_info[] info;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 1);
            if (this.info == null) { Eproto.PackNil(wb); } else {
                Eproto.PackArray(wb, this.info.Length);
                for(int i=0; i<this.info.Length; ++i)
                {
                    table_info v = this.info[i];
                    if (v == null) { Eproto.PackNil(wb); } else { v.Encode(wb); }
                }
            }
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            {
                long n = Eproto.UnpackArray(rb);
                if (n < 0) { this.info=null; } else {
                    this.info = new table_info[n];
                    for(int i=0; i<n; ++i)
                    {
                        table_info v=null;
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { v = new table_info(); v.Decode(rb); }
                        this.info[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new response_pull_user_matches(); }
    }
    class request_dismiss_match_by_owner : Proto
    {
        public int tid;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 1);
            Eproto.PackInteger(wb, this.tid);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new request_dismiss_match_by_owner(); }
    }
    class user_info : Proto
    {
        public int uid;
        public int signup_time;
        public Dictionary<int, string> data;
        public DataType dt;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 4);
            Eproto.PackInteger(wb, this.uid);
            Eproto.PackInteger(wb, this.signup_time);
            if (this.data == null) { Eproto.PackNil(wb); } else {
                Eproto.PackMap(wb, this.data.Count);
                foreach (var i in this.data)
                {
                    Eproto.PackInteger(wb, i.Key);
                    Eproto.PackString(wb, i.Value);
                }
            }
            if (this.dt == null) { Eproto.PackNil(wb); } else { this.dt.Encode(wb); }
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.uid);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.signup_time);
            if (--c <= 0) { return; }
            {
                long n = Eproto.UnpackMap(rb);
                if (n < 0) { this.data=null; } else {
                    this.data = new Dictionary<int, string>();
                    for(int i=0; i<n; ++i)
                    {
                        int k=0; string v=null;
                        Eproto.UnpackInteger(rb, ref k);
                        Eproto.UnpackString(rb, ref v);
                        this.data[k] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            if (rb.NextIsNil()) { rb.MoveNext(); } else { this.dt = new DataType(); this.dt.Decode(rb); }
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new user_info(); }
    }
    class table_info : Proto
    {
        public int game_id;
        public string game_name;
        public int player_number;
        public int owner_uid;
        public string owner_name;
        public int tid;
        public int create_time;
        public int state;
        public string game_info;
        public user_info[] signup_users;
        public bool ss;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 11);
            Eproto.PackInteger(wb, this.game_id);
            Eproto.PackString(wb, this.game_name);
            Eproto.PackInteger(wb, this.player_number);
            Eproto.PackInteger(wb, this.owner_uid);
            Eproto.PackString(wb, this.owner_name);
            Eproto.PackInteger(wb, this.tid);
            Eproto.PackInteger(wb, this.create_time);
            Eproto.PackInteger(wb, this.state);
            Eproto.PackString(wb, this.game_info);
            if (this.signup_users == null) { Eproto.PackNil(wb); } else {
                Eproto.PackArray(wb, this.signup_users.Length);
                for(int i=0; i<this.signup_users.Length; ++i)
                {
                    user_info v = this.signup_users[i];
                    if (v == null) { Eproto.PackNil(wb); } else { v.Encode(wb); }
                }
            }
            Eproto.PackBool(wb, this.ss);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.game_id);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.game_name);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.player_number);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.owner_uid);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.owner_name);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.create_time);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.state);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.game_info);
            if (--c <= 0) { return; }
            {
                long n = Eproto.UnpackArray(rb);
                if (n < 0) { this.signup_users=null; } else {
                    this.signup_users = new user_info[n];
                    for(int i=0; i<n; ++i)
                    {
                        user_info v=null;
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { v = new user_info(); v.Decode(rb); }
                        this.signup_users[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            Eproto.UnpackBool(rb, ref this.ss);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new table_info(); }
    }
    enum DataType
    {
        data_type_nil = 1,
        data_type_int = 2,
        data_type_string = 3,
        data_type_double = 4
    };
    class invite_game : Proto
    {
        public int game_id;
        public string game_name;
        public int showtag;
        public int play_countdown;
        public int operate_countdown;
        public string[] showtag2_version;
        public string game_info;
        public int player_number;
        public int is_new;
        public int sort_id;
        public match_price[] price;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 11);
            Eproto.PackInteger(wb, this.game_id);
            Eproto.PackString(wb, this.game_name);
            Eproto.PackInteger(wb, this.showtag);
            Eproto.PackInteger(wb, this.play_countdown);
            Eproto.PackInteger(wb, this.operate_countdown);
            if (this.showtag2_version == null) { Eproto.PackNil(wb); } else {
                Eproto.PackArray(wb, this.showtag2_version.Length);
                for(int i=0; i<this.showtag2_version.Length; ++i)
                {
                    string v = this.showtag2_version[i];
                Eproto.PackString(wb, v);
                }
            }
            Eproto.PackString(wb, this.game_info);
            Eproto.PackInteger(wb, this.player_number);
            Eproto.PackInteger(wb, this.is_new);
            Eproto.PackInteger(wb, this.sort_id);
            if (this.price == null) { Eproto.PackNil(wb); } else {
                Eproto.PackArray(wb, this.price.Length);
                for(int i=0; i<this.price.Length; ++i)
                {
                    match_price v = this.price[i];
                    if (v == null) { Eproto.PackNil(wb); } else { v.Encode(wb); }
                }
            }
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.game_id);
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.game_name);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.showtag);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.play_countdown);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.operate_countdown);
            if (--c <= 0) { return; }
            {
                long n = Eproto.UnpackArray(rb);
                if (n < 0) { this.showtag2_version=null; } else {
                    this.showtag2_version = new string[n];
                    for(int i=0; i<n; ++i)
                    {
                        string v=null;
                        Eproto.UnpackString(rb, ref v);
                        this.showtag2_version[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            Eproto.UnpackString(rb, ref this.game_info);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.player_number);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.is_new);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.sort_id);
            if (--c <= 0) { return; }
            {
                long n = Eproto.UnpackArray(rb);
                if (n < 0) { this.price=null; } else {
                    this.price = new match_price[n];
                    for(int i=0; i<n; ++i)
                    {
                        match_price v=null;
                        if (rb.NextIsNil()) { rb.MoveNext(); } else { v = new match_price(); v.Decode(rb); }
                        this.price[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new invite_game(); }
    }
    class response_join_match : Proto
    {
        public int result;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 1);
            Eproto.PackInteger(wb, this.result);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.result);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new response_join_match(); }
    }
    class response_kick_user : Proto
    {
        public int result;
        public int tid;
        override public void Encode(WriteBuffer wb)
        {
            Eproto.PackArray(wb, 2);
            Eproto.PackInteger(wb, this.result);
            Eproto.PackInteger(wb, this.tid);
        }
        override public void Decode(ReadBuffer rb)
        {
            long c = Eproto.UnpackArray(rb);
            if (c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.result);
            if (--c <= 0) { return; }
            Eproto.UnpackInteger(rb, ref this.tid);
            if (--c <= 0) { return; }
            Eproto.UnpackDiscard(rb, c);
        }
        override public Proto Create() { return new response_kick_user(); }
    }

}
