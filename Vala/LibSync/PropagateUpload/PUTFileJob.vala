/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
Q_DECLARE_LOGGING_CATEGORY (lc_put_job)
/***********************************************************
@brief The PUTFile_job class
@ingroup libsync
***********************************************************/
class PUTFile_job : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    private QIODevice this.device;
    private GLib.HashMap<GLib.ByteArray, GLib.ByteArray> this.headers;
    private string this.error_string;
    private GLib.Uri this.url;
    private QElapsedTimer this.request_timer;


    // Takes ownership of the device
    public PUTFile_job (AccountPointer account, string path, std.unique_ptr<QIODevice> device,
        const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, int chunk, GLib.Object parent = new GLib.Object ())
        : AbstractNetworkJob (account, path, parent)
        , this.device (device.release ())
        , this.headers (headers)
        , this.chunk (chunk) {
        this.device.set_parent (this);
    }


    /***********************************************************
    ***********************************************************/
    public PUTFile_job (AccountPointer account, GLib.Uri url, std.unique_ptr<QIODevice> device,
        const GLib.HashMap<GLib.ByteArray, GLib.ByteArray> headers, int chunk, GLib.Object parent = new GLib.Object ())
        : AbstractNetworkJob (account, "", parent)
        , this.device (device.release ())
        , this.headers (headers)
        , this.url (url)
        , this.chunk (chunk) {
        this.device.set_parent (this);
    }
    ~PUTFile_job () override;

    /***********************************************************
    ***********************************************************/
    public int this.chunk;

    /***********************************************************
    ***********************************************************/
    public void on_start () override;

    /***********************************************************
    ***********************************************************/
    public bool on_finished () override;

    /***********************************************************
    ***********************************************************/
    public QIODevice device () {
        return this.device;
    }


    /***********************************************************
    ***********************************************************/
    public string error_string () override {
        return this.error_string.is_empty () ? AbstractNetworkJob.error_string () : this.error_string;
    }


    /***********************************************************
    ***********************************************************/
    public std.chrono.milliseconds ms_since_start () {
        return std.chrono.milliseconds (this.request_timer.elapsed ());
    }

signals:
    void finished_signal ();
    void upload_progress (int64, int64);

}




PUTFile_job.~PUTFile_job () {
    // Make sure that we destroy the Soup.Reply before our this.device of which it keeps an internal pointer.
    set_reply (nullptr);
}

void PUTFile_job.on_start () {
    Soup.Request req;
    for (GLib.HashMap<GLib.ByteArray, GLib.ByteArray>.Const_iterator it = this.headers.begin (); it != this.headers.end (); ++it) {
        req.set_raw_header (it.key (), it.value ());
    }

    req.set_priority (Soup.Request.Low_priority); // Long uploads must not block non-propagation jobs.

    if (this.url.is_valid ()) {
        send_request ("PUT", this.url, req, this.device);
    } else {
        send_request ("PUT", make_dav_url (path ()), req, this.device);
    }

    if (reply ().error () != Soup.Reply.NoError) {
        GLib.warn (lc_put_job) << " Network error : " << reply ().error_string ();
    }

    connect (reply (), &Soup.Reply.upload_progress, this, &PUTFile_job.upload_progress);
    connect (this, &AbstractNetworkJob.network_activity, account ().data (), &Account.propagator_network_activity);
    this.request_timer.on_start ();
    AbstractNetworkJob.on_start ();
}

bool PUTFile_job.on_finished () {
    this.device.close ();

    q_c_info (lc_put_job) << "PUT of" << reply ().request ().url ().to_string () << "FINISHED WITH STATUS"
                     << reply_status_""
                     << reply ().attribute (Soup.Request.HttpStatusCodeAttribute)
                     << reply ().attribute (Soup.Request.HttpReasonPhraseAttribute);

    /* emit */ finished_signal ();
    return true;
}