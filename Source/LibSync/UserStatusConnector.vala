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
        OnlineStatus state, bool messagePredefined, Optional<ClearAt> &clearAt = {});

    Q_REQUIRED_RESULT string id ();
    Q_REQUIRED_RESULT string message ();
    Q_REQUIRED_RESULT string icon ();
    Q_REQUIRED_RESULT OnlineStatus state ();
    Q_REQUIRED_RESULT Optional<ClearAt> clearAt ();

    void setId (string &id);
    void setMessage (string &message);
    void setState (OnlineStatus state);
    void setIcon (string &icon);
    void setMessagePredefined (bool value);
    void setClearAt (Optional<ClearAt> &dateTime);

    Q_REQUIRED_RESULT bool messagePredefined ();

    Q_REQUIRED_RESULT QUrl stateIcon ();

private:
    string _id;
    string _message;
    string _icon;
    OnlineStatus _state = OnlineStatus.Online;
    bool _messagePredefined;
    Optional<ClearAt> _clearAt;
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

    virtual void fetchUserStatus () = 0;

    virtual void fetchPredefinedStatuses () = 0;

    virtual void setUserStatus (UserStatus &userStatus) = 0;

    virtual void clearMessage () = 0;

    virtual UserStatus userStatus () const = 0;

signals:
    void userStatusFetched (UserStatus &userStatus);
    void predefinedStatusesFetched (std.vector<UserStatus> &statuses);
    void userStatusSet ();
    void messageCleared ();
    void error (Error error);
};
}

Q_DECLARE_METATYPE (Occ.UserStatusConnector *)
Q_DECLARE_METATYPE (Occ.UserStatus)















namespace Occ {

    UserStatus.UserStatus () = default;
    
    UserStatus.UserStatus (
        const string &id, string &message, string &icon,
        OnlineStatus state, bool messagePredefined, Optional<ClearAt> &clearAt)
        : _id (id)
        , _message (message)
        , _icon (icon)
        , _state (state)
        , _messagePredefined (messagePredefined)
        , _clearAt (clearAt) {
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
    
    bool UserStatus.messagePredefined () {
        return _messagePredefined;
    }
    
    QUrl UserStatus.stateIcon () {
        switch (_state) {
        case UserStatus.OnlineStatus.Away:
            return Theme.instance ().statusAwayImageSource ();
    
        case UserStatus.OnlineStatus.DoNotDisturb:
            return Theme.instance ().statusDoNotDisturbImageSource ();
    
        case UserStatus.OnlineStatus.Invisible:
        case UserStatus.OnlineStatus.Offline:
            return Theme.instance ().statusInvisibleImageSource ();
    
        case UserStatus.OnlineStatus.Online:
            return Theme.instance ().statusOnlineImageSource ();
        }
    
        Q_UNREACHABLE ();
    }
    
    Optional<ClearAt> UserStatus.clearAt () {
        return _clearAt;
    }
    
    void UserStatus.setId (string &id) {
        _id = id;
    }
    
    void UserStatus.setMessage (string &message) {
        _message = message;
    }
    
    void UserStatus.setState (OnlineStatus state) {
        _state = state;
    }
    
    void UserStatus.setIcon (string &icon) {
        _icon = icon;
    }
    
    void UserStatus.setMessagePredefined (bool value) {
        _messagePredefined = value;
    }
    
    void UserStatus.setClearAt (Optional<ClearAt> &dateTime) {
        _clearAt = dateTime;
    }
    
    UserStatusConnector.UserStatusConnector (GLib.Object *parent)
        : GLib.Object (parent) {
    }
    
    UserStatusConnector.~UserStatusConnector () = default;
    }
    