namespace Occ {
namespace LibSync {

/***********************************************************
@class PUTFileJob

@brief The PUTFileJob class

@author Olivier Goffart <ogoffart@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class PUTFileJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public GLib.OutputStream device { public get; private set; }
    private GLib.HashTable<string, string> headers;

    new string error_string {
        public get {
            this.error_string == "" ? base.error_string : this.error_string;
        }
        protected set {
            this.error_string = value;
        }
    }
    private GLib.Uri url;
    private GLib.Timer request_timer;

    /***********************************************************
    ***********************************************************/
    public int chunk;


    internal signal void signal_finished ();
    internal signal void signal_upload_progress (int64 value1, int64 value2);


    /***********************************************************
    Takes ownership of the device
    ***********************************************************/
    public PUTFileJob.for_path (
        Account account,
        string path,
        GLib.OutputStream device,
        GLib.HashTable<string, string> headers,
        int chunk,
        GLib.Object parent = new GLib.Object ()
    ) {
        //  base (account, path, parent);
        //  this.device = device.release ();
        //  this.headers = headers;
        //  this.chunk = chunk;
        //  this.device.parent (this);
    }


    /***********************************************************
    ***********************************************************/
    public PUTFileJob.for_url (
        Account account,
        GLib.Uri url,
        GLib.OutputStream device,
        GLib.HashTable<string, string> headers,
        int chunk,
        GLib.Object parent = new GLib.Object ()
    ) {
        //  base (account, "", parent);
        //  this.device = device.release ();
        //  this.headers = headers;
        //  this.url = url;
        //  this.chunk = chunk;
        //  this.device.parent (this);
    }


    ~PUTFileJob () {
        //  // Make sure that we destroy the GLib.InputStream before our this.device of which it keeps an internal pointer.
        //  this.input_stream = null;
    }

    /***********************************************************
    ***********************************************************/
    public new void start () {
        //  Soup.Request request = new Soup.Request ();
        //  foreach (var header in this.headers) {
        //      request.raw_header (header.key (), header.value ());
        //  }

        //  request.priority (Soup.Request.Low_priority); // Long uploads must not block non-propagation jobs.

        //  if (this.url.is_valid != null) {
        //      send_request ("PUT", this.url, request, this.device);
        //  } else {
        //      send_request ("PUT", make_dav_url (path), request, this.device);
        //  }

        //  if (this.input_stream.error != GLib.InputStream.NoError) {
        //      GLib.warning (" Network error: " + this.input_stream.error_string);
        //  }

        //  this.input_stream.signal_upload_progress.connect (
        //      this.on_signal_upload_progress
        //  );
        //  this.signal_network_activity.connect (
        //      account.on_signal_propagator_network_activity
        //  );
        //  this.request_timer.start ();
        //  AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    public bool on_signal_finished () {
        //  this.device.close ();

        //  GLib.info ("PUT of " + this.input_stream.request ().url.to_string () + " finished with status "
        //      + reply_status_string ()
        //      + this.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute)
        //      + this.input_stream.attribute (Soup.Request.HttpReasonPhraseAttribute));

        //  signal_finished ();
        //  return true;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.TimeSpan microseconds_since_start {
        //  public get {
        //      return GLib.TimeSpan (this.request_timer.elapsed ());
        //  }
    }

} // class PUTFileJob

} // namespace LibSync
} // namespace Occ
