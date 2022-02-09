/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <Soup.Request>
//  #include <QNetworkAccessManager>
//  #include <Soup.Request>
//  #include <QSslConfigur
//  #include <Soup.Buffer>
//  #include <QXmlStrea
//  #include <string[
//  #include <GLib.List>
//  #include <QTimer>
//  #include <QMutex>
//  #include <QCoreApplicatio
//  #include <QAuthentic
//  #include <QMetaEnum>
//  #include <QRegularExpression>

//  #include <Soup.Request>
//  #include <QPointer>
//  #include <QElapsedTimer>
//  #include <QTimer>

namespace Occ {

/***********************************************************
@brief The AbstractNetworkJob class
@ingroup libsync
***********************************************************/
class AbstractNetworkJob : GLib.Object {

    /***********************************************************
    @brief Internal Helper class
    ***********************************************************/
    class NetworkJobTimeoutPauser {

        /***********************************************************
        ***********************************************************/
        private QPointer<QTimer> timer;

        /***********************************************************
        ***********************************************************/
        public NetworkJobTimeoutPauser (Soup.Reply reply) {
            this.timer = reply.property ("timer").value<QTimer> ();
            if (!this.timer.is_null ()) {
                this.timer.stop ();
            }
        }
    
        ~NetworkJobTimeoutPauser () {
            if (!this.timer.is_null ()) {
                this.timer.on_signal_start ();
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
    //  ASSERT (!this.response_timestamp.is_empty ());
    ***********************************************************/
    GLib.ByteArray response_timestamp { public get; protected set; }

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

    AccountPointer account { public get; protected set; }

    public bool ignore_credential_failure;

    /***********************************************************
    (QPointer because the NetworkManager may be destroyed before
    the jobs at exit)
    ***********************************************************/
    QPointer<Soup.Reply> reply {
        public get {
            return this.reply;
        }
        public set {
            if (value) {
                value.property ("do_not_handle_auth", true);
            }

            Soup.Reply old = this.reply;
            this.reply = value;
            delete old;
        }
    }

    public string path;


    private QTimer timer;
    private int redirect_count = 0;
    private int http2_resend_count = 0;

    /***********************************************************
    Set by the xyz_request () functions and needed to be able to
    redirect requests, should it be required.

    Reparented to the currently running Soup.Reply.
    ***********************************************************/
    private QPointer<QIODevice> request_body;

    /***********************************************************
    Emitted on network error.

    \a reply is never null
    ***********************************************************/
    signal void network_error (Soup.Reply reply);
    signal void network_activity ();


    /***********************************************************
    Emitted when a redirect is followed.

    \a reply The "please redirect" reply
    \a target_url Where to redirect to
    \a redirect_count Counts redirect hops, first is 0.
    ***********************************************************/
    signal void redirected (Soup.Reply reply, GLib.Uri target_url, int redirect_count);

    /***********************************************************
    ***********************************************************/
    public AbstractNetworkJob.for_account (AccountPointer account, string path, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.timedout = false;
        this.follow_redirects = true;
        this.account = account;
        this.ignore_credential_failure = false;
        this.reply = null;
        this.path = path;
        // Since we hold a unowned to the account, this makes no sense. (issue #6893)
        //  ASSERT (account != parent);

        this.timer.single_shot (true);
        this.timer.interval ( (http_timeout ? http_timeout : 300) * 1000); // default to 5 minutes.
        connect (&this.timer, &QTimer.timeout, this, &AbstractNetworkJob.on_signal_timeout);

        connect (this, &AbstractNetworkJob.network_activity, this, &AbstractNetworkJob.on_signal_reset_timeout);

        // Network activity on the propagator jobs (GET/PUT) keeps all requests alive.
        // This is a workaround for OC instances which only support one
        // parallel up and download
        if (this.account) {
            connect (this.account.data (), &Account.propagator_network_activity, this, &AbstractNetworkJob.on_signal_reset_timeout);
        }
    }


    ~AbstractNetworkJob () {
        reply (null);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        this.timer.on_signal_start ();

        const GLib.Uri url = account ().url ();
        const string display_url = string ("%1://%2%3").arg (url.scheme ()).arg (url.host ()).arg (url.path ());

        string parent_meta_object_name = parent () ? parent ().meta_object ().class_name () : "";
        GLib.info (meta_object ().class_name ("created for" + display_url + "+" + path () + parent_meta_object_name;
    }


    /***********************************************************
    Content of the X-Request-ID header. (Only set after the
    request is sent)
    ***********************************************************/
    public GLib.ByteArray request_id () {
        return  this.reply ? this.reply.request ().raw_header ("X-Request-ID") : GLib.ByteArray ();
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
    public virtual string error_string () {
        if (this.timedout) {
            return _("Connection timed out");
        } else if (!reply ()) {
            return _("Unknown error : network reply was deleted");
        } else if (reply ().has_raw_header ("OC-ErrorString")) {
            return reply ().raw_header ("OC-ErrorString");
        } else {
            return network_reply_error_string (*reply ());
        }
    }


    /***********************************************************
    Like error_string, but also checking the reply body for
    information.

    Specifically, sometimes xml bodies have extra error information.
    This function reads the body of the reply and parses out the
    error information, if possible.

    \a body is optinally filled with the reply body.

    Warning : Needs to call reply ().read_all ().
    ***********************************************************/
    public string error_string_parsing_body (GLib.ByteArray body = null) {
        string base = error_string ();
        if (base.is_empty () || !reply ()) {
            return "";
        }

        GLib.ByteArray reply_body = reply ().read_all ();
        if (body) {
            *body = reply_body;
        }

        string extra = extract_error_message (reply_body);
        // Don't append the XML error message to a OC-ErrorString message.
        if (!extra.is_empty () && !reply ().has_raw_header ("OC-ErrorString")) {
            return string.from_latin1 ("%1 (%2)").arg (base, extra);
        }

        return base;
    }


    /***********************************************************
    Make a new request
    ***********************************************************/
    public void retry () {
        //  ENFORCE (this.reply);
        var request = this.reply.request ();
        GLib.Uri requested_url = request.url ();
        GLib.ByteArray verb = HttpLogger.request_verb (*this.reply);
        GLib.info ("Restarting" + verb + requested_url;
        on_signal_reset_timeout ();
        if (this.request_body) {
            this.request_body.seek (0);
        }
        // The cookie will be added automatically, we don't want AccessManager.create_request to duplicate them
        request.raw_header ("cookie", GLib.ByteArray ());
        send_request (verb, requested_url, request, this.request_body);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_timeout (int64 msec) {
        this.timer.on_signal_start (msec);
    }

    //  private void on_signal_timeout () {
    //      this.timedout = true;
    //      GLib.warning ("Network job timeout" + (reply () ? reply ().request ().url () : path ());
    //      on_signal_timed_out ();
    //  }


    /***********************************************************
    ***********************************************************/
    public void on_signal_reset_timeout () {
        int64 interval = this.timer.interval ();
        this.timer.stop ();
        this.timer.on_signal_start (interval);
    }


    /***********************************************************
    Initiate a network request, returning a Soup.Reply.

    Calls reply () and up_connections () on it.

    Takes ownership of the request_body (to allow redirects).
    ***********************************************************/
    protected Soup.Reply send_request_for_device (
        GLib.ByteArray verb,
        GLib.Uri url,
        Soup.Request request = Soup.Request (),
        QIODevice request_body = null) {
        var reply = this.account.send_raw_request (verb, url, request, request_body);
        this.request_body = null;
        adopt_request (reply);
        return reply;
    }


    protected Soup.Reply send_request_for_multipart (
        GLib.ByteArray verb,
        GLib.Uri url,
        Soup.Request request,
        QHttpMultiPart request_body) {
        var reply = this.account.send_raw_request (verb, url, request, request_body);
        this.request_body = null;
        adopt_request (reply);
        return reply;
    }


    /***********************************************************
    send_request does not take a relative path instead of an url,
    but the old API allowed that. We have this undefined
    overload to help catch usage errors
    ***********************************************************/
    protected Soup.Reply send_request_for_relative_path (
        GLib.ByteArray verb,
        string relative_path,
        Soup.Request request = Soup.Request (),
        QIODevice request_body = null) {
        var reply = this.account.send_raw_request (verb, url, request, request_body);
        this.request_body = request_body;
        if (this.request_body) {
            this.request_body.parent (reply);
        }
        adopt_request (reply);
        return reply;
    }


    /***********************************************************
    Makes this job drive a pre-made Soup.Reply

    This reply cannot have a QIODevice request body because we can't get
    at it and thus not resend it in case of redirects.
    ***********************************************************/
    protected void adopt_request (Soup.Reply reply) {
        add_timer (reply);
        reply (reply);
        up_connections (reply);
        new_reply_hook (reply);
    }


    protected void up_connections (Soup.Reply reply) {
        connect (reply, &Soup.Reply.on_signal_finished, this, &AbstractNetworkJob.on_signal_finished);
        connect (reply, &Soup.Reply.encrypted, this, &AbstractNetworkJob.network_activity);
        connect (reply.manager (), &QNetworkAccessManager.proxy_authentication_required, this, &AbstractNetworkJob.network_activity);
        connect (reply, &Soup.Reply.ssl_errors, this, &AbstractNetworkJob.network_activity);
        connect (reply, &Soup.Reply.meta_data_changed, this, &AbstractNetworkJob.network_activity);
        connect (reply, &Soup.Reply.download_progress, this, &AbstractNetworkJob.network_activity);
        connect (reply, &Soup.Reply.upload_progress, this, &AbstractNetworkJob.network_activity);
    }


    /***********************************************************
    Can be used by derived classes to set up the network reply.

    Particularly useful when the request is redirected and
    reply () changes. For things like setting up additional
    signal connections on the new reply.
    ***********************************************************/
    protected virtual void new_reply_hook (Soup.Reply *) {}


    /***********************************************************
    Creates a url for the account from a relative path
    ***********************************************************/
    protected GLib.Uri make_account_url (string relative_path) {
        return Utility.concat_url_path (this.account.url (), relative_path);
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

    The default implementation aborts the reply.
    ***********************************************************/
    protected virtual void on_signal_timed_out () {
        if (reply ()) {
            reply ().on_signal_abort ();
        } else {
            delete_later ();
        }
    }


    protected string reply_status_string () {
        //  Q_ASSERT (reply ());
        if (reply ().error () == Soup.Reply.NoError) {
            return QLatin1String ("OK");
        } else {
            string enum_str = QMetaEnum.from_type<Soup.Reply.NetworkError> ().value_to_key (static_cast<int> (reply ().error ()));
            return QStringLiteral ("%1 %2").arg (enum_str, error_string ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private Soup.Reply add_timer (Soup.Reply reply) {
        reply.property ("timer", GLib.Variant.from_value (&this.timer));
        return reply;
    }


    /***********************************************************
    Called at the end of Soup.Reply.on_signal_finished processing.

    Returning true triggers a delete_later () of this job.
    ***********************************************************/
    private void on_signal_finished () {
        this.timer.stop ();

        if (this.reply.error () == Soup.Reply.SslHandshakeFailedError) {
            GLib.warning ("SslHandshakeFailedError : " + error_string (" : can be caused by a webserver wanting SSL client certificates";
        }
        // Qt doesn't yet transparently resend HTTP2 requests, do so here
        var max_http2Resends = 3;
        GLib.ByteArray verb = HttpLogger.request_verb (*reply ());
        if (this.reply.error () == Soup.Reply.ContentReSendError
            && this.reply.attribute (Soup.Request.HTTP2WasUsedAttribute).to_bool ()) {

            if ( (this.request_body && !this.request_body.is_sequential ()) || verb.is_empty ()) {
                GLib.warning ("Can't resend HTTP2 request, verb or body not suitable"
                                        + this.reply.request ().url () + verb + this.request_body;
            } else if (this.http2_resend_count >= max_http2Resends) {
                GLib.warning ("Not resending HTTP2 request, number of resends exhausted"
                                        + this.reply.request ().url () + this.http2_resend_count;
            } else {
                GLib.info ("HTTP2 resending" + this.reply.request ().url ();
                this.http2_resend_count++;

                on_signal_reset_timeout ();
                if (this.request_body) {
                    if (!this.request_body.is_open ())
                    this.request_body.open (QIODevice.ReadOnly);
                    this.request_body.seek (0);
                }
                send_request (
                    verb,
                    this.reply.request ().url (),
                    this.reply.request (),
                    this.request_body);
                return;
            }
        }

        if (this.reply.error () != Soup.Reply.NoError) {

            if (this.account.credentials ().retry_if_needed (this))
                return;

            if (!this.ignore_credential_failure || this.reply.error () != Soup.Reply.AuthenticationRequiredError) {
                GLib.warning () + this.reply.error () + error_string ()
                                        + this.reply.attribute (Soup.Request.HttpStatusCodeAttribute);
                if (this.reply.error () == Soup.Reply.ProxyAuthenticationRequiredError) {
                    GLib.warning () + this.reply.raw_header ("Proxy-Authenticate");
                }
            }
            /* emit */ network_error (this.reply);
        }

        // get the Date timestamp from reply
        this.response_timestamp = this.reply.raw_header ("Date");

        GLib.Uri requested_url = reply ().request ().url ();
        GLib.Uri redirect_url = reply ().attribute (Soup.Request.RedirectionTargetAttribute).to_url ();
        if (this.follow_redirects && !redirect_url.is_empty ()) {
            // Redirects may be relative
            if (redirect_url.is_relative ())
                redirect_url = requested_url.resolved (redirect_url);

            // For POST requests where the target url has query arguments, Qt automatically
            // moves these arguments to the body if no explicit body is specified.
            // This can cause problems with redirected requests, because the redirect url
            // will no longer contain these query arguments.
            if (reply ().operation () == QNetworkAccessManager.PostOperation
                && requested_url.has_query ()
                && !redirect_url.has_query ()
                && !this.request_body) {
                GLib.warning ("Redirecting a POST request with an implicit body loses that body";
            }

            // ### some of the q_warnings here should be exported via display_errors () so they
            // ### can be presented to the user if the job executor has a GUI
            if (requested_url.scheme () == QLatin1String ("https") && redirect_url.scheme () == QLatin1String ("http")) {
                GLib.warning () + this + "HTTPS.HTTP downgrade detected!";
            } else if (requested_url == redirect_url || this.redirect_count + 1 >= max_redirects ()) {
                GLib.warning () + this + "Redirect loop detected!";
            } else if (this.request_body && this.request_body.is_sequential ()) {
                GLib.warning () + this + "cannot redirect request with sequential body";
            } else if (verb.is_empty ()) {
                GLib.warning () + this + "cannot redirect request : could not detect original verb";
            } else {
                /* emit */ redirected (this.reply, redirect_url, this.redirect_count);

                // The signal emission may have changed this value
                if (this.follow_redirects) {
                    this.redirect_count++;

                    // Create the redirected request and send it
                    GLib.info ("Redirecting" + verb + requested_url + redirect_url;
                    on_signal_reset_timeout ();
                    if (this.request_body) {
                        if (!this.request_body.is_open ()) {
                            // Avoid the QIODevice.seek (Soup.Buffer) : The device is not open warning message
                        this.request_body.open (QIODevice.ReadOnly);
                        }
                        this.request_body.seek (0);
                    }
                    send_request (
                        verb,
                        redirect_url,
                        reply ().request (),
                        this.request_body);
                    return;
                }
            }
        }

        AbstractCredentials creds = this.account.credentials ();
        if (!creds.still_valid (this.reply) && !this.ignore_credential_failure) {
            this.account.handle_invalid_credentials ();
        }

        bool discard = on_signal_finished ();
        if (discard) {
            GLib.debug ("Network job" + meta_object ().class_name ("on_signal_finished for" + path ();
            delete_later ();
        }
    }

}


    /***********************************************************
    Gets the SabreDAV-style error message from an error response.

    This assumes the response is XML with a 'error' tag that has a
    'message' tag that contains the data to extract.

    Returns a null string if no message was found.
    ***********************************************************/
    string extract_error_message (GLib.ByteArray error_response) {
        QXmlStreamReader reader = new QXmlStreamReader (error_response);
        reader.read_next_start_element ();
        if (reader.name () != "error") {
            return "";
        }

        string exception;
        while (!reader.at_end () && !reader.has_error ()) {
            reader.read_next_start_element ();
            if (reader.name () == QLatin1String ("message")) {
                string message = reader.read_element_text ();
                if (!message.is_empty ()) {
                    return message;
                }
            } else if (reader.name () == QLatin1String ("exception")) {
                exception = reader.read_element_text ();
            }
        }
        // Fallback, if message could not be found
        return exception;
    }


    /***********************************************************
    Builds a error message based on the error and the reply body.
    ***********************************************************/
    string error_message (string base_error, GLib.ByteArray body) {
        string message = base_error;
        string extra = extract_error_message (body);
        if (!extra.is_empty ()) {
            message += string.from_latin1 (" (%1)").arg (extra);
        }
        return message;
    }


    /***********************************************************
    Nicer error_string () for Soup.Reply

    By default Soup.Reply.error_string () often produces messages like
    "Error downloading <url> - server replied : <reason>"
    but the "downloading" part invariably confuses people since the
    error might very well have been produced by a PUT request.

    This function produces clearer error messages for HTTP errors.
    ***********************************************************/
    string network_reply_error_string (Soup.Reply reply) {
        string base = reply.error_string ();
        int http_status = reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        string http_reason = reply.attribute (Soup.Request.HttpReasonPhraseAttribute).to_string ();

        // Only adjust HTTP error messages of the expected format.
        if (http_reason.is_empty () || http_status == 0 || !base.contains (http_reason)) {
            return base;
        }

        return AbstractNetworkJob._(R" (Server replied \"%1 %2\" to \"%3 %4\")").arg (string.number (http_status), http_reason, HttpLogger.request_verb (reply), reply.request ().url ().to_display_"");
    }

} // class AbstractNetworkJob

} // namespace Occ