/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The GETEncryptedFileJob class that provides file decryption on the fly while the download is running
@ingroup libsync
***********************************************************/
class GETEncryptedFileJob : GETFileJob {

    /***********************************************************
    ***********************************************************/
    private unowned<EncryptionHelper.StreamingDecryptor> decryptor;
    private EncryptedFile encrypted_file_info = {};
    private GLib.ByteArray pending_bytes;
    private int64 processed_so_far = 0;

    /***********************************************************
    DOES NOT take ownership of the device.
    ***********************************************************/
    public GETEncryptedFileJob (AccountPointer account, string path, QIODevice device,
        GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, GLib.ByteArray expected_etag_for_resume,
        int64 resume_start, EncryptedFile encrypted_info, GLib.Object parent = new GLib.Object ()) {
        base (account, path, device, headers, expected_etag_for_resume, resume_start, parent);
        this.encrypted_file_info = encrypted_info;
    }


    /***********************************************************
    ***********************************************************/
    public GETEncryptedFileJob (AccountPointer account, GLib.Uri url, QIODevice device,
        GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, GLib.ByteArray expected_etag_for_resume,
        int64 resume_start, EncryptedFile encrypted_info, GLib.Object parent = new GLib.Object ()) {
        base (account, url, device, headers, expected_etag_for_resume, resume_start, parent);
        this.encrypted_file_info = encrypted_info;
    }


    ~GETEncryptedFileJob () override = default;


    protected int64 write_to_device (GLib.ByteArray data) {
        if (!this.decryptor) {
            // only initialize the decryptor once, because, according to Qt documentation, metadata might get changed during the processing of the data sometimes
            // https://doc.qt.io/qt-5/qnetworkreply.html#meta_data_changed
            this.decryptor.on_signal_reset (new EncryptionHelper.StreamingDecryptor (this.encrypted_file_info.encryption_key, this.encrypted_file_info.initialization_vector, this.content_length));
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
                q_c_critical ("Decryption failed!";
                return -1;
            }

            GETFileJob.write_to_device (decrypted_chunk);

            return data.length ();
        }

        const var decrypted_chunk = this.decryptor.chunk_decryption (data.const_data (), data.length ());

        if (decrypted_chunk.is_empty ()) {
            q_c_critical ("Decryption failed!";
            return -1;
        }

        GETFileJob.write_to_device (decrypted_chunk);

        this.processed_so_far += data.length ();

        return data.length ();
    }

} // class GETEncryptedFileJob

} // namespace Occ
