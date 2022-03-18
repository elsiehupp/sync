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
The share manager allows for creating, retrieving and
deletion of shares. It abstracts away from the OCS Share
API, all the usages shares should talk to this manager and
not use OCS Share Job directly/
***********************************************************/
public class ShareManager : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private unowned Account account;

    internal signal void signal_share_created (Share share);
    internal signal void signal_link_share_created (LinkShare share);
    internal signal void signal_shares_fetched (GLib.List<unowned Share> shares);
    internal signal void signal_server_error (int code, string message);


    /***********************************************************
    Emitted when creating a link share with password fails.

    @param message the error message reported by the server

    See create_link_share ().
    ***********************************************************/
    internal signal void signal_link_share_requires_password (string message);

    /***********************************************************
    ***********************************************************/
    public ShareManager (
        unowned Account account,
        GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.account = account;
    }


    /***********************************************************
    Tell the manager to create a link share

    @param path The path of the linkshare relative to the u
    @param name The name of the created share, may be empty
    @param password The password of the share, may be

    On success the signal on_signal_create_link_share_job_finished is emitted
    For older server the on_signal_link_share_requires_password signal is emitted when it seems appropiate
    In case of a server error the on_signal_server_error signal is emitted
    ***********************************************************/
    public void create_link_share (
        string path,
        string name,
        string password) {
        var create_link_share_job = new OcsShareJob (this.account);
        create_link_share_job.signal_finished.connect (
            this.on_signal_create_link_share_job_finished
        );
        create_link_share_job.signal_error.connect (
            this.on_signal_ocs_share_job_error
        );
        create_link_share_job.create_link_share (path, name, password);
    }


    /***********************************************************
    Tell the manager to create a new share

    @param path The path of the share relative to the user folder on the
    @param share_type The type of share (Type_u
    @param Permissions The share permissions

    On on_signal_success the signal signal_share_created is emitted
    In case of a server error the on_signal_server_error signal is emitted
    ***********************************************************/
    public void create_share (string path,
        Share.Type share_type,
        string share_with,
        Share.Permissions permissions,
        string password = "") {
        var ocs_share_job = new OcsShareJob (this.account);
        ocs_share_job.signal_error.connect (
            this.on_signal_ocs_share_job_error
        );
        ocs_share_job.signal_finished.connect (
            this.on_signal_create_share_job_finished
        );
        ocs_share_job.shared_with_me ();
    }


    /***********************************************************
    Fetch all the shares for path

    @param path The path to get the shares for rel

    On on_signal_success the on_signal_shares_fetched signal is emitted
    In case of a server error the on_signal_server_error signal is emitted
    ***********************************************************/
    public void fetch_shares (string path) {
        var ocs_share_job = new OcsShareJob (this.account);
        ocs_share_job.signal_finished.connect (
            this.on_signal_shares_fetched
        );
        ocs_share_job.signal_error.connect (
            this.on_signal_ocs_share_job_error
        );
        ocs_share_job.on_signal_get_shares (path);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_share_job_finished (QJsonDocument reply) {
        // Find existing share permissions (if this was shared with us)
        Share.Permissions existing_permissions = Share_permission_default;
        foreach (QJsonValue element in reply.object ()["ocs"].to_object ()["data"].to_array ()) {
            var map = element.to_object ();
            if (map["file_target"] == path) {
                existing_permissions = Share.Permissions (map["permissions"].to_int ());
            }
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

        var ocs_share_job = new OcsShareJob (this.account);
        ocs_share_job.signal_finished.connect (
            this.on_signal_share_created
        );
        ocs_share_job.signal_error.connect (
            this.on_signal_ocs_share_job_error
        );
        ocs_share_job.create_share (
            path,
            share_type,
            share_with,
            valid_permissions,
            password
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_shares_fetched (QJsonDocument reply) {
        var temporary_shares = reply.object ().value ("ocs").to_object ().value ("data").to_array ();
        GLib.debug (this.account.server_version () + " Fetched " + temporary_shares.count () + "shares");

        GLib.List<unowned Share> shares;

        foreach (var share in temporary_shares) {
            var data = share.to_object ();

            var share_type = data.value ("share_type").to_int ();

            unowned Share new_share;

            if (share_type == Share.Type.LINK) {
                new_share = parse_link_share (data);
            } else if (Share.is_share_type_user_group_email_room_or_remote (static_cast <Share.Type> (share_type))) {
                new_share = parse_user_group_share (data);
            } else {
                new_share = parse_share (data);
            }

            shares.append (new Share (new_share));
        }

        GLib.debug ("Sending " + shares.count () + " shares.");
        /* emit */ shares_fetched (shares);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_create_link_share_job_finished (QJsonDocument reply) {
        string message;
        int code = OcsShareJob.json_return_code (reply, message);


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
        unowned LinkShare share = new LinkShare (parse_link_share (data));

        /* emit */ link_share_created (share);

        update_folder (this.account, share.path ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_share_created (QJsonDocument reply) {
        //Parse share
        var data = reply.object ().value ("ocs").to_object ().value ("data").to_object ();
        unowned Share share = new Share (parse_share (data));

        /* emit */ signal_share_created (share);

        update_folder (this.account, share.path ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_ocs_share_job_error (int status_code, string message) {
        /* emit */ server_error (status_code, message);
    }


    /***********************************************************
    ***********************************************************/
    private unowned LinkShare parse_link_share (QJsonObject data);
    unowned LinkShare ShareManager.parse_link_share (QJsonObject data) {
        GLib.Uri url;

        // From own_cloud server 8.2 the url field is always set for public shares
        if (data.contains ("url")) {
            url = GLib.Uri (data.value ("url").to_string ());
        } else if (this.account.server_version_int () >= Account.make_server_version (8, 0, 0)) {
            // From own_cloud server version 8 on, a different share link scheme is used.
            url = GLib.Uri (Utility.concat_url_path (this.account.url, "index.php/s/" + data.value ("token").to_string ())).to_string ();
        } else {
            QUrlQuery query_args;
            query_args.add_query_item ("service", "files");
            query_args.add_query_item ("t", data.value ("token").to_string ());
            url = GLib.Uri (Utility.concat_url_path (this.account.url, "public.php", query_args).to_string ());
        }

        QDate expire_date;
        if (data.value ("expiration").is_string ()) {
            expire_date = QDate.from_string (data.value ("expiration").to_string (), "yyyy-MM-dd 00:00:00");
        }

        string note;
        if (data.value ("note").is_string ()) {
            note = data.value ("note").to_string ();
        }

        return new LinkShare (
            this.account,
            data.value ("identifier").to_variant ().to_string (), // "identifier" used to be an integer, support both
            data.value ("owner_uid").to_string (),
            data.value ("displayname_owner").to_string (),
            data.value ("path").to_string (),
            data.value ("name").to_string (),
            data.value ("token").to_string (),
            (Share.Permissions)data.value ("permissions").to_int (),
            data.value ("share_with").is_string (), // has password?
            url,
            expire_date,
            note,
            data.value ("label").to_string ()
        );
    }


    /***********************************************************
    ***********************************************************/
    private unowned UserGroupShare parse_user_group_share (QJsonObject data) {
        unowned Sharee sharee = new Sharee (
            data.value ("share_with").to_string (),
            data.value ("share_with_displayname").to_string (),
            (Sharee.Type) data.value ("share_type").to_int ()
        );

        QDate expire_date;
        if (data.value ("expiration").is_string ()) {
            expire_date = QDate.from_string (data.value ("expiration").to_string (), "yyyy-MM-dd 00:00:00");
        }

        string note;
        if (data.value ("note").is_string ()) {
            note = data.value ("note").to_string ();
        }

        return new UserGroupShare (
            this.account,
            data.value ("identifier").to_variant ().to_string (), // "identifier" used to be an integer, support both
            data.value ("owner_uid").to_variant ().to_string (),
            data.value ("displayname_owner").to_variant ().to_string (),
            data.value ("path").to_string (),
            static_cast<Share.Type> (data.value ("share_type").to_int ()),
            !data.value ("password").to_string () == "",
            static_cast<Share.Permissions> (data.value ("permissions").to_int ()),
            sharee,
            expire_date,
            note
        );
    }


    /***********************************************************
    ***********************************************************/
    private unowned Share parse_share (QJsonObject data) {
        unowned Sharee sharee = new Sharee (
            data.value ("share_with").to_string (),
            data.value ("share_with_displayname").to_string (),
            (Sharee.Type) data.value ("share_type").to_int ()
        );

        return new Share (
            this.account,
            data.value ("identifier").to_variant ().to_string (), // "identifier" used to be an integer, support both
            data.value ("owner_uid").to_variant ().to_string (),
            data.value ("displayname_owner").to_variant ().to_string (),
            data.value ("path").to_string (),
            (Share.Type) data.value ("share_type").to_int (),
            !data.value ("password").to_string () == "",
            (Share.Permissions) data.value ("permissions").to_int (),
            sharee
        );
    }


    /***********************************************************
    When a share is modified, we need to tell the folders so they can adjust overlay icons
    ***********************************************************/
    private static void update_folder (unowned Account account, string path) {
        foreach (Folder folder in FolderMan.instance.map ()) {
            if (folder.account_state ().account != account) {
                continue;
            }
            var folder_path = folder.remote_path ();
            if (path.starts_with (folder_path) && (path == folder_path || folder_path.ends_with ('/') || path[folder_path.size ()] == '/')) {
                // Workaround the fact that the server does not invalidate the etags of parent directories
                // when something is shared.
                var relative = path.mid_ref (folder.remote_path_trailing_slash ().length ());
                folder.journal_database ().schedule_path_for_remote_discovery (relative.to_string ());

                // Schedule a sync so it can update the remote permission flag and let the socket API
                // know about the shared icon.
                folder.schedule_this_folder_soon ();
            }
        }
    }

} // class ShareManager

} // namespace Ui
} // namespace Occ
