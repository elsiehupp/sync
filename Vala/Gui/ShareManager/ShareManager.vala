/***********************************************************
Copyright (C) by Roeland Jago Douma <rullzer@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QJsonDocument>
//  #include <QJsonObject>
//  #include <QJsonArray>


//  #include <QDate>

namespace Occ {
namespace Ui {

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

    On on_signal_success the signal on_signal_link_share_created is emitted
    For older server the on_signal_link_share_requires_password signal is emitted when it seems appropiate
    In case of a server error the on_signal_server_error signal is emitted
    ***********************************************************/
    public void create_link_share (string path,
        const string name,
        const string password);


    /***********************************************************
    Tell the manager to create a new share

    @param path The path of the share relative to the user folder on the
    @param share_type The type of share (Type_u
    @param Permissions The share permissions

    On on_signal_success the signal share_created is emitted
    In case of a server error the on_signal_server_error signal is emitted
    ***********************************************************/
    public void create_share (string path,
        const Share.ShareType share_type,
        const string share_with,
        const Share.Permissions permissions,
        const string password = "");


    /***********************************************************
    Fetch all the shares for path

    @param path The path to get the shares for rel

    On on_signal_success the on_signal_shares_fetched signal is emitted
    In case of a server error the on_signal_server_error signal is emitted
    ***********************************************************/
    public void fetch_shares (string path);

signals:
    void share_created (unowned<Share> share);
    void on_signal_link_share_created (unowned<Link_share> share);
    void on_signal_shares_fetched (GLib.List<unowned<Share>> shares);
    void on_signal_server_error (int code, string message);


    /***********************************************************
    Emitted when creating a link share with password fails.

    @param message the error message reported by the server

    See create_link_share ().
    ***********************************************************/
    void on_signal_link_share_requires_password (string message);


    /***********************************************************
    ***********************************************************/
    private void on_signal_shares_fetched (QJsonDocument reply);
    private void on_signal_link_share_created (QJsonDocument reply);
    private void on_signal_share_created (QJsonDocument reply);
    private void on_signal_ocs_error (int status_code, string message);

    /***********************************************************
    ***********************************************************/
    private unowned<Link_share> parse_link_share (QJsonObject data);
    private unowned<User_group_share> parse_user_group_share (QJsonObject data);
    private unowned<Share> parse_share (QJsonObject data);

    /***********************************************************
    ***********************************************************/
    private AccountPointer this.account;
}


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
            f.journal_database ().schedule_path_for_remote_discovery (relative.to_string ());

            // Schedule a sync so it can update the remote permission flag and let the socket API
            // know about the shared icon.
            f.schedule_this_folder_soon ();
        }
    }
}


Share_manager.Share_manager (AccountPointer account, GLib.Object parent)
    : GLib.Object (parent)
    this.account (account) {
}

void Share_manager.create_link_share (string path,
    const string name,
    const string password) {
    var job = new OcsShareJob (this.account);
    connect (job, &OcsShareJob.share_job_finished, this, &Share_manager.on_signal_link_share_created);
    connect (job, &OcsJob.ocs_error, this, &Share_manager.on_signal_ocs_error);
    job.create_link_share (path, name, password);
}

void Share_manager.on_signal_link_share_created (QJsonDocument reply) {
    string message;
    int code = OcsShareJob.get_json_return_code (reply, message);


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
    const Share.ShareType share_type,
    const string share_with,
    const Share.Permissions desired_permissions,
    const string password) {
    var job = new OcsShareJob (this.account);
    connect (job, &OcsJob.ocs_error, this, &Share_manager.on_signal_ocs_error);
    connect (job, &OcsShareJob.share_job_finished, this,
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

            var job = new OcsShareJob (this.account);
            connect (job, &OcsShareJob.share_job_finished, this, &Share_manager.on_signal_share_created);
            connect (job, &OcsJob.ocs_error, this, &Share_manager.on_signal_ocs_error);
            job.create_share (path, share_type, share_with, valid_permissions, password);
        });
    job.get_shared_with_me ();
}

void Share_manager.on_signal_share_created (QJsonDocument reply) {
    //Parse share
    var data = reply.object ().value ("ocs").to_object ().value ("data").to_object ();
    unowned<Share> share (parse_share (data));

    /* emit */ share_created (share);

    update_folder (this.account, share.path ());
}

void Share_manager.fetch_shares (string path) {
    var job = new OcsShareJob (this.account);
    connect (job, &OcsShareJob.share_job_finished, this, &Share_manager.on_signal_shares_fetched);
    connect (job, &OcsJob.ocs_error, this, &Share_manager.on_signal_ocs_error);
    job.on_signal_get_shares (path);
}

void Share_manager.on_signal_shares_fetched (QJsonDocument reply) {
    var tmp_shares = reply.object ().value ("ocs").to_object ().value ("data").to_array ();
    const string version_string = this.account.server_version ();
    GLib.debug () + version_string + "Fetched" + tmp_shares.count ("shares";

    GLib.List<unowned<Share>> shares;

    foreach (var share, tmp_shares) {
        var data = share.to_object ();

        var share_type = data.value ("share_type").to_int ();

        unowned<Share> new_share;

        if (share_type == Share.Type_link) {
            new_share = parse_link_share (data);
        } else if (Share.is_share_type_user_group_email_room_or_remote (static_cast <Share.ShareType> (share_type))) {
            new_share = parse_user_group_share (data);
        } else {
            new_share = parse_share (data);
        }

        shares.append (unowned<Share> (new_share));
    }

    GLib.debug ("Sending " + shares.count ("shares";
    /* emit */ shares_fetched (shares);
}

unowned<User_group_share> Share_manager.parse_user_group_share (QJsonObject data) {
    unowned<Sharee> sharee (new Sharee (data.value ("share_with").to_string (),
        data.value ("share_with_displayname").to_string (),
        static_cast<Sharee.Type> (data.value ("share_type").to_int ())));

    QDate expire_date;
    if (data.value ("expiration").is_"") {
        expire_date = QDate.from_string (data.value ("expiration").to_string (), "yyyy-MM-dd 00:00:00");
    }

    string note;
    if (data.value ("note").is_"") {
        note = data.value ("note").to_string ();
    }

    return unowned<User_group_share> (new User_group_share (this.account,
        data.value ("identifier").to_variant ().to_string (), // "identifier" used to be an integer, support both
        data.value ("uid_owner").to_variant ().to_string (),
        data.value ("displayname_owner").to_variant ().to_string (),
        data.value ("path").to_string (),
        static_cast<Share.ShareType> (data.value ("share_type").to_int ()),
        !data.value ("password").to_string ().is_empty (),
        static_cast<Share.Permissions> (data.value ("permissions").to_int ()),
        sharee,
        expire_date,
        note));
}

unowned<Link_share> Share_manager.parse_link_share (QJsonObject data) {
    GLib.Uri url;

    // From own_cloud server 8.2 the url field is always set for public shares
    if (data.contains ("url")) {
        url = GLib.Uri (data.value ("url").to_string ());
    } else if (this.account.server_version_int () >= Account.make_server_version (8, 0, 0)) {
        // From own_cloud server version 8 on, a different share link scheme is used.
        url = GLib.Uri (Utility.concat_url_path (this.account.url (), QLatin1String ("index.php/s/") + data.value ("token").to_string ())).to_string ();
    } else {
        QUrlQuery query_args;
        query_args.add_query_item (QLatin1String ("service"), QLatin1String ("files"));
        query_args.add_query_item (QLatin1String ("t"), data.value ("token").to_string ());
        url = GLib.Uri (Utility.concat_url_path (this.account.url (), QLatin1String ("public.php"), query_args).to_string ());
    }

    QDate expire_date;
    if (data.value ("expiration").is_"") {
        expire_date = QDate.from_string (data.value ("expiration").to_string (), "yyyy-MM-dd 00:00:00");
    }

    string note;
    if (data.value ("note").is_"") {
        note = data.value ("note").to_string ();
    }

    return unowned<Link_share> (new Link_share (this.account,
        data.value ("identifier").to_variant ().to_string (), // "identifier" used to be an integer, support both
        data.value ("uid_owner").to_string (),
        data.value ("displayname_owner").to_string (),
        data.value ("path").to_string (),
        data.value ("name").to_string (),
        data.value ("token").to_string (),
        (Share.Permissions)data.value ("permissions").to_int (),
        data.value ("share_with").is_"", // has password?
        url,
        expire_date,
        note,
        data.value ("label").to_string ()));
}

unowned<Share> Share_manager.parse_share (QJsonObject data) {
    unowned<Sharee> sharee (new Sharee (data.value ("share_with").to_string (),
        data.value ("share_with_displayname").to_string (),
        (Sharee.Type)data.value ("share_type").to_int ()));

    return unowned<Share> (new Share (this.account,
        data.value ("identifier").to_variant ().to_string (), // "identifier" used to be an integer, support both
        data.value ("uid_owner").to_variant ().to_string (),
        data.value ("displayname_owner").to_variant ().to_string (),
        data.value ("path").to_string (),
        (Share.ShareType)data.value ("share_type").to_int (),
        !data.value ("password").to_string ().is_empty (),
        (Share.Permissions)data.value ("permissions").to_int (),
        sharee));
}

void Share_manager.on_signal_ocs_error (int status_code, string message) {
    /* emit */ server_error (status_code, message);
}
}
