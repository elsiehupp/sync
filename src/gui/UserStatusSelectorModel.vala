/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

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

    Q_PROPERTY (string userStatusMessage READ userStatusMessage NOTIFY userStatusChanged)
    Q_PROPERTY (string userStatusEmoji READ userStatusEmoji WRITE setUserStatusEmoji NOTIFY userStatusChanged)
    Q_PROPERTY (Occ.UserStatus.OnlineStatus onlineStatus READ onlineStatus WRITE setOnlineStatus NOTIFY onlineStatusChanged)
    Q_PROPERTY (int predefinedStatusesCount READ predefinedStatusesCount NOTIFY predefinedStatusesChanged)
    Q_PROPERTY (QStringList clearAtValues READ clearAtValues CONSTANT)
    Q_PROPERTY (string clearAt READ clearAt NOTIFY clearAtChanged)
    Q_PROPERTY (string errorMessage READ errorMessage NOTIFY errorMessageChanged)
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

    Q_REQUIRED_RESULT string userStatusMessage ();
    Q_INVOKABLE void setUserStatusMessage (string &message);
    void setUserStatusEmoji (string &emoji);
    Q_REQUIRED_RESULT string userStatusEmoji ();

    Q_INVOKABLE void setUserStatus ();
    Q_INVOKABLE void clearUserStatus ();

    Q_REQUIRED_RESULT int predefinedStatusesCount ();
    Q_INVOKABLE UserStatus predefinedStatus (int index) const;
    Q_INVOKABLE string predefinedStatusClearAt (int index) const;
    Q_INVOKABLE void setPredefinedStatus (int index);

    Q_REQUIRED_RESULT QStringList clearAtValues ();
    Q_REQUIRED_RESULT string clearAt ();
    Q_INVOKABLE void setClearAt (int index);

    Q_REQUIRED_RESULT string errorMessage ();

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

    Q_REQUIRED_RESULT string clearAtStageToString (ClearStageType stage) const;
    Q_REQUIRED_RESULT string clearAtReadable (Optional<ClearAt> &clearAt) const;
    Q_REQUIRED_RESULT string timeDifferenceToString (int differenceSecs) const;
    Q_REQUIRED_RESULT Optional<ClearAt> clearStageTypeToDateTime (ClearStageType type) const;
    void setError (string &reason);
    void clearError ();

    std.shared_ptr<UserStatusConnector> _userStatusConnector {};
    std.vector<UserStatus> _predefinedStatuses;
    UserStatus _userStatus;
    std.unique_ptr<DateTimeProvider> _dateTimeProvider;

    string _errorMessage;

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










/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <ocsuserstatusconnector.h>
// #include <qnamespace.h>
// #include <userstatusconnector.h>
// #include <theme.h>

// #include <QDateTime>
// #include <QLoggingCategory>

// #include <algorithm>
// #include <cmath>
// #include <cstddef>

namespace Occ {

    Q_LOGGING_CATEGORY (lcUserStatusDialogModel, "nextcloud.gui.userstatusdialogmodel", QtInfoMsg)
    
    UserStatusSelectorModel.UserStatusSelectorModel (GLib.Object *parent)
        : GLib.Object (parent)
        , _dateTimeProvider (new DateTimeProvider) {
        _userStatus.setIcon ("😀");
    }
    
    UserStatusSelectorModel.UserStatusSelectorModel (std.shared_ptr<UserStatusConnector> userStatusConnector, GLib.Object *parent)
        : GLib.Object (parent)
        , _userStatusConnector (userStatusConnector)
        , _userStatus ("no-id", "", "😀", UserStatus.OnlineStatus.Online, false, {})
        , _dateTimeProvider (new DateTimeProvider) {
        _userStatus.setIcon ("😀");
        init ();
    }
    
    UserStatusSelectorModel.UserStatusSelectorModel (std.shared_ptr<UserStatusConnector> userStatusConnector,
        std.unique_ptr<DateTimeProvider> dateTimeProvider,
        GLib.Object *parent)
        : GLib.Object (parent)
        , _userStatusConnector (userStatusConnector)
        , _dateTimeProvider (std.move (dateTimeProvider)) {
        _userStatus.setIcon ("😀");
        init ();
    }
    
    UserStatusSelectorModel.UserStatusSelectorModel (UserStatus &userStatus,
        std.unique_ptr<DateTimeProvider> dateTimeProvider, GLib.Object *parent)
        : GLib.Object (parent)
        , _userStatus (userStatus)
        , _dateTimeProvider (std.move (dateTimeProvider)) {
        _userStatus.setIcon ("😀");
    }
    
    UserStatusSelectorModel.UserStatusSelectorModel (UserStatus &userStatus,
        GLib.Object *parent)
        : GLib.Object (parent)
        , _userStatus (userStatus) {
        _userStatus.setIcon ("😀");
    }
    
    void UserStatusSelectorModel.load (int id) {
        reset ();
        _userStatusConnector = UserModel.instance ().userStatusConnector (id);
        init ();
    }
    
    void UserStatusSelectorModel.reset () {
        if (_userStatusConnector) {
            disconnect (_userStatusConnector.get (), &UserStatusConnector.userStatusFetched, this,
                &UserStatusSelectorModel.onUserStatusFetched);
            disconnect (_userStatusConnector.get (), &UserStatusConnector.predefinedStatusesFetched, this,
                &UserStatusSelectorModel.onPredefinedStatusesFetched);
            disconnect (_userStatusConnector.get (), &UserStatusConnector.error, this,
                &UserStatusSelectorModel.onError);
            disconnect (_userStatusConnector.get (), &UserStatusConnector.userStatusSet, this,
                &UserStatusSelectorModel.onUserStatusSet);
            disconnect (_userStatusConnector.get (), &UserStatusConnector.messageCleared, this,
                &UserStatusSelectorModel.onMessageCleared);
        }
        _userStatusConnector = nullptr;
    }
    
    void UserStatusSelectorModel.init () {
        if (!_userStatusConnector) {
            return;
        }
    
        connect (_userStatusConnector.get (), &UserStatusConnector.userStatusFetched, this,
            &UserStatusSelectorModel.onUserStatusFetched);
        connect (_userStatusConnector.get (), &UserStatusConnector.predefinedStatusesFetched, this,
            &UserStatusSelectorModel.onPredefinedStatusesFetched);
        connect (_userStatusConnector.get (), &UserStatusConnector.error, this,
            &UserStatusSelectorModel.onError);
        connect (_userStatusConnector.get (), &UserStatusConnector.userStatusSet, this,
            &UserStatusSelectorModel.onUserStatusSet);
        connect (_userStatusConnector.get (), &UserStatusConnector.messageCleared, this,
            &UserStatusSelectorModel.onMessageCleared);
    
        _userStatusConnector.fetchUserStatus ();
        _userStatusConnector.fetchPredefinedStatuses ();
    }
    
    void UserStatusSelectorModel.onUserStatusSet () {
        emit finished ();
    }
    
    void UserStatusSelectorModel.onMessageCleared () {
        emit finished ();
    }
    
    void UserStatusSelectorModel.onError (UserStatusConnector.Error error) {
        qCWarning (lcUserStatusDialogModel) << "Error:" << error;
    
        switch (error) {
        case UserStatusConnector.Error.CouldNotFetchPredefinedUserStatuses:
            setError (tr ("Could not fetch predefined statuses. Make sure you are connected to the server."));
            return;
    
        case UserStatusConnector.Error.CouldNotFetchUserStatus:
            setError (tr ("Could not fetch user status. Make sure you are connected to the server."));
            return;
    
        case UserStatusConnector.Error.UserStatusNotSupported:
            setError (tr ("User status feature is not supported. You will not be able to set your user status."));
            return;
    
        case UserStatusConnector.Error.EmojisNotSupported:
            setError (tr ("Emojis feature is not supported. Some user status functionality may not work."));
            return;
    
        case UserStatusConnector.Error.CouldNotSetUserStatus:
            setError (tr ("Could not set user status. Make sure you are connected to the server."));
            return;
    
        case UserStatusConnector.Error.CouldNotClearMessage:
            setError (tr ("Could not clear user status message. Make sure you are connected to the server."));
            return;
        }
    
        Q_UNREACHABLE ();
    }
    
    void UserStatusSelectorModel.setError (string &reason) {
        _errorMessage = reason;
        emit errorMessageChanged ();
    }
    
    void UserStatusSelectorModel.clearError () {
        setError ("");
    }
    
    void UserStatusSelectorModel.setOnlineStatus (UserStatus.OnlineStatus status) {
        if (status == _userStatus.state ()) {
            return;
        }
    
        _userStatus.setState (status);
        emit onlineStatusChanged ();
    }
    
    QUrl UserStatusSelectorModel.onlineIcon () {
        return Theme.instance ().statusOnlineImageSource ();
    }
    
    QUrl UserStatusSelectorModel.awayIcon () {
        return Theme.instance ().statusAwayImageSource ();
    }
    QUrl UserStatusSelectorModel.dndIcon () {
        return Theme.instance ().statusDoNotDisturbImageSource ();
    }
    QUrl UserStatusSelectorModel.invisibleIcon () {
        return Theme.instance ().statusInvisibleImageSource ();
    }
    
    UserStatus.OnlineStatus UserStatusSelectorModel.onlineStatus () {
        return _userStatus.state ();
    }
    
    string UserStatusSelectorModel.userStatusMessage () {
        return _userStatus.message ();
    }
    
    void UserStatusSelectorModel.setUserStatusMessage (string &message) {
        _userStatus.setMessage (message);
        _userStatus.setMessagePredefined (false);
        emit userStatusChanged ();
    }
    
    void UserStatusSelectorModel.setUserStatusEmoji (string &emoji) {
        _userStatus.setIcon (emoji);
        _userStatus.setMessagePredefined (false);
        emit userStatusChanged ();
    }
    
    string UserStatusSelectorModel.userStatusEmoji () {
        return _userStatus.icon ();
    }
    
    void UserStatusSelectorModel.onUserStatusFetched (UserStatus &userStatus) {
        if (userStatus.state () != UserStatus.OnlineStatus.Offline) {
            _userStatus.setState (userStatus.state ());
        }
        _userStatus.setMessage (userStatus.message ());
        _userStatus.setMessagePredefined (userStatus.messagePredefined ());
        _userStatus.setId (userStatus.id ());
        _userStatus.setClearAt (userStatus.clearAt ());
    
        if (!userStatus.icon ().isEmpty ()) {
            _userStatus.setIcon (userStatus.icon ());
        }
    
        emit userStatusChanged ();
        emit onlineStatusChanged ();
        emit clearAtChanged ();
    }
    
    Optional<ClearAt> UserStatusSelectorModel.clearStageTypeToDateTime (ClearStageType type) {
        switch (type) {
        case ClearStageType.DontClear:
            return {};
    
        case ClearStageType.HalfHour : {
            ClearAt clearAt;
            clearAt._type = ClearAtType.Period;
            clearAt._period = 60 * 30;
            return clearAt;
        }
    
        case ClearStageType.OneHour : {
            ClearAt clearAt;
            clearAt._type = ClearAtType.Period;
            clearAt._period = 60 * 60;
            return clearAt;
        }
    
        case ClearStageType.FourHour : {
            ClearAt clearAt;
            clearAt._type = ClearAtType.Period;
            clearAt._period = 60 * 60 * 4;
            return clearAt;
        }
    
        case ClearStageType.Today : {
            ClearAt clearAt;
            clearAt._type = ClearAtType.EndOf;
            clearAt._endof = "day";
            return clearAt;
        }
    
        case ClearStageType.Week : {
            ClearAt clearAt;
            clearAt._type = ClearAtType.EndOf;
            clearAt._endof = "week";
            return clearAt;
        }
    
        default:
            Q_UNREACHABLE ();
        }
    }
    
    void UserStatusSelectorModel.setUserStatus () {
        Q_ASSERT (_userStatusConnector);
        if (!_userStatusConnector) {
            return;
        }
    
        clearError ();
        _userStatusConnector.setUserStatus (_userStatus);
    }
    
    void UserStatusSelectorModel.clearUserStatus () {
        Q_ASSERT (_userStatusConnector);
        if (!_userStatusConnector) {
            return;
        }
    
        clearError ();
        _userStatusConnector.clearMessage ();
    }
    
    void UserStatusSelectorModel.onPredefinedStatusesFetched (std.vector<UserStatus> &statuses) {
        _predefinedStatuses = statuses;
        emit predefinedStatusesChanged ();
    }
    
    UserStatus UserStatusSelectorModel.predefinedStatus (int index) {
        Q_ASSERT (0 <= index && index < static_cast<int> (_predefinedStatuses.size ()));
        return _predefinedStatuses[index];
    }
    
    int UserStatusSelectorModel.predefinedStatusesCount () {
        return static_cast<int> (_predefinedStatuses.size ());
    }
    
    void UserStatusSelectorModel.setPredefinedStatus (int index) {
        Q_ASSERT (0 <= index && index < static_cast<int> (_predefinedStatuses.size ()));
    
        _userStatus.setMessagePredefined (true);
        const auto predefinedStatus = _predefinedStatuses[index];
        _userStatus.setId (predefinedStatus.id ());
        _userStatus.setMessage (predefinedStatus.message ());
        _userStatus.setIcon (predefinedStatus.icon ());
        _userStatus.setClearAt (predefinedStatus.clearAt ());
    
        emit userStatusChanged ();
        emit clearAtChanged ();
    }
    
    string UserStatusSelectorModel.clearAtStageToString (ClearStageType stage) {
        switch (stage) {
        case ClearStageType.DontClear:
            return tr ("Don't clear");
    
        case ClearStageType.HalfHour:
            return tr ("30 minutes");
    
        case ClearStageType.OneHour:
            return tr ("1 hour");
    
        case ClearStageType.FourHour:
            return tr ("4 hours");
    
        case ClearStageType.Today:
            return tr ("Today");
    
        case ClearStageType.Week:
            return tr ("This week");
    
        default:
            Q_UNREACHABLE ();
        }
    }
    
    QStringList UserStatusSelectorModel.clearAtValues () {
        QStringList clearAtStages;
        std.transform (_clearStages.begin (), _clearStages.end (),
            std.back_inserter (clearAtStages),
            [this] (ClearStageType &stage) { return clearAtStageToString (stage); });
    
        return clearAtStages;
    }
    
    void UserStatusSelectorModel.setClearAt (int index) {
        Q_ASSERT (0 <= index && index < static_cast<int> (_clearStages.size ()));
        _userStatus.setClearAt (clearStageTypeToDateTime (_clearStages[index]));
        emit clearAtChanged ();
    }
    
    string UserStatusSelectorModel.errorMessage () {
        return _errorMessage;
    }
    
    string UserStatusSelectorModel.timeDifferenceToString (int differenceSecs) {
        if (differenceSecs < 60) {
            return tr ("Less than a minute");
        } else if (differenceSecs < 60 * 60) {
            const auto minutesLeft = std.ceil (differenceSecs / 60.0);
            if (minutesLeft == 1) {
                return tr ("1 minute");
            } else {
                return tr ("%1 minutes").arg (minutesLeft);
            }
        } else if (differenceSecs < 60 * 60 * 24) {
            const auto hoursLeft = std.ceil (differenceSecs / 60.0 / 60.0);
            if (hoursLeft == 1) {
                return tr ("1 hour");
            } else {
                return tr ("%1 hours").arg (hoursLeft);
            }
        } else {
            const auto daysLeft = std.ceil (differenceSecs / 60.0 / 60.0 / 24.0);
            if (daysLeft == 1) {
                return tr ("1 day");
            } else {
                return tr ("%1 days").arg (daysLeft);
            }
        }
    }
    
    string UserStatusSelectorModel.clearAtReadable (Optional<ClearAt> &clearAt) {
        if (clearAt) {
            switch (clearAt._type) {
            case ClearAtType.Period : {
                return timeDifferenceToString (clearAt._period);
            }
    
            case ClearAtType.Timestamp : {
                const int difference = static_cast<int> (clearAt._timestamp - _dateTimeProvider.currentDateTime ().toTime_t ());
                return timeDifferenceToString (difference);
            }
    
            case ClearAtType.EndOf : {
                if (clearAt._endof == "day") {
                    return tr ("Today");
                } else if (clearAt._endof == "week") {
                    return tr ("This week");
                }
                Q_UNREACHABLE ();
            }
    
            default:
                Q_UNREACHABLE ();
            }
        }
        return tr ("Don't clear");
    }
    
    string UserStatusSelectorModel.predefinedStatusClearAt (int index) {
        return clearAtReadable (predefinedStatus (index).clearAt ());
    }
    
    string UserStatusSelectorModel.clearAt () {
        return clearAtReadable (_userStatus.clearAt ());
    }
    }
    