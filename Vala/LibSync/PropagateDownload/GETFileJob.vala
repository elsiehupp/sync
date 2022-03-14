/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The GETFileJob class
@ingroup libsync
***********************************************************/
public class GETFileJob : AbstractNetworkJob {

    QIODevice device;
    GLib.HashTable<string, string> headers;
    string error_string {
        public get {
            if (!this.error_string == "") {
                return this.error_string;
            }
            return AbstractNetworkJob.error_string ();
        }
        private set {
            this.error_string = value;
        }
    }

    string expected_etag_for_resume;
    int64 expected_content_length {
        public get {
            return -1;
        }
        public set {
            this.expected_content_length = value;
        }
    }


    int64 resume_start {
        public get {
            return -1;
        }
        private set {
            this.resume_start = value;
        }
    }

    public SyncFileItem.Status error_status;

    GLib.Uri direct_download_url;
    string etag { public get; private set; }

    /***********************************************************
    If this.bandwidth_quota will be used
    ***********************************************************/
    bool bandwidth_limited;

    /***********************************************************
    If download is paused (won't read on ready_read ())
    ***********************************************************/
    bool bandwidth_choked;
    int64 bandwidth_quota;

    QPointer<BandwidthManager> bandwidth_manager { private get; public set; }
    bool has_emitted_finished_signal;
    time_t last_modified { public get; private set; }

    /***********************************************************
    Will be set to true once we've seen a 2xx response header
    ***********************************************************/
    bool save_body_to_file = false;

    int64 content_length { public get; protected set; }


    signal void signal_finished ();
    signal void download_progress (int64 value1, int64 value2);


    /***********************************************************
    DOES NOT take ownership of the device.
    ***********************************************************/
    public GETFileJob.for_account (Account account, string path, QIODevice device,
        GLib.HashTable<string, string> headers, string expected_etag_for_resume,
        int64 resume_start, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
        this.device = device;
        this.headers = headers;
        this.expected_etag_for_resume = expected_etag_for_resume;
        this.expected_content_length = -1;
        this.resume_start = resume_start;
        this.error_status = SyncFileItem.Status.NO_STATUS;
        this.bandwidth_limited = false;
        this.bandwidth_choked = false;
        this.bandwidth_quota = 0;
        this.bandwidth_manager = null;
        this.has_emitted_finished_signal = false;
        //  this.last_modified ()
        this.content_length = -1;
    }



    /***********************************************************
    For direct_download_url:
    ***********************************************************/
    public GETFileJob.direct_for_account (Account account, GLib.Uri url, QIODevice device,
        GLib.HashTable<string, string> headers, string expected_etag_for_resume,
        int64 resume_start, GLib.Object parent = new GLib.Object ()) {
        base (account, url.to_encoded (), parent);
        this.device = device;
        this.headers = headers;
        this.expected_etag_for_resume = expected_etag_for_resume;
        this.expected_content_length = -1;
        this.resume_start = resume_start;
        this.error_status = SyncFileItem.Status.NO_STATUS;
        this.direct_download_url = url;
        this.bandwidth_limited = false;
        this.bandwidth_choked = false;
        this.bandwidth_quota = 0;
        this.bandwidth_manager = null;
        this.has_emitted_finished_signal = false;
        //  this.last_modified ()
        this.content_length = -1;
    }

    /***********************************************************
    ***********************************************************/
    ~GETFileJob () {
        if (this.bandwidth_manager) {
            this.bandwidth_manager.on_signal_unregister_download_job (this);
        }
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        if (this.resume_start > 0) {
            this.headers["Range"] = "bytes=" + string.number (this.resume_start) + '-';
            this.headers["Accept-Ranges"] = "bytes";
            GLib.debug ("Retry with range " + this.headers["Range"]);
        }

        Soup.Request request = new Soup.Request ();
        foreach (var header in this.headers) {
            request.raw_header (header.key (), header.value ());
        }

        request.priority (Soup.Request.Low_priority); // Long downloads must not block non-propagation jobs.

        if (this.direct_download_url == "") {
            send_request ("GET", make_dav_url (path ()), request);
        } else {
            // Use direct URL
            send_request ("GET", this.direct_download_url, request);
        }

        GLib.debug (this.bandwidth_manager + this.bandwidth_choked + this.bandwidth_limited);
        if (this.bandwidth_manager) {
            this.bandwidth_manager.on_signal_register_download_job (this);
        }

        connect (this, AbstractNetworkJob.signal_network_activity, account ().data (), Account.signal_propagator_network_activity);

        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        if (this.save_body_to_file && reply ().bytes_available ()) {
            return false;
        } else {
            if (this.bandwidth_manager) {
                this.bandwidth_manager.on_signal_unregister_download_job (this);
            }
            if (!this.has_emitted_finished_signal) {
                /* emit */ signal_finished ();
            }
            this.has_emitted_finished_signal = true;
            return true; // discard
        }
    }


    /***********************************************************
    ***********************************************************/
    public void cancel () {
        var network_reply = reply ();
        if (network_reply && network_reply.is_running ()) {
            network_reply.abort ();
        }
        if (this.device && this.device.is_open ()) {
            this.device.close ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void new_reply_hook (GLib.InputStream reply);
    void GETFileJob.new_reply_hook (GLib.InputStream reply) {
        reply.read_buffer_size (16 * 1024); // keep low so we can easier limit the bandwidth

        connect (reply, Soup.Reply.meta_data_changed, this, GETFileJob.on_signal_meta_data_changed);
        connect (reply, QIODevice.ready_read, this, GETFileJob.on_signal_ready_read);
        connect (reply, Soup.Reply.on_signal_finished, this, GETFileJob.on_signal_ready_read);
        connect (reply, Soup.Reply.download_progress, this, GETFileJob.download_progress);
    }





    /***********************************************************
    ***********************************************************/
    public 
    void GETFileJob.choked (bool c) {
        this.bandwidth_choked = c;
        QMetaObject.invoke_method (this, "on_signal_ready_read", Qt.QueuedConnection);
    }


    /***********************************************************
    ***********************************************************/
    //  public 


    /***********************************************************
    ***********************************************************/
    public void bandwidth_limited (bool b) {
        this.bandwidth_limited = b;
        QMetaObject.invoke_method (this, "on_signal_ready_read", Qt.QueuedConnection);
    }



    /***********************************************************
    ***********************************************************/
    public void give_bandwidth_quota (int64 q) {
        this.bandwidth_quota = q;
        GLib.debug ("Got " + q + " bytes");
        QMetaObject.invoke_method (this, "on_signal_ready_read", Qt.QueuedConnection);
    }

    /***********************************************************
    ***********************************************************/
    //  public 


    /***********************************************************
    ***********************************************************/
    public int64 current_download_position () {
        if (this.device && this.device.position () > 0 && this.device.position () > int64 (this.resume_start)) {
            return this.device.position ();
        }
        return this.resume_start;
    }




    /***********************************************************
    ***********************************************************/
    public void on_signal_error_string (string s) {
        this.error_string = s;
    }


    /***********************************************************
    ***********************************************************/
    public new void on_signal_timed_out () {
        GLib.warning ("Timeout" + reply () ? reply ().request ().url () : path ());
        if (!reply ())
            return;
        this.error_string = _("Connection Timeout");
        this.error_status = SyncFileItem.Status.FATAL_ERROR;
        reply ().abort ();
    }




    /***********************************************************
    ***********************************************************/
    protected int64 write_to_device (string data) {
        return this.device.write (data);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_ready_read () {
        if (!reply ())
            return;
        int buffer_size = q_min (1024 * 8ll, reply ().bytes_available ());
        string buffer = new string (buffer_size, Qt.Uninitialized);

        while (reply ().bytes_available () > 0 && this.save_body_to_file) {
            if (this.bandwidth_choked) {
                GLib.warning ("Download choked.");
                break;
            }
            int64 to_read = buffer_size;
            if (this.bandwidth_limited) {
                to_read = q_min (int64 (buffer_size), this.bandwidth_quota);
                if (to_read == 0) {
                    GLib.warning ("Out of quota.");
                    break;
                }
                this.bandwidth_quota -= to_read;
            }

            const int64 read_bytes = reply ().read (buffer.data (), to_read);
            if (read_bytes < 0) {
                this.error_string = network_reply_error_string (*reply ());
                this.error_status = SyncFileItem.Status.NORMAL_ERROR;
                GLib.warning ("Error while reading from device: " + this.error_string);
                reply ().abort ();
                return;
            }

            const int64 written_bytes = write_to_device (string.from_raw_data (buffer.const_data (), read_bytes));
            if (written_bytes != read_bytes) {
                this.error_string = this.device.error_string ();
                this.error_status = SyncFileItem.Status.NORMAL_ERROR;
                GLib.warning ("Error while writing to file " + written_bytes + read_bytes + this.error_string);
                reply ().abort ();
                return;
            }
        }

        if (reply ().is_finished () && (reply ().bytes_available () == 0 || !this.save_body_to_file)) {
            GLib.debug ("Actually finished!");
            if (this.bandwidth_manager) {
                this.bandwidth_manager.on_signal_unregister_download_job (this);
            }
            if (!this.has_emitted_finished_signal) {
                GLib.info ("GET of " + reply ().request ().url ().to_string ()
                          + " finished with status " + reply_status_string ()
                          + reply ().raw_header ("Content-Range") + reply ().raw_header ("Content-Length"));

                /* emit */ signal_finished ();
            }
            this.has_emitted_finished_signal = true;
            delete_later ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_meta_data_changed () {
        // For some reason setting the read buffer in GETFileJob.start doesn't seem to go
        // through the HTTP layer thread (?)
        reply ().read_buffer_size (16 * 1024);

        int http_status = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        if (http_status == 301 || http_status == 302 || http_status == 303 || http_status == 307
            || http_status == 308 || http_status == 401) {
            // Redirects and auth failures (oauth token renew) are handled by AbstractNetworkJob and
            // will end up restarting the job. We do not want to process further data from the initial
            // request. new_reply_hook () will reestablish signal connections for the follow-up request.
            bool ok = disconnect (reply (), Soup.Reply.on_signal_finished, this, GETFileJob.on_signal_ready_read)
                && disconnect (reply (), Soup.Reply.ready_read, this, GETFileJob.on_signal_ready_read);
            //  ASSERT (ok);
            return;
        }

        // If the status code isn't 2xx, don't write the reply body to the file.
        // For any error : handle it when the job is on_signal_finished, not here.
        if (http_status / 100 != 2) {
            // Disable the buffer limit, as we don't limit the bandwidth for error messages.
            // (We are only going to do a read_all () at the end.)
            reply ().read_buffer_size (0);
            return;
        }
        if (reply ().error () != Soup.Reply.NoError) {
            return;
        }
        this.etag = get_etag_from_reply (reply ());

        if (!this.direct_download_url == "" && !this.etag == "") {
            GLib.info ("Direct download used, ignoring server ETag " + this.etag);
            this.etag = ""; // reset received ETag
        } else if (!this.direct_download_url == "") {
            // All fine, ETag empty and direct_download_url used
        } else if (this.etag == "") {
            GLib.warning ("No E-Tag reply by server, considering it invalid.");
            this.error_string = _("No E-Tag received from server, check Proxy/Gateway.");
            this.error_status = SyncFileItem.Status.NORMAL_ERROR;
            reply ().abort ();
            return;
        } else if (!this.expected_etag_for_resume == "" && this.expected_etag_for_resume != this.etag) {
            GLib.warning ("We received a different E-Tag for resuming!"
                        + this.expected_etag_for_resume + " vs " + this.etag);
            this.error_string = _("We received a different E-Tag for resuming. Retrying next time.");
            this.error_status = SyncFileItem.Status.NORMAL_ERROR;
            reply ().abort ();
            return;
        }

        bool ok = false;
        this.content_length = reply ().header (Soup.Request.ContentLengthHeader).to_long_long (&ok);
        if (ok && this.expected_content_length != -1 && this.content_length != this.expected_content_length) {
            GLib.warning ("We received a different content length than expected! "
                    + this.expected_content_length + " vs " + this.content_length);
            this.error_string = _("We received an unexpected download Content-Length.");
            this.error_status = SyncFileItem.Status.NORMAL_ERROR;
            reply ().abort ();
            return;
        }

        int64 start = 0;
        string ranges = reply ().raw_header ("Content-Range");
        if (!ranges == "") {
            const QRegularExpression rx = new QRegularExpression ("bytes (\\d+)-");
            var rx_match = rx.match (ranges);
            if (rx_match.has_match ()) {
                start = rx_match.captured (1).to_long_long ();
            }
        }
        if (start != this.resume_start) {
            GLib.warning ("Wrong content-range: " + ranges + " while expecting start was " + this.resume_start);
            if (ranges == "") {
                // device doesn't support range, just try again from scratch
                this.device.close ();
                if (!this.device.open (QIODevice.WriteOnly)) {
                    this.error_string = this.device.error_string ();
                    this.error_status = SyncFileItem.Status.NORMAL_ERROR;
                    reply ().abort ();
                    return;
                }
                this.resume_start = 0;
            } else {
                this.error_string = _("Server returned wrong content-range");
                this.error_status = SyncFileItem.Status.NORMAL_ERROR;
                reply ().abort ();
                return;
            }
        }

        var last_modified = reply ().header (Soup.Request.Last_modified_header);
        if (!last_modified.is_null ()) {
            this.last_modified = Utility.q_date_time_to_time_t (last_modified.to_date_time ());
        }

        this.save_body_to_file = true;
    }

} // class GETFileJob

} // namespace LibSync
} // namespace Occ

