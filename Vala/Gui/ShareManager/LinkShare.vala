/***********************************************************
@author Roeland Jago Douma <rullzer@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
A Link share is just like a regular share but then slightly different.
There are several methods in the API that either work differently for
link shares or are only available to link shares.
***********************************************************/
public class LinkShare : Share {

    /***********************************************************
    ***********************************************************/
    public string name {
        /***********************************************************
        Returns the name of the link share. Can be empty.
        ***********************************************************/
        public get {
            return this.name;
        }
        /***********************************************************
        Set the name of the link share.

        Emits either signal_name_set () or on_signal_server_error ().
        ***********************************************************/
        public set {
            create_share_job (LinkShare.on_signal_name_set).name (identifier, value);
        }
    }


    public string token {
        /***********************************************************
        Returns the token of the link share.
        ***********************************************************/
        public get {
            return this.token;
        }
        private set {
            this.token = value;
        }
    }


    public string note {
        /***********************************************************
        Returns the note of the link share.
        ***********************************************************/
        public get {
            return this.note;
        }
        /***********************************************************
        Set the note of the link share.
        ***********************************************************/
        public set {
            create_share_job (LinkShare.on_signal_link_share_note_set).note (identifier, value);
        }
    }


    public GLib.Date expire_date {
        /***********************************************************
        Get the expiration date
        ***********************************************************/
        public get {
            return this.expire_date;
        }
        /***********************************************************
        Set the expiration date

        On on_signal_success the signal_expire_date_set signal is emitted
        In case of a server error the on_signal_server_error signal is emitted.
        ***********************************************************/
        public set {
            create_share_job (LinkShare.on_signal_expire_date_set).expire_date (identifier, value);
        }
    }


    public GLib.Uri share_link {
        /***********************************************************
        Get the share link
        ***********************************************************/
        public get {
            return this.share_link;
        }
        private set {
            this.share_link = value;
        }
    }


    public string label {
        /***********************************************************
        Returns the label of the link share.
        ***********************************************************/
        public get {
            return this.label;
        }
        /***********************************************************
        Set the label of the share link.
        ***********************************************************/
        public set {
            create_share_job (LinkShare.on_signal_link_share_label_set).label (identifier, value);
        }
    }


    internal signal void signal_expire_date_set ();
    internal signal void signal_note_set ();
    internal signal void signal_name_set ();
    internal signal void signal_label_set ();


    /***********************************************************
    ***********************************************************/
    public LinkShare (
        LibSync.Account account,
        string identifier,
        string owner_uid,
        string owner_display_name,
        string path,
        string name,
        string token,
        Permissions permissions,
        bool password_is_set,
        GLib.Uri url,
        GLib.Date expire_date,
        string note,
        string label) {
        base (account, identifier, owner_uid, owner_display_name, path, Share.Type.LINK, password_is_set, permissions);
        this.name = name;
        this.token = token;
        this.note = note;
        this.expire_date = expire_date;
        this.url = url;
        this.label = label;
    }


    /***********************************************************
    The share's link for direct downloading.
    ***********************************************************/
    public GLib.Uri direct_download_link () {
        GLib.Uri url = this.share_link;
        url.path (url.path + "/download");
        return url;
    }


    /***********************************************************
    Get the public_upload status of this share
    ***********************************************************/
    public bool public_upload () {
        return this.permissions & Share_permission_create;
    }


    /***********************************************************
    Whether directory listings are available (READ permission)
    ***********************************************************/
    public bool show_file_listing () {
        return this.permissions & SharePermissionRead;
    }


    delegate void OnSignalOcsShareJobFinished


    /***********************************************************
    Create OcsShareJob and connect to signal/slots
    ***********************************************************/
    public OcsShareJob create_share_job (OnSignalOcsShareJobFinished on_signal_ocs_share_job_finished) {
        var ocs_share_job = new OcsShareJob (this.account);
        ocs_share_job.signal_share_job_finished.connect (
            this.on_signal_ocs_share_job_finished
        );
        ocs_share_job.signal_error.connect (
            this.on_signal_ocs_share_job_error
        );
        return ocs_share_job;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_link_share_note_set (GLib.JsonDocument reply, GLib.Variant value) {
        this.note = note.to_string ();
        signal_note_set ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_expire_date_set (GLib.JsonDocument reply, GLib.Variant value) {
        var data = reply.object ().value ("ocs").to_object ().value ("data").to_object ();

        /***********************************************************
        If the reply provides a data back (more REST style)
        they use this date.
        ***********************************************************/
        if (data.value ("expiration").is_string ()) {
            this.expire_date = GLib.Date.from_string (data.value ("expiration").to_string (), "yyyy-MM-dd 00:00:00");
        } else {
            this.expire_date = value.to_date ();
        }
        signal_expire_date_set ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_name_set (GLib.JsonDocument reply, GLib.Variant value) {
        this.name = value.to_string ();
        signal_name_set ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_link_share_label_set (GLib.JsonDocument reply, GLib.Variant value) {
        if (this.label != label.to_string ()) {
            this.label = label.to_string ();
            signal_label_set ();
        }
    }

} // class LinkShare

} // namespace Ui
} // namespace Occ
