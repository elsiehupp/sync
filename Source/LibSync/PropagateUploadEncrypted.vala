

// #include <string>
// #include <QMap>
// #include <QJsonDocument>
// #include <QNetworkReply>
// #include <GLib.File>
// #include <QTemporary_file>
// #include <QFileInfo>
// #include <QDir>
// #include <GLib.Uri>
// #include <GLib.File>
// #include <QTemporary_file>
// #include <QLoggingCategory>
// #include <QMimeDatabase>

namespace Occ {

/*
This class is used if the server supports end to end encryption.
It will fire for any* folder, encrypted or not, because when the
client starts the upload request we don't know if the folder is
encrypted on the server.

emits:
finalized () if the encrypted file is ready to be
error () if there was an error with the encryption
folder_not_encrypted () if the file is within a folder that's not encrypted.
***********************************************************/

class Propagate_upload_encrypted : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public Propagate_upload_encrypted (OwncloudPropagator propagator, string remote_parent_path, SyncFileItemPtr item, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public bool is_unlock_running () {
        return _is_unlock_running;
    }


    /***********************************************************
    ***********************************************************/
    public bool is_folder_locked () {
    }


    /***********************************************************
    ***********************************************************/
    public 
    public const GLib.ByteArray folder_token () {
        return _folder_token;
    }


    /***********************************************************
    ***********************************************************/
    private void on_folder_encrypted_id_received (string[] &list);
    private void on_folder_encrypted_id_error (QNetworkReply r);
    private void on_folder_locked_successfully (GLib.ByteArray& file_id, GLib.ByteArray& token);
    private void on_folder_locked_error (GLib.ByteArray& file_id, int http_error_code);
    private void on_try_lock (GLib.ByteArray& file_id);
    private void on_folder_encrypted_metadata_received (QJsonDocument &json, int status_code);
    private void on_folder_encrypted_metadata_error (GLib.ByteArray& file_id, int http_return_code);
    private void on_update_metadata_success (GLib.ByteArray& file_id);
    private void on_update_metadata_error (GLib.ByteArray& file_id, int http_return_code);

signals:
    // Emmited after the file is encrypted and everythign is setup.
    void finalized (string& path, string& filename, uint64 size);
    void error ();
    void folder_unlocked (GLib.ByteArray folder_id, int http_status);


    /***********************************************************
    ***********************************************************/
    private OwncloudPropagator _propagator;
    private string _remote_parent_path;
    private SyncFileItemPtr _item;

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray _folder_token;

    /***********************************************************
    ***********************************************************/
    private 

    /***********************************************************
    ***********************************************************/
    private bool _current_locking_in_progress = false;

    /***********************************************************
    ***********************************************************/
    private bool _is_unlock_running = false;
    private bool _is_folder_locked = false;

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray _generated_key;
    private GLib.ByteArray _generated_iv;
    private FolderMetadata _metadata;
    private EncryptedFile _encrypted_file;
    private string _complete_file_name;
};


  Propagate_upload_encrypted.Propagate_upload_encrypted (OwncloudPropagator propagator, string remote_parent_path, SyncFileItemPtr item, GLib.Object parent)
      : GLib.Object (parent)
      , _propagator (propagator)
      , _remote_parent_path (remote_parent_path)
      , _item (item)
      , _metadata (nullptr) {
  }

  void Propagate_upload_encrypted.on_start () {
      const var root_path = [=] () {
          const var result = _propagator.remote_path ();
          if (result.starts_with ('/')) {
              return result.mid (1);
          } else {
              return result;
          }
      } ();
      const var absolute_remote_parent_path = [=]{
          var path = string (root_path + _remote_parent_path);
          if (path.ends_with ('/')) {
              path.chop (1);
          }
          return path;
      } ();

      /* If the file is in a encrypted folder, which we know, we wouldn't be here otherwise,
      we need to do the long road:
      find the ID of the folder.
      lock the folder using it's id.
      download the metadata
      update the metadata
      upload the file
      upload the metadata
      unlock the folder.
       */
      GLib.debug (lc_propagate_upload_encrypted) << "Folder is encrypted, let's get the Id from it.";
      var job = new LsColJob (_propagator.account (), absolute_remote_parent_path, this);
      job.set_properties ({"resourcetype", "http://owncloud.org/ns:fileid"});
      connect (job, &LsColJob.directory_listing_subfolders, this, &Propagate_upload_encrypted.on_folder_encrypted_id_received);
      connect (job, &LsColJob.finished_with_error, this, &Propagate_upload_encrypted.on_folder_encrypted_id_error);
      job.on_start ();
  }

  /* We try to lock a folder, if it's locked we try again in one second.
  if it's still locked we try again in one second. looping untill one minute.
                                                                       . fail.
  the 'loop' :                                                         /
     on_folder_encrypted_id_received . on_try_lock . lock_error . still_time? . on_try_lock

                                          . on_success.
  ***********************************************************/

  void Propagate_upload_encrypted.on_folder_encrypted_id_received (string[] &list) {
    GLib.debug (lc_propagate_upload_encrypted) << "Received id of folder, trying to lock it so we can prepare the metadata";
    var job = qobject_cast<LsColJob> (sender ());
    const var& folder_info = job._folder_infos.value (list.first ());
    _folder_lock_first_try.on_start ();
    on_try_lock (folder_info.file_id);
  }

  void Propagate_upload_encrypted.on_try_lock (GLib.ByteArray& file_id) {
    var lock_job = new LockEncryptFolderApiJob (_propagator.account (), file_id, this);
    connect (lock_job, &LockEncryptFolderApiJob.on_success, this, &Propagate_upload_encrypted.on_folder_locked_successfully);
    connect (lock_job, &LockEncryptFolderApiJob.error, this, &Propagate_upload_encrypted.on_folder_locked_error);
    lock_job.on_start ();
  }

  void Propagate_upload_encrypted.on_folder_locked_successfully (GLib.ByteArray& file_id, GLib.ByteArray& token) {
    GLib.debug (lc_propagate_upload_encrypted) << "Folder" << file_id << "Locked Successfully for Upload, Fetching Metadata";
    // Should I use a mutex here?
    _current_locking_in_progress = true;
    _folder_token = token;
    _folder_id = file_id;
    _is_folder_locked = true;

    var job = new GetMetadataApiJob (_propagator.account (), _folder_id);
    connect (job, &GetMetadataApiJob.json_received,
            this, &Propagate_upload_encrypted.on_folder_encrypted_metadata_received);
    connect (job, &GetMetadataApiJob.error,
            this, &Propagate_upload_encrypted.on_folder_encrypted_metadata_error);

    job.on_start ();
  }

  void Propagate_upload_encrypted.on_folder_encrypted_metadata_error (GLib.ByteArray& file_id, int http_return_code) {
      Q_UNUSED (file_id);
      Q_UNUSED (http_return_code);
      GLib.debug (lc_propagate_upload_encrypted ()) << "Error Getting the encrypted metadata. Pretend we got empty metadata.";
      FolderMetadata empty_metadata (_propagator.account ());
      empty_metadata.encrypted_metadata ();
      var json = QJsonDocument.from_json (empty_metadata.encrypted_metadata ());
      on_folder_encrypted_metadata_received (json, http_return_code);
  }

  void Propagate_upload_encrypted.on_folder_encrypted_metadata_received (QJsonDocument &json, int status_code) {
    GLib.debug (lc_propagate_upload_encrypted) << "Metadata Received, Preparing it for the new file." << json.to_variant ();

    // Encrypt File!
    _metadata = new FolderMetadata (_propagator.account (), json.to_json (QJsonDocument.Compact), status_code);

    QFileInfo info (_propagator.full_local_path (_item._file));
    const string file_name = info.file_name ();

    // Find existing metadata for this file
    bool found = false;
    EncryptedFile encrypted_file;
    const QVector<EncryptedFile> files = _metadata.files ();

    for (EncryptedFile &file : files) {
      if (file.original_filename == file_name) {
        encrypted_file = file;
        found = true;
      }
    }

    // New encrypted file so set it all up!
    if (!found) {
        encrypted_file.encryption_key = EncryptionHelper.generate_random (16);
        encrypted_file.encrypted_filename = EncryptionHelper.generate_random_filename ();
        encrypted_file.initialization_vector = EncryptionHelper.generate_random (16);
        encrypted_file.file_version = 1;
        encrypted_file.metadata_key = 1;
        encrypted_file.original_filename = file_name;

        QMimeDatabase mdatabase;
        encrypted_file.mimetype = mdatabase.mime_type_for_file (info).name ().to_local8Bit ();

        // Other clients expect "httpd/unix-directory" instead of "inode/directory"
        // Doesn't matter much for us since we don't do much about that mimetype anyway
        if (encrypted_file.mimetype == QByteArrayLiteral ("inode/directory")) {
            encrypted_file.mimetype = QByteArrayLiteral ("httpd/unix-directory");
        }
    }

    _item._encrypted_file_name = _remote_parent_path + '/' + encrypted_file.encrypted_filename;
    _item._is_encrypted = true;

    GLib.debug (lc_propagate_upload_encrypted) << "Creating the encrypted file.";

    if (info.is_dir ()) {
        _complete_file_name = encrypted_file.encrypted_filename;
    } else {
        GLib.File input (info.absolute_file_path ());
        GLib.File output (QDir.temp_path () + QDir.separator () + encrypted_file.encrypted_filename);

        GLib.ByteArray tag;
        bool encryption_result = EncryptionHelper.file_encryption (
          encrypted_file.encryption_key,
          encrypted_file.initialization_vector,
          &input, &output, tag);

        if (!encryption_result) {
          GLib.debug (lc_propagate_upload_encrypted ()) << "There was an error encrypting the file, aborting upload.";
          connect (this, &Propagate_upload_encrypted.folder_unlocked, this, &Propagate_upload_encrypted.error);
          unlock_folder ();
          return;
        }

        encrypted_file.authentication_tag = tag;
        _complete_file_name = output.file_name ();
    }

    GLib.debug (lc_propagate_upload_encrypted) << "Creating the metadata for the encrypted file.";

    _metadata.add_encrypted_file (encrypted_file);
    _encrypted_file = encrypted_file;

    GLib.debug (lc_propagate_upload_encrypted) << "Metadata created, sending to the server.";

    if (status_code == 404) {
      var job = new StoreMetaDataApiJob (_propagator.account (),
                                         _folder_id,
                                         _metadata.encrypted_metadata ());
      connect (job, &StoreMetaDataApiJob.on_success, this, &Propagate_upload_encrypted.on_update_metadata_success);
      connect (job, &StoreMetaDataApiJob.error, this, &Propagate_upload_encrypted.on_update_metadata_error);
      job.on_start ();
    } else {
      var job = new UpdateMetadataApiJob (_propagator.account (),
                                        _folder_id,
                                        _metadata.encrypted_metadata (),
                                        _folder_token);

      connect (job, &UpdateMetadataApiJob.on_success, this, &Propagate_upload_encrypted.on_update_metadata_success);
      connect (job, &UpdateMetadataApiJob.error, this, &Propagate_upload_encrypted.on_update_metadata_error);
      job.on_start ();
    }
  }

  void Propagate_upload_encrypted.on_update_metadata_success (GLib.ByteArray& file_id) {
      Q_UNUSED (file_id);
      GLib.debug (lc_propagate_upload_encrypted) << "Uploading of the metadata on_success, Encrypting the file";
      QFileInfo output_info (_complete_file_name);

      GLib.debug (lc_propagate_upload_encrypted) << "Encrypted Info:" << output_info.path () << output_info.file_name () << output_info.size ();
      GLib.debug (lc_propagate_upload_encrypted) << "Finalizing the upload part, now the actuall uploader will take over";
      emit finalized (output_info.path () + '/' + output_info.file_name (),
                     _remote_parent_path + '/' + output_info.file_name (),
                     output_info.size ());
  }

  void Propagate_upload_encrypted.on_update_metadata_error (GLib.ByteArray& file_id, int http_error_response) {
    GLib.debug (lc_propagate_upload_encrypted) << "Update metadata error for folder" << file_id << "with error" << http_error_response;
    GLib.debug (lc_propagate_upload_encrypted ()) << "Unlocking the folder.";
    connect (this, &Propagate_upload_encrypted.folder_unlocked, this, &Propagate_upload_encrypted.error);
    unlock_folder ();
  }

  void Propagate_upload_encrypted.on_folder_locked_error (GLib.ByteArray& file_id, int http_error_code) {
      Q_UNUSED (http_error_code);
      /* try to call the lock from 5 to 5 seconds
      and fail if it's more than 5 minutes. */
      QTimer.single_shot (5000, this, [this, file_id]{
          if (!_current_locking_in_progress) {
              GLib.debug (lc_propagate_upload_encrypted) << "Error locking the folder while no other update is locking it up.";
              GLib.debug (lc_propagate_upload_encrypted) << "Perhaps another client locked it.";
              GLib.debug (lc_propagate_upload_encrypted) << "Abort";
          return;
          }

          // Perhaps I should remove the elapsed timer if the lock is from this client?
          if (_folder_lock_first_try.elapsed () > /* five minutes */ 1000 * 60 * 5 ) {
              GLib.debug (lc_propagate_upload_encrypted) << "One minute passed, ignoring more attempts to lock the folder.";
          return;
          }
          on_try_lock (file_id);
      });

      GLib.debug (lc_propagate_upload_encrypted) << "Folder" << file_id << "Coundn't be locked.";
  }

  void Propagate_upload_encrypted.on_folder_encrypted_id_error (QNetworkReply r) {
      Q_UNUSED (r);
      GLib.debug (lc_propagate_upload_encrypted) << "Error retrieving the Id of the encrypted folder.";
  }

  void Propagate_upload_encrypted.unlock_folder () {
      ASSERT (!_is_unlock_running);

      if (_is_unlock_running) {
          q_warning () << "Double-call to unlock_folder.";
          return;
      }

      _is_unlock_running = true;

      q_debug () << "Calling Unlock";
      var unlock_job = new UnlockEncryptFolderApiJob (_propagator.account (),
          _folder_id, _folder_token, this);

      connect (unlock_job, &UnlockEncryptFolderApiJob.on_success, [this] (GLib.ByteArray folder_id) {
          q_debug () << "Successfully Unlocked";
          _folder_token = "";
          _folder_id = "";
          _is_folder_locked = false;

          emit folder_unlocked (folder_id, 200);
          _is_unlock_running = false;
      });
      connect (unlock_job, &UnlockEncryptFolderApiJob.error, [this] (GLib.ByteArray folder_id, int http_status) {
          q_debug () << "Unlock Error";

          emit folder_unlocked (folder_id, http_status);
          _is_unlock_running = false;
      });
      unlock_job.on_start ();
  }

  } // namespace Occ
  