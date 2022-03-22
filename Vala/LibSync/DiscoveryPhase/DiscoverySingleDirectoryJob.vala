namespace Occ {
namespace LibSync {

/***********************************************************
@class DiscoverySingleDirectoryJob

@brief Run a PROPFIND on a directory and process the results
for Discovery.

@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/
public class DiscoverySingleDirectoryJob : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private GLib.List<RemoteInfo> results;
    private string sub_path;
    private string first_etag;
    private string file_identifier;
    private string local_file_id;
    private unowned Account account;


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
    private LscolJob lscol_job;


    /***********************************************************
    ***********************************************************/
    private public string data_fingerprint;


    /***********************************************************
    This is not actually a network job, it is just a job
    ***********************************************************/
    internal signal void first_directory_permissions (RemotePermissions);
    internal signal void etag (string , GLib.DateTime time);
    internal signal void signal_finished (HttpResult<GLib.List<RemoteInfo>> result);


    /***********************************************************
    ***********************************************************/
    public DiscoverySingleDirectoryJob.for_account (unowned Account account, string path, GLib.Object parent = new GLib.Object ()) {
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
    public new void start () {
        // Start the actual HTTP job
        var lscol_job = new LscolJob (this.account, this.sub_path, this);

        GLib.List<string> props = new GLib.List<string> ();
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
        if (this.account.server_version_int >= Account.make_server_version (10, 0, 0)) {
            // Server older than 10.0 have performances issue if we ask for the share-types on every PROPFIND
            props.append ("http://owncloud.org/ns:share-types");
        }
        if (this.account.capabilities.client_side_encryption_available ()) {
            props.append ("http://nextcloud.org/ns:is-encrypted");
        }

        lscol_job.properties (props);

        lscol_job.signal_directory_listing_iterated.connect (
            this.on_signal_directory_listing_iterated_slot
        );
        lscol_job.signal_finished_with_error.connect (
            this.on_signal_ls_job_finished_with_error_slot
        );
        lscol_job.signal_finished_without_error.connect (
            this.on_signal_ls_job_finished_without_error_slot
        );
        lscol_job.start ();

        this.lscol_job = lscol_job;
    }


    /***********************************************************
    ***********************************************************/
    public new void abort () {
        if (this.lscol_job && this.lscol_job.input_stream) {
            this.lscol_job.input_stream.abort ();
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
    private void on_signal_ls_job_finished_with_error_slot (GLib.InputStream *);


    /***********************************************************
    ***********************************************************/
    private void on_signal_fetch_e2e_metadata ();


    /***********************************************************
    ***********************************************************/
    private void on_signal_metadata_received (QJsonDocument json, int status_code);


    /***********************************************************
    ***********************************************************/
    private void on_signal_metadata_error (string file_identifier, int http_return_code);

} // class DiscoverySingleDirectoryJob

} // namespace LibSync
} // namespace Occ
