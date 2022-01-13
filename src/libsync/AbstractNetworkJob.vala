/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <GLib.Object>
// #include <QNetworkRequest>
// #include <QNetworkReply>
// #include <QPointer>
// #include <QElapsedTimer>
// #include <QDateTime>
// #include <QTimer>


namespace Occ {


/***********************************************************
@brief The AbstractNetworkJob class
@ingroup libsync
***********************************************************/
class AbstractNetworkJob : GLib.Object {
public:
    AbstractNetworkJob (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    ~AbstractNetworkJob () override;

    virtual void start ();

    AccountPtr account () { return _account; }

    void setPath (string &path);
    string path () { return _path; }

    void setReply (QNetworkReply *reply);
    QNetworkReply *reply () { return _reply; }

    void setIgnoreCredentialFailure (bool ignore);
    bool ignoreCredentialFailure () { return _ignoreCredentialFailure; }

    /** Whether to handle redirects transparently.
     *
     * If true, a follow-up request is issued automatically when
     * a redirect is encountered. The finished () function is only
     * called if there are no more redirects (or there are problems
     * with the redirect).
     *
     * The transparent redirect following may be disabled for some
     * requests where custom handling is necessary.
     */
    void setFollowRedirects (bool follow);
    bool followRedirects () { return _followRedirects; }

    QByteArray responseTimestamp ();
    /* Content of the X-Request-ID header. (Only set after the request is sent) */
    QByteArray requestId ();

    int64 timeoutMsec () { return _timer.interval (); }
    bool timedOut () { return _timedout; }

    /** Returns an error message, if any. */
    virtual string errorString ();

    /** Like errorString, but also checking the reply body for information.
     *
     * Specifically, sometimes xml bodies have extra error information.
     * This function reads the body of the reply and parses out the
     * error information, if possible.
     *
     * \a body is optinally filled with the reply body.
     *
     * Warning : Needs to call reply ().readAll ().
     */
    string errorStringParsingBody (QByteArray *body = nullptr);

    /** Make a new request */
    void retry ();

    /** static variable the HTTP timeout (in seconds). If set to 0, the default will be used
     */
    static int httpTimeout;

public slots:
    void setTimeout (int64 msec);
    void resetTimeout ();
signals:
    /** Emitted on network error.
     *
     * \a reply is never null
     */
    void networkError (QNetworkReply *reply);
    void networkActivity ();

    /** Emitted when a redirect is followed.
     *
     * \a reply The "please redirect" reply
     * \a targetUrl Where to redirect to
     * \a redirectCount Counts redirect hops, first is 0.
     */
    void redirected (QNetworkReply *reply, QUrl &targetUrl, int redirectCount);

protected:
    /** Initiate a network request, returning a QNetworkReply.
     *
     * Calls setReply () and setupConnections () on it.
     *
     * Takes ownership of the requestBody (to allow redirects).
     */
    QNetworkReply *sendRequest (QByteArray &verb, QUrl &url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice *requestBody = nullptr);

    QNetworkReply *sendRequest (QByteArray &verb, QUrl &url,
        QNetworkRequest req, QByteArray &requestBody);

    // sendRequest does not take a relative path instead of an url,
    // but the old API allowed that. We have this undefined overload
    // to help catch usage errors
    QNetworkReply *sendRequest (QByteArray &verb, string &relativePath,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice *requestBody = nullptr);

    QNetworkReply *sendRequest (QByteArray &verb, QUrl &url,
        QNetworkRequest req, QHttpMultiPart *requestBody);

    /** Makes this job drive a pre-made QNetworkReply
     *
     * This reply cannot have a QIODevice request body because we can't get
     * at it and thus not resend it in case of redirects.
     */
    void adoptRequest (QNetworkReply *reply);

    void setupConnections (QNetworkReply *reply);

    /** Can be used by derived classes to set up the network reply.
     *
     * Particularly useful when the request is redirected and reply ()
     * changes. For things like setting up additional signal connections
     * on the new reply.
     */
    virtual void newReplyHook (QNetworkReply *) {}

    /// Creates a url for the account from a relative path
    QUrl makeAccountUrl (string &relativePath) const;

    /// Like makeAccountUrl () but uses the account's dav base path
    QUrl makeDavUrl (string &relativePath) const;

    int maxRedirects () { return 10; }

    /** Called at the end of QNetworkReply.finished processing.
     *
     * Returning true triggers a deleteLater () of this job.
     */
    virtual bool finished () = 0;

    /** Called on timeout.
     *
     * The default implementation aborts the reply.
     */
    virtual void onTimedOut ();

    QByteArray _responseTimestamp;
    bool _timedout; // set to true when the timeout slot is received

    // Automatically follows redirects. Note that this only works for
    // GET requests that don't set up any HTTP body or other flags.
    bool _followRedirects;

    string replyStatusString ();

private slots:
    void slotFinished ();
    void slotTimeout ();

protected:
    AccountPtr _account;

private:
    QNetworkReply *addTimer (QNetworkReply *reply);
    bool _ignoreCredentialFailure;
    QPointer<QNetworkReply> _reply; // (QPointer because the NetworkManager may be destroyed before the jobs at exit)
    string _path;
    QTimer _timer;
    int _redirectCount = 0;
    int _http2ResendCount = 0;

    // Set by the xyzRequest () functions and needed to be able to redirect
    // requests, should it be required.
    //
    // Reparented to the currently running QNetworkReply.
    QPointer<QIODevice> _requestBody;
};

/***********************************************************
@brief Internal Helper class
***********************************************************/
class NetworkJobTimeoutPauser {
public:
    NetworkJobTimeoutPauser (QNetworkReply *reply);
    ~NetworkJobTimeoutPauser ();

private:
    QPointer<QTimer> _timer;
};

/** Gets the SabreDAV-style error message from an error response.

This assumes the response is XML with a 'error' tag that has a
'message' tag that contains the data to extract.

Returns a null string if no message was found.
***********************************************************/
string OWNCLOUDSYNC_EXPORT extractErrorMessage (QByteArray &errorResponse);

/** Builds a error message based on the error and the reply body. */
string OWNCLOUDSYNC_EXPORT errorMessage (string &baseError, QByteArray &body);

/** Nicer errorString () for QNetworkReply

By default QNetworkReply.errorString () often produces messages like
  "Error downloading <url> - server replied : <reason>"
but the "downloading" part invariably confuses people since the
error might very well have been produced by a PUT request.

This function produces clearer error messages for HTTP errors.
***********************************************************/
string OWNCLOUDSYNC_EXPORT networkReplyErrorString (QNetworkReply &reply);

} // namespace Occ








/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QNetworkRequest>
// #include <QNetworkAccessManager>
// #include <QNetworkReply>
// #include <QNetworkRequest>
// #include <QSslConfiguration>
// #include <QBuffer>
// #include <QXmlStreamReader>
// #include <QStringList>
// #include <QStack>
// #include <QTimer>
// #include <QMutex>
// #include <QCoreApplication>
// #include <QAuthenticator>
// #include <QMetaEnum>
// #include <QRegularExpression>

Q_DECLARE_METATYPE (QTimer *)

namespace Occ {

Q_LOGGING_CATEGORY (lcNetworkJob, "nextcloud.sync.networkjob", QtInfoMsg)

// If not set, it is overwritten by the Application constructor with the value from the config
int AbstractNetworkJob.httpTimeout = qEnvironmentVariableIntValue ("OWNCLOUD_TIMEOUT");

AbstractNetworkJob.AbstractNetworkJob (AccountPtr account, string &path, GLib.Object *parent)
    : GLib.Object (parent)
    , _timedout (false)
    , _followRedirects (true)
    , _account (account)
    , _ignoreCredentialFailure (false)
    , _reply (nullptr)
    , _path (path) {
    // Since we hold a QSharedPointer to the account, this makes no sense. (issue #6893)
    ASSERT (account != parent);

    _timer.setSingleShot (true);
    _timer.setInterval ( (httpTimeout ? httpTimeout : 300) * 1000); // default to 5 minutes.
    connect (&_timer, &QTimer.timeout, this, &AbstractNetworkJob.slotTimeout);

    connect (this, &AbstractNetworkJob.networkActivity, this, &AbstractNetworkJob.resetTimeout);

    // Network activity on the propagator jobs (GET/PUT) keeps all requests alive.
    // This is a workaround for OC instances which only support one
    // parallel up and download
    if (_account) {
        connect (_account.data (), &Account.propagatorNetworkActivity, this, &AbstractNetworkJob.resetTimeout);
    }
}

void AbstractNetworkJob.setReply (QNetworkReply *reply) {
    if (reply)
        reply.setProperty ("doNotHandleAuth", true);

    QNetworkReply *old = _reply;
    _reply = reply;
    delete old;
}

void AbstractNetworkJob.setTimeout (int64 msec) {
    _timer.start (msec);
}

void AbstractNetworkJob.resetTimeout () {
    int64 interval = _timer.interval ();
    _timer.stop ();
    _timer.start (interval);
}

void AbstractNetworkJob.setIgnoreCredentialFailure (bool ignore) {
    _ignoreCredentialFailure = ignore;
}

void AbstractNetworkJob.setFollowRedirects (bool follow) {
    _followRedirects = follow;
}

void AbstractNetworkJob.setPath (string &path) {
    _path = path;
}

void AbstractNetworkJob.setupConnections (QNetworkReply *reply) {
    connect (reply, &QNetworkReply.finished, this, &AbstractNetworkJob.slotFinished);
    connect (reply, &QNetworkReply.encrypted, this, &AbstractNetworkJob.networkActivity);
    connect (reply.manager (), &QNetworkAccessManager.proxyAuthenticationRequired, this, &AbstractNetworkJob.networkActivity);
    connect (reply, &QNetworkReply.sslErrors, this, &AbstractNetworkJob.networkActivity);
    connect (reply, &QNetworkReply.metaDataChanged, this, &AbstractNetworkJob.networkActivity);
    connect (reply, &QNetworkReply.downloadProgress, this, &AbstractNetworkJob.networkActivity);
    connect (reply, &QNetworkReply.uploadProgress, this, &AbstractNetworkJob.networkActivity);
}

QNetworkReply *AbstractNetworkJob.addTimer (QNetworkReply *reply) {
    reply.setProperty ("timer", QVariant.fromValue (&_timer));
    return reply;
}

QNetworkReply *AbstractNetworkJob.sendRequest (QByteArray &verb, QUrl &url,
    QNetworkRequest req, QIODevice *requestBody) {
    auto reply = _account.sendRawRequest (verb, url, req, requestBody);
    _requestBody = requestBody;
    if (_requestBody) {
        _requestBody.setParent (reply);
    }
    adoptRequest (reply);
    return reply;
}

QNetworkReply *AbstractNetworkJob.sendRequest (QByteArray &verb, QUrl &url,
    QNetworkRequest req, QByteArray &requestBody) {
    auto reply = _account.sendRawRequest (verb, url, req, requestBody);
    _requestBody = nullptr;
    adoptRequest (reply);
    return reply;
}

QNetworkReply *AbstractNetworkJob.sendRequest (QByteArray &verb,
                                               const QUrl &url,
                                               QNetworkRequest req,
                                               QHttpMultiPart *requestBody) {
    auto reply = _account.sendRawRequest (verb, url, req, requestBody);
    _requestBody = nullptr;
    adoptRequest (reply);
    return reply;
}

void AbstractNetworkJob.adoptRequest (QNetworkReply *reply) {
    addTimer (reply);
    setReply (reply);
    setupConnections (reply);
    newReplyHook (reply);
}

QUrl AbstractNetworkJob.makeAccountUrl (string &relativePath) {
    return Utility.concatUrlPath (_account.url (), relativePath);
}

QUrl AbstractNetworkJob.makeDavUrl (string &relativePath) {
    return Utility.concatUrlPath (_account.davUrl (), relativePath);
}

void AbstractNetworkJob.slotFinished () {
    _timer.stop ();

    if (_reply.error () == QNetworkReply.SslHandshakeFailedError) {
        qCWarning (lcNetworkJob) << "SslHandshakeFailedError : " << errorString () << " : can be caused by a webserver wanting SSL client certificates";
    }
    // Qt doesn't yet transparently resend HTTP2 requests, do so here
    const auto maxHttp2Resends = 3;
    QByteArray verb = HttpLogger.requestVerb (*reply ());
    if (_reply.error () == QNetworkReply.ContentReSendError
        && _reply.attribute (QNetworkRequest.HTTP2WasUsedAttribute).toBool ()) {

        if ( (_requestBody && !_requestBody.isSequential ()) || verb.isEmpty ()) {
            qCWarning (lcNetworkJob) << "Can't resend HTTP2 request, verb or body not suitable"
                                    << _reply.request ().url () << verb << _requestBody;
        } else if (_http2ResendCount >= maxHttp2Resends) {
            qCWarning (lcNetworkJob) << "Not resending HTTP2 request, number of resends exhausted"
                                    << _reply.request ().url () << _http2ResendCount;
        } else {
            qCInfo (lcNetworkJob) << "HTTP2 resending" << _reply.request ().url ();
            _http2ResendCount++;

            resetTimeout ();
            if (_requestBody) {
                if (!_requestBody.isOpen ())
                   _requestBody.open (QIODevice.ReadOnly);
                _requestBody.seek (0);
            }
            sendRequest (
                verb,
                _reply.request ().url (),
                _reply.request (),
                _requestBody);
            return;
        }
    }

    if (_reply.error () != QNetworkReply.NoError) {

        if (_account.credentials ().retryIfNeeded (this))
            return;

        if (!_ignoreCredentialFailure || _reply.error () != QNetworkReply.AuthenticationRequiredError) {
            qCWarning (lcNetworkJob) << _reply.error () << errorString ()
                                    << _reply.attribute (QNetworkRequest.HttpStatusCodeAttribute);
            if (_reply.error () == QNetworkReply.ProxyAuthenticationRequiredError) {
                qCWarning (lcNetworkJob) << _reply.rawHeader ("Proxy-Authenticate");
            }
        }
        emit networkError (_reply);
    }

    // get the Date timestamp from reply
    _responseTimestamp = _reply.rawHeader ("Date");

    QUrl requestedUrl = reply ().request ().url ();
    QUrl redirectUrl = reply ().attribute (QNetworkRequest.RedirectionTargetAttribute).toUrl ();
    if (_followRedirects && !redirectUrl.isEmpty ()) {
        // Redirects may be relative
        if (redirectUrl.isRelative ())
            redirectUrl = requestedUrl.resolved (redirectUrl);

        // For POST requests where the target url has query arguments, Qt automatically
        // moves these arguments to the body if no explicit body is specified.
        // This can cause problems with redirected requests, because the redirect url
        // will no longer contain these query arguments.
        if (reply ().operation () == QNetworkAccessManager.PostOperation
            && requestedUrl.hasQuery ()
            && !redirectUrl.hasQuery ()
            && !_requestBody) {
            qCWarning (lcNetworkJob) << "Redirecting a POST request with an implicit body loses that body";
        }

        // ### some of the qWarnings here should be exported via displayErrors () so they
        // ### can be presented to the user if the job executor has a GUI
        if (requestedUrl.scheme () == QLatin1String ("https") && redirectUrl.scheme () == QLatin1String ("http")) {
            qCWarning (lcNetworkJob) << this << "HTTPS.HTTP downgrade detected!";
        } else if (requestedUrl == redirectUrl || _redirectCount + 1 >= maxRedirects ()) {
            qCWarning (lcNetworkJob) << this << "Redirect loop detected!";
        } else if (_requestBody && _requestBody.isSequential ()) {
            qCWarning (lcNetworkJob) << this << "cannot redirect request with sequential body";
        } else if (verb.isEmpty ()) {
            qCWarning (lcNetworkJob) << this << "cannot redirect request : could not detect original verb";
        } else {
            emit redirected (_reply, redirectUrl, _redirectCount);

            // The signal emission may have changed this value
            if (_followRedirects) {
                _redirectCount++;

                // Create the redirected request and send it
                qCInfo (lcNetworkJob) << "Redirecting" << verb << requestedUrl << redirectUrl;
                resetTimeout ();
                if (_requestBody) {
                    if (!_requestBody.isOpen ()) {
                        // Avoid the QIODevice.seek (QBuffer) : The device is not open warning message
                       _requestBody.open (QIODevice.ReadOnly);
                    }
                    _requestBody.seek (0);
                }
                sendRequest (
                    verb,
                    redirectUrl,
                    reply ().request (),
                    _requestBody);
                return;
            }
        }
    }

    AbstractCredentials *creds = _account.credentials ();
    if (!creds.stillValid (_reply) && !_ignoreCredentialFailure) {
        _account.handleInvalidCredentials ();
    }

    bool discard = finished ();
    if (discard) {
        qCDebug (lcNetworkJob) << "Network job" << metaObject ().className () << "finished for" << path ();
        deleteLater ();
    }
}

QByteArray AbstractNetworkJob.responseTimestamp () {
    ASSERT (!_responseTimestamp.isEmpty ());
    return _responseTimestamp;
}

QByteArray AbstractNetworkJob.requestId () {
    return  _reply ? _reply.request ().rawHeader ("X-Request-ID") : QByteArray ();
}

string AbstractNetworkJob.errorString () {
    if (_timedout) {
        return tr ("Connection timed out");
    } else if (!reply ()) {
        return tr ("Unknown error : network reply was deleted");
    } else if (reply ().hasRawHeader ("OC-ErrorString")) {
        return reply ().rawHeader ("OC-ErrorString");
    } else {
        return networkReplyErrorString (*reply ());
    }
}

string AbstractNetworkJob.errorStringParsingBody (QByteArray *body) {
    string base = errorString ();
    if (base.isEmpty () || !reply ()) {
        return string ();
    }

    QByteArray replyBody = reply ().readAll ();
    if (body) {
        *body = replyBody;
    }

    string extra = extractErrorMessage (replyBody);
    // Don't append the XML error message to a OC-ErrorString message.
    if (!extra.isEmpty () && !reply ().hasRawHeader ("OC-ErrorString")) {
        return string.fromLatin1 ("%1 (%2)").arg (base, extra);
    }

    return base;
}

AbstractNetworkJob.~AbstractNetworkJob () {
    setReply (nullptr);
}

void AbstractNetworkJob.start () {
    _timer.start ();

    const QUrl url = account ().url ();
    const string displayUrl = string ("%1://%2%3").arg (url.scheme ()).arg (url.host ()).arg (url.path ());

    string parentMetaObjectName = parent () ? parent ().metaObject ().className () : "";
    qCInfo (lcNetworkJob) << metaObject ().className () << "created for" << displayUrl << "+" << path () << parentMetaObjectName;
}

void AbstractNetworkJob.slotTimeout () {
    _timedout = true;
    qCWarning (lcNetworkJob) << "Network job timeout" << (reply () ? reply ().request ().url () : path ());
    onTimedOut ();
}

void AbstractNetworkJob.onTimedOut () {
    if (reply ()) {
        reply ().abort ();
    } else {
        deleteLater ();
    }
}

string AbstractNetworkJob.replyStatusString () {
    Q_ASSERT (reply ());
    if (reply ().error () == QNetworkReply.NoError) {
        return QLatin1String ("OK");
    } else {
        string enumStr = QMetaEnum.fromType<QNetworkReply.NetworkError> ().valueToKey (static_cast<int> (reply ().error ()));
        return QStringLiteral ("%1 %2").arg (enumStr, errorString ());
    }
}

NetworkJobTimeoutPauser.NetworkJobTimeoutPauser (QNetworkReply *reply) {
    _timer = reply.property ("timer").value<QTimer> ();
    if (!_timer.isNull ()) {
        _timer.stop ();
    }
}

NetworkJobTimeoutPauser.~NetworkJobTimeoutPauser () {
    if (!_timer.isNull ()) {
        _timer.start ();
    }
}

string extractErrorMessage (QByteArray &errorResponse) {
    QXmlStreamReader reader (errorResponse);
    reader.readNextStartElement ();
    if (reader.name () != "error") {
        return string ();
    }

    string exception;
    while (!reader.atEnd () && !reader.hasError ()) {
        reader.readNextStartElement ();
        if (reader.name () == QLatin1String ("message")) {
            string message = reader.readElementText ();
            if (!message.isEmpty ()) {
                return message;
            }
        } else if (reader.name () == QLatin1String ("exception")) {
            exception = reader.readElementText ();
        }
    }
    // Fallback, if message could not be found
    return exception;
}

string errorMessage (string &baseError, QByteArray &body) {
    string msg = baseError;
    string extra = extractErrorMessage (body);
    if (!extra.isEmpty ()) {
        msg += string.fromLatin1 (" (%1)").arg (extra);
    }
    return msg;
}

string networkReplyErrorString (QNetworkReply &reply) {
    string base = reply.errorString ();
    int httpStatus = reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    string httpReason = reply.attribute (QNetworkRequest.HttpReasonPhraseAttribute).toString ();

    // Only adjust HTTP error messages of the expected format.
    if (httpReason.isEmpty () || httpStatus == 0 || !base.contains (httpReason)) {
        return base;
    }

    return AbstractNetworkJob.tr (R" (Server replied "%1 %2" to "%3 %4")").arg (string.number (httpStatus), httpReason, HttpLogger.requestVerb (reply), reply.request ().url ().toDisplayString ());
}

void AbstractNetworkJob.retry () {
    ENFORCE (_reply);
    auto req = _reply.request ();
    QUrl requestedUrl = req.url ();
    QByteArray verb = HttpLogger.requestVerb (*_reply);
    qCInfo (lcNetworkJob) << "Restarting" << verb << requestedUrl;
    resetTimeout ();
    if (_requestBody) {
        _requestBody.seek (0);
    }
    // The cookie will be added automatically, we don't want AccessManager.createRequest to duplicate them
    req.setRawHeader ("cookie", QByteArray ());
    sendRequest (verb, requestedUrl, req, _requestBody);
}

} // namespace Occ
