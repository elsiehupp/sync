/***********************************************************
@author Roeland Jago Douma <rullzer@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class Share { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    public class Permissions : Share.Permissions {}

    /***********************************************************
    Possible share types
    Need to be in sync with Sharee.Type
    ***********************************************************/
    public enum Type {
        USER = Sharee.Type.USER,
        GROUP = Sharee.Type.GROUP,
        LINK = 3,
        EMAIL = Sharee.Type.EMAIL,
        REMOTE = Sharee.Type.FEDERATED,
        CIRCLE = Sharee.Type.CIRCLE,
        ROOM = Sharee.Type.ROOM
    }

    /***********************************************************
    The account the share is defined on.
    ***********************************************************/
    public LibSync.Account account { public get; protected set; }

    public string identifier { public get; protected set; }
    public string owner_uid { public get; protected set; }
    public string owner_display_name { public get; protected set; }
    public string path { public get; protected set; }
    public Share.Type share_type { public get; protected set; }
    public bool password_is_set { public get; protected set; }
    public Sharee share_with { public get; protected set; }

    public Permissions permissions {
        /***********************************************************
        Get permissions
        ***********************************************************/
        public get {
            return this.permissions;
        }
        /***********************************************************
        Set the permissions of a share

        On on_signal_success the signal_permissions_set signal is emitted
        In case of a server error the on_signal_server_error signal is emitted.
        ***********************************************************/
        public set {
            OcsShareJob ocs_share_job = new OcsShareJob (this.account);
            ocs_share_job.signal_finished.connect (
                this.on_signal_permissions_set
            );
            ocs_share_job.signal_error.connect (
                this.on_signal_ocs_share_job_error
            );
            ocs_share_job.permissions (identifier, value);
        }
    }

    internal signal void signal_permissions_set ();
    internal signal void signal_share_deleted ();
    internal signal void signal_server_error (int code, string message);
    internal signal void signal_password_set ();
    internal signal void signal_password_error (int status_code, string message);


    /***********************************************************
    Constructor for shares
    ***********************************************************/
    public Share (
        LibSync.Account account,
        string identifier,
        string owner,
        string owner_display_name,
        string path,
        Share.Type share_type,
        bool password_is_set = false,
        Permissions permissions = SharePermission.DEFAULT,
        Sharee share_with = new Sharee (null)
    ) {
        //  this.account = account;
        //  this.identifier = identifier;
        //  this.owner_uid = owner_uid;
        //  this.owner_display_name = owner_display_name;
        //  this.path = path;
        //  this.share_type = share_type;
        //  this.password_is_set = password_is_set;
        //  this.permissions = permissions;
        //  this.share_with = share_with;
    }


    /***********************************************************
    Set the password for remote share

    On on_signal_success the signal_password_set signal is emitted
    In case of a server error the signal_password_error signal is emitted.
    ***********************************************************/
    public void password (string password) {
        //  OcsShareJob ocs_share_job = new OcsShareJob (this.account);
        //  ocs_share_job.signal_finished.connect (
        //      this.on_signal_password_set
        //  );
        //  ocs_share_job.signal_error.connect (
        //      this.on_signal_password_error
        //  );
        //  ocs_share_job.password (identifier, password);
    }


    /***********************************************************
    Deletes a share

    On on_signal_success the signal_share_deleted signal is emitted
    In case of a server error the on_signal_server_error signal is emitted.
    ***********************************************************/
    public void delete_share () {
        //  OcsShareJob ocs_share_job = new OcsShareJob (this.account);
        //  ocs_share_job.signal_finished.connect (
        //      this.on_signal_deleted
        //  );
        //  ocs_share_job.signal_error.connect (
        //      this.on_signal_ocs_share_job_error
        //  );
        //  ocs_share_job.delete_share (identifier);
    }


    /***********************************************************
    Is it a share with a user or group (local or remote)
    ***********************************************************/
    public static bool is_share_type_user_group_email_room_or_remote (Share.Type type) {
        //  return (type == Share.Type.USER || type == Share.Type.GROUP || type == Share.Type.EMAIL || type == Share.Type.ROOM
        //      || type == Share.Type.REMOTE);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_ocs_share_job_error (int status_code, string message) {
        //  signal_server_error (status_code, message);
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_password_set (GLib.JsonDocument reply, GLib.Variant value) {
        //  this.password_is_set = !value.to_string () = "";
        //  signal_password_set ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_password_error (int status_code, string message) {
        //  signal_password_error (status_code, message);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_deleted () {
        //  update_folder (this.account, this.path);
        //  signal_share_deleted ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_permissions_set (GLib.JsonDocument reply, GLib.Variant value) {
        //  this.permissions = (Permissions)value.to_int ();
        //  signal_permissions_set ();
    }

} // class Share

} // namespace Ui
} // namespace Occ
