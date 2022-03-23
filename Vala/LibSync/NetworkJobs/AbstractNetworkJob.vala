namespace Occ {
namespace LibSync {

/***********************************************************
@class AbstractNetworkJob

@brief The AbstractNetworkJob class

@author Olivier Goffart <ogoffart@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>
@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class AbstractNetworkJob : GLib.Object {

    /***********************************************************
    Tags for checksum header.
    It's here for being shared between Upload- and Download Job
    ***********************************************************/
    const string CHECK_SUM_HEADER_C = "OC-Checksum";
    const string CONTENT_MD5_HEADER_C = "Content-MD5";

    /***********************************************************
    @brief Internal Helper class
    ***********************************************************/
    class NetworkJobTimeoutPauser {

        /***********************************************************
        ***********************************************************/
        private GLib.Timeout timer;

        /***********************************************************
        ***********************************************************/
        public NetworkJobTimeoutPauser (GLib.InputStream input_stream) {
            this.timer = input_stream.property ("timer").value<GLib.Timeout> ();
            if (this.timer != null) {
                this.timer.stop ();
            }
        }

        ~NetworkJobTimeoutPauser () {
            if (this.timer != null) {
                this.timer.start ();
            }
        }
    }


    /***********************************************************
    static variable the HTTP timeout (in seconds).

    If set to 0, the default will be used
    If not set, it is overwritten by the Application constructor
    with the value from the config
    ***********************************************************/
    static int http_timeout = q_environment_variable_int_value ("OWNCLOUD_TIMEOUT");

    /***********************************************************
    On get ():
    //  ASSERT (!this.response_timestamp == "");
    ***********************************************************/
    public string response_timestamp { public get; protected set; }

    /***********************************************************
    Set to true when the timeout slot is received
    ***********************************************************/
    protected bool timedout;


    /***********************************************************
    Whether to handle redirects transparently.

    Automatically follows redirects. Note that this only works
    for GET requests that don't set up any HTTP body or other
    flags.

    If true, a follow-up request is issued automatically when
    a redirect is encountered. The on_signal_finished ()
    function is only called if there are no more redirects
    (or there are problems with the redirect).

    The transparent redirect following may be disabled for some
    requests where custom handling is necessary.
    ***********************************************************/
    public bool follow_redirects;

    public unowned Account account { public get; protected set; }

    public bool ignore_credential_failure;

    /***********************************************************
    (QPointer because the NetworkManager may be destroyed before
    the jobs at exit)
    ***********************************************************/
    public GLib.InputStream input_stream {
        public get {
            return this.input_stream;
        }
        public set {
            if (value != null) {
                value.property ("do_not_handle_auth", true);
            }

            GLib.InputStream old = this.input_stream;
            this.input_stream = value;
            old = null;
        }
    }

    public string path;


    private GLib.Timeout timer;
    private int redirect_count = 0;
    private int http2_resend_count = 0;

    /***********************************************************
    Set by the xyz_request () functions and needed to be able to
    redirect requests, should it be required.

    Reparented to the currently running GLib.InputStream.
    ***********************************************************/
    private QIODevice request_body;

    /***********************************************************
    Emitted on network error.

    \a input_stream is never null
    ***********************************************************/
    internal signal void signal_network_error (GLib.InputStream input_stream);
    internal signal void signal_network_activity ();


    /***********************************************************
    Emitted when a redirect is followed.

    \a input_stream The "please redirect" input_stream
    \a target_url Where to redirect to
    \a redirect_count Counts redirect hops, first is 0.
    ***********************************************************/
    internal signal void redirected (GLib.InputStream input_stream, GLib.Uri target_url, int redirect_count);

    /***********************************************************
    ***********************************************************/
    public AbstractNetworkJob.for_account (Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.timedout = false;
        this.follow_redirects = true;
        this.account = account;
        this.ignore_credential_failure = false;
        this.input_stream = null;
        this.path = path;
        // Since we hold a unowned to the account, this makes no sense. (issue #6893)
        //  ASSERT (account != parent);

        this.timer.single_shot (true);
        this.timer.interval (
            (http_timeout ? http_timeout : 300) * 1000
        ); // default to 5 minutes.
        this.timer.timeout.connect (
            this.on_signal_timeout
        );

        this.signal_network_activity.connect (
            this.reset_timeout
        );

        // Network activity on the propagator jobs (GET/PUT) keeps all requests alive.
        // This is a workaround for OC instances which only support one
        // parallel up and download
        if (this.account != null) {
            this.account.signal_propagator_network_activity.connect (
                this.reset_timeout
            );
        }
    }


    ~AbstractNetworkJob () {
        input_stream = null;
    }


    /***********************************************************
    ***********************************************************/
    public void start () {
        this.timer.start ();

        GLib.Uri url = account.url;
        string display_url = "%1://%2%3".printf (url.scheme ()).printf (url.host ()).printf (url.this.path);

        string parent_meta_object_name = parent () ? parent ().meta_object ().class_name (): "";
        GLib.info (meta_object ().class_name () + " created for " + display_url + " + " + this.path + parent_meta_object_name);
    }


    /***********************************************************
    Content of the X-Request-ID header. (Only set after the
    request is sent)
    ***********************************************************/
    public string request_id () {
        return this.input_stream != null ? this.input_stream.request ().raw_header ("X-Request-ID") : "";
    }


    /***********************************************************
    ***********************************************************/
    public int64 timeout_msec () {
        return this.timer.interval ();
    }


    /***********************************************************
    ***********************************************************/
    public bool timed_out () {
        return this.timedout;
    }


    /***********************************************************
    Returns an error message, if any.
    ***********************************************************/
    public string error_string {
        public get {
            if (this.timedout) {
                return _("Connection timed out");
            } else if (this.input_stream == null) {
                return _("Unknown error : network input_stream was deleted");
            } else if (this.input_stream.has_raw_header ("OC-ErrorString")) {
                return this.input_stream.raw_header ("OC-ErrorString");
            } else {
                return network_reply_error_string (*this.input_stream);
            }
        }
    }


    /***********************************************************
    Like error_string, but also checking the input_stream body for
    information.

    Specifically, sometimes xml bodies have extra error information.
    This function reads the body of the input_stream and parses out the
    error information, if possible.

    \a body is optinally filled with the input_stream body.

    Warning : Needs to call this.input_stream.read_all ().
    ***********************************************************/
    public string error_string_parsing_body (string body = "") {
        string base_string = this.error_string;
        if (base_string == "" || this.input_stream == null) {
            return "";
        }

        string reply_body = this.input_stream.read_all ();
        if (body != "") {
            *body = reply_body;
        }

        string extra = extract_error_message (reply_body);
        // Don't append the XML error message to a OC-ErrorString message.
        if (!extra == "" && !this.input_stream.has_raw_header ("OC-ErrorString")) {
            return "%1 (%2)".printf (base_string, extra);
        }

        return base_string;
    }


    /***********************************************************
    Make a new request
    ***********************************************************/
    public void retry () {
        //  ENFORCE (this.input_stream);
        var request = this.input_stream.request ();
        GLib.Uri requested_url = request.url;
        string verb = HttpLogger.request_verb (*this.input_stream);
        GLib.info ("Restarting " + verb + requested_url);
        reset_timeout ();
        if (this.request_body != null) {
            this.request_body.seek (0);
        }
        // The cookie will be added automatically, we don't want AccessManager.create_request to duplicate them
        request.raw_header ("cookie", "");
        send_request (verb, requested_url, request, this.request_body);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_timeout (int64 msec) {
        this.timer.start (msec);
    }

    //  private void on_signal_timeout () {
    //      this.timedout = true;
    //      GLib.warning ("Network job timeout" + (this.input_stream ? this.input_stream.request ().url : this.path);
    //      on_signal_timed_out ();
    //  }


    /***********************************************************
    ***********************************************************/
    public void reset_timeout () {
        int64 interval = this.timer.interval ();
        this.timer.stop ();
        this.timer.start (interval);
    }


    /***********************************************************
    Initiate a network request, returning a GLib.InputStream.

    Calls this.input_stream and up_connections () on it.

    Takes ownership of the request_body (to allow redirects).
    ***********************************************************/
    protected GLib.InputStream send_request_for_device (
        string verb,
        GLib.Uri url,
        Soup.Request request = new Soup.Request (),
        QIODevice request_body = null) {
        var input_stream = this.account.send_raw_request (verb, url, request, request_body);
        this.request_body = null;
        adopt_request (input_stream);
        return input_stream;
    }


    protected GLib.InputStream send_request_for_multipart (
        string verb,
        GLib.Uri url,
        Soup.Request request,
        Soup.Multipart request_body) {
        var input_stream = this.account.send_raw_request (verb, url, request, request_body);
        this.request_body = null;
        adopt_request (input_stream);
        return input_stream;
    }


    /***********************************************************
    send_request does not take a relative path instead of an url,
    but the old API allowed that. We have this undefined
    overload to help catch usage errors
    ***********************************************************/
    protected GLib.InputStream send_request_for_relative_path (
        string verb,
        string relative_path,
        Soup.Request request = new Soup.Request (),
        QIODevice request_body = null
    ) {
        var input_stream = this.account.send_raw_request (verb, url, request, request_body);
        this.request_body = request_body;
        if (this.request_body != null) {
            this.request_body.parent (input_stream);
        }
        adopt_request (input_stream);
        return input_stream;
    }


    /***********************************************************
    Makes this job drive a pre-made GLib.InputStream

    This input_stream cannot have a QIODevice request body because we can't get
    at it and thus not resend it in case of redirects.
    ***********************************************************/
    protected void adopt_request (GLib.InputStream input_stream) {
        this.add_timer (input_stream);
        this.input_stream = input_stream;
        this.up_connections = input_stream;
        this.new_reply_hook (input_stream);
    }


    protected GLib.InputStream up_connections {
        protected set {
            value.signal_finished.connect (
                this.on_signal_finished
            );
            value.encrypted.connect (
                this.on_signal_network_activity
            );
            value.manager.signal_proxy_authentication_required.connect (
                this.on_signal_network_activity
            );
            value.signal_ssl_errors.connect (
                this.on_signal_network_activity
            );
            value.meta_data_changed.connect (
                this.on_signal_network_activity
            );
            value.download_progress.connect (
                this.on_signal_network_activity
            );
            value.signal_upload_progress.connect (
                this.on_signal_network_activity
            );
        }
    }


    /***********************************************************
    Can be used by derived classes to set up the network input_stream.

    Particularly useful when the request is redirected and
    this.input_stream changes. For things like setting up additional
    signal connections on the new input_stream.
    ***********************************************************/
    protected virtual void new_reply_hook (GLib.InputStream input_stream) {}


    /***********************************************************
    Creates a url for the account from a relative path
    ***********************************************************/
    protected GLib.Uri make_account_url (string relative_path) {
        return Utility.concat_url_path (this.account.url, relative_path);
    }


    /***********************************************************
    Like make_account_url () but uses the account's dav base
    path
    ***********************************************************/
    protected GLib.Uri make_dav_url (string relative_path) {
        return Utility.concat_url_path (this.account.dav_url (), relative_path);
    }


    /***********************************************************
    ***********************************************************/
    protected int max_redirects () {
        return 10;
    }


    /***********************************************************
    Called on timeout.

    The default implementation aborts the input_stream.
    ***********************************************************/
    protected virtual void on_signal_timed_out () {
        if (this.input_stream != null) {
            this.input_stream.abort ();
        } else {
            delete_later ();
        }
    }


    protected string reply_status_string () {
        GLib.assert (this.input_stream);
        if (this.input_stream.error == GLib.InputStream.NoError) {
            return "OK";
        } else {
            string enumber_of_str = QMetaEnum.from_type<GLib.InputStream.NetworkError> ().value_to_key (static_cast<int> (this.input_stream.error));
            return "%1 %2".printf (enumber_of_str, this.error_string);
        }
    }


    /***********************************************************
    ***********************************************************/
    private GLib.InputStream add_timer (GLib.InputStream input_stream) {
        input_stream.property ("timer", GLib.Variant.from_value (&this.timer));
        return input_stream;
    }


    /***********************************************************
    Called at the end of GLib.InputStream.on_signal_finished processing.

    Returning true triggers a delete_later () of this job.
    ***********************************************************/
    private void on_signal_finished () {
        this.timer.stop ();

        if (this.input_stream.error == GLib.InputStream.SslHandshakeFailedError) {
            GLib.warning ("SslHandshakeFailedError: " + this.error_string + ": can be caused by a webserver wanting SSL client certificates.");
        }
        // Qt doesn't yet transparently resend HTTP2 requests, do so here
        var max_http2Resends = 3;
        string verb = HttpLogger.request_verb (*this.input_stream);
        if (this.input_stream.error == GLib.InputStream.ContentReSendError
            && this.input_stream.attribute (Soup.Request.HTTP2WasUsedAttribute).to_bool ()) {

            if ( (this.request_body != null && !this.request_body.is_sequential ()) || verb == "") {
                GLib.warning (
                    "Can't resend HTTP2 request; verb or body not suitable "
                    + this.input_stream.request ().url + verb + this.request_body
                );
            } else if (this.http2_resend_count >= max_http2Resends) {
                GLib.warning (
                    "Not resending HTTP2 request; number of resends exhausted "
                    + this.input_stream.request ().url + this.http2_resend_count
                );
            } else {
                GLib.info ("HTTP2 resending " + this.input_stream.request ().url);
                this.http2_resend_count++;

                reset_timeout ();
                if (this.request_body != null) {
                    if (!this.request_body.is_open) {
                        this.request_body.open (QIODevice.ReadOnly);
                    }
                    this.request_body.seek (0);
                }
                send_request (
                    verb,
                    this.input_stream.request ().url,
                    this.input_stream.request (),
                    this.request_body);
                return;
            }
        }

        if (this.input_stream.error != GLib.InputStream.NoError) {

            if (this.account.credentials.retry_if_needed (this)) {
                return;
            }

            if (!this.ignore_credential_failure || this.input_stream.error != GLib.InputStream.AuthenticationRequiredError) {
                GLib.warning (this.input_stream.error + this.error_string
                    + this.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute));
                if (this.input_stream.error == GLib.InputStream.ProxyAuthenticationRequiredError) {
                    GLib.warning (this.input_stream.raw_header ("Proxy-Authenticate"));
                }
            }
            /* emit */ signal_network_error (this.input_stream);
        }

        // get the Date timestamp from input_stream
        this.response_timestamp = this.input_stream.raw_header ("Date");

        GLib.Uri requested_url = this.input_stream.request ().url;
        GLib.Uri redirect_url = this.input_stream.attribute (Soup.Request.RedirectionTargetAttribute).to_url ();
        if (this.follow_redirects && !redirect_url == "") {
            // Redirects may be relative
            if (redirect_url.is_relative ())
                redirect_url = requested_url.resolved (redirect_url);

            // For POST requests where the target url has query arguments, Qt automatically
            // moves these arguments to the body if no explicit body is specified.
            // This can cause problems with redirected requests, because the redirect url
            // will no longer contain these query arguments.
            if (this.input_stream.operation () == Soup.Session.PostOperation
                && requested_url.has_query ()
                && !redirect_url.has_query ()
                && this.request_body == null
            ) {
                GLib.warning ("Redirecting a POST request with an implicit body loses that body.");
            }

            // ### some of the q_warnings here should be exported via display_errors () so they
            // ### can be presented to the user if the job executor has a GUI
            if (requested_url.scheme () == "https" && redirect_url.scheme () == "http") {
                GLib.warning (this + " HTTPS.HTTP downgrade detected!");
            } else if (requested_url == redirect_url || this.redirect_count + 1 >= max_redirects ()) {
                GLib.warning (this + " Redirect loop detected!");
            } else if (this.request_body != null && this.request_body.is_sequential ()) {
                GLib.warning (this + " cannot redirect request with sequential body.");
            } else if (verb == "") {
                GLib.warning (this + " cannot redirect request: could not detect original verb.");
            } else {
                /* emit */ redirected (this.input_stream, redirect_url, this.redirect_count);

                // The signal emission may have changed this value
                if (this.follow_redirects) {
                    this.redirect_count++;

                    // Create the redirected request and send it
                    GLib.info ("Redirecting " + verb + requested_url + redirect_url);
                    reset_timeout ();
                    if (this.request_body != null) {
                        if (!this.request_body.is_open) {
                            // Avoid the QIODevice.seek (Soup.Buffer) : The device is not open warning message
                            this.request_body.open (QIODevice.ReadOnly);
                        }
                        this.request_body.seek (0);
                    }
                    send_request (
                        verb,
                        redirect_url,
                        this.input_stream.request (),
                        this.request_body);
                    return;
                }
            }
        }

        if (!this.account.credentials.still_valid (this.input_stream) && !this.ignore_credential_failure) {
            this.account.handle_invalid_credentials ();
        }

        /*bool discard =*/ on_signal_finished ();
        if (discard) {
            GLib.debug ("Network job " + meta_object ().class_name () + " finished for " + this.path);
            delete_later ();
        }
    }


    /***********************************************************
    Gets the SabreDAV-style error message from an error response.

    This assumes the response is XML with a 'error' tag that has a
    'message' tag that contains the data to extract.

    Returns a null string if no message was found.
    ***********************************************************/
    private static string extract_error_message (string error_response) {
        QXmlStreamReader reader = new QXmlStreamReader (error_response);
        reader.read_next_start_element ();
        if (reader.name () != "error") {
            return "";
        }

        string exception;
        while (!reader.at_end () && !reader.has_error ()) {
            reader.read_next_start_element ();
            if (reader.name () == "message") {
                string message = reader.read_element_text ();
                if (!message == "") {
                    return message;
                }
            } else if (reader.name () == "exception") {
                exception = reader.read_element_text ();
            }
        }
        // Fallback, if message could not be found
        return exception;
    }


    /***********************************************************
    Builds a error message based on the error and the input_stream body.
    ***********************************************************/
    private static string error_message (string base_error, string body) {
        string message = base_error;
        string extra = extract_error_message (body);
        if (extra != "") {
            message += " (%1)".printf (extra);
        }
        return message;
    }


    /***********************************************************
    Nicer this.error_string for GLib.InputStream

    By default GLib.InputStream.error_string often produces messages like
    "Error downloading <url> - server replied : <reason>"
    but the "downloading" part invariably confuses people since the
    error might very well have been produced by a PUT request.

    This function produces clearer error messages for HTTP errors.
    ***********************************************************/
    private static string network_reply_error_string (GLib.InputStream input_stream) {
        string base_string = input_stream.error_string;
        int http_status = input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        string http_reason = input_stream.attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ();

        // Only adjust HTTP error messages of the expected format.
        if (http_reason == "" || http_status == 0 || !base_string.contains (http_reason)) {
            return base_string;
        }

        return _(" (Server replied \"%1 %2\" to \"%3 %4\")").printf (string.number (http_status), http_reason, HttpLogger.request_verb (input_stream), input_stream.request ().url.to_display_string ());
    }

} // class AbstractNetworkJob

} // namespace LibSync
} // namespace Occ
