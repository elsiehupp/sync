/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <common/checksums.h>
// #include <common/asserts.h>
// #include <common/constants.h>

// #include <QLoggingCategory>
// #include <QNetworkAccessManager>
// #include <QFileInfo>
// #include <QDir>
// #include <cmath>

#ifdef Q_OS_UNIX
// #include <unistd.h>
#endif

// #pragma once

// #include <QBuffer>
// #include <GLib.File>

namespace Occ {

/***********************************************************
@brief The GETFileJob class
@ingroup libsync
***********************************************************/
class GETFileJob : AbstractNetworkJob {
    QIODevice _device;
    QMap<GLib.ByteArray, GLib.ByteArray> _headers;
    string _error_string;
    GLib.ByteArray _expected_etag_for_resume;
    int64 _expected_content_length;
    int64 _resume_start;
    SyncFileItem.Status _error_status;
    GLib.Uri _direct_download_url;
    GLib.ByteArray _etag;
    bool _bandwidth_limited; // if _bandwidth_quota will be used
    bool _bandwidth_choked; // if download is paused (won't read on ready_read ())
    int64 _bandwidth_quota;
    QPointer<BandwidthManager> _bandwidth_manager;
    bool _has_emitted_finished_signal;
    time_t _last_modified;

    /// Will be set to true once we've seen a 2xx response header
    bool _save_body_to_file = false;


    protected int64 _content_length;


    // DOES NOT take ownership of the device.
    public GETFileJob (AccountPointer account, string path, QIODevice device,
        const QMap<GLib.ByteArray, GLib.ByteArray> &headers, GLib.ByteArray expected_etag_for_resume,
        int64 resume_start, GLib.Object parent = new GLib.Object ());
    // For direct_download_url:
    public GETFileJob (AccountPointer account, GLib.Uri url, QIODevice device,
        const QMap<GLib.ByteArray, GLib.ByteArray> &headers, GLib.ByteArray expected_etag_for_resume,
        int64 resume_start, GLib.Object parent = new GLib.Object ());
    ~GETFileJob () override {
        if (_bandwidth_manager) {
            _bandwidth_manager.on_unregister_download_job (this);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override;
    public bool on_finished () override {
        if (_save_body_to_file && reply ().bytes_available ()) {
            return false;
        } else {
            if (_bandwidth_manager) {
                _bandwidth_manager.on_unregister_download_job (this);
            }
            if (!_has_emitted_finished_signal) {
                emit finished_signal ();
            }
            _has_emitted_finished_signal = true;
            return true; // discard
        }
    }


    /***********************************************************
    ***********************************************************/
    public void cancel ();

    /***********************************************************
    ***********************************************************/
    public void new_reply_hook (QNetworkReply reply) override;

    /***********************************************************
    ***********************************************************/
    public void set_bandwidth_manager (BandwidthManager bwm);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void set_bandwidth_limited (bool b);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public int64 current_download_position ();

    public string error_string () override;
    public void on_set_error_string (string s) {
        _error_string = s;
    }


    /***********************************************************
    ***********************************************************/
    public SyncFileItem.Status error_status () {
        return _error_status;
    }


    /***********************************************************
    ***********************************************************/
    public void set_error_status (SyncFileItem.Status &s) {
        _error_status = s;
    }


    /***********************************************************
    ***********************************************************/
    public void on_timed_out () override;

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray etag () {
        return _etag;
    }


    /***********************************************************
    ***********************************************************/
    public int64 resume_start () {
    }


    /***********************************************************
    ***********************************************************/
    public 
    public time_t last_modified () {
        return _last_modified;
    }


    /***********************************************************
    ***********************************************************/
    public int64 content_length () {
        return _content_length;
    }


    /***********************************************************
    ***********************************************************/
    public int64 expected_content_length () {
    }


    /***********************************************************
    ***********************************************************/
    public 
    public void set_expected_content_length (int64 size) {
        _expected_content_length = size;
    }


    protected virtual int64 write_to_device (GLib.ByteArray data);

signals:
    void finished_signal ();
    void download_progress (int64, int64);

    /***********************************************************
    ***********************************************************/
    private void on_ready_read ();
    private void on_meta_data_changed ();
};

/***********************************************************
@brief The GETEncrypted_file_job class that provides file decryption on the fly while the download is running
@ingroup libsync
***********************************************************/
class GETEncrypted_file_job : GETFileJob {

    // DOES NOT take ownership of the device.
    public GETEncrypted_file_job (AccountPointer account, string path, QIODevice device,
        const QMap<GLib.ByteArray, GLib.ByteArray> &headers, GLib.ByteArray expected_etag_for_resume,
        int64 resume_start, EncryptedFile encrypted_info, GLib.Object parent = new GLib.Object ());


    /***********************************************************
    ***********************************************************/
    public GETEncrypted_file_job (AccountPointer account, GLib.Uri url, QIODevice device,
        const QMap<GLib.ByteArray, GLib.ByteArray> &headers, GLib.ByteArray expected_etag_for_resume,
        int64 resume_start, EncryptedFile encrypted_info, GLib.Object parent = new GLib.Object ());
    ~GETEncrypted_file_job () override = default;


    protected int64 write_to_device (GLib.ByteArray data) override;


    /***********************************************************
    ***********************************************************/
    private unowned<EncryptionHelper.StreamingDecryptor> _decryptor;
    private EncryptedFile _encrypted_file_info = {};
    private GLib.ByteArray _pending_bytes;
    private int64 _processed_so_far = 0;
};

/***********************************************************
@brief The PropagateDownloadFile class
@ingroup libsync

This is the flow:

\code{.unparsed}
  on_start ()
    |
    | delete_existing_folder () if enabled
    |
    +-. mtime and size identical?
    |    then compute the local checksum
    |                               done?. conflict_checksum_computed ()
    |                                              |
    |                         checksum differs?    |
    +. start_download () <--------------------------+
          |                                        |
          +. run a GETFileJob                     | checksum identical?
                                                   |
      done?. on_get_finished ()                    |
                |                                  |
                +. validate checksum header       |
                                                   |
      done?. transmission_checksum_validated ()      |
                |                                  |
                +. compute the content checksum   |
                                                   |
      done?. content_checksum_computed ()            |
                |                                  |
                +. download_finished ()             |
                       |                           |
    +------------------+                           |
    |                                              |
    +. update_metadata () <-------------------------+

\endcode
***********************************************************/
class PropagateDownloadFile : PropagateItemJob {

    /***********************************************************
    ***********************************************************/
    public PropagateDownloadFile (OwncloudPropagator propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item)
        , _resume_start (0)
        , _download_progress (0)
        , _delete_existing (false) {
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override;
    public int64 committed_disk_space () override;

    // We think it might finish quickly because it is a small file.
    public bool is_likely_finished_quickly () override {
        return _item._size < propagator ().small_file_size ();
    }


    /***********************************************************
    Whether an existing folder with the same name may be deleted before
    the download.

    If it's a non-empty folder, it'll be renamed to a confl
    to preserve any non-synced content that may be inside.

    Default: false.
    ***********************************************************/
    public void set_delete_existing_folder (bool enabled);


    /// Called when ComputeChecksum on the local file finishes,
    /// maybe the local and remote checksums are identical?
    private on_ void conflict_checksum_computed (GLib.ByteArray checksum_type, GLib.ByteArray checksum);
    /// Called to on_start downloading the remote file
    private on_ void start_download ();
    /// Called when the GETFileJob finishes
    private void on_get_finished ();
    /// Called when the download's checksum header was validated
    private on_ void transmission_checksum_validated (GLib.ByteArray checksum_type, GLib.ByteArray checksum);
    /// Called when the download's checksum computation is done
    private on_ void content_checksum_computed (GLib.ByteArray checksum_type, GLib.ByteArray checksum);
    private on_ void download_finished ();
    /// Called when it's time to update the database metadata
    private void update_metadata (bool is_conflict);

    /***********************************************************
    ***********************************************************/
    private void on_abort (PropagatorJob.AbortType abort_type) override;
    private void on_download_progress (int64, int64);
    private void on_checksum_fail (string error_message);


    /***********************************************************
    ***********************************************************/
    private void start_after_is_encrypted_is_checked ();

    /***********************************************************
    ***********************************************************/
    private 
    private int64 _resume_start;
    private int64 _download_progress;
    private QPointer<GETFileJob> _job;
    private GLib.File _tmp_file;
    private bool _delete_existing;
    private bool _is_encrypted = false;
    private EncryptedFile _encrypted_info;
    private ConflictRecord _conflict_record;

    /***********************************************************
    ***********************************************************/
    private QElapsedTimer _stopwatch;

    /***********************************************************
    ***********************************************************/
    private Propagate_download_encrypted _download_encrypted_helper = nullptr;
};

// Always coming in with forward slashes.
// In csync_excluded_no_ctx we ignore all files with longer than 254 chars
// This function also adds a dot at the beginning of the filename to hide the file on OS X and Linux
string create_download_tmp_file_name (string previous) {
    string tmp_file_name;
    string tmp_path;
    int slash_pos = previous.last_index_of ('/');
    // work with both pathed filenames and only filenames
    if (slash_pos == -1) {
        tmp_file_name = previous;
        tmp_path = "";
    } else {
        tmp_file_name = previous.mid (slash_pos + 1);
        tmp_path = previous.left (slash_pos);
    }
    int overhead = 1 + 1 + 2 + 8; // slash dot dot-tilde ffffffff"
    int space_for_file_name = q_min (254, tmp_file_name.length () + overhead) - overhead;
    if (tmp_path.length () > 0) {
        return tmp_path + '/' + '.' + tmp_file_name.left (space_for_file_name) + ".~" + (string.number (uint32 (Utility.rand () % 0x_f_f_f_f_f_f_f_f), 16));
    } else {
        return '.' + tmp_file_name.left (space_for_file_name) + ".~" + (string.number (uint32 (Utility.rand () % 0x_f_f_f_f_f_f_f_f), 16));
    }
}

// DOES NOT take ownership of the device.
GETFileJob.GETFileJob (AccountPointer account, string path, QIODevice device,
    const QMap<GLib.ByteArray, GLib.ByteArray> &headers, GLib.ByteArray expected_etag_for_resume,
    int64 resume_start, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent)
    , _device (device)
    , _headers (headers)
    , _expected_etag_for_resume (expected_etag_for_resume)
    , _expected_content_length (-1)
    , _resume_start (resume_start)
    , _error_status (SyncFileItem.NoStatus)
    , _bandwidth_limited (false)
    , _bandwidth_choked (false)
    , _bandwidth_quota (0)
    , _bandwidth_manager (nullptr)
    , _has_emitted_finished_signal (false)
    , _last_modified ()
    , _content_length (-1) {
}

GETFileJob.GETFileJob (AccountPointer account, GLib.Uri url, QIODevice device,
    const QMap<GLib.ByteArray, GLib.ByteArray> &headers, GLib.ByteArray expected_etag_for_resume,
    int64 resume_start, GLib.Object parent)
    : AbstractNetworkJob (account, url.to_encoded (), parent)
    , _device (device)
    , _headers (headers)
    , _expected_etag_for_resume (expected_etag_for_resume)
    , _expected_content_length (-1)
    , _resume_start (resume_start)
    , _error_status (SyncFileItem.NoStatus)
    , _direct_download_url (url)
    , _bandwidth_limited (false)
    , _bandwidth_choked (false)
    , _bandwidth_quota (0)
    , _bandwidth_manager (nullptr)
    , _has_emitted_finished_signal (false)
    , _last_modified ()
    , _content_length (-1) {
}

void GETFileJob.on_start () {
    if (_resume_start > 0) {
        _headers["Range"] = "bytes=" + GLib.ByteArray.number (_resume_start) + '-';
        _headers["Accept-Ranges"] = "bytes";
        GLib.debug (lc_get_job) << "Retry with range " << _headers["Range"];
    }

    QNetworkRequest req;
    for (QMap<GLib.ByteArray, GLib.ByteArray>.Const_iterator it = _headers.begin (); it != _headers.end (); ++it) {
        req.set_raw_header (it.key (), it.value ());
    }

    req.set_priority (QNetworkRequest.Low_priority); // Long downloads must not block non-propagation jobs.

    if (_direct_download_url.is_empty ()) {
        send_request ("GET", make_dav_url (path ()), req);
    } else {
        // Use direct URL
        send_request ("GET", _direct_download_url, req);
    }

    GLib.debug (lc_get_job) << _bandwidth_manager << _bandwidth_choked << _bandwidth_limited;
    if (_bandwidth_manager) {
        _bandwidth_manager.on_register_download_job (this);
    }

    connect (this, &AbstractNetworkJob.network_activity, account ().data (), &Account.propagator_network_activity);

    AbstractNetworkJob.on_start ();
}

void GETFileJob.new_reply_hook (QNetworkReply reply) {
    reply.set_read_buffer_size (16 * 1024); // keep low so we can easier limit the bandwidth

    connect (reply, &QNetworkReply.meta_data_changed, this, &GETFileJob.on_meta_data_changed);
    connect (reply, &QIODevice.ready_read, this, &GETFileJob.on_ready_read);
    connect (reply, &QNetworkReply.on_finished, this, &GETFileJob.on_ready_read);
    connect (reply, &QNetworkReply.download_progress, this, &GETFileJob.download_progress);
}

void GETFileJob.on_meta_data_changed () {
    // For some reason setting the read buffer in GETFileJob.on_start doesn't seem to go
    // through the HTTP layer thread (?)
    reply ().set_read_buffer_size (16 * 1024);

    int http_status = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    if (http_status == 301 || http_status == 302 || http_status == 303 || http_status == 307
        || http_status == 308 || http_status == 401) {
        // Redirects and auth failures (oauth token renew) are handled by AbstractNetworkJob and
        // will end up restarting the job. We do not want to process further data from the initial
        // request. new_reply_hook () will reestablish signal connections for the follow-up request.
        bool ok = disconnect (reply (), &QNetworkReply.on_finished, this, &GETFileJob.on_ready_read)
            && disconnect (reply (), &QNetworkReply.ready_read, this, &GETFileJob.on_ready_read);
        ASSERT (ok);
        return;
    }

    // If the status code isn't 2xx, don't write the reply body to the file.
    // For any error : handle it when the job is on_finished, not here.
    if (http_status / 100 != 2) {
        // Disable the buffer limit, as we don't limit the bandwidth for error messages.
        // (We are only going to do a read_all () at the end.)
        reply ().set_read_buffer_size (0);
        return;
    }
    if (reply ().error () != QNetworkReply.NoError) {
        return;
    }
    _etag = get_etag_from_reply (reply ());

    if (!_direct_download_url.is_empty () && !_etag.is_empty ()) {
        q_c_info (lc_get_job) << "Direct download used, ignoring server ETag" << _etag;
        _etag = GLib.ByteArray (); // reset received ETag
    } else if (!_direct_download_url.is_empty ()) {
        // All fine, ETag empty and direct_download_url used
    } else if (_etag.is_empty ()) {
        GLib.warn (lc_get_job) << "No E-Tag reply by server, considering it invalid";
        _error_string = _("No E-Tag received from server, check Proxy/Gateway");
        _error_status = SyncFileItem.NormalError;
        reply ().on_abort ();
        return;
    } else if (!_expected_etag_for_resume.is_empty () && _expected_etag_for_resume != _etag) {
        GLib.warn (lc_get_job) << "We received a different E-Tag for resuming!"
                            << _expected_etag_for_resume << "vs" << _etag;
        _error_string = _("We received a different E-Tag for resuming. Retrying next time.");
        _error_status = SyncFileItem.NormalError;
        reply ().on_abort ();
        return;
    }

    bool ok = false;
    _content_length = reply ().header (QNetworkRequest.ContentLengthHeader).to_long_long (&ok);
    if (ok && _expected_content_length != -1 && _content_length != _expected_content_length) {
        GLib.warn (lc_get_job) << "We received a different content length than expected!"
                            << _expected_content_length << "vs" << _content_length;
        _error_string = _("We received an unexpected download Content-Length.");
        _error_status = SyncFileItem.NormalError;
        reply ().on_abort ();
        return;
    }

    int64 on_start = 0;
    GLib.ByteArray ranges = reply ().raw_header ("Content-Range");
    if (!ranges.is_empty ()) {
        const QRegularExpression rx ("bytes (\\d+)-");
        const var rx_match = rx.match (ranges);
        if (rx_match.has_match ()) {
            on_start = rx_match.captured (1).to_long_long ();
        }
    }
    if (on_start != _resume_start) {
        GLib.warn (lc_get_job) << "Wrong content-range : " << ranges << " while expecting on_start was" << _resume_start;
        if (ranges.is_empty ()) {
            // device doesn't support range, just try again from scratch
            _device.close ();
            if (!_device.open (QIODevice.WriteOnly)) {
                _error_string = _device.error_string ();
                _error_status = SyncFileItem.NormalError;
                reply ().on_abort ();
                return;
            }
            _resume_start = 0;
        } else {
            _error_string = _("Server returned wrong content-range");
            _error_status = SyncFileItem.NormalError;
            reply ().on_abort ();
            return;
        }
    }

    var last_modified = reply ().header (QNetworkRequest.Last_modified_header);
    if (!last_modified.is_null ()) {
        _last_modified = Utility.q_date_time_to_time_t (last_modified.to_date_time ());
    }

    _save_body_to_file = true;
}

void GETFileJob.set_bandwidth_manager (BandwidthManager bwm) {
    _bandwidth_manager = bwm;
}

void GETFileJob.set_choked (bool c) {
    _bandwidth_choked = c;
    QMetaObject.invoke_method (this, "on_ready_read", Qt.QueuedConnection);
}

void GETFileJob.set_bandwidth_limited (bool b) {
    _bandwidth_limited = b;
    QMetaObject.invoke_method (this, "on_ready_read", Qt.QueuedConnection);
}

void GETFileJob.give_bandwidth_quota (int64 q) {
    _bandwidth_quota = q;
    GLib.debug (lc_get_job) << "Got" << q << "bytes";
    QMetaObject.invoke_method (this, "on_ready_read", Qt.QueuedConnection);
}

int64 GETFileJob.current_download_position () {
    if (_device && _device.pos () > 0 && _device.pos () > int64 (_resume_start)) {
        return _device.pos ();
    }
    return _resume_start;
}

int64 GETFileJob.write_to_device (GLib.ByteArray data) {
    return _device.write (data);
}

void GETFileJob.on_ready_read () {
    if (!reply ())
        return;
    int buffer_size = q_min (1024 * 8ll, reply ().bytes_available ());
    GLib.ByteArray buffer (buffer_size, Qt.Uninitialized);

    while (reply ().bytes_available () > 0 && _save_body_to_file) {
        if (_bandwidth_choked) {
            GLib.warn (lc_get_job) << "Download choked";
            break;
        }
        int64 to_read = buffer_size;
        if (_bandwidth_limited) {
            to_read = q_min (int64 (buffer_size), _bandwidth_quota);
            if (to_read == 0) {
                GLib.warn (lc_get_job) << "Out of quota";
                break;
            }
            _bandwidth_quota -= to_read;
        }

        const int64 read_bytes = reply ().read (buffer.data (), to_read);
        if (read_bytes < 0) {
            _error_string = network_reply_error_string (*reply ());
            _error_status = SyncFileItem.NormalError;
            GLib.warn (lc_get_job) << "Error while reading from device : " << _error_string;
            reply ().on_abort ();
            return;
        }

        const int64 written_bytes = write_to_device (GLib.ByteArray.from_raw_data (buffer.const_data (), read_bytes));
        if (written_bytes != read_bytes) {
            _error_string = _device.error_string ();
            _error_status = SyncFileItem.NormalError;
            GLib.warn (lc_get_job) << "Error while writing to file" << written_bytes << read_bytes << _error_string;
            reply ().on_abort ();
            return;
        }
    }

    if (reply ().is_finished () && (reply ().bytes_available () == 0 || !_save_body_to_file)) {
        GLib.debug (lc_get_job) << "Actually on_finished!";
        if (_bandwidth_manager) {
            _bandwidth_manager.on_unregister_download_job (this);
        }
        if (!_has_emitted_finished_signal) {
            q_c_info (lc_get_job) << "GET of" << reply ().request ().url ().to_"" << "FINISHED WITH STATUS"
                             << reply_status_""
                             << reply ().raw_header ("Content-Range") << reply ().raw_header ("Content-Length");

            emit finished_signal ();
        }
        _has_emitted_finished_signal = true;
        delete_later ();
    }
}

void GETFileJob.cancel () {
    const var network_reply = reply ();
    if (network_reply && network_reply.is_running ()) {
        network_reply.on_abort ();
    }
    if (_device && _device.is_open ()) {
        _device.close ();
    }
}

void GETFileJob.on_timed_out () {
    GLib.warn (lc_get_job) << "Timeout" << (reply () ? reply ().request ().url () : path ());
    if (!reply ())
        return;
    _error_string = _("Connection Timeout");
    _error_status = SyncFileItem.FatalError;
    reply ().on_abort ();
}

string GETFileJob.error_string () {
    if (!_error_string.is_empty ()) {
        return _error_string;
    }
    return AbstractNetworkJob.error_string ();
}

GETEncrypted_file_job.GETEncrypted_file_job (AccountPointer account, string path, QIODevice device,
    const QMap<GLib.ByteArray, GLib.ByteArray> &headers, GLib.ByteArray expected_etag_for_resume,
    int64 resume_start, EncryptedFile encrypted_info, GLib.Object parent)
    : GETFileJob (account, path, device, headers, expected_etag_for_resume, resume_start, parent)
    , _encrypted_file_info (encrypted_info) {
}

GETEncrypted_file_job.GETEncrypted_file_job (AccountPointer account, GLib.Uri url, QIODevice device,
    const QMap<GLib.ByteArray, GLib.ByteArray> &headers, GLib.ByteArray expected_etag_for_resume,
    int64 resume_start, EncryptedFile encrypted_info, GLib.Object parent)
    : GETFileJob (account, url, device, headers, expected_etag_for_resume, resume_start, parent)
    , _encrypted_file_info (encrypted_info) {
}

int64 GETEncrypted_file_job.write_to_device (GLib.ByteArray data) {
    if (!_decryptor) {
        // only initialize the decryptor once, because, according to Qt documentation, metadata might get changed during the processing of the data sometimes
        // https://doc.qt.io/qt-5/qnetworkreply.html#meta_data_changed
        _decryptor.on_reset (new EncryptionHelper.StreamingDecryptor (_encrypted_file_info.encryption_key, _encrypted_file_info.initialization_vector, _content_length));
    }

    if (!_decryptor.is_initialized ()) {
        return -1;
    }

    const var bytes_remaining = _content_length - _processed_so_far - data.length ();

    if (bytes_remaining != 0 && bytes_remaining < Occ.Constants.E2EE_TAG_SIZE) {
        // decryption is going to fail if last chunk does not include or does not equal to Occ.Constants.E2EE_TAG_SIZE bytes tag
        // we may end up receiving packets beyond Occ.Constants.E2EE_TAG_SIZE bytes tag at the end
        // in that case, we don't want to try and decrypt less than Occ.Constants.E2EE_TAG_SIZE ending bytes of tag, we will accumulate all the incoming data till the end
        // and then, we are going to decrypt the entire chunk containing Occ.Constants.E2EE_TAG_SIZE bytes at the end
        _pending_bytes += GLib.ByteArray (data.const_data (), data.length ());
        _processed_so_far += data.length ();
        if (_processed_so_far != _content_length) {
            return data.length ();
        }
    }

    if (!_pending_bytes.is_empty ()) {
        const var decrypted_chunk = _decryptor.chunk_decryption (_pending_bytes.const_data (), _pending_bytes.size ());

        if (decrypted_chunk.is_empty ()) {
            q_c_critical (lc_propagate_download) << "Decryption failed!";
            return -1;
        }

        GETFileJob.write_to_device (decrypted_chunk);

        return data.length ();
    }

    const var decrypted_chunk = _decryptor.chunk_decryption (data.const_data (), data.length ());

    if (decrypted_chunk.is_empty ()) {
        q_c_critical (lc_propagate_download) << "Decryption failed!";
        return -1;
    }

    GETFileJob.write_to_device (decrypted_chunk);

    _processed_so_far += data.length ();

    return data.length ();
}

void PropagateDownloadFile.on_start () {
    if (propagator ()._abort_requested)
        return;
    _is_encrypted = false;

    GLib.debug (lc_propagate_download) << _item._file << propagator ()._active_job_list.count ();

    const var path = _item._file;
    const var slash_position = path.last_index_of ('/');
    const var parent_path = slash_position >= 0 ? path.left (slash_position) : "";

    SyncJournalFileRecord parent_rec;
    propagator ()._journal.get_file_record (parent_path, &parent_rec);

    const var account = propagator ().account ();
    if (!account.capabilities ().client_side_encryption_available () ||
        !parent_rec.is_valid () ||
        !parent_rec._is_e2e_encrypted) {
        start_after_is_encrypted_is_checked ();
    } else {
        _download_encrypted_helper = new Propagate_download_encrypted (propagator (), parent_path, _item, this);
        connect (_download_encrypted_helper, &Propagate_download_encrypted.file_metadata_found, [this] {
          _is_encrypted = true;
          start_after_is_encrypted_is_checked ();
        });
        connect (_download_encrypted_helper, &Propagate_download_encrypted.failed, [this] {
          on_done (SyncFileItem.NormalError,
               _("File %1 cannot be downloaded because encryption information is missing.").arg (QDir.to_native_separators (_item._file)));
        });
        _download_encrypted_helper.on_start ();
    }
}

void PropagateDownloadFile.start_after_is_encrypted_is_checked () {
    _stopwatch.on_start ();

    var &sync_options = propagator ().sync_options ();
    var &vfs = sync_options._vfs;

    // For virtual files just dehydrate or create the file and be done
    if (_item._type == ItemTypeVirtualFileDehydration) {
        string fs_path = propagator ().full_local_path (_item._file);
        if (!FileSystem.verify_file_unchanged (fs_path, _item._previous_size, _item._previous_modtime)) {
            propagator ()._another_sync_needed = true;
            on_done (SyncFileItem.SoftError, _("File has changed since discovery"));
            return;
        }

        GLib.debug (lc_propagate_download) << "dehydrating file" << _item._file;
        var r = vfs.dehydrate_placeholder (*_item);
        if (!r) {
            on_done (SyncFileItem.NormalError, r.error ());
            return;
        }
        propagator ()._journal.delete_file_record (_item._original_file);
        update_metadata (false);

        if (!_item._remote_perm.is_null () && !_item._remote_perm.has_permission (RemotePermissions.Can_write)) {
            // make sure ReadOnly flag is preserved for placeholder, similarly to regular files
            FileSystem.set_file_read_only (propagator ().full_local_path (_item._file), true);
        }

        return;
    }
    if (vfs.mode () == Vfs.Off && _item._type == ItemTypeVirtualFile) {
        GLib.warn (lc_propagate_download) << "ignored virtual file type of" << _item._file;
        _item._type = ItemTypeFile;
    }
    if (_item._type == ItemTypeVirtualFile) {
        if (propagator ().local_file_name_clash (_item._file)) {
            on_done (SyncFileItem.NormalError, _("File %1 cannot be downloaded because of a local file name clash!").arg (QDir.to_native_separators (_item._file)));
            return;
        }

        GLib.debug (lc_propagate_download) << "creating virtual file" << _item._file;
        // do a klaas' case clash check.
        if (propagator ().local_file_name_clash (_item._file)) {
            on_done (SyncFileItem.NormalError, _("File %1 can not be downloaded because of a local file name clash!").arg (QDir.to_native_separators (_item._file)));
            return;
        }
        var r = vfs.create_placeholder (*_item);
        if (!r) {
            on_done (SyncFileItem.NormalError, r.error ());
            return;
        }
        update_metadata (false);

        if (!_item._remote_perm.is_null () && !_item._remote_perm.has_permission (RemotePermissions.Can_write)) {
            // make sure ReadOnly flag is preserved for placeholder, similarly to regular files
            FileSystem.set_file_read_only (propagator ().full_local_path (_item._file), true);
        }

        return;
    }

    if (_delete_existing) {
        delete_existing_folder ();

        // check for error with deletion
        if (_state == Finished) {
            return;
        }
    }

    // If we have a conflict where size of the file is unchanged,
    // compare the remote checksum to the local one.
    // Maybe it's not a real conflict and no download is necessary!
    // If the hashes are collision safe and identical, we assume the content is too.
    // For weak checksums, we only do that if the mtimes are also identical.

    const var csync_is_collision_safe_hash = [] (GLib.ByteArray checksum_header) {
        return checksum_header.starts_with ("SHA")
            || checksum_header.starts_with ("MD5:");
    };
    Q_ASSERT (_item._modtime > 0);
    if (_item._modtime <= 0) {
        GLib.warn (lc_propagate_download ()) << "invalid modified time" << _item._file << _item._modtime;
    }
    if (_item._instruction == CSYNC_INSTRUCTION_CONFLICT
        && _item._size == _item._previous_size
        && !_item._checksum_header.is_empty ()
        && (csync_is_collision_safe_hash (_item._checksum_header)
            || _item._modtime == _item._previous_modtime)) {
        GLib.debug (lc_propagate_download) << _item._file << "may not need download, computing checksum";
        var compute_checksum = new ComputeChecksum (this);
        compute_checksum.set_checksum_type (parse_checksum_header_type (_item._checksum_header));
        connect (compute_checksum, &ComputeChecksum.done,
            this, &PropagateDownloadFile.conflict_checksum_computed);
        propagator ()._active_job_list.append (this);
        compute_checksum.on_start (propagator ().full_local_path (_item._file));
        return;
    }

    start_download ();
}

void PropagateDownloadFile.conflict_checksum_computed (GLib.ByteArray checksum_type, GLib.ByteArray checksum) {
    propagator ()._active_job_list.remove_one (this);
    if (make_checksum_header (checksum_type, checksum) == _item._checksum_header) {
        // No download necessary, just update fs and journal metadata
        GLib.debug (lc_propagate_download) << _item._file << "remote and local checksum match";

        // Apply the server mtime locally if necessary, ensuring the journal
        // and local mtimes end up identical
        var fn = propagator ().full_local_path (_item._file);
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            GLib.warn (lc_propagate_download ()) << "invalid modified time" << _item._file << _item._modtime;
            return;
        }
        if (_item._modtime != _item._previous_modtime) {
            Q_ASSERT (_item._modtime > 0);
            FileSystem.set_mod_time (fn, _item._modtime);
            emit propagator ().touched_file (fn);
        }
        _item._modtime = FileSystem.get_mod_time (fn);
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            GLib.warn (lc_propagate_download ()) << "invalid modified time" << _item._file << _item._modtime;
            return;
        }
        update_metadata (/*is_conflict=*/false);
        return;
    }
    start_download ();
}

void PropagateDownloadFile.start_download () {
    if (propagator ()._abort_requested)
        return;

    // do a klaas' case clash check.
    if (propagator ().local_file_name_clash (_item._file)) {
        on_done (SyncFileItem.NormalError, _("File %1 cannot be downloaded because of a local file name clash!").arg (QDir.to_native_separators (_item._file)));
        return;
    }

    propagator ().report_progress (*_item, 0);

    string tmp_file_name;
    GLib.ByteArray expected_etag_for_resume;
    const SyncJournalDb.DownloadInfo progress_info = propagator ()._journal.get_download_info (_item._file);
    if (progress_info._valid) {
        // if the etag has changed meanwhile, remove the already downloaded part.
        if (progress_info._etag != _item._etag) {
            FileSystem.remove (propagator ().full_local_path (progress_info._tmpfile));
            propagator ()._journal.set_download_info (_item._file, SyncJournalDb.DownloadInfo ());
        } else {
            tmp_file_name = progress_info._tmpfile;
            expected_etag_for_resume = progress_info._etag;
        }
    }

    if (tmp_file_name.is_empty ()) {
        tmp_file_name = create_download_tmp_file_name (_item._file);
    }
    _tmp_file.set_file_name (propagator ().full_local_path (tmp_file_name));

    _resume_start = _tmp_file.size ();
    if (_resume_start > 0 && _resume_start == _item._size) {
        q_c_info (lc_propagate_download) << "File is already complete, no need to download";
        download_finished ();
        return;
    }

    // Can't open (Append) read-only files, make sure to make
    // file writable if it exists.
    if (_tmp_file.exists ())
        FileSystem.set_file_read_only (_tmp_file.file_name (), false);
    if (!_tmp_file.open (QIODevice.Append | QIODevice.Unbuffered)) {
        GLib.warn (lc_propagate_download) << "could not open temporary file" << _tmp_file.file_name ();
        on_done (SyncFileItem.NormalError, _tmp_file.error_string ());
        return;
    }
    // Hide temporary after creation
    FileSystem.set_file_hidden (_tmp_file.file_name (), true);

    // If there's not enough space to fully download this file, stop.
    const var disk_space_result = propagator ().disk_space_check ();
    if (disk_space_result != OwncloudPropagator.DiskSpaceOk) {
        if (disk_space_result == OwncloudPropagator.DiskSpaceFailure) {
            // Using DetailError here will make the error not pop up in the account
            // tab : instead we'll generate a general "disk space low" message and show
            // these detail errors only in the error view.
            on_done (SyncFileItem.DetailError,
                _("The download would reduce free local disk space below the limit"));
            emit propagator ().insufficient_local_storage ();
        } else if (disk_space_result == OwncloudPropagator.DiskSpaceCritical) {
            on_done (SyncFileItem.FatalError,
                _("Free space on disk is less than %1").arg (Utility.octets_to_string (critical_free_space_limit ())));
        }

        // Remove the temporary, if empty.
        if (_resume_start == 0) {
            _tmp_file.remove ();
        }

        return;
    }
 {
        SyncJournalDb.DownloadInfo pi;
        pi._etag = _item._etag;
        pi._tmpfile = tmp_file_name;
        pi._valid = true;
        propagator ()._journal.set_download_info (_item._file, pi);
        propagator ()._journal.commit ("download file on_start");
    }

    QMap<GLib.ByteArray, GLib.ByteArray> headers;

    if (_item._direct_download_url.is_empty ()) {
        // Normal job, download from o_c instance
        _job = new GETFileJob (propagator ().account (),
            propagator ().full_remote_path (_is_encrypted ? _item._encrypted_file_name : _item._file),
            &_tmp_file, headers, expected_etag_for_resume, _resume_start, this);
    } else {
        // We were provided a direct URL, use that one
        q_c_info (lc_propagate_download) << "direct_download_url given for " << _item._file << _item._direct_download_url;

        if (!_item._direct_download_cookies.is_empty ()) {
            headers["Cookie"] = _item._direct_download_cookies.to_utf8 ();
        }

        GLib.Uri url = GLib.Uri.from_user_input (_item._direct_download_url);
        _job = new GETFileJob (propagator ().account (),
            url,
            &_tmp_file, headers, expected_etag_for_resume, _resume_start, this);
    }
    _job.set_bandwidth_manager (&propagator ()._bandwidth_manager);
    connect (_job.data (), &GETFileJob.finished_signal, this, &PropagateDownloadFile.on_get_finished);
    connect (_job.data (), &GETFileJob.download_progress, this, &PropagateDownloadFile.on_download_progress);
    propagator ()._active_job_list.append (this);
    _job.on_start ();
}

int64 PropagateDownloadFile.committed_disk_space () {
    if (_state == Running) {
        return q_bound (0LL, _item._size - _resume_start - _download_progress, _item._size);
    }
    return 0;
}

void PropagateDownloadFile.set_delete_existing_folder (bool enabled) {
    _delete_existing = enabled;
}

const char owncloud_custom_soft_error_string_c[] = "owncloud-custom-soft-error-string";
void PropagateDownloadFile.on_get_finished () {
    propagator ()._active_job_list.remove_one (this);

    GETFileJob job = _job;
    ASSERT (job);

    _item._http_error_code = job.reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    _item._request_id = job.request_id ();

    QNetworkReply.NetworkError err = job.reply ().error ();
    if (err != QNetworkReply.NoError) {
        // If we sent a 'Range' header and get 416 back, we want to retry
        // without the header.
        const bool bad_range_header = job.resume_start () > 0 && _item._http_error_code == 416;
        if (bad_range_header) {
            GLib.warn (lc_propagate_download) << "server replied 416 to our range request, trying again without";
            propagator ()._another_sync_needed = true;
        }

        // Getting a 404 probably means that the file was deleted on the server.
        const bool file_not_found = _item._http_error_code == 404;
        if (file_not_found) {
            GLib.warn (lc_propagate_download) << "server replied 404, assuming file was deleted";
        }

        // Getting a 423 means that the file is locked
        const bool file_locked = _item._http_error_code == 423;
        if (file_locked) {
            GLib.warn (lc_propagate_download) << "server replied 423, file is Locked";
        }

        // Don't keep the temporary file if it is empty or we
        // used a bad range header or the file's not on the server anymore.
        if (_tmp_file.exists () && (_tmp_file.size () == 0 || bad_range_header || file_not_found)) {
            _tmp_file.close ();
            FileSystem.remove (_tmp_file.file_name ());
            propagator ()._journal.set_download_info (_item._file, SyncJournalDb.DownloadInfo ());
        }

        if (!_item._direct_download_url.is_empty () && err != QNetworkReply.OperationCanceledError) {
            // If this was with a direct download, retry without direct download
            GLib.warn (lc_propagate_download) << "Direct download of" << _item._direct_download_url << "failed. Retrying through owncloud.";
            _item._direct_download_url.clear ();
            on_start ();
            return;
        }

        // This gives a custom QNAM (by the user of libowncloudsync) to on_abort () a QNetworkReply in its meta_data_changed () slot and
        // set a custom error string to make this a soft error. In contrast to the default hard error this won't bring down
        // the whole sync and allows for a custom error message.
        QNetworkReply reply = job.reply ();
        if (err == QNetworkReply.OperationCanceledError && reply.property (owncloud_custom_soft_error_string_c).is_valid ()) {
            job.on_set_error_string (reply.property (owncloud_custom_soft_error_string_c).to_"");
            job.set_error_status (SyncFileItem.SoftError);
        } else if (bad_range_header) {
            // Can't do this in classify_error () because 416 without a
            // Range header should result in NormalError.
            job.set_error_status (SyncFileItem.SoftError);
        } else if (file_not_found) {
            job.on_set_error_string (_("File was deleted from server"));
            job.set_error_status (SyncFileItem.SoftError);

            // As a precaution against bugs that cause our database and the
            // reality on the server to diverge, rediscover this folder on the
            // next sync run.
            propagator ()._journal.schedule_path_for_remote_discovery (_item._file);
        }

        GLib.ByteArray error_body;
        string error_string = _item._http_error_code >= 400 ? job.error_string_parsing_body (&error_body)
                                                           : job.error_string ();
        SyncFileItem.Status status = job.error_status ();
        if (status == SyncFileItem.NoStatus) {
            status = classify_error (err, _item._http_error_code,
                &propagator ()._another_sync_needed, error_body);
        }

        on_done (status, error_string);
        return;
    }

    _item._response_time_stamp = job.response_timestamp ();

    if (!job.etag ().is_empty ()) {
        // The etag will be empty if we used a direct download URL.
        // (If it was really empty by the server, the GETFileJob will have errored
        _item._etag = parse_etag (job.etag ());
    }
    if (job.last_modified ()) {
        // It is possible that the file was modified on the server since we did the discovery phase
        // so make sure we have the up-to-date time
        _item._modtime = job.last_modified ();
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            GLib.warn (lc_propagate_download ()) << "invalid modified time" << _item._file << _item._modtime;
        }
    }

    _tmp_file.close ();
    _tmp_file.flush ();

    /* Check that the size of the GET reply matches the file size. There have been cases
    reported that if a server breaks behind a proxy, the GET is still a 200 but is
    truncated, as described here : https://github.com/owncloud/mirall/issues/2528
    ***********************************************************/
    const GLib.ByteArray size_header ("Content-Length");
    int64 body_size = job.reply ().raw_header (size_header).to_long_long ();
    bool has_size_header = !job.reply ().raw_header (size_header).is_empty ();

    // Qt removes the content-length header for transparently decompressed HTTP1 replies
    // but not for HTTP2 or SPDY replies. For these it remains and contains the size
    // of the compressed data. See QTBUG-73364.
    const var content_encoding = job.reply ().raw_header ("content-encoding").to_lower ();
    if ( (content_encoding == "gzip" || content_encoding == "deflate")
        && (job.reply ().attribute (QNetworkRequest.HTTP2WasUsedAttribute).to_bool ()
         || job.reply ().attribute (QNetworkRequest.Spdy_was_used_attribute).to_bool ())) {
        body_size = 0;
        has_size_header = false;
    }

    if (has_size_header && _tmp_file.size () > 0 && body_size == 0) {
        // Strange bug with broken webserver or webfirewall https://github.com/owncloud/client/issues/3373#issuecomment-122672322
        // This happened when trying to resume a file. The Content-Range header was files, Content-Length was == 0
        GLib.debug (lc_propagate_download) << body_size << _item._size << _tmp_file.size () << job.resume_start ();
        FileSystem.remove (_tmp_file.file_name ());
        on_done (SyncFileItem.SoftError, QLatin1String ("Broken webserver returning empty content length for non-empty file on resume"));
        return;
    }

    if (body_size > 0 && body_size != _tmp_file.size () - job.resume_start ()) {
        GLib.debug (lc_propagate_download) << body_size << _tmp_file.size () << job.resume_start ();
        propagator ()._another_sync_needed = true;
        on_done (SyncFileItem.SoftError, _("The file could not be downloaded completely."));
        return;
    }

    if (_tmp_file.size () == 0 && _item._size > 0) {
        FileSystem.remove (_tmp_file.file_name ());
        on_done (SyncFileItem.NormalError,
            _("The downloaded file is empty, but the server said it should have been %1.")
                .arg (Utility.octets_to_string (_item._size)));
        return;
    }

    // Did the file come with conflict headers? If so, store them now!
    // If we download conflict files but the server doesn't send conflict
    // headers, the record will be established by SyncEngine.conflict_record_maintenance.
    // (we can't reliably determine the file id of the base file here,
    // it might still be downloaded in a parallel job and not exist in
    // the database yet!)
    if (job.reply ().raw_header ("OC-Conflict") == "1") {
        _conflict_record.path = _item._file.to_utf8 ();
        _conflict_record.initial_base_path = job.reply ().raw_header ("OC-ConflictInitialBasePath");
        _conflict_record.base_file_id = job.reply ().raw_header ("OC-ConflictBaseFileId");
        _conflict_record.base_etag = job.reply ().raw_header ("OC-ConflictBaseEtag");

        var mtime_header = job.reply ().raw_header ("OC-ConflictBaseMtime");
        if (!mtime_header.is_empty ())
            _conflict_record.base_modtime = mtime_header.to_long_long ();

        // We don't set it yet. That will only be done when the download on_finished
        // successfully, much further down. Here we just grab the headers because the
        // job will be deleted later.
    }

    // Do checksum validation for the download. If there is no checksum header, the validator
    // will also emit the validated () signal to continue the flow in slot transmission_checksum_validated ()
    // as this is (still) also correct.
    var validator = new ValidateChecksumHeader (this);
    connect (validator, &ValidateChecksumHeader.validated,
        this, &PropagateDownloadFile.transmission_checksum_validated);
    connect (validator, &ValidateChecksumHeader.validation_failed,
        this, &PropagateDownloadFile.on_checksum_fail);
    var checksum_header = find_best_checksum (job.reply ().raw_header (check_sum_header_c));
    var content_md5Header = job.reply ().raw_header (content_md5Header_c);
    if (checksum_header.is_empty () && !content_md5Header.is_empty ())
        checksum_header = "MD5:" + content_md5Header;
    validator.on_start (_tmp_file.file_name (), checksum_header);
}

void PropagateDownloadFile.on_checksum_fail (string error_message) {
    FileSystem.remove (_tmp_file.file_name ());
    propagator ()._another_sync_needed = true;
    on_done (SyncFileItem.SoftError, error_message); // _("The file downloaded with a broken checksum, will be redownloaded."));
}

void PropagateDownloadFile.delete_existing_folder () {
    string existing_dir = propagator ().full_local_path (_item._file);
    if (!QFileInfo (existing_dir).is_dir ()) {
        return;
    }

    // Delete the directory if it is empty!
    QDir dir (existing_dir);
    if (dir.entry_list (QDir.NoDotAndDotDot | QDir.AllEntries).count () == 0) {
        if (dir.rmdir (existing_dir)) {
            return;
        }
        // on error, just try to move it away...
    }

    string error;
    if (!propagator ().create_conflict (_item, _associated_composite, &error)) {
        on_done (SyncFileItem.NormalError, error);
    }
}

namespace { // Anonymous namespace for the recall feature
    static string make_recall_file_name (string fn) {
        string recall_file_name (fn);
        // Add _recall-XXXX  before the extension.
        int dot_location = recall_file_name.last_index_of ('.');
        // If no extension, add it at the end  (take care of cases like foo/.hidden or foo.bar/file)
        if (dot_location <= recall_file_name.last_index_of ('/') + 1) {
            dot_location = recall_file_name.size ();
        }

        string time_string = GLib.DateTime.current_date_time_utc ().to_string ("yyyy_mMdd-hhmmss");
        recall_file_name.insert (dot_location, "_.sys.admin#recall#-" + time_string);

        return recall_file_name;
    }

    void handle_recall_file (string file_path, string folder_path, SyncJournalDb &journal) {
        GLib.debug (lc_propagate_download) << "handle_recall_file : " << file_path;

        FileSystem.set_file_hidden (file_path, true);

        GLib.File file = new GLib.File (file_path);
        if (!file.open (QIODevice.ReadOnly)) {
            GLib.warn (lc_propagate_download) << "Could not open recall file" << file.error_string ();
            return;
        }
        QFileInfo existing_file (file_path);
        QDir base_dir = existing_file.dir ();

        while (!file.at_end ()) {
            GLib.ByteArray line = file.read_line ();
            line.chop (1); // remove trailing \n

            string recalled_file = QDir.clean_path (base_dir.file_path (line));
            if (!recalled_file.starts_with (folder_path) || !recalled_file.starts_with (base_dir.path ())) {
                GLib.warn (lc_propagate_download) << "Ignoring recall of " << recalled_file;
                continue;
            }

            // Path of the recalled file in the local folder
            string local_recalled_file = recalled_file.mid (folder_path.size ());

            SyncJournalFileRecord record;
            if (!journal.get_file_record (local_recalled_file, &record) || !record.is_valid ()) {
                GLib.warn (lc_propagate_download) << "No database entry for recall of" << local_recalled_file;
                continue;
            }

            q_c_info (lc_propagate_download) << "Recalling" << local_recalled_file << "Checksum:" << record._checksum_header;

            string target_path = make_recall_file_name (recalled_file);

            GLib.debug (lc_propagate_download) << "Copy recall file : " << recalled_file << " . " << target_path;
            // Remove the target first, GLib.File.copy will not overwrite it.
            FileSystem.remove (target_path);
            GLib.File.copy (recalled_file, target_path);
        }
    }

    /***********************************************************
    ***********************************************************/
    static void preserve_group_ownership (string file_name, QFileInfo &fi) {
#ifdef Q_OS_UNIX
        int chown_err = chown (file_name.to_local8Bit ().const_data (), -1, fi.group_id ());
        if (chown_err) {
            // TODO : Consider further error handling!
            GLib.warn (lc_propagate_download) << string ("preserve_group_ownership : chown error %1 : setting group %2 failed on file %3").arg (chown_err).arg (fi.group_id ()).arg (file_name);
        }
#else
        Q_UNUSED (file_name);
        Q_UNUSED (fi);
#endif
    }
} // end namespace

void PropagateDownloadFile.transmission_checksum_validated (GLib.ByteArray checksum_type, GLib.ByteArray checksum) {
    const GLib.ByteArray the_content_checksum_type = propagator ().account ().capabilities ().preferred_upload_checksum_type ();

    // Reuse transmission checksum as content checksum.
    //
    // We could do this more aggressively and accept both MD5 and SHA1
    // instead of insisting on the exactly correct checksum type.
    if (the_content_checksum_type == checksum_type || the_content_checksum_type.is_empty ()) {
        return content_checksum_computed (checksum_type, checksum);
    }

    // Compute the content checksum.
    var compute_checksum = new ComputeChecksum (this);
    compute_checksum.set_checksum_type (the_content_checksum_type);

    connect (compute_checksum, &ComputeChecksum.done,
        this, &PropagateDownloadFile.content_checksum_computed);
    compute_checksum.on_start (_tmp_file.file_name ());
}

void PropagateDownloadFile.content_checksum_computed (GLib.ByteArray checksum_type, GLib.ByteArray checksum) {
    _item._checksum_header = make_checksum_header (checksum_type, checksum);

    if (_is_encrypted) {
        if (_download_encrypted_helper.decrypt_file (_tmp_file)) {
          download_finished ();
        } else {
          on_done (SyncFileItem.NormalError, _download_encrypted_helper.error_string ());
        }

    } else {
        download_finished ();
    }
}

void PropagateDownloadFile.download_finished () {
    ASSERT (!_tmp_file.is_open ());
    string fn = propagator ().full_local_path (_item._file);

    // In case of file name clash, report an error
    // This can happen if another parallel download saved a clashing file.
    if (propagator ().local_file_name_clash (_item._file)) {
        on_done (SyncFileItem.NormalError, _("File %1 cannot be saved because of a local file name clash!").arg (QDir.to_native_separators (_item._file)));
        return;
    }

    if (_item._modtime <= 0) {
        FileSystem.remove (_tmp_file.file_name ());
        on_done (SyncFileItem.NormalError, _("File %1 has invalid modified time reported by server. Do not save it.").arg (QDir.to_native_separators (_item._file)));
        return;
    }
    Q_ASSERT (_item._modtime > 0);
    if (_item._modtime <= 0) {
        GLib.warn (lc_propagate_download ()) << "invalid modified time" << _item._file << _item._modtime;
    }
    FileSystem.set_mod_time (_tmp_file.file_name (), _item._modtime);
    // We need to fetch the time again because some file systems such as FAT have worse than a second
    // Accuracy, and we really need the time from the file system. (#3103)
    _item._modtime = FileSystem.get_mod_time (_tmp_file.file_name ());
    if (_item._modtime <= 0) {
        FileSystem.remove (_tmp_file.file_name ());
        on_done (SyncFileItem.NormalError, _("File %1 has invalid modified time reported by server. Do not save it.").arg (QDir.to_native_separators (_item._file)));
        return;
    }
    Q_ASSERT (_item._modtime > 0);
    if (_item._modtime <= 0) {
        GLib.warn (lc_propagate_download ()) << "invalid modified time" << _item._file << _item._modtime;
    }

    bool previous_file_exists = FileSystem.file_exists (fn);
    if (previous_file_exists) {
        // Preserve the existing file permissions.
        QFileInfo existing_file (fn);
        if (existing_file.permissions () != _tmp_file.permissions ()) {
            _tmp_file.set_permissions (existing_file.permissions ());
        }
        preserve_group_ownership (_tmp_file.file_name (), existing_file);

        // Make the file a hydrated placeholder if possible
        const var result = propagator ().sync_options ()._vfs.convert_to_placeholder (_tmp_file.file_name (), _item, fn);
        if (!result) {
            on_done (SyncFileItem.NormalError, result.error ());
            return;
        }
    }

    // Apply the remote permissions
    FileSystem.set_file_read_only_weak (_tmp_file.file_name (), !_item._remote_perm.is_null () && !_item._remote_perm.has_permission (RemotePermissions.Can_write));

    bool is_conflict = _item._instruction == CSYNC_INSTRUCTION_CONFLICT
        && (QFileInfo (fn).is_dir () || !FileSystem.file_equals (fn, _tmp_file.file_name ()));
    if (is_conflict) {
        string error;
        if (!propagator ().create_conflict (_item, _associated_composite, &error)) {
            on_done (SyncFileItem.SoftError, error);
            return;
        }
        previous_file_exists = false;
    }

    const var vfs = propagator ().sync_options ()._vfs;

    // In the case of an hydration, this size is likely to change for placeholders
    // (except with the cfapi backend)
    const var is_virtual_download = _item._type == ItemTypeVirtualFileDownload;
    const var is_cf_api_vfs = vfs && vfs.mode () == Vfs.WindowsCfApi;
    if (previous_file_exists && (is_cf_api_vfs || !is_virtual_download)) {
        // Check whether the existing file has changed since the discovery
        // phase by comparing size and mtime to the previous values. This
        // is necessary to avoid overwriting user changes that happened between
        // the discovery phase and now.
        const int64 expected_size = _item._previous_size;
        const time_t expected_mtime = _item._previous_modtime;
        if (!FileSystem.verify_file_unchanged (fn, expected_size, expected_mtime)) {
            propagator ()._another_sync_needed = true;
            on_done (SyncFileItem.SoftError, _("File has changed since discovery"));
            return;
        }
    }

    string error;
    emit propagator ().touched_file (fn);
    // The file_changed () check is done above to generate better error messages.
    if (!FileSystem.unchecked_rename_replace (_tmp_file.file_name (), fn, &error)) {
        GLib.warn (lc_propagate_download) << string ("Rename failed : %1 => %2").arg (_tmp_file.file_name ()).arg (fn);
        // If the file is locked, we want to retry this sync when it
        // becomes available again, otherwise try again directly
        if (FileSystem.is_file_locked (fn)) {
            emit propagator ().seen_locked_file (fn);
        } else {
            propagator ()._another_sync_needed = true;
        }

        on_done (SyncFileItem.SoftError, error);
        return;
    }

    FileSystem.set_file_hidden (fn, false);

    // Maybe we downloaded a newer version of the file than we thought we would...
    // Get up to date information for the journal.
    _item._size = FileSystem.get_size (fn);

    // Maybe what we downloaded was a conflict file? If so, set a conflict record.
    // (the data was prepared in on_get_finished above)
    if (_conflict_record.is_valid ())
        propagator ()._journal.set_conflict_record (_conflict_record);

    if (vfs && vfs.mode () == Vfs.WithSuffix) {
        // If the virtual file used to have a different name and database
        // entry, remove it transfer its old pin state.
        if (_item._type == ItemTypeVirtualFileDownload) {
            string virtual_file = _item._file + vfs.file_suffix ();
            var fn = propagator ().full_local_path (virtual_file);
            GLib.debug (lc_propagate_download) << "Download of previous virtual file on_finished" << fn;
            GLib.File.remove (fn);
            propagator ()._journal.delete_file_record (virtual_file);

            // Move the pin state to the new location
            var pin = propagator ()._journal.internal_pin_states ().raw_for_path (virtual_file.to_utf8 ());
            if (pin && *pin != PinState.PinState.INHERITED) {
                if (!vfs.set_pin_state (_item._file, *pin)) {
                    GLib.warn (lc_propagate_download) << "Could not set pin state of" << _item._file;
                }
                if (!vfs.set_pin_state (virtual_file, PinState.PinState.INHERITED)) {
                    GLib.warn (lc_propagate_download) << "Could not set pin state of" << virtual_file << " to inherited";
                }
            }
        }

        // Ensure the pin state isn't contradictory
        var pin = vfs.pin_state (_item._file);
        if (pin && *pin == PinState.VfsItemAvailability.ONLINE_ONLY)
            if (!vfs.set_pin_state (_item._file, PinState.PinState.UNSPECIFIED)) {
                GLib.warn (lc_propagate_download) << "Could not set pin state of" << _item._file << "to unspecified";
            }
    }

    update_metadata (is_conflict);
}

void PropagateDownloadFile.update_metadata (bool is_conflict) {
    const string fn = propagator ().full_local_path (_item._file);
    const var result = propagator ().update_metadata (*_item);
    if (!result) {
        on_done (SyncFileItem.FatalError, _("Error updating metadata : %1").arg (result.error ()));
        return;
    } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
        on_done (SyncFileItem.SoftError, _("The file %1 is currently in use").arg (_item._file));
        return;
    }

    if (_is_encrypted) {
        propagator ()._journal.set_download_info (_item._file, SyncJournalDb.DownloadInfo ());
    } else {
        propagator ()._journal.set_download_info (_item._encrypted_file_name, SyncJournalDb.DownloadInfo ());
    }

    propagator ()._journal.commit ("download file start2");

    on_done (is_conflict ? SyncFileItem.Conflict : SyncFileItem.Success);

    // handle the special recall file
    if (!_item._remote_perm.has_permission (RemotePermissions.IsShared)
        && (_item._file == QLatin1String (".sys.admin#recall#")
               || _item._file.ends_with (QLatin1String ("/.sys.admin#recall#")))) {
        handle_recall_file (fn, propagator ().local_path (), *propagator ()._journal);
    }

    int64 duration = _stopwatch.elapsed ();
    if (is_likely_finished_quickly () && duration > 5 * 1000) {
        GLib.warn (lc_propagate_download) << "WARNING : Unexpectedly slow connection, took" << duration << "msec for" << _item._size - _resume_start << "bytes for" << _item._file;
    }
}

void PropagateDownloadFile.on_download_progress (int64 received, int64) {
    if (!_job)
        return;
    _download_progress = received;
    propagator ().report_progress (*_item, _resume_start + received);
}

void PropagateDownloadFile.on_abort (PropagatorJob.AbortType abort_type) {
    if (_job && _job.reply ())
        _job.reply ().on_abort ();

    if (abort_type == AbortType.Asynchronous) {
        emit abort_finished ();
    }
}
}
