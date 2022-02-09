
//  #include <QtCore>
//  #include <QJsonDocument>
//  #include <QJsonObject>

namespace Occ {
namespace Ui {

class ServerNotificationHandler : GLib.Object {

    const string NOTIFICATIONS_PATH = "ocs/v2.php/apps/notifications/api/v2/notifications";
    const string PROPERTY_ACCOUNT_STATE = "oc_account_state";
    const int SUCCESS_STATUS_CODE = 200;
    const int NOT_MODIFIED_STATUS_CODE = 304;

    /***********************************************************
    ***********************************************************/
    private QPointer<JsonApiJob> notification_job;
    private AccountState account_state;


    signal void signal_new_notification_list (ActivityList);


    /***********************************************************
    ***********************************************************/
    public ServerNotificationHandler (AccountState account_state, GLib.Object parent = new GLib.Object ())
        base (parent);
        this.account_state = account_state;
    }



    /***********************************************************
    ***********************************************************/
    public void on_signal_fetch_notifications () {
        // check connectivity and credentials
        if (! (this.account_state && this.account_state.is_connected () && this.account_state.account () && this.account_state.account ().credentials () && this.account_state.account ().credentials ().ready ())) {
            delete_later ();
            return;
        }
        // check if the account has notifications enabled. If the capabilities are
        // not yet valid, its assumed that notifications are available.
        if (this.account_state.account ().capabilities ().is_valid ()) {
            if (!this.account_state.account ().capabilities ().notifications_available ()) {
                GLib.info ("Account" + this.account_state.account ().display_name ("does not have notifications enabled.";
                delete_later ();
                return;
            }
        }

        // if the previous notification job has on_signal_finished, on_signal_start next.
        this.notification_job = new JsonApiJob (this.account_state.account (), NOTIFICATIONS_PATH, this);
        GLib.Object.connect (this.notification_job.data (), &JsonApiJob.json_received,
            this, &ServerNotificationHandler.on_signal_notifications_received);
        GLib.Object.connect (this.notification_job.data (), &JsonApiJob.etag_response_header_received,
            this, &ServerNotificationHandler.on_signal_etag_response_header_received);
        GLib.Object.connect (this.notification_job.data (), &JsonApiJob.allow_desktop_notifications_changed,
                this, &ServerNotificationHandler.on_signal_allow_desktop_notifications_changed);
        this.notification_job.property (PROPERTY_ACCOUNT_STATE, GLib.Variant.from_value<AccountState> (this.account_state));
        this.notification_job.add_raw_header ("If-None-Match", this.account_state.notifications_etag_response_header ());
        this.notification_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_notifications_received (QJsonDocument json, int status_code) {
        if (status_code != SUCCESS_STATUS_CODE && status_code != NOT_MODIFIED_STATUS_CODE) {
            GLib.warn ("Notifications failed with status code " + status_code;
            delete_later ();
            return;
        }

        if (status_code == NOT_MODIFIED_STATUS_CODE) {
            GLib.warn ("Status code " + status_code + " Not Modified - No new notifications.";
            delete_later ();
            return;
        }

        var notifies = json.object ().value ("ocs").to_object ().value ("data").to_array ();

        var ai = qvariant_cast<AccountState> (sender ().property (PROPERTY_ACCOUNT_STATE));

        ActivityList list;

        foreach (var element, notifies) {
            Activity a;
            var json = element.to_object ();
            a.type = Activity.Type.NOTIFICATION;
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
                ActivityLink al;
                al.label = GLib.Uri.from_percent_encoding (action_json.value ("label").to_string ().to_utf8 ());
                al.link = action_json.value ("link").to_string ();
                al.verb = action_json.value ("type").to_string ().to_utf8 ();
                al.primary = action_json.value ("primary").to_bool ();

                a.links.append (al);
            }

            // Add another action to dismiss notification on server
            // https://github.com/owncloud/notifications/blob/master/docs/ocs-endpoint-v1.md#deleting-a-notification-for-a-user
            ActivityLink al;
            al.label = _("Dismiss");
            al.link = Utility.concat_url_path (ai.account ().url (), NOTIFICATIONS_PATH + "/" + string.number (a.id)).to_string ();
            al.verb = "DELETE";
            al.primary = false;
            a.links.append (al);

            list.append (a);
        }
        /* emit */ signal_new_notification_list (list);

        delete_later ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_etag_response_header_received (GLib.ByteArray value, int status_code) {
        if (status_code == SUCCESS_STATUS_CODE) {
            GLib.warn ("New Notification ETag Response Header received " + value;
            var account = qvariant_cast<AccountState> (sender ().property (PROPERTY_ACCOUNT_STATE));
            account.notifications_etag_response_header (value);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_allow_desktop_notifications_changed (bool is_allowed) {
        var account = qvariant_cast<AccountState> (sender ().property (PROPERTY_ACCOUNT_STATE));
        if (account != null) {
           account.desktop_notifications_allowed (is_allowed);
        }
    }

} // class ServerNotificationHandler

} // namespace Ui
} // namespace Occ