/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <theme.h>
//  #include <QTimer>
//  #include <QJsonDocument
//  #include <QJsonObje
//  #include <QPointer>
//  #include <QTimer>

namespace Occ {
namespace Ui {

/***********************************************************
@brief handles getting the user info and quota to display in the UI

It is typically owned by the Account_setting page.

The user info and quota is r
 - This object is active via active () (typically if the settings page is visible.)
 - The account is connected.
 - Every 30 seconds (DEFAULT_INTERVAL_T) or 5 seconds in case of failure (FAIL_INTERVAL_T)

We only request the info when the UI is visible otherwise this might slow down the server with
too many requests.
quota is not updated fast enough when changed on the server.

If the fetch job is not on_signal_finished within 30 seconds, it is cancelled and another

Constructor notes:
 - allow_disconnected_account_state : set to true if you want to ignore AccountState's is_connected () state,
   this is used by ConnectionValidator (prior having a valid AccountState).
 - fetch_avatar_image : set to false if you don't want to fetch the avatar image

@ingroup gui

Here follows the state machine

 \code{.unparsed}
 *--. on_signal_fetch_info
         JsonApiJob (ocs/v1.php/cloud/user)
         |
         +. on_signal_update_last_info
               AvatarJob (if this.fetch_avatar_image is true)
               |
               +. on_signal_avatar_image -.
   +-----------------------------------+
   |
   +. Client Side Encryption Checks --+ --report_result ()
\endcode
***********************************************************/
class UserInfo : GLib.Object {

    const int DEFAULT_INTERVAL_T = 30 * 1000;
    const int FAIL_INTERVAL_T = 5 * 1000;

    /***********************************************************
    ***********************************************************/
    private QPointer<AccountState> this.account_state;
    private bool this.allow_disconnected_account_state;
    private bool this.fetch_avatar_image;

    /***********************************************************
    ***********************************************************/
    private int64 this.last_quota_total_bytes;
    private int64 this.last_quota_used_bytes;
    private QTimer this.job_restart_timer;
    /***********************************************************
    The time at which the user info and quota was received last
    ***********************************************************/
    private GLib.DateTime this.last_info_received;
    /***********************************************************
    If we should check at regular interval (when the UI is visible)
    ***********************************************************/
    private bool this.active;
    /***********************************************************
    The currently running job
    ***********************************************************/
    private QPointer<JsonApiJob> this.job;


    signal void quota_updated (int64 total, int64 used);
    signal void fetched_last_info (UserInfo user_info);


    /***********************************************************
    ***********************************************************/
    public UserInfo (Occ.AccountState account_state, bool allow_disconnected_account_state, bool fetch_avatar_image, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account_state = account_state;
        this.allow_disconnected_account_state = allow_disconnected_account_state;
        this.fetch_avatar_image = fetch_avatar_image;
        this.last_quota_total_bytes = 0;
        this.last_quota_used_bytes = 0;
        this.active = false;
        connect (account_state, &AccountState.state_changed,
            this, &UserInfo.on_signal_account_state_changed);
        connect (&this.job_restart_timer, &QTimer.timeout, this, &UserInfo.on_signal_fetch_info);
        this.job_restart_timer.single_shot (true);
    }


    /***********************************************************
    ***********************************************************/
    public int64 last_quota_total_bytes () {
        return this.last_quota_total_bytes;
    }


    /***********************************************************
    ***********************************************************/
    public int64 last_quota_used_bytes () {
        return this.last_quota_used_bytes;
    }


    /***********************************************************
    When the quotainfo is active, it requests the quota at regular interval.
    When setting it to active it will request the quota immediately if the last time
    the quota was requested was more than the interval
    ***********************************************************/
    public void active (bool active) {
        this.active = active;
        on_signal_account_state_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_fetch_info () {
        if (!can_get_info ()) {
            return;
        }

        if (this.job) {
            // The previous job was not on_signal_finished?  Then we cancel it!
            this.job.delete_later ();
        }

        AccountPointer account = this.account_state.account ();
        this.job = new JsonApiJob (account, "ocs/v1.php/cloud/user", this);
        this.job.on_signal_timeout (20 * 1000);
        connect (this.job.data (), &JsonApiJob.json_received, this, &UserInfo.on_signal_update_last_info);
        connect (this.job.data (), &AbstractNetworkJob.network_error, this, &UserInfo.on_signal_request_failed);
        this.job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_update_last_info (QJsonDocument json) {
        var obj_data = json.object ().value ("ocs").to_object ().value ("data").to_object ();

        AccountPointer account = this.account_state.account ();

        // User Info
        string user = obj_data.value ("identifier").to_string ();
        if (!user.is_empty ()) {
            account.dav_user (user);
        }
        string display_name = obj_data.value ("display-name").to_string ();
        if (!display_name.is_empty ()) {
            account.dav_display_name (display_name);
        }

        // Quota
        var obj_quota = obj_data.value ("quota").to_object ();
        int64 used = obj_quota.value ("used").to_double ();
        int64 total = obj_quota.value ("quota").to_double ();

        if (this.last_info_received.is_null () || this.last_quota_used_bytes != used || this.last_quota_total_bytes != total) {
            this.last_quota_used_bytes = used;
            this.last_quota_total_bytes = total;
            /* emit */ quota_updated (this.last_quota_total_bytes, this.last_quota_used_bytes);
        }

        this.job_restart_timer.on_signal_start (DEFAULT_INTERVAL_T);
        this.last_info_received = GLib.DateTime.current_date_time ();

        // Avatar Image
        if (this.fetch_avatar_image) {
            var job = new AvatarJob (account, account.dav_user (), 128, this);
            job.on_signal_timeout (20 * 1000);
            GLib.Object.connect (job, &AvatarJob.avatar_pixmap, this, &UserInfo.on_signal_avatar_image);
            job.on_signal_start ();
        }
        else
            /* emit */ fetched_last_info (this);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_account_state_changed () {
        if (can_get_info ()) {
            // Obviously assumes there will never be more than thousand of hours between last info
            // received and now, hence why we static_cast
            var elapsed = static_cast<int> (this.last_info_received.msecs_to (GLib.DateTime.current_date_time ()));
            if (this.last_info_received.is_null () || elapsed >= DEFAULT_INTERVAL_T) {
                on_signal_fetch_info ();
            } else {
                this.job_restart_timer.on_signal_start (DEFAULT_INTERVAL_T - elapsed);
            }
        } else {
            this.job_restart_timer.stop ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_request_failed () {
        this.last_quota_total_bytes = 0;
        this.last_quota_used_bytes = 0;
        this.job_restart_timer.on_signal_start (FAIL_INTERVAL_T);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_avatar_image (Gtk.Image img) {
        this.account_state.account ().avatar (img);

        /* emit */ fetched_last_info (this);
    }


    /***********************************************************
    ***********************************************************/
    private bool can_get_info () {
        if (!this.account_state || !this.active) {
            return false;
        }
        AccountPointer account = this.account_state.account ();
        return (this.account_state.is_connected () || this.allow_disconnected_account_state)
            && account.credentials ()
            && account.credentials ().ready ();
    }

} // class UserInfo

} // namespace Ui
} // namespace Occ
    