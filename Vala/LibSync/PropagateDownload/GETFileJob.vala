/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The GETFileJob class
@ingroup libsync
***********************************************************/
class GETFileJob : AbstractNetworkJob {
    QIODevice this.device;
    GLib.HashMap<GLib.ByteArray, GLib.ByteArray> this.headers;
    string this.error_string;
    GLib.ByteArray this.expected_etag_for_resume;
    int64 this.expected_content_length;
    int64 this.resume_start;
    SyncFileItem.Status this.error_status;
    GLib.Uri this.direct_download_url;
    GLib.ByteArray this.etag;
    bool this.bandwidth_limited; // if this.bandwidth_quota will be used
    bool this.bandwidth_choked; // if download is paused (won't read on ready_read ())
    int64 this.bandwidth_quota;
    QPointer<BandwidthManager> this.bandwidth_manager;
    bool this.has_emitted_finished_signal;
    time_t this.last_modified;

    /// Will be set to true once we've seen a 2xx response header
    bool this.save_body_to_file = false;


    protected int64 this.content_length;


    // DOES NOT take ownership of the device.
    public GETFileJob (AccountPointer account, string path, QIODevice device,
        const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, GLib.ByteArray expected_etag_for_resume,
        int64 resume_start, GLib.Object parent = new GLib.Object ());
    // For direct_download_url:
    public GETFileJob (AccountPointer account, GLib.Uri url, QIODevice device,
        const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, GLib.ByteArray expected_etag_for_resume,
        int64 resume_start, GLib.Object parent = new GLib.Object ());
    ~GETFileJob () override {
        if (this.bandwidth_manager) {
            this.bandwidth_manager.on_unregister_download_job (this);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () override;
    public bool on_finished () override {
        if (this.save_body_to_file && reply ().bytes_available ()) {
            return false;
        } else {
            if (this.bandwidth_manager) {
                this.bandwidth_manager.on_unregister_download_job (this);
            }
            if (!this.has_emitted_finished_signal) {
                /* emit */ finished_signal ();
            }
            this.has_emitted_finished_signal = true;
            return true; // discard
        }
    }


    /***********************************************************
    ***********************************************************/
    public void cancel ();

    /***********************************************************
    ***********************************************************/
    public void new_reply_hook (Soup.Reply reply) override;

    /***********************************************************
    ***********************************************************/
    public void set_bandwidth_manager (BandwidthManager bandwidth_manager);

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
        this.error_string = s;
    }


    /***********************************************************
    ***********************************************************/
    public SyncFileItem.Status error_status () {
        return this.error_status;
    }


    /***********************************************************
    ***********************************************************/
    public void set_error_status (SyncFileItem.Status s) {
        this.error_status = s;
    }


    /***********************************************************
    ***********************************************************/
    public void on_timed_out () override;

    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray etag () {
        return this.etag;
    }


    /***********************************************************
    ***********************************************************/
    public int64 resume_start () {
    }


    /***********************************************************
    ***********************************************************/
    public time_t last_modified () {
        return this.last_modified;
    }


    /***********************************************************
    ***********************************************************/
    public int64 content_length () {
        return this.content_length;
    }


    /***********************************************************
    ***********************************************************/
    public int64 expected_content_length () {
    }


    /***********************************************************
    ***********************************************************/
    public void set_expected_content_length (int64 size) {
        this.expected_content_length = size;
    }


    protected virtual int64 write_to_device (GLib.ByteArray data);

signals:
    void finished_signal ();
    void download_progress (int64, int64);

    /***********************************************************
    ***********************************************************/
    private void on_ready_read ();
    private void on_meta_data_changed ();
}



// DOES NOT take ownership of the device.
GETFileJob.GETFileJob (AccountPointer account, string path, QIODevice device,
    const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, GLib.ByteArray expected_etag_for_resume,
    int64 resume_start, GLib.Object parent)
    : base (account, path, parent)
    this.device (device)
    this.headers (headers)
    this.expected_etag_for_resume (expected_etag_for_resume)
    this.expected_content_length (-1)
    this.resume_start (resume_start)
    this.error_status (SyncFileItem.Status.NO_STATUS)
    this.bandwidth_limited (false)
    this.bandwidth_choked (false)
    this.bandwidth_quota (0)
    this.bandwidth_manager (null)
    this.has_emitted_finished_signal (false)
    this.last_modified ()
    this.content_length (-1) {
}

GETFileJob.GETFileJob (AccountPointer account, GLib.Uri url, QIODevice device,
    const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, GLib.ByteArray expected_etag_for_resume,
    int64 resume_start, GLib.Object parent)
    : base (account, url.to_encoded (), parent)
    this.device (device)
    this.headers (headers)
    this.expected_etag_for_resume (expected_etag_for_resume)
    this.expected_content_length (-1)
    this.resume_start (resume_start)
    this.error_status (SyncFileItem.Status.NO_STATUS)
    this.direct_download_url (url)
    this.bandwidth_limited (false)
    this.bandwidth_choked (false)
    this.bandwidth_quota (0)
    this.bandwidth_manager (null)
    this.has_emitted_finished_signal (false)
    this.last_modified ()
    this.content_length (-1) {
}

void GETFileJob.on_start () {
    if (this.resume_start > 0) {
        this.headers["Range"] = "bytes=" + GLib.ByteArray.number (this.resume_start) + '-';
        this.headers["Accept-Ranges"] = "bytes";
        GLib.debug (lc_get_job) << "Retry with range " << this.headers["Range"];
    }

    Soup.Request req;
    for (GLib.HashMap<GLib.ByteArray, GLib.ByteArray>.Const_iterator it = this.headers.begin (); it != this.headers.end (); ++it) {
        req.set_raw_header (it.key (), it.value ());
    }

    req.set_priority (Soup.Request.Low_priority); // Long downloads must not block non-propagation jobs.

    if (this.direct_download_url.is_empty ()) {
        send_request ("GET", make_dav_url (path ()), req);
    } else {
        // Use direct URL
        send_request ("GET", this.direct_download_url, req);
    }

    GLib.debug (lc_get_job) << this.bandwidth_manager << this.bandwidth_choked << this.bandwidth_limited;
    if (this.bandwidth_manager) {
        this.bandwidth_manager.on_register_download_job (this);
    }

    connect (this, &AbstractNetworkJob.network_activity, account ().data (), &Account.propagator_network_activity);

    AbstractNetworkJob.on_start ();
}

void GETFileJob.new_reply_hook (Soup.Reply reply) {
    reply.set_read_buffer_size (16 * 1024); // keep low so we can easier limit the bandwidth

    connect (reply, &Soup.Reply.meta_data_changed, this, &GETFileJob.on_meta_data_changed);
    connect (reply, &QIODevice.ready_read, this, &GETFileJob.on_ready_read);
    connect (reply, &Soup.Reply.on_finished, this, &GETFileJob.on_ready_read);
    connect (reply, &Soup.Reply.download_progress, this, &GETFileJob.download_progress);
}

void GETFileJob.on_meta_data_changed () {
    // For some reason setting the read buffer in GETFileJob.on_start doesn't seem to go
    // through the HTTP layer thread (?)
    reply ().set_read_buffer_size (16 * 1024);

    int http_status = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

    if (http_status == 301 || http_status == 302 || http_status == 303 || http_status == 307
        || http_status == 308 || http_status == 401) {
        // Redirects and auth failures (oauth token renew) are handled by AbstractNetworkJob and
        // will end up restarting the job. We do not want to process further data from the initial
        // request. new_reply_hook () will reestablish signal connections for the follow-up request.
        bool ok = disconnect (reply (), &Soup.Reply.on_finished, this, &GETFileJob.on_ready_read)
            && disconnect (reply (), &Soup.Reply.ready_read, this, &GETFileJob.on_ready_read);
        //  ASSERT (ok);
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
    if (reply ().error () != Soup.Reply.NoError) {
        return;
    }
    this.etag = get_etag_from_reply (reply ());

    if (!this.direct_download_url.is_empty () && !this.etag.is_empty ()) {
        GLib.info (lc_get_job) << "Direct download used, ignoring server ETag" << this.etag;
        this.etag = GLib.ByteArray (); // reset received ETag
    } else if (!this.direct_download_url.is_empty ()) {
        // All fine, ETag empty and direct_download_url used
    } else if (this.etag.is_empty ()) {
        GLib.warn (lc_get_job) << "No E-Tag reply by server, considering it invalid";
        this.error_string = _("No E-Tag received from server, check Proxy/Gateway");
        this.error_status = SyncFileItem.Status.NORMAL_ERROR;
        reply ().on_abort ();
        return;
    } else if (!this.expected_etag_for_resume.is_empty () && this.expected_etag_for_resume != this.etag) {
        GLib.warn (lc_get_job) << "We received a different E-Tag for resuming!"
                            << this.expected_etag_for_resume << "vs" << this.etag;
        this.error_string = _("We received a different E-Tag for resuming. Retrying next time.");
        this.error_status = SyncFileItem.Status.NORMAL_ERROR;
        reply ().on_abort ();
        return;
    }

    bool ok = false;
    this.content_length = reply ().header (Soup.Request.ContentLengthHeader).to_long_long (&ok);
    if (ok && this.expected_content_length != -1 && this.content_length != this.expected_content_length) {
        GLib.warn (lc_get_job) << "We received a different content length than expected!"
                            << this.expected_content_length << "vs" << this.content_length;
        this.error_string = _("We received an unexpected download Content-Length.");
        this.error_status = SyncFileItem.Status.NORMAL_ERROR;
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
    if (on_start != this.resume_start) {
        GLib.warn (lc_get_job) << "Wrong content-range : " << ranges << " while expecting on_start was" << this.resume_start;
        if (ranges.is_empty ()) {
            // device doesn't support range, just try again from scratch
            this.device.close ();
            if (!this.device.open (QIODevice.WriteOnly)) {
                this.error_string = this.device.error_string ();
                this.error_status = SyncFileItem.Status.NORMAL_ERROR;
                reply ().on_abort ();
                return;
            }
            this.resume_start = 0;
        } else {
            this.error_string = _("Server returned wrong content-range");
            this.error_status = SyncFileItem.Status.NORMAL_ERROR;
            reply ().on_abort ();
            return;
        }
    }

    var last_modified = reply ().header (Soup.Request.Last_modified_header);
    if (!last_modified.is_null ()) {
        this.last_modified = Utility.q_date_time_to_time_t (last_modified.to_date_time ());
    }

    this.save_body_to_file = true;
}

void GETFileJob.set_bandwidth_manager (BandwidthManager bandwidth_manager) {
    this.bandwidth_manager = bandwidth_manager;
}

void GETFileJob.set_choked (bool c) {
    this.bandwidth_choked = c;
    QMetaObject.invoke_method (this, "on_ready_read", Qt.QueuedConnection);
}

void GETFileJob.set_bandwidth_limited (bool b) {
    this.bandwidth_limited = b;
    QMetaObject.invoke_method (this, "on_ready_read", Qt.QueuedConnection);
}

void GETFileJob.give_bandwidth_quota (int64 q) {
    this.bandwidth_quota = q;
    GLib.debug (lc_get_job) << "Got" << q << "bytes";
    QMetaObject.invoke_method (this, "on_ready_read", Qt.QueuedConnection);
}

int64 GETFileJob.current_download_position () {
    if (this.device && this.device.position () > 0 && this.device.position () > int64 (this.resume_start)) {
        return this.device.position ();
    }
    return this.resume_start;
}

int64 GETFileJob.write_to_device (GLib.ByteArray data) {
    return this.device.write (data);
}

void GETFileJob.on_ready_read () {
    if (!reply ())
        return;
    int buffer_size = q_min (1024 * 8ll, reply ().bytes_available ());
    GLib.ByteArray buffer (buffer_size, Qt.Uninitialized);

    while (reply ().bytes_available () > 0 && this.save_body_to_file) {
        if (this.bandwidth_choked) {
            GLib.warn (lc_get_job) << "Download choked";
            break;
        }
        int64 to_read = buffer_size;
        if (this.bandwidth_limited) {
            to_read = q_min (int64 (buffer_size), this.bandwidth_quota);
            if (to_read == 0) {
                GLib.warn (lc_get_job) << "Out of quota";
                break;
            }
            this.bandwidth_quota -= to_read;
        }

        const int64 read_bytes = reply ().read (buffer.data (), to_read);
        if (read_bytes < 0) {
            this.error_string = network_reply_error_string (*reply ());
            this.error_status = SyncFileItem.Status.NORMAL_ERROR;
            GLib.warn (lc_get_job) << "Error while reading from device : " << this.error_string;
            reply ().on_abort ();
            return;
        }

        const int64 written_bytes = write_to_device (GLib.ByteArray.from_raw_data (buffer.const_data (), read_bytes));
        if (written_bytes != read_bytes) {
            this.error_string = this.device.error_string ();
            this.error_status = SyncFileItem.Status.NORMAL_ERROR;
            GLib.warn (lc_get_job) << "Error while writing to file" << written_bytes << read_bytes << this.error_string;
            reply ().on_abort ();
            return;
        }
    }

    if (reply ().is_finished () && (reply ().bytes_available () == 0 || !this.save_body_to_file)) {
        GLib.debug (lc_get_job) << "Actually on_finished!";
        if (this.bandwidth_manager) {
            this.bandwidth_manager.on_unregister_download_job (this);
        }
        if (!this.has_emitted_finished_signal) {
            GLib.info (lc_get_job) << "GET of" << reply ().request ().url ().to_string () << "FINISHED WITH STATUS"
                             << reply_status_string ()
                             << reply ().raw_header ("Content-Range") << reply ().raw_header ("Content-Length");

            /* emit */ finished_signal ();
        }
        this.has_emitted_finished_signal = true;
        delete_later ();
    }
}

void GETFileJob.cancel () {
    const var network_reply = reply ();
    if (network_reply && network_reply.is_running ()) {
        network_reply.on_abort ();
    }
    if (this.device && this.device.is_open ()) {
        this.device.close ();
    }
}

void GETFileJob.on_timed_out () {
    GLib.warn (lc_get_job) << "Timeout" << (reply () ? reply ().request ().url () : path ());
    if (!reply ())
        return;
    this.error_string = _("Connection Timeout");
    this.error_status = SyncFileItem.Status.FATAL_ERROR;
    reply ().on_abort ();
}

string GETFileJob.error_string () {
    if (!this.error_string.is_empty ()) {
        return this.error_string;
    }
    return AbstractNetworkJob.error_string ();
}