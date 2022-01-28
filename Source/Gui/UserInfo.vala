/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <theme.h>

// #include <QTimer>
// #include <QJsonDocument>
// #include <QJsonObject>

// #include <QPointer>
// #include <QVariant>
// #include <QTimer>
// #include <QDateTime>

namespace Occ {

/***********************************************************
@brief handles getting the user info and quota to display in the UI

It is typically owned by the Account_setting page.

The user info and quota is r
 - This object is active via set_active () (typically if the settings page is visible.)
 - The account is connected.
 - Every 30 seconds (default_interval_t) or 5 seconds in case of failure (fail_interval_t)

We only request the info when the UI is visible otherwise this might slow down the server with
too many requests.
quota is not updated fast enough when changed on the server.

If the fetch job is not on_finished within 30 seconds, it is cancelled and another

Constructor notes:
 - allow_disconnected_account_state : set to true if you want to ignore AccountState's is_connected () state,
   this is used by ConnectionValidator (prior having a valid AccountState).
 - fetch_avatar_image : set to false if you don't want to fetch the avatar image

@ingroup gui

Here follows the state machine

 \code{.unparsed}
 *--. on_fetch_info
         JsonApiJob (ocs/v1.php/cloud/user)
         |
         +. on_update_last_info
               AvatarJob (if _fetch_avatar_image is true)
               |
               +. on_avatar_image -.
   +-----------------------------------+
   |
   +. Client Side Encryption Checks --+ --report_result ()
\endcode
***********************************************************/
class UserInfo : GLib.Object {

    public UserInfo (Occ.AccountState account_state, bool allow_disconnected_account_state, bool fetch_avatar_image, GLib.Object parent = nullptr);

    public int64 last_quota_total_bytes () {
        return _last_quota_total_bytes;
    }
    public int64 last_quota_used_bytes () {
        return _last_quota_used_bytes;
    }


    /***********************************************************
    When the quotainfo is active, it requests the quota at regular interval.
    When setting it to active it will request the quota immediately if the last time
    the quota was requested was more than the interval
    ***********************************************************/
    public void set_active (bool active);


    public void on_fetch_info ();


    private void on_update_last_info (QJsonDocument &json);
    private void on_account_state_changed ();
    private void on_request_failed ();
    private void on_avatar_image (QImage &img);

signals:
    void quota_updated (int64 total, int64 used);
    void fetched_last_info (UserInfo user_info);


    private bool can_get_info ();

    private QPointer<AccountState> _account_state;
    private bool _allow_disconnected_account_state;
    private bool _fetch_avatar_image;

    private int64 _last_quota_total_bytes;
    private int64 _last_quota_used_bytes;
    private QTimer _job_restart_timer;
    private QDateTime _last_info_received; // the time at which the user info and quota was received last
    private bool _active; // if we should check at regular interval (when the UI is visible)
    private QPointer<JsonApiJob> _job; // the currently running job
};



    namespace {
        static const int default_interval_t = 30 * 1000;
        static const int fail_interval_t = 5 * 1000;
    }

    UserInfo.UserInfo (AccountState account_state, bool allow_disconnected_account_state, bool fetch_avatar_image, GLib.Object parent)
        : GLib.Object (parent)
        , _account_state (account_state)
        , _allow_disconnected_account_state (allow_disconnected_account_state)
        , _fetch_avatar_image (fetch_avatar_image)
        , _last_quota_total_bytes (0)
        , _last_quota_used_bytes (0)
        , _active (false) {
        connect (account_state, &AccountState.state_changed,
            this, &UserInfo.on_account_state_changed);
        connect (&_job_restart_timer, &QTimer.timeout, this, &UserInfo.on_fetch_info);
        _job_restart_timer.set_single_shot (true);
    }

    void UserInfo.set_active (bool active) {
        _active = active;
        on_account_state_changed ();
    }

    void UserInfo.on_account_state_changed () {
        if (can_get_info ()) {
            // Obviously assumes there will never be more than thousand of hours between last info
            // received and now, hence why we static_cast
            var elapsed = static_cast<int> (_last_info_received.msecs_to (QDateTime.current_date_time ()));
            if (_last_info_received.is_null () || elapsed >= default_interval_t) {
                on_fetch_info ();
            } else {
                _job_restart_timer.on_start (default_interval_t - elapsed);
            }
        } else {
            _job_restart_timer.stop ();
        }
    }

    void UserInfo.on_request_failed () {
        _last_quota_total_bytes = 0;
        _last_quota_used_bytes = 0;
        _job_restart_timer.on_start (fail_interval_t);
    }

    bool UserInfo.can_get_info () {
        if (!_account_state || !_active) {
            return false;
        }
        AccountPtr account = _account_state.account ();
        return (_account_state.is_connected () || _allow_disconnected_account_state)
            && account.credentials ()
            && account.credentials ().ready ();
    }

    void UserInfo.on_fetch_info () {
        if (!can_get_info ()) {
            return;
        }

        if (_job) {
            // The previous job was not on_finished?  Then we cancel it!
            _job.delete_later ();
        }

        AccountPtr account = _account_state.account ();
        _job = new JsonApiJob (account, QLatin1String ("ocs/v1.php/cloud/user"), this);
        _job.on_set_timeout (20 * 1000);
        connect (_job.data (), &JsonApiJob.json_received, this, &UserInfo.on_update_last_info);
        connect (_job.data (), &AbstractNetworkJob.network_error, this, &UserInfo.on_request_failed);
        _job.on_start ();
    }

    void UserInfo.on_update_last_info (QJsonDocument &json) {
        var obj_data = json.object ().value ("ocs").to_object ().value ("data").to_object ();

        AccountPtr account = _account_state.account ();

        // User Info
        string user = obj_data.value ("id").to_string ();
        if (!user.is_empty ()) {
            account.set_dav_user (user);
        }
        string display_name = obj_data.value ("display-name").to_string ();
        if (!display_name.is_empty ()) {
            account.set_dav_display_name (display_name);
        }

        // Quota
        var obj_quota = obj_data.value ("quota").to_object ();
        int64 used = obj_quota.value ("used").to_double ();
        int64 total = obj_quota.value ("quota").to_double ();

        if (_last_info_received.is_null () || _last_quota_used_bytes != used || _last_quota_total_bytes != total) {
            _last_quota_used_bytes = used;
            _last_quota_total_bytes = total;
            emit quota_updated (_last_quota_total_bytes, _last_quota_used_bytes);
        }

        _job_restart_timer.on_start (default_interval_t);
        _last_info_received = QDateTime.current_date_time ();

        // Avatar Image
        if (_fetch_avatar_image) {
            var job = new AvatarJob (account, account.dav_user (), 128, this);
            job.on_set_timeout (20 * 1000);
            GLib.Object.connect (job, &AvatarJob.avatar_pixmap, this, &UserInfo.on_avatar_image);
            job.on_start ();
        }
        else
            emit fetched_last_info (this);
    }

    void UserInfo.on_avatar_image (QImage &img) {
        _account_state.account ().set_avatar (img);

        emit fetched_last_info (this);
    }

    } // namespace Occ
    