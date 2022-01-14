#ifndef PROPAGATEDOWNLOADENCRYPTED_H
const int PROPAGATEDOWNLOADENCRYPTED_H

// #include <GLib.Object>
// #include <QFileInfo>


namespace Occ {

class Propagate_download_encrypted : GLib.Object {
  Q_OBJECT
public:
  Propagate_download_encrypted (Owncloud_propagator *propagator, string &local_parent_path, Sync_file_item_ptr item, GLib.Object *parent = nullptr);
  void start ();
  bool decrypt_file (QFile& tmp_file);
  string error_string ();

public slots:
  void check_folder_id (QStringList &list);
  void check_folder_encrypted_metadata (QJsonDocument &json);
  void folder_id_error ();
  void folder_encrypted_metadata_error (QByteArray &file_id, int http_return_code);

signals:
  void file_metadata_found ();
  void failed ();

  void decryption_finished ();

private:
  Owncloud_propagator *_propagator;
  string _local_parent_path;
  Sync_file_item_ptr _item;
  QFileInfo _info;
  Encrypted_file _encrypted_info;
  string _error_string;
};



Propagate_download_encrypted.Propagate_download_encrypted (Owncloud_propagator *propagator, string &local_parent_path, Sync_file_item_ptr item, GLib.Object *parent)
    : GLib.Object (parent)
    , _propagator (propagator)
    , _local_parent_path (local_parent_path)
    , _item (item)
    , _info (_item._file) {
}

void Propagate_download_encrypted.start () {
    const auto root_path = [=] () {
        const auto result = _propagator.remote_path ();
        if (result.starts_with ('/')) {
            return result.mid (1);
        } else {
            return result;
        }
    } ();
    const auto remote_filename = _item._encrypted_file_name.is_empty () ? _item._file : _item._encrypted_file_name;
    const auto remote_path = string (root_path + remote_filename);
    const auto remote_parent_path = remote_path.left (remote_path.last_index_of ('/'));

    // Is encrypted Now we need the folder-id
    auto job = new Ls_col_job (_propagator.account (), remote_parent_path, this);
    job.set_properties ({"resourcetype", "http://owncloud.org/ns:fileid"});
    connect (job, &Ls_col_job.directory_listing_subfolders,
            this, &Propagate_download_encrypted.check_folder_id);
    connect (job, &Ls_col_job.finished_with_error,
            this, &Propagate_download_encrypted.folder_id_error);
    job.start ();
}

void Propagate_download_encrypted.folder_id_error () {
  q_c_debug (lc_propagate_download_encrypted) << "Failed to get encrypted metadata of folder";
}

void Propagate_download_encrypted.check_folder_id (QStringList &list) {
  auto job = qobject_cast<Ls_col_job> (sender ());
  const string folder_id = list.first ();
  q_c_debug (lc_propagate_download_encrypted) << "Received id of folder" << folder_id;

  const Extra_folder_info &folder_info = job._folder_infos.value (folder_id);

  // Now that we have the folder-id we need it's JSON metadata
  auto metadata_job = new Get_metadata_api_job (_propagator.account (), folder_info.file_id);
  connect (metadata_job, &Get_metadata_api_job.json_received,
          this, &Propagate_download_encrypted.check_folder_encrypted_metadata);
  connect (metadata_job, &Get_metadata_api_job.error,
          this, &Propagate_download_encrypted.folder_encrypted_metadata_error);

  metadata_job.start ();
}

void Propagate_download_encrypted.folder_encrypted_metadata_error (QByteArray & /*file_id*/, int /*http_return_code*/) {
    q_c_critical (lc_propagate_download_encrypted) << "Failed to find encrypted metadata information of remote file" << _info.file_name ();
    emit failed ();
}

void Propagate_download_encrypted.check_folder_encrypted_metadata (QJsonDocument &json) {
  q_c_debug (lc_propagate_download_encrypted) << "Metadata Received reading"
                                        << _item._instruction << _item._file << _item._encrypted_file_name;
  const string filename = _info.file_name ();
  auto meta = new Folder_metadata (_propagator.account (), json.to_json (QJsonDocument.Compact));
  const QVector<Encrypted_file> files = meta.files ();

  const string encrypted_filename = _item._encrypted_file_name.section (QLatin1Char ('/'), -1);
  for (Encrypted_file &file : files) {
    if (encrypted_filename == file.encrypted_filename) {
      _encrypted_info = file;

      q_c_debug (lc_propagate_download_encrypted) << "Found matching encrypted metadata for file, starting download";
      emit file_metadata_found ();
      return;
    }
  }

  emit failed ();
  q_c_critical (lc_propagate_download_encrypted) << "Failed to find encrypted metadata information of remote file" << filename;
}

// TODO : Fix this. Exported in the wrong place.
string create_download_tmp_file_name (string &previous);

bool Propagate_download_encrypted.decrypt_file (QFile& tmp_file) {
    const string tmp_file_name = create_download_tmp_file_name (_item._file + QLatin1String ("_dec"));
    q_c_debug (lc_propagate_download_encrypted) << "Content Checksum Computed starting decryption" << tmp_file_name;

    tmp_file.close ();
    QFile _tmp_output (_propagator.full_local_path (tmp_file_name), this);
    Encryption_helper.file_decryption (_encrypted_info.encryption_key,
                                     _encrypted_info.initialization_vector,
                                     &tmp_file,
                                     &_tmp_output);

    q_c_debug (lc_propagate_download_encrypted) << "Decryption finished" << tmp_file.file_name () << _tmp_output.file_name ();

    tmp_file.close ();
    _tmp_output.close ();

    // we decripted the temporary into another temporary, so good bye old one
    if (!tmp_file.remove ()) {
        q_c_debug (lc_propagate_download_encrypted) << "Failed to remove temporary file" << tmp_file.error_string ();
        _error_string = tmp_file.error_string ();
        return false;
    }

    // Let's fool the rest of the logic into thinking this was the actual download
    tmp_file.set_file_name (_tmp_output.file_name ());

    return true;
}

string Propagate_download_encrypted.error_string () {
  return _error_string;
}

}
