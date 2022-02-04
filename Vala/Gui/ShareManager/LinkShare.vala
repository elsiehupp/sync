/***********************************************************
Copyright (C) by Roeland Jago Douma <rullzer@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
A Link share is just like a regular share but then slightly different.
There are several methods in the API that either work differently for
link shares or are only available to link shares.
***********************************************************/
class Link_share : Share {

    /***********************************************************
    ***********************************************************/
    public Link_share (AccountPointer account,
        const string identifier,
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
    const string identifier,
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
    : Share (account, identifier, uidowner, owner_display_name, path, Share.Type_link, is_password_set, permissions)
    this.name (name)
    this.token (token)
    this.note (note)
    this.expire_date (expire_date)
    this.url (url)
    this.label (label) {
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
    this.note = note.to_string ();
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
        this.expire_date = QDate.from_string (data.value ("expiration").to_string (), "yyyy-MM-dd 00:00:00");
    } else {
        this.expire_date = value.to_date ();
    }
    /* emit */ expire_date_set ();
}

void Link_share.on_name_set (QJsonDocument &, GLib.Variant value) {
    this.name = value.to_string ();
    /* emit */ name_set ();
}

void Link_share.on_label_set (QJsonDocument &, GLib.Variant label) {
    if (this.label != label.to_string ()) {
        this.label = label.to_string ();
        /* emit */ label_set ();
    }
}