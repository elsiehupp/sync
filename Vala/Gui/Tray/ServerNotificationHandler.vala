

//  #include <QtCore>
//  #include <QJsonDocument>
//  #include <QJsonObject>

namespace Occ {
namespace Ui {

class Server_notification_handler : GLib.Object {

    const string notifications_path = "ocs/v2.php/apps/notifications/api/v2/notifications";
    const string property_account_state_c = "oc_account_state";
    const int success_status_code = 200;
    const int NOT_MODIFIED_STATUS_CODE = 304;    

    /***********************************************************
    ***********************************************************/
    public Server_notification_handler (AccountState account_state, GLib.Object parent = new GLib.Object ());

signals:
    void new_notification_list (Activity_list);


    /***********************************************************
    ***********************************************************/
    public void on_fetch_notifications ();


    /***********************************************************
    ***********************************************************/
    private void on_notifications_received (QJsonDocument json, int status_code);
    private void on_etag_response_header_received (GLib.ByteArray value, int status_code);
    private void on_allow_desktop_notifications_changed (bool is_allowed);


    /***********************************************************
    ***********************************************************/
    private QPointer<JsonApiJob> this.notification_job;
    private AccountState this.account_state;
}


    Server_notification_handler.Server_notification_handler (AccountState account_state, GLib.Object parent)
        : GLib.Object (parent)
        this.account_state (account_state) {
    }

    void Server_notification_handler.on_fetch_notifications () {
        // check connectivity and credentials
        if (! (this.account_state && this.account_state.is_connected () && this.account_state.account () && this.account_state.account ().credentials () && this.account_state.account ().credentials ().ready ())) {
            delete_later ();
            return;
        }
        // check if the account has notifications enabled. If the capabilities are
        // not yet valid, its assumed that notifications are available.
        if (this.account_state.account ().capabilities ().is_valid ()) {
            if (!this.account_state.account ().capabilities ().notifications_available ()) {
                GLib.info (lc_server_notification) << "Account" << this.account_state.account ().display_name () << "does not have notifications enabled.";
                delete_later ();
                return;
            }
        }

        // if the previous notification job has on_finished, on_start next.
        this.notification_job = new JsonApiJob (this.account_state.account (), notifications_path, this);
        GLib.Object.connect (this.notification_job.data (), &JsonApiJob.json_received,
            this, &Server_notification_handler.on_notifications_received);
        GLib.Object.connect (this.notification_job.data (), &JsonApiJob.etag_response_header_received,
            this, &Server_notification_handler.on_etag_response_header_received);
        GLib.Object.connect (this.notification_job.data (), &JsonApiJob.allow_desktop_notifications_changed,
                this, &Server_notification_handler.on_allow_desktop_notifications_changed);
        this.notification_job.property (property_account_state_c, GLib.Variant.from_value<AccountState> (this.account_state));
        this.notification_job.add_raw_header ("If-None-Match", this.account_state.notifications_etag_response_header ());
        this.notification_job.on_start ();
    }

    void Server_notification_handler.on_etag_response_header_received (GLib.ByteArray value, int status_code) {
        if (status_code == success_status_code) {
            GLib.warn (lc_server_notification) << "New Notification ETag Response Header received " << value;
            var account = qvariant_cast<AccountState> (sender ().property (property_account_state_c));
            account.notifications_etag_response_header (value);
        }
    }

    void Server_notification_handler.on_allow_desktop_notifications_changed (bool is_allowed) {
        var account = qvariant_cast<AccountState> (sender ().property (property_account_state_c));
        if (account != null) {
           account.desktop_notifications_allowed (is_allowed);
        }
    }

    void Server_notification_handler.on_notifications_received (QJsonDocument json, int status_code) {
        if (status_code != success_status_code && status_code != NOT_MODIFIED_STATUS_CODE) {
            GLib.warn (lc_server_notification) << "Notifications failed with status code " << status_code;
            delete_later ();
            return;
        }

        if (status_code == NOT_MODIFIED_STATUS_CODE) {
            GLib.warn (lc_server_notification) << "Status code " << status_code << " Not Modified - No new notifications.";
            delete_later ();
            return;
        }

        var notifies = json.object ().value ("ocs").to_object ().value ("data").to_array ();

        var ai = qvariant_cast<AccountState> (sender ().property (property_account_state_c));

        Activity_list list;

        foreach (var element, notifies) {
            Activity a;
            var json = element.to_object ();
            a.type = Activity.Notification_type;
            a.acc_name = ai.account ().display_name ();
            a.id = json.value ("notification_id").to_int ();

            //need to know, specially for remote_share
            a.object_type = json.value ("object_type").to_string ();
            a.status = 0;

            a.subject = json.value ("subject").to_string ();
            a.message = json.value ("message").to_string ();
            a.icon = json.value ("icon").to_string ();

            GLib.Uri link (json.value ("link").to_string ());
            if (!link.is_empty ()) {
                if (link.host ().is_empty ()) {
                    link.scheme (ai.account ().url ().scheme ());
                    link.host (ai.account ().url ().host ());
                }
                if (link.port () == -1) {
                    link.port (ai.account ().url ().port ());
                }
            }
            a.link = link;
            a.date_time = GLib.DateTime.from_string (json.value ("datetime").to_string (), Qt.ISODate);

            var actions = json.value ("actions").to_array ();
            foreach (var action, actions) {
                var action_json = action.to_object ();
                Activity_link al;
                al.label = GLib.Uri.from_percent_encoding (action_json.value ("label").to_string ().to_utf8 ());
                al.link = action_json.value ("link").to_string ();
                al.verb = action_json.value ("type").to_string ().to_utf8 ();
                al.primary = action_json.value ("primary").to_bool ();

                a.links.append (al);
            }

            // Add another action to dismiss notification on server
            // https://github.com/owncloud/notifications/blob/master/docs/ocs-endpoint-v1.md#deleting-a-notification-for-a-user
            Activity_link al;
            al.label = _("Dismiss");
            al.link = Utility.concat_url_path (ai.account ().url (), notifications_path + "/" + string.number (a.id)).to_string ();
            al.verb = "DELETE";
            al.primary = false;
            a.links.append (al);

            list.append (a);
        }
        /* emit */ new_notification_list (list);

        delete_later ();
    }
    }
    