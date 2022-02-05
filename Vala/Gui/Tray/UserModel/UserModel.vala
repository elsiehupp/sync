#ifndef USERMODEL_H
const int USERMODEL_H

//  #include <QAbstractListModel>
//  #include <QImage>
//  #include <QQuick_image_provider>
//  #include <chrono>
//  #include <pushnotifications
//  #include <QDesktopServ
//  #include <QIcon>
//  #include <QMessageB
//  #include <QSvgRenderer>
//  #include <QPainter>
//  #include <QPushButton>

// time span in milliseconds which has to be between two
// refreshes of the notifications
const int NOTIFICATION_REQUEST_FREE_PERIOD 15000

namespace {
constexpr int64 expired_activities_check_interval_msecs = 1000 * 60;
constexpr int64 activity_default_expiration_time_msecs = 1000 * 60 * 10;
}

namespace Occ {

class User_model : QAbstractListModel {
    //  Q_PROPERTY (User* current_user READ current_user NOTIFY new_user_selected)
    //  Q_PROPERTY (int current_user_id READ current_user_id NOTIFY new_user_selected)

    /***********************************************************
    ***********************************************************/
    public static User_model instance ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int current_user_index ();

    /***********************************************************
    ***********************************************************/
    public int row_count (QModelIndex parent = QModelIndex ()) override;

    /***********************************************************
    ***********************************************************/
    public GLib.Variant data (QModelIndex in

    /***********************************************************
    ***********************************************************/
    public QImage avatar_by_id (

    /***********************************************************
    ***********************************************************/
    public User current_user ();

    /***********************************************************
    ***********************************************************/
    public int find_user_id_for_account (AccountS

    /***********************************************************
    ***********************************************************/
    public void fetch_current_activity_model ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void open_current_

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int num_users ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public int current_user_id ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void switch_current_user (int identifier);

    /***********************************************************
    ***********************************************************/
    public void login (int identifier);


    public void logout (int identifier);


    public void remove_account (int identifier);

    public std.shared_ptr<Occ.UserStatusConnector> user_status_connector (int identifier);

    public ActivityListModel current_activity_model ();

    public enum User_roles {
        Name_role = Qt.User_role + 1,
        Server_role,
        Server_has_user_status_role,
        Status_icon_role,
        Status_emoji_role,
        Status_message_role,
        Desktop_notifications_allowed_role,
        Avatar_role,
        Is_current_user_role,
        Is_connected_role,
        Id_role
    };

    /***********************************************************
    ***********************************************************/
    public AccountAppList app_list ();

signals:
    Q_INVOKABLE void add_account ();
    Q_INVOKABLE void new_user_selected ();


    protected GLib.HashMap<int, GLib.ByteArray> role_names () override;


    /***********************************************************
    ***********************************************************/
    private static User_model this.instance;
    private User_model (GLib.Object parent = new GLib.Object ());
    private GLib.List<User> this.users;
    private int this.current_user_id = 0;
    private bool this.init = true;

    /***********************************************************
    ***********************************************************/
    private void build_user_list ();
}

User_model *User_model.instance = null;

User_model *User_model.instance () {
    if (!this.instance) {
        this.instance = new User_model ();
    }
    return this.instance;
}

User_model.User_model (GLib.Object parent)
    : QAbstractListModel (parent) {
    // TODO : Remember selected user from last quit via settings file
    if (AccountManager.instance ().accounts ().size () > 0) {
        build_user_list ();
    }

    connect (AccountManager.instance (), &AccountManager.on_account_added,
        this, &User_model.build_user_list);
}

void User_model.build_user_list () {
    for (int i = 0; i < AccountManager.instance ().accounts ().size (); i++) {
        var user = AccountManager.instance ().accounts ().at (i);
        add_user (user);
    }
    if (this.init) {
        this.users.first ().set_current_user (true);
        this.init = false;
    }
}

// Q_INVOKABLE
int User_model.num_users () {
    return this.users.size ();
}

// Q_INVOKABLE
int User_model.current_user_id () {
    return this.current_user_id;
}

// Q_INVOKABLE
bool User_model.is_user_connected (int identifier) {
    if (identifier < 0 || identifier >= this.users.size ())
        return false;

    return this.users[identifier].is_connected ();
}

QImage User_model.avatar_by_id (int identifier) {
    if (identifier < 0 || identifier >= this.users.size ())
        return {};

    return this.users[identifier].avatar ();
}

// Q_INVOKABLE
string User_model.current_user_server () {
    if (this.current_user_id < 0 || this.current_user_id >= this.users.size ())
        return {};

    return this.users[this.current_user_id].server ();
}

void User_model.add_user (AccountStatePtr user, bool is_current) {
    bool contains_user = false;
    for (var u : q_as_const (this.users)) {
        if (u.account () == user.account ()) {
            contains_user = true;
            continue;
        }
    }

    if (!contains_user) {
        int row = row_count ();
        begin_insert_rows (QModelIndex (), row, row);

        User u = new User (user, is_current);

        connect (u, &User.avatar_changed, this, [this, row] {
           /* emit */ data_changed (index (row, 0), index (row, 0), {User_model.Avatar_role});
        });

        connect (u, &User.status_changed, this, [this, row] {
            /* emit */ data_changed (index (row, 0), index (row, 0), {User_model.Status_icon_role,
			    				    User_model.Status_emoji_role,
                                                            User_model.Status_message_role});
        });

        connect (u, &User.desktop_notifications_allowed_changed, this, [this, row] {
            /* emit */ data_changed (index (row, 0), index (row, 0), {
                User_model.Desktop_notifications_allowed_role
            });
        });

        connect (u, &User.account_state_changed, this, [this, row] {
            /* emit */ data_changed (index (row, 0), index (row, 0), {
                User_model.Is_connected_role
            });
        });

        this.users << u;
        if (is_current) {
            this.current_user_id = this.users.index_of (this.users.last ());
        }

        end_insert_rows ();
        ConfigFile config;
        this.users.last ().on_set_notification_refresh_interval (config.notification_refresh_interval ());
        /* emit */ new_user_selected ();
    }
}

int User_model.current_user_index () {
    return this.current_user_id;
}

// Q_INVOKABLE
void User_model.open_current_account_local_folder () {
    if (this.current_user_id < 0 || this.current_user_id >= this.users.size ())
        return;

    this.users[this.current_user_id].open_local_folder ();
}

// Q_INVOKABLE
void User_model.open_current_account_talk () {
    if (!current_user ())
        return;

    const var talk_app = current_user ().talk_app ();
    if (talk_app) {
        Utility.open_browser (talk_app.url ());
    } else {
        GLib.warn (lc_activity) << "The Talk app is not enabled on" << current_user ().server ();
    }
}

// Q_INVOKABLE
void User_model.open_current_account_server () {
    if (this.current_user_id < 0 || this.current_user_id >= this.users.size ())
        return;

    string url = this.users[this.current_user_id].server (false);
    if (!url.starts_with ("http://") && !url.starts_with ("https://")) {
        url = "https://" + this.users[this.current_user_id].server (false);
    }

    QDesktopServices.open_url (url);
}

// Q_INVOKABLE
void User_model.switch_current_user (int identifier) {
    if (this.current_user_id < 0 || this.current_user_id >= this.users.size ())
        return;

    this.users[this.current_user_id].set_current_user (false);
    this.users[identifier].set_current_user (true);
    this.current_user_id = identifier;
    /* emit */ new_user_selected ();
}

// Q_INVOKABLE
void User_model.login (int identifier) {
    if (identifier < 0 || identifier >= this.users.size ())
        return;

    this.users[identifier].login ();
}

// Q_INVOKABLE
void User_model.logout (int identifier) {
    if (identifier < 0 || identifier >= this.users.size ())
        return;

    this.users[identifier].logout ();
}

// Q_INVOKABLE
void User_model.remove_account (int identifier) {
    if (identifier < 0 || identifier >= this.users.size ())
        return;

    QMessageBox message_box (QMessageBox.Question,
        _("Confirm Account Removal"),
        _("<p>Do you really want to remove the connection to the account <i>%1</i>?</p>"
           "<p><b>Note:</b> This will <b>not</b> delete any files.</p>")
            .arg (this.users[identifier].name ()),
        QMessageBox.NoButton);
    QPushButton yes_button =
        message_box.add_button (_("Remove connection"), QMessageBox.YesRole);
    message_box.add_button (_("Cancel"), QMessageBox.NoRole);

    message_box.exec ();
    if (message_box.clicked_button () != yes_button) {
        return;
    }

    if (this.users[identifier].is_current_user () && this.users.count () > 1) {
        identifier == 0 ? switch_current_user (1) : switch_current_user (0);
    }

    this.users[identifier].logout ();
    this.users[identifier].remove_account ();

    begin_remove_rows (QModelIndex (), identifier, identifier);
    this.users.remove_at (identifier);
    end_remove_rows ();
}

std.shared_ptr<Occ.UserStatusConnector> User_model.user_status_connector (int identifier) {
    if (identifier < 0 || identifier >= this.users.size ()) {
        return null;
    }

    return this.users[identifier].account ().user_status_connector ();
}

int User_model.row_count (QModelIndex parent) {
    //  Q_UNUSED (parent);
    return this.users.count ();
}

GLib.Variant User_model.data (QModelIndex index, int role) {
    if (index.row () < 0 || index.row () >= this.users.count ()) {
        return GLib.Variant ();
    }

    if (role == Name_role) {
        return this.users[index.row ()].name ();
    } else if (role == Server_role) {
        return this.users[index.row ()].server ();
    } else if (role == Server_has_user_status_role) {
        return this.users[index.row ()].server_has_user_status ();
    } else if (role == Status_icon_role) {
        return this.users[index.row ()].status_icon ();
    } else if (role == Status_emoji_role) {
        return this.users[index.row ()].status_emoji ();
    } else if (role == Status_message_role) {
        return this.users[index.row ()].status_message ();
    } else if (role == Desktop_notifications_allowed_role) {
        return this.users[index.row ()].is_desktop_notifications_allowed ();
    } else if (role == Avatar_role) {
        return this.users[index.row ()].avatar_url ();
    } else if (role == Is_current_user_role) {
        return this.users[index.row ()].is_current_user ();
    } else if (role == Is_connected_role) {
        return this.users[index.row ()].is_connected ();
    } else if (role == Id_role) {
        return index.row ();
    }
    return GLib.Variant ();
}

GLib.HashMap<int, GLib.ByteArray> User_model.role_names () {
    GLib.HashMap<int, GLib.ByteArray> roles;
    roles[Name_role] = "name";
    roles[Server_role] = "server";
    roles[Server_has_user_status_role] = "server_has_user_status";
    roles[Status_icon_role] = "status_icon";
    roles[Status_emoji_role] = "status_emoji";
    roles[Status_message_role] = "status_message";
    roles[Desktop_notifications_allowed_role] = "desktop_notifications_allowed";
    roles[Avatar_role] = "avatar";
    roles[Is_current_user_role] = "is_current_user";
    roles[Is_connected_role] = "is_connected";
    roles[Id_role] = "identifier";
    return roles;
}

ActivityListModel *User_model.current_activity_model () {
    if (current_user_index () < 0 || current_user_index () >= this.users.size ())
        return null;

    return this.users[current_user_index ()].get_activity_model ();
}

void User_model.fetch_current_activity_model () {
    if (current_user_id () < 0 || current_user_id () >= this.users.size ())
        return;

    this.users[current_user_id ()].on_refresh ();
}

AccountAppList User_model.app_list () {
    if (this.current_user_id < 0 || this.current_user_id >= this.users.size ())
        return {};

    return this.users[this.current_user_id].app_list ();
}

User *User_model.current_user () {
    if (current_user_id () < 0 || current_user_id () >= this.users.size ())
        return null;

    return this.users[current_user_id ()];
}

int User_model.find_user_id_for_account (AccountState account) {
    const var it = std.find_if (std.cbegin (this.users), std.cend (this.users), [=] (User user) {
        return user.account ().identifier () == account.account ().identifier ();
    });

    if (it == std.cend (this.users)) {
        return -1;
    }

    const var identifier = std.distance (std.cbegin (this.users), it);
    return identifier;
}

/*-------------------------------------------------------------------------------------*/

Image_provider.Image_provider ()
    : QQuick_image_provider (QQuick_image_provider.Image) {
}

QImage Image_provider.request_image (string identifier, QSize size, QSize requested_size) {
    //  Q_UNUSED (size)
    //  Q_UNUSED (requested_size)

    const var make_icon = [] (string path) {
        QImage image (128, 128, QImage.Format_ARGB32);
        image.fill (Qt.Global_color.transparent);
        QPainter painter (&image);
        QSvgRenderer renderer (path);
        renderer.render (&painter);
        return image;
    };

    if (identifier == QLatin1String ("fallback_white")) {
        return make_icon (QStringLiteral (":/client/theme/white/user.svg"));
    }

    if (identifier == QLatin1String ("fallback_black")) {
        return make_icon (QStringLiteral (":/client/theme/black/user.svg"));
    }

    const int uid = identifier.to_int ();
    return User_model.instance ().avatar_by_id (uid);
}


}
