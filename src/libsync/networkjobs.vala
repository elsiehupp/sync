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
void OWNCLOUDSYNC_EXPORT fetchPrivateLinkUrl (
    AccountPtr account, string &remotePath,
    const QByteArray &numericFileId, GLib.Object *target,
    std.function<void (string &url)> targetFun);

} // namespace Occ
