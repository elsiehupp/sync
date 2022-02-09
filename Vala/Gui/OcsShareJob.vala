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
@brief The Ocs_share_job class
@ingroup gui

Handle talking to the OCS Share API.
For creation, deletion and modification of shares.
***********************************************************/
class Ocs_share_job : Ocs_job {

    /***********************************************************
    Constructor for new shares or listing of shares
    ***********************************************************/
    public Ocs_share_job (AccountPointer account);


    /***********************************************************
    Get all the shares

    @param path Path to request shares for (default all shares)
    ***********************************************************/
    public void on_signal_get_shares (string path = "");


    /***********************************************************
    Delete the current Share
    ***********************************************************/
    public void delete_share (string share_id);


    /***********************************************************
    Set the expiration date of a share

    @param date The expire date, if this date is invalid the expire date
    will be removed
    ***********************************************************/
    public void expire_date (string share_id, QDate date);

	 /***********************************************************
    Set note a share

    @param note The note to a share, if the note is empty the
    share will be removed
    ***********************************************************/
    public void note (string share_id, string note);


    /***********************************************************
    Set the password of a share

    @param password The password of the share, if the password is empty the
    share will be removed
    ***********************************************************/
    public void password (string share_id, string password);


    /***********************************************************
    Set the share to be public upload

    @param public_upload Set or remove public upload
    ***********************************************************/
    public void public_upload (string share_id, bool public_upload);


    /***********************************************************
    Change the name of a share
    ***********************************************************/
    public void name (string share_id, string name);


    /***********************************************************
    Set the permissions

    @param permissions
    ***********************************************************/
    public void permissions (string share_id,
        const Share.Permissions permissions);


    /***********************************************************
    Set share link label
    ***********************************************************/
    public void label (string share_id, string label);


    /***********************************************************
    Create a new link share

    @param path The path of the file/folder to share
    @param password Optionally a password for the share
    ***********************************************************/
    public void create_link_share (string path, string name,
        const string password);


    /***********************************************************
    Create a new share

    @param path The path of the file/folder to share
    @param share_type The type of share (user/group/link/fed
    @param share_with The uid/gid/federated identifier to share wit
    @param permissions The permissions the share will have
    @param password The password to protect the share with
    ***********************************************************/
    public void create_share (string path,
        const Share.Share_type share_type,
        const string share_with = "",
        const Share.Permissions permissions = Share_permission_read,
        const string password = "");


    /***********************************************************
    Returns information on the items shared with the current user.
    ***********************************************************/
    public void get_shared_with_me ();

signals:
    /***********************************************************
    Result of the OCS request
    The value parameter is only set if this was a put request.
    e.g. if we set the password to 'foo' the GLib.Variant will hold a string with 'foo'.
    This is needed so we can update the share objects properly

    @param reply The reply
    @param value To what did we set a variable (if we set any).
    ***********************************************************/
    void share_job_finished (QJsonDocument reply, GLib.Variant value);


    /***********************************************************
    ***********************************************************/
    private void on_signal_job_done (QJsonDocument reply);

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.Variant this.value;
}


    Ocs_share_job.Ocs_share_job (AccountPointer account)
        : Ocs_job (account) {
        path ("ocs/v2.php/apps/files_sharing/api/v1/shares");
        connect (this, &Ocs_job.job_finished, this, &Ocs_share_job.on_signal_job_done);
    }

    void Ocs_share_job.on_signal_get_shares (string path) {
        verb ("GET");

        add_param (string.from_latin1 ("path"), path);
        add_param (string.from_latin1 ("reshares"), string ("true"));
        add_pass_status_code (404);

        on_signal_start ();
    }

    void Ocs_share_job.delete_share (string share_id) {
        append_path (share_id);
        verb ("DELETE");

        on_signal_start ();
    }

    void Ocs_share_job.expire_date (string share_id, QDate date) {
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

    void Ocs_share_job.password (string share_id, string password) {
        append_path (share_id);
        verb ("PUT");

        add_param (string.from_latin1 ("password"), password);
        this.value = password;

        on_signal_start ();
    }

    void Ocs_share_job.note (string share_id, string note) {
        append_path (share_id);
        verb ("PUT");

        add_param (string.from_latin1 ("note"), note);
        this.value = note;

        on_signal_start ();
    }

    void Ocs_share_job.public_upload (string share_id, bool public_upload) {
        append_path (share_id);
        verb ("PUT");

        const string value = string.from_latin1 (public_upload ? "true" : "false");
        add_param (string.from_latin1 ("public_upload"), value);
        this.value = public_upload;

        on_signal_start ();
    }

    void Ocs_share_job.name (string share_id, string name) {
        append_path (share_id);
        verb ("PUT");
        add_param (string.from_latin1 ("name"), name);
        this.value = name;

        on_signal_start ();
    }

    void Ocs_share_job.permissions (string share_id,
        const Share.Permissions permissions) {
        append_path (share_id);
        verb ("PUT");

        add_param (string.from_latin1 ("permissions"), string.number (permissions));
        this.value = (int)permissions;

        on_signal_start ();
    }

    void Ocs_share_job.label (string share_id, string label) {
        append_path (share_id);
        verb ("PUT");

        add_param (QStringLiteral ("label"), label);
        this.value = label;

        on_signal_start ();
    }

    void Ocs_share_job.create_link_share (string path,
        const string name,
        const string password) {
        verb ("POST");

        add_param (string.from_latin1 ("path"), path);
        add_param (string.from_latin1 ("share_type"), string.number (Share.Type_link));

        if (!name.is_empty ()) {
            add_param (string.from_latin1 ("name"), name);
        }
        if (!password.is_empty ()) {
            add_param (string.from_latin1 ("password"), password);
        }

        add_pass_status_code (403);

        on_signal_start ();
    }

    void Ocs_share_job.create_share (string path,
        const Share.Share_type share_type,
        const string share_with,
        const Share.Permissions permissions,
        const string password) {
        //  Q_UNUSED (permissions)
        verb ("POST");

        add_param (string.from_latin1 ("path"), path);
        add_param (string.from_latin1 ("share_type"), string.number (share_type));
        add_param (string.from_latin1 ("share_with"), share_with);

        if (!password.is_empty ()) {
            add_param (string.from_latin1 ("password"), password);
        }

        on_signal_start ();
    }

    void Ocs_share_job.get_shared_with_me () {
        verb ("GET");
        add_param (QLatin1String ("shared_with_me"), QLatin1String ("true"));
        on_signal_start ();
    }

    void Ocs_share_job.on_signal_job_done (QJsonDocument reply) {
        /* emit */ share_job_finished (reply, this.value);
    }
    }
    