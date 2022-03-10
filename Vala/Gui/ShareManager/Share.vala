/***********************************************************
Copyright (C) by Roeland Jago Douma <rullzer@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

class Share : GLib.Object {

    /***********************************************************
    Possible share types
    Need to be in sync with Sharee.Type
    ***********************************************************/
    public enum ShareType {
        Type_user = Sharee.User,
        Type_group = Sharee.Group,
        Type_link = 3,
        Type_email = Sharee.Email,
        Type_remote = Sharee.Federated,
        Type_circle = Sharee.Circle,
        Type_room = Sharee.Room
    }


    /***********************************************************
    ***********************************************************/
    public using Permissions = SharePermissions;


    /***********************************************************
    Constructor for shares
    ***********************************************************/
    public Share (AccountPointer account,
        const string identifier,
        const string owner,
        const string owner_display_name,
        const string path,
        const ShareType share_type,
        bool is_password_set = false,
        const Permissions permissions = Share_permission_default,
        const unowned<Sharee> share_with = unowned<Sharee> (null));


    /***********************************************************
    The account the share is defined on.
    ***********************************************************/
    public AccountPointer account ();

    /***********************************************************
    ***********************************************************/
    public string path ();


    /***********************************************************
    Get the identifier
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
    public ShareType get_share_type ();


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

    On on_signal_success the permissions_set signal is emitted
    In case of a server error the on_signal_server_error signal is emitted.
    ***********************************************************/
    public void permissions (Permissions permissions);


    /***********************************************************
    Set the password for remote share

    On on_signal_success the password_set signal is emitted
    In case of a server error the password_error signal is emitted.
    ***********************************************************/
    public void password (string password);

    /***********************************************************
    ***********************************************************/
    public bool is_password_set ();


    /***********************************************************
    Deletes a share

    On on_signal_success the share_deleted signal is emitted
    In case of a server error the on_signal_server_error signal is emitted.
    ***********************************************************/
    public void delete_share ();


    /***********************************************************
    Is it a share with a user or group (local or remote)
    ***********************************************************/
    public static bool is_share_type_user_group_email_room_or_remote (ShareType type);

signals:
    void permissions_set ();
    void share_deleted ();
    void on_signal_server_error (int code, string message);
    void password_set ();
    void password_error (int status_code, string message);


    protected AccountPointer this.account;
    protected string this.identifier;
    protected string this.uidowner;
    protected string this.owner_display_name;
    protected string this.path;
    protected ShareType this.share_type;
    protected bool this.is_password_set;
    protected Permissions this.permissions;
    protected unowned<Sharee> this.share_with;

protected slots:
    void on_signal_ocs_error (int status_code, string message);
    void on_signal_password_set (QJsonDocument &, GLib.Variant value);
    void on_signal_password_error (int status_code, string message);


    /***********************************************************
    ***********************************************************/
    private void on_signal_deleted ();
    private void on_signal_permissions_set (QJsonDocument &, GLib.Variant value);
}





Share.Share (AccountPointer account,
    const string identifier,
    const string uidowner,
    const string owner_display_name,
    const string path,
    const ShareType share_type,
    bool is_password_set,
    const Permissions permissions,
    const unowned<Sharee> share_with)
    : this.account (account)
    this.identifier (identifier)
    this.uidowner (uidowner)
    this.owner_display_name (owner_display_name)
    this.path (path)
    this.share_type (share_type)
    this.is_password_set (is_password_set)
    this.permissions (permissions)
    this.share_with (share_with) {
}

AccountPointer Share.account () {
    return this.account;
}

string Share.path () {
    return this.path;
}

string Share.get_id () {
    return this.identifier;
}

string Share.get_uid_owner () {
    return this.uidowner;
}

string Share.get_owner_display_name () {
    return this.owner_display_name;
}

Share.ShareType Share.get_share_type () {
    return this.share_type;
}

unowned<Sharee> Share.get_share_with () {
    return this.share_with;
}

void Share.password (string password) {
    var * const job = new OcsShareJob (this.account);
    connect (job, &OcsShareJob.share_job_finished, this, &Share.on_signal_password_set);
    connect (job, &OcsJob.ocs_error, this, &Share.on_signal_password_error);
    job.password (get_id (), password);
}

bool Share.is_password_set () {
    return this.is_password_set;
}

void Share.permissions (Permissions permissions) {
    var job = new OcsShareJob (this.account);
    connect (job, &OcsShareJob.share_job_finished, this, &Share.on_signal_permissions_set);
    connect (job, &OcsJob.ocs_error, this, &Share.on_signal_ocs_error);
    job.permissions (get_id (), permissions);
}

void Share.on_signal_permissions_set (QJsonDocument &, GLib.Variant value) {
    this.permissions = (Permissions)value.to_int ();
    /* emit */ permissions_set ();
}

Share.Permissions Share.get_permissions () {
    return this.permissions;
}

void Share.delete_share () {
    var job = new OcsShareJob (this.account);
    connect (job, &OcsShareJob.share_job_finished, this, &Share.on_signal_deleted);
    connect (job, &OcsJob.ocs_error, this, &Share.on_signal_ocs_error);
    job.delete_share (get_id ());
}

bool Share.is_share_type_user_group_email_room_or_remote (ShareType type) {
    return (type == Share.Type_user || type == Share.Type_group || type == Share.Type_email || type == Share.Type_room
        || type == Share.Type_remote);
}

void Share.on_signal_deleted () {
    update_folder (this.account, this.path);
    /* emit */ share_deleted ();
}

void Share.on_signal_ocs_error (int status_code, string message) {
    /* emit */ server_error (status_code, message);
}

void Share.on_signal_password_set (QJsonDocument &, GLib.Variant value) {
    this.is_password_set = !value.to_string ().is_empty ();
    /* emit */ password_set ();
}

void Share.on_signal_password_error (int status_code, string message) {
    /* emit */ password_error (status_code, message);
}