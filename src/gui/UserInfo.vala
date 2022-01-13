/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>
// #include <QPointer>
// #include <QVariant>
// #include <QTimer>
// #include <QDateTime>

namespace Occ {

/***********************************************************
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

    /***********************************************************
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










/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <theme.h>

// #include <QTimer>
// #include <QJsonDocument>
// #include <QJsonObject>

namespace Occ {

    namespace {
        static const int defaultIntervalT = 30 * 1000;
        static const int failIntervalT = 5 * 1000;
    }
    
    UserInfo.UserInfo (AccountState *accountState, bool allowDisconnectedAccountState, bool fetchAvatarImage, GLib.Object *parent)
        : GLib.Object (parent)
        , _accountState (accountState)
        , _allowDisconnectedAccountState (allowDisconnectedAccountState)
        , _fetchAvatarImage (fetchAvatarImage)
        , _lastQuotaTotalBytes (0)
        , _lastQuotaUsedBytes (0)
        , _active (false) {
        connect (accountState, &AccountState.stateChanged,
            this, &UserInfo.slotAccountStateChanged);
        connect (&_jobRestartTimer, &QTimer.timeout, this, &UserInfo.slotFetchInfo);
        _jobRestartTimer.setSingleShot (true);
    }
    
    void UserInfo.setActive (bool active) {
        _active = active;
        slotAccountStateChanged ();
    }
    
    void UserInfo.slotAccountStateChanged () {
        if (canGetInfo ()) {
            // Obviously assumes there will never be more than thousand of hours between last info
            // received and now, hence why we static_cast
            auto elapsed = static_cast<int> (_lastInfoReceived.msecsTo (QDateTime.currentDateTime ()));
            if (_lastInfoReceived.isNull () || elapsed >= defaultIntervalT) {
                slotFetchInfo ();
            } else {
                _jobRestartTimer.start (defaultIntervalT - elapsed);
            }
        } else {
            _jobRestartTimer.stop ();
        }
    }
    
    void UserInfo.slotRequestFailed () {
        _lastQuotaTotalBytes = 0;
        _lastQuotaUsedBytes = 0;
        _jobRestartTimer.start (failIntervalT);
    }
    
    bool UserInfo.canGetInfo () {
        if (!_accountState || !_active) {
            return false;
        }
        AccountPtr account = _accountState.account ();
        return (_accountState.isConnected () || _allowDisconnectedAccountState)
            && account.credentials ()
            && account.credentials ().ready ();
    }
    
    void UserInfo.slotFetchInfo () {
        if (!canGetInfo ()) {
            return;
        }
    
        if (_job) {
            // The previous job was not finished?  Then we cancel it!
            _job.deleteLater ();
        }
    
        AccountPtr account = _accountState.account ();
        _job = new JsonApiJob (account, QLatin1String ("ocs/v1.php/cloud/user"), this);
        _job.setTimeout (20 * 1000);
        connect (_job.data (), &JsonApiJob.jsonReceived, this, &UserInfo.slotUpdateLastInfo);
        connect (_job.data (), &AbstractNetworkJob.networkError, this, &UserInfo.slotRequestFailed);
        _job.start ();
    }
    
    void UserInfo.slotUpdateLastInfo (QJsonDocument &json) {
        auto objData = json.object ().value ("ocs").toObject ().value ("data").toObject ();
    
        AccountPtr account = _accountState.account ();
    
        // User Info
        string user = objData.value ("id").toString ();
        if (!user.isEmpty ()) {
            account.setDavUser (user);
        }
        string displayName = objData.value ("display-name").toString ();
        if (!displayName.isEmpty ()) {
            account.setDavDisplayName (displayName);
        }
    
        // Quota
        auto objQuota = objData.value ("quota").toObject ();
        int64 used = objQuota.value ("used").toDouble ();
        int64 total = objQuota.value ("quota").toDouble ();
    
        if (_lastInfoReceived.isNull () || _lastQuotaUsedBytes != used || _lastQuotaTotalBytes != total) {
            _lastQuotaUsedBytes = used;
            _lastQuotaTotalBytes = total;
            emit quotaUpdated (_lastQuotaTotalBytes, _lastQuotaUsedBytes);
        }
    
        _jobRestartTimer.start (defaultIntervalT);
        _lastInfoReceived = QDateTime.currentDateTime ();
    
        // Avatar Image
        if (_fetchAvatarImage) {
            auto *job = new AvatarJob (account, account.davUser (), 128, this);
            job.setTimeout (20 * 1000);
            GLib.Object.connect (job, &AvatarJob.avatarPixmap, this, &UserInfo.slotAvatarImage);
            job.start ();
        }
        else
            emit fetchedLastInfo (this);
    }
    
    void UserInfo.slotAvatarImage (QImage &img) {
        _accountState.account ().setAvatar (img);
    
        emit fetchedLastInfo (this);
    }
    
    } // namespace Occ
    