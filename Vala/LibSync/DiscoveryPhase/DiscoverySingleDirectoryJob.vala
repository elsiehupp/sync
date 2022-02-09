/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using CSync;
namespace Occ {

/***********************************************************
@brief Run a PROPFIND on a directory and process the results for Discovery

@ingroup libsync
***********************************************************/
class DiscoverySingleDirectoryJob : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private GLib.List<RemoteInfo> results;
    private string sub_path;
    private GLib.ByteArray first_etag;
    private GLib.ByteArray file_identifier;
    private GLib.ByteArray local_file_id;
    private AccountPointer account;


    /***********************************************************
    The first result is for the directory itself and need to be
    ignored. This flag is true if it was already ignored.
    ***********************************************************/
    private bool ignored_first;


    /***********************************************************
    Set to true if this is the root path and we need to check
    the data-fingerprint
    ***********************************************************/
    private bool is_root_path;


    /***********************************************************
    If this directory is an external storage (The first item
    has 'M' in its permission)
    ***********************************************************/
    private bool is_external_storage;


    /***********************************************************
    If this directory is e2ee
    ***********************************************************/
    private bool is_e2e_encrypted;

    /***********************************************************
    If set, the discovery will finish with an error
    ***********************************************************/
    private int64 size = 0;
    private string error;
    private QPointer<LsColJob> ls_col_job;


    /***********************************************************
    ***********************************************************/
    private public GLib.ByteArray data_fingerprint;


    /***********************************************************
    This is not actually a network job, it is just a job
    ***********************************************************/
    signal void first_directory_permissions (RemotePermissions);
    signal void etag (GLib.ByteArray , GLib.DateTime time);
    signal void finished (HttpResult<GLib.List<RemoteInfo>> result);


    /***********************************************************
    ***********************************************************/
    public DiscoverySingleDirectoryJob.for_account (AccountPointer account, string path, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.sub_path = path;
        this.account = account;
        this.ignored_first = false;
        this.is_root_path = false;
        this.is_external_storage = false;
        this.is_e2e_encrypted = false;
    }


    /***********************************************************
    Specify that this is the root and we need to check the
    data-fingerprint
    ***********************************************************/
    public void is_root_path_true () {
        this.is_root_path = true;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        // Start the actual HTTP job
        var ls_col_job = new LsColJob (this.account, this.sub_path, this);

        GLib.List<GLib.ByteArray> props = new GLib.List<GLib.ByteArray> ();
        props.append ("resourcetype");
        props.append ("getlastmodified");
        props.append ("getcontentlength");
        props.append ("getetag");
        props.append ("http://owncloud.org/ns:size");
        props.append ("http://owncloud.org/ns:identifier");
        props.append ("http://owncloud.org/ns:fileid");
        props.append ("http://owncloud.org/ns:download_uRL");
        props.append ("http://owncloud.org/ns:d_dC");
        props.append ("http://owncloud.org/ns:permissions");
        props.append ("http://owncloud.org/ns:checksums");
        if (this.is_root_path)
            props.append ("http://owncloud.org/ns:data-fingerprint");
        if (this.account.server_version_int () >= Account.make_server_version (10, 0, 0)) {
            // Server older than 10.0 have performances issue if we ask for the share-types on every PROPFIND
            props.append ("http://owncloud.org/ns:share-types");
        }
        if (this.account.capabilities ().client_side_encryption_available ()) {
            props.append ("http://nextcloud.org/ns:is-encrypted");
        }

        ls_col_job.properties (props);

        GLib.Object.connect (ls_col_job, &LsColJob.directory_listing_iterated,
            this, &DiscoverySingleDirectoryJob.on_signal_directory_listing_iterated_slot);
        GLib.Object.connect (ls_col_job, &LsColJob.finished_with_error, this, &DiscoverySingleDirectoryJob.on_signal_ls_job_finished_with_error_slot);
        GLib.Object.connect (ls_col_job, &LsColJob.finished_without_error, this, &DiscoverySingleDirectoryJob.on_signal_ls_job_finished_without_error_slot);
        ls_col_job.on_signal_start ();

        this.ls_col_job = ls_col_job;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_abort () {
        if (this.ls_col_job && this.ls_col_job.reply ()) {
            this.ls_col_job.reply ().on_signal_abort ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_directory_listing_iterated_slot (string , GLib.HashTable<string, string> &);


    /***********************************************************
    ***********************************************************/
    private void on_signal_ls_job_finished_without_error_slot ();


    /***********************************************************
    ***********************************************************/
    private void on_signal_ls_job_finished_with_error_slot (Soup.Reply *);


    /***********************************************************
    ***********************************************************/
    private void on_signal_fetch_e2e_metadata ();


    /***********************************************************
    ***********************************************************/
    private void on_signal_metadata_received (QJsonDocument json, int status_code);


    /***********************************************************
    ***********************************************************/
    private void on_signal_metadata_error (GLib.ByteArray file_identifier, int http_return_code);

}





