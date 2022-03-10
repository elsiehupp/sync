/***********************************************************
Copyright (C) by Roeland Jago Douma <rullzer@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

class User_group_share : Share {

    /***********************************************************
    ***********************************************************/
    public User_group_share (AccountPointer account,
        const string identifier,
        const string owner,
        const string owner_display_name,
        const string path,
        const ShareType share_type,
        bool is_password_set,
        const Permissions permissions,
        const unowned<Sharee> share_with,
        const QDate expire_date,
        const string note);

    /***********************************************************
    ***********************************************************/
    public void note (string note);

    /***********************************************************
    ***********************************************************/
    public string get_note ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_note_set (QJsonDocument &, GLib.Variant note);

    /***********************************************************
    ***********************************************************/
    public void expire_date (QDate date);

    /***********************************************************
    ***********************************************************/
    public QDate get_expire_date ();

    /***********************************************************
    ***********************************************************/
    public void on_signal_expire_date_set (QJsonDocument reply, GLib.Variant value);

signals:
    void note_set ();
    void note_error ();
    void expire_date_set ();


    /***********************************************************
    ***********************************************************/
    private string this.note;
    private QDate this.expire_date;
}







User_group_share.User_group_share (AccountPointer account,
    const string identifier,
    const string owner,
    const string owner_display_name,
    const string path,
    const ShareType share_type,
    bool is_password_set,
    const Permissions permissions,
    const unowned<Sharee> share_with,
    const QDate expire_date,
    const string note)
    : Share (account, identifier, owner, owner_display_name, path, share_type, is_password_set, permissions, share_with)
    this.note (note)
    this.expire_date (expire_date) {
    //  Q_ASSERT (Share.is_share_type_user_group_email_room_or_remote (share_type));
    //  Q_ASSERT (share_with);
}

void User_group_share.note (string note) {
    var job = new OcsShareJob (this.account);
    connect (job, &OcsShareJob.share_job_finished, this, &User_group_share.on_signal_note_set);
    connect (job, &OcsJob.ocs_error, this, &User_group_share.note_error);
    job.note (get_id (), note);
}

string User_group_share.get_note () {
    return this.note;
}

void User_group_share.on_signal_note_set (QJsonDocument &, GLib.Variant note) {
    this.note = note.to_string ();
    /* emit */ note_set ();
}

QDate User_group_share.get_expire_date () {
    return this.expire_date;
}

void User_group_share.expire_date (QDate date) {
    if (this.expire_date == date) {
        /* emit */ expire_date_set ();
        return;
    }

    var job = new OcsShareJob (this.account);
    connect (job, &OcsShareJob.share_job_finished, this, &User_group_share.on_signal_expire_date_set);
    connect (job, &OcsJob.ocs_error, this, &User_group_share.on_signal_ocs_error);
    job.expire_date (get_id (), date);
}

void User_group_share.on_signal_expire_date_set (QJsonDocument reply, GLib.Variant value) {
    var data = reply.object ().value ("ocs").to_object ().value ("data").to_object ();


    /***********************************************************
    If the reply provides a data back (more REST style)
    they use this date.
    ***********************************************************/
    if (data.value ("expiration").is_"") {
        this.expire_date = QDate.from_string (data.value ("expiration").to_string (), "yyyy-MM-dd 00:00:00");
    } else {
        this.expire_date = value.to_date ();
    }
    /* emit */ expire_date_set ();
}