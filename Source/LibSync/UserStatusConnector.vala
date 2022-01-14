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

enum class ClearAtType {
    Period,
    EndOf,
    Timestamp
};

// TODO : If we can use C++17 make it a std.variant
struct ClearAt {
    ClearAtType _type = ClearAtType.Period;

    uint64 _timestamp;
    int _period;
    string _endof;
};

class UserStatus {
    Q_GADGET

    Q_PROPERTY (string id MEMBER _id)
    Q_PROPERTY (string message MEMBER _message)
    Q_PROPERTY (string icon MEMBER _icon)
    Q_PROPERTY (OnlineStatus state MEMBER _state)

public:
    enum class OnlineStatus : uint8 {
        Online,
        DoNotDisturb,
        Away,
        Offline,
        Invisible
    };
    Q_ENUM (OnlineStatus);

    UserStatus ();

    UserStatus (string &id, string &message, string &icon,
        OnlineStatus state, bool message_predefined, Optional<ClearAt> &clear_at = {});

    Q_REQUIRED_RESULT string id ();
    Q_REQUIRED_RESULT string message ();
    Q_REQUIRED_RESULT string icon ();
    Q_REQUIRED_RESULT OnlineStatus state ();
    Q_REQUIRED_RESULT Optional<ClearAt> clear_at ();

    void set_id (string &id);
    void set_message (string &message);
    void set_state (OnlineStatus state);
    void set_icon (string &icon);
    void set_message_predefined (bool value);
    void set_clear_at (Optional<ClearAt> &date_time);

    Q_REQUIRED_RESULT bool message_predefined ();

    Q_REQUIRED_RESULT QUrl state_icon ();

private:
    string _id;
    string _message;
    string _icon;
    OnlineStatus _state = OnlineStatus.Online;
    bool _message_predefined;
    Optional<ClearAt> _clear_at;
};

class UserStatusConnector : GLib.Object {

public:
    enum class Error {
        CouldNotFetchUserStatus,
        CouldNotFetchPredefinedUserStatuses,
        UserStatusNotSupported,
        EmojisNotSupported,
        CouldNotSetUserStatus,
        CouldNotClearMessage
    };
    Q_ENUM (Error)

    UserStatusConnector (GLib.Object *parent = nullptr);

    ~UserStatusConnector () override;

    virtual void fetch_user_status () = 0;

    virtual void fetch_predefined_statuses () = 0;

    virtual void set_user_status (UserStatus &user_status) = 0;

    virtual void clear_message () = 0;

    virtual UserStatus user_status () const = 0;

signals:
    void user_status_fetched (UserStatus &user_status);
    void predefined_statuses_fetched (std.vector<UserStatus> &statuses);
    void user_status_set ();
    void message_cleared ();
    void error (Error error);
};


    UserStatus.UserStatus () = default;

    UserStatus.UserStatus (
        const string &id, string &message, string &icon,
        OnlineStatus state, bool message_predefined, Optional<ClearAt> &clear_at)
        : _id (id)
        , _message (message)
        , _icon (icon)
        , _state (state)
        , _message_predefined (message_predefined)
        , _clear_at (clear_at) {
    }

    string UserStatus.id () {
        return _id;
    }

    string UserStatus.message () {
        return _message;
    }

    string UserStatus.icon () {
        return _icon;
    }

    auto UserStatus.state () const . OnlineStatus {
        return _state;
    }

    bool UserStatus.message_predefined () {
        return _message_predefined;
    }

    QUrl UserStatus.state_icon () {
        switch (_state) {
        case UserStatus.OnlineStatus.Away:
            return Theme.instance ().status_away_image_source ();

        case UserStatus.OnlineStatus.DoNotDisturb:
            return Theme.instance ().status_do_not_disturb_image_source ();

        case UserStatus.OnlineStatus.Invisible:
        case UserStatus.OnlineStatus.Offline:
            return Theme.instance ().status_invisible_image_source ();

        case UserStatus.OnlineStatus.Online:
            return Theme.instance ().status_online_image_source ();
        }

        Q_UNREACHABLE ();
    }

    Optional<ClearAt> UserStatus.clear_at () {
        return _clear_at;
    }

    void UserStatus.set_id (string &id) {
        _id = id;
    }

    void UserStatus.set_message (string &message) {
        _message = message;
    }

    void UserStatus.set_state (OnlineStatus state) {
        _state = state;
    }

    void UserStatus.set_icon (string &icon) {
        _icon = icon;
    }

    void UserStatus.set_message_predefined (bool value) {
        _message_predefined = value;
    }

    void UserStatus.set_clear_at (Optional<ClearAt> &date_time) {
        _clear_at = date_time;
    }

    UserStatusConnector.UserStatusConnector (GLib.Object *parent)
        : GLib.Object (parent) {
    }

    UserStatusConnector.~UserStatusConnector () = default;
    }
    