namespace Occ {
namespace LibSync {

/***********************************************************
@class PropagateRemoteMkdir

@brief The PropagateRemoteMkdir class

@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PropagateRemoteMkdir : AbstractPropagateItemJob {

//    KeychainChunkDeleteJob delete_job;
//    MkColJob mkcol_job;

//    /***********************************************************
//    Whether an existing entity with the same name may be deleted before
//    creating the directory.

//    Default: false.
//    ***********************************************************/
//    public bool delete_existing;

//    PropagateUploadEncrypted upload_encrypted_helper;

//    //  friend class PropagateDirectory; // So it can access the this.item;

//    /***********************************************************
//    ***********************************************************/
//    public PropagateRemoteMkdir (OwncloudPropagator propagator, SyncFileItem item) {
//        base (propagator, item);
//        this.delete_existing = false;
//        this.upload_encrypted_helper = null;
//        var path = this.item.file;
//        var slash_position = path.last_index_of ("/");
//        var parent_path = slash_position >= 0 ? path.left (slash_position): "";

//        Common.SyncJournalFileRecord parent_rec;
//        bool ok = propagator.journal.get_file_record (parent_path, parent_rec);
//        if (!ok) {
//            return;
//        }
//    }


//    /***********************************************************
//    ***********************************************************/
//    public new void start () {
//        if (this.propagator.abort_requested) {
//            return;
//        }

//        GLib.debug (this.item.file);

//        this.propagator.active_job_list.append (this);

//        if (!this.delete_existing) {
//            on_signal_mkdir ();
//            return;
//        }

//        this.delete_job = new KeychainChunkDeleteJob (
//            this.propagator.account,
//            this.propagator.full_remote_path (this.item.file),
//            this
//        );
//        this.delete_job.signal_finished.connect (
//            this.on_signal_mkdir
//        );
//        this.delete_job.start ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    public new void abort (AbstractPropagatorJob.AbortType abort_type) {
//        if (this.mkcol_job != null && this.mkcol_job.input_stream) {
//            this.mkcol_job.input_stream.abort ();
//        }
//        if (this.delete_job != null && this.delete_job.input_stream) {
//            this.delete_job.input_stream.abort ();
//        }

//        if (abort_type == AbstractPropagatorJob.AbortType.ASYNCHRONOUS) {
//            signal_abort_finished ();
//        }
//    }


//    /***********************************************************
//    Creating a directory should be fast.
//    ***********************************************************/
//    public new bool is_likely_finished_quickly () {
//        return true;
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void on_signal_mkdir () {
//        var path = this.item.file;
//        var slash_position = path.last_index_of ("/");
//        var parent_path = slash_position >= 0 ? path.left (slash_position): "";

//        Common.SyncJournalFileRecord parent_rec;
//        bool ok = this.propagator.journal.get_file_record (parent_path, parent_rec);
//        if (!ok) {
//            on_signal_done (SyncFileItem.Status.NORMAL_ERROR);
//            return;
//        }

//        if (!has_encrypted_ancestor ()) {
//            on_signal_start_mkcol_job ();
//            return;
//        }

//        // We should be encrypted as well since our parent is
//        var remote_parent_path = parent_rec.e2e_mangled_name == "" ? parent_path : parent_rec.e2e_mangled_name;
//        this.upload_encrypted_helper = new PropagateUploadEncrypted (this.propagator, remote_parent_path, this.item, this);
//        this.upload_encrypted_helper.signal_finalized.connect (
//            this.on_signal_start_encrypted_mkcol_job
//        );
//        this.upload_encrypted_helper.signal_error.connect (
//            this.on_signal_propagate_upload_encrypted_error
//        );
//        this.upload_encrypted_helper.start ();
//    }


//    private void on_signal_propagate_upload_encrypted_error () {
//        GLib.debug ("Error setting up encryption.");
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void on_signal_start_mkcol_job () {
//        if (this.propagator.abort_requested) {
//            return;
//        }

//        GLib.debug (this.item.file);

//        this.mkcol_job = new MkColJob (
//            this.propagator.account,
//            this.propagator.full_remote_path (this.item.file),
//            this
//        );
//        this.mkcol_job.signal_finished_with_error.connect (
//            this.on_signal_mkcol_job_finished
//        );
//        this.mkcol_job.signal_finished_without_error.connect (
//            this.on_signal_mkcol_job_finished
//        );
//        this.mkcol_job.start ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void on_signal_start_encrypted_mkcol_job (string path, string filename, uint64 size) {
//        //  Q_UNUSED (path)
//        //  Q_UNUSED (size)

//        if (this.propagator.abort_requested) {
//            return;
//        }

//        GLib.debug (filename);

//        var mkcol_job = new MkColJob (
//            this.propagator.account,
//            this.propagator.full_remote_path (filename),
//            {
//                {
//                    "e2e-token",
//                    this.upload_encrypted_helper.folder_token ()
//                }
//            },
//            this
//        );
//        mkcol_job.signal_finished_with_error.connect (
//            this.on_signal_mkcol_job_finished
//        );
//        mkcol_job.signal_finished_without_error.connect (
//            this.on_signal_mkcol_job_finished
//        );
//        this.mkcol_job = mkcol_job;
//        this.mkcol_job.start ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void on_signal_mkcol_job_finished () {
//        this.propagator.active_job_list.remove_one (this);

//        //  GLib.assert_true (this.mkcol_job);

//        GLib.InputStream.NetworkError err = this.mkcol_job.input_stream.error;
//        this.item.http_error_code = this.mkcol_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
//        this.item.response_time_stamp = this.mkcol_job.response_timestamp;
//        this.item.request_id = this.mkcol_job.request_id ();

//        this.item.file_id = this.mkcol_job.input_stream.raw_header ("OC-File_id");

//        this.item.error_string = this.mkcol_job.error_string;

//        var job_http_reason_phrase_string = this.mkcol_job.input_stream.attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ();

//        var job_path = this.mkcol_job.path;

//        if (this.upload_encrypted_helper != null && this.upload_encrypted_helper.is_folder_locked && !this.upload_encrypted_helper.is_unlock_running) {
//            // since we are done, we need to unlock a folder in case it was locked
//            this.upload_encrypted_helper.signal_folder_unlocked.connect (
//                this.on_signal_propagate_upload_encrypted_folder_unlocked
//            );
//            this.upload_encrypted_helper.unlock_folder ();
//        } else {
//            finalize_mkcol_job (err, job_http_reason_phrase_string, job_path);
//        }
//    }


//    protected void on_signal_propagate_upload_encrypted_folder_unlocked (GLib.InputStream.NetworkError err, string job_http_reason_phrase_string, string job_path) {
//        finalize_mkcol_job (err, job_http_reason_phrase_string, job_path);
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void on_signal_encrypt_folder_finished () {
//        GLib.debug ("Success making the new folder encrypted.");
//        this.propagator.active_job_list.remove_one (this);
//        this.item.is_encrypted = true;
//        on_signal_success ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void on_signal_success () {
//        // Never save the etag on first mkdir.
//        // Only fully propagated directories should have the etag set.
//        var item_copy = this.item;
//        item_copy.etag = "";

//        // save the file identifier already so we can detect rename or remove
//        var result = this.propagator.update_metadata (item_copy);
//        if (!result) {
//            on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("Error writing metadata to the database : %1").printf (result.error));
//            return;
//        } else if (result == Common.AbstractVfs.ConvertToPlaceholderResult.Locked) {
//            on_signal_done (SyncFileItem.Status.FATAL_ERROR, _("The file %1 is currently in use").printf (this.item.file));
//            return;
//        }

//        on_signal_done (SyncFileItem.Status.SUCCESS);
//    }


//    /***********************************************************
//    ***********************************************************/
//    private void finalize_mkcol_job (GLib.InputStream.NetworkError err, string job_http_reason_phrase_string, string job_path) {
//        if (this.item.http_error_code == 405) {
//            // This happens when the directory already exists. Nothing to do.
//            GLib.debug ("FolderConnection " + job_path + " already exists.");
//        } else if (err != GLib.InputStream.NoError) {
//            SyncFileItem.Status status = classify_error (
//                err,
//                this.item.http_error_code,
//                this.propagator.another_sync_needed
//            );
//            on_signal_done (status, this.item.error_string);
//            return;
//        } else if (this.item.http_error_code != 201) {
//            // Normally we expect "201 Created"
//            // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
//            // throw an error.
//            on_signal_done (SyncFileItem.Status.NORMAL_ERROR,
//                _("Wrong HTTP code returned by server. Expected 201, but received \"%1 %2\".")
//                    .printf (this.item.http_error_code)
//                    .printf (job_http_reason_phrase_string));
//            return;
//        }

//        this.propagator.active_job_list.append (this);
//        var propfind_job = new PropfindJob (this.propagator.account, job_path, this);
//        propfind_job.properties ({"http://owncloud.org/ns:permissions"});
//        propfind_job.signal_result.connect (
//            this.on_signal_prop_find_job_result
//        );
//        propfind_job.signal_finished_with_error.connect (
//            this.on_signal_prop_find_job_finished_with_error
//        );
//        propfind_job.start ();
//    }


//    private void on_signal_prop_find_job_result (string job_path, GLib.HashTable<string, GLib.Variant> result) {
//        this.propagator.active_job_list.remove_one (this);
//        this.item.remote_permissions = Common.RemotePermissions.from_server_string (result.value ("permissions").to_string ());

//        if (this.upload_encrypted_helper == null && !this.item.is_encrypted) {
//            on_signal_success ();
//        } else {
//            // We still need to mark that folder encrypted in case we were uploading it as encrypted one
//            // Another scenario, is we are creating a new folder because of move operation on an encrypted folder that works via remove + re-upload
//            this.propagator.active_job_list.append (this);

//            // We're expecting directory path in /Foo/Bar convention...
//            GLib.assert (job_path.has_prefix ("/") && !job_path.has_suffix ("/"));
//            // But encryption job expect it in Foo/Bar/ convention
//            var encrypt_folder_job = new EncryptFolderJob (this.propagator.account, this.propagator.journal, job_path.mid (1), this.item.file_id, this);
//            encrypt_folder_job.signal_finished.connect (
//                this.on_signal_encrypt_folder_finished
//            );
//            encrypt_folder_job.start ();
//        }
//    }


//    private void on_signal_prop_find_job_finished_with_error () {
//        // ignore the PROPFIND error
//        this.propagator.active_job_list.remove_one (this);
//        on_signal_done (SyncFileItem.Status.NORMAL_ERROR);
//    }

} // class PropagateRemoteMkdir

} // namespace LibSync
} // namespace Occ
//    