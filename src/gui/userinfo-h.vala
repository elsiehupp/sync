/*
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <GLib.Object>
// #include <QPointer>
// #include <QVariant>
// #include <QTimer>
// #include <QDateTime>

namespace Occ {
class JsonApiJob;

/**
@brief handles getting the user info and quota to display in the UI

It is typically owned by the AccountSetting page.

The user info and quota is r
 - This object is active via setActive () (typically if the settings page is visible.)
 - The account is connected.
 - Every 30 seconds (defaultIntervalT) or 5 seconds in case of failure (failIntervalT)

We only request the info when the UI is visible otherwise this might slow down the server with
too many requests.
quota is not updated fast enough when changed on the server.

If the fetch job is not finished within 30 seconds, it is cancelled and another

Constructor notes:
 - allowDisconnectedAccountState : set to true if you want to ignore AccountState's isConnected () state,
   this is used by ConnectionValidator (prior having a valid AccountState).
 - fetchAvatarImage : set to false if you don't want to fetch the avatar image

@ingroup gui

Here follows the state machine

 \code{.unparsed}
 *--. slotFetchInfo
         JsonApiJob (ocs/v1.php/cloud/user)
         |
         +. slotUpdateLastInfo
               AvatarJob (if _fetchAvatarImage is true)
               |
               +. slotAvatarImage -.
   +-----------------------------------+
   |
   +. Client Side Encryption Checks --+ --reportResult ()
     \endcode
  */
class UserInfo : GLib.Object {
public:
    UserInfo (Occ.AccountState *accountState, bool allowDisconnectedAccountState, bool fetchAvatarImage, GLib.Object *parent = nullptr);

    int64 lastQuotaTotalBytes () { return _lastQuotaTotalBytes; }
    int64 lastQuotaUsedBytes () { return _lastQuotaUsedBytes; }

    /**
     * When the quotainfo is active, it requests the quota at regular interval.
     * When setting it to active it will request the quota immediately if the last time
     * the quota was requested was more than the interval
     */
    void setActive (bool active);

public slots:
    void slotFetchInfo ();

private slots:
    void slotUpdateLastInfo (QJsonDocument &json);
    void slotAccountStateChanged ();
    void slotRequestFailed ();
    void slotAvatarImage (QImage &img);

signals:
    void quotaUpdated (int64 total, int64 used);
    void fetchedLastInfo (UserInfo *userInfo);

private:
    bool canGetInfo ();

    QPointer<AccountState> _accountState;
    bool _allowDisconnectedAccountState;
    bool _fetchAvatarImage;

    int64 _lastQuotaTotalBytes;
    int64 _lastQuotaUsedBytes;
    QTimer _jobRestartTimer;
    QDateTime _lastInfoReceived; // the time at which the user info and quota was received last
    bool _active; // if we should check at regular interval (when the UI is visible)
    QPointer<JsonApiJob> _job; // the currently running job
};

} // namespace Occ

#endif //USERINFO_H
