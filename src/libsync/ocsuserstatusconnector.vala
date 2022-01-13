/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QPointer>

namespace Occ {


class OcsUserStatusConnector : UserStatusConnector {
public:
    OcsUserStatusConnector (AccountPtr account, GLib.Object *parent = nullptr);

    void fetchUserStatus () override;

    void fetchPredefinedStatuses () override;

    void setUserStatus (UserStatus &userStatus) override;

    void clearMessage () override;

    UserStatus userStatus () const override;

private:
    void onUserStatusFetched (QJsonDocument &json, int statusCode);
    void onPredefinedStatusesFetched (QJsonDocument &json, int statusCode);
    void onUserStatusOnlineStatusSet (QJsonDocument &json, int statusCode);
    void onUserStatusMessageSet (QJsonDocument &json, int statusCode);
    void onMessageCleared (QJsonDocument &json, int statusCode);

    void logResponse (string &message, QJsonDocument &json, int statusCode);
    void startFetchUserStatusJob ();
    void startFetchPredefinedStatuses ();
    void setUserStatusOnlineStatus (UserStatus.OnlineStatus onlineStatus);
    void setUserStatusMessage (UserStatus &userStatus);
    void setUserStatusMessagePredefined (UserStatus &userStatus);
    void setUserStatusMessageCustom (UserStatus &userStatus);

    AccountPtr _account;

    bool _userStatusSupported = false;
    bool _userStatusEmojisSupported = false;

    QPointer<JsonApiJob> _clearMessageJob {};
    QPointer<JsonApiJob> _setMessageJob {};
    QPointer<JsonApiJob> _setOnlineStatusJob {};
    QPointer<JsonApiJob> _getPredefinedStausesJob {};
    QPointer<JsonApiJob> _getUserStatusJob {};

    UserStatus _userStatus;
};
}
