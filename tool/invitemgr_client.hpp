#ifndef __invitemgr_client_hpp__
#define __invitemgr_client_hpp__

#include "eproto.hpp"

namespace invitemgr
{
    class DataType : public eproto::Proto
    {
    public:
        DataType() : eproto::Proto() {}
        virtual ~DataType(){ Clear(); }
        virtual void Clear()
        {
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(0);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return DataType::New(); }
        virtual void Destroy() { DataType::Delete(this); }
        static DataType* New() { DataType* p = new DataType(); p->retain(); return p; }
        static void Delete(DataType* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::DataType"; }
    };
    class match_price : public eproto::Proto
    {
    public:
        int id;
        int type;
        int value;
        std::string name;
        int agent_value;
        std::string agent_name;
        match_price() : eproto::Proto(), id(0), type(0), value(0), agent_value(0) {}
        virtual ~match_price(){ Clear(); }
        virtual void Clear()
        {
            this->id = 0;
            this->type = 0;
            this->value = 0;
            this->name = "";
            this->agent_value = 0;
            this->agent_name = "";
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(6);
            wb.pack_int(this->id);
            wb.pack_int(this->type);
            wb.pack_int(this->value);
            wb.pack_string(this->name);
            wb.pack_int(this->agent_value);
            wb.pack_string(this->agent_name);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->id);
            if (--c <= 0) { return; }
            rb.unpack_int(this->type);
            if (--c <= 0) { return; }
            rb.unpack_int(this->value);
            if (--c <= 0) { return; }
            rb.unpack_string(this->name);
            if (--c <= 0) { return; }
            rb.unpack_int(this->agent_value);
            if (--c <= 0) { return; }
            rb.unpack_string(this->agent_name);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return match_price::New(); }
        virtual void Destroy() { match_price::Delete(this); }
        static match_price* New() { match_price* p = new match_price(); p->retain(); return p; }
        static void Delete(match_price* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::match_price"; }
    };
    class request_create_match : public eproto::Proto
    {
    public:
        int region_code;
        int game_id;
        std::string version;
        int owner_uid;
        std::string owner_name;
        std::string game_info;
        request_create_match() : eproto::Proto(), region_code(0), game_id(0), owner_uid(0) {}
        virtual ~request_create_match(){ Clear(); }
        virtual void Clear()
        {
            this->region_code = 0;
            this->game_id = 0;
            this->version = "";
            this->owner_uid = 0;
            this->owner_name = "";
            this->game_info = "";
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(6);
            wb.pack_int(this->region_code);
            wb.pack_int(this->game_id);
            wb.pack_string(this->version);
            wb.pack_int(this->owner_uid);
            wb.pack_string(this->owner_name);
            wb.pack_string(this->game_info);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->region_code);
            if (--c <= 0) { return; }
            rb.unpack_int(this->game_id);
            if (--c <= 0) { return; }
            rb.unpack_string(this->version);
            if (--c <= 0) { return; }
            rb.unpack_int(this->owner_uid);
            if (--c <= 0) { return; }
            rb.unpack_string(this->owner_name);
            if (--c <= 0) { return; }
            rb.unpack_string(this->game_info);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return request_create_match::New(); }
        virtual void Destroy() { request_create_match::Delete(this); }
        static request_create_match* New() { request_create_match* p = new request_create_match(); p->retain(); return p; }
        static void Delete(request_create_match* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::request_create_match"; }
    };
    class request_dismiss_match_by_owner : public eproto::Proto
    {
    public:
        int tid;
        request_dismiss_match_by_owner() : eproto::Proto(), tid(0) {}
        virtual ~request_dismiss_match_by_owner(){ Clear(); }
        virtual void Clear()
        {
            this->tid = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(1);
            wb.pack_int(this->tid);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return request_dismiss_match_by_owner::New(); }
        virtual void Destroy() { request_dismiss_match_by_owner::Delete(this); }
        static request_dismiss_match_by_owner* New() { request_dismiss_match_by_owner* p = new request_dismiss_match_by_owner(); p->retain(); return p; }
        static void Delete(request_dismiss_match_by_owner* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::request_dismiss_match_by_owner"; }
    };
    class request_invite_config : public eproto::Proto
    {
    public:
        int region_code;
        std::string version;
        request_invite_config() : eproto::Proto(), region_code(0) {}
        virtual ~request_invite_config(){ Clear(); }
        virtual void Clear()
        {
            this->region_code = 0;
            this->version = "";
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(2);
            wb.pack_int(this->region_code);
            wb.pack_string(this->version);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->region_code);
            if (--c <= 0) { return; }
            rb.unpack_string(this->version);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return request_invite_config::New(); }
        virtual void Destroy() { request_invite_config::Delete(this); }
        static request_invite_config* New() { request_invite_config* p = new request_invite_config(); p->retain(); return p; }
        static void Delete(request_invite_config* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::request_invite_config"; }
    };
    class request_join_match : public eproto::Proto
    {
    public:
        int tid;
        request_join_match() : eproto::Proto(), tid(0) {}
        virtual ~request_join_match(){ Clear(); }
        virtual void Clear()
        {
            this->tid = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(1);
            wb.pack_int(this->tid);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return request_join_match::New(); }
        virtual void Destroy() { request_join_match::Delete(this); }
        static request_join_match* New() { request_join_match* p = new request_join_match(); p->retain(); return p; }
        static void Delete(request_join_match* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::request_join_match"; }
    };
    class request_kick_user : public eproto::Proto
    {
    public:
        int tid;
        int uid;
        request_kick_user() : eproto::Proto(), tid(0), uid(0) {}
        virtual ~request_kick_user(){ Clear(); }
        virtual void Clear()
        {
            this->tid = 0;
            this->uid = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(2);
            wb.pack_int(this->tid);
            wb.pack_int(this->uid);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_int(this->uid);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return request_kick_user::New(); }
        virtual void Destroy() { request_kick_user::Delete(this); }
        static request_kick_user* New() { request_kick_user* p = new request_kick_user(); p->retain(); return p; }
        static void Delete(request_kick_user* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::request_kick_user"; }
    };
    class request_leave_match : public eproto::Proto
    {
    public:
        int tid;
        request_leave_match() : eproto::Proto(), tid(0) {}
        virtual ~request_leave_match(){ Clear(); }
        virtual void Clear()
        {
            this->tid = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(1);
            wb.pack_int(this->tid);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return request_leave_match::New(); }
        virtual void Destroy() { request_leave_match::Delete(this); }
        static request_leave_match* New() { request_leave_match* p = new request_leave_match(); p->retain(); return p; }
        static void Delete(request_leave_match* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::request_leave_match"; }
    };
    class request_pull_user_matches : public eproto::Proto
    {
    public:
        request_pull_user_matches() : eproto::Proto() {}
        virtual ~request_pull_user_matches(){ Clear(); }
        virtual void Clear()
        {
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(0);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return request_pull_user_matches::New(); }
        virtual void Destroy() { request_pull_user_matches::Delete(this); }
        static request_pull_user_matches* New() { request_pull_user_matches* p = new request_pull_user_matches(); p->retain(); return p; }
        static void Delete(request_pull_user_matches* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::request_pull_user_matches"; }
    };
    class request_query_match : public eproto::Proto
    {
    public:
        int tid;
        request_query_match() : eproto::Proto(), tid(0) {}
        virtual ~request_query_match(){ Clear(); }
        virtual void Clear()
        {
            this->tid = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(1);
            wb.pack_int(this->tid);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return request_query_match::New(); }
        virtual void Destroy() { request_query_match::Delete(this); }
        static request_query_match* New() { request_query_match* p = new request_query_match(); p->retain(); return p; }
        static void Delete(request_query_match* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::request_query_match"; }
    };
    class request_start_match : public eproto::Proto
    {
    public:
        int tid;
        request_start_match() : eproto::Proto(), tid(0) {}
        virtual ~request_start_match(){ Clear(); }
        virtual void Clear()
        {
            this->tid = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(1);
            wb.pack_int(this->tid);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return request_start_match::New(); }
        virtual void Destroy() { request_start_match::Delete(this); }
        static request_start_match* New() { request_start_match* p = new request_start_match(); p->retain(); return p; }
        static void Delete(request_start_match* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::request_start_match"; }
    };
    class response_dismiss_match_by_owner : public eproto::Proto
    {
    public:
        int result;
        int tid;
        response_dismiss_match_by_owner() : eproto::Proto(), result(0), tid(0) {}
        virtual ~response_dismiss_match_by_owner(){ Clear(); }
        virtual void Clear()
        {
            this->result = 0;
            this->tid = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(2);
            wb.pack_int(this->result);
            wb.pack_int(this->tid);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->result);
            if (--c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return response_dismiss_match_by_owner::New(); }
        virtual void Destroy() { response_dismiss_match_by_owner::Delete(this); }
        static response_dismiss_match_by_owner* New() { response_dismiss_match_by_owner* p = new response_dismiss_match_by_owner(); p->retain(); return p; }
        static void Delete(response_dismiss_match_by_owner* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::response_dismiss_match_by_owner"; }
    };
    class response_join_match : public eproto::Proto
    {
    public:
        int result;
        response_join_match() : eproto::Proto(), result(0) {}
        virtual ~response_join_match(){ Clear(); }
        virtual void Clear()
        {
            this->result = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(1);
            wb.pack_int(this->result);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->result);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return response_join_match::New(); }
        virtual void Destroy() { response_join_match::Delete(this); }
        static response_join_match* New() { response_join_match* p = new response_join_match(); p->retain(); return p; }
        static void Delete(response_join_match* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::response_join_match"; }
    };
    class response_kick_user : public eproto::Proto
    {
    public:
        int result;
        int tid;
        response_kick_user() : eproto::Proto(), result(0), tid(0) {}
        virtual ~response_kick_user(){ Clear(); }
        virtual void Clear()
        {
            this->result = 0;
            this->tid = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(2);
            wb.pack_int(this->result);
            wb.pack_int(this->tid);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->result);
            if (--c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return response_kick_user::New(); }
        virtual void Destroy() { response_kick_user::Delete(this); }
        static response_kick_user* New() { response_kick_user* p = new response_kick_user(); p->retain(); return p; }
        static void Delete(response_kick_user* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::response_kick_user"; }
    };
    class response_leave_match : public eproto::Proto
    {
    public:
        int result;
        response_leave_match() : eproto::Proto(), result(0) {}
        virtual ~response_leave_match(){ Clear(); }
        virtual void Clear()
        {
            this->result = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(1);
            wb.pack_int(this->result);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->result);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return response_leave_match::New(); }
        virtual void Destroy() { response_leave_match::Delete(this); }
        static response_leave_match* New() { response_leave_match* p = new response_leave_match(); p->retain(); return p; }
        static void Delete(response_leave_match* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::response_leave_match"; }
    };
    class response_query_match : public eproto::Proto
    {
    public:
        int result;
        int tid;
        int owner_uid;
        int game_id;
        int node_type;
        int node_id;
        response_query_match() : eproto::Proto(), result(0), tid(0), owner_uid(0), game_id(0), node_type(0), node_id(0) {}
        virtual ~response_query_match(){ Clear(); }
        virtual void Clear()
        {
            this->result = 0;
            this->tid = 0;
            this->owner_uid = 0;
            this->game_id = 0;
            this->node_type = 0;
            this->node_id = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(6);
            wb.pack_int(this->result);
            wb.pack_int(this->tid);
            wb.pack_int(this->owner_uid);
            wb.pack_int(this->game_id);
            wb.pack_int(this->node_type);
            wb.pack_int(this->node_id);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->result);
            if (--c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_int(this->owner_uid);
            if (--c <= 0) { return; }
            rb.unpack_int(this->game_id);
            if (--c <= 0) { return; }
            rb.unpack_int(this->node_type);
            if (--c <= 0) { return; }
            rb.unpack_int(this->node_id);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return response_query_match::New(); }
        virtual void Destroy() { response_query_match::Delete(this); }
        static response_query_match* New() { response_query_match* p = new response_query_match(); p->retain(); return p; }
        static void Delete(response_query_match* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::response_query_match"; }
    };
    class response_start_match : public eproto::Proto
    {
    public:
        int result;
        int tid;
        response_start_match() : eproto::Proto(), result(0), tid(0) {}
        virtual ~response_start_match(){ Clear(); }
        virtual void Clear()
        {
            this->result = 0;
            this->tid = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(2);
            wb.pack_int(this->result);
            wb.pack_int(this->tid);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->result);
            if (--c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return response_start_match::New(); }
        virtual void Destroy() { response_start_match::Delete(this); }
        static response_start_match* New() { response_start_match* p = new response_start_match(); p->retain(); return p; }
        static void Delete(response_start_match* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::response_start_match"; }
    };
    class invite_game : public eproto::Proto
    {
    public:
        int game_id;
        std::string game_name;
        int showtag;
        int play_countdown;
        int operate_countdown;
        std::vector<std::string> showtag2_version;
        std::string game_info;
        int player_number;
        int is_new;
        int sort_id;
        std::vector<match_price*> price;
        invite_game() : eproto::Proto(), game_id(0), showtag(0), play_countdown(0), operate_countdown(0), player_number(0), is_new(0), sort_id(0) {}
        virtual ~invite_game(){ Clear(); }
        void price_Add(match_price* p){ if(NULL!=p){p->retain();} this->price.push_back(p); }
        match_price* price_New(){ match_price* p = match_price::New(); this->price.push_back(p); return p; }
        virtual void Clear()
        {
            this->game_id = 0;
            this->game_name = "";
            this->showtag = 0;
            this->play_countdown = 0;
            this->operate_countdown = 0;
            this->showtag2_version.clear();
            this->game_info = "";
            this->player_number = 0;
            this->is_new = 0;
            this->sort_id = 0;
            {
                for(size_t i=0; i<this->price.size(); ++i)
                {
                    match_price* v = this->price[i];
                    match_price::Delete(v);
                }
                this->price.clear();
            }
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(11);
            wb.pack_int(this->game_id);
            wb.pack_string(this->game_name);
            wb.pack_int(this->showtag);
            wb.pack_int(this->play_countdown);
            wb.pack_int(this->operate_countdown);
            {
                wb.pack_array(this->showtag2_version.size());
                for(size_t i=0; i<this->showtag2_version.size(); ++i)
                {
                    std::string v = this->showtag2_version[i];
                    wb.pack_string(v);
                }
            }
            wb.pack_string(this->game_info);
            wb.pack_int(this->player_number);
            wb.pack_int(this->is_new);
            wb.pack_int(this->sort_id);
            {
                wb.pack_array(this->price.size());
                for(size_t i=0; i<this->price.size(); ++i)
                {
                    match_price* v = this->price[i];
                    if (v == NULL) { wb.pack_nil(); } else { v->Encode(wb); }
                }
            }
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->game_id);
            if (--c <= 0) { return; }
            rb.unpack_string(this->game_name);
            if (--c <= 0) { return; }
            rb.unpack_int(this->showtag);
            if (--c <= 0) { return; }
            rb.unpack_int(this->play_countdown);
            if (--c <= 0) { return; }
            rb.unpack_int(this->operate_countdown);
            if (--c <= 0) { return; }
            {
                long long int n = rb.unpack_array();
                if (n > 0) {
                    this->showtag2_version.resize(n);
                    for(long long int i=0; i<n; ++i)
                    {
                        std::string v;
                        rb.unpack_string(v);
                        this->showtag2_version[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            rb.unpack_string(this->game_info);
            if (--c <= 0) { return; }
            rb.unpack_int(this->player_number);
            if (--c <= 0) { return; }
            rb.unpack_int(this->is_new);
            if (--c <= 0) { return; }
            rb.unpack_int(this->sort_id);
            if (--c <= 0) { return; }
            {
                long long int n = rb.unpack_array();
                if (n > 0) {
                    this->price.resize(n);
                    for(long long int i=0; i<n; ++i)
                    {
                        match_price* v=NULL;
                        if (rb.nextIsNil()) { rb.moveNext(); } else { match_price::Delete(v); v = match_price::New(); v->Decode(rb); }
                        this->price[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return invite_game::New(); }
        virtual void Destroy() { invite_game::Delete(this); }
        static invite_game* New() { invite_game* p = new invite_game(); p->retain(); return p; }
        static void Delete(invite_game* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::invite_game"; }
    };
    class user_info : public eproto::Proto
    {
    public:
        int uid;
        int signup_time;
        std::unordered_map<int, std::string> data;
        DataType* dt;
        user_info() : eproto::Proto(), uid(0), signup_time(0), dt(NULL) {}
        virtual ~user_info(){ Clear(); }
        DataType* dt_New(){ DataType::Delete(this->dt); this->dt = DataType::New(); return this->dt; }
        void dt_Set(DataType* p){ if(NULL!=p){p->retain();} DataType::Delete(this->dt); this->dt = p; }
        virtual void Clear()
        {
            this->uid = 0;
            this->signup_time = 0;
            this->data.clear();
            if(NULL!=this->dt){ DataType::Delete(this->dt); this->dt=NULL; }
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(4);
            wb.pack_int(this->uid);
            wb.pack_int(this->signup_time);
            {
                wb.pack_map(this->data.size());
                for(auto &i : this->data)
                {
                    wb.pack_int(i.first);
                    wb.pack_string(i.second);
                }
            }
            if (this->dt == NULL) { wb.pack_nil(); } else { this->dt->Encode(wb); }
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->uid);
            if (--c <= 0) { return; }
            rb.unpack_int(this->signup_time);
            if (--c <= 0) { return; }
            {
                long long int n = rb.unpack_map();
                if (n > 0) {
                    for(long long int i=0; i<n; ++i)
                    {
                        int k=0;
                        rb.unpack_int(k);
                        std::string v;
                        rb.unpack_string(v);
                        this->data[k] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            if (rb.nextIsNil()) { rb.moveNext(); } else { DataType::Delete(this->dt); this->dt = DataType::New(); this->dt->Decode(rb); }
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return user_info::New(); }
        virtual void Destroy() { user_info::Delete(this); }
        static user_info* New() { user_info* p = new user_info(); p->retain(); return p; }
        static void Delete(user_info* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::user_info"; }
    };
    class response_invite_config : public eproto::Proto
    {
    public:
        int result;
        int region_code;
        std::vector<invite_game*> games;
        response_invite_config() : eproto::Proto(), result(0), region_code(0) {}
        virtual ~response_invite_config(){ Clear(); }
        void games_Add(invite_game* p){ if(NULL!=p){p->retain();} this->games.push_back(p); }
        invite_game* games_New(){ invite_game* p = invite_game::New(); this->games.push_back(p); return p; }
        virtual void Clear()
        {
            this->result = 0;
            this->region_code = 0;
            {
                for(size_t i=0; i<this->games.size(); ++i)
                {
                    invite_game* v = this->games[i];
                    invite_game::Delete(v);
                }
                this->games.clear();
            }
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(3);
            wb.pack_int(this->result);
            wb.pack_int(this->region_code);
            {
                wb.pack_array(this->games.size());
                for(size_t i=0; i<this->games.size(); ++i)
                {
                    invite_game* v = this->games[i];
                    if (v == NULL) { wb.pack_nil(); } else { v->Encode(wb); }
                }
            }
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->result);
            if (--c <= 0) { return; }
            rb.unpack_int(this->region_code);
            if (--c <= 0) { return; }
            {
                long long int n = rb.unpack_array();
                if (n > 0) {
                    this->games.resize(n);
                    for(long long int i=0; i<n; ++i)
                    {
                        invite_game* v=NULL;
                        if (rb.nextIsNil()) { rb.moveNext(); } else { invite_game::Delete(v); v = invite_game::New(); v->Decode(rb); }
                        this->games[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return response_invite_config::New(); }
        virtual void Destroy() { response_invite_config::Delete(this); }
        static response_invite_config* New() { response_invite_config* p = new response_invite_config(); p->retain(); return p; }
        static void Delete(response_invite_config* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::response_invite_config"; }
    };
    class table_info : public eproto::Proto
    {
    public:
        int game_id;
        std::string game_name;
        int player_number;
        int owner_uid;
        std::string owner_name;
        int tid;
        int create_time;
        int state;
        std::string game_info;
        std::vector<user_info*> signup_users;
        bool ss;
        table_info() : eproto::Proto(), game_id(0), player_number(0), owner_uid(0), tid(0), create_time(0), state(0), ss(false) {}
        virtual ~table_info(){ Clear(); }
        void signup_users_Add(user_info* p){ if(NULL!=p){p->retain();} this->signup_users.push_back(p); }
        user_info* signup_users_New(){ user_info* p = user_info::New(); this->signup_users.push_back(p); return p; }
        virtual void Clear()
        {
            this->game_id = 0;
            this->game_name = "";
            this->player_number = 0;
            this->owner_uid = 0;
            this->owner_name = "";
            this->tid = 0;
            this->create_time = 0;
            this->state = 0;
            this->game_info = "";
            {
                for(size_t i=0; i<this->signup_users.size(); ++i)
                {
                    user_info* v = this->signup_users[i];
                    user_info::Delete(v);
                }
                this->signup_users.clear();
            }
            this->ss = false;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(11);
            wb.pack_int(this->game_id);
            wb.pack_string(this->game_name);
            wb.pack_int(this->player_number);
            wb.pack_int(this->owner_uid);
            wb.pack_string(this->owner_name);
            wb.pack_int(this->tid);
            wb.pack_int(this->create_time);
            wb.pack_int(this->state);
            wb.pack_string(this->game_info);
            {
                wb.pack_array(this->signup_users.size());
                for(size_t i=0; i<this->signup_users.size(); ++i)
                {
                    user_info* v = this->signup_users[i];
                    if (v == NULL) { wb.pack_nil(); } else { v->Encode(wb); }
                }
            }
            wb.pack_bool(this->ss);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->game_id);
            if (--c <= 0) { return; }
            rb.unpack_string(this->game_name);
            if (--c <= 0) { return; }
            rb.unpack_int(this->player_number);
            if (--c <= 0) { return; }
            rb.unpack_int(this->owner_uid);
            if (--c <= 0) { return; }
            rb.unpack_string(this->owner_name);
            if (--c <= 0) { return; }
            rb.unpack_int(this->tid);
            if (--c <= 0) { return; }
            rb.unpack_int(this->create_time);
            if (--c <= 0) { return; }
            rb.unpack_int(this->state);
            if (--c <= 0) { return; }
            rb.unpack_string(this->game_info);
            if (--c <= 0) { return; }
            {
                long long int n = rb.unpack_array();
                if (n > 0) {
                    this->signup_users.resize(n);
                    for(long long int i=0; i<n; ++i)
                    {
                        user_info* v=NULL;
                        if (rb.nextIsNil()) { rb.moveNext(); } else { user_info::Delete(v); v = user_info::New(); v->Decode(rb); }
                        this->signup_users[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            rb.unpack_bool(this->ss);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return table_info::New(); }
        virtual void Destroy() { table_info::Delete(this); }
        static table_info* New() { table_info* p = new table_info(); p->retain(); return p; }
        static void Delete(table_info* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::table_info"; }
    };
    class response_create_match : public eproto::Proto
    {
    public:
        int result;
        table_info* info;
        int prop_type;
        int prop_num;
        response_create_match() : eproto::Proto(), result(0), info(NULL), prop_type(0), prop_num(0) {}
        virtual ~response_create_match(){ Clear(); }
        table_info* info_New(){ table_info::Delete(this->info); this->info = table_info::New(); return this->info; }
        void info_Set(table_info* p){ if(NULL!=p){p->retain();} table_info::Delete(this->info); this->info = p; }
        virtual void Clear()
        {
            this->result = 0;
            if(NULL!=this->info){ table_info::Delete(this->info); this->info=NULL; }
            this->prop_type = 0;
            this->prop_num = 0;
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(4);
            wb.pack_int(this->result);
            if (this->info == NULL) { wb.pack_nil(); } else { this->info->Encode(wb); }
            wb.pack_int(this->prop_type);
            wb.pack_int(this->prop_num);
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            rb.unpack_int(this->result);
            if (--c <= 0) { return; }
            if (rb.nextIsNil()) { rb.moveNext(); } else { table_info::Delete(this->info); this->info = table_info::New(); this->info->Decode(rb); }
            if (--c <= 0) { return; }
            rb.unpack_int(this->prop_type);
            if (--c <= 0) { return; }
            rb.unpack_int(this->prop_num);
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return response_create_match::New(); }
        virtual void Destroy() { response_create_match::Delete(this); }
        static response_create_match* New() { response_create_match* p = new response_create_match(); p->retain(); return p; }
        static void Delete(response_create_match* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::response_create_match"; }
    };
    class response_pull_user_matches : public eproto::Proto
    {
    public:
        std::vector<table_info*> info;
        response_pull_user_matches() : eproto::Proto() {}
        virtual ~response_pull_user_matches(){ Clear(); }
        void info_Add(table_info* p){ if(NULL!=p){p->retain();} this->info.push_back(p); }
        table_info* info_New(){ table_info* p = table_info::New(); this->info.push_back(p); return p; }
        virtual void Clear()
        {
            {
                for(size_t i=0; i<this->info.size(); ++i)
                {
                    table_info* v = this->info[i];
                    table_info::Delete(v);
                }
                this->info.clear();
            }
        }
        virtual void Encode(eproto::Writer& wb)
        {
            wb.pack_array(1);
            {
                wb.pack_array(this->info.size());
                for(size_t i=0; i<this->info.size(); ++i)
                {
                    table_info* v = this->info[i];
                    if (v == NULL) { wb.pack_nil(); } else { v->Encode(wb); }
                }
            }
        }
        virtual void Decode(eproto::Reader& rb)
        {
            long long int c = rb.unpack_array();
            if (c <= 0) { return; }
            {
                long long int n = rb.unpack_array();
                if (n > 0) {
                    this->info.resize(n);
                    for(long long int i=0; i<n; ++i)
                    {
                        table_info* v=NULL;
                        if (rb.nextIsNil()) { rb.moveNext(); } else { table_info::Delete(v); v = table_info::New(); v->Decode(rb); }
                        this->info[i] = v;
                    }
                }
            }
            if (--c <= 0) { return; }
            rb.unpack_discard(c);
        }
        virtual eproto::Proto* Create() { return response_pull_user_matches::New(); }
        virtual void Destroy() { response_pull_user_matches::Delete(this); }
        static response_pull_user_matches* New() { response_pull_user_matches* p = new response_pull_user_matches(); p->retain(); return p; }
        static void Delete(response_pull_user_matches* p) { if(NULL != p){ p->release(); } }
        virtual std::string ClassName() { return "invitemgr::response_pull_user_matches"; }
    };

};


#endif
