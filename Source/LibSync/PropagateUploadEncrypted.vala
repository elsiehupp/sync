

// #include <GLib.Object>
// #include <string>
// #include <QMap>
// #include <QByteArray>
// #include <QJsonDocument>
// #include <QNetworkReply>
// #include <QFile>
// #include <QTemporary_file>
// #include <QFileInfo>
// #include <QDir>
// #include <QUrl>
// #include <QFile>
// #include <QTemporary_file>
// #include <QLoggingCategory>
// #include <QMimeDatabase>

namespace Occ {

  /* This class is used if the server supports end to end encryption.
It will fire for *any* folder, encrypted or not, because when the
client starts the upload request we don't know if the folder is
encrypted on the server.

emits:
finalized () if the encrypted file is ready to be
error () if there was an error with the encryption
folder_not_encrypted () if the file is within a folder that's not encrypted.

***********************************************************/

class Propagate_upload_encrypted : GLib.Object {
  Q_OBJECT
public:
    Propagate_upload_encrypted (Owncloud_propagator *propagator, string &remote_parent_path, SyncFileItemPtr item, GLib.Object *parent = nullptr);
    ~Propagate_upload_encrypted () override = default;

    void start ();

    void unlock_folder ();

    bool is_unlock_running () { return _is_unlock_running; }
    bool is_folder_locked () { return _is_folder_locked; }
    const QByteArray folder_token () { return _folder_token; }

private slots:
    void slot_folder_encrypted_id_received (QStringList &list);
    void slot_folder_encrypted_id_error (QNetworkReply *r);
    void slot_folder_locked_successfully (QByteArray& file_id, QByteArray& token);
    void slot_folder_locked_error (QByteArray& file_id, int http_error_code);
    void slot_try_lock (QByteArray& file_id);
    void slot_folder_encrypted_metadata_received (QJsonDocument &json, int status_code);
    void slot_folder_encrypted_metadata_error (QByteArray& file_id, int http_return_code);
    void slot_update_metadata_success (QByteArray& file_id);
    void slot_update_metadata_error (QByteArray& file_id, int http_return_code);

signals:
    // Emmited after the file is encrypted and everythign is setup.
    void finalized (string& path, string& filename, uint64 size);
    void error ();
    void folder_unlocked (QByteArray &folder_id, int http_status);

private:
  Owncloud_propagator *_propagator;
  string _remote_parent_path;
  SyncFileItemPtr _item;

  QByteArray _folder_token;
  QByteArray _folder_id;

  QElapsedTimer _folder_lock_first_try;
  bool _current_locking_in_progress = false;

  bool _is_unlock_running = false;
  bool _is_folder_locked = false;

  QByteArray _generated_key;
  QByteArray _generated_iv;
  Folder_metadata *_metadata;
  Encrypted_file _encrypted_file;
  string _complete_file_name;
};


  Propagate_upload_encrypted.Propagate_upload_encrypted (Owncloud_propagator *propagator, string &remote_parent_path, SyncFileItemPtr item, GLib.Object *parent)
      : GLib.Object (parent)
      , _propagator (propagator)
      , _remote_parent_path (remote_parent_path)
      , _item (item)
      , _metadata (nullptr) {
  }
  
  void Propagate_upload_encrypted.start () {
      const auto root_path = [=] () {
          const auto result = _propagator.remote_path ();
          if (result.starts_with ('/')) {
              return result.mid (1);
          } else {
              return result;
          }
      } ();
      const auto absolute_remote_parent_path = [=]{
          auto path = string (root_path + _remote_parent_path);
          if (path.ends_with ('/')) {
              path.chop (1);
          }
          return path;
      } ();
  
      /* If the file is in a encrypted folder, which we know, we wouldn't be here otherwise,
       * we need to do the long road:
       * find the ID of the folder.
       * lock the folder using it's id.
       * download the metadata
       * update the metadata
       * upload the file
       * upload the metadata
       * unlock the folder.
       */
      q_c_debug (lc_propagate_upload_encrypted) << "Folder is encrypted, let's get the Id from it.";
      auto job = new Ls_col_job (_propagator.account (), absolute_remote_parent_path, this);
      job.set_properties ({"resourcetype", "http://owncloud.org/ns:fileid"});
      connect (job, &Ls_col_job.directory_listing_subfolders, this, &Propagate_upload_encrypted.slot_folder_encrypted_id_received);
      connect (job, &Ls_col_job.finished_with_error, this, &Propagate_upload_encrypted.slot_folder_encrypted_id_error);
      job.start ();
  }
  
  /* We try to lock a folder, if it's locked we try again in one second.
  if it's still locked we try again in one second. looping untill one minute.
                                                                       . fail.
  the 'loop' :                                                         /
     slot_folder_encrypted_id_received . slot_try_lock . lock_error . still_time? . slot_try_lock
  
                                          . success.
  ***********************************************************/
  
  void Propagate_upload_encrypted.slot_folder_encrypted_id_received (QStringList &list) {
    q_c_debug (lc_propagate_upload_encrypted) << "Received id of folder, trying to lock it so we can prepare the metadata";
    auto job = qobject_cast<Ls_col_job> (sender ());
    const auto& folder_info = job._folder_infos.value (list.first ());
    _folder_lock_first_try.start ();
    slot_try_lock (folder_info.file_id);
  }
  
  void Propagate_upload_encrypted.slot_try_lock (QByteArray& file_id) {
    auto *lock_job = new Lock_encrypt_folder_api_job (_propagator.account (), file_id, this);
    connect (lock_job, &Lock_encrypt_folder_api_job.success, this, &Propagate_upload_encrypted.slot_folder_locked_successfully);
    connect (lock_job, &Lock_encrypt_folder_api_job.error, this, &Propagate_upload_encrypted.slot_folder_locked_error);
    lock_job.start ();
  }
  
  void Propagate_upload_encrypted.slot_folder_locked_successfully (QByteArray& file_id, QByteArray& token) {
    q_c_debug (lc_propagate_upload_encrypted) << "Folder" << file_id << "Locked Successfully for Upload, Fetching Metadata";
    // Should I use a mutex here?
    _current_locking_in_progress = true;
    _folder_token = token;
    _folder_id = file_id;
    _is_folder_locked = true;
  
    auto job = new Get_metadata_api_job (_propagator.account (), _folder_id);
    connect (job, &Get_metadata_api_job.json_received,
            this, &Propagate_upload_encrypted.slot_folder_encrypted_metadata_received);
    connect (job, &Get_metadata_api_job.error,
            this, &Propagate_upload_encrypted.slot_folder_encrypted_metadata_error);
  
    job.start ();
  }
  
  void Propagate_upload_encrypted.slot_folder_encrypted_metadata_error (QByteArray& file_id, int http_return_code) {
      Q_UNUSED (file_id);
      Q_UNUSED (http_return_code);
      q_c_debug (lc_propagate_upload_encrypted ()) << "Error Getting the encrypted metadata. Pretend we got empty metadata.";
      Folder_metadata empty_metadata (_propagator.account ());
      empty_metadata.encrypted_metadata ();
      auto json = QJsonDocument.from_json (empty_metadata.encrypted_metadata ());
      slot_folder_encrypted_metadata_received (json, http_return_code);
  }
  
  void Propagate_upload_encrypted.slot_folder_encrypted_metadata_received (QJsonDocument &json, int status_code) {
    q_c_debug (lc_propagate_upload_encrypted) << "Metadata Received, Preparing it for the new file." << json.to_variant ();
  
    // Encrypt File!
    _metadata = new Folder_metadata (_propagator.account (), json.to_json (QJsonDocument.Compact), status_code);
  
    QFileInfo info (_propagator.full_local_path (_item._file));
    const string file_name = info.file_name ();
  
    // Find existing metadata for this file
    bool found = false;
    Encrypted_file encrypted_file;
    const QVector<Encrypted_file> files = _metadata.files ();
  
    for (Encrypted_file &file : files) {
      if (file.original_filename == file_name) {
        encrypted_file = file;
        found = true;
      }
    }
  
    // New encrypted file so set it all up!
    if (!found) {
        encrypted_file.encryption_key = Encryption_helper.generate_random (16);
        encrypted_file.encrypted_filename = Encryption_helper.generate_random_filename ();
        encrypted_file.initialization_vector = Encryption_helper.generate_random (16);
        encrypted_file.file_version = 1;
        encrypted_file.metadata_key = 1;
        encrypted_file.original_filename = file_name;
  
        QMimeDatabase mdb;
        encrypted_file.mimetype = mdb.mime_type_for_file (info).name ().to_local8Bit ();
  
        // Other clients expect "httpd/unix-directory" instead of "inode/directory"
        // Doesn't matter much for us since we don't do much about that mimetype anyway
        if (encrypted_file.mimetype == QByteArrayLiteral ("inode/directory")) {
            encrypted_file.mimetype = QByteArrayLiteral ("httpd/unix-directory");
        }
    }
  
    _item._encrypted_file_name = _remote_parent_path + QLatin1Char ('/') + encrypted_file.encrypted_filename;
    _item._is_encrypted = true;
  
    q_c_debug (lc_propagate_upload_encrypted) << "Creating the encrypted file.";
  
    if (info.is_dir ()) {
        _complete_file_name = encrypted_file.encrypted_filename;
    } else {
        QFile input (info.absolute_file_path ());
        QFile output (QDir.temp_path () + QDir.separator () + encrypted_file.encrypted_filename);
  
        QByteArray tag;
        bool encryption_result = Encryption_helper.file_encryption (
          encrypted_file.encryption_key,
          encrypted_file.initialization_vector,
          &input, &output, tag);
  
        if (!encryption_result) {
          q_c_debug (lc_propagate_upload_encrypted ()) << "There was an error encrypting the file, aborting upload.";
          connect (this, &Propagate_upload_encrypted.folder_unlocked, this, &Propagate_upload_encrypted.error);
          unlock_folder ();
          return;
        }
  
        encrypted_file.authentication_tag = tag;
        _complete_file_name = output.file_name ();
    }
  
    q_c_debug (lc_propagate_upload_encrypted) << "Creating the metadata for the encrypted file.";
  
    _metadata.add_encrypted_file (encrypted_file);
    _encrypted_file = encrypted_file;
  
    q_c_debug (lc_propagate_upload_encrypted) << "Metadata created, sending to the server.";
  
    if (status_code == 404) {
      auto job = new Store_meta_data_api_job (_propagator.account (),
                                         _folder_id,
                                         _metadata.encrypted_metadata ());
      connect (job, &Store_meta_data_api_job.success, this, &Propagate_upload_encrypted.slot_update_metadata_success);
      connect (job, &Store_meta_data_api_job.error, this, &Propagate_upload_encrypted.slot_update_metadata_error);
      job.start ();
    } else {
      auto job = new Update_metadata_api_job (_propagator.account (),
                                        _folder_id,
                                        _metadata.encrypted_metadata (),
                                        _folder_token);
  
      connect (job, &Update_metadata_api_job.success, this, &Propagate_upload_encrypted.slot_update_metadata_success);
      connect (job, &Update_metadata_api_job.error, this, &Propagate_upload_encrypted.slot_update_metadata_error);
      job.start ();
    }
  }
  
  void Propagate_upload_encrypted.slot_update_metadata_success (QByteArray& file_id) {
      Q_UNUSED (file_id);
      q_c_debug (lc_propagate_upload_encrypted) << "Uploading of the metadata success, Encrypting the file";
      QFileInfo output_info (_complete_file_name);
  
      q_c_debug (lc_propagate_upload_encrypted) << "Encrypted Info:" << output_info.path () << output_info.file_name () << output_info.size ();
      q_c_debug (lc_propagate_upload_encrypted) << "Finalizing the upload part, now the actuall uploader will take over";
      emit finalized (output_info.path () + QLatin1Char ('/') + output_info.file_name (),
                     _remote_parent_path + QLatin1Char ('/') + output_info.file_name (),
                     output_info.size ());
  }
  
  void Propagate_upload_encrypted.slot_update_metadata_error (QByteArray& file_id, int http_error_response) {
    q_c_debug (lc_propagate_upload_encrypted) << "Update metadata error for folder" << file_id << "with error" << http_error_response;
    q_c_debug (lc_propagate_upload_encrypted ()) << "Unlocking the folder.";
    connect (this, &Propagate_upload_encrypted.folder_unlocked, this, &Propagate_upload_encrypted.error);
    unlock_folder ();
  }
  
  void Propagate_upload_encrypted.slot_folder_locked_error (QByteArray& file_id, int http_error_code) {
      Q_UNUSED (http_error_code);
      /* try to call the lock from 5 to 5 seconds
       * and fail if it's more than 5 minutes. */
      QTimer.single_shot (5000, this, [this, file_id]{
          if (!_current_locking_in_progress) {
              q_c_debug (lc_propagate_upload_encrypted) << "Error locking the folder while no other update is locking it up.";
              q_c_debug (lc_propagate_upload_encrypted) << "Perhaps another client locked it.";
              q_c_debug (lc_propagate_upload_encrypted) << "Abort";
          return;
          }
  
          // Perhaps I should remove the elapsed timer if the lock is from this client?
          if (_folder_lock_first_try.elapsed () > /* five minutes */ 1000 * 60 * 5 ) {
              q_c_debug (lc_propagate_upload_encrypted) << "One minute passed, ignoring more attempts to lock the folder.";
          return;
          }
          slot_try_lock (file_id);
      });
  
      q_c_debug (lc_propagate_upload_encrypted) << "Folder" << file_id << "Coundn't be locked.";
  }
  
  void Propagate_upload_encrypted.slot_folder_encrypted_id_error (QNetworkReply *r) {
      Q_UNUSED (r);
      q_c_debug (lc_propagate_upload_encrypted) << "Error retrieving the Id of the encrypted folder.";
  }
  
  void Propagate_upload_encrypted.unlock_folder () {
      ASSERT (!_is_unlock_running);
  
      if (_is_unlock_running) {
          q_warning () << "Double-call to unlock_folder.";
          return;
      }
  
      _is_unlock_running = true;
  
      q_debug () << "Calling Unlock";
      auto *unlock_job = new Unlock_encrypt_folder_api_job (_propagator.account (),
          _folder_id, _folder_token, this);
  
      connect (unlock_job, &Unlock_encrypt_folder_api_job.success, [this] (QByteArray &folder_id) {
          q_debug () << "Successfully Unlocked";
          _folder_token = "";
          _folder_id = "";
          _is_folder_locked = false;
  
          emit folder_unlocked (folder_id, 200);
          _is_unlock_running = false;
      });
      connect (unlock_job, &Unlock_encrypt_folder_api_job.error, [this] (QByteArray &folder_id, int http_status) {
          q_debug () << "Unlock Error";
  
          emit folder_unlocked (folder_id, http_status);
          _is_unlock_running = false;
      });
      unlock_job.start ();
  }
  
  } // namespace Occ
  