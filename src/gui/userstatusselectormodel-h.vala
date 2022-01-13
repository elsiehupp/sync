/*
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #pragma once

// #include <userstatusconnector.h>
// #include <datetimeprovider.h>

// #include <GLib.Object>
// #include <QMetaType>
// #include <QtNumeric>

// #include <cstddef>
// #include <memory>
// #include <vector>

namespace Occ {

class UserStatusSelectorModel : GLib.Object {

    Q_PROPERTY (QString userStatusMessage READ userStatusMessage NOTIFY userStatusChanged)
    Q_PROPERTY (QString userStatusEmoji READ userStatusEmoji WRITE setUserStatusEmoji NOTIFY userStatusChanged)
    Q_PROPERTY (Occ.UserStatus.OnlineStatus onlineStatus READ onlineStatus WRITE setOnlineStatus NOTIFY onlineStatusChanged)
    Q_PROPERTY (int predefinedStatusesCount READ predefinedStatusesCount NOTIFY predefinedStatusesChanged)
    Q_PROPERTY (QStringList clearAtValues READ clearAtValues CONSTANT)
    Q_PROPERTY (QString clearAt READ clearAt NOTIFY clearAtChanged)
    Q_PROPERTY (QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY (QUrl onlineIcon READ onlineIcon CONSTANT)
    Q_PROPERTY (QUrl awayIcon READ awayIcon CONSTANT)
    Q_PROPERTY (QUrl dndIcon READ dndIcon CONSTANT)
    Q_PROPERTY (QUrl invisibleIcon READ invisibleIcon CONSTANT)

public:
    UserStatusSelectorModel (GLib.Object *parent = nullptr);

    UserStatusSelectorModel (std.shared_ptr<UserStatusConnector> userStatusConnector,
        GLib.Object *parent = nullptr);

    UserStatusSelectorModel (std.shared_ptr<UserStatusConnector> userStatusConnector,
        std.unique_ptr<DateTimeProvider> dateTimeProvider,
        GLib.Object *parent = nullptr);

    UserStatusSelectorModel (UserStatus &userStatus,
        std.unique_ptr<DateTimeProvider> dateTimeProvider,
        GLib.Object *parent = nullptr);

    UserStatusSelectorModel (UserStatus &userStatus,
        GLib.Object *parent = nullptr);

    Q_INVOKABLE void load (int id);

    Q_REQUIRED_RESULT UserStatus.OnlineStatus onlineStatus ();
    Q_INVOKABLE void setOnlineStatus (Occ.UserStatus.OnlineStatus status);

    Q_REQUIRED_RESULT QUrl onlineIcon ();
    Q_REQUIRED_RESULT QUrl awayIcon ();
    Q_REQUIRED_RESULT QUrl dndIcon ();
    Q_REQUIRED_RESULT QUrl invisibleIcon ();

    Q_REQUIRED_RESULT QString userStatusMessage ();
    Q_INVOKABLE void setUserStatusMessage (QString &message);
    void setUserStatusEmoji (QString &emoji);
    Q_REQUIRED_RESULT QString userStatusEmoji ();

    Q_INVOKABLE void setUserStatus ();
    Q_INVOKABLE void clearUserStatus ();

    Q_REQUIRED_RESULT int predefinedStatusesCount ();
    Q_INVOKABLE UserStatus predefinedStatus (int index) const;
    Q_INVOKABLE QString predefinedStatusClearAt (int index) const;
    Q_INVOKABLE void setPredefinedStatus (int index);

    Q_REQUIRED_RESULT QStringList clearAtValues ();
    Q_REQUIRED_RESULT QString clearAt ();
    Q_INVOKABLE void setClearAt (int index);

    Q_REQUIRED_RESULT QString errorMessage ();

signals:
    void errorMessageChanged ();
    void userStatusChanged ();
    void onlineStatusChanged ();
    void clearAtChanged ();
    void predefinedStatusesChanged ();
    void finished ();

private:
    enum class ClearStageType {
        DontClear,
        HalfHour,
        OneHour,
        FourHour,
        Today,
        Week
    };

    void init ();
    void reset ();
    void onUserStatusFetched (UserStatus &userStatus);
    void onPredefinedStatusesFetched (std.vector<UserStatus> &statuses);
    void onUserStatusSet ();
    void onMessageCleared ();
    void onError (UserStatusConnector.Error error);

    Q_REQUIRED_RESULT QString clearAtStageToString (ClearStageType stage) const;
    Q_REQUIRED_RESULT QString clearAtReadable (Optional<ClearAt> &clearAt) const;
    Q_REQUIRED_RESULT QString timeDifferenceToString (int differenceSecs) const;
    Q_REQUIRED_RESULT Optional<ClearAt> clearStageTypeToDateTime (ClearStageType type) const;
    void setError (QString &reason);
    void clearError ();

    std.shared_ptr<UserStatusConnector> _userStatusConnector {};
    std.vector<UserStatus> _predefinedStatuses;
    UserStatus _userStatus;
    std.unique_ptr<DateTimeProvider> _dateTimeProvider;

    QString _errorMessage;

    std.vector<ClearStageType> _clearStages = {
        ClearStageType.DontClear,
        ClearStageType.HalfHour,
        ClearStageType.OneHour,
        ClearStageType.FourHour,
        ClearStageType.Today,
        ClearStageType.Week
    };
};
}
