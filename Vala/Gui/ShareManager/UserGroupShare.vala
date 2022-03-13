/***********************************************************
Copyright (C) by Roeland Jago Douma <rullzer@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

class UserGroupShare : Share {

    string note {
        public get {
            return this.note;
        }
        public set {
            var ocs_share_job = new OcsShareJob (this.account);
            connect (
                ocs_share_job,
                OcsShareJob.share_job_finished,
                this,
                UserGroupShare.on_signal_note_set
            );
            connect (
                ocs_share_job,
                OcsJob.ocs_error,
                this,
                UserGroupShare.signal_note_error
            );
            ocs_share_job.note (identifier (), value);
        }
    }


    QDate expire_date {
        public get {
            return this.expire_date;
        }
        public set {
            if (this.expire_date == value) {
                /* emit */ signal_expire_date_set ();
                return;
            }

            var ocs_share_job = new OcsShareJob (this.account);
            connect (ocs_share_job, OcsShareJob.share_job_finished, this, UserGroupShare.on_signal_expire_date_set);
            connect (ocs_share_job, OcsJob.ocs_error, this, UserGroupShare.on_signal_ocs_error);
            ocs_share_job.expire_date (identifier (), value);
        }
    }


    signal void signal_note_set ();
    signal void signal_note_error ();
    signal void signal_expire_date_set ();


    /***********************************************************
    ***********************************************************/
    public UserGroupShare (
        unowned Account account,
        string identifier,
        string owner,
        string owner_display_name,
        string path,
        Share.Type share_type,
        bool is_password_set,
        Permissions permissions,
        unowned Sharee share_with,
        QDate expire_date,
        string note) {
        base (account, identifier, owner, owner_display_name, path, share_type, is_password_set, permissions, share_with);
        this.note = note;
        this.expire_date = expire_date;
        //  Q_ASSERT (Share.is_share_type_user_group_email_room_or_remote (share_type));
        //  Q_ASSERT (share_with);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_note_set (QJsonDocument reply, GLib.Variant note) {
        this.note = note.to_string ();
        /* emit */ signal_note_set ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_expire_date_set (QJsonDocument reply, GLib.Variant value) {
        var data = reply.object ().value ("ocs").to_object ().value ("data").to_object ();

        /***********************************************************
        If the reply provides a data back (more REST style)
        they use this date.
        ***********************************************************/
        if (data.value ("expiration").is_string ()) {
            this.expire_date = QDate.from_string (data.value ("expiration").to_string (), "yyyy-MM-dd 00:00:00");
        } else {
            this.expire_date = value.to_date ();
        }
        /* emit */ signal_expire_date_set ();
    }

} // class UserGroupShare

} // namespace Ui
} // namespace Occ
