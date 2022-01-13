/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
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
struct OWNCLOUDSYNC_EXPORT ClearAt {
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
