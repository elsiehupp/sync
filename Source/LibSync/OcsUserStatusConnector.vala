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


class Ocs_user_status_connector : User_status_connector {
public:
    Ocs_user_status_connector (AccountPtr account, GLib.Object *parent = nullptr);

    void fetch_user_status () override;

    void fetch_predefined_statuses () override;

    void set_user_status (User_status &user_status) override;

    void clear_message () override;

    User_status user_status () const override;

private:
    void on_user_status_fetched (QJsonDocument &json, int status_code);
    void on_predefined_statuses_fetched (QJsonDocument &json, int status_code);
    void on_user_status_online_status_set (QJsonDocument &json, int status_code);
    void on_user_status_message_set (QJsonDocument &json, int status_code);
    void on_message_cleared (QJsonDocument &json, int status_code);

    void log_response (string &message, QJsonDocument &json, int status_code);
    void start_fetch_user_status_job ();
    void start_fetch_predefined_statuses ();
    void set_user_status_online_status (User_status.Online_status online_status);
    void set_user_status_message (User_status &user_status);
    void set_user_status_message_predefined (User_status &user_status);
    void set_user_status_message_custom (User_status &user_status);

    AccountPtr _account;

    bool _user_status_supported = false;
    bool _user_status_emojis_supported = false;

    QPointer<JsonApiJob> _clear_message_job {};
    QPointer<JsonApiJob> _set_message_job {};
    QPointer<JsonApiJob> _set_online_status_job {};
    QPointer<JsonApiJob> _get_predefined_stauses_job {};
    QPointer<JsonApiJob> _get_user_status_job {};

    User_status _user_status;
};

    Occ.User_status.Online_status string_to_user_online_status (string &status) {
        // it needs to match the Status enum
        const QHash<string, Occ.User_status.Online_status> pre_defined_status {
            {
                "online", Occ.User_status.Online_status.Online
            },
            {
                "dnd", Occ.User_status.Online_status.Do_not_disturb
            },
            {
                "away", Occ.User_status.Online_status.Away
            },
            {
                "offline", Occ.User_status.Online_status.Offline
            },
            {
                "invisible", Occ.User_status.Online_status.Invisible
            }
        };

        // api should return invisible, dnd,... to_lower () it is to make sure
        // it matches _pre_defined_status, otherwise the default is online (0)
        return pre_defined_status.value (status.to_lower (), Occ.User_status.Online_status.Online);
    }

    string online_status_to_string (Occ.User_status.Online_status status) {
        switch (status) {
        case Occ.User_status.Online_status.Online:
            return QStringLiteral ("online");
        case Occ.User_status.Online_status.Do_not_disturb:
            return QStringLiteral ("dnd");
        case Occ.User_status.Online_status.Away:
            return QStringLiteral ("offline");
        case Occ.User_status.Online_status.Offline:
            return QStringLiteral ("offline");
        case Occ.User_status.Online_status.Invisible:
            return QStringLiteral ("invisible");
        }
        return QStringLiteral ("online");
    }

    Occ.Optional<Occ.Clear_at> json_extract_clear_at (QJsonObject json_object) {
        Occ.Optional<Occ.Clear_at> clear_at {};
        if (json_object.contains ("clear_at") && !json_object.value ("clear_at").is_null ()) {
            Occ.Clear_at clear_at_value;
            clear_at_value._type = Occ.Clear_at_type.Timestamp;
            clear_at_value._timestamp = json_object.value ("clear_at").to_int ();
            clear_at = clear_at_value;
        }
        return clear_at;
    }

    Occ.User_status json_extract_user_status (QJsonObject json) {
        const auto clear_at = json_extract_clear_at (json);

        const Occ.User_status user_status (json.value ("message_id").to_string (),
            json.value ("message").to_string ().trimmed (),
            json.value ("icon").to_string ().trimmed (), string_to_user_online_status (json.value ("status").to_string ()),
            json.value ("message_is_predefined").to_bool (false), clear_at);

        return user_status;
    }

    Occ.User_status json_to_user_status (QJsonDocument &json) {
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
        const auto retrieved_data = json.object ().value ("ocs").to_object ().value ("data").to_object (default_values);
        return json_extract_user_status (retrieved_data);
    }

    uint64 clear_at_end_of_to_timestamp (Occ.Clear_at &clear_at) {
        Q_ASSERT (clear_at._type == Occ.Clear_at_type.End_of);

        if (clear_at._endof == "day") {
            return QDate.current_date ().add_days (1).start_of_day ().to_time_t ();
        } else if (clear_at._endof == "week") {
            const auto days = Qt.Sunday - QDate.current_date ().day_of_week ();
            return QDate.current_date ().add_days (days + 1).start_of_day ().to_time_t ();
        }
        q_c_warning (lc_ocs_user_status_connector) << "Can not handle clear at endof day type" << clear_at._endof;
        return QDateTime.current_date_time ().to_time_t ();
    }

    uint64 clear_at_period_to_timestamp (Occ.Clear_at &clear_at) {
        return QDateTime.current_date_time ().add_secs (clear_at._period).to_time_t ();
    }

    uint64 clear_at_to_timestamp (Occ.Clear_at &clear_at) {
        switch (clear_at._type) {
        case Occ.Clear_at_type.Period : {
            return clear_at_period_to_timestamp (clear_at);
        }

        case Occ.Clear_at_type.End_of : {
            return clear_at_end_of_to_timestamp (clear_at);
        }

        case Occ.Clear_at_type.Timestamp : {
            return clear_at._timestamp;
        }
        }

        return 0;
    }

    uint64 clear_at_to_timestamp (Occ.Optional<Occ.Clear_at> &clear_at) {
        if (clear_at) {
            return clear_at_to_timestamp (*clear_at);
        }
        return 0;
    }

    Occ.Optional<Occ.Clear_at> json_to_clear_at (QJsonObject json_object) {
        Occ.Optional<Occ.Clear_at> clear_at;

        if (json_object.value ("clear_at").is_object () && !json_object.value ("clear_at").is_null ()) {
            Occ.Clear_at clear_at_value;
            const auto clear_at_object = json_object.value ("clear_at").to_object ();
            const auto type_value = clear_at_object.value ("type").to_string ("period");
            if (type_value == "period") {
                const auto time_value = clear_at_object.value ("time").to_int (0);
                clear_at_value._type = Occ.Clear_at_type.Period;
                clear_at_value._period = time_value;
            } else if (type_value == "end-of") {
                const auto time_value = clear_at_object.value ("time").to_string ("day");
                clear_at_value._type = Occ.Clear_at_type.End_of;
                clear_at_value._endof = time_value;
            } else {
                q_c_warning (lc_ocs_user_status_connector) << "Can not handle clear type value" << type_value;
            }
            clear_at = clear_at_value;
        }

        return clear_at;
    }

    Occ.User_status json_to_user_status (QJsonObject json_object) {
        const auto clear_at = json_to_clear_at (json_object);

        Occ.User_status user_status (
            json_object.value ("id").to_string ("no-id"),
            json_object.value ("message").to_string ("No message"),
            json_object.value ("icon").to_string ("no-icon"),
            Occ.User_status.Online_status.Online,
            true,
            clear_at);

        return user_status;
    }

    std.vector<Occ.User_status> json_to_predefined_statuses (QJsonArray json_data_array) {
        std.vector<Occ.User_status> statuses;
        for (auto &json_entry : json_data_array) {
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

    Ocs_user_status_connector.Ocs_user_status_connector (AccountPtr account, GLib.Object *parent)
        : User_status_connector (parent)
        , _account (account) {
        Q_ASSERT (_account);
        _user_status_supported = _account.capabilities ().user_status ();
        _user_status_emojis_supported = _account.capabilities ().user_status_supports_emoji ();
    }

    void Ocs_user_status_connector.fetch_user_status () {
        q_c_debug (lc_ocs_user_status_connector) << "Try to fetch user status";

        if (!_user_status_supported) {
            q_c_debug (lc_ocs_user_status_connector) << "User status not supported";
            emit error (Error.User_status_not_supported);
            return;
        }

        start_fetch_user_status_job ();
    }

    void Ocs_user_status_connector.start_fetch_user_status_job () {
        if (_get_user_status_job) {
            q_c_debug (lc_ocs_user_status_connector) << "Get user status job is already running.";
            return;
        }

        _get_user_status_job = new JsonApiJob (_account, user_status_base_url, this);
        connect (_get_user_status_job, &JsonApiJob.json_received, this, &Ocs_user_status_connector.on_user_status_fetched);
        _get_user_status_job.start ();
    }

    void Ocs_user_status_connector.on_user_status_fetched (QJsonDocument &json, int status_code) {
        log_response ("user status fetched", json, status_code);

        if (status_code != 200) {
            q_c_info (lc_ocs_user_status_connector) << "Slot fetch User_status finished with status code" << status_code;
            emit error (Error.Could_not_fetch_user_status);
            return;
        }

        _user_status = json_to_user_status (json);
        emit user_status_fetched (_user_status);
    }

    void Ocs_user_status_connector.start_fetch_predefined_statuses () {
        if (_get_predefined_stauses_job) {
            q_c_debug (lc_ocs_user_status_connector) << "Get predefined statuses job is already running";
            return;
        }

        _get_predefined_stauses_job = new JsonApiJob (_account,
            base_url + QStringLiteral ("/predefined_statuses"), this);
        connect (_get_predefined_stauses_job, &JsonApiJob.json_received, this,
            &Ocs_user_status_connector.on_predefined_statuses_fetched);
        _get_predefined_stauses_job.start ();
    }

    void Ocs_user_status_connector.fetch_predefined_statuses () {
        if (!_user_status_supported) {
            emit error (Error.User_status_not_supported);
            return;
        }
        start_fetch_predefined_statuses ();
    }

    void Ocs_user_status_connector.on_predefined_statuses_fetched (QJsonDocument &json, int status_code) {
        log_response ("predefined statuses", json, status_code);

        if (status_code != 200) {
            q_c_info (lc_ocs_user_status_connector) << "Slot predefined user statuses finished with status code" << status_code;
            emit error (Error.Could_not_fetch_predefined_user_statuses);
            return;
        }
        const auto json_data = json.object ().value ("ocs").to_object ().value ("data");
        Q_ASSERT (json_data.is_array ());
        if (!json_data.is_array ()) {
            return;
        }
        const auto statuses = json_to_predefined_statuses (json_data.to_array ());
        emit predefined_statuses_fetched (statuses);
    }

    void Ocs_user_status_connector.log_response (string &message, QJsonDocument &json, int status_code) {
        q_c_debug (lc_ocs_user_status_connector) << "Response from:" << message << "Status:" << status_code << "Json:" << json;
    }

    void Ocs_user_status_connector.set_user_status_online_status (User_status.Online_status online_status) {
        _set_online_status_job = new JsonApiJob (_account,
            user_status_base_url + QStringLiteral ("/status"), this);
        _set_online_status_job.set_verb (JsonApiJob.Verb.Put);
        // Set body
        QJsonObject data_object;
        data_object.insert ("status_type", online_status_to_string (online_status));
        QJsonDocument body;
        body.set_object (data_object);
        _set_online_status_job.set_body (body);
        connect (_set_online_status_job, &JsonApiJob.json_received, this, &Ocs_user_status_connector.on_user_status_online_status_set);
        _set_online_status_job.start ();
    }

    void Ocs_user_status_connector.set_user_status_message_predefined (User_status &user_status) {
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
        connect (_set_message_job, &JsonApiJob.json_received, this, &Ocs_user_status_connector.on_user_status_message_set);
        _set_message_job.start ();
    }

    void Ocs_user_status_connector.set_user_status_message_custom (User_status &user_status) {
        Q_ASSERT (!user_status.message_predefined ());
        if (user_status.message_predefined ()) {
            return;
        }

        if (!_user_status_emojis_supported) {
            emit error (Error.Emojis_not_supported);
            return;
        }
        _set_message_job = new JsonApiJob (_account, user_status_base_url + QStringLiteral ("/message/custom"), this);
        _set_message_job.set_verb (JsonApiJob.Verb.Put);
        // Set body
        QJsonObject data_object;
        data_object.insert ("status_icon", user_status.icon ());
        data_object.insert ("message", user_status.message ());
        const auto clear_at = user_status.clear_at ();
        if (clear_at) {
            data_object.insert ("clear_at", static_cast<int> (clear_at_to_timestamp (*clear_at)));
        } else {
            data_object.insert ("clear_at", QJsonValue ());
        }
        QJsonDocument body;
        body.set_object (data_object);
        _set_message_job.set_body (body);
        connect (_set_message_job, &JsonApiJob.json_received, this, &Ocs_user_status_connector.on_user_status_message_set);
        _set_message_job.start ();
    }

    void Ocs_user_status_connector.set_user_status_message (User_status &user_status) {
        if (user_status.message_predefined ()) {
            set_user_status_message_predefined (user_status);
            return;
        }
        set_user_status_message_custom (user_status);
    }

    void Ocs_user_status_connector.set_user_status (User_status &user_status) {
        if (!_user_status_supported) {
            emit error (Error.User_status_not_supported);
            return;
        }

        if (_set_online_status_job || _set_message_job) {
            q_c_debug (lc_ocs_user_status_connector) << "Set online status job or set message job are already running.";
            return;
        }

        set_user_status_online_status (user_status.state ());
        set_user_status_message (user_status);
    }

    void Ocs_user_status_connector.on_user_status_online_status_set (QJsonDocument &json, int status_code) {
        log_response ("Online status set", json, status_code);

        if (status_code != 200) {
            emit error (Error.Could_not_set_user_status);
            return;
        }
    }

    void Ocs_user_status_connector.on_user_status_message_set (QJsonDocument &json, int status_code) {
        log_response ("Message set", json, status_code);

        if (status_code != 200) {
            emit error (Error.Could_not_set_user_status);
            return;
        }

        // We fetch the user status again because json does not contain
        // the new message when user status was set from a predefined
        // message
        fetch_user_status ();

        emit user_status_set ();
    }

    void Ocs_user_status_connector.clear_message () {
        _clear_message_job = new JsonApiJob (_account, user_status_base_url + QStringLiteral ("/message"));
        _clear_message_job.set_verb (JsonApiJob.Verb.Delete);
        connect (_clear_message_job, &JsonApiJob.json_received, this, &Ocs_user_status_connector.on_message_cleared);
        _clear_message_job.start ();
    }

    User_status Ocs_user_status_connector.user_status () {
        return _user_status;
    }

    void Ocs_user_status_connector.on_message_cleared (QJsonDocument &json, int status_code) {
        log_response ("Message cleared", json, status_code);

        if (status_code != 200) {
            emit error (Error.Could_not_clear_message);
            return;
        }

        _user_status = {};
        emit message_cleared ();
    }
    }
    