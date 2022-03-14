/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The PUTFileJob class
@ingroup libsync
***********************************************************/
public class PUTFileJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    QIODevice device { public get; private set; }
    private GLib.HashTable<string, string> headers;
    new string error_string {
        public get {
            this.error_string == "" ? AbstractNetworkJob.error_string () : this.error_string;
        }
        protected set {
            this.error_string = value;
        }
    }
    private GLib.Uri url;
    private QElapsedTimer request_timer;

    /***********************************************************
    ***********************************************************/
    public int chunk;


    signal void signal_finished ();
    signal void signal_upload_progress (int64 value1, int64 value2);


    /***********************************************************
    Takes ownership of the device
    ***********************************************************/
    public PUTFileJob.for_path (Account account, string path, std.unique_ptr<QIODevice> device,
        GLib.HashTable<string, string> headers, int chunk, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
        this.device = device.release ();
        this.headers = headers;
        this.chunk = chunk;
        this.device.parent (this);
    }


    /***********************************************************
    ***********************************************************/
    public PUTFileJob.for_url (Account account, GLib.Uri url, std.unique_ptr<QIODevice> device,
        GLib.HashTable<string, string> headers, int chunk, GLib.Object parent = new GLib.Object ()) {
        base (account, "", parent);
        this.device = device.release ();
        this.headers = headers;
        this.url = url;
        this.chunk = chunk;
        this.device.parent (this);
    }


    ~PUTFileJob () {
        // Make sure that we destroy the GLib.InputStream before our this.device of which it keeps an internal pointer.
        reply (null);
    }

    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request = new Soup.Request ();
        foreach (var header in this.headers) {
            request.raw_header (header.key (), header.value ());
        }

        request.priority (Soup.Request.Low_priority); // Long uploads must not block non-propagation jobs.

        if (this.url.is_valid ()) {
            send_request ("PUT", this.url, request, this.device);
        } else {
            send_request ("PUT", make_dav_url (path ()), request, this.device);
        }

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warning (" Network error: " + reply ().error_string ());
        }

        connect (reply (), Soup.Reply.signal_upload_progress, this, PUTFileJob.signal_upload_progress);
        connect (this, AbstractNetworkJob.signal_network_activity, account ().data (), Account.signal_propagator_network_activity);
        this.request_timer.start ();
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        this.device.close ();

        GLib.info ("PUT of " + reply ().request ().url ().to_string () + " finished with status "
            + reply_status_string ()
            + reply ().attribute (Soup.Request.HttpStatusCodeAttribute)
            + reply ().attribute (Soup.Request.HttpReasonPhraseAttribute));

        /* emit */ signal_finished ();
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.TimeSpan ms_since_start () {
        return GLib.TimeSpan (this.request_timer.elapsed ());
    }

} // class PUTFileJob

} // namespace LibSync
} // namespace Occ
