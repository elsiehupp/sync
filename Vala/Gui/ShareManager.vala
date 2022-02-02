/***********************************************************
Copyright (C) by Roeland Jago Douma <rullzer@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Uri>
// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QJsonArray>


// #include <QDate>
// #include <GLib.List>

// #include <GLib.Uri>



namespace Occ {


class Share : GLib.Object {

    /***********************************************************
    Possible share types
    Need to be in sync with Sharee.Type
    ***********************************************************/
    public enum Share_type {
        Type_user = Sharee.User,
        Type_group = Sharee.Group,
        Type_link = 3,
        Type_email = Sharee.Email,
        Type_remote = Sharee.Federated,
        Type_circle = Sharee.Circle,
        Type_room = Sharee.Room
    };

    /***********************************************************
    ***********************************************************/
    public using Permissions = Share_permissions;


    /***********************************************************
    Constructor for shares
    ***********************************************************/
    public Share (AccountPointer account,
        const string id,
        const string owner,
        const string owner_display_name,
        const string path,
        const Share_type share_type,
        bool is_password_set = false,
        const Permissions permissions = Share_permission_default,
        const unowned<Sharee> share_with = unowned<Sharee> (nullptr));


    /***********************************************************
    The account the share is defined on.
    ***********************************************************/
    public AccountPointer account ();

    /***********************************************************
    ***********************************************************/
    public string path ();


    /***********************************************************
    Get the id
    ***********************************************************/
    public string get_id ();


    /***********************************************************
    Get the uid_owner
    ***********************************************************/
    public string get_uid_owner ();


    /***********************************************************
    Get the owner display name
    ***********************************************************/
    public string get_owner_display_name ();


    /***********************************************************
    Get the share_type
    ***********************************************************/
    public Share_type get_share_type ();


    /***********************************************************
    Get the share_with
    ***********************************************************/
    public unowned<Sharee> get_share_with ();


    /***********************************************************
    Get permissions
    ***********************************************************/
    public Permissions get_permissions ();


    /***********************************************************
    Set the permissions of a share

    On on_success the permissions_set signal is emitted
    In case of a server error the on_server_error signal is emitted.
    ***********************************************************/
    public void set_permissions (Permissions permissions);


    /***********************************************************
    Set the password for remote share

    On on_success the password_set signal is emitted
    In case of a server error the password_set_error signal is emitted.
    ***********************************************************/
    public void set_password (string password);

    /***********************************************************
    ***********************************************************/
    public bool is_password_set ();


    /***********************************************************
    Deletes a share

    On on_success the share_deleted signal is emitted
    In case of a server error the on_server_error signal is emitted.
    ***********************************************************/
    public void delete_share ();


    /***********************************************************
    Is it a share with a user or group (local or remote)
    ***********************************************************/
    public static bool is_share_type_user_group_email_room_or_remote (Share_type type);

signals:
    void permissions_set ();
    void share_deleted ();
    void on_server_error (int code, string message);
    void password_set ();
    void password_set_error (int status_code, string message);


    protected AccountPointer this.account;
    protected string this.id;
    protected string this.uidowner;
    protected string this.owner_display_name;
    protected string this.path;
    protected Share_type this.share_type;
    protected bool this.is_password_set;
    protected Permissions this.permissions;
    protected unowned<Sharee> this.share_with;

protected slots:
    void on_ocs_error (int status_code, string message);
    void on_password_set (QJsonDocument &, GLib.Variant value);
    void on_set_password_error (int status_code, string message);


    /***********************************************************
    ***********************************************************/
    private void on_deleted ();
    private void on_permissions_set (QJsonDocument &, GLib.Variant value);
};

/***********************************************************
A Link share is just like a regular share but then slightly different.
There are several methods in the API that either work differently for
link shares or are only available to link shares.
***********************************************************/
class Link_share : Share {

    /***********************************************************
    ***********************************************************/
    public Link_share (AccountPointer account,
        const string id,
        const string uidowner,
        const string owner_display_name,
        const string path,
        const string name,
        const string token,
        const Permissions permissions,
        bool is_password_set,
        const GLib.Uri url,
        const QDate expire_date,
        const string note,
        const string label);


    /***********************************************************
    Get the share link
    ***********************************************************/
    public GLib.Uri get_link ();


    /***********************************************************
    The share's link for direct downloading.
    ***********************************************************/
    public GLib.Uri get_direct_download_link ();


    /***********************************************************
    Get the public_upload status of this share
    ***********************************************************/
    public bool get_public_upload ();


    /***********************************************************
    Whether directory listings are available (READ permission)
    ***********************************************************/
    public bool get_show_file_listing ();


    /***********************************************************
    Returns the name of the link share. Can be empty.
    ***********************************************************/
    public string get_name ();


    /***********************************************************
    Returns the note of the link share.
    ***********************************************************/
    public string get_note ();


    /***********************************************************
    Returns the label of the link share.
    ***********************************************************/
    public string get_label ();


    /***********************************************************
    Set the name of the link share.

    Emits either name_set () or on_server_error ().
    ***********************************************************/
    public void set_name (string name);


    /***********************************************************
    Set the note of the link share.
    ***********************************************************/
    public void set_note (string note);


    /***********************************************************
    Returns the token of the link share.
    ***********************************************************/
    public string get_token ();


    /***********************************************************
    Get the expiration date
    ***********************************************************/
    public QDate get_expire_date ();


    /***********************************************************
    Set the expiration date

    On on_success the expire_date_set signal is emitted
    In case of a server error the on_server_error signal is emitted.
    ***********************************************************/
    public void set_expire_date (QDate expire_date);


    /***********************************************************
    Set the label of the share link.
    ***********************************************************/
    public void set_label (string label);


    /***********************************************************
    Create Ocs_share_job and connect to signal/slots
    ***********************************************************/
    public template <typename Link_share_slot>
    public Ocs_share_job create_share_job (Link_share_slot on_function);

signals:
    void expire_date_set ();
    void note_set ();
    void name_set ();
    void label_set ();


    /***********************************************************
    ***********************************************************/
    private void on_note_set (QJsonDocument &, GLib.Variant value);
    private void on_expire_date_set (QJsonDocument reply, GLib.Variant value);
    private void on_name_set (QJsonDocument &, GLib.Variant value);
    private void on_label_set (QJsonDocument &, GLib.Variant value);


    /***********************************************************
    ***********************************************************/
    private string this.name;
    private string this.token;
    private string this.note;
    private QDate this.expire_date;
    private GLib.Uri this.url;
    private string this.label;
};

class User_group_share : Share {

    /***********************************************************
    ***********************************************************/
    public User_group_share (AccountPointer account,
        const string id,
        const string owner,
        const string owner_display_name,
        const string path,
        const Share_type share_type,
        bool is_password_set,
        const Permissions permissions,
        const unowned<Sharee> share_with,
        const QDate expire_date,
        const string note);

    /***********************************************************
    ***********************************************************/
    public void set_note (string note);

    /***********************************************************
    ***********************************************************/
    public string get_note ();

    /***********************************************************
    ***********************************************************/
    public void on_note_set (QJsonDocument &, GLib.Variant note);

    /***********************************************************
    ***********************************************************/
    public void set_expire_date (QDate date);

    /***********************************************************
    ***********************************************************/
    public QDate get_expire_date ();

    /***********************************************************
    ***********************************************************/
    public void on_expire_date_set (QJsonDocument reply, GLib.Variant value);

signals:
    void note_set ();
    void note_set_error ();
    void expire_date_set ();


    /***********************************************************
    ***********************************************************/
    private string this.note;
    private QDate this.expire_date;
};

/***********************************************************
The share manager allows for creating, retrieving and deletion
of shares. It abstracts away from the OCS Share API, all the usages
shares should talk to this manager and not use OCS Share Job directly
***********************************************************/
class Share_manager : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public Share_manager (AccountPointer this.account, GLib.Object parent = new GLib.Object ());


    /***********************************************************
    Tell the manager to create a link share

    @param path The path of the linkshare relative to the u
    @param name The name of the created share, may be empty
    @param password The password of the share, may be

    On on_success the signal on_link_share_created is emitted
    For older server the on_link_share_requires_password signal is emitted when it seems appropiate
    In case of a server error the on_server_error signal is emitted
    ***********************************************************/
    public void create_link_share (string path,
        const string name,
        const string password);


    /***********************************************************
    Tell the manager to create a new share

    @param path The path of the share relative to the user folder on the
    @param share_type The type of share (Type_u
    @param Permissions The share permissions

    On on_success the signal share_created is emitted
    In case of a server error the on_server_error signal is emitted
    ***********************************************************/
    public void create_share (string path,
        const Share.Share_type share_type,
        const string share_with,
        const Share.Permissions permissions,
        const string password = "");


    /***********************************************************
    Fetch all the shares for path

    @param path The path to get the shares for rel

    On on_success the on_shares_fetched signal is emitted
    In case of a server error the on_server_error signal is emitted
    ***********************************************************/
    public void fetch_shares (string path);

signals:
    void share_created (unowned<Share> share);
    void on_link_share_created (unowned<Link_share> share);
    void on_shares_fetched (GLib.List<unowned<Share>> shares);
    void on_server_error (int code, string message);


    /***********************************************************
    Emitted when creating a link share with password fails.

    @param message the error message reported by the server

    See create_link_share ().
    ***********************************************************/
    void on_link_share_requires_password (string message);


    /***********************************************************
    ***********************************************************/
    private void on_shares_fetched (QJsonDocument reply);
    private void on_link_share_created (QJsonDocument reply);
    private void on_share_created (QJsonDocument reply);
    private void on_ocs_error (int status_code, string message);

    /***********************************************************
    ***********************************************************/
    private unowned<Link_share> parse_link_share (QJsonObject data);
    private unowned<User_group_share> parse_user_group_share (QJsonObject data);
    private unowned<Share> parse_share (QJsonObject data);

    /***********************************************************
    ***********************************************************/
    private AccountPointer this.account;
};


/***********************************************************
When a share is modified, we need to tell the folders so they can adjust overlay icons
***********************************************************/
static void update_folder (AccountPointer account, string path) {
    foreach (Folder f, FolderMan.instance ().map ()) {
        if (f.account_state ().account () != account)
            continue;
        var folder_path = f.remote_path ();
        if (path.starts_with (folder_path) && (path == folder_path || folder_path.ends_with ('/') || path[folder_path.size ()] == '/')) {
            // Workaround the fact that the server does not invalidate the etags of parent directories
            // when something is shared.
            var relative = path.mid_ref (f.remote_path_trailing_slash ().length ());
            f.journal_database ().schedule_path_for_remote_discovery (relative.to_"");

            // Schedule a sync so it can update the remote permission flag and let the socket API
            // know about the shared icon.
            f.schedule_this_folder_soon ();
        }
    }
}

Share.Share (AccountPointer account,
    const string id,
    const string uidowner,
    const string owner_display_name,
    const string path,
    const Share_type share_type,
    bool is_password_set,
    const Permissions permissions,
    const unowned<Sharee> share_with)
    : this.account (account)
    , this.id (id)
    , this.uidowner (uidowner)
    , this.owner_display_name (owner_display_name)
    , this.path (path)
    , this.share_type (share_type)
    , this.is_password_set (is_password_set)
    , this.permissions (permissions)
    , this.share_with (share_with) {
}

AccountPointer Share.account () {
    return this.account;
}

string Share.path () {
    return this.path;
}

string Share.get_id () {
    return this.id;
}

string Share.get_uid_owner () {
    return this.uidowner;
}

string Share.get_owner_display_name () {
    return this.owner_display_name;
}

Share.Share_type Share.get_share_type () {
    return this.share_type;
}

unowned<Sharee> Share.get_share_with () {
    return this.share_with;
}

void Share.set_password (string password) {
    var * const job = new Ocs_share_job (this.account);
    connect (job, &Ocs_share_job.share_job_finished, this, &Share.on_password_set);
    connect (job, &Ocs_job.ocs_error, this, &Share.on_set_password_error);
    job.set_password (get_id (), password);
}

bool Share.is_password_set () {
    return this.is_password_set;
}

void Share.set_permissions (Permissions permissions) {
    var job = new Ocs_share_job (this.account);
    connect (job, &Ocs_share_job.share_job_finished, this, &Share.on_permissions_set);
    connect (job, &Ocs_job.ocs_error, this, &Share.on_ocs_error);
    job.set_permissions (get_id (), permissions);
}

void Share.on_permissions_set (QJsonDocument &, GLib.Variant value) {
    this.permissions = (Permissions)value.to_int ();
    /* emit */ permissions_set ();
}

Share.Permissions Share.get_permissions () {
    return this.permissions;
}

void Share.delete_share () {
    var job = new Ocs_share_job (this.account);
    connect (job, &Ocs_share_job.share_job_finished, this, &Share.on_deleted);
    connect (job, &Ocs_job.ocs_error, this, &Share.on_ocs_error);
    job.delete_share (get_id ());
}

bool Share.is_share_type_user_group_email_room_or_remote (Share_type type) {
    return (type == Share.Type_user || type == Share.Type_group || type == Share.Type_email || type == Share.Type_room
        || type == Share.Type_remote);
}

void Share.on_deleted () {
    update_folder (this.account, this.path);
    /* emit */ share_deleted ();
}

void Share.on_ocs_error (int status_code, string message) {
    /* emit */ server_error (status_code, message);
}

void Share.on_password_set (QJsonDocument &, GLib.Variant value) {
    this.is_password_set = !value.to_"".is_empty ();
    /* emit */ password_set ();
}

void Share.on_set_password_error (int status_code, string message) {
    /* emit */ password_set_error (status_code, message);
}

GLib.Uri Link_share.get_link () {
    return this.url;
}

GLib.Uri Link_share.get_direct_download_link () {
    GLib.Uri url = this.url;
    url.set_path (url.path () + "/download");
    return url;
}

QDate Link_share.get_expire_date () {
    return this.expire_date;
}

Link_share.Link_share (AccountPointer account,
    const string id,
    const string uidowner,
    const string owner_display_name,
    const string path,
    const string name,
    const string token,
    Permissions permissions,
    bool is_password_set,
    const GLib.Uri url,
    const QDate expire_date,
    const string note,
    const string label)
    : Share (account, id, uidowner, owner_display_name, path, Share.Type_link, is_password_set, permissions)
    , this.name (name)
    , this.token (token)
    , this.note (note)
    , this.expire_date (expire_date)
    , this.url (url)
    , this.label (label) {
}

bool Link_share.get_public_upload () {
    return this.permissions & Share_permission_create;
}

bool Link_share.get_show_file_listing () {
    return this.permissions & Share_permission_read;
}

string Link_share.get_name () {
    return this.name;
}

string Link_share.get_note () {
    return this.note;
}

string Link_share.get_label () {
    return this.label;
}

void Link_share.set_name (string name) {
    create_share_job (&Link_share.on_name_set).set_name (get_id (), name);
}

void Link_share.set_note (string note) {
    create_share_job (&Link_share.on_note_set).set_note (get_id (), note);
}

void Link_share.on_note_set (QJsonDocument &, GLib.Variant note) {
    this.note = note.to_"";
    /* emit */ note_set ();
}

string Link_share.get_token () {
    return this.token;
}

void Link_share.set_expire_date (QDate date) {
    create_share_job (&Link_share.on_expire_date_set).set_expire_date (get_id (), date);
}

void Link_share.set_label (string label) {
    create_share_job (&Link_share.on_label_set).set_label (get_id (), label);
}

template <typename Link_share_slot>
Ocs_share_job *Link_share.create_share_job (Link_share_slot on_function) {
    var job = new Ocs_share_job (this.account);
    connect (job, &Ocs_share_job.share_job_finished, this, on_function);
    connect (job, &Ocs_job.ocs_error, this, &Link_share.on_ocs_error);
    return job;
}

void Link_share.on_expire_date_set (QJsonDocument reply, GLib.Variant value) {
    var data = reply.object ().value ("ocs").to_object ().value ("data").to_object ();


    /***********************************************************
    If the reply provides a data back (more REST style)
    they use this date.
    ***********************************************************/
    if (data.value ("expiration").is_"") {
        this.expire_date = QDate.from_string (data.value ("expiration").to_"", "yyyy-MM-dd 00:00:00");
    } else {
        this.expire_date = value.to_date ();
    }
    /* emit */ expire_date_set ();
}

void Link_share.on_name_set (QJsonDocument &, GLib.Variant value) {
    this.name = value.to_"";
    /* emit */ name_set ();
}

void Link_share.on_label_set (QJsonDocument &, GLib.Variant label) {
    if (this.label != label.to_"") {
        this.label = label.to_"";
        /* emit */ label_set ();
    }
}

User_group_share.User_group_share (AccountPointer account,
    const string id,
    const string owner,
    const string owner_display_name,
    const string path,
    const Share_type share_type,
    bool is_password_set,
    const Permissions permissions,
    const unowned<Sharee> share_with,
    const QDate expire_date,
    const string note)
    : Share (account, id, owner, owner_display_name, path, share_type, is_password_set, permissions, share_with)
    , this.note (note)
    , this.expire_date (expire_date) {
    Q_ASSERT (Share.is_share_type_user_group_email_room_or_remote (share_type));
    Q_ASSERT (share_with);
}

void User_group_share.set_note (string note) {
    var job = new Ocs_share_job (this.account);
    connect (job, &Ocs_share_job.share_job_finished, this, &User_group_share.on_note_set);
    connect (job, &Ocs_job.ocs_error, this, &User_group_share.note_set_error);
    job.set_note (get_id (), note);
}

string User_group_share.get_note () {
    return this.note;
}

void User_group_share.on_note_set (QJsonDocument &, GLib.Variant note) {
    this.note = note.to_"";
    /* emit */ note_set ();
}

QDate User_group_share.get_expire_date () {
    return this.expire_date;
}

void User_group_share.set_expire_date (QDate date) {
    if (this.expire_date == date) {
        /* emit */ expire_date_set ();
        return;
    }

    var job = new Ocs_share_job (this.account);
    connect (job, &Ocs_share_job.share_job_finished, this, &User_group_share.on_expire_date_set);
    connect (job, &Ocs_job.ocs_error, this, &User_group_share.on_ocs_error);
    job.set_expire_date (get_id (), date);
}

void User_group_share.on_expire_date_set (QJsonDocument reply, GLib.Variant value) {
    var data = reply.object ().value ("ocs").to_object ().value ("data").to_object ();


    /***********************************************************
    If the reply provides a data back (more REST style)
    they use this date.
    ***********************************************************/
    if (data.value ("expiration").is_"") {
        this.expire_date = QDate.from_string (data.value ("expiration").to_"", "yyyy-MM-dd 00:00:00");
    } else {
        this.expire_date = value.to_date ();
    }
    /* emit */ expire_date_set ();
}

Share_manager.Share_manager (AccountPointer account, GLib.Object parent)
    : GLib.Object (parent)
    , this.account (account) {
}

void Share_manager.create_link_share (string path,
    const string name,
    const string password) {
    var job = new Ocs_share_job (this.account);
    connect (job, &Ocs_share_job.share_job_finished, this, &Share_manager.on_link_share_created);
    connect (job, &Ocs_job.ocs_error, this, &Share_manager.on_ocs_error);
    job.create_link_share (path, name, password);
}

void Share_manager.on_link_share_created (QJsonDocument reply) {
    string message;
    int code = Ocs_share_job.get_json_return_code (reply, message);


    /***********************************************************
    Before we had decent sharing capabilities on the server a 403 "generally"
    meant that a share was password protected
    ***********************************************************/
    if (code == 403) {
        /* emit */ link_share_requires_password (message);
        return;
    }

    //Parse share
    var data = reply.object ().value ("ocs").to_object ().value ("data").to_object ();
    unowned<Link_share> share (parse_link_share (data));

    /* emit */ link_share_created (share);

    update_folder (this.account, share.path ());
}

void Share_manager.create_share (string path,
    const Share.Share_type share_type,
    const string share_with,
    const Share.Permissions desired_permissions,
    const string password) {
    var job = new Ocs_share_job (this.account);
    connect (job, &Ocs_job.ocs_error, this, &Share_manager.on_ocs_error);
    connect (job, &Ocs_share_job.share_job_finished, this,
        [=] (QJsonDocument reply) {
            // Find existing share permissions (if this was shared with us)
            Share.Permissions existing_permissions = Share_permission_default;
            foreach (QJsonValue element, reply.object ()["ocs"].to_object ()["data"].to_array ()) {
                var map = element.to_object ();
                if (map["file_target"] == path)
                    existing_permissions = Share.Permissions (map["permissions"].to_int ());
            }

            // Limit the permissions we request for a share to the ones the item
            // was shared with initially.
            var valid_permissions = desired_permissions;
            if (valid_permissions == Share_permission_default) {
                valid_permissions = existing_permissions;
            }
            if (existing_permissions != Share_permission_default) {
                valid_permissions &= existing_permissions;
            }

            var job = new Ocs_share_job (this.account);
            connect (job, &Ocs_share_job.share_job_finished, this, &Share_manager.on_share_created);
            connect (job, &Ocs_job.ocs_error, this, &Share_manager.on_ocs_error);
            job.create_share (path, share_type, share_with, valid_permissions, password);
        });
    job.get_shared_with_me ();
}

void Share_manager.on_share_created (QJsonDocument reply) {
    //Parse share
    var data = reply.object ().value ("ocs").to_object ().value ("data").to_object ();
    unowned<Share> share (parse_share (data));

    /* emit */ share_created (share);

    update_folder (this.account, share.path ());
}

void Share_manager.fetch_shares (string path) {
    var job = new Ocs_share_job (this.account);
    connect (job, &Ocs_share_job.share_job_finished, this, &Share_manager.on_shares_fetched);
    connect (job, &Ocs_job.ocs_error, this, &Share_manager.on_ocs_error);
    job.on_get_shares (path);
}

void Share_manager.on_shares_fetched (QJsonDocument reply) {
    var tmp_shares = reply.object ().value ("ocs").to_object ().value ("data").to_array ();
    const string version_string = this.account.server_version ();
    GLib.debug (lc_sharing) << version_string << "Fetched" << tmp_shares.count () << "shares";

    GLib.List<unowned<Share>> shares;

    foreach (var share, tmp_shares) {
        var data = share.to_object ();

        var share_type = data.value ("share_type").to_int ();

        unowned<Share> new_share;

        if (share_type == Share.Type_link) {
            new_share = parse_link_share (data);
        } else if (Share.is_share_type_user_group_email_room_or_remote (static_cast <Share.Share_type> (share_type))) {
            new_share = parse_user_group_share (data);
        } else {
            new_share = parse_share (data);
        }

        shares.append (unowned<Share> (new_share));
    }

    GLib.debug (lc_sharing) << "Sending " << shares.count () << "shares";
    /* emit */ shares_fetched (shares);
}

unowned<User_group_share> Share_manager.parse_user_group_share (QJsonObject data) {
    unowned<Sharee> sharee (new Sharee (data.value ("share_with").to_"",
        data.value ("share_with_displayname").to_"",
        static_cast<Sharee.Type> (data.value ("share_type").to_int ())));

    QDate expire_date;
    if (data.value ("expiration").is_"") {
        expire_date = QDate.from_string (data.value ("expiration").to_"", "yyyy-MM-dd 00:00:00");
    }

    string note;
    if (data.value ("note").is_"") {
        note = data.value ("note").to_"";
    }

    return unowned<User_group_share> (new User_group_share (this.account,
        data.value ("id").to_variant ().to_"", // "id" used to be an integer, support both
        data.value ("uid_owner").to_variant ().to_"",
        data.value ("displayname_owner").to_variant ().to_"",
        data.value ("path").to_"",
        static_cast<Share.Share_type> (data.value ("share_type").to_int ()),
        !data.value ("password").to_"".is_empty (),
        static_cast<Share.Permissions> (data.value ("permissions").to_int ()),
        sharee,
        expire_date,
        note));
}

unowned<Link_share> Share_manager.parse_link_share (QJsonObject data) {
    GLib.Uri url;

    // From own_cloud server 8.2 the url field is always set for public shares
    if (data.contains ("url")) {
        url = GLib.Uri (data.value ("url").to_"");
    } else if (this.account.server_version_int () >= Account.make_server_version (8, 0, 0)) {
        // From own_cloud server version 8 on, a different share link scheme is used.
        url = GLib.Uri (Utility.concat_url_path (this.account.url (), QLatin1String ("index.php/s/") + data.value ("token").to_"")).to_"";
    } else {
        QUrlQuery query_args;
        query_args.add_query_item (QLatin1String ("service"), QLatin1String ("files"));
        query_args.add_query_item (QLatin1String ("t"), data.value ("token").to_"");
        url = GLib.Uri (Utility.concat_url_path (this.account.url (), QLatin1String ("public.php"), query_args).to_"");
    }

    QDate expire_date;
    if (data.value ("expiration").is_"") {
        expire_date = QDate.from_string (data.value ("expiration").to_"", "yyyy-MM-dd 00:00:00");
    }

    string note;
    if (data.value ("note").is_"") {
        note = data.value ("note").to_"";
    }

    return unowned<Link_share> (new Link_share (this.account,
        data.value ("id").to_variant ().to_"", // "id" used to be an integer, support both
        data.value ("uid_owner").to_"",
        data.value ("displayname_owner").to_"",
        data.value ("path").to_"",
        data.value ("name").to_"",
        data.value ("token").to_"",
        (Share.Permissions)data.value ("permissions").to_int (),
        data.value ("share_with").is_"", // has password?
        url,
        expire_date,
        note,
        data.value ("label").to_""));
}

unowned<Share> Share_manager.parse_share (QJsonObject data) {
    unowned<Sharee> sharee (new Sharee (data.value ("share_with").to_"",
        data.value ("share_with_displayname").to_"",
        (Sharee.Type)data.value ("share_type").to_int ()));

    return unowned<Share> (new Share (this.account,
        data.value ("id").to_variant ().to_"", // "id" used to be an integer, support both
        data.value ("uid_owner").to_variant ().to_"",
        data.value ("displayname_owner").to_variant ().to_"",
        data.value ("path").to_"",
        (Share.Share_type)data.value ("share_type").to_int (),
        !data.value ("password").to_"".is_empty (),
        (Share.Permissions)data.value ("permissions").to_int (),
        sharee));
}

void Share_manager.on_ocs_error (int status_code, string message) {
    /* emit */ server_error (status_code, message);
}
}
