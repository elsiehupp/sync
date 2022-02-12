/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
Removing the root encrypted folder is consisted of multiple steps:
- 1st step is to obtain the folder_iD via LsColJob so it then can be used for the next step
- 2nd step is to lock the root folder useing the folder_iD from the previous step. !!! Note: If there are no nested items in the folder, this, and subsequent steps are skipped until step 7.
- 3rd step is to obtain the root folder's metadata (it contains list of nested files and folders)
- 4th step is to remove the nested files and folders from the metadata and send it to the server via UpdateMetadataApiJob
- 5th step is to trigger DeleteJob for every nested file and folder of the root folder
- 6th step is to unlock the root folder using the previously obtained token from locking
- 7th step is to decrypt and delete the root folder, because it is now possible as it has become empty
***********************************************************/

//  #include <GLib.FileInfo>
//  #include <QLoggingCategory>


namespace Occ {

class PropagateRemoteDeleteEncryptedRootFolder : AbstractPropagateRemoteDeleteEncrypted {

    const string ENCRYPTED_FILENAME_PROPERTY_KEY = "encrypted_filename";

    /***********************************************************
    Nested files and folders
    ***********************************************************/
    private GLib.HashTable<string, Occ.SyncJournalFileRecord> nested_items;

    /***********************************************************
    ***********************************************************/
    public PropagateRemoteDeleteEncryptedRootFolder (OwncloudPropagator propagator, SyncFileItemPtr item, GLib.Object parent) {
        base (propagator, item, parent);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        //  Q_ASSERT (this.item.is_encrypted);

        const bool list_files_result = this.propagator.journal.list_files_in_path (this.item.file.to_utf8 (), (Occ.SyncJournalFileRecord record) {
            this.nested_items[record.e2e_mangled_name] = record;
        });

        if (!list_files_result || this.nested_items.is_empty ()) {
            // if the folder is empty, just decrypt and delete it
            decrypt_and_remote_delete ();
            return;
        }

        start_ls_col_job (this.item.file);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_unlocked_successfully (GLib.ByteArray folder_identifier) {
        AbstractPropagateRemoteDeleteEncrypted.on_signal_folder_unlocked_successfully (folder_identifier);
        decrypt_and_remote_delete ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_encrypted_metadata_received (QJsonDocument json, int status_code)  {
        if (status_code == 404) {
            // we've eneded up having no metadata, but, this.nested_items is not empty since we went this far, let's proceed with removing the nested items without modifying the metadata
            GLib.debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) + "There is no metadata for this folder. Just remove it's nested items.";
            for (var it = this.nested_items.const_begin (); it != this.nested_items.const_end (); ++it) {
                delete_nested_remote_item (it.key ());
            }
            return;
        }

        FolderMetadata metadata (this.propagator.account (), json.to_json (QJsonDocument.Compact), status_code);

        GLib.debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) + "It's a root encrypted folder. Let's remove nested items first.";

        metadata.remove_all_encrypted_files ();

        GLib.debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) + "Metadata updated, sending to the server.";

        var job = new UpdateMetadataApiJob (this.propagator.account (), this.folder_identifier, metadata.encrypted_metadata (), this.folder_token);
        connect (job, UpdateMetadataApiJob.on_signal_success, this, (GLib.ByteArray file_identifier) {
            //  Q_UNUSED (file_identifier);
            for (var it = this.nested_items.const_begin (); it != this.nested_items.const_end (); ++it) {
                delete_nested_remote_item (it.key ());
            }
        });
        connect (job, UpdateMetadataApiJob.error, this, PropagateRemoteDeleteEncryptedRootFolder.task_failed);
        job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_nested_remote_item_finished () {
        var delete_job = qobject_cast<DeleteJob> (GLib.Object.sender ());

        //  Q_ASSERT (delete_job);

        if (!delete_job) {
            return;
        }

        const string encrypted_filename = delete_job.property (ENCRYPTED_FILENAME_PROPERTY_KEY).to_string ();

        if (!encrypted_filename.is_empty ()) {
            var nested_item = this.nested_items.take (encrypted_filename);

            if (nested_item.is_valid ()) {
                this.propagator.journal.delete_file_record (nested_item.path, nested_item.type == ItemTypeDirectory);
                this.propagator.journal.commit ("Remote Remove");
            }
        }

        Soup.Reply.NetworkError err = delete_job.reply ().error ();

        var http_error_code = delete_job.reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        this.item.response_time_stamp = delete_job.response_timestamp ();
        this.item.request_id = delete_job.request_id ();

        if (err != Soup.Reply.NoError && err != Soup.Reply.ContentNotFoundError) {
            store_first_error (err);
            store_first_error_string (delete_job.error_string ());
            GLib.warning (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) + "Delete nested item on_signal_finished with error" + err + ".";
        } else if (http_error_code != 204 && http_error_code != 404) {
            // A 404 reply is also considered a on_signal_success here : We want to make sure
            // a file is gone from the server. It not being there in the first place
            // is ok. This will happen for files that are in the DB but not on
            // the server or the local file system.

            // Normally we expect "204 No Content"
            // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
            // throw an error.
            store_first_error_string (_("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
                            .arg (http_error_code)
                            .arg (delete_job.reply ().attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ()));
            if (this.item.http_error_code == 0) {
                this.item.http_error_code = http_error_code;
            }

            GLib.warning (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) + "Delete nested item on_signal_finished with error" + http_error_code + ".";
        }

        if (this.nested_items.size () == 0) {
            // we wait for all this.nested_items' Delete_jobs to finish, and then - fail if any of those jobs has failed
            if (signal_network_error () != Soup.Reply.NetworkError.NoError || this.item.http_error_code != 0) {
                const int error_code = signal_network_error () != Soup.Reply.NetworkError.NoError ? signal_network_error () : this.item.http_error_code;
                GLib.critical (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) + "Delete of nested items on_signal_finished with error" + error_code + ". Failing the entire sequence.";
                task_failed ();
                return;
            }
            unlock_folder ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void decrypt_and_remote_delete () {
        var job = new Occ.SetEncryptionFlagApiJob (this.propagator.account (), this.item.file_id, Occ.SetEncryptionFlagApiJob.Clear, this);
        connect (job, Occ.SetEncryptionFlagApiJob.on_signal_success, this, (GLib.ByteArray file_identifier) {
            //  Q_UNUSED (file_identifier);
            delete_remote_item (this.item.file);
        });
        connect (job, Occ.SetEncryptionFlagApiJob.error, this, (GLib.ByteArray file_identifier, int http_return_code) {
            //  Q_UNUSED (file_identifier);
            this.item.http_error_code = http_return_code;
            task_failed ();
        });
        job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void delete_nested_remote_item (string filename) {
        GLib.info (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) + "Deleting nested encrypted remote item" + filename;

        var delete_job = new DeleteJob (this.propagator.account (), this.propagator.full_remote_path (filename), this);
        delete_job.folder_token (this.folder_token);
        delete_job.property (ENCRYPTED_FILENAME_PROPERTY_KEY, filename);

        connect (delete_job, DeleteJob.signal_finished, this, PropagateRemoteDeleteEncryptedRootFolder.on_signal_delete_nested_remote_item_finished);

        delete_job.on_signal_start ();
    }

} // class PropagateRemoteDeleteEncryptedRootFolder

} // namespace Occ
