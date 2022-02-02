/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
@brief The GETEncrypted_file_job class that provides file decryption on the fly while the download is running
@ingroup libsync
***********************************************************/
class GETEncrypted_file_job : GETFileJob {

    // DOES NOT take ownership of the device.
    public GETEncrypted_file_job (AccountPointer account, string path, QIODevice device,
        const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, GLib.ByteArray expected_etag_for_resume,
        int64 resume_start, EncryptedFile encrypted_info, GLib.Object parent = new GLib.Object ());


    /***********************************************************
    ***********************************************************/
    public GETEncrypted_file_job (AccountPointer account, GLib.Uri url, QIODevice device,
        const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, GLib.ByteArray expected_etag_for_resume,
        int64 resume_start, EncryptedFile encrypted_info, GLib.Object parent = new GLib.Object ());
    ~GETEncrypted_file_job () override = default;


    protected int64 write_to_device (GLib.ByteArray data) override;


    /***********************************************************
    ***********************************************************/
    private unowned<EncryptionHelper.StreamingDecryptor> this.decryptor;
    private EncryptedFile this.encrypted_file_info = {};
    private GLib.ByteArray this.pending_bytes;
    private int64 this.processed_so_far = 0;
}


GETEncrypted_file_job.GETEncrypted_file_job (AccountPointer account, string path, QIODevice device,
    const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, GLib.ByteArray expected_etag_for_resume,
    int64 resume_start, EncryptedFile encrypted_info, GLib.Object parent)
    : GETFileJob (account, path, device, headers, expected_etag_for_resume, resume_start, parent)
    , this.encrypted_file_info (encrypted_info) {
}

GETEncrypted_file_job.GETEncrypted_file_job (AccountPointer account, GLib.Uri url, QIODevice device,
    const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, GLib.ByteArray expected_etag_for_resume,
    int64 resume_start, EncryptedFile encrypted_info, GLib.Object parent)
    : GETFileJob (account, url, device, headers, expected_etag_for_resume, resume_start, parent)
    , this.encrypted_file_info (encrypted_info) {
}

int64 GETEncrypted_file_job.write_to_device (GLib.ByteArray data) {
    if (!this.decryptor) {
        // only initialize the decryptor once, because, according to Qt documentation, metadata might get changed during the processing of the data sometimes
        // https://doc.qt.io/qt-5/qnetworkreply.html#meta_data_changed
        this.decryptor.on_reset (new EncryptionHelper.StreamingDecryptor (this.encrypted_file_info.encryption_key, this.encrypted_file_info.initialization_vector, this.content_length));
    }

    if (!this.decryptor.is_initialized ()) {
        return -1;
    }

    const var bytes_remaining = this.content_length - this.processed_so_far - data.length ();

    if (bytes_remaining != 0 && bytes_remaining < Occ.Constants.E2EE_TAG_SIZE) {
        // decryption is going to fail if last chunk does not include or does not equal to Occ.Constants.E2EE_TAG_SIZE bytes tag
        // we may end up receiving packets beyond Occ.Constants.E2EE_TAG_SIZE bytes tag at the end
        // in that case, we don't want to try and decrypt less than Occ.Constants.E2EE_TAG_SIZE ending bytes of tag, we will accumulate all the incoming data till the end
        // and then, we are going to decrypt the entire chunk containing Occ.Constants.E2EE_TAG_SIZE bytes at the end
        this.pending_bytes += GLib.ByteArray (data.const_data (), data.length ());
        this.processed_so_far += data.length ();
        if (this.processed_so_far != this.content_length) {
            return data.length ();
        }
    }

    if (!this.pending_bytes.is_empty ()) {
        const var decrypted_chunk = this.decryptor.chunk_decryption (this.pending_bytes.const_data (), this.pending_bytes.size ());

        if (decrypted_chunk.is_empty ()) {
            q_c_critical (lc_propagate_download) << "Decryption failed!";
            return -1;
        }

        GETFileJob.write_to_device (decrypted_chunk);

        return data.length ();
    }

    const var decrypted_chunk = this.decryptor.chunk_decryption (data.const_data (), data.length ());

    if (decrypted_chunk.is_empty ()) {
        q_c_critical (lc_propagate_download) << "Decryption failed!";
        return -1;
    }

    GETFileJob.write_to_device (decrypted_chunk);

    this.processed_so_far += data.length ();

    return data.length ();
}

void PropagateDownloadFile.on_start () {
    if (propagator ()._abort_requested)
        return;
    this.is_encrypted = false;

    GLib.debug (lc_propagate_download) << this.item._file << propagator ()._active_job_list.count ();

    const var path = this.item._file;
    const var slash_position = path.last_index_of ('/');
    const var parent_path = slash_position >= 0 ? path.left (slash_position) : "";

    SyncJournalFileRecord parent_rec;
    propagator ()._journal.get_file_record (parent_path, parent_rec);

    const var account = propagator ().account ();
    if (!account.capabilities ().client_side_encryption_available () ||
        !parent_rec.is_valid () ||
        !parent_rec._is_e2e_encrypted) {
        start_after_is_encrypted_is_checked ();
    } else {
        this.download_encrypted_helper = new Propagate_download_encrypted (propagator (), parent_path, this.item, this);
        connect (this.download_encrypted_helper, &Propagate_download_encrypted.file_metadata_found, [this] {
          this.is_encrypted = true;
          start_after_is_encrypted_is_checked ();
        });
        connect (this.download_encrypted_helper, &Propagate_download_encrypted.failed, [this] {
          on_done (SyncFileItem.Status.NORMAL_ERROR,
               _("File %1 cannot be downloaded because encryption information is missing.").arg (QDir.to_native_separators (this.item._file)));
        });
        this.download_encrypted_helper.on_start ();
    }
}
