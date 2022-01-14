/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QNetworkAccessManager>
// #include <QFileInfo>
// #include <QDir>
// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QFileInfo>

// #include <cmath>
// #include <cstring>
// #pragma once

// #include <QBuffer>
// #include <QFile>
// #include <QElapsedTimer>

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lc_put_job)
Q_DECLARE_LOGGING_CATEGORY (lc_propagate_upload)
Q_DECLARE_LOGGING_CATEGORY (lc_propagate_upload_v1)
Q_DECLARE_LOGGING_CATEGORY (lc_propagate_upload_nG)


/***********************************************************
@brief The Upload_device class
@ingroup libsync
***********************************************************/
class Upload_device : QIODevice {
public:
    Upload_device (string &file_name, int64 start, int64 size, Bandwidth_manager *bwm);
    ~Upload_device () override;

    bool open (QIODevice.Open_mode mode) override;
    void close () override;

    int64 write_data (char *, int64) override;
    int64 read_data (char *data, int64 maxlen) override;
    bool at_end () const override;
    int64 size () const override;
    int64 bytes_available () const override;
    bool is_sequential () const override;
    bool seek (int64 pos) override;

    void set_bandwidth_limited (bool);
    bool is_bandwidth_limited () { return _bandwidth_limited; }
    void set_choked (bool);
    bool is_choked () { return _choked; }
    void give_bandwidth_quota (int64 bwq);

signals:

private:
    /// The local file to read data from
    QFile _file;

    /// Start of the file data to use
    int64 _start = 0;
    /// Amount of file data after _start to use
    int64 _size = 0;
    /// Position between _start and _start+_size
    int64 _read = 0;

    // Bandwidth manager related
    QPointer<Bandwidth_manager> _bandwidth_manager;
    int64 _bandwidth_quota = 0;
    int64 _read_with_progress = 0;
    bool _bandwidth_limited = false; // if _bandwidth_quota will be used
    bool _choked = false; // if upload is paused (read_data () will return 0)
    friend class Bandwidth_manager;
public slots:
    void slot_job_upload_progress (int64 sent, int64 t);
};

/***********************************************************
@brief The PUTFile_job class
@ingroup libsync
***********************************************************/
class PUTFile_job : AbstractNetworkJob {

private:
    QIODevice *_device;
    QMap<QByteArray, QByteArray> _headers;
    string _error_string;
    QUrl _url;
    QElapsedTimer _request_timer;

public:
    // Takes ownership of the device
    PUTFile_job (AccountPtr account, string &path, std.unique_ptr<QIODevice> device,
        const QMap<QByteArray, QByteArray> &headers, int chunk, GLib.Object *parent = nullptr)
        : AbstractNetworkJob (account, path, parent)
        , _device (device.release ())
        , _headers (headers)
        , _chunk (chunk) {
        _device.set_parent (this);
    }
    PUTFile_job (AccountPtr account, QUrl &url, std.unique_ptr<QIODevice> device,
        const QMap<QByteArray, QByteArray> &headers, int chunk, GLib.Object *parent = nullptr)
        : AbstractNetworkJob (account, string (), parent)
        , _device (device.release ())
        , _headers (headers)
        , _url (url)
        , _chunk (chunk) {
        _device.set_parent (this);
    }
    ~PUTFile_job () override;

    int _chunk;

    void start () override;

    bool finished () override;

    QIODevice *device () {
        return _device;
    }

    string error_string () const override {
        return _error_string.is_empty () ? AbstractNetworkJob.error_string () : _error_string;
    }

    std.chrono.milliseconds ms_since_start () {
        return std.chrono.milliseconds (_request_timer.elapsed ());
    }

signals:
    void finished_signal ();
    void upload_progress (int64, int64);

};

/***********************************************************
@brief This job implements the asynchronous PUT

If the server replies
replies with an etag.
@ingroup libsync
***********************************************************/
class Poll_job : AbstractNetworkJob {
    SyncJournalDb *_journal;
    string _local_path;

public:
    SyncFileItemPtr _item;
    // Takes ownership of the device
    Poll_job (AccountPtr account, string &path, SyncFileItemPtr &item,
        SyncJournalDb *journal, string &local_path, GLib.Object *parent)
        : AbstractNetworkJob (account, path, parent)
        , _journal (journal)
        , _local_path (local_path)
        , _item (item) {
    }

    void start () override;
    bool finished () override;

signals:
    void finished_signal ();
};


/***********************************************************
@brief The Propagate_upload_file_common class is the code common between all chunking algorithms
@ingroup libsync

State Machine:

  +--. start ()  -. (delete job) -------+
  |
  +-. slot_compute_co
                  |

   slot_co
        |
        v
   slot_start_upload ()  . do_start_up
                                 .
                                 .
                                 v
       finalize () or abort_with_error ()  or start_poll_job ()
***********************************************************/
class Propagate_upload_file_common : Propagate_item_job {

    struct Upload_status {
        SyncFileItem.Status status = SyncFileItem.No_status;
        string message;
    };

protected:
    QVector<AbstractNetworkJob> _jobs; /// network jobs that are currently in transit
    bool _finished BITFIELD (1); /// Tells that all the jobs have been finished
    bool _delete_existing BITFIELD (1);

    /***********************************************************
    Whether an abort is currently ongoing.

    Important to avoid duplicate aborts since each finishing PUTFile_job might
    trigger an abort on error.
    ***********************************************************/
    bool _aborting BITFIELD (1);

    /* This is a minified version of the SyncFileItem,
    that holds only the specifics about the file that's
    being uploaded.
    
    This is needed if we wanna apply changes on the file
    that's being uploaded while keeping the original on disk.
    ***********************************************************/
    struct Upload_file_info {
      string _file; /// I'm still unsure if I should use a Sync_file_ptr here.
      string _path; /// the full path on disk.
      int64 _size;
    };
    Upload_file_info _file_to_upload;
    QByteArray _transmission_checksum_header;

public:
    Propagate_upload_file_common (Owncloud_propagator *propagator, SyncFileItemPtr &item);

    /***********************************************************
    Whether an existing entity with the same name may be deleted before
    the upload.
    
    Default : false.
    ***********************************************************/
    void set_delete_existing (bool enabled);

    /* start should setup the file, path and size that will be send to the server */
    void start () override;
    void setup_encrypted_file (string& path, string& filename, uint64 size);
    void setup_unencrypted_file ();
    void start_upload_file ();
    void call_unlock_folder ();
    bool is_likely_finished_quickly () override { return _item._size < propagator ().small_file_size (); }

private slots:
    void slot_compute_content_checksum ();
    // Content checksum computed, compute the transmission checksum
    void slot_compute_transmission_checksum (QByteArray &content_checksum_type, QByteArray &content_checksum);
    // transmission checksum computed, prepare the upload
    void slot_start_upload (QByteArray &transmission_checksum_type, QByteArray &transmission_checksum);
    // invoked when encrypted folder lock has been released
    void slot_folder_unlocked (QByteArray &folder_id, int http_return_code);
    // invoked on internal error to unlock a folder and faile
    void slot_on_error_start_folder_unlock (SyncFileItem.Status status, string &error_string);

public:
    virtual void do_start_upload () = 0;

    void start_poll_job (string &path);
    void finalize ();
    void abort_with_error (SyncFileItem.Status status, string &error);

public slots:
    void slot_job_destroyed (GLib.Object *job);

private slots:
    void slot_poll_finished ();

protected:
    void done (SyncFileItem.Status status, string &error_string = string ()) override;

    /***********************************************************
    Aborts all running network jobs, except for the ones that may_abort_job
    returns false on and, for async aborts, emits abort_finished when done.
    ***********************************************************/
    void abort_network_jobs (
        Abort_type abort_type,
        const std.function<bool (AbstractNetworkJob *job)> &may_abort_job);

    /***********************************************************
    Checks whether the current error is one that should reset the whole
    transfer if it happens too often. If so : Bump UploadInfo.error_count
    and maybe perform the reset.
    ***********************************************************/
    void check_resetting_errors ();

    /***********************************************************
    Error handling functionality that is shared between jobs.
    ***********************************************************/
    void common_error_handling (AbstractNetworkJob *job);

    /***********************************************************
    Increases the timeout for the final MOVE/PUT for large files.
    
    This is an unfortunate workaround since the drawback is not being able to
    detect real disconnects in a timely manner. Shall go away when the s
    response starts coming quicker, or there is some sort of async api.

    See #6527, enterprise#2480
    ***********************************************************/
    static void adjust_last_job_timeout (AbstractNetworkJob *job, int64 file_size);

    /***********************************************************
    Bases headers that need to be sent on the PUT, or in the MOVE for chunking-ng */
    QMap<QByteArray, QByteArray> headers ();
private:
  Propagate_upload_encrypted *_upload_encrypted_helper;
  bool _uploading_encrypted;
  Upload_status _upload_status;
};

/***********************************************************
@ingroup libsync

Propagation job, impementing the old chunking agorithm

***********************************************************/
class Propagate_upload_file_v1 : Propagate_upload_file_common {

private:
    /***********************************************************
    That's the start chunk that was stored in the database for resuming.
    In the non-resuming case it is 0.
    If we are resuming, this is the first chunk we need to send
    ***********************************************************/
    int _start_chunk = 0;
    /***********************************************************
    This is the next chunk that we need to send. Starting from 0 even if _start_chunk != 0
    (In other words,  _start_chunk + _current_chunk is really the number of the chunk we need to send next)
    (In other words, _current_chunk is the number of the chunk that we already sent or started sending)
    ***********************************************************/
    int _current_chunk = 0;
    int _chunk_count = 0; /// Total number of chunks for this file
    uint _transfer_id = 0; /// transfer id (part of the url)

    int64 chunk_size () {
        // Old chunking does not use dynamic chunking algorithm, and does not adjusts the chunk size respectively,
        // thus this value should be used as the one classifing item to be chunked
        return propagator ().sync_options ()._initial_chunk_size;
    }

public:
    Propagate_upload_file_v1 (Owncloud_propagator *propagator, SyncFileItemPtr &item)
        : Propagate_upload_file_common (propagator, item) {
    }

    void do_start_upload () override;
public slots:
    void abort (Propagator_job.Abort_type abort_type) override;
private slots:
    void start_next_chunk ();
    void slot_put_finished ();
    void slot_upload_progress (int64, int64);
};

/***********************************************************
@ingroup libsync

Propagation job, impementing the new chunking agorithm

***********************************************************/
class Propagate_upload_file_nG : Propagate_upload_file_common {
private:
    int64 _sent = 0; /// amount of data (bytes) that was already sent
    uint _transfer_id = 0; /// transfer id (part of the url)
    int _current_chunk = 0; /// Id of the next chunk that will be sent
    int64 _current_chunk_size = 0; /// current chunk size
    bool _remove_job_error = false; /// If not null, there was an error removing the job

    // Map chunk number with its size  from the PROPFIND on resume.
    // (Only used from slot_propfind_iterate/slot_propfind_finished because the Ls_col_job use signals to report data.)
    struct Server_chunk_info {
        int64 size;
        string original_name;
    };
    QMap<int64, Server_chunk_info> _server_chunks;

    /***********************************************************
    Return the URL of a chunk.
    If chunk == -1, returns the URL of the parent folder containing the chunks
    ***********************************************************/
    QUrl chunk_url (int chunk = -1);

public:
    Propagate_upload_file_nG (Owncloud_propagator *propagator, SyncFileItemPtr &item)
        : Propagate_upload_file_common (propagator, item) {
    }

    void do_start_upload () override;

private:
    void start_new_upload ();
    void start_next_chunk ();
public slots:
    void abort (Abort_type abort_type) override;
private slots:
    void slot_propfind_finished ();
    void slot_propfind_finished_with_error ();
    void slot_propfind_iterate (string &name, QMap<string, string> &properties);
    void slot_delete_job_finished ();
    void slot_mk_col_finished ();
    void slot_put_finished ();
    void slot_move_job_finished ();
    void slot_upload_progress (int64, int64);
};

    PUTFile_job.~PUTFile_job () {
        // Make sure that we destroy the QNetworkReply before our _device of which it keeps an internal pointer.
        set_reply (nullptr);
    }
    
    void PUTFile_job.start () {
        QNetworkRequest req;
        for (QMap<QByteArray, QByteArray>.Const_iterator it = _headers.begin (); it != _headers.end (); ++it) {
            req.set_raw_header (it.key (), it.value ());
        }
    
        req.set_priority (QNetworkRequest.Low_priority); // Long uploads must not block non-propagation jobs.
    
        if (_url.is_valid ()) {
            send_request ("PUT", _url, req, _device);
        } else {
            send_request ("PUT", make_dav_url (path ()), req, _device);
        }
    
        if (reply ().error () != QNetworkReply.NoError) {
            q_c_warning (lc_put_job) << " Network error : " << reply ().error_string ();
        }
    
        connect (reply (), &QNetworkReply.upload_progress, this, &PUTFile_job.upload_progress);
        connect (this, &AbstractNetworkJob.network_activity, account ().data (), &Account.propagator_network_activity);
        _request_timer.start ();
        AbstractNetworkJob.start ();
    }
    
    bool PUTFile_job.finished () {
        _device.close ();
    
        q_c_info (lc_put_job) << "PUT of" << reply ().request ().url ().to_string () << "FINISHED WITH STATUS"
                         << reply_status_string ()
                         << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute)
                         << reply ().attribute (QNetworkRequest.Http_reason_phrase_attribute);
    
        emit finished_signal ();
        return true;
    }
    
    void Poll_job.start () {
        set_timeout (120 * 1000);
        QUrl account_url = account ().url ();
        QUrl final_url = QUrl.from_user_input (account_url.scheme () + QLatin1String ("://") + account_url.authority ()
            + (path ().starts_with ('/') ? QLatin1String ("") : QLatin1String ("/")) + path ());
        send_request ("GET", final_url);
        connect (reply (), &QNetworkReply.download_progress, this, &AbstractNetworkJob.reset_timeout, Qt.UniqueConnection);
        AbstractNetworkJob.start ();
    }
    
    bool Poll_job.finished () {
        QNetworkReply.NetworkError err = reply ().error ();
        if (err != QNetworkReply.NoError) {
            _item._http_error_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
            _item._request_id = request_id ();
            _item._status = classify_error (err, _item._http_error_code);
            _item._error_string = error_string ();
    
            if (_item._status == SyncFileItem.Fatal_error || _item._http_error_code >= 400) {
                if (_item._status != SyncFileItem.Fatal_error
                    && _item._http_error_code != 503) {
                    SyncJournalDb.Poll_info info;
                    info._file = _item._file;
                    // no info._url removes it from the database
                    _journal.set_poll_info (info);
                    _journal.commit ("remove poll info");
                }
                emit finished_signal ();
                return true;
            }
            QTimer.single_shot (8 * 1000, this, &Poll_job.start);
            return false;
        }
    
        QByteArray json_data = reply ().read_all ().trimmed ();
        QJsonParseError json_parse_error;
        QJsonObject json = QJsonDocument.from_json (json_data, &json_parse_error).object ();
        q_c_info (lc_poll_job) << ">" << json_data << "<" << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int () << json << json_parse_error.error_string ();
        if (json_parse_error.error != QJsonParseError.NoError) {
            _item._error_string = tr ("Invalid JSON reply from the poll URL");
            _item._status = SyncFileItem.Normal_error;
            emit finished_signal ();
            return true;
        }
    
        auto status = json["status"].to_string ();
        if (status == QLatin1String ("init") || status == QLatin1String ("started")) {
            QTimer.single_shot (5 * 1000, this, &Poll_job.start);
            return false;
        }
    
        _item._response_time_stamp = response_timestamp ();
        _item._http_error_code = json["error_code"].to_int ();
    
        if (status == QLatin1String ("finished")) {
            _item._status = SyncFileItem.Success;
            _item._file_id = json["file_id"].to_string ().to_utf8 ();
            _item._etag = parse_etag (json["ETag"].to_string ().to_utf8 ());
        } else { // error
            _item._status = classify_error (QNetworkReply.Unknown_content_error, _item._http_error_code);
            _item._error_string = json["error_message"].to_string ();
        }
    
        SyncJournalDb.Poll_info info;
        info._file = _item._file;
        // no info._url removes it from the database
        _journal.set_poll_info (info);
        _journal.commit ("remove poll info");
    
        emit finished_signal ();
        return true;
    }
    
    Propagate_upload_file_common.Propagate_upload_file_common (Owncloud_propagator *propagator, SyncFileItemPtr &item)
        : Propagate_item_job (propagator, item)
        , _finished (false)
        , _delete_existing (false)
        , _aborting (false)
        , _upload_encrypted_helper (nullptr)
        , _uploading_encrypted (false) {
        const auto path = _item._file;
        const auto slash_position = path.last_index_of ('/');
        const auto parent_path = slash_position >= 0 ? path.left (slash_position) : string ();
    
        SyncJournalFileRecord parent_rec;
        bool ok = propagator._journal.get_file_record (parent_path, &parent_rec);
        if (!ok) {
            return;
        }
    }
    
    void Propagate_upload_file_common.set_delete_existing (bool enabled) {
        _delete_existing = enabled;
    }
    
    void Propagate_upload_file_common.start () {
        const auto path = _item._file;
        const auto slash_position = path.last_index_of ('/');
        const auto parent_path = slash_position >= 0 ? path.left (slash_position) : string ();
    
        if (!_item._rename_target.is_empty () && _item._file != _item._rename_target) {
            // Try to rename the file
            const auto original_file_path_absolute = propagator ().full_local_path (_item._file);
            const auto new_file_path_absolute = propagator ().full_local_path (_item._rename_target);
            const auto rename_success = QFile.rename (original_file_path_absolute, new_file_path_absolute);
            if (!rename_success) {
                done (SyncFileItem.Normal_error, "File contains trailing spaces and couldn't be renamed");
                return;
            }
            _item._file = _item._rename_target;
            _item._modtime = FileSystem.get_mod_time (new_file_path_absolute);
            Q_ASSERT (_item._modtime > 0);
            if (_item._modtime <= 0) {
                q_c_warning (lc_propagate_upload ()) << "invalid modified time" << _item._file << _item._modtime;
                slot_on_error_start_folder_unlock (SyncFileItem.Normal_error, tr ("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (_item._file)));
                return;
            }
        }
    
        SyncJournalFileRecord parent_rec;
        bool ok = propagator ()._journal.get_file_record (parent_path, &parent_rec);
        if (!ok) {
            done (SyncFileItem.Normal_error);
            return;
        }
    
        const auto account = propagator ().account ();
    
        if (!account.capabilities ().client_side_encryption_available () ||
            !parent_rec.is_valid () ||
            !parent_rec._is_e2e_encrypted) {
            setup_unencrypted_file ();
            return;
        }
    
        const auto remote_parent_path = parent_rec._e2e_mangled_name.is_empty () ? parent_path : parent_rec._e2e_mangled_name;
        _upload_encrypted_helper = new Propagate_upload_encrypted (propagator (), remote_parent_path, _item, this);
        connect (_upload_encrypted_helper, &Propagate_upload_encrypted.finalized,
                this, &Propagate_upload_file_common.setup_encrypted_file);
        connect (_upload_encrypted_helper, &Propagate_upload_encrypted.error, [this] {
            q_c_debug (lc_propagate_upload) << "Error setting up encryption.";
            done (SyncFileItem.Fatal_error, tr ("Failed to upload encrypted file."));
        });
        _upload_encrypted_helper.start ();
    }
    
    void Propagate_upload_file_common.setup_encrypted_file (string& path, string& filename, uint64 size) {
        q_c_debug (lc_propagate_upload) << "Starting to upload encrypted file" << path << filename << size;
        _uploading_encrypted = true;
        _file_to_upload._path = path;
        _file_to_upload._file = filename;
        _file_to_upload._size = size;
        start_upload_file ();
    }
    
    void Propagate_upload_file_common.setup_unencrypted_file () {
        _uploading_encrypted = false;
        _file_to_upload._file = _item._file;
        _file_to_upload._size = _item._size;
        _file_to_upload._path = propagator ().full_local_path (_file_to_upload._file);
        start_upload_file ();
    }
    
    void Propagate_upload_file_common.start_upload_file () {
        if (propagator ()._abort_requested) {
            return;
        }
    
        // Check if the specific file can be accessed
        if (propagator ().has_case_clash_accessibility_problem (_file_to_upload._file)) {
            done (SyncFileItem.Normal_error, tr ("File %1 cannot be uploaded because another file with the same name, differing only in case, exists").arg (QDir.to_native_separators (_item._file)));
            return;
        }
    
        // Check if we believe that the upload will fail due to remote quota limits
        const int64 quota_guess = propagator ()._folder_quota.value (
            QFileInfo (_file_to_upload._file).path (), std.numeric_limits<int64>.max ());
        if (_file_to_upload._size > quota_guess) {
            // Necessary for blacklisting logic
            _item._http_error_code = 507;
            emit propagator ().insufficient_remote_storage ();
            done (SyncFileItem.Detail_error, tr ("Upload of %1 exceeds the quota for the folder").arg (Utility.octets_to_string (_file_to_upload._size)));
            return;
        }
    
        propagator ()._active_job_list.append (this);
    
        if (!_delete_existing) {
            q_debug () << "Running the compute checksum";
            return slot_compute_content_checksum ();
        }
    
        q_debug () << "Deleting the current";
        auto job = new DeleteJob (propagator ().account (),
            propagator ().full_remote_path (_file_to_upload._file),
            this);
        _jobs.append (job);
        connect (job, &DeleteJob.finished_signal, this, &Propagate_upload_file_common.slot_compute_content_checksum);
        connect (job, &GLib.Object.destroyed, this, &Propagate_upload_file_common.slot_job_destroyed);
        job.start ();
    }
    
    void Propagate_upload_file_common.slot_compute_content_checksum () {
        q_debug () << "Trying to compute the checksum of the file";
        q_debug () << "Still trying to understand if this is the local file or the uploaded one";
        if (propagator ()._abort_requested) {
            return;
        }
    
        const string file_path = propagator ().full_local_path (_item._file);
    
        // remember the modtime before checksumming to be able to detect a file
        // change during the checksum calculation - This goes inside of the _item._file
        // and not the _file_to_upload because we are checking the original file, not there
        // probably temporary one.
        _item._modtime = FileSystem.get_mod_time (file_path);
        if (_item._modtime <= 0) {
            slot_on_error_start_folder_unlock (SyncFileItem.Normal_error, tr ("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (_item._file)));
            return;
        }
    
        const QByteArray checksum_type = propagator ().account ().capabilities ().preferred_upload_checksum_type ();
    
        // Maybe the discovery already computed the checksum?
        // Should I compute the checksum of the original (_item._file)
        // or the maybe-modified? (_file_to_upload._file) ?
    
        QByteArray existing_checksum_type, existing_checksum;
        parse_checksum_header (_item._checksum_header, &existing_checksum_type, &existing_checksum);
        if (existing_checksum_type == checksum_type) {
            slot_compute_transmission_checksum (checksum_type, existing_checksum);
            return;
        }
    
        // Compute the content checksum.
        auto compute_checksum = new ComputeChecksum (this);
        compute_checksum.set_checksum_type (checksum_type);
    
        connect (compute_checksum, &ComputeChecksum.done,
            this, &Propagate_upload_file_common.slot_compute_transmission_checksum);
        connect (compute_checksum, &ComputeChecksum.done,
            compute_checksum, &GLib.Object.delete_later);
        compute_checksum.start (_file_to_upload._path);
    }
    
    void Propagate_upload_file_common.slot_compute_transmission_checksum (QByteArray &content_checksum_type, QByteArray &content_checksum) {
        _item._checksum_header = make_checksum_header (content_checksum_type, content_checksum);
    
        // Reuse the content checksum as the transmission checksum if possible
        const auto supported_transmission_checksums =
            propagator ().account ().capabilities ().supported_checksum_types ();
        if (supported_transmission_checksums.contains (content_checksum_type)) {
            slot_start_upload (content_checksum_type, content_checksum);
            return;
        }
    
        // Compute the transmission checksum.
        auto compute_checksum = new ComputeChecksum (this);
        if (upload_checksum_enabled ()) {
            compute_checksum.set_checksum_type (propagator ().account ().capabilities ().upload_checksum_type ());
        } else {
            compute_checksum.set_checksum_type (QByteArray ());
        }
    
        connect (compute_checksum, &ComputeChecksum.done,
            this, &Propagate_upload_file_common.slot_start_upload);
        connect (compute_checksum, &ComputeChecksum.done,
            compute_checksum, &GLib.Object.delete_later);
        compute_checksum.start (_file_to_upload._path);
    }
    
    void Propagate_upload_file_common.slot_start_upload (QByteArray &transmission_checksum_type, QByteArray &transmission_checksum) {
        // Remove ourselfs from the list of active job, before any posible call to done ()
        // When we start chunks, we will add it again, once for every chunks.
        propagator ()._active_job_list.remove_one (this);
    
        _transmission_checksum_header = make_checksum_header (transmission_checksum_type, transmission_checksum);
    
        // If no checksum header was not set, reuse the transmission checksum as the content checksum.
        if (_item._checksum_header.is_empty ()) {
            _item._checksum_header = _transmission_checksum_header;
        }
    
        const string full_file_path = _file_to_upload._path;
        const string original_file_path = propagator ().full_local_path (_item._file);
    
        if (!FileSystem.file_exists (full_file_path)) {
            return slot_on_error_start_folder_unlock (SyncFileItem.Soft_error, tr ("File Removed (start upload) %1").arg (full_file_path));
        }
        if (_item._modtime <= 0) {
            slot_on_error_start_folder_unlock (SyncFileItem.Normal_error, tr ("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (_item._file)));
            return;
        }
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            q_c_warning (lc_propagate_upload ()) << "invalid modified time" << _item._file << _item._modtime;
        }
        time_t prev_modtime = _item._modtime; // the _item value was set in Propagate_upload_file.start ()
        // but a potential checksum calculation could have taken some time during which the file could
        // have been changed again, so better check again here.
    
        _item._modtime = FileSystem.get_mod_time (original_file_path);
        if (_item._modtime <= 0) {
            slot_on_error_start_folder_unlock (SyncFileItem.Normal_error, tr ("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.to_native_separators (_item._file)));
            return;
        }
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            q_c_warning (lc_propagate_upload ()) << "invalid modified time" << _item._file << _item._modtime;
        }
        if (prev_modtime != _item._modtime) {
            propagator ()._another_sync_needed = true;
            q_debug () << "prev_modtime" << prev_modtime << "Curr" << _item._modtime;
            return slot_on_error_start_folder_unlock (SyncFileItem.Soft_error, tr ("Local file changed during syncing. It will be resumed."));
        }
    
        _file_to_upload._size = FileSystem.get_size (full_file_path);
        _item._size = FileSystem.get_size (original_file_path);
    
        // But skip the file if the mtime is too close to 'now'!
        // That usually indicates a file that is still being changed
        // or not yet fully copied to the destination.
        if (file_is_still_changing (*_item)) {
            propagator ()._another_sync_needed = true;
            return slot_on_error_start_folder_unlock (SyncFileItem.Soft_error, tr ("Local file changed during sync."));
        }
    
        do_start_upload ();
    }
    
    void Propagate_upload_file_common.slot_folder_unlocked (QByteArray &folder_id, int http_return_code) {
        q_debug () << "Failed to unlock encrypted folder" << folder_id;
        if (_upload_status.status == SyncFileItem.No_status && http_return_code != 200) {
            done (SyncFileItem.Fatal_error, tr ("Failed to unlock encrypted folder."));
        } else {
            done (_upload_status.status, _upload_status.message);
        }
    }
    
    void Propagate_upload_file_common.slot_on_error_start_folder_unlock (SyncFileItem.Status status, string &error_string) {
        if (_uploading_encrypted) {
            _upload_status = { status, error_string };
            connect (_upload_encrypted_helper, &Propagate_upload_encrypted.folder_unlocked, this, &Propagate_upload_file_common.slot_folder_unlocked);
            _upload_encrypted_helper.unlock_folder ();
        } else {
            done (status, error_string);
        }
    }
    
    Upload_device.Upload_device (string &file_name, int64 start, int64 size, Bandwidth_manager *bwm)
        : _file (file_name)
        , _start (start)
        , _size (size)
        , _bandwidth_manager (bwm) {
        _bandwidth_manager.register_upload_device (this);
    }
    
    Upload_device.~Upload_device () {
        if (_bandwidth_manager) {
            _bandwidth_manager.unregister_upload_device (this);
        }
    }
    
    bool Upload_device.open (QIODevice.Open_mode mode) {
        if (mode & QIODevice.WriteOnly)
            return false;
    
        // Get the file size now : _file.file_name () is no longer reliable
        // on all platforms after open_and_seek_file_shared_read ().
        auto file_disk_size = FileSystem.get_size (_file.file_name ());
    
        string open_error;
        if (!FileSystem.open_and_seek_file_shared_read (&_file, &open_error, _start)) {
            set_error_string (open_error);
            return false;
        }
    
        _size = q_bound (0ll, _size, file_disk_size - _start);
        _read = 0;
    
        return QIODevice.open (mode);
    }
    
    void Upload_device.close () {
        _file.close ();
        QIODevice.close ();
    }
    
    int64 Upload_device.write_data (char *, int64) {
        ASSERT (false, "write to read only device");
        return 0;
    }
    
    int64 Upload_device.read_data (char *data, int64 maxlen) {
        if (_size - _read <= 0) {
            // at end
            if (_bandwidth_manager) {
                _bandwidth_manager.unregister_upload_device (this);
            }
            return -1;
        }
        maxlen = q_min (maxlen, _size - _read);
        if (maxlen <= 0) {
            return 0;
        }
        if (is_choked ()) {
            return 0;
        }
        if (is_bandwidth_limited ()) {
            maxlen = q_min (maxlen, _bandwidth_quota);
            if (maxlen <= 0) { // no quota
                return 0;
            }
            _bandwidth_quota -= maxlen;
        }
    
        auto c = _file.read (data, maxlen);
        if (c < 0) {
            set_error_string (_file.error_string ());
            return -1;
        }
        _read += c;
        return c;
    }
    
    void Upload_device.slot_job_upload_progress (int64 sent, int64 t) {
        if (sent == 0 || t == 0) {
            return;
        }
        _read_with_progress = sent;
    }
    
    bool Upload_device.at_end () {
        return _read >= _size;
    }
    
    int64 Upload_device.size () {
        return _size;
    }
    
    int64 Upload_device.bytes_available () {
        return _size - _read + QIODevice.bytes_available ();
    }
    
    // random access, we can seek
    bool Upload_device.is_sequential () {
        return false;
    }
    
    bool Upload_device.seek (int64 pos) {
        if (!QIODevice.seek (pos)) {
            return false;
        }
        if (pos < 0 || pos > _size) {
            return false;
        }
        _read = pos;
        _file.seek (_start + pos);
        return true;
    }
    
    void Upload_device.give_bandwidth_quota (int64 bwq) {
        if (!at_end ()) {
            _bandwidth_quota = bwq;
            QMetaObject.invoke_method (this, "ready_read", Qt.QueuedConnection); // tell QNAM that we have quota
        }
    }
    
    void Upload_device.set_bandwidth_limited (bool b) {
        _bandwidth_limited = b;
        QMetaObject.invoke_method (this, "ready_read", Qt.QueuedConnection);
    }
    
    void Upload_device.set_choked (bool b) {
        _choked = b;
        if (!_choked) {
            QMetaObject.invoke_method (this, "ready_read", Qt.QueuedConnection);
        }
    }
    
    void Propagate_upload_file_common.start_poll_job (string &path) {
        auto *job = new Poll_job (propagator ().account (), path, _item,
            propagator ()._journal, propagator ().local_path (), this);
        connect (job, &Poll_job.finished_signal, this, &Propagate_upload_file_common.slot_poll_finished);
        SyncJournalDb.Poll_info info;
        info._file = _item._file;
        info._url = path;
        info._modtime = _item._modtime;
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            q_c_warning (lc_propagate_upload ()) << "invalid modified time" << _item._file << _item._modtime;
        }
        info._file_size = _item._size;
        propagator ()._journal.set_poll_info (info);
        propagator ()._journal.commit ("add poll info");
        propagator ()._active_job_list.append (this);
        job.start ();
    }
    
    void Propagate_upload_file_common.slot_poll_finished () {
        auto *job = qobject_cast<Poll_job> (sender ());
        ASSERT (job);
    
        propagator ()._active_job_list.remove_one (this);
    
        if (job._item._status != SyncFileItem.Success) {
            done (job._item._status, job._item._error_string);
            return;
        }
    
        finalize ();
    }
    
    void Propagate_upload_file_common.done (SyncFileItem.Status status, string &error_string) {
        _finished = true;
        Propagate_item_job.done (status, error_string);
    }
    
    void Propagate_upload_file_common.check_resetting_errors () {
        if (_item._http_error_code == 412
            || propagator ().account ().capabilities ().http_error_codes_that_reset_failing_chunked_uploads ().contains (_item._http_error_code)) {
            auto upload_info = propagator ()._journal.get_upload_info (_item._file);
            upload_info._error_count += 1;
            if (upload_info._error_count > 3) {
                q_c_info (lc_propagate_upload) << "Reset transfer of" << _item._file
                                          << "due to repeated error" << _item._http_error_code;
                upload_info = SyncJournalDb.UploadInfo ();
            } else {
                q_c_info (lc_propagate_upload) << "Error count for maybe-reset error" << _item._http_error_code
                                          << "on file" << _item._file
                                          << "is" << upload_info._error_count;
            }
            propagator ()._journal.set_upload_info (_item._file, upload_info);
            propagator ()._journal.commit ("Upload info");
        }
    }
    
    void Propagate_upload_file_common.common_error_handling (AbstractNetworkJob *job) {
        QByteArray reply_content;
        string error_string = job.error_string_parsing_body (&reply_content);
        q_c_debug (lc_propagate_upload) << reply_content; // display the XML error in the debug
    
        if (_item._http_error_code == 412) {
            // Precondition Failed : Either an etag or a checksum mismatch.
    
            // Maybe the bad etag is in the database, we need to clear the
            // parent folder etag so we won't read from DB next sync.
            propagator ()._journal.schedule_path_for_remote_discovery (_item._file);
            propagator ()._another_sync_needed = true;
        }
    
        // Ensure errors that should eventually reset the chunked upload are tracked.
        check_resetting_errors ();
    
        SyncFileItem.Status status = classify_error (job.reply ().error (), _item._http_error_code,
            &propagator ()._another_sync_needed, reply_content);
    
        // Insufficient remote storage.
        if (_item._http_error_code == 507) {
            // Update the quota expectation
            /* store the quota for the real local file using the information
             * on the file to upload, that could have been modified by
             * filters or something. */
            const auto path = QFileInfo (_item._file).path ();
            auto quota_it = propagator ()._folder_quota.find (path);
            if (quota_it != propagator ()._folder_quota.end ()) {
                quota_it.value () = q_min (quota_it.value (), _file_to_upload._size - 1);
            } else {
                propagator ()._folder_quota[path] = _file_to_upload._size - 1;
            }
    
            // Set up the error
            status = SyncFileItem.Detail_error;
            error_string = tr ("Upload of %1 exceeds the quota for the folder").arg (Utility.octets_to_string (_file_to_upload._size));
            emit propagator ().insufficient_remote_storage ();
        }
    
        abort_with_error (status, error_string);
    }
    
    void Propagate_upload_file_common.adjust_last_job_timeout (AbstractNetworkJob *job, int64 file_size) {
        constexpr double three_minutes = 3.0 * 60 * 1000;
    
        job.set_timeout (q_bound (
            job.timeout_msec (),
            // Calculate 3 minutes for each gigabyte of data
            q_round64 (three_minutes * file_size / 1e9),
            // Maximum of 30 minutes
            static_cast<int64> (30 * 60 * 1000)));
    }
    
    void Propagate_upload_file_common.slot_job_destroyed (GLib.Object *job) {
        _jobs.erase (std.remove (_jobs.begin (), _jobs.end (), job), _jobs.end ());
    }
    
    // This function is used whenever there is an error occuring and jobs might be in progress
    void Propagate_upload_file_common.abort_with_error (SyncFileItem.Status status, string &error) {
        if (_aborting)
            return;
        abort (Abort_type.Synchronous);
        done (status, error);
    }
    
    QMap<QByteArray, QByteArray> Propagate_upload_file_common.headers () {
        QMap<QByteArray, QByteArray> headers;
        headers[QByteArrayLiteral ("Content-Type")] = QByteArrayLiteral ("application/octet-stream");
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            q_c_warning (lc_propagate_upload ()) << "invalid modified time" << _item._file << _item._modtime;
        }
        headers[QByteArrayLiteral ("X-OC-Mtime")] = QByteArray.number (int64 (_item._modtime));
        if (q_environment_variable_int_value ("OWNCLOUD_LAZYOPS"))
            headers[QByteArrayLiteral ("OC-Lazy_ops")] = QByteArrayLiteral ("true");
    
        if (_item._file.contains (QLatin1String (".sys.admin#recall#"))) {
            // This is a file recall triggered by the admin.  Note : the
            // recall list file created by the admin and downloaded by the
            // client (.sys.admin#recall#) also falls into this category
            // (albeit users are not supposed to mess up with it)
    
            // We use a special tag header so that the server may decide to store this file away in some admin stage area
            // And not directly in the user's area (which would trigger redownloads etc).
            headers["OC-Tag"] = ".sys.admin#recall#";
        }
    
        if (!_item._etag.is_empty () && _item._etag != "empty_etag"
            && _item._instruction != CSYNC_INSTRUCTION_NEW // On new files never send a If-Match
            && _item._instruction != CSYNC_INSTRUCTION_TYPE_CHANGE
            && !_delete_existing) {
            // We add quotes because the owncloud server always adds quotes around the etag, and
            //  csync_owncloud.c's owncloud_file_id always strips the quotes.
            headers[QByteArrayLiteral ("If-Match")] = '"' + _item._etag + '"';
        }
    
        // Set up a conflict file header pointing to the original file
        auto conflict_record = propagator ()._journal.conflict_record (_item._file.to_utf8 ());
        if (conflict_record.is_valid ()) {
            headers[QByteArrayLiteral ("OC-Conflict")] = "1";
            if (!conflict_record.initial_base_path.is_empty ())
                headers[QByteArrayLiteral ("OC-Conflict_initial_base_path")] = conflict_record.initial_base_path;
            if (!conflict_record.base_file_id.is_empty ())
                headers[QByteArrayLiteral ("OC-Conflict_base_file_id")] = conflict_record.base_file_id;
            if (conflict_record.base_modtime != -1)
                headers[QByteArrayLiteral ("OC-Conflict_base_mtime")] = QByteArray.number (conflict_record.base_modtime);
            if (!conflict_record.base_etag.is_empty ())
                headers[QByteArrayLiteral ("OC-Conflict_base_etag")] = conflict_record.base_etag;
        }
    
        if (_upload_encrypted_helper && !_upload_encrypted_helper.folder_token ().is_empty ()) {
            headers.insert ("e2e-token", _upload_encrypted_helper.folder_token ());
        }
    
        return headers;
    }
    
    void Propagate_upload_file_common.finalize () {
        // Update the quota, if known
        auto quota_it = propagator ()._folder_quota.find (QFileInfo (_item._file).path ());
        if (quota_it != propagator ()._folder_quota.end ())
            quota_it.value () -= _file_to_upload._size;
    
        // Update the database entry
        const auto result = propagator ().update_metadata (*_item);
        if (!result) {
            done (SyncFileItem.Fatal_error, tr ("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            done (SyncFileItem.Soft_error, tr ("The file %1 is currently in use").arg (_item._file));
            return;
        }
    
        // Files that were new on the remote shouldn't have online-only pin state
        // even if their parent folder is online-only.
        if (_item._instruction == CSYNC_INSTRUCTION_NEW
            || _item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE) {
            auto &vfs = propagator ().sync_options ()._vfs;
            const auto pin = vfs.pin_state (_item._file);
            if (pin && *pin == PinState.OnlineOnly) {
                if (!vfs.set_pin_state (_item._file, PinState.Unspecified)) {
                    q_c_warning (lc_propagate_upload) << "Could not set pin state of" << _item._file << "to unspecified";
                }
            }
        }
    
        // Remove from the progress database:
        propagator ()._journal.set_upload_info (_item._file, SyncJournalDb.UploadInfo ());
        propagator ()._journal.commit ("upload file start");
    
        if (_uploading_encrypted) {
            _upload_status = { SyncFileItem.Success, string () };
            connect (_upload_encrypted_helper, &Propagate_upload_encrypted.folder_unlocked, this, &Propagate_upload_file_common.slot_folder_unlocked);
            _upload_encrypted_helper.unlock_folder ();
        } else {
            done (SyncFileItem.Success);
        }
    }
    
    void Propagate_upload_file_common.abort_network_jobs (
        Propagator_job.Abort_type abort_type,
        const std.function<bool (AbstractNetworkJob *)> &may_abort_job) {
        if (_aborting)
            return;
        _aborting = true;
    
        // Count the number of jobs that need aborting, and emit the overall
        // abort signal when they're all done.
        QSharedPointer<int> running_count (new int (0));
        auto one_abort_finished = [this, running_count] () {
            (*running_count)--;
            if (*running_count == 0) {
                emit this.abort_finished ();
            }
        };
    
        // Abort all running jobs, except for explicitly excluded ones
        foreach (AbstractNetworkJob *job, _jobs) {
            auto reply = job.reply ();
            if (!reply || !reply.is_running ())
                continue;
    
            (*running_count)++;
    
            // If a job should not be aborted that means we'll never abort before
            // the hard abort timeout signal comes as running_count will never go to
            // zero.
            // We may however finish before that if the un-abortable job completes
            // normally.
            if (!may_abort_job (job))
                continue;
    
            // Abort the job
            if (abort_type == Abort_type.Asynchronous) {
                // Connect to finished signal of job reply to asynchonously finish the abort
                connect (reply, &QNetworkReply.finished, this, one_abort_finished);
            }
            reply.abort ();
        }
    
        if (*running_count == 0 && abort_type == Abort_type.Asynchronous)
            emit abort_finished ();
    }
    }
    