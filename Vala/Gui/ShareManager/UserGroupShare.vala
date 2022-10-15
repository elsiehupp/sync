/***********************************************************
@author Roeland Jago Douma <rullzer@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class UserGroupShare : Share {

    public string note {
        public get {
            return this.note;
        }
        public set {
            var ocs_share_job = new OcsShareJob (this.account);
            ocs_share_job.signal_finished.connect (
                this.on_signal_link_share_note_set
            );
            ocs_share_job.signal_error.connect (
                this.signal_note_error
            );
            ocs_share_job.note (identifier, value);
        }
    }


    public GLib.Date expire_date {
        public get {
            return this.expire_date;
        }
        public set {
            if (this.expire_date == value) {
                signal_expire_date_set ();
                return;
            }

            var ocs_share_job = new OcsShareJob (this.account);
            ocs_share_job.signal_finished.connect (
                this.on_signal_expire_date_set
            );
            ocs_share_job.signal_error.connect (
                this.on_signal_ocs_error
            );
            ocs_share_job.expire_date (identifier, value);
        }
    }


    internal signal void signal_note_set ();
    internal signal void signal_note_error ();
    internal signal void signal_expire_date_set ();


    /***********************************************************
    ***********************************************************/
    public UserGroupShare (
        LibSync.Account account,
        string identifier,
        string owner,
        string owner_display_name,
        string path,
        Share.Type share_type,
        bool password_is_set,
        Permissions permissions,
        unowned Sharee share_with,
        GLib.Date expire_date,
        string note
    ) {
        //  base (account, identifier, owner, owner_display_name, path, share_type, password_is_set, permissions, share_with);
        //  this.note = note;
        //  this.expire_date = expire_date;
        //  //  GLib.assert_true (Share.is_share_type_user_group_email_room_or_remote (share_type));
        //  //  GLib.assert_true (share_with);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_link_share_note_set (GLib.JsonDocument reply, GLib.Variant note) {
        //  this.note = note.to_string ();
        //  signal_note_set ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_expire_date_set (GLib.JsonDocument reply, GLib.Variant value) {
        //  var data = reply.object ().value ("ocs").to_object ().value ("data").to_object ();

        //  /***********************************************************
        //  If the reply provides a data back (more REST style)
        //  they use this date.
        //  ***********************************************************/
        //  if (data.value ("expiration").is_string ()) {
        //      this.expire_date = GLib.Date.from_string (data.value ("expiration").to_string (), "yyyy-MM-dd 00:00:00");
        //  } else {
        //      this.expire_date = value.to_date ();
        //  }
        //  signal_expire_date_set ();
    }

} // class UserGroupShare

} // namespace Ui
} // namespace Occ
