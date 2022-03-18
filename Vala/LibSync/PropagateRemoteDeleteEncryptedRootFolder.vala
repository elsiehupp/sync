/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
Removing the root encrypted folder is consisted of multiple steps:
- 1st step is to obtain the folder_iD via LscolJob so it then can be used for the next step
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
namespace LibSync {

public class PropagateRemoteDeleteEncryptedRootFolder : AbstractPropagateRemoteDeleteEncrypted {

    const string ENCRYPTED_FILENAME_PROPERTY_KEY = "encrypted_filename";

    /***********************************************************
    Nested files and folders
    ***********************************************************/
    private GLib.HashTable<string, SyncJournalFileRecord> nested_items;

    /***********************************************************
    ***********************************************************/
    public PropagateRemoteDeleteEncryptedRootFolder (OwncloudPropagator propagator, SyncFileItem item, GLib.Object parent) {
        base (propagator, item, parent);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        GLib.assert (this.item.is_encrypted);

        const bool list_files_result = this.propagator.journal.list_files_in_path (
            this.item.file.to_utf8 (),
            this.result_list_filter
        );

        if (!list_files_result || this.nested_items == "") {
            // if the folder is empty, just decrypt and delete it
            decrypt_and_remote_delete ();
            return;
        }

        start_lscol_job (this.item.file);
    }


    private void result_list_filter (SyncJournalFileRecord record) {
        this.nested_items[record.e2e_mangled_name] = record;
    }


    /***********************************************************
    ***********************************************************/
    private new void on_signal_folder_unlocked_successfully (string folder_identifier) {
        AbstractPropagateRemoteDeleteEncrypted.on_signal_folder_unlocked_successfully (folder_identifier);
        decrypt_and_remote_delete ();
    }


    /***********************************************************
    ***********************************************************/
    private new void on_signal_folder_encrypted_metadata_received (QJsonDocument json, int status_code)  {
        if (status_code == 404) {
            // we've eneded up having no metadata, but, this.nested_items is not empty since we went this far, let's proceed with removing the nested items without modifying the metadata
            GLib.debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER + "There is no metadata for this folder. Just remove it's nested items.");
            for (var it = this.nested_items.const_begin (); it != this.nested_items.const_end (); ++it) {
                delete_nested_remote_item (it.key ());
            }
            return;
        }

        FolderMetadata metadata = new FolderMetadata (this.propagator.account, json.to_json (QJsonDocument.Compact), status_code);

        GLib.debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER + "It's a root encrypted folder. Let's remove nested items first.");

        metadata.remove_all_encrypted_files ();

        GLib.debug (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER + "Metadata updated, sending to the server.");

        var update_metadata_api_job = new UpdateMetadataApiJob (this.propagator.account, this.folder_identifier, metadata.encrypted_metadata (), this.folder_token);
        update_metadata_api_job.signal_success.connect (
            this.on_signal_update_metadata_api_job_success
        );
        update_metadata_api_job.signal_error.connect (
            this.on_signal_task_failed
        );
        update_metadata_api_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_delete_nested_remote_item_finished () {
        var delete_job = qobject_cast<DeleteJob> (GLib.Object.sender ());

        GLib.assert (delete_job);

        if (!delete_job) {
            return;
        }

        const string encrypted_filename = delete_job.property (ENCRYPTED_FILENAME_PROPERTY_KEY).to_string ();

        if (!encrypted_filename == "") {
            var nested_item = this.nested_items.take (encrypted_filename);

            if (nested_item.is_valid ()) {
                this.propagator.journal.delete_file_record (nested_item.path, nested_item.type == ItemType.DIRECTORY);
                this.propagator.journal.commit ("Remote Remove");
            }
        }

        Soup.Reply.NetworkError network_error = delete_job.input_stream.error;

        var http_error_code = delete_job.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        this.item.response_time_stamp = delete_job.response_timestamp;
        this.item.request_id = delete_job.request_id ();

        if (network_error != Soup.Reply.NoError && network_error != Soup.Reply.ContentNotFoundError) {
            store_first_error (network_error);
            store_first_error_string (delete_job.error_string);
            GLib.warning (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER + "Delete nested item on_signal_finished with error" + network_error + ".");
        } else if (http_error_code != 204 && http_error_code != 404) {
            // A 404 reply is also considered a on_signal_success here : We want to make sure
            // a file is gone from the server. It not being there in the first place
            // is ok. This will happen for files that are in the DB but not on
            // the server or the local file system.

            // Normally we expect "204 No Content"
            // If it is not the case, it might be because of a proxy or gateway intercepting the request, so we must
            // throw an error.
            store_first_error_string (
                _("Wrong HTTP code returned by server. Expected 204, but received \"%1 %2\".")
                    .printf (http_error_code)
                    .printf (delete_job.input_stream.attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ())
            );
            if (this.item.http_error_code == 0) {
                this.item.http_error_code = http_error_code;
            }

            GLib.warning (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER + "Delete nested item finished with error " + http_error_code + ".");
        }

        if (this.nested_items.size () == 0) {
            // we wait for all this.nested_items' Delete_jobs to finish, and then - fail if any of those jobs has failed
            if (network_error != Soup.Reply.NetworkError.NoError || this.item.http_error_code != 0) {
                const int error_code = network_error != Soup.Reply.NetworkError.NoError ? network_error : this.item.http_error_code;
                GLib.critical (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER + "Delete of nested items finished with error " + error_code.to_string () + ". Failing the entire sequence.");
                on_signal_task_failed ();
                return;
            }
            unlock_folder ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_update_metadata_api_job_success (string file_identifier) {
        //  Q_UNUSED (file_identifier);
        for (var it = this.nested_items.const_begin (); it != this.nested_items.const_end (); ++it) {
            delete_nested_remote_item (it.key ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private void decrypt_and_remote_delete () {
        var set_encryption_flag_api_job = new SetEncryptionFlagApiJob (this.propagator.account, this.item.file_id, SetEncryptionFlagApiJob.Clear, this);
        set_encryption_flag_api_job.signal_success.connect (
            this.on_signal_set_encryption_flag_api_job_success
        );
        set_encryption_flag_api_job.signal_error.connect (
            this.on_signal_set_encryption_flag_api_job_error
        );
        set_encryption_flag_api_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_set_encryption_flag_api_job_success (string file_identifier) {
        //  Q_UNUSED (file_identifier);
        delete_remote_item (this.item.file);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_set_encryption_flag_api_job_error (string file_identifier, int http_return_code) {
        //  Q_UNUSED (file_identifier);
        this.item.http_error_code = http_return_code;
        on_signal_task_failed ();
    }


    /***********************************************************
    ***********************************************************/
    private void delete_nested_remote_item (string filename) {
        GLib.info (PROPAGATE_REMOVE_ENCRYPTED_ROOTFOLDER) + "Deleting nested encrypted remote item" + filename;

        var delete_job = new DeleteJob (this.propagator.account, this.propagator.full_remote_path (filename), this);
        delete_job.folder_token (this.folder_token);
        delete_job.property (ENCRYPTED_FILENAME_PROPERTY_KEY, filename);

        delete_job.signal_finished.connect (
            this.on_signal_delete_nested_remote_item_finished
        );

        delete_job.start ();
    }

} // class PropagateRemoteDeleteEncryptedRootFolder

} // namespace LibSync
} // namespace Occ
