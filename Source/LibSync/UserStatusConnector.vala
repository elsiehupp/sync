/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <GLib.Object>
// #include <string>
// #include <QMetaType>
// #include <QUrl>
// #include <QDateTime>
// #include <QtGlobal>
// #include <QVariant>

// #include <vector>

namespace Occ {

enum class Clear_at_type {
    Period,
    End_of,
    Timestamp
};

// TODO : If we can use C++17 make it a std.variant
struct Clear_at {
    Clear_at_type _type = Clear_at_type.Period;

    uint64 _timestamp;
    int _period;
    string _endof;
};

class User_status {
    Q_GADGET

    Q_PROPERTY (string id MEMBER _id)
    Q_PROPERTY (string message MEMBER _message)
    Q_PROPERTY (string icon MEMBER _icon)
    Q_PROPERTY (Online_status state MEMBER _state)

public:
    enum class Online_status : uint8 {
        Online,
        Do_not_disturb,
        Away,
        Offline,
        Invisible
    };
    Q_ENUM (Online_status);

    User_status ();

    User_status (string &id, string &message, string &icon,
        Online_status state, bool message_predefined, Optional<Clear_at> &clear_at = {});

    Q_REQUIRED_RESULT string id ();
    Q_REQUIRED_RESULT string message ();
    Q_REQUIRED_RESULT string icon ();
    Q_REQUIRED_RESULT Online_status state ();
    Q_REQUIRED_RESULT Optional<Clear_at> clear_at ();

    void set_id (string &id);
    void set_message (string &message);
    void set_state (Online_status state);
    void set_icon (string &icon);
    void set_message_predefined (bool value);
    void set_clear_at (Optional<Clear_at> &date_time);

    Q_REQUIRED_RESULT bool message_predefined ();

    Q_REQUIRED_RESULT QUrl state_icon ();

private:
    string _id;
    string _message;
    string _icon;
    Online_status _state = Online_status.Online;
    bool _message_predefined;
    Optional<Clear_at> _clear_at;
};

class User_status_connector : GLib.Object {

public:
    enum class Error {
        Could_not_fetch_user_status,
        Could_not_fetch_predefined_user_statuses,
        User_status_not_supported,
        Emojis_not_supported,
        Could_not_set_user_status,
        Could_not_clear_message
    };
    Q_ENUM (Error)

    User_status_connector (GLib.Object *parent = nullptr);

    ~User_status_connector () override;

    virtual void fetch_user_status () = 0;

    virtual void fetch_predefined_statuses () = 0;

    virtual void set_user_status (User_status &user_status) = 0;

    virtual void clear_message () = 0;

    virtual User_status user_status () const = 0;

signals:
    void user_status_fetched (User_status &user_status);
    void predefined_statuses_fetched (std.vector<User_status> &statuses);
    void user_status_set ();
    void message_cleared ();
    void error (Error error);
};


    User_status.User_status () = default;

    User_status.User_status (
        const string &id, string &message, string &icon,
        Online_status state, bool message_predefined, Optional<Clear_at> &clear_at)
        : _id (id)
        , _message (message)
        , _icon (icon)
        , _state (state)
        , _message_predefined (message_predefined)
        , _clear_at (clear_at) {
    }

    string User_status.id () {
        return _id;
    }

    string User_status.message () {
        return _message;
    }

    string User_status.icon () {
        return _icon;
    }

    auto User_status.state () const . Online_status {
        return _state;
    }

    bool User_status.message_predefined () {
        return _message_predefined;
    }

    QUrl User_status.state_icon () {
        switch (_state) {
        case User_status.Online_status.Away:
            return Theme.instance ().status_away_image_source ();

        case User_status.Online_status.Do_not_disturb:
            return Theme.instance ().status_do_not_disturb_image_source ();

        case User_status.Online_status.Invisible:
        case User_status.Online_status.Offline:
            return Theme.instance ().status_invisible_image_source ();

        case User_status.Online_status.Online:
            return Theme.instance ().status_online_image_source ();
        }

        Q_UNREACHABLE ();
    }

    Optional<Clear_at> User_status.clear_at () {
        return _clear_at;
    }

    void User_status.set_id (string &id) {
        _id = id;
    }

    void User_status.set_message (string &message) {
        _message = message;
    }

    void User_status.set_state (Online_status state) {
        _state = state;
    }

    void User_status.set_icon (string &icon) {
        _icon = icon;
    }

    void User_status.set_message_predefined (bool value) {
        _message_predefined = value;
    }

    void User_status.set_clear_at (Optional<Clear_at> &date_time) {
        _clear_at = date_time;
    }

    User_status_connector.User_status_connector (GLib.Object *parent)
        : GLib.Object (parent) {
    }

    User_status_connector.~User_status_connector () = default;
    }
    