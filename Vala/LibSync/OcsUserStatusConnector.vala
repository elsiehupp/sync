/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <networkjobs.h>
//  #include <QtGlobal>
//  #include <QJsonDocume
//  #include <QJsonValue>
//  #include <QLoggingCate
//  #include <QJsonObject
//  #include <QJsonArray>
//  #include <qdatetime.h>
//  #include <qjsonarray.h>
//  #include <qjsonobject.h>
//  #include <qloggingcategory.h>


//  #include <QPointer>

namespace Occ {

class OcsUserStatusConnector : UserStatusConnector {

    const string BASE_URL = "/ocs/v2.php/apps/user_status/api/v1";
    const string USER_STATUS_BASE_URL = BASE_URL + "/user_status";

    /***********************************************************
    ***********************************************************/
    private AccountPointer account;

    /***********************************************************
    ***********************************************************/
    private bool user_status_supported = false;

    /***********************************************************
    ***********************************************************/
    private QPointer<JsonApiJob> clear_message_job {};
    private QPointer<JsonApiJob> message_job {};
    private QPointer<JsonApiJob> online_status_job {};
    private QPointer<JsonApiJob> get_predefined_stauses_job {};
    private QPointer<JsonApiJob> get_user_status_job {};

    /***********************************************************
    ***********************************************************/
    private UserStatus user_status;

    /***********************************************************
    ***********************************************************/
    public OcsUserStatusConnector (AccountPointer account, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account = account;
        //  Q_ASSERT (this.account);
        this.user_status_supported = this.account.capabilities ().user_status ();
        this.user_status_emojis_supported = this.account.capabilities ().user_status_supports_emoji ();
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_user_status () {
        GLib.debug ("Try to fetch user status";

        if (!this.user_status_supported) {
            GLib.debug ("User status not supported";
            /* emit */ error (Error.UserStatusNotSupported);
            return;
        }

        start_fetch_user_status_job ();
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_predefined_statuses () {
        if (!this.user_status_supported) {
            /* emit */ error (Error.UserStatusNotSupported);
            return;
        }
        start_fetch_predefined_statuses ();
    }


    /***********************************************************
    ***********************************************************/
    public void user_status (UserStatus user_status) {
        if (!this.user_status_supported) {
            /* emit */ error (Error.UserStatusNotSupported);
            return;
        }

        if (this.online_status_job || this.message_job) {
            GLib.debug ("Set online status job or set message job are already running.";
            return;
        }

        user_status_online_status (user_status.state ());
        user_status_message (user_status);
    }


    /***********************************************************
    ***********************************************************/
    public void clear_message () {
        this.clear_message_job = new JsonApiJob (this.account, USER_STATUS_BASE_URL + QStringLiteral ("/message"));
        this.clear_message_job.verb (JsonApiJob.Verb.DELETE);
        connect (this.clear_message_job, &JsonApiJob.json_received, this, &OcsUserStatusConnector.on_signal_message_cleared);
        this.clear_message_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    public UserStatus user_status () {
        return this.user_status;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_user_status_fetched (QJsonDocument json, int status_code) {
        log_response ("user status fetched", json, status_code);

        if (status_code != 200) {
            GLib.info ("Slot fetch UserStatus on_signal_finished with status code" + status_code;
            /* emit */ error (Error.CouldNotFetchUserStatus);
            return;
        }

        this.user_status = json_to_user_status (json);
        /* emit */ user_status_fetched (this.user_status);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_predefined_statuses_fetched (QJsonDocument json, int status_code) {
        log_response ("predefined statuses", json, status_code);

        if (status_code != 200) {
            GLib.info ("Slot predefined user statuses on_signal_finished with status code" + status_code;
            /* emit */ error (Error.CouldNotFetchPredefinedUserStatuses);
            return;
        }
        var json_data = json.object ().value ("ocs").to_object ().value ("data");
        //  Q_ASSERT (json_data.is_array ());
        if (!json_data.is_array ()) {
            return;
        }
        var statuses = json_to_predefined_statuses (json_data.to_array ());
        /* emit */ predefined_statuses_fetched (statuses);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_user_status_online_status_set (QJsonDocument json, int status_code) {
        log_response ("Online status set", json, status_code);

        if (status_code != 200) {
            /* emit */ error (Error.CouldNotSetUserStatus);
            return;
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_user_status_message_set (QJsonDocument json, int status_code) {
        log_response ("Message set", json, status_code);

        if (status_code != 200) {
            /* emit */ error (Error.CouldNotSetUserStatus);
            return;
        }

        // We fetch the user status again because json does not contain
        // the new message when user status was set from a predefined
        // message
        fetch_user_status ();

        /* emit */ user_status_set ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_message_cleared (QJsonDocument json, int status_code) {
        log_response ("Message cleared", json, status_code);

        if (status_code != 200) {
            /* emit */ error (Error.CouldNotClearMessage);
            return;
        }

        this.user_status = {};
        /* emit */ message_cleared ();
    }


    /***********************************************************
    ***********************************************************/
    private void log_response (string message, QJsonDocument json, int status_code) {
        GLib.debug ("Response from:" + message + "Status:" + status_code + "Json:" + json;
    }


    /***********************************************************
    ***********************************************************/
    private void start_fetch_user_status_job () {
        if (this.get_user_status_job) {
            GLib.debug ("Get user status job is already running.";
            return;
        }

        this.get_user_status_job = new JsonApiJob (this.account, USER_STATUS_BASE_URL, this);
        connect (this.get_user_status_job, &JsonApiJob.json_received, this, &OcsUserStatusConnector.on_signal_user_status_fetched);
        this.get_user_status_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void start_fetch_predefined_statuses () {
        if (this.get_predefined_stauses_job) {
            GLib.debug ("Get predefined statuses job is already running";
            return;
        }

        this.get_predefined_stauses_job = new JsonApiJob (this.account,
            BASE_URL + QStringLiteral ("/predefined_statuses"), this);
        connect (this.get_predefined_stauses_job, &JsonApiJob.json_received, this,
            &OcsUserStatusConnector.on_signal_predefined_statuses_fetched);
        this.get_predefined_stauses_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void user_status_online_status (UserStatus.OnlineStatus online_status) {
        this.online_status_job = new JsonApiJob (this.account,
            USER_STATUS_BASE_URL + QStringLiteral ("/status"), this);
        this.online_status_job.verb (JsonApiJob.Verb.PUT);
        // Set body
        QJsonObject data_object;
        data_object.insert ("status_type", online_status_to_string (online_status));
        QJsonDocument body;
        body.object (data_object);
        this.online_status_job.body (body);
        connect (this.online_status_job, &JsonApiJob.json_received, this, &OcsUserStatusConnector.on_signal_user_status_online_status_set);
        this.online_status_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void user_status_message (UserStatus user_status) {
        if (user_status.message_predefined ()) {
            user_status_message_predefined (user_status);
            return;
        }
        user_status_message_custom (user_status);
    }


    /***********************************************************
    ***********************************************************/
    private void user_status_message_predefined (UserStatus user_status) {
        //  Q_ASSERT (user_status.message_predefined ());
        if (!user_status.message_predefined ()) {
            return;
        }

        this.message_job = new JsonApiJob (this.account, USER_STATUS_BASE_URL + QStringLiteral ("/message/predefined"), this);
        this.message_job.verb (JsonApiJob.Verb.PUT);
        // Set body
        QJsonObject data_object;
        data_object.insert ("message_id", user_status.identifier ());
        if (user_status.clear_at ()) {
            data_object.insert ("clear_at", static_cast<int> (clear_at_to_timestamp (user_status.clear_at ())));
        } else {
            data_object.insert ("clear_at", QJsonValue ());
        }
        QJsonDocument body;
        body.object (data_object);
        this.message_job.body (body);
        connect (this.message_job, &JsonApiJob.json_received, this, &OcsUserStatusConnector.on_signal_user_status_message_set);
        this.message_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void user_status_message_custom (UserStatus user_status) {
        //  Q_ASSERT (!user_status.message_predefined ());
        if (user_status.message_predefined ()) {
            return;
        }

        if (!this.user_status_emojis_supported) {
            /* emit */ error (Error.EmojisNotSupported);
            return;
        }
        this.message_job = new JsonApiJob (this.account, USER_STATUS_BASE_URL + QStringLiteral ("/message/custom"), this);
        this.message_job.verb (JsonApiJob.Verb.PUT);
        // Set body
        QJsonObject data_object;
        data_object.insert ("status_icon", user_status.icon ());
        data_object.insert ("message", user_status.message ());
        var clear_at = user_status.clear_at ();
        if (clear_at) {
            data_object.insert ("clear_at", static_cast<int> (clear_at_to_timestamp (*clear_at)));
        } else {
            data_object.insert ("clear_at", QJsonValue ());
        }
        QJsonDocument body;
        body.object (data_object);
        this.message_job.body (body);
        connect (this.message_job, &JsonApiJob.json_received, this, &OcsUserStatusConnector.on_signal_user_status_message_set);
        this.message_job.on_signal_start ();
    }


    private static Occ.UserStatus.OnlineStatus string_to_user_online_status (string status) {
        // it needs to match the Status enum
        const GLib.HashMap<string, Occ.UserStatus.OnlineStatus> pre_defined_status {
            {
                "online", Occ.UserStatus.OnlineStatus.Online
            },
            {
                "dnd", Occ.UserStatus.OnlineStatus.DoNotDisturb
            },
            {
                "away", Occ.UserStatus.OnlineStatus.Away
            },
            {
                "offline", Occ.UserStatus.OnlineStatus.Offline
            },
            {
                "invisible", Occ.UserStatus.OnlineStatus.Invisible
            }
        }

        // api should return invisible, dnd,... to_lower () it is to make sure
        // it matches this.pre_defined_status, otherwise the default is online (0)
        return pre_defined_status.value (status.to_lower (), Occ.UserStatus.OnlineStatus.Online);
    }


    private static string online_status_to_string (Occ.UserStatus.OnlineStatus status) {
        switch (status) {
        case Occ.UserStatus.OnlineStatus.Online:
            return QStringLiteral ("online");
        case Occ.UserStatus.OnlineStatus.DoNotDisturb:
            return QStringLiteral ("dnd");
        case Occ.UserStatus.OnlineStatus.Away:
            return QStringLiteral ("offline");
        case Occ.UserStatus.OnlineStatus.Offline:
            return QStringLiteral ("offline");
        case Occ.UserStatus.OnlineStatus.Invisible:
            return QStringLiteral ("invisible");
        }
        return QStringLiteral ("online");
    }


    private static Occ.Optional<Occ.ClearAt> json_extract_clear_at (QJsonObject json_object) {
        Occ.Optional<Occ.ClearAt> clear_at {};
        if (json_object.contains ("clear_at") && !json_object.value ("clear_at").is_null ()) {
            Occ.ClearAt clear_at_value;
            clear_at_value.type = Occ.ClearAtType.Timestamp;
            clear_at_value.timestamp = json_object.value ("clear_at").to_int ();
            clear_at = clear_at_value;
        }
        return clear_at;
    }


    private static Occ.UserStatus json_extract_user_status (QJsonObject json) {
        var clear_at = json_extract_clear_at (json);

        const Occ.UserStatus user_status (json.value ("message_id").to_string (),
            json.value ("message").to_string ().trimmed (),
            json.value ("icon").to_string ().trimmed (), string_to_user_online_status (json.value ("status").to_string ()),
            json.value ("message_is_predefined").to_bool (false), clear_at);

        return user_status;
    }


    private static Occ.UserStatus json_to_user_status (QJsonDocument json) {
        {
            QJsonObject d
            {
                "icon", ""
            },
            {
                "message", ""
            },
            {
                "status", "online"
            },
            {
                "message_is_predefined", "false"
            },
            {
                "status_is_user_defined", "false"
            }
        }
        var retrieved_data = json.object ().value ("ocs").to_object ().value ("data").to_object (default_values);
        return json_extract_user_status (retrieved_data);
    }


    private static uint64 clear_at_end_of_to_timestamp (Occ.ClearAt clear_at) {
        //  Q_ASSERT (clear_at.type == Occ.ClearAtType.EndOf);

        if (clear_at.endof == "day") {
            return QDate.current_date ().add_days (1).start_of_day ().to_time_t ();
        } else if (clear_at.endof == "week") {
            var days = Qt.Sunday - QDate.current_date ().day_of_week ();
            return QDate.current_date ().add_days (days + 1).start_of_day ().to_time_t ();
        }
        GLib.warning ("Can not handle clear at endof day type" + clear_at.endof;
        return GLib.DateTime.current_date_time ().to_time_t ();
    }


    private static uint64 clear_at_period_to_timestamp (Occ.ClearAt clear_at) {
        return GLib.DateTime.current_date_time ().add_secs (clear_at.period).to_time_t ();
    }


    private static uint64 clear_at_to_timestamp (Occ.ClearAt clear_at) {
        switch (clear_at.type) {
        case Occ.ClearAtType.Period: {
            return clear_at_period_to_timestamp (clear_at);
        }

        case Occ.ClearAtType.EndOf: {
            return clear_at_end_of_to_timestamp (clear_at);
        }

        case Occ.ClearAtType.Timestamp: {
            return clear_at.timestamp;
        }
        }

        return 0;
    }


    private static uint64 clear_at_to_timestamp (Occ.Optional<Occ.ClearAt> clear_at) {
        if (clear_at) {
            return clear_at_to_timestamp (*clear_at);
        }
        return 0;
    }


    private static Occ.Optional<Occ.ClearAt> json_to_clear_at (QJsonObject json_object) {
        Occ.Optional<Occ.ClearAt> clear_at;

        if (json_object.value ("clear_at").is_object () && !json_object.value ("clear_at").is_null ()) {
            Occ.ClearAt clear_at_value;
            var clear_at_object = json_object.value ("clear_at").to_object ();
            var type_value = clear_at_object.value ("type").to_string () + "period");
            if (type_value == "period") {
                var time_value = clear_at_object.value ("time").to_int (0);
                clear_at_value.type = Occ.ClearAtType.Period;
                clear_at_value.period = time_value;
            } else if (type_value == "end-of") {
                var time_value = clear_at_object.value ("time").to_string () + "day");
                clear_at_value.type = Occ.ClearAtType.EndOf;
                clear_at_value.endof = time_value;
            } else {
                GLib.warning ("Can not handle clear type value" + type_value;
            }
            clear_at = clear_at_value;
        }

        return clear_at;
    }


    private static Occ.UserStatus json_to_user_status (QJsonObject json_object) {
        var clear_at = json_to_clear_at (json_object);

        Occ.UserStatus user_status (
            json_object.value ("identifier").to_string () + "no-identifier"),
            json_object.value ("message").to_string () + "No message"),
            json_object.value ("icon").to_string () + "no-icon"),
            Occ.UserStatus.OnlineStatus.Online,
            true,
            clear_at);

        return user_status;
    }


    private static GLib.Vector<Occ.UserStatus> json_to_predefined_statuses (QJsonArray json_data_array) {
        GLib.Vector<Occ.UserStatus> statuses;
        foreach (var json_entry in json_data_array) {
            //  Q_ASSERT (json_entry.is_object ());
            if (!json_entry.is_object ()) {
                continue;
            }
            statuses.push_back (json_to_user_status (json_entry.to_object ()));
        }

        return statuses;
    }

} // class OcsUserStatusConnector

} // namespace Occ
    