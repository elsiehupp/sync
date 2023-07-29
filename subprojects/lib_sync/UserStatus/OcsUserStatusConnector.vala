namespace Occ {
namespace LibSync {

/***********************************************************
@class OcsUserStatusConnector

@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class OcsUserStatusConnector : AbstractUserStatusConnector {

    const string BASE_URL = "/ocs/v2.php/apps/user_status/api/v1";
    const string USER_STATUS_BASE_URL = BASE_URL + "/user_status";

    /***********************************************************
    ***********************************************************/
    private unowned Account account;

    /***********************************************************
    ***********************************************************/
    private bool user_status_supported = false;

    /***********************************************************
    ***********************************************************/
    private JsonApiJob clear_message_job = new JsonApiJob ();
    private JsonApiJob message_job = new JsonApiJob ();
    private JsonApiJob online_status_job = new JsonApiJob ();
    private JsonApiJob get_predefined_stauses_job = new JsonApiJob ();
    private JsonApiJob get_user_status_job = new JsonApiJob ();

    /***********************************************************
    ***********************************************************/
    UserStatus user_status {
        public get {
            return this.user_status;
        }
        public set {
            if (!this.user_status_supported) {
                signal_error (Error.USER_STATUS_NOT_SUPPORTED);
                return;
            }

            if (this.online_status_job || this.message_job) {
                GLib.debug ("Set online status job or set message job are already running.");
                return;
            }

            user_status_online_status (value.state);
            user_status_message (value);
        }
    }


    /***********************************************************
    ***********************************************************/
    public OcsUserStatusConnector (Account account) {
        //  base ();
        //  this.account = account;
        //  GLib.assert (this.account);
        //  this.user_status_supported = this.account.capabilities.user_status ();
        //  this.user_status_emojis_supported = this.account.capabilities.user_status_supports_emoji ();
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_user_status () {
        //  GLib.debug ("Try to fetch user status.");

        //  if (!this.user_status_supported) {
        //      GLib.debug ("User status not supported.");
        //      signal_error (Error.USER_STATUS_NOT_SUPPORTED);
        //      return;
        //  }

        //  start_fetch_user_status_job ();
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_predefined_statuses () {
        //  if (!this.user_status_supported) {
        //      signal_error (Error.USER_STATUS_NOT_SUPPORTED);
        //      return;
        //  }
        //  start_fetch_predefined_statuses ();
    }




    /***********************************************************
    ***********************************************************/
    public void clear_message () {
        //  this.clear_message_job = new JsonApiJob (this.account, USER_STATUS_BASE_URL + "/message");
        //  this.clear_message_job.verb = JsonApiJob.Verb.DELETE;
        //  this.clear_message_job.signal_json_received.connect (
        //      this.on_signal_message_cleared
        //  );
        //  this.clear_message_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_user_status_fetched (GLib.JsonDocument json, int status_code) {
        //  log_response ("user status fetched", json, status_code);

        //  if (status_code != 200) {
        //      GLib.info ("Slot fetch UserStatus finished with status code " + status_code.to_string ());
        //      signal_error (Error.COULD_NOT_FETCH_USER_STATUS);
        //      return;
        //  }

        //  this.user_status = json_to_user_status (json);
        //  signal_user_status_fetched (this.user_status);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_predefined_statuses_fetched (GLib.JsonDocument json, int status_code) {
        //  log_response ("predefined statuses", json, status_code);

        //  if (status_code != 200) {
        //      GLib.info ("Slot predefined user statuses finished with status code " + status_code.to_string ());
        //      signal_error (Error.COULD_NOT_FETCH_PREDEFINED_USER_STATUSES);
        //      return;
        //  }
        //  var json_data = json.object ().value ("ocs").to_object ().value ("data");
        //  GLib.assert (json_data.is_array ());
        //  if (!json_data.is_array ()) {
        //      return;
        //  }
        //  var statuses = json_to_predefined_statuses (json_data.to_array ());
        //  signal_predefined_statuses_fetched (statuses);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_user_status_online_status_set (GLib.JsonDocument json, int status_code) {
        //  log_response ("Online status set", json, status_code);

        //  if (status_code != 200) {
        //      signal_error (Error.COULD_NOT_SET_USER_STATUS);
        //      return;
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_user_status_message_set (GLib.JsonDocument json, int status_code) {
        //  log_response ("Message set", json, status_code);

        //  if (status_code != 200) {
        //      signal_error (Error.COULD_NOT_SET_USER_STATUS);
        //      return;
        //  }

        //  // We fetch the user status again because json does not contain
        //  // the new message when user status was set from a predefined
        //  // message
        //  fetch_user_status ();

        //  signal_user_status_set ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_message_cleared (GLib.JsonDocument json, int status_code) {
        //  log_response ("Message cleared", json, status_code);

        //  if (status_code != 200) {
        //      signal_error (Error.COULD_NOT_CLEAR_MESSAGE);
        //      return;
        //  }

        //  this.user_status = new JsonApiJob ();
        //  signal_message_cleared ();
    }


    /***********************************************************
    ***********************************************************/
    private void log_response (string message, GLib.JsonDocument json, int status_code) {
        //  GLib.debug ("Response from: " + message + " Status: " + status_code.to_string () +  " Json: " + json.to_string ());
    }


    /***********************************************************
    ***********************************************************/
    private void start_fetch_user_status_job () {
        //  if (this.get_user_status_job) {
        //      GLib.debug ("Get user status job is already running.");
        //      return;
        //  }

        //  this.get_user_status_job = new JsonApiJob (this.account, USER_STATUS_BASE_URL, this);
        //  this.get_user_status_job.signal_json_received.connect (
        //      this.on_signal_user_status_fetched
        //  );
        //  this.get_user_status_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void start_fetch_predefined_statuses () {
        //  if (this.get_predefined_stauses_job) {
        //      GLib.debug ("Get predefined statuses job is already running.");
        //      return;
        //  }

        //  this.get_predefined_stauses_job = new JsonApiJob (
        //      this.account,
        //      BASE_URL + "/predefined_statuses",
        //      this
        //  );
        //  this.get_predefined_stauses_job.signal_json_received.connect (
        //      this.on_signal_predefined_statuses_fetched
        //  );
        //  this.get_predefined_stauses_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void user_status_online_status (UserStatus.OnlineStatus online_status) {
        //  this.online_status_job = new JsonApiJob (
        //      this.account,
        //      USER_STATUS_BASE_URL + "/status",
        //      this
        //  );
        //  this.online_status_job.verb = JsonApiJob.Verb.PUT;
        //  // Set body
        //  Json.Object data_object;
        //  data_object.insert ("status_type", online_status_to_string (online_status));
        //  GLib.JsonDocument body;
        //  body.object (data_object);
        //  this.online_status_job.body = body;
        //  this.online_status_job.signal_json_received.connect (
        //      this.on_signal_user_status_online_status_set
        //  );
        //  this.online_status_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void user_status_message (UserStatus user_status) {
        //  if (user_status.message_predefined) {
        //      user_status_message_predefined = user_status;
        //      return;
        //  }
        //  user_status_message_custom (user_status);
    }


    /***********************************************************
    ***********************************************************/
    private void user_status_message_predefined (UserStatus user_status) {
        //  GLib.assert (user_status.message_predefined);
        //  if (!user_status.message_predefined) {
        //      return;
        //  }

        //  this.message_job = new JsonApiJob (this.account, USER_STATUS_BASE_URL + "/message/predefined", this);
        //  this.message_job.verb = JsonApiJob.Verb.PUT;
        //  // Set body
        //  Json.Object data_object;
        //  data_object.insert ("message_id", user_status.identifier);
        //  if (user_status.clear_at) {
        //      data_object.insert ("clear_at", (int)clear_at_to_timestamp (user_status.clear_at ()));
        //  } else {
        //      data_object.insert ("clear_at", GLib.JsonValue ());
        //  }
        //  GLib.JsonDocument body;
        //  body.object (data_object);
        //  this.message_job.body = body;
        //  this.message_job.signal_json_received.connect (
        //      this.on_signal_user_status_message_set
        //  );
        //  this.message_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void user_status_message_custom (UserStatus user_status) {
        //  GLib.assert (!user_status.message_predefined);
        //  if (user_status.message_predefined) {
        //      return;
        //  }

        //  if (!this.user_status_emojis_supported) {
        //      signal_error (Error.EMOJIS_NOT_SUPPORTED);
        //      return;
        //  }
        //  this.message_job = new JsonApiJob (this.account, USER_STATUS_BASE_URL + "/message/custom", this);
        //  this.message_job.verb = JsonApiJob.Verb.PUT;
        //  // Set body
        //  Json.Object data_object;
        //  data_object.insert ("status_icon", user_status.icon ());
        //  data_object.insert ("message", user_status.message ());
        //  var clear_at = user_status.clear_at;
        //  if (clear_at) {
        //      data_object.insert ("clear_at", (int)clear_at_to_timestamp (clear_at));
        //  } else {
        //      data_object.insert ("clear_at", GLib.JsonValue ());
        //  }
        //  GLib.JsonDocument body;
        //  body.object (data_object);
        //  this.message_job.body = body;
        //  this.message_job.signal_json_received.connect (
        //      this.on_signal_user_status_message_set
        //  );
        //  this.message_job.start ();
    }


    private static UserStatus.OnlineStatus string_to_user_online_status (string status) {
        //  // it needs to match the Status enum
        //  GLib.HashTable<string, UserStatus.OnlineStatus> pre_defined_status = new GLib.HashTable<string, UserStatus.OnlineStatus> (str_hash, str_equal);
        //  pre_defined_status.set (
        //      "online", UserStatus.OnlineStatus.ONLINE
        //  );
        //  pre_defined_status.set (
        //      "dnd", UserStatus.OnlineStatus.DO_NOT_DISTURB
        //  );
        //  pre_defined_status.set (
        //      "away", UserStatus.OnlineStatus.AWAY
        //  );
        //  pre_defined_status.set (
        //      "offline", UserStatus.OnlineStatus.OFFLINE
        //  );
        //  pre_defined_status.set (
        //      "invisible", UserStatus.OnlineStatus.INVISIBLE
        //  );

        //  // api should return invisible, dnd,... down () it is to make sure
        //  // it matches this.pre_defined_status, otherwise the default is online (0)
        //  if (pre_defined_status.contains (status.down ())) {
        //      return pre_defined_status.get (status.down ());
        //  } else {
        //      return UserStatus.OnlineStatus.ONLINE;
        //  }
    }


    private static string online_status_to_string (UserStatus.OnlineStatus status) {
        //  switch (status) {
        //  case UserStatus.OnlineStatus.ONLINE:
        //      return "online";
        //  case UserStatus.OnlineStatus.DO_NOT_DISTURB:
        //      return "dnd";
        //  case UserStatus.OnlineStatus.AWAY:
        //      return "offline";
        //  case UserStatus.OnlineStatus.OFFLINE:
        //      return "offline";
        //  case UserStatus.OnlineStatus.INVISIBLE:
        //      return "invisible";
        //  }
        //  return "online";
    }


    private static Gpseq.Optional<ClearAt> json_extract_clear_at (Json.Object json_object) {
        //  Gpseq.Optional<ClearAt> clear_at = new JsonApiJob ();
        //  if (json_object.contains ("clear_at") && !json_object.value ("clear_at") == null) {
        //      ClearAt clear_at_value;
        //      clear_at_value.type = ClearAtType.TIMESTAMP;
        //      clear_at_value.timestamp = json_object.value ("clear_at").to_int ();
        //      clear_at = clear_at_value;
        //  }
        //  return clear_at;
    }


    private static UserStatus json_extract_user_status (Json.Object json) {
        //  return new UserStatus (
        //      json.value ("message_id").to_string (),
        //      json.value ("message").to_string ().trimmed (),
        //      json.value ("icon").to_string ().trimmed (),
        //      string_to_user_online_status (json.value ("status").to_string ()),
        //      json.value ("message_is_predefined").to_bool (false),
        //      json_extract_clear_at (json)
        //  );
    }


    private static UserStatus json_document_to_user_status (GLib.JsonDocument json) {
        //  Json.Object d = new Json.Object (
        //      {
        //          "icon",
        //          ""
        //      },
        //      {
        //          "message",
        //          ""
        //      },
        //      {
        //          "status",
        //          "online"
        //      },
        //      {
        //          "message_is_predefined",
        //          "false"
        //      },
        //      {
        //          "status_is_user_defined",
        //          "false"
        //      }
        //  );
        //  var retrieved_data = json.object ().value ("ocs").to_object ().value ("data").to_object (default_values);
        //  return json_extract_user_status (retrieved_data);
    }


    private static uint64 clear_at_end_of_to_timestamp (ClearAt clear_at) {
        //  GLib.assert (clear_at.type == ClearAtType.END_OF);

        //  if (clear_at.endof == "day") {
        //      return GLib.Date.current_date ().add_days (1).start_of_day ().to_time_t ();
        //  } else if (clear_at.endof == "week") {
        //      var days = GLib.Sunday - GLib.Date.current_date ().day_of_week ();
        //      return GLib.Date.current_date ().add_days (days + 1).start_of_day ().to_time_t ();
        //  }
        //  GLib.warning ("Can not handle clear at endof day type " + clear_at.endof);
        //  return GLib.DateTime.current_date_time ().to_time_t ();
    }


    private static uint64 clear_at_period_to_timestamp (ClearAt clear_at) {
        //  return GLib.DateTime.current_date_time ().add_secs (clear_at.period).to_time_t ();
    }


    private static uint64 clear_at_to_timestamp (ClearAt clear_at) {
        //  switch (clear_at.type) {
        //  case ClearAtType.PERIOD: {
        //      return clear_at_period_to_timestamp (clear_at);
        //  }

        //  case ClearAtType.END_OF: {
        //      return clear_at_end_of_to_timestamp (clear_at);
        //  }

        //  case ClearAtType.TIMESTAMP: {
        //      return clear_at.timestamp;
        //  }
        //  }

        //  return 0;
    }


    private static uint64 clear_at_to_timestamp_optional (Gpseq.Optional<ClearAt> clear_at) {
        //  if (clear_at) {
        //      return clear_at_to_timestamp (clear_at);
        //  }
        //  return 0;
    }


    private static Gpseq.Optional<ClearAt> json_to_clear_at (Json.Object json_object) {
        //  Gpseq.Optional<ClearAt> clear_at;

        //  if (json_object.value ("clear_at").is_object () && !json_object.value ("clear_at") == null) {
        //      ClearAt clear_at_value;
        //      var clear_at_object = json_object.value ("clear_at").to_object ();
        //      var type_value = clear_at_object.value ("type").to_string () + " period";
        //      if (type_value == "period") {
        //          var time_value = clear_at_object.value ("time").to_int (0);
        //          clear_at_value.type = ClearAtType.PERIOD;
        //          clear_at_value.period = time_value;
        //      } else if (type_value == "end-of") {
        //          var time_value = clear_at_object.value ("time").to_string () + " day";
        //          clear_at_value.type = ClearAtType.END_OF;
        //          clear_at_value.endof = time_value;
        //      } else {
        //          GLib.warning ("Can not handle clear type value " + type_value);
        //      }
        //      clear_at = clear_at_value;
        //  }

        //  return clear_at;
    }


    private static UserStatus json_object_to_user_status (Json.Object json_object) {
        //  return new UserStatus (
        //      json_object.value ("identifier").to_string () + "no-identifier",
        //      json_object.value ("message").to_string () + "No message",
        //      json_object.value ("icon").to_string () + "no-icon",
        //      UserStatus.OnlineStatus.ONLINE,
        //      true,
        //      json_to_clear_at (json_object)
        //  );
    }


    private static GLib.List<UserStatus> json_to_predefined_statuses (GLib.JsonArray json_data_array) {
        //  GLib.List<UserStatus> statuses;
        //  foreach (var json_entry in json_data_array) {
        //      GLib.assert (json_entry.is_object ());
        //      if (!json_entry.is_object ()) {
        //          continue;
        //      }
        //      statuses.push_back (json_object_to_user_status (json_entry.to_object ()));
        //  }

        //  return statuses;
    }

} // class OcsUserStatusConnector

} // namespace LibSync
} // namespace Occ
    