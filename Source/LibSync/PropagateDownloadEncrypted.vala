#ifndef PROPAGATEDOWNLOADENCRYPTED_H
const int PROPAGATEDOWNLOADENCRYPTED_H

// #include <QFileInfo>


namespace Occ {

class Propagate_download_encrypted : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public Propagate_download_encrypted (OwncloudPropagator propagator, string local_parent_path, SyncFileItemPtr item, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool decrypt_file (GLib.

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_check_folder_id (string_value

    /***********************************************************
    ***********************************************************/
    public 
    public void on_check_folder_encrypted_metadata (QJsonDocument json);


    public void on_folder_id_error ();


    public void on_folder_encrypted_metadata_error (GLib.ByteArray file_id, int http_return_code);

signals:
    void file_metadata_found ();
    void failed ();

    void decryption_finished ();


    /***********************************************************
    ***********************************************************/
    private OwncloudPropagator this.propagator;
    private string this.local_parent_path;
    private SyncFileItemPtr this.item;
    private QFileInfo this.info;
    private EncryptedFile this.encrypted_info;
    private string this.error_string;
};



Propagate_download_encrypted.Propagate_download_encrypted (OwncloudPropagator propagator, string local_parent_path, SyncFileItemPtr item, GLib.Object parent)
        : GLib.Object (parent)
        , this.propagator (propagator)
        , this.local_parent_path (local_parent_path)
        , this.item (item)
        , this.info (this.item._file) {
}

void Propagate_download_encrypted.on_start () {
        const var root_path = [=] () {
                const var result = this.propagator.remote_path ();
                if (result.starts_with ('/')) {
                        return result.mid (1);
                } else {
                        return result;
                }
        } ();
        const var remote_filename = this.item._encrypted_filename.is_empty () ? this.item._file : this.item._encrypted_filename;
        const var remote_path = string (root_path + remote_filename);
        const var remote_parent_path = remote_path.left (remote_path.last_index_of ('/'));

        // Is encrypted Now we need the folder-id
        var job = new LsColJob (this.propagator.account (), remote_parent_path, this);
        job.set_properties ({"resourcetype", "http://owncloud.org/ns:fileid"});
        connect (job, &LsColJob.directory_listing_subfolders,
                        this, &Propagate_download_encrypted.on_check_folder_id);
        connect (job, &LsColJob.finished_with_error,
                        this, &Propagate_download_encrypted.on_folder_id_error);
        job.on_start ();
}

void Propagate_download_encrypted.on_folder_id_error () {
    GLib.debug (lc_propagate_download_encrypted) << "Failed to get encrypted metadata of folder";
}

void Propagate_download_encrypted.on_check_folder_id (string[] list) {
    var job = qobject_cast<LsColJob> (sender ());
    const string folder_id = list.first ();
    GLib.debug (lc_propagate_download_encrypted) << "Received id of folder" << folder_id;

    const ExtraFolderInfo folder_info = job._folder_infos.value (folder_id);

    // Now that we have the folder-id we need it's JSON metadata
    var metadata_job = new GetMetadataApiJob (this.propagator.account (), folder_info.file_id);
    connect (metadata_job, &GetMetadataApiJob.json_received,
                    this, &Propagate_download_encrypted.on_check_folder_encrypted_metadata);
    connect (metadata_job, &GetMetadataApiJob.error,
                    this, &Propagate_download_encrypted.on_folder_encrypted_metadata_error);

    metadata_job.on_start ();
}

void Propagate_download_encrypted.on_folder_encrypted_metadata_error (GLib.ByteArray  /*file_id*/, int /*http_return_code*/) {
        q_c_critical (lc_propagate_download_encrypted) << "Failed to find encrypted metadata information of remote file" << this.info.filename ();
        /* emit */ failed ();
}

void Propagate_download_encrypted.on_check_folder_encrypted_metadata (QJsonDocument json) {
    GLib.debug (lc_propagate_download_encrypted) << "Metadata Received reading"
                                                                                << this.item._instruction << this.item._file << this.item._encrypted_filename;
    const string filename = this.info.filename ();
    var meta = new FolderMetadata (this.propagator.account (), json.to_json (QJsonDocument.Compact));
    const GLib.Vector<EncryptedFile> files = meta.files ();

    const string encrypted_filename = this.item._encrypted_filename.section ('/', -1);
    for (EncryptedFile file : files) {
        if (encrypted_filename == file.encrypted_filename) {
            this.encrypted_info = file;

            GLib.debug (lc_propagate_download_encrypted) << "Found matching encrypted metadata for file, starting download";
            /* emit */ file_metadata_found ();
            return;
        }
    }

    /* emit */ failed ();
    q_c_critical (lc_propagate_download_encrypted) << "Failed to find encrypted metadata information of remote file" << filename;
}

// TODO : Fix this. Exported in the wrong place.
string create_download_tmp_filename (string previous);

bool Propagate_download_encrypted.decrypt_file (GLib.File& tmp_file) {
        const string tmp_filename = create_download_tmp_filename (this.item._file + QLatin1String ("this.dec"));
        GLib.debug (lc_propagate_download_encrypted) << "Content Checksum Computed starting decryption" << tmp_filename;

        tmp_file.close ();
        GLib.File this.tmp_output (this.propagator.full_local_path (tmp_filename), this);
        EncryptionHelper.file_decryption (this.encrypted_info.encryption_key,
                                                                         this.encrypted_info.initialization_vector,
                                                                         tmp_file,
                                                                         this.tmp_output);

        GLib.debug (lc_propagate_download_encrypted) << "Decryption on_finished" << tmp_file.filename () << this.tmp_output.filename ();

        tmp_file.close ();
        this.tmp_output.close ();

        // we decripted the temporary into another temporary, so good bye old one
        if (!tmp_file.remove ()) {
                GLib.debug (lc_propagate_download_encrypted) << "Failed to remove temporary file" << tmp_file.error_string ();
                this.error_string = tmp_file.error_string ();
                return false;
        }

        // Let's fool the rest of the logic into thinking this was the actual download
        tmp_file.set_filename (this.tmp_output.filename ());

        return true;
}

string Propagate_download_encrypted.error_string () {
    return this.error_string;
}

}
