/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QNetworkRequest>
// #include <QNetworkAccessManager>
// #include <QNetworkReply>
// #include <QNetworkRequest>
// #include <QSslConfiguration>
// #include <QBuffer>
// #include <QXmlStreamReader>
// #include <string[]>
// #include <QStack>
// #include <QTimer>
// #include <QMutex>
// #include <QCoreApplication>
// #include <QAuthenticator>
// #include <QMetaEnum>
// #include <QRegularExpression>
// #pragma once

// #include <QNetworkRequest>
// #include <QNetworkReply>
// #include <QPointer>
// #include <QElapsedTimer>
// #include <QTimer>

namespace Occ {

// If not set, it is overwritten by the Application constructor with the value from the config
int AbstractNetworkJob.http_timeout = q_environment_variable_int_value ("OWNCLOUD_TIMEOUT");


/***********************************************************
@brief The AbstractNetworkJob class
@ingroup libsync
***********************************************************/
class AbstractNetworkJob : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public AbstractNetworkJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 
    public AccountPointer account () {
        return this.account;
    }


    /***********************************************************
    ***********************************************************/
    public void set_path (string path);

    /***********************************************************
    ***********************************************************/
    public 
    public string path () {
        return this.path;
    }


    /***********************************************************
    ***********************************************************/
    public void set_reply (QNetworkReply reply);

    /***********************************************************
    ***********************************************************/
    public 
    public QNetworkReply reply () {
        return this.reply;
    }


    /***********************************************************
    ***********************************************************/
    public void set_ignore_credential_failure (bool ignore);

    /***********************************************************
    ***********************************************************/
    public 
    public bool ignore_credential_failure () {
        return this.ignore_credential_failure;
    }


    /***********************************************************
    Whether to handle redirects transparently.

    If true, a follow-up request is issued automatically when
    a redirect is encountered. The on_finished () function is
    only called if there are no more redirects (or there are
    problems with the redirect).

    The transparent redirect following may be disabled for some
    requests where custom handling is necessary.
    ***********************************************************/
    public void set_follow_redirects (bool follow);


    /***********************************************************
    ***********************************************************/
    public bool follow_redirects () {
        return this.follow_redirects;
    }


    /***********************************************************
    ***********************************************************/
    public GLib.ByteArray response_timestamp ();


    /***********************************************************
    Content of the X-Request-ID header. (Only set after the
    request is sent)
    ***********************************************************/
    public GLib.ByteArray request_id ();

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
    public virtual string error_string ();


    /***********************************************************
    Like error_string, but also checking the reply body for
    information.

    Specifically, sometimes xml bodies have extra error information.
    This function reads the body of the reply and parses out the
    error information, if possible.

    \a body is optinally filled with the reply body.

    Warning : Needs to call reply ().read_all ().
    ***********************************************************/
    public string error_string_parsing_body (GLib.ByteArray body = nullptr);


    /***********************************************************
    Make a new request
    ***********************************************************/
    public void retry ();


    /***********************************************************
    static variable the HTTP timeout (in seconds).
    
    If set to 0, the default will be used
    ***********************************************************/
    static int http_timeout;


    /***********************************************************
    ***********************************************************/
    public void on_set_timeout (int64 msec);

    /***********************************************************
    ***********************************************************/
    public 
    public void on_reset_timeout ();
signals:
    /***********************************************************
    Emitted on network error.

    \a reply is never null
    ***********************************************************/
    void network_error (QNetworkReply reply);
    void network_activity ();


    /***********************************************************
    Emitted when a redirect is followed.

    \a reply The "please redirect" reply
    \a target_url Where to redirect to
    \a redirect_count Counts redirect hops, first is 0.
    ***********************************************************/
    void redirected (QNetworkReply reply, GLib.Uri target_url, int redirect_count);


    /***********************************************************
    Initiate a network request, returning a QNetworkReply.

    Calls set_reply () and setup_connections () on it.

    Takes ownership of the request_body (to allow redirects).
    ***********************************************************/
    protected QNetworkReply send_request (GLib.ByteArray verb, GLib.Uri url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice request_body = nullptr);

    protected QNetworkReply send_request (GLib.ByteArray verb, GLib.Uri url,
        QNetworkRequest req, GLib.ByteArray request_body);

    // send_request does not take a relative path instead of an url,
    // but the old API allowed that. We have this undefined overload
    // to help catch usage errors
    protected QNetworkReply send_request (GLib.ByteArray verb, string relative_path,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice request_body = nullptr);

    protected QNetworkReply send_request (GLib.ByteArray verb, GLib.Uri url,
        QNetworkRequest req, QHttpMultiPart request_body);


    /***********************************************************
    Makes this job drive a pre-made QNetworkReply

    This reply cannot have a QIODevice request body because we can't get
    at it and thus not resend it in case of redirects.
    ***********************************************************/
    protected void adopt_request (QNetworkReply reply);

    protected void setup_connections (QNetworkReply reply);


    /***********************************************************
    Can be used by derived classes to set up the network reply.

    Particularly useful when the request is redirected and reply ()
    changes. For things like setting up additional signal connections
    on the new reply.
    ***********************************************************/
    protected virtual void new_reply_hook (QNetworkReply *) {}

    /// Creates a url for the account from a relative path
    protected GLib.Uri make_account_url (string relative_path);

    /// Like make_account_url () but uses the account's dav base path
    protected GLib.Uri make_dav_url (string relative_path);

    protected int max_redirects () {
        return 10;
    }


    /***********************************************************
    Called at the end of QNetworkReply.on_finished processing.

    Returning true triggers a delete_later () of this job.
    ***********************************************************/
    protected virtual bool on_finished ();


    /***********************************************************
    Called on timeout.

    The default implementation aborts the reply.
    ***********************************************************/
    protected virtual void on_timed_out ();

    protected GLib.ByteArray this.response_timestamp;
    protected bool this.timedout; // set to true when the timeout slot is received

    // Automatically follows redirects. Note that this only works for
    // GET requests that don't set up any HTTP body or other flags.
    protected bool this.follow_redirects;

    protected string reply_status_"";


    /***********************************************************
    ***********************************************************/
    private void on_finished ();
    private void on_timeout ();


    protected AccountPointer this.account;


    /***********************************************************
    ***********************************************************/
    private QNetworkReply add_timer (QNetworkReply reply);
    private bool this.ignore_credential_failure;
    private QPointer<QNetworkReply> this.reply; // (QPointer because the NetworkManager may be destroyed before the jobs at exit)
    private string this.path;
    private QTimer this.timer;
    private int this.redirect_count = 0;
    private int this.http2_resend_count = 0;

    // Set by the xyz_request () functions and needed to be able to redirect
    // requests, should it be required.
    //
    // Reparented to the currently running QNetworkReply.
    private QPointer<QIODevice> this.request_body;
};

/***********************************************************
@brief Internal Helper class
***********************************************************/
class NetworkJobTimeoutPauser {

    /***********************************************************
    ***********************************************************/
    public NetworkJobTimeoutPauser (QNetworkReply reply);
    ~NetworkJobTimeoutPauser ();


    /***********************************************************
    ***********************************************************/
    private QPointer<QTimer> this.timer;
};

/***********************************************************
Gets the SabreDAV-style error message from an error response.

This assumes the response is XML with a 'error' tag that has a
'message' tag that contains the data to extract.

Returns a null string if no message was found.
***********************************************************/
string extract_error_message (GLib.ByteArray error_response);

/***********************************************************
Builds a error message based on the error and the reply body.
***********************************************************/
string error_message (string base_error, GLib.ByteArray body);

/***********************************************************
Nicer error_string () for QNetworkReply

By default QNetworkReply.error_string () often produces messages like
  "Error downloading <url> - server replied : <reason>"
but the "downloading" part invariably confuses people since the
error might very well have been produced by a PUT request.

This function produces clearer error messages for HTTP errors.
***********************************************************/
string network_reply_error_string (QNetworkReply reply);

} // namespace Occ









AbstractNetworkJob.AbstractNetworkJob (AccountPointer account, string path, GLib.Object parent)
    : GLib.Object (parent)
    , this.timedout (false)
    , this.follow_redirects (true)
    , this.account (account)
    , this.ignore_credential_failure (false)
    , this.reply (nullptr)
    , this.path (path) {
    // Since we hold a unowned to the account, this makes no sense. (issue #6893)
    ASSERT (account != parent);

    this.timer.set_single_shot (true);
    this.timer.set_interval ( (http_timeout ? http_timeout : 300) * 1000); // default to 5 minutes.
    connect (&this.timer, &QTimer.timeout, this, &AbstractNetworkJob.on_timeout);

    connect (this, &AbstractNetworkJob.network_activity, this, &AbstractNetworkJob.on_reset_timeout);

    // Network activity on the propagator jobs (GET/PUT) keeps all requests alive.
    // This is a workaround for OC instances which only support one
    // parallel up and download
    if (this.account) {
        connect (this.account.data (), &Account.propagator_network_activity, this, &AbstractNetworkJob.on_reset_timeout);
    }
}

void AbstractNetworkJob.set_reply (QNetworkReply reply) {
    if (reply)
        reply.set_property ("do_not_handle_auth", true);

    QNetworkReply old = this.reply;
    this.reply = reply;
    delete old;
}

void AbstractNetworkJob.on_set_timeout (int64 msec) {
    this.timer.on_start (msec);
}

void AbstractNetworkJob.on_reset_timeout () {
    int64 interval = this.timer.interval ();
    this.timer.stop ();
    this.timer.on_start (interval);
}

void AbstractNetworkJob.set_ignore_credential_failure (bool ignore) {
    this.ignore_credential_failure = ignore;
}

void AbstractNetworkJob.set_follow_redirects (bool follow) {
    this.follow_redirects = follow;
}

void AbstractNetworkJob.set_path (string path) {
    this.path = path;
}

void AbstractNetworkJob.setup_connections (QNetworkReply reply) {
    connect (reply, &QNetworkReply.on_finished, this, &AbstractNetworkJob.on_finished);
    connect (reply, &QNetworkReply.encrypted, this, &AbstractNetworkJob.network_activity);
    connect (reply.manager (), &QNetworkAccessManager.proxy_authentication_required, this, &AbstractNetworkJob.network_activity);
    connect (reply, &QNetworkReply.ssl_errors, this, &AbstractNetworkJob.network_activity);
    connect (reply, &QNetworkReply.meta_data_changed, this, &AbstractNetworkJob.network_activity);
    connect (reply, &QNetworkReply.download_progress, this, &AbstractNetworkJob.network_activity);
    connect (reply, &QNetworkReply.upload_progress, this, &AbstractNetworkJob.network_activity);
}

QNetworkReply *AbstractNetworkJob.add_timer (QNetworkReply reply) {
    reply.set_property ("timer", GLib.Variant.from_value (&this.timer));
    return reply;
}

QNetworkReply *AbstractNetworkJob.send_request (GLib.ByteArray verb, GLib.Uri url,
    QNetworkRequest req, QIODevice request_body) {
    var reply = this.account.send_raw_request (verb, url, req, request_body);
    this.request_body = request_body;
    if (this.request_body) {
        this.request_body.set_parent (reply);
    }
    adopt_request (reply);
    return reply;
}

QNetworkReply *AbstractNetworkJob.send_request (GLib.ByteArray verb, GLib.Uri url,
    QNetworkRequest req, GLib.ByteArray request_body) {
    var reply = this.account.send_raw_request (verb, url, req, request_body);
    this.request_body = nullptr;
    adopt_request (reply);
    return reply;
}

QNetworkReply *AbstractNetworkJob.send_request (GLib.ByteArray verb,
                                               const GLib.Uri url,
                                               QNetworkRequest req,
                                               QHttpMultiPart request_body) {
    var reply = this.account.send_raw_request (verb, url, req, request_body);
    this.request_body = nullptr;
    adopt_request (reply);
    return reply;
}

void AbstractNetworkJob.adopt_request (QNetworkReply reply) {
    add_timer (reply);
    set_reply (reply);
    setup_connections (reply);
    new_reply_hook (reply);
}

GLib.Uri AbstractNetworkJob.make_account_url (string relative_path) {
    return Utility.concat_url_path (this.account.url (), relative_path);
}

GLib.Uri AbstractNetworkJob.make_dav_url (string relative_path) {
    return Utility.concat_url_path (this.account.dav_url (), relative_path);
}

void AbstractNetworkJob.on_finished () {
    this.timer.stop ();

    if (this.reply.error () == QNetworkReply.SslHandshakeFailedError) {
        GLib.warn (lc_network_job) << "SslHandshakeFailedError : " << error_string () << " : can be caused by a webserver wanting SSL client certificates";
    }
    // Qt doesn't yet transparently resend HTTP2 requests, do so here
    const var max_http2Resends = 3;
    GLib.ByteArray verb = HttpLogger.request_verb (*reply ());
    if (this.reply.error () == QNetworkReply.ContentReSendError
        && this.reply.attribute (QNetworkRequest.HTTP2WasUsedAttribute).to_bool ()) {

        if ( (this.request_body && !this.request_body.is_sequential ()) || verb.is_empty ()) {
            GLib.warn (lc_network_job) << "Can't resend HTTP2 request, verb or body not suitable"
                                    << this.reply.request ().url () << verb << this.request_body;
        } else if (this.http2_resend_count >= max_http2Resends) {
            GLib.warn (lc_network_job) << "Not resending HTTP2 request, number of resends exhausted"
                                    << this.reply.request ().url () << this.http2_resend_count;
        } else {
            q_c_info (lc_network_job) << "HTTP2 resending" << this.reply.request ().url ();
            this.http2_resend_count++;

            on_reset_timeout ();
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

    if (this.reply.error () != QNetworkReply.NoError) {

        if (this.account.credentials ().retry_if_needed (this))
            return;

        if (!this.ignore_credential_failure || this.reply.error () != QNetworkReply.AuthenticationRequiredError) {
            GLib.warn (lc_network_job) << this.reply.error () << error_string ()
                                    << this.reply.attribute (QNetworkRequest.HttpStatusCodeAttribute);
            if (this.reply.error () == QNetworkReply.ProxyAuthenticationRequiredError) {
                GLib.warn (lc_network_job) << this.reply.raw_header ("Proxy-Authenticate");
            }
        }
        /* emit */ network_error (this.reply);
    }

    // get the Date timestamp from reply
    this.response_timestamp = this.reply.raw_header ("Date");

    GLib.Uri requested_url = reply ().request ().url ();
    GLib.Uri redirect_url = reply ().attribute (QNetworkRequest.RedirectionTargetAttribute).to_url ();
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
            GLib.warn (lc_network_job) << "Redirecting a POST request with an implicit body loses that body";
        }

        // ### some of the q_warnings here should be exported via display_errors () so they
        // ### can be presented to the user if the job executor has a GUI
        if (requested_url.scheme () == QLatin1String ("https") && redirect_url.scheme () == QLatin1String ("http")) {
            GLib.warn (lc_network_job) << this << "HTTPS.HTTP downgrade detected!";
        } else if (requested_url == redirect_url || this.redirect_count + 1 >= max_redirects ()) {
            GLib.warn (lc_network_job) << this << "Redirect loop detected!";
        } else if (this.request_body && this.request_body.is_sequential ()) {
            GLib.warn (lc_network_job) << this << "cannot redirect request with sequential body";
        } else if (verb.is_empty ()) {
            GLib.warn (lc_network_job) << this << "cannot redirect request : could not detect original verb";
        } else {
            /* emit */ redirected (this.reply, redirect_url, this.redirect_count);

            // The signal emission may have changed this value
            if (this.follow_redirects) {
                this.redirect_count++;

                // Create the redirected request and send it
                q_c_info (lc_network_job) << "Redirecting" << verb << requested_url << redirect_url;
                on_reset_timeout ();
                if (this.request_body) {
                    if (!this.request_body.is_open ()) {
                        // Avoid the QIODevice.seek (QBuffer) : The device is not open warning message
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

    bool discard = on_finished ();
    if (discard) {
        GLib.debug (lc_network_job) << "Network job" << meta_object ().class_name () << "on_finished for" << path ();
        delete_later ();
    }
}

GLib.ByteArray AbstractNetworkJob.response_timestamp () {
    ASSERT (!this.response_timestamp.is_empty ());
    return this.response_timestamp;
}

GLib.ByteArray AbstractNetworkJob.request_id () {
    return  this.reply ? this.reply.request ().raw_header ("X-Request-ID") : GLib.ByteArray ();
}

string AbstractNetworkJob.error_string () {
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

string AbstractNetworkJob.error_string_parsing_body (GLib.ByteArray body) {
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

AbstractNetworkJob.~AbstractNetworkJob () {
    set_reply (nullptr);
}

void AbstractNetworkJob.on_start () {
    this.timer.on_start ();

    const GLib.Uri url = account ().url ();
    const string display_url = string ("%1://%2%3").arg (url.scheme ()).arg (url.host ()).arg (url.path ());

    string parent_meta_object_name = parent () ? parent ().meta_object ().class_name () : "";
    q_c_info (lc_network_job) << meta_object ().class_name () << "created for" << display_url << "+" << path () << parent_meta_object_name;
}

void AbstractNetworkJob.on_timeout () {
    this.timedout = true;
    GLib.warn (lc_network_job) << "Network job timeout" << (reply () ? reply ().request ().url () : path ());
    on_timed_out ();
}

void AbstractNetworkJob.on_timed_out () {
    if (reply ()) {
        reply ().on_abort ();
    } else {
        delete_later ();
    }
}

string AbstractNetworkJob.reply_status_"" {
    Q_ASSERT (reply ());
    if (reply ().error () == QNetworkReply.NoError) {
        return QLatin1String ("OK");
    } else {
        string enum_str = QMetaEnum.from_type<QNetworkReply.NetworkError> ().value_to_key (static_cast<int> (reply ().error ()));
        return QStringLiteral ("%1 %2").arg (enum_str, error_string ());
    }
}

NetworkJobTimeoutPauser.NetworkJobTimeoutPauser (QNetworkReply reply) {
    this.timer = reply.property ("timer").value<QTimer> ();
    if (!this.timer.is_null ()) {
        this.timer.stop ();
    }
}

NetworkJobTimeoutPauser.~NetworkJobTimeoutPauser () {
    if (!this.timer.is_null ()) {
        this.timer.on_start ();
    }
}

string extract_error_message (GLib.ByteArray error_response) {
    QXmlStreamReader reader (error_response);
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

string error_message (string base_error, GLib.ByteArray body) {
    string msg = base_error;
    string extra = extract_error_message (body);
    if (!extra.is_empty ()) {
        msg += string.from_latin1 (" (%1)").arg (extra);
    }
    return msg;
}

string network_reply_error_string (QNetworkReply reply) {
    string base = reply.error_string ();
    int http_status = reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    string http_reason = reply.attribute (QNetworkRequest.HttpReasonPhraseAttribute).to_"";

    // Only adjust HTTP error messages of the expected format.
    if (http_reason.is_empty () || http_status == 0 || !base.contains (http_reason)) {
        return base;
    }

    return AbstractNetworkJob._(R" (Server replied "%1 %2" to "%3 %4")").arg (string.number (http_status), http_reason, HttpLogger.request_verb (reply), reply.request ().url ().to_display_"");
}

void AbstractNetworkJob.retry () {
    ENFORCE (this.reply);
    var req = this.reply.request ();
    GLib.Uri requested_url = req.url ();
    GLib.ByteArray verb = HttpLogger.request_verb (*this.reply);
    q_c_info (lc_network_job) << "Restarting" << verb << requested_url;
    on_reset_timeout ();
    if (this.request_body) {
        this.request_body.seek (0);
    }
    // The cookie will be added automatically, we don't want AccessManager.create_request to duplicate them
    req.set_raw_header ("cookie", GLib.ByteArray ());
    send_request (verb, requested_url, req, this.request_body);
}

} // namespace Occ
