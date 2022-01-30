/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <networkjobs.h>

// #include <QDateTime>
// #include <QtGlobal>
// #include <QJsonDocument>
// #include <QJsonValue>
// #include <QLoggingCategory>
// #include <string>
// #include <QJsonObject>
// #include <QJsonArray>
// #include <qdatetime.h>
// #include <qjsonarray.h>
// #include <qjsonobject.h>
// #include <qloggingcategory.h>

// #pragma once

// #include <QPointer>

namespace Occ {


class OcsUserStatusConnector : UserStatusConnector {

    public OcsUserStatusConnector (AccountPointer account, GLib.Object parent = nullptr);

    public void fetch_user_status () override;

    public void fetch_predefined_statuses () override;

    public void set_user_status (UserStatus &user_status) override;

    public void clear_message () override;

    public UserStatus user_status () override;


    private void on_user_status_fetched (QJsonDocument &json, int status_code);
    private void on_predefined_statuses_fetched (QJsonDocument &json, int status_code);
    private void on_user_status_online_status_set (QJsonDocument &json, int status_code);
    private void on_user_status_message_set (QJsonDocument &json, int status_code);
    private void on_message_cleared (QJsonDocument &json, int status_code);

    private void log_response (string message, QJsonDocument &json, int status_code);
    private void start_fetch_user_status_job ();
    private void start_fetch_predefined_statuses ();
    private void set_user_status_online_status (UserStatus.OnlineStatus online_status);
    private void set_user_status_message (UserStatus &user_status);
    private void set_user_status_message_predefined (UserStatus &user_status);
    private void set_user_status_message_custom (UserStatus &user_status);

    private AccountPointer _account;

    private bool _user_status_supported = false;
    private bool _user_status_emojis_supported = false;

    private QPointer<JsonApiJob> _clear_message_job {};
    private QPointer<JsonApiJob> _set_message_job {};
    private QPointer<JsonApiJob> _set_online_status_job {};
    private QPointer<JsonApiJob> _get_predefined_stauses_job {};
    private QPointer<JsonApiJob> _get_user_status_job {};

    private UserStatus _user_status;
};

    Occ.UserStatus.OnlineStatus string_to_user_online_status (string status) {
        // it needs to match the Status enum
        const QHash<string, Occ.UserStatus.OnlineStatus> pre_defined_status {
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
        };

        // api should return invisible, dnd,... to_lower () it is to make sure
        // it matches _pre_defined_status, otherwise the default is online (0)
        return pre_defined_status.value (status.to_lower (), Occ.UserStatus.OnlineStatus.Online);
    }

    string online_status_to_string (Occ.UserStatus.OnlineStatus status) {
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

    Occ.Optional<Occ.ClearAt> json_extract_clear_at (QJsonObject json_object) {
        Occ.Optional<Occ.ClearAt> clear_at {};
        if (json_object.contains ("clear_at") && !json_object.value ("clear_at").is_null ()) {
            Occ.ClearAt clear_at_value;
            clear_at_value._type = Occ.ClearAtType.Timestamp;
            clear_at_value._timestamp = json_object.value ("clear_at").to_int ();
            clear_at = clear_at_value;
        }
        return clear_at;
    }

    Occ.UserStatus json_extract_user_status (QJsonObject json) {
        const var clear_at = json_extract_clear_at (json);

        const Occ.UserStatus user_status (json.value ("message_id").to_string (),
            json.value ("message").to_string ().trimmed (),
            json.value ("icon").to_string ().trimmed (), string_to_user_online_status (json.value ("status").to_string ()),
            json.value ("message_is_predefined").to_bool (false), clear_at);

        return user_status;
    }

    Occ.UserStatus json_to_user_status (QJsonDocument &json) {
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
        };
        const var retrieved_data = json.object ().value ("ocs").to_object ().value ("data").to_object (default_values);
        return json_extract_user_status (retrieved_data);
    }

    uint64 clear_at_end_of_to_timestamp (Occ.ClearAt &clear_at) {
        Q_ASSERT (clear_at._type == Occ.ClearAtType.EndOf);

        if (clear_at._endof == "day") {
            return QDate.current_date ().add_days (1).start_of_day ().to_time_t ();
        } else if (clear_at._endof == "week") {
            const var days = Qt.Sunday - QDate.current_date ().day_of_week ();
            return QDate.current_date ().add_days (days + 1).start_of_day ().to_time_t ();
        }
        GLib.warn (lc_ocs_user_status_connector) << "Can not handle clear at endof day type" << clear_at._endof;
        return QDateTime.current_date_time ().to_time_t ();
    }

    uint64 clear_at_period_to_timestamp (Occ.ClearAt &clear_at) {
        return QDateTime.current_date_time ().add_secs (clear_at._period).to_time_t ();
    }

    uint64 clear_at_to_timestamp (Occ.ClearAt &clear_at) {
        switch (clear_at._type) {
        case Occ.ClearAtType.Period: {
            return clear_at_period_to_timestamp (clear_at);
        }

        case Occ.ClearAtType.EndOf: {
            return clear_at_end_of_to_timestamp (clear_at);
        }

        case Occ.ClearAtType.Timestamp: {
            return clear_at._timestamp;
        }
        }

        return 0;
    }

    uint64 clear_at_to_timestamp (Occ.Optional<Occ.ClearAt> &clear_at) {
        if (clear_at) {
            return clear_at_to_timestamp (*clear_at);
        }
        return 0;
    }

    Occ.Optional<Occ.ClearAt> json_to_clear_at (QJsonObject json_object) {
        Occ.Optional<Occ.ClearAt> clear_at;

        if (json_object.value ("clear_at").is_object () && !json_object.value ("clear_at").is_null ()) {
            Occ.ClearAt clear_at_value;
            const var clear_at_object = json_object.value ("clear_at").to_object ();
            const var type_value = clear_at_object.value ("type").to_string ("period");
            if (type_value == "period") {
                const var time_value = clear_at_object.value ("time").to_int (0);
                clear_at_value._type = Occ.ClearAtType.Period;
                clear_at_value._period = time_value;
            } else if (type_value == "end-of") {
                const var time_value = clear_at_object.value ("time").to_string ("day");
                clear_at_value._type = Occ.ClearAtType.EndOf;
                clear_at_value._endof = time_value;
            } else {
                GLib.warn (lc_ocs_user_status_connector) << "Can not handle clear type value" << type_value;
            }
            clear_at = clear_at_value;
        }

        return clear_at;
    }

    Occ.UserStatus json_to_user_status (QJsonObject json_object) {
        const var clear_at = json_to_clear_at (json_object);

        Occ.UserStatus user_status (
            json_object.value ("id").to_string ("no-id"),
            json_object.value ("message").to_string ("No message"),
            json_object.value ("icon").to_string ("no-icon"),
            Occ.UserStatus.OnlineStatus.Online,
            true,
            clear_at);

        return user_status;
    }

    std.vector<Occ.UserStatus> json_to_predefined_statuses (QJsonArray json_data_array) {
        std.vector<Occ.UserStatus> statuses;
        for (var &json_entry : json_data_array) {
            Q_ASSERT (json_entry.is_object ());
            if (!json_entry.is_object ()) {
                continue;
            }
            statuses.push_back (json_to_user_status (json_entry.to_object ()));
        }

        return statuses;
    }

    const string base_url ("/ocs/v2.php/apps/user_status/api/v1");
    const string user_status_base_url = base_url + QStringLiteral ("/user_status");

    OcsUserStatusConnector.OcsUserStatusConnector (AccountPointer account, GLib.Object parent)
        : UserStatusConnector (parent)
        , _account (account) {
        Q_ASSERT (_account);
        _user_status_supported = _account.capabilities ().user_status ();
        _user_status_emojis_supported = _account.capabilities ().user_status_supports_emoji ();
    }

    void OcsUserStatusConnector.fetch_user_status () {
        GLib.debug (lc_ocs_user_status_connector) << "Try to fetch user status";

        if (!_user_status_supported) {
            GLib.debug (lc_ocs_user_status_connector) << "User status not supported";
            emit error (Error.UserStatusNotSupported);
            return;
        }

        start_fetch_user_status_job ();
    }

    void OcsUserStatusConnector.start_fetch_user_status_job () {
        if (_get_user_status_job) {
            GLib.debug (lc_ocs_user_status_connector) << "Get user status job is already running.";
            return;
        }

        _get_user_status_job = new JsonApiJob (_account, user_status_base_url, this);
        connect (_get_user_status_job, &JsonApiJob.json_received, this, &OcsUserStatusConnector.on_user_status_fetched);
        _get_user_status_job.on_start ();
    }

    void OcsUserStatusConnector.on_user_status_fetched (QJsonDocument &json, int status_code) {
        log_response ("user status fetched", json, status_code);

        if (status_code != 200) {
            q_c_info (lc_ocs_user_status_connector) << "Slot fetch UserStatus on_finished with status code" << status_code;
            emit error (Error.CouldNotFetchUserStatus);
            return;
        }

        _user_status = json_to_user_status (json);
        emit user_status_fetched (_user_status);
    }

    void OcsUserStatusConnector.start_fetch_predefined_statuses () {
        if (_get_predefined_stauses_job) {
            GLib.debug (lc_ocs_user_status_connector) << "Get predefined statuses job is already running";
            return;
        }

        _get_predefined_stauses_job = new JsonApiJob (_account,
            base_url + QStringLiteral ("/predefined_statuses"), this);
        connect (_get_predefined_stauses_job, &JsonApiJob.json_received, this,
            &OcsUserStatusConnector.on_predefined_statuses_fetched);
        _get_predefined_stauses_job.on_start ();
    }

    void OcsUserStatusConnector.fetch_predefined_statuses () {
        if (!_user_status_supported) {
            emit error (Error.UserStatusNotSupported);
            return;
        }
        start_fetch_predefined_statuses ();
    }

    void OcsUserStatusConnector.on_predefined_statuses_fetched (QJsonDocument &json, int status_code) {
        log_response ("predefined statuses", json, status_code);

        if (status_code != 200) {
            q_c_info (lc_ocs_user_status_connector) << "Slot predefined user statuses on_finished with status code" << status_code;
            emit error (Error.CouldNotFetchPredefinedUserStatuses);
            return;
        }
        const var json_data = json.object ().value ("ocs").to_object ().value ("data");
        Q_ASSERT (json_data.is_array ());
        if (!json_data.is_array ()) {
            return;
        }
        const var statuses = json_to_predefined_statuses (json_data.to_array ());
        emit predefined_statuses_fetched (statuses);
    }

    void OcsUserStatusConnector.log_response (string message, QJsonDocument &json, int status_code) {
        GLib.debug (lc_ocs_user_status_connector) << "Response from:" << message << "Status:" << status_code << "Json:" << json;
    }

    void OcsUserStatusConnector.set_user_status_online_status (UserStatus.OnlineStatus online_status) {
        _set_online_status_job = new JsonApiJob (_account,
            user_status_base_url + QStringLiteral ("/status"), this);
        _set_online_status_job.set_verb (JsonApiJob.Verb.Put);
        // Set body
        QJsonObject data_object;
        data_object.insert ("status_type", online_status_to_string (online_status));
        QJsonDocument body;
        body.set_object (data_object);
        _set_online_status_job.set_body (body);
        connect (_set_online_status_job, &JsonApiJob.json_received, this, &OcsUserStatusConnector.on_user_status_online_status_set);
        _set_online_status_job.on_start ();
    }

    void OcsUserStatusConnector.set_user_status_message_predefined (UserStatus &user_status) {
        Q_ASSERT (user_status.message_predefined ());
        if (!user_status.message_predefined ()) {
            return;
        }

        _set_message_job = new JsonApiJob (_account, user_status_base_url + QStringLiteral ("/message/predefined"), this);
        _set_message_job.set_verb (JsonApiJob.Verb.Put);
        // Set body
        QJsonObject data_object;
        data_object.insert ("message_id", user_status.id ());
        if (user_status.clear_at ()) {
            data_object.insert ("clear_at", static_cast<int> (clear_at_to_timestamp (user_status.clear_at ())));
        } else {
            data_object.insert ("clear_at", QJsonValue ());
        }
        QJsonDocument body;
        body.set_object (data_object);
        _set_message_job.set_body (body);
        connect (_set_message_job, &JsonApiJob.json_received, this, &OcsUserStatusConnector.on_user_status_message_set);
        _set_message_job.on_start ();
    }

    void OcsUserStatusConnector.set_user_status_message_custom (UserStatus &user_status) {
        Q_ASSERT (!user_status.message_predefined ());
        if (user_status.message_predefined ()) {
            return;
        }

        if (!_user_status_emojis_supported) {
            emit error (Error.EmojisNotSupported);
            return;
        }
        _set_message_job = new JsonApiJob (_account, user_status_base_url + QStringLiteral ("/message/custom"), this);
        _set_message_job.set_verb (JsonApiJob.Verb.Put);
        // Set body
        QJsonObject data_object;
        data_object.insert ("status_icon", user_status.icon ());
        data_object.insert ("message", user_status.message ());
        const var clear_at = user_status.clear_at ();
        if (clear_at) {
            data_object.insert ("clear_at", static_cast<int> (clear_at_to_timestamp (*clear_at)));
        } else {
            data_object.insert ("clear_at", QJsonValue ());
        }
        QJsonDocument body;
        body.set_object (data_object);
        _set_message_job.set_body (body);
        connect (_set_message_job, &JsonApiJob.json_received, this, &OcsUserStatusConnector.on_user_status_message_set);
        _set_message_job.on_start ();
    }

    void OcsUserStatusConnector.set_user_status_message (UserStatus &user_status) {
        if (user_status.message_predefined ()) {
            set_user_status_message_predefined (user_status);
            return;
        }
        set_user_status_message_custom (user_status);
    }

    void OcsUserStatusConnector.set_user_status (UserStatus &user_status) {
        if (!_user_status_supported) {
            emit error (Error.UserStatusNotSupported);
            return;
        }

        if (_set_online_status_job || _set_message_job) {
            GLib.debug (lc_ocs_user_status_connector) << "Set online status job or set message job are already running.";
            return;
        }

        set_user_status_online_status (user_status.state ());
        set_user_status_message (user_status);
    }

    void OcsUserStatusConnector.on_user_status_online_status_set (QJsonDocument &json, int status_code) {
        log_response ("Online status set", json, status_code);

        if (status_code != 200) {
            emit error (Error.CouldNotSetUserStatus);
            return;
        }
    }

    void OcsUserStatusConnector.on_user_status_message_set (QJsonDocument &json, int status_code) {
        log_response ("Message set", json, status_code);

        if (status_code != 200) {
            emit error (Error.CouldNotSetUserStatus);
            return;
        }

        // We fetch the user status again because json does not contain
        // the new message when user status was set from a predefined
        // message
        fetch_user_status ();

        emit user_status_set ();
    }

    void OcsUserStatusConnector.clear_message () {
        _clear_message_job = new JsonApiJob (_account, user_status_base_url + QStringLiteral ("/message"));
        _clear_message_job.set_verb (JsonApiJob.Verb.Delete);
        connect (_clear_message_job, &JsonApiJob.json_received, this, &OcsUserStatusConnector.on_message_cleared);
        _clear_message_job.on_start ();
    }

    UserStatus OcsUserStatusConnector.user_status () {
        return _user_status;
    }

    void OcsUserStatusConnector.on_message_cleared (QJsonDocument &json, int status_code) {
        log_response ("Message cleared", json, status_code);

        if (status_code != 200) {
            emit error (Error.CouldNotClearMessage);
            return;
        }

        _user_status = {};
        emit message_cleared ();
    }
    }
    