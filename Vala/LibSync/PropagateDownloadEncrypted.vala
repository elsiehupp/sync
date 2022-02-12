
//  #include <QFileInfo>

namespace Occ {

class PropagateDownloadEncrypted : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private OwncloudPropagator propagator;
    private string local_parent_path;
    private SyncFileItemPtr item;
    private QFileInfo info;
    private EncryptedFile encrypted_info;


    /***********************************************************
    ***********************************************************/
    string error_string { public get; protected set; }


    signal void file_metadata_found ();
    signal void failed ();
    signal void decryption_finished ();


    /***********************************************************
    ***********************************************************/
    public PropagateDownloadEncrypted (OwncloudPropagator propagator, string local_parent_path, SyncFileItemPtr item, GLib.Object parent = new GLib.Object ())
        base (parent);
        this.propagator = propagator;
        this.local_parent_path = local_parent_path;
        this.item = item;
        this.info = this.item.file;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
            var root_path = [=] () {
                    var result = this.propagator.remote_path ();
                    if (result.starts_with ('/')) {
                            return result.mid (1);
                    } else {
                            return result;
                    }
            } ();
            var remote_filename = this.item.encrypted_filename.is_empty () ? this.item.file : this.item.encrypted_filename;
            var remote_path = string (root_path + remote_filename);
            var remote_parent_path = remote_path.left (remote_path.last_index_of ('/'));

            // Is encrypted Now we need the folder-identifier
            var job = new LsColJob (this.propagator.account (), remote_parent_path, this);
            job.properties ({"resourcetype", "http://owncloud.org/ns:fileid"});
            connect (job, LsColJob.directory_listing_subfolders,
                            this, PropagateDownloadEncrypted.on_signal_check_folder_id);
            connect (job, LsColJob.finished_with_error,
                            this, PropagateDownloadEncrypted.on_signal_folder_id_error);
            job.on_signal_start ();
    }


    /***********************************************************
    TODO: Fix this. Exported in the wrong place.
    ***********************************************************/
    public string create_download_tmp_filename (string previous);


    /***********************************************************
    ***********************************************************/
    public bool decrypt_file (GLib.File tmp_file) {
            const string tmp_filename = create_download_tmp_filename (this.item.file + "_dec");
            GLib.debug ("Content Checksum Computed starting decryption" + tmp_filename);

            tmp_file.close ();
            GLib.File tmp_output = new GLib.File (this.propagator.full_local_path (tmp_filename), this);
            EncryptionHelper.file_decryption (this.encrypted_info.encryption_key,
                                                                            this.encrypted_info.initialization_vector,
                                                                            tmp_file,
                                                                            this.tmp_output);

            GLib.debug ("Decryption on_signal_finished" + tmp_file.filename () + tmp_output.filename ());

            tmp_file.close ();
            this.tmp_output.close ();

            // we decripted the temporary into another temporary, so good bye old one
            if (!tmp_file.remove ()) {
                    GLib.debug ("Failed to remove temporary file" + tmp_file.error_string ());
                    this.error_string = tmp_file.error_string ();
                    return false;
            }

            // Let's fool the rest of the logic into thinking this was the actual download
            tmp_file.filename (this.tmp_output.filename ());

            return true;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_check_folder_id (string[] list) {
        var job = qobject_cast<LsColJob> (sender ());
        const string folder_identifier = list.first ();
        GLib.debug ("Received identifier of folder" + folder_identifier);

        const ExtraFolderInfo folder_info = job.folder_infos.value (folder_identifier);

        // Now that we have the folder-identifier we need it's JSON metadata
        var metadata_job = new GetMetadataApiJob (this.propagator.account (), folder_info.file_identifier);
        connect (metadata_job, GetMetadataApiJob.signal_json_received,
                        this, PropagateDownloadEncrypted.on_signal_check_folder_encrypted_metadata);
        connect (metadata_job, GetMetadataApiJob.error,
                        this, PropagateDownloadEncrypted.on_signal_folder_encrypted_metadata_error);

        metadata_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_check_folder_encrypted_metadata (QJsonDocument json) {
        GLib.debug ("Metadata Received reading: "
                   + this.item.instruction
                   + this.item.file
                   + this.item.encrypted_filename);
        const string filename = this.info.filename ();
        var meta = new FolderMetadata (this.propagator.account (), json.to_json (QJsonDocument.Compact));
        const GLib.List<EncryptedFile> files = meta.files ();

        const string encrypted_filename = this.item.encrypted_filename.section ('/', -1);
        foreach (EncryptedFile file in files) {
            if (encrypted_filename == file.encrypted_filename) {
                this.encrypted_info = file;

                GLib.debug ("Found matching encrypted metadata for file, starting download.");
                /* emit */ file_metadata_found ();
                return;
            }
        }

        /* emit */ failed ();
        GLib.critical ("Failed to find encrypted metadata information of remote file " + filename);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_folder_id_error () {
        GLib.debug ("Failed to get encrypted metadata of folder.");
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_folder_encrypted_metadata_error (GLib.ByteArray file_identifier, int http_return_code) {
            GLib.critical ("Failed to find encrypted metadata information of remote file " + this.info.filename ());
            /* emit */ failed ();
    }

} // class PropagateDownloadEncrypted

} // namespace Occ
