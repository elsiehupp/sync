/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QBuffer>
// #include <QUrlQuery>
// #include <QJsonDocument>
// #include <functional>


namespace Occ {

/** Strips quotes and gzip annotations */
OWNCLOUDSYNC_EXPORT QByteArray parseEtag (char *header);

struct HttpError {
    int code; // HTTP error code
    string message;
};

template <typename T>
using HttpResult = Result<T, HttpError>;

/***********************************************************
@brief The EntityExistsJob class
@ingroup libsync
***********************************************************/
class EntityExistsJob : AbstractNetworkJob {
public:
    EntityExistsJob (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    void start () override;

signals:
    void exists (QNetworkReply *);

private slots:
    bool finished () override;
};

/***********************************************************
@brief sends a DELETE http request to a url.

See Nextcloud API usage for the possible DELETE requests.

This does *not* delete files, it does a http request.
***********************************************************/
class DeleteApiJob : AbstractNetworkJob {
public:
    DeleteApiJob (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    void start () override;

signals:
    void result (int httpCode);

private slots:
    bool finished () override;
};

struct ExtraFolderInfo {
    QByteArray fileId;
    int64 size = -1;
};

/***********************************************************
@brief The LsColJob class
@ingroup libsync
***********************************************************/
class LsColXMLParser : GLib.Object {
public:
    LsColXMLParser ();

    bool parse (QByteArray &xml,
               QHash<string, ExtraFolderInfo> *sizes,
               const string &expectedPath);

signals:
    void directoryListingSubfolders (QStringList &items);
    void directoryListingIterated (string &name, QMap<string, string> &properties);
    void finishedWithError (QNetworkReply *reply);
    void finishedWithoutError ();
};

class LsColJob : AbstractNetworkJob {
public:
    LsColJob (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    LsColJob (AccountPtr account, QUrl &url, GLib.Object *parent = nullptr);
    void start () override;
    QHash<string, ExtraFolderInfo> _folderInfos;

    /***********************************************************
     * Used to specify which properties shall be retrieved.
     *
     * The properties can
     *  - contain no colon : they refer to a property in the DAV : namespace
     *  - contain a colon : and thus specify an explicit namespace,
     *    e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
     */
    void setProperties (QList<QByteArray> properties);
    QList<QByteArray> properties ();

signals:
    void directoryListingSubfolders (QStringList &items);
    void directoryListingIterated (string &name, QMap<string, string> &properties);
    void finishedWithError (QNetworkReply *reply);
    void finishedWithoutError ();

private slots:
    bool finished () override;

private:
    QList<QByteArray> _properties;
    QUrl _url; // Used instead of path () if the url is specified in the constructor
};

/***********************************************************
@brief The PropfindJob class

Setting the desired properties with setProperties

Note that this job is only for querying one item.
There is also the LsColJob which can be used to list collections

@ingroup libsync
***********************************************************/
class PropfindJob : AbstractNetworkJob {
public:
    PropfindJob (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    void start () override;

    /***********************************************************
     * Used to specify which properties shall be retrieved.
     *
     * The properties can
     *  - contain no colon : they refer to a property in the DAV : namespace
     *  - contain a colon : and thus specify an explicit namespace,
     *    e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
     */
    void setProperties (QList<QByteArray> properties);
    QList<QByteArray> properties ();

signals:
    void result (QVariantMap &values);
    void finishedWithError (QNetworkReply *reply = nullptr);

private slots:
    bool finished () override;

private:
    QList<QByteArray> _properties;
};

#ifndef TOKEN_AUTH_ONLY
/***********************************************************
@brief Retrieves the account users avatar from the server using a GET request.

If the server does not have the avatar, the result Pixmap is empty.

@ingroup libsync
***********************************************************/
class AvatarJob : AbstractNetworkJob {
public:
    /***********************************************************
     * @param userId The user for which to obtain the avatar
     * @param size The size of the avatar (square so size*size)
     */
    AvatarJob (AccountPtr account, string &userId, int size, GLib.Object *parent = nullptr);

    void start () override;

    /** The retrieved avatar images don't have the circle shape by default */
    static QImage makeCircularAvatar (QImage &baseAvatar);

signals:
    /***********************************************************
     * @brief avatarPixmap - returns either a valid pixmap or not.
     */

    void avatarPixmap (QImage &);

private slots:
    bool finished () override;

private:
    QUrl _avatarUrl;
};
#endif

/***********************************************************
@brief Send a Proppatch request

Setting the desired p

WARNING : Untested!

@ingroup libsync
***********************************************************/
class ProppatchJob : AbstractNetworkJob {
public:
    ProppatchJob (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    void start () override;

    /***********************************************************
     * Used to specify which properties shall be set.
     *
     * The property keys can
     *  - contain no colon : they refer to a property in the DAV : namespace
     *  - contain a colon : and thus specify an explicit namespace,
     *    e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
     */
    void setProperties (QMap<QByteArray, QByteArray> properties);
    QMap<QByteArray, QByteArray> properties ();

signals:
    void success ();
    void finishedWithError ();

private slots:
    bool finished () override;

private:
    QMap<QByteArray, QByteArray> _properties;
};

/***********************************************************
@brief The MkColJob class
@ingroup libsync
***********************************************************/
class MkColJob : AbstractNetworkJob {
    QUrl _url; // Only used if the constructor taking a url is taken.
    QMap<QByteArray, QByteArray> _extraHeaders;

public:
    MkColJob (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    MkColJob (AccountPtr account, string &path, QMap<QByteArray, QByteArray> &extraHeaders, GLib.Object *parent = nullptr);
    MkColJob (AccountPtr account, QUrl &url,
        const QMap<QByteArray, QByteArray> &extraHeaders, GLib.Object *parent = nullptr);
    void start () override;

signals:
    void finishedWithError (QNetworkReply *reply);
    void finishedWithoutError ();

private:
    bool finished () override;
};

/***********************************************************
@brief The CheckServerJob class
@ingroup libsync
***********************************************************/
class CheckServerJob : AbstractNetworkJob {
public:
    CheckServerJob (AccountPtr account, GLib.Object *parent = nullptr);
    void start () override;

    static string version (QJsonObject &info);
    static string versionString (QJsonObject &info);
    static bool installed (QJsonObject &info);

signals:
    /** Emitted when a status.php was successfully read.
     *
     * \a url see _serverStatusUrl (does not include "/status.php")
     * \a info The status.php reply information
     */
    void instanceFound (QUrl &url, QJsonObject &info);

    /** Emitted on invalid status.php reply.
     *
     * \a reply is never null
     */
    void instanceNotFound (QNetworkReply *reply);

    /** A timeout occurred.
     *
     * \a url The specific url where the timeout happened.
     */
    void timeout (QUrl &url);

private:
    bool finished () override;
    void onTimedOut () override;
private slots:
    virtual void metaDataChangedSlot ();
    virtual void encryptedSlot ();
    void slotRedirected (QNetworkReply *reply, QUrl &targetUrl, int redirectCount);

private:
    bool _subdirFallback;

    /** The permanent-redirect adjusted account url.
     *
     * Note that temporary redirects or a permanent redirect behind a temporary
     * one do not affect this url.
     */
    QUrl _serverUrl;

    /** Keep track of how many permanent redirect were applied. */
    int _permanentRedirects;
};

/***********************************************************
@brief The RequestEtagJob class
***********************************************************/
class RequestEtagJob : AbstractNetworkJob {
public:
    RequestEtagJob (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    void start () override;

signals:
    void etagRetrieved (QByteArray &etag, QDateTime &time);
    void finishedWithResult (HttpResult<QByteArray> &etag);

private slots:
    bool finished () override;
};

/***********************************************************
@brief Job to check an API that return JSON

Note! you need to be in the connected state befo
https://github.com/ow

To be used like this:
\code
_job = new JsonApiJob (account, QLatin1String ("o
connect (j
The received QVariantMap is null in case of error
\encode

@ingroup libsync
***********************************************************/
class JsonApiJob : AbstractNetworkJob {
public:
    enum class Verb {
        Get,
        Post,
        Put,
        Delete,
    };

    JsonApiJob (AccountPtr &account, string &path, GLib.Object *parent = nullptr);

    /***********************************************************
     * @brief addQueryParams - add more parameters to the ocs call
     * @param params : list pairs of strings containing the parameter name and the value.
     *
     * All parameters from the passed list are appended to the query. Note
     * that the format=json parameter is added automatically and does not
     * need to be set this way.
     *
     * This function needs to be called before start () obviously.
     */
    void addQueryParams (QUrlQuery &params);
    void addRawHeader (QByteArray &headerName, QByteArray &value);

    void setBody (QJsonDocument &body);

    void setVerb (Verb value);

public slots:
    void start () override;

protected:
    bool finished () override;
signals:

    /***********************************************************
     * @brief jsonReceived - signal to report the json answer from ocs
     * @param json - the parsed json document
     * @param statusCode - the OCS status code : 100 (!) for success
     */
    void jsonReceived (QJsonDocument &json, int statusCode);

    /***********************************************************
     * @brief etagResponseHeaderReceived - signal to report the ETag response header value
     * from ocs api v2
     * @param value - the ETag response header value
     * @param statusCode - the OCS status code : 100 (!) for success
     */
    void etagResponseHeaderReceived (QByteArray &value, int statusCode);

    /***********************************************************
     * @brief desktopNotificationStatusReceived - signal to report if notifications are allowed
     * @param status - set desktop notifications allowed status
     */
    void allowDesktopNotificationsChanged (bool isAllowed);

private:
    QByteArray _body;
    QUrlQuery _additionalParams;
    QNetworkRequest _request;

    Verb _verb = Verb.Get;

    QByteArray verbToString ();
};

/***********************************************************
@brief Checks with auth type to use for a server
@ingroup libsync
***********************************************************/
class DetermineAuthTypeJob : GLib.Object {
public:
    enum AuthType {
        NoAuthType, // used only before we got a chance to probe the server
#ifdef WITH_WEBENGINE
        WebViewFlow,
#endif // WITH_WEBENGINE
        Basic, // also the catch-all fallback for backwards compatibility reasons
        OAuth,
        LoginFlowV2
    };
    Q_ENUM (AuthType)

    DetermineAuthTypeJob (AccountPtr account, GLib.Object *parent = nullptr);
    void start ();
signals:
    void authType (AuthType);

private:
    void checkAllDone ();

    AccountPtr _account;
    AuthType _resultGet = NoAuthType;
    AuthType _resultPropfind = NoAuthType;
    AuthType _resultOldFlow = NoAuthType;
    bool _getDone = false;
    bool _propfindDone = false;
    bool _oldFlowDone = false;
};

/***********************************************************
@brief A basic job around a network request without extra funtionality
@ingroup libsync

Primarily adds timeout and redirection handling.
***********************************************************/
class SimpleNetworkJob : AbstractNetworkJob {
public:
    SimpleNetworkJob (AccountPtr account, GLib.Object *parent = nullptr);

    QNetworkReply *startRequest (QByteArray &verb, QUrl &url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice *requestBody = nullptr);

signals:
    void finishedSignal (QNetworkReply *reply);
private slots:
    bool finished () override;
};

/***********************************************************
@brief Runs a PROPFIND to figure out the private link url

The numericFileId is used only to build the deprecatedPrivateLinkUrl
locally as a fallback. If it's empty an
will be called with an empty string.

The job and signal connections are parented to the target GLib.Object.

Note : targetFun is guaranteed to be called only through the event
loop and never directly.
***********************************************************/
void fetchPrivateLinkUrl (
    AccountPtr account, string &remotePath,
    const QByteArray &numericFileId, GLib.Object *target,
    std.function<void (string &url)> targetFun);

} // namespace Occ














/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QJsonDocument>
// #include <QLoggingCategory>
// #include <QNetworkRequest>
// #include <QNetworkAccessManager>
// #include <QNetworkReply>
// #include <QNetworkRequest>
// #include <QSslConfiguration>
// #include <QSslCipher>
// #include <QBuffer>
// #include <QXmlStreamReader>
// #include <QStringList>
// #include <QStack>
// #include <QTimer>
// #include <QMutex>
// #include <QCoreApplication>
// #include <QJsonDocument>
// #include <QJsonObject>
// #include <qloggingcategory.h>
#ifndef TOKEN_AUTH_ONLY
// #include <QPainter>
// #include <QPainterPath>
#endif

namespace Occ {

Q_LOGGING_CATEGORY (lcEtagJob, "nextcloud.sync.networkjob.etag", QtInfoMsg)
Q_LOGGING_CATEGORY (lcLsColJob, "nextcloud.sync.networkjob.lscol", QtInfoMsg)
Q_LOGGING_CATEGORY (lcCheckServerJob, "nextcloud.sync.networkjob.checkserver", QtInfoMsg)
Q_LOGGING_CATEGORY (lcPropfindJob, "nextcloud.sync.networkjob.propfind", QtInfoMsg)
Q_LOGGING_CATEGORY (lcAvatarJob, "nextcloud.sync.networkjob.avatar", QtInfoMsg)
Q_LOGGING_CATEGORY (lcMkColJob, "nextcloud.sync.networkjob.mkcol", QtInfoMsg)
Q_LOGGING_CATEGORY (lcProppatchJob, "nextcloud.sync.networkjob.proppatch", QtInfoMsg)
Q_LOGGING_CATEGORY (lcJsonApiJob, "nextcloud.sync.networkjob.jsonapi", QtInfoMsg)
Q_LOGGING_CATEGORY (lcDetermineAuthTypeJob, "nextcloud.sync.networkjob.determineauthtype", QtInfoMsg)
const int notModifiedStatusCode = 304;

QByteArray parseEtag (char *header) {
    if (!header)
        return QByteArray ();
    QByteArray arr = header;

    // Weak E-Tags can appear when gzip compression is on, see #3946
    if (arr.startsWith ("W/"))
        arr = arr.mid (2);

    // https://github.com/owncloud/client/issues/1195
    arr.replace ("-gzip", "");

    if (arr.length () >= 2 && arr.startsWith ('"') && arr.endsWith ('"')) {
        arr = arr.mid (1, arr.length () - 2);
    }
    return arr;
}

RequestEtagJob.RequestEtagJob (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

void RequestEtagJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("Depth", "0");

    QByteArray xml ("<?xml version=\"1.0\" ?>\n"
                   "<d:propfind xmlns:d=\"DAV:\">\n"
                   "  <d:prop>\n"
                   "    <d:getetag/>\n"
                   "  </d:prop>\n"
                   "</d:propfind>\n");
    auto *buf = new QBuffer (this);
    buf.setData (xml);
    buf.open (QIODevice.ReadOnly);
    // assumes ownership
    sendRequest ("PROPFIND", makeDavUrl (path ()), req, buf);

    if (reply ().error () != QNetworkReply.NoError) {
        qCWarning (lcEtagJob) << "request network error : " << reply ().errorString ();
    }
    AbstractNetworkJob.start ();
}

bool RequestEtagJob.finished () {
    qCInfo (lcEtagJob) << "Request Etag of" << reply ().request ().url () << "FINISHED WITH STATUS"
                      <<  replyStatusString ();

    auto httpCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    if (httpCode == 207) {
        // Parse DAV response
        QXmlStreamReader reader (reply ());
        reader.addExtraNamespaceDeclaration (QXmlStreamNamespaceDeclaration (QStringLiteral ("d"), QStringLiteral ("DAV:")));
        QByteArray etag;
        while (!reader.atEnd ()) {
            QXmlStreamReader.TokenType type = reader.readNext ();
            if (type == QXmlStreamReader.StartElement && reader.namespaceUri () == QLatin1String ("DAV:")) {
                string name = reader.name ().toString ();
                if (name == QLatin1String ("getetag")) {
                    auto etagText = reader.readElementText ();
                    auto parsedTag = parseEtag (etagText.toUtf8 ());
                    if (!parsedTag.isEmpty ()) {
                        etag += parsedTag;
                    } else {
                        etag += etagText.toUtf8 ();
                    }
                }
            }
        }
        emit etagRetrieved (etag, QDateTime.fromString (string.fromUtf8 (_responseTimestamp), Qt.RFC2822Date));
        emit finishedWithResult (etag);
    } else {
        emit finishedWithResult (HttpError{ httpCode, errorString () });
    }
    return true;
}

/****************************************************************************/

MkColJob.MkColJob (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

MkColJob.MkColJob (AccountPtr account, string &path, QMap<QByteArray, QByteArray> &extraHeaders, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent)
    , _extraHeaders (extraHeaders) {
}

MkColJob.MkColJob (AccountPtr account, QUrl &url,
    const QMap<QByteArray, QByteArray> &extraHeaders, GLib.Object *parent)
    : AbstractNetworkJob (account, string (), parent)
    , _url (url)
    , _extraHeaders (extraHeaders) {
}

void MkColJob.start () {
    // add 'Content-Length : 0' header (see https://github.com/owncloud/client/issues/3256)
    QNetworkRequest req;
    req.setRawHeader ("Content-Length", "0");
    for (auto it = _extraHeaders.constBegin (); it != _extraHeaders.constEnd (); ++it) {
        req.setRawHeader (it.key (), it.value ());
    }

    // assumes ownership
    if (_url.isValid ()) {
        sendRequest ("MKCOL", _url, req);
    } else {
        sendRequest ("MKCOL", makeDavUrl (path ()), req);
    }
    AbstractNetworkJob.start ();
}

bool MkColJob.finished () {
    qCInfo (lcMkColJob) << "MKCOL of" << reply ().request ().url () << "FINISHED WITH STATUS"
                       << replyStatusString ();

    if (reply ().error () != QNetworkReply.NoError) {
        Q_EMIT finishedWithError (reply ());
    } else {
        Q_EMIT finishedWithoutError ();
    }
    return true;
}

/****************************************************************************/
// supposed to read <D:collection> when pointing to <D:resourcetype><D:collection></D:resourcetype>..
static string readContentsAsString (QXmlStreamReader &reader) {
    string result;
    int level = 0;
    do {
        QXmlStreamReader.TokenType type = reader.readNext ();
        if (type == QXmlStreamReader.StartElement) {
            level++;
            result += "<" + reader.name ().toString () + ">";
        } else if (type == QXmlStreamReader.Characters) {
            result += reader.text ();
        } else if (type == QXmlStreamReader.EndElement) {
            level--;
            if (level < 0) {
                break;
            }
            result += "</" + reader.name ().toString () + ">";
        }

    } while (!reader.atEnd ());
    return result;
}

LsColXMLParser.LsColXMLParser () = default;

bool LsColXMLParser.parse (QByteArray &xml, QHash<string, ExtraFolderInfo> *fileInfo, string &expectedPath) {
    // Parse DAV response
    QXmlStreamReader reader (xml);
    reader.addExtraNamespaceDeclaration (QXmlStreamNamespaceDeclaration ("d", "DAV:"));

    QStringList folders;
    string currentHref;
    QMap<string, string> currentTmpProperties;
    QMap<string, string> currentHttp200Properties;
    bool currentPropsHaveHttp200 = false;
    bool insidePropstat = false;
    bool insideProp = false;
    bool insideMultiStatus = false;

    while (!reader.atEnd ()) {
        QXmlStreamReader.TokenType type = reader.readNext ();
        string name = reader.name ().toString ();
        // Start elements with DAV:
        if (type == QXmlStreamReader.StartElement && reader.namespaceUri () == QLatin1String ("DAV:")) {
            if (name == QLatin1String ("href")) {
                // We don't use URL encoding in our request URL (which is the expected path) (QNAM will do it for us)
                // but the result will have URL encoding..
                string hrefString = QUrl.fromLocalFile (QUrl.fromPercentEncoding (reader.readElementText ().toUtf8 ()))
                        .adjusted (QUrl.NormalizePathSegments)
                        .path ();
                if (!hrefString.startsWith (expectedPath)) {
                    qCWarning (lcLsColJob) << "Invalid href" << hrefString << "expected starting with" << expectedPath;
                    return false;
                }
                currentHref = hrefString;
            } else if (name == QLatin1String ("response")) {
            } else if (name == QLatin1String ("propstat")) {
                insidePropstat = true;
            } else if (name == QLatin1String ("status") && insidePropstat) {
                string httpStatus = reader.readElementText ();
                if (httpStatus.startsWith ("HTTP/1.1 200")) {
                    currentPropsHaveHttp200 = true;
                } else {
                    currentPropsHaveHttp200 = false;
                }
            } else if (name == QLatin1String ("prop")) {
                insideProp = true;
                continue;
            } else if (name == QLatin1String ("multistatus")) {
                insideMultiStatus = true;
                continue;
            }
        }

        if (type == QXmlStreamReader.StartElement && insidePropstat && insideProp) {
            // All those elements are properties
            string propertyContent = readContentsAsString (reader);
            if (name == QLatin1String ("resourcetype") && propertyContent.contains ("collection")) {
                folders.append (currentHref);
            } else if (name == QLatin1String ("size")) {
                bool ok = false;
                auto s = propertyContent.toLongLong (&ok);
                if (ok && fileInfo) {
                    (*fileInfo)[currentHref].size = s;
                }
            } else if (name == QLatin1String ("fileid")) {
                (*fileInfo)[currentHref].fileId = propertyContent.toUtf8 ();
            }
            currentTmpProperties.insert (reader.name ().toString (), propertyContent);
        }

        // End elements with DAV:
        if (type == QXmlStreamReader.EndElement) {
            if (reader.namespaceUri () == QLatin1String ("DAV:")) {
                if (reader.name () == "response") {
                    if (currentHref.endsWith ('/')) {
                        currentHref.chop (1);
                    }
                    emit directoryListingIterated (currentHref, currentHttp200Properties);
                    currentHref.clear ();
                    currentHttp200Properties.clear ();
                } else if (reader.name () == "propstat") {
                    insidePropstat = false;
                    if (currentPropsHaveHttp200) {
                        currentHttp200Properties = QMap<string, string> (currentTmpProperties);
                    }
                    currentTmpProperties.clear ();
                    currentPropsHaveHttp200 = false;
                } else if (reader.name () == "prop") {
                    insideProp = false;
                }
            }
        }
    }

    if (reader.hasError ()) {
        // XML Parser error? Whatever had been emitted before will come as directoryListingIterated
        qCWarning (lcLsColJob) << "ERROR" << reader.errorString () << xml;
        return false;
    } else if (!insideMultiStatus) {
        qCWarning (lcLsColJob) << "ERROR no WebDAV response?" << xml;
        return false;
    } else {
        emit directoryListingSubfolders (folders);
        emit finishedWithoutError ();
    }
    return true;
}

/****************************************************************************/

LsColJob.LsColJob (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

LsColJob.LsColJob (AccountPtr account, QUrl &url, GLib.Object *parent)
    : AbstractNetworkJob (account, string (), parent)
    , _url (url) {
}

void LsColJob.setProperties (QList<QByteArray> properties) {
    _properties = properties;
}

QList<QByteArray> LsColJob.properties () {
    return _properties;
}

void LsColJob.start () {
    QList<QByteArray> properties = _properties;

    if (properties.isEmpty ()) {
        qCWarning (lcLsColJob) << "Propfind with no properties!";
    }
    QByteArray propStr;
    foreach (QByteArray &prop, properties) {
        if (prop.contains (':')) {
            int colIdx = prop.lastIndexOf (":");
            auto ns = prop.left (colIdx);
            if (ns == "http://owncloud.org/ns") {
                propStr += "    <oc:" + prop.mid (colIdx + 1) + " />\n";
            } else {
                propStr += "    <" + prop.mid (colIdx + 1) + " xmlns=\"" + ns + "\" />\n";
            }
        } else {
            propStr += "    <d:" + prop + " />\n";
        }
    }

    QNetworkRequest req;
    req.setRawHeader ("Depth", "1");
    QByteArray xml ("<?xml version=\"1.0\" ?>\n"
                   "<d:propfind xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\">\n"
                   "  <d:prop>\n"
        + propStr + "  </d:prop>\n"
                    "</d:propfind>\n");
    auto *buf = new QBuffer (this);
    buf.setData (xml);
    buf.open (QIODevice.ReadOnly);
    if (_url.isValid ()) {
        sendRequest ("PROPFIND", _url, req, buf);
    } else {
        sendRequest ("PROPFIND", makeDavUrl (path ()), req, buf);
    }
    AbstractNetworkJob.start ();
}

// TODO : Instead of doing all in this slot, we should iteratively parse in readyRead (). This
// would allow us to be more asynchronous in processing while data is coming from the network,
// not all in one big blob at the end.
bool LsColJob.finished () {
    qCInfo (lcLsColJob) << "LSCOL of" << reply ().request ().url () << "FINISHED WITH STATUS"
                       << replyStatusString ();

    string contentType = reply ().header (QNetworkRequest.ContentTypeHeader).toString ();
    int httpCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    if (httpCode == 207 && contentType.contains ("application/xml; charset=utf-8")) {
        LsColXMLParser parser;
        connect (&parser, &LsColXMLParser.directoryListingSubfolders,
            this, &LsColJob.directoryListingSubfolders);
        connect (&parser, &LsColXMLParser.directoryListingIterated,
            this, &LsColJob.directoryListingIterated);
        connect (&parser, &LsColXMLParser.finishedWithError,
            this, &LsColJob.finishedWithError);
        connect (&parser, &LsColXMLParser.finishedWithoutError,
            this, &LsColJob.finishedWithoutError);

        string expectedPath = reply ().request ().url ().path (); // something like "/owncloud/remote.php/dav/folder"
        if (!parser.parse (reply ().readAll (), &_folderInfos, expectedPath)) {
            // XML parse error
            emit finishedWithError (reply ());
        }
    } else {
        // wrong content type, wrong HTTP code or any other network error
        emit finishedWithError (reply ());
    }

    return true;
}

/****************************************************************************/

namespace {
    const char statusphpC[] = "status.php";
    const char nextcloudDirC[] = "nextcloud/";
}

CheckServerJob.CheckServerJob (AccountPtr account, GLib.Object *parent)
    : AbstractNetworkJob (account, QLatin1String (statusphpC), parent)
    , _subdirFallback (false)
    , _permanentRedirects (0) {
    setIgnoreCredentialFailure (true);
    connect (this, &AbstractNetworkJob.redirected,
        this, &CheckServerJob.slotRedirected);
}

void CheckServerJob.start () {
    _serverUrl = account ().url ();
    sendRequest ("GET", Utility.concatUrlPath (_serverUrl, path ()));
    connect (reply (), &QNetworkReply.metaDataChanged, this, &CheckServerJob.metaDataChangedSlot);
    connect (reply (), &QNetworkReply.encrypted, this, &CheckServerJob.encryptedSlot);
    AbstractNetworkJob.start ();
}

void CheckServerJob.onTimedOut () {
    qCWarning (lcCheckServerJob) << "TIMEOUT";
    if (reply () && reply ().isRunning ()) {
        emit timeout (reply ().url ());
    } else if (!reply ()) {
        qCWarning (lcCheckServerJob) << "Timeout even there was no reply?";
    }
    deleteLater ();
}

string CheckServerJob.version (QJsonObject &info) {
    return info.value (QLatin1String ("version")).toString ();
}

string CheckServerJob.versionString (QJsonObject &info) {
    return info.value (QLatin1String ("versionstring")).toString ();
}

bool CheckServerJob.installed (QJsonObject &info) {
    return info.value (QLatin1String ("installed")).toBool ();
}

static void mergeSslConfigurationForSslButton (QSslConfiguration &config, AccountPtr account) {
    if (config.peerCertificateChain ().length () > 0) {
        account._peerCertificateChain = config.peerCertificateChain ();
    }
    if (!config.sessionCipher ().isNull ()) {
        account._sessionCipher = config.sessionCipher ();
    }
    if (config.sessionTicket ().length () > 0) {
        account._sessionTicket = config.sessionTicket ();
    }
}

void CheckServerJob.encryptedSlot () {
    mergeSslConfigurationForSslButton (reply ().sslConfiguration (), account ());
}

void CheckServerJob.slotRedirected (QNetworkReply *reply, QUrl &targetUrl, int redirectCount) {
    QByteArray slashStatusPhp ("/");
    slashStatusPhp.append (statusphpC);

    int httpCode = reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    string path = targetUrl.path ();
    if ( (httpCode == 301 || httpCode == 308) // permanent redirection
        && redirectCount == _permanentRedirects // don't apply permanent redirects after a temporary one
        && path.endsWith (slashStatusPhp)) {
        _serverUrl = targetUrl;
        _serverUrl.setPath (path.left (path.size () - slashStatusPhp.size ()));
        qCInfo (lcCheckServerJob) << "status.php was permanently redirected to"
                                 << targetUrl << "new server url is" << _serverUrl;
        ++_permanentRedirects;
    }
}

void CheckServerJob.metaDataChangedSlot () {
    account ().setSslConfiguration (reply ().sslConfiguration ());
    mergeSslConfigurationForSslButton (reply ().sslConfiguration (), account ());
}

bool CheckServerJob.finished () {
    if (reply ().request ().url ().scheme () == QLatin1String ("https")
        && reply ().sslConfiguration ().sessionTicket ().isEmpty ()
        && reply ().error () == QNetworkReply.NoError) {
        qCWarning (lcCheckServerJob) << "No SSL session identifier / session ticket is used, this might impact sync performance negatively.";
    }

    mergeSslConfigurationForSslButton (reply ().sslConfiguration (), account ());

    // The server installs to /owncloud. Let's try that if the file wasn't found
    // at the original location
    if ( (reply ().error () == QNetworkReply.ContentNotFoundError) && (!_subdirFallback)) {
        _subdirFallback = true;
        setPath (QLatin1String (nextcloudDirC) + QLatin1String (statusphpC));
        start ();
        qCInfo (lcCheckServerJob) << "Retrying with" << reply ().url ();
        return false;
    }

    QByteArray body = reply ().peek (4 * 1024);
    int httpStatus = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    if (body.isEmpty () || httpStatus != 200) {
        qCWarning (lcCheckServerJob) << "error : status.php replied " << httpStatus << body;
        emit instanceNotFound (reply ());
    } else {
        QJsonParseError error;
        auto status = QJsonDocument.fromJson (body, &error);
        // empty or invalid response
        if (error.error != QJsonParseError.NoError || status.isNull ()) {
            qCWarning (lcCheckServerJob) << "status.php from server is not valid JSON!" << body << reply ().request ().url () << error.errorString ();
        }

        qCInfo (lcCheckServerJob) << "status.php returns : " << status << " " << reply ().error () << " Reply : " << reply ();
        if (status.object ().contains ("installed")) {
            emit instanceFound (_serverUrl, status.object ());
        } else {
            qCWarning (lcCheckServerJob) << "No proper answer on " << reply ().url ();
            emit instanceNotFound (reply ());
        }
    }
    return true;
}

/****************************************************************************/

PropfindJob.PropfindJob (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

void PropfindJob.start () {
    QList<QByteArray> properties = _properties;

    if (properties.isEmpty ()) {
        qCWarning (lcLsColJob) << "Propfind with no properties!";
    }
    QNetworkRequest req;
    // Always have a higher priority than the propagator because we use this from the UI
    // and really want this to be done first (no matter what internal scheduling QNAM uses).
    // Also possibly useful for avoiding false timeouts.
    req.setPriority (QNetworkRequest.HighPriority);
    req.setRawHeader ("Depth", "0");
    QByteArray propStr;
    foreach (QByteArray &prop, properties) {
        if (prop.contains (':')) {
            int colIdx = prop.lastIndexOf (":");
            propStr += "    <" + prop.mid (colIdx + 1) + " xmlns=\"" + prop.left (colIdx) + "\" />\n";
        } else {
            propStr += "    <d:" + prop + " />\n";
        }
    }
    QByteArray xml = "<?xml version=\"1.0\" ?>\n"
                     "<d:propfind xmlns:d=\"DAV:\">\n"
                     "  <d:prop>\n"
        + propStr + "  </d:prop>\n"
                    "</d:propfind>\n";

    auto *buf = new QBuffer (this);
    buf.setData (xml);
    buf.open (QIODevice.ReadOnly);
    sendRequest ("PROPFIND", makeDavUrl (path ()), req, buf);

    AbstractNetworkJob.start ();
}

void PropfindJob.setProperties (QList<QByteArray> properties) {
    _properties = properties;
}

QList<QByteArray> PropfindJob.properties () {
    return _properties;
}

bool PropfindJob.finished () {
    qCInfo (lcPropfindJob) << "PROPFIND of" << reply ().request ().url () << "FINISHED WITH STATUS"
                          << replyStatusString ();

    int http_result_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();

    if (http_result_code == 207) {
        // Parse DAV response
        QXmlStreamReader reader (reply ());
        reader.addExtraNamespaceDeclaration (QXmlStreamNamespaceDeclaration ("d", "DAV:"));

        QVariantMap items;
        // introduced to nesting is ignored
        QStack<string> curElement;

        while (!reader.atEnd ()) {
            QXmlStreamReader.TokenType type = reader.readNext ();
            if (type == QXmlStreamReader.StartElement) {
                if (!curElement.isEmpty () && curElement.top () == QLatin1String ("prop")) {
                    items.insert (reader.name ().toString (), reader.readElementText (QXmlStreamReader.SkipChildElements));
                } else {
                    curElement.push (reader.name ().toString ());
                }
            }
            if (type == QXmlStreamReader.EndElement) {
                if (curElement.top () == reader.name ()) {
                    curElement.pop ();
                }
            }
        }
        if (reader.hasError ()) {
            qCWarning (lcPropfindJob) << "XML parser error : " << reader.errorString ();
            emit finishedWithError (reply ());
        } else {
            emit result (items);
        }
    } else {
        qCWarning (lcPropfindJob) << "*not* successful, http result code is" << http_result_code
                                 << (http_result_code == 302 ? reply ().header (QNetworkRequest.LocationHeader).toString () : QLatin1String (""));
        emit finishedWithError (reply ());
    }
    return true;
}

/****************************************************************************/

#ifndef TOKEN_AUTH_ONLY
AvatarJob.AvatarJob (AccountPtr account, string &userId, int size, GLib.Object *parent)
    : AbstractNetworkJob (account, string (), parent) {
    if (account.serverVersionInt () >= Account.makeServerVersion (10, 0, 0)) {
        _avatarUrl = Utility.concatUrlPath (account.url (), string ("remote.php/dav/avatars/%1/%2.png").arg (userId, string.number (size)));
    } else {
        _avatarUrl = Utility.concatUrlPath (account.url (), string ("index.php/avatar/%1/%2").arg (userId, string.number (size)));
    }
}

void AvatarJob.start () {
    QNetworkRequest req;
    sendRequest ("GET", _avatarUrl, req);
    AbstractNetworkJob.start ();
}

QImage AvatarJob.makeCircularAvatar (QImage &baseAvatar) {
    if (baseAvatar.isNull ()) {
        return {};
    }

    int dim = baseAvatar.width ();

    QImage avatar (dim, dim, QImage.Format_ARGB32);
    avatar.fill (Qt.transparent);

    QPainter painter (&avatar);
    painter.setRenderHint (QPainter.Antialiasing);

    QPainterPath path;
    path.addEllipse (0, 0, dim, dim);
    painter.setClipPath (path);

    painter.drawImage (0, 0, baseAvatar);
    painter.end ();

    return avatar;
}

bool AvatarJob.finished () {
    int http_result_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();

    QImage avImage;

    if (http_result_code == 200) {
        QByteArray pngData = reply ().readAll ();
        if (pngData.size ()) {
            if (avImage.loadFromData (pngData)) {
                qCDebug (lcAvatarJob) << "Retrieved Avatar pixmap!";
            }
        }
    }
    emit (avatarPixmap (avImage));
    return true;
}
#endif

/****************************************************************************/

ProppatchJob.ProppatchJob (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

void ProppatchJob.start () {
    if (_properties.isEmpty ()) {
        qCWarning (lcProppatchJob) << "Proppatch with no properties!";
    }
    QNetworkRequest req;

    QByteArray propStr;
    QMapIterator<QByteArray, QByteArray> it (_properties);
    while (it.hasNext ()) {
        it.next ();
        QByteArray keyName = it.key ();
        QByteArray keyNs;
        if (keyName.contains (':')) {
            int colIdx = keyName.lastIndexOf (":");
            keyNs = keyName.left (colIdx);
            keyName = keyName.mid (colIdx + 1);
        }

        propStr += "    <" + keyName;
        if (!keyNs.isEmpty ()) {
            propStr += " xmlns=\"" + keyNs + "\" ";
        }
        propStr += ">";
        propStr += it.value ();
        propStr += "</" + keyName + ">\n";
    }
    QByteArray xml = "<?xml version=\"1.0\" ?>\n"
                     "<d:propertyupdate xmlns:d=\"DAV:\">\n"
                     "  <d:set><d:prop>\n"
        + propStr + "  </d:prop></d:set>\n"
                    "</d:propertyupdate>\n";

    auto *buf = new QBuffer (this);
    buf.setData (xml);
    buf.open (QIODevice.ReadOnly);
    sendRequest ("PROPPATCH", makeDavUrl (path ()), req, buf);
    AbstractNetworkJob.start ();
}

void ProppatchJob.setProperties (QMap<QByteArray, QByteArray> properties) {
    _properties = properties;
}

QMap<QByteArray, QByteArray> ProppatchJob.properties () {
    return _properties;
}

bool ProppatchJob.finished () {
    qCInfo (lcProppatchJob) << "PROPPATCH of" << reply ().request ().url () << "FINISHED WITH STATUS"
                           << replyStatusString ();

    int http_result_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();

    if (http_result_code == 207) {
        emit success ();
    } else {
        qCWarning (lcProppatchJob) << "*not* successful, http result code is" << http_result_code
                                  << (http_result_code == 302 ? reply ().header (QNetworkRequest.LocationHeader).toString () : QLatin1String (""));
        emit finishedWithError ();
    }
    return true;
}

/****************************************************************************/

EntityExistsJob.EntityExistsJob (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

void EntityExistsJob.start () {
    sendRequest ("HEAD", makeAccountUrl (path ()));
    AbstractNetworkJob.start ();
}

bool EntityExistsJob.finished () {
    emit exists (reply ());
    return true;
}

/****************************************************************************/

JsonApiJob.JsonApiJob (AccountPtr &account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

void JsonApiJob.addQueryParams (QUrlQuery &params) {
    _additionalParams = params;
}

void JsonApiJob.addRawHeader (QByteArray &headerName, QByteArray &value) {
   _request.setRawHeader (headerName, value);
}

void JsonApiJob.setBody (QJsonDocument &body) {
    _body = body.toJson ();
    qCDebug (lcJsonApiJob) << "Set body for request:" << _body;
    if (!_body.isEmpty ()) {
        _request.setHeader (QNetworkRequest.ContentTypeHeader, "application/json");
    }
}

void JsonApiJob.setVerb (Verb value) {
    _verb = value;
}

QByteArray JsonApiJob.verbToString () {
    switch (_verb) {
    case Verb.Get:
        return "GET";
    case Verb.Post:
        return "POST";
    case Verb.Put:
        return "PUT";
    case Verb.Delete:
        return "DELETE";
    }
    return "GET";
}

void JsonApiJob.start () {
    addRawHeader ("OCS-APIREQUEST", "true");
    auto query = _additionalParams;
    query.addQueryItem (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concatUrlPath (account ().url (), path (), query);
    const auto httpVerb = verbToString ();
    if (!_body.isEmpty ()) {
        sendRequest (httpVerb, url, _request, _body);
    } else {
        sendRequest (httpVerb, url, _request);
    }
    AbstractNetworkJob.start ();
}

bool JsonApiJob.finished () {
    qCInfo (lcJsonApiJob) << "JsonApiJob of" << reply ().request ().url () << "FINISHED WITH STATUS"
                         << replyStatusString ();

    int statusCode = 0;
    int httpStatusCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    if (reply ().error () != QNetworkReply.NoError) {
        qCWarning (lcJsonApiJob) << "Network error : " << path () << errorString () << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute);
        statusCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
        emit jsonReceived (QJsonDocument (), statusCode);
        return true;
    }

    string jsonStr = string.fromUtf8 (reply ().readAll ());
    if (jsonStr.contains ("<?xml version=\"1.0\"?>")) {
        const QRegularExpression rex ("<statuscode> (\\d+)</statuscode>");
        const auto rexMatch = rex.match (jsonStr);
        if (rexMatch.hasMatch ()) {
            // this is a error message coming back from ocs.
            statusCode = rexMatch.captured (1).toInt ();
        }
    } else if (jsonStr.isEmpty () && httpStatusCode == notModifiedStatusCode){
        qCWarning (lcJsonApiJob) << "Nothing changed so nothing to retrieve - status code : " << httpStatusCode;
        statusCode = httpStatusCode;
    } else {
        const QRegularExpression rex (R" ("statuscode" : (\d+))");
        // example : "{"ocs":{"meta":{"status":"ok","statuscode":100,"message":null},"data":{"version":{"major":8,"minor":"... (504)
        const auto rxMatch = rex.match (jsonStr);
        if (rxMatch.hasMatch ()) {
            statusCode = rxMatch.captured (1).toInt ();
        }
    }

    // save new ETag value
    if (reply ().rawHeaderList ().contains ("ETag"))
        emit etagResponseHeaderReceived (reply ().rawHeader ("ETag"), statusCode);

    const auto desktopNotificationsAllowed = reply ().rawHeader (QByteArray ("X-Nextcloud-User-Status"));
    if (!desktopNotificationsAllowed.isEmpty ()) {
        emit allowDesktopNotificationsChanged (desktopNotificationsAllowed == "online");
    }

    QJsonParseError error;
    auto json = QJsonDocument.fromJson (jsonStr.toUtf8 (), &error);
    // empty or invalid response and status code is != 304 because jsonStr is expected to be empty
    if ( (error.error != QJsonParseError.NoError || json.isNull ()) && httpStatusCode != notModifiedStatusCode) {
        qCWarning (lcJsonApiJob) << "invalid JSON!" << jsonStr << error.errorString ();
        emit jsonReceived (json, statusCode);
        return true;
    }

    emit jsonReceived (json, statusCode);
    return true;
}

DetermineAuthTypeJob.DetermineAuthTypeJob (AccountPtr account, GLib.Object *parent)
    : GLib.Object (parent)
    , _account (account) {
}

void DetermineAuthTypeJob.start () {
    qCInfo (lcDetermineAuthTypeJob) << "Determining auth type for" << _account.davUrl ();

    QNetworkRequest req;
    // Prevent HttpCredentialsAccessManager from setting an Authorization header.
    req.setAttribute (HttpCredentials.DontAddCredentialsAttribute, true);
    // Don't reuse previous auth credentials
    req.setAttribute (QNetworkRequest.AuthenticationReuseAttribute, QNetworkRequest.Manual);

    // Start three parallel requests

    // 1. determines whether it's a basic auth server
    auto get = _account.sendRequest ("GET", _account.url (), req);

    // 2. checks the HTTP auth method.
    auto propfind = _account.sendRequest ("PROPFIND", _account.davUrl (), req);

    // 3. Determines if the old flow has to be used (GS for now)
    auto oldFlowRequired = new JsonApiJob (_account, "/ocs/v2.php/cloud/capabilities", this);

    get.setTimeout (30 * 1000);
    propfind.setTimeout (30 * 1000);
    oldFlowRequired.setTimeout (30 * 1000);
    get.setIgnoreCredentialFailure (true);
    propfind.setIgnoreCredentialFailure (true);
    oldFlowRequired.setIgnoreCredentialFailure (true);

    connect (get, &SimpleNetworkJob.finishedSignal, this, [this, get] () {
        const auto reply = get.reply ();
        const auto wwwAuthenticateHeader = reply.rawHeader ("WWW-Authenticate");
        if (reply.error () == QNetworkReply.AuthenticationRequiredError
            && (wwwAuthenticateHeader.startsWith ("Basic") || wwwAuthenticateHeader.startsWith ("Bearer"))) {
            _resultGet = Basic;
        } else {
            _resultGet = LoginFlowV2;
        }
        _getDone = true;
        checkAllDone ();
    });
    connect (propfind, &SimpleNetworkJob.finishedSignal, this, [this] (QNetworkReply *reply) {
        auto authChallenge = reply.rawHeader ("WWW-Authenticate").toLower ();
        if (authChallenge.contains ("bearer ")) {
            _resultPropfind = OAuth;
        } else {
            if (authChallenge.isEmpty ()) {
                qCWarning (lcDetermineAuthTypeJob) << "Did not receive WWW-Authenticate reply to auth-test PROPFIND";
            } else {
                qCWarning (lcDetermineAuthTypeJob) << "Unknown WWW-Authenticate reply to auth-test PROPFIND:" << authChallenge;
            }
            _resultPropfind = Basic;
        }
        _propfindDone = true;
        checkAllDone ();
    });
    connect (oldFlowRequired, &JsonApiJob.jsonReceived, this, [this] (QJsonDocument &json, int statusCode) {
        if (statusCode == 200) {
            _resultOldFlow = LoginFlowV2;

            auto data = json.object ().value ("ocs").toObject ().value ("data").toObject ().value ("capabilities").toObject ();
            auto gs = data.value ("globalscale");
            if (gs != QJsonValue.Undefined) {
                auto flow = gs.toObject ().value ("desktoplogin");
                if (flow != QJsonValue.Undefined) {
                    if (flow.toInt () == 1) {
#ifdef WITH_WEBENGINE
                        _resultOldFlow = WebViewFlow;
#else // WITH_WEBENGINE
                        qCWarning (lcDetermineAuthTypeJob) << "Server does only support flow1, but this client was compiled without support for flow1";
#endif // WITH_WEBENGINE
                    }
                }
            }
        } else {
            _resultOldFlow = Basic;
        }
        _oldFlowDone = true;
        checkAllDone ();
    });

    oldFlowRequired.start ();
}

void DetermineAuthTypeJob.checkAllDone () {
    // Do not conitunue until eve
    if (!_getDone || !_propfindDone || !_oldFlowDone) {
        return;
    }

    Q_ASSERT (_resultGet != NoAuthType);
    Q_ASSERT (_resultPropfind != NoAuthType);
    Q_ASSERT (_resultOldFlow != NoAuthType);

    auto result = _resultPropfind;

#ifdef WITH_WEBENGINE
    // WebViewFlow > OAuth > Basic
    if (_account.serverVersionInt () >= Account.makeServerVersion (12, 0, 0)) {
        result = WebViewFlow;
    }
#endif // WITH_WEBENGINE

    // LoginFlowV2 > WebViewFlow > OAuth > Basic
    if (_account.serverVersionInt () >= Account.makeServerVersion (16, 0, 0)) {
        result = LoginFlowV2;
    }

#ifdef WITH_WEBENGINE
    // If we determined that we need the webview flow (GS for example) then we switch to that
    if (_resultOldFlow == WebViewFlow) {
        result = WebViewFlow;
    }
#endif // WITH_WEBENGINE

    // If we determined that a simple get gave us an authentication required error
    // then the server enforces basic auth and we got no choice but to use this
    if (_resultGet == Basic) {
        result = Basic;
    }

    qCInfo (lcDetermineAuthTypeJob) << "Auth type for" << _account.davUrl () << "is" << result;
    emit authType (result);
    deleteLater ();
}

SimpleNetworkJob.SimpleNetworkJob (AccountPtr account, GLib.Object *parent)
    : AbstractNetworkJob (account, string (), parent) {
}

QNetworkReply *SimpleNetworkJob.startRequest (QByteArray &verb, QUrl &url,
    QNetworkRequest req, QIODevice *requestBody) {
    auto reply = sendRequest (verb, url, req, requestBody);
    start ();
    return reply;
}

bool SimpleNetworkJob.finished () {
    emit finishedSignal (reply ());
    return true;
}

DeleteApiJob.DeleteApiJob (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {

}

void DeleteApiJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("OCS-APIREQUEST", "true");
    QUrl url = Utility.concatUrlPath (account ().url (), path ());
    sendRequest ("DELETE", url, req);
    AbstractNetworkJob.start ();
}

bool DeleteApiJob.finished () {
    qCInfo (lcJsonApiJob) << "JsonApiJob of" << reply ().request ().url () << "FINISHED WITH STATUS"
                         << reply ().error ()
                         << (reply ().error () == QNetworkReply.NoError ? QLatin1String ("") : errorString ());

    int httpStatus = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();

    if (reply ().error () != QNetworkReply.NoError) {
        qCWarning (lcJsonApiJob) << "Network error : " << path () << errorString () << httpStatus;
        emit result (httpStatus);
        return true;
    }

    const auto replyData = string.fromUtf8 (reply ().readAll ());
    qCInfo (lcJsonApiJob ()) << "TMX Delete Job" << replyData;
    emit result (httpStatus);
    return true;
}

void fetchPrivateLinkUrl (AccountPtr account, string &remotePath,
    const QByteArray &numericFileId, GLib.Object *target,
    std.function<void (string &url)> targetFun) {
    string oldUrl;
    if (!numericFileId.isEmpty ())
        oldUrl = account.deprecatedPrivateLinkUrl (numericFileId).toString (QUrl.FullyEncoded);

    // Retrieve the new link by PROPFIND
    auto *job = new PropfindJob (account, remotePath, target);
    job.setProperties (
        QList<QByteArray> ()
        << "http://owncloud.org/ns:fileid" // numeric file id for fallback private link generation
        << "http://owncloud.org/ns:privatelink");
    job.setTimeout (10 * 1000);
    GLib.Object.connect (job, &PropfindJob.result, target, [=] (QVariantMap &result) {
        auto privateLinkUrl = result["privatelink"].toString ();
        auto numericFileId = result["fileid"].toByteArray ();
        if (!privateLinkUrl.isEmpty ()) {
            targetFun (privateLinkUrl);
        } else if (!numericFileId.isEmpty ()) {
            targetFun (account.deprecatedPrivateLinkUrl (numericFileId).toString (QUrl.FullyEncoded));
        } else {
            targetFun (oldUrl);
        }
    });
    GLib.Object.connect (job, &PropfindJob.finishedWithError, target, [=] (QNetworkReply *) {
        targetFun (oldUrl);
    });
    job.start ();
}

} // namespace Occ
