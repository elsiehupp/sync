/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>
@author Michael Schuster <michael@schuster.ms>

@copyright GPLv3 or Later
***********************************************************/

//  #include <theme.h>
//  #include <QJsonDocument
//  #include <QJsonObje
//  #include <QPointer>

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

If the fetch job is not finished within 30 seconds, it is cancelled and another

Constructor notes:
 - allow_disconnected_account_state : set to true if you want to ignore AccountState's is_connected state,
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
public class UserInfo : GLib.Object {

    const int DEFAULT_INTERVAL_T = 30 * 1000;
    const int FAIL_INTERVAL_T = 5 * 1000;

    /***********************************************************
    ***********************************************************/
    private QPointer<AccountState> account_state;
    private bool allow_disconnected_account_state;
    private bool fetch_avatar_image;

    /***********************************************************
    ***********************************************************/
    public int64 last_quota_total_bytes { public get; private set; }
    public int64 last_quota_used_bytes { public get; private set; }

    private GLib.Timeout job_restart_timer;

    /***********************************************************
    The time at which the user info and quota was received last
    ***********************************************************/
    private GLib.DateTime last_info_received;

    /***********************************************************
    If we should check at regular interval (when the UI is visible)

    When the quotainfo is active, it requests the quota at
    regular interval. When setting it to active it will request
    the quota immediately if the last time the quota was
    requested was more than the interval
    ***********************************************************/
    public bool active {
        private get {
            return this.active;
        }
        public set {
            this.active = value;
            on_signal_account_state_changed ();
        }
    }

    /***********************************************************
    The currently running job
    ***********************************************************/
    private QPointer<JsonApiJob> json_api_job;


    internal signal void quota_updated (int64 total, int64 used);
    internal signal void fetched_last_info (UserInfo user_info);


    /***********************************************************
    ***********************************************************/
    public UserInfo (AccountState account_state, bool allow_disconnected_account_state, bool fetch_avatar_image, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account_state = account_state;
        this.allow_disconnected_account_state = allow_disconnected_account_state;
        this.fetch_avatar_image = fetch_avatar_image;
        this.last_quota_total_bytes = 0;
        this.last_quota_used_bytes = 0;
        this.active = false;
        account_state.signal_state_changed.connect (
            this.on_signal_account_state_changed
        );
        this.job_restart_timer.timeout.connect (
            this.on_signal_fetch_info
        );
        this.job_restart_timer.single_shot (true);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_fetch_info () {
        if (!can_get_info ()) {
            return;
        }

        if (this.json_api_job) {
            // The previous job was not finished?  Then we cancel it!
            this.json_api_job.delete_later ();
        }

        unowned Account account = this.account_state.account;
        this.json_api_job = new JsonApiJob (account, "ocs/v1.php/cloud/user", this);
        this.json_api_job.on_signal_timeout (20 * 1000);
        this.json_api_job.json_received.connect (
            this.on_signal_update_last_info
        );
        this.json_api_job.network_error.connect (
            this.on_signal_request_failed
        );
        this.json_api_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_update_last_info (QJsonDocument json) {
        var obj_data = json.object ().value ("ocs").to_object ().value ("data").to_object ();

        unowned Account account = this.account_state.account;

        // User Info
        string user = obj_data.value ("identifier").to_string ();
        if (!user == "") {
            account.dav_user (user);
        }
        string display_name = obj_data.value ("display-name").to_string ();
        if (!display_name == "") {
            account.dav_display_name (display_name);
        }

        // Quota
        var obj_quota = obj_data.value ("quota").to_object ();
        int64 used = obj_quota.value ("used").to_double ();
        int64 total = obj_quota.value ("quota").to_double ();

        if (this.last_info_received == null || this.last_quota_used_bytes != used || this.last_quota_total_bytes != total) {
            this.last_quota_used_bytes = used;
            this.last_quota_total_bytes = total;
            /* emit */ quota_updated (this.last_quota_total_bytes, this.last_quota_used_bytes);
        }

        this.job_restart_timer.on_signal_start (DEFAULT_INTERVAL_T);
        this.last_info_received = GLib.DateTime.current_date_time ();

        // Avatar Image
        if (this.fetch_avatar_image) {
            var avatar_job = new AvatarJob (account, account.dav_user, 128, this);
            avatar_job.on_signal_timeout (20 * 1000);
            avatar_job.avatar_pixmap.connect (
                this.on_signal_avatar_image
            );
            avatar_job.on_signal_start ();
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
            if (this.last_info_received == null || elapsed >= DEFAULT_INTERVAL_T) {
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
        this.account_state.account.avatar (img);

        /* emit */ fetched_last_info (this);
    }


    /***********************************************************
    ***********************************************************/
    private bool can_get_info () {
        if (!this.account_state || !this.active) {
            return false;
        }
        unowned Account account = this.account_state.account;
        return (this.account_state.is_connected || this.allow_disconnected_account_state)
            && account.credentials ()
            && account.credentials ().ready ();
    }

} // class UserInfo

} // namespace Ui
} // namespace Occ
    