

// #include <QtCore>
// #include <QJsonDocument>
// #include <QJsonObject>


namespace Occ {

const string notifications_path = QLatin1String ("ocs/v2.php/apps/notifications/api/v2/notifications");
const char property_account_state_c[] = "oc_account_state";
const int success_status_code = 200;
const int not_modified_status_code = 304;

class Server_notification_handler : GLib.Object {
public:
    Server_notification_handler (AccountState *account_state, GLib.Object *parent = nullptr);

signals:
    void new_notification_list (Activity_list);

public slots:
    void slot_fetch_notifications ();

private slots:
    void slot_notifications_received (QJsonDocument &json, int status_code);
    void slot_etag_response_header_received (QByteArray &value, int status_code);
    void slot_allow_desktop_notifications_changed (bool is_allowed);

private:
    QPointer<JsonApiJob> _notification_job;
    AccountState *_account_state;
};


    Server_notification_handler.Server_notification_handler (AccountState *account_state, GLib.Object *parent)
        : GLib.Object (parent)
        , _account_state (account_state) {
    }

    void Server_notification_handler.slot_fetch_notifications () {
        // check connectivity and credentials
        if (! (_account_state && _account_state.is_connected () && _account_state.account () && _account_state.account ().credentials () && _account_state.account ().credentials ().ready ())) {
            delete_later ();
            return;
        }
        // check if the account has notifications enabled. If the capabilities are
        // not yet valid, its assumed that notifications are available.
        if (_account_state.account ().capabilities ().is_valid ()) {
            if (!_account_state.account ().capabilities ().notifications_available ()) {
                q_c_info (lc_server_notification) << "Account" << _account_state.account ().display_name () << "does not have notifications enabled.";
                delete_later ();
                return;
            }
        }

        // if the previous notification job has finished, start next.
        _notification_job = new JsonApiJob (_account_state.account (), notifications_path, this);
        GLib.Object.connect (_notification_job.data (), &JsonApiJob.json_received,
            this, &Server_notification_handler.slot_notifications_received);
        GLib.Object.connect (_notification_job.data (), &JsonApiJob.etag_response_header_received,
            this, &Server_notification_handler.slot_etag_response_header_received);
        GLib.Object.connect (_notification_job.data (), &JsonApiJob.allow_desktop_notifications_changed,
                this, &Server_notification_handler.slot_allow_desktop_notifications_changed);
        _notification_job.set_property (property_account_state_c, QVariant.from_value<AccountState> (_account_state));
        _notification_job.add_raw_header ("If-None-Match", _account_state.notifications_etag_response_header ());
        _notification_job.start ();
    }

    void Server_notification_handler.slot_etag_response_header_received (QByteArray &value, int status_code) {
        if (status_code == success_status_code) {
            q_c_warning (lc_server_notification) << "New Notification ETag Response Header received " << value;
            auto *account = qvariant_cast<AccountState> (sender ().property (property_account_state_c));
            account.set_notifications_etag_response_header (value);
        }
    }

    void Server_notification_handler.slot_allow_desktop_notifications_changed (bool is_allowed) {
        auto *account = qvariant_cast<AccountState> (sender ().property (property_account_state_c));
        if (account != nullptr) {
           account.set_desktop_notifications_allowed (is_allowed);
        }
    }

    void Server_notification_handler.slot_notifications_received (QJsonDocument &json, int status_code) {
        if (status_code != success_status_code && status_code != not_modified_status_code) {
            q_c_warning (lc_server_notification) << "Notifications failed with status code " << status_code;
            delete_later ();
            return;
        }

        if (status_code == not_modified_status_code) {
            q_c_warning (lc_server_notification) << "Status code " << status_code << " Not Modified - No new notifications.";
            delete_later ();
            return;
        }

        auto notifies = json.object ().value ("ocs").to_object ().value ("data").to_array ();

        auto *ai = qvariant_cast<AccountState> (sender ().property (property_account_state_c));

        Activity_list list;

        foreach (auto element, notifies) {
            Activity a;
            auto json = element.to_object ();
            a._type = Activity.Notification_type;
            a._acc_name = ai.account ().display_name ();
            a._id = json.value ("notification_id").to_int ();

            //need to know, specially for remote_share
            a._object_type = json.value ("object_type").to_string ();
            a._status = 0;

            a._subject = json.value ("subject").to_string ();
            a._message = json.value ("message").to_string ();
            a._icon = json.value ("icon").to_string ();

            QUrl link (json.value ("link").to_string ());
            if (!link.is_empty ()) {
                if (link.host ().is_empty ()) {
                    link.set_scheme (ai.account ().url ().scheme ());
                    link.set_host (ai.account ().url ().host ());
                }
                if (link.port () == -1) {
                    link.set_port (ai.account ().url ().port ());
                }
            }
            a._link = link;
            a._date_time = QDateTime.from_string (json.value ("datetime").to_string (), Qt.ISODate);

            auto actions = json.value ("actions").to_array ();
            foreach (auto action, actions) {
                auto action_json = action.to_object ();
                Activity_link al;
                al._label = QUrl.from_percent_encoding (action_json.value ("label").to_string ().to_utf8 ());
                al._link = action_json.value ("link").to_string ();
                al._verb = action_json.value ("type").to_string ().to_utf8 ();
                al._primary = action_json.value ("primary").to_bool ();

                a._links.append (al);
            }

            // Add another action to dismiss notification on server
            // https://github.com/owncloud/notifications/blob/master/docs/ocs-endpoint-v1.md#deleting-a-notification-for-a-user
            Activity_link al;
            al._label = tr ("Dismiss");
            al._link = Utility.concat_url_path (ai.account ().url (), notifications_path + "/" + string.number (a._id)).to_string ();
            al._verb = "DELETE";
            al._primary = false;
            a._links.append (al);

            list.append (a);
        }
        emit new_notification_list (list);

        delete_later ();
    }
    }
    