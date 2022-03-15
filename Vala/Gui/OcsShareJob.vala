/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QBuffer>
//  #include <QJsonDocument>
//  #include <QPair>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OcsShareJob class
@ingroup gui

Handle talking to the OCS Share API.
For creation, deletion and modification of shares.
***********************************************************/
public class OcsShareJob : OcsJob {

    /***********************************************************
    ***********************************************************/
    private GLib.Variant value;


    /***********************************************************
    Result of the OCS request

    The value parameter is only set if this was a put request.
    e.g. if we set the password to 'foo' the GLib.Variant will
    hold a string with 'foo'. This is needed so we can update
    the share objects properly.

    @param reply The reply
    @param value To what did we set a variable (if we set any).
    ***********************************************************/
    signal void share_job_finished (QJsonDocument reply, GLib.Variant value);


    /***********************************************************
    Constructor for new shares or listing of shares
    ***********************************************************/
    public OcsShareJob (unowned Account account) {
        base (account);
        path ("ocs/v2.php/apps/files_sharing/api/v1/shares");
        connect (
            this,
            OcsJob.signal_job_finished,
            this,
            OcsShareJob.on_signal_job_done);
    }


    /***********************************************************
    Get all the shares

    @param path Path to request shares for (default all shares)
    ***********************************************************/
    public void on_signal_get_shares (string path = "") {
        verb ("GET");

        add_param (string.from_latin1 ("path"), path);
        add_param (string.from_latin1 ("reshares"), string ("true"));
        add_pass_status_code (404);

        on_signal_start ();
    }


    /***********************************************************
    Delete the current Share
    ***********************************************************/
    public void delete_share (string share_id) {
        append_path (share_id);
        verb ("DELETE");

        on_signal_start ();
    }


    /***********************************************************
    Set the expiration date of a share

    @param date The expire date, if this date is invalid the
    expire date will be removed
    ***********************************************************/
    public void expire_date (string share_id, QDate date) {
        append_path (share_id);
        verb ("PUT");

        if (date.is_valid ()) {
            add_param (string.from_latin1 ("expire_date"), date.to_string ("yyyy-MM-dd"));
        } else {
            add_param (string.from_latin1 ("expire_date"), "");
        }
        this.value = date;

        on_signal_start ();
    }


    /***********************************************************
    Set note a share

    @param note The note to a share, if the note is empty the
    share will be removed
    ***********************************************************/
    public void note (string share_id, string note) {
        append_path (share_id);
        verb ("PUT");

        add_param ("note", note);
        this.value = note;

        on_signal_start ();
    }


    /***********************************************************
    Set the password of a share

    @param password The password of the share, if the password
    is empty the share will be removed
    ***********************************************************/
    public void password (string share_id, string password) {
        append_path (share_id);
        verb ("PUT");

        add_param (string.from_latin1 ("password"), password);
        this.value = password;

        on_signal_start ();
    }


    /***********************************************************
    Set the share to be public upload

    @param public_upload Set or remove public upload
    ***********************************************************/
    public void public_upload (string share_id, bool public_upload) {
        append_path (share_id);
        verb ("PUT");

        const string value = public_upload ? "true": "false";
        add_param ("public_upload", value);
        this.value = public_upload;

        on_signal_start ();
    }


    /***********************************************************
    Change the name of a share
    ***********************************************************/
    public void name (string share_id, string name) {
        append_path (share_id);
        verb ("PUT");
        add_param ("name", name);
        this.value = name;

        on_signal_start ();
    }


    /***********************************************************
    Set the permissions

    @param permissions
    ***********************************************************/
    public void permissions (
        string share_id,
        Share.Permissions permissions) {
        append_path (share_id);
        verb ("PUT");

        add_param ("permissions", permissions.to_int ());
        this.value = (int)permissions;

        on_signal_start ();
    }


    /***********************************************************
    Set share link label
    ***********************************************************/
    public void label (string share_id, string label) {
        append_path (share_id);
        verb ("PUT");

        add_param ("label", label);
        this.value = label;

        on_signal_start ();
    }


    /***********************************************************
    Create a new link share

    @param path The path of the file/folder to share
    @param password Optionally a password for the share
    ***********************************************************/
    public void create_link_share (
        string path,
        string name,
        string password) {
        verb ("POST");

        add_param (string.from_latin1 ("path"), path);
        add_param (string.from_latin1 ("share_type"), string.number (Share.Type.LINK));

        if (!name == "") {
            add_param (string.from_latin1 ("name"), name);
        }
        if (!password == "") {
            add_param (string.from_latin1 ("password"), password);
        }

        add_pass_status_code (403);

        on_signal_start ();
    }


    /***********************************************************
    Create a new share

    @param path The path of the file/folder to share
    @param share_type The type of share (user/group/link/fed
    @param share_with The uid/gid/federated identifier to share wit
    @param permissions The permissions the share will have
    @param password The password to protect the share with
    ***********************************************************/
    public void create_share (
        string path,
        Share.Type share_type,
        string share_with = "",
        Share.Permissions permissions = SharePermissionRead,
        string password = "") {
        //  Q_UNUSED (permissions)
        verb ("POST");

        add_param ("path", path);
        add_param ("share_type", share_type.to_int ());
        add_param ("share_with", share_with);

        if (!password == "") {
            add_param ("password", password);
        }

        on_signal_start ();
    }


    /***********************************************************
    Returns information on the items shared with the current user.
    ***********************************************************/
    public void shared_with_me () {
        verb ("GET");
        add_param ("shared_with_me", "true");
        on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_job_done (QJsonDocument reply) {
        /* emit */ share_job_finished (reply, this.value);
    }

} // class OcsShareJob

} // namespace Ui
} // namespace Occ
    