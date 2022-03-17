
//  #include <QAbstractListModel>
//  #include <Gtk.Image>
//  #include <QQuickImageProvider>
//  #include <chrono>
//  #include <pushnotifications
//  #include <QDesktopServ
//  #include <Gtk.Icon>
//  #include <QMessageB
//  #include <QSvgRenderer>
//  #include <QPainter>
//  #include <QPushButton>

namespace Occ {
namespace Ui {

public class UserModel : QAbstractListModel {

    public enum UserRoles {
        NAME = Qt.USER_ROLE + 1,
        SERVER,
        SERVER_HAS_USER_STATUS,
        STATUS_ICON,
        STATUS_EMOJI,
        STATUS_MESSAGE,
        DESKTOP_NOTIFICATION,
        AVATAR,
        IS_CURRENT_USER,
        IS_CONNECTED,
        IDENTIFIER;

        public static GLib.HashTable<int, string> role_names () {
            GLib.HashTable<int, string> roles;
            roles[UserRoles.NAME] = "name";
            roles[UserRoles.SERVER] = "server";
            roles[UserRoles.SERVER_HAS_USER_STATUS] = "server_has_user_status";
            roles[UserRoles.STATUS_ICON] = "status_icon";
            roles[UserRoles.STATUS_EMOJI] = "status_emoji";
            roles[UserRoles.STATUS_MESSAGE] = "status_message";
            roles[UserRoles.DESKTOP_NOTIFICATION] = "are_desktop_notifications_allowed";
            roles[UserRoles.AVATAR] = "avatar";
            roles[UserRoles.IS_CURRENT_USER] = "is_current_user";
            roles[UserRoles.IS_CONNECTED] = "is_connected";
            roles[UserRoles.IDENTIFIER] = "identifier";
            return roles;
        }
    }


    /***********************************************************
    Time span in milliseconds which must elapse between
    sequential refreshes of the notifications
    ***********************************************************/
    const int NOTIFICATION_REQUEST_FREE_PERIOD = 15000;


    /***********************************************************
    Time span in milliseconds which must elapse between
    sequential checks for expired activities
    ***********************************************************/
    const int64 EXPIRED_ACTIVITIES_CHECK_INTERVAL_MSEC = 1000 * 60;


    /***********************************************************
    Time span in milliseconds after which activities will
    expired by default
    ***********************************************************/
    const int64 ACTIVITY_DEFAULT_EXPIRATION_TIME_MSECS = 1000 * 60 * 10;


    /***********************************************************
    ***********************************************************/
    static UserModel instance {
        public get {
            if (!this.instance) {
                this.instance = new UserModel ();
            }
            return this.instance;
        }
        private set {
            this.instance = value;
        }
    }
    private GLib.List<User> users;
    /***********************************************************
    ***********************************************************/
    int current_user_id {
        public get {
            return this.current_user_id;
        }
        private set {
            this.current_user_id = value;
        }
        //  construct {
        //      this.current_user_id = 0;
        //  }
    }

    private bool init = true;


    internal signal void signal_add_account ();
    internal signal void signal_new_user_selected ();


    /***********************************************************
    ***********************************************************/
    private UserModel (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        // TODO: Remember selected user from last quit via settings file
        if (AccountManager.instance.accounts ().size () > 0) {
            build_user_list ();
        }

        connect (AccountManager.instance, AccountManager.signal_account_added,
            this, UserModel.build_user_list);
    }


    /***********************************************************
    ***********************************************************/
    public bool is_user_connected (int identifier) {
        if (identifier < 0 || identifier >= this.users.size ())
            return false;

        return this.users[identifier].is_connected ();
    }


    /***********************************************************
    ***********************************************************/
    public string current_user_server () {
        if (this.current_user_id < 0 || this.current_user_id >= this.users.size ())
            return {};

        return this.users[this.current_user_id].server ();
    }


    /***********************************************************
    ***********************************************************/
    public int current_user_index () {
        return this.current_user_id;
    }


    /***********************************************************
    ***********************************************************/
    public int row_count (QModelIndex index = QModelIndex ()) {
        //  Q_UNUSED (index);
        return this.users.count ();
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Variant data (QModelIndex index, int role) {
        if (index.row () < 0 || index.row () >= this.users.count ()) {
            return GLib.Variant ();
        }

        if (role == UserRoles.NAME) {
            return this.users[index.row ()].name ();
        } else if (role == UserRoles.SERVER) {
            return this.users[index.row ()].server ();
        } else if (role == UserRoles.SERVER_HAS_USER_STATUS) {
            return this.users[index.row ()].server_has_user_status ();
        } else if (role == UserRoles.STATUS_ICON) {
            return this.users[index.row ()].status_icon ();
        } else if (role == UserRoles.STATUS_EMOJI) {
            return this.users[index.row ()].status_emoji ();
        } else if (role == UserRoles.STATUS_MESSAGE) {
            return this.users[index.row ()].status_message ();
        } else if (role == UserRoles.DESKTOP_NOTIFICATION) {
            return this.users[index.row ()].are_desktop_notifications_allowed ();
        } else if (role == UserRoles.AVATAR) {
            return this.users[index.row ()].avatar_url ();
        } else if (role == UserRoles.IS_CURRENT_USER) {
            return this.users[index.row ()].is_current_user ();
        } else if (role == UserRoles.IS_CONNECTED) {
            return this.users[index.row ()].is_connected ();
        } else if (role == UserRoles.IDENTIFIER) {
            return index.row ();
        }
        return GLib.Variant ();
    }


    /***********************************************************
    ***********************************************************/
    public Gtk.Image avatar_by_identifier (int identifier) {
        if (identifier < 0 || identifier >= this.users.size ())
            return {};

        return this.users[identifier].avatar ();
    }


    /***********************************************************
    ***********************************************************/
    public User current_user () {
        if (current_user_id () < 0 || current_user_id () >= this.users.size ())
            return null;

        return this.users[current_user_id ()];
    }


    /***********************************************************
    ***********************************************************/
    public int find_identifier_for_account (AccountState account) {
        int identifier = 0;
        foreach (var user in this.users) {
            identifer++;
            if (user.account.identifier () == account.account.identifier ()) {
                break;
            }
        }
        if (identifier == this.users.length) {
            identifier =-1;
        }
        return identifier;
    }


    /***********************************************************
    ***********************************************************/
    public void fetch_current_activity_model () {
        if (current_user_id () < 0 || current_user_id () >= this.users.size ())
            return;

        this.users[current_user_id ()].on_signal_refresh ();
    }


    /***********************************************************
    ***********************************************************/
    public void add_user (unowned AccountState user, bool is_current) {
        bool contains_user = false;
        foreach (var u in this.users) {
            if (u.account == user.account) {
                contains_user = true;
                continue;
            }
        }

        if (!contains_user) {
            int row = row_count ();
            begin_insert_rows (QModelIndex (), row, row);

            User u = new User (user, is_current);

            connect (
                u,
                User.signal_avatar_changed,
                this,
                this.on_signal_avatar_changed
            );

            connect (
                u,
                User.signal_status_changed,
                this,
                this.on_signal_status_changed
            );

            connect (
                u,
                User.signal_desktop_notifications_allowed_changed,
                this,
                this.on_signal_desktop_notifications_allowed_changed
            );

            connect (
                u,
                User.signal_account_state_changed,
                this,
                this.on_signal_account_state_changed
            );

            this.users += u;

            if (is_current) {
                this.current_user_id = this.users.index_of (this.users.last ());
            }

            end_insert_rows ();
            ConfigFile config;
            this.users.last ().on_signal_notification_refresh_interval (config.notification_refresh_interval ());
            /* emit */ signal_new_user_selected ();
        }
    }



    /***********************************************************
    ***********************************************************/
    private void on_signal_avatar_changed (int row) {
        /* emit */ data_changed (
            index (row, 0),
            index (row, 0),
            {
                UserModel.UserRoles.AVATAR
            }
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_status_changed (int row) {
        /* emit */ data_changed (
            index (row, 0),
            index (row, 0),
            {
                UserModel.UserRoles.STATUS_ICON,
                UserModel.UserRoles.STATUS_EMOJI,
                UserModel.UserRoles.STATUS_MESSAGE
            }
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_desktop_notifications_allowed_changed (int row) {
        /* emit */ data_changed (
            index (row, 0),
            index (row, 0),
            {
                UserModel.UserRoles.DESKTOP_NOTIFICATION
            }
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_account_state_changed (int row) {
        /* emit */ data_changed (
            index (row, 0),
            index (row, 0),
            {
                UserModel.UserRoles.IS_CONNECTED
            }
        );
    }


    /***********************************************************
    ***********************************************************/
    public void open_current_account_local_folder () {
        if (this.current_user_id < 0 || this.current_user_id >= this.users.size ()) {
            return;
        }

        this.users[this.current_user_id].open_local_folder ();
    }


    /***********************************************************
    ***********************************************************/
    public void open_current_account_talk () {
        if (!current_user ()) {
            return;
        }

        const var talk_app = current_user ().talk_app ();
        if (talk_app) {
            Utility.open_browser (talk_app.url ());
        } else {
            GLib.warning ("The Talk app is not enabled on " + current_user ().server ());
        }
    }


    /***********************************************************
    ***********************************************************/
    public void open_current_account_server () {
        if (this.current_user_id < 0 || this.current_user_id >= this.users.size ()) {
            return;
        }

        string url = this.users[this.current_user_id].server (false);
        if (!url.starts_with ("http://") && !url.starts_with ("https://")) {
            url = "https://" + this.users[this.current_user_id].server (false);
        }

        QDesktopServices.open_url (url);
    }


    /***********************************************************
    ***********************************************************/
    public int number_of_users () {
        return this.users.size ();
    }


    /***********************************************************
    ***********************************************************/
    public void switch_current_user (int identifier) {
        if (this.current_user_id < 0 || this.current_user_id >= this.users.size ()) {
            return;
        }

        this.users[this.current_user_id].is_current_user (false);
        this.users[identifier].is_current_user (true);
        this.current_user_id = identifier;
        /* emit */ signal_new_user_selected ();
    }


    /***********************************************************
    ***********************************************************/
    public void log_in (int identifier) {
        if (identifier < 0 || identifier >= this.users.size ()) {
            return;
        }

        this.users[identifier].log_in ();
    }


    /***********************************************************
    ***********************************************************/
    public void log_out (int identifier) {
        if (identifier < 0 || identifier >= this.users.size ()) {
            return;
        }

        this.users[identifier].log_out ();
    }


    /***********************************************************
    ***********************************************************/
    public void remove_account (int identifier) {
        if (identifier < 0 || identifier >= this.users.size ())
            return;

        QMessageBox message_box = new QMessageBox (
            QMessageBox.Question,
            _("Confirm Account Removal"),
            _("<p>Do you really want to remove the connection to the account <i>%1</i>?</p>"
            + "<p><b>Note:</b> This will <b>not</b> delete any files.</p>")
                .printf (this.users[identifier].name ()),
            QMessageBox.NoButton);
        QPushButton yes_button =
            message_box.add_button (_("Remove connection"), QMessageBox.YesRole);
        message_box.add_button (_("Cancel"), QMessageBox.NoRole);

        message_box.exec ();
        if (message_box.clicked_button () != yes_button) {
            return;
        }

        if (this.users[identifier].is_current_user () && this.users.count () > 1) {
            if (identifier == 0) {
                switch_current_user (1);
            } else {
                switch_current_user (0);
            }
        }

        this.users[identifier].log_out ();
        this.users[identifier].remove_account ();

        begin_remove_rows (QModelIndex (), identifier, identifier);
        this.users.remove_at (identifier);
        end_remove_rows ();
    }


    /***********************************************************
    ***********************************************************/
    public std.shared_ptr<Occ.UserStatusConnector> user_status_connector (int identifier) {
        if (identifier < 0 || identifier >= this.users.size ()) {
            return null;
        }

        return this.users[identifier].account.user_status_connector ();
    }


    /***********************************************************
    ***********************************************************/
    public ActivityListModel current_activity_model () {
        if (current_user_index () < 0 || current_user_index () >= this.users.size ())
            return null;

        return this.users[current_user_index ()].activity_model ();
    }


    /***********************************************************
    ***********************************************************/
    public AccountAppList app_list (){
        if (this.current_user_id < 0 || this.current_user_id >= this.users.size ())
            return {};

        return this.users[this.current_user_id].app_list ();
    }


    /***********************************************************
    ***********************************************************/
    private void build_user_list () {
        for (int i = 0; i < AccountManager.instance.accounts ().size (); i++) {
            var user = AccountManager.instance.accounts ().at (i);
            add_user (user);
        }
        if (this.init) {
            this.users.first ().is_current_user (true);
            this.init = false;
        }
    }

} // class UserModel

} // namespace Ui
} // namespace Occ
