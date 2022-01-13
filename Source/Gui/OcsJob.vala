/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QVector>
// #include <QList>
// #include <QPair>
// #include <QUrl>

const int OCS_SUCCESS_STATUS_CODE 100
// Apparantly the v2.php URLs can return that
const int OCS_SUCCESS_STATUS_CODE_V2 200
// not modified when using  ETag
const int OCS_NOT_MODIFIED_STATUS_CODE_V2 304


namespace Occ {

/***********************************************************
@brief The OcsShareJob class
@ingroup gui

Base class for jobs that talk to the OCS endpoints on th
All the communication logic is handled in this class.

All OCS jobs (e.g. sharing) should extend this class.
***********************************************************/
class OcsJob : AbstractNetworkJob {

protected:
    OcsJob (AccountPtr account);

    /***********************************************************
     * Set the verb for the job
     *
     * @param verb currently supported PUT POST DELETE
     */
    void setVerb (QByteArray &verb);

    /***********************************************************
     * Add a new parameter to the request.
     * Depending on the verb this is GET or POST parameter
     *
     * @param name The name of the parameter
     * @param value The value of the parameter
     */
    void addParam (string &name, string &value);

    /***********************************************************
     * Set the post parameters
     *
     * @param postParams list of pairs to add (urlEncoded) to the body of the
     * request
     */
    void setPostParams (QList<QPair<string, string>> &postParams);

    /***********************************************************
     * List of expected statuscodes for this request
     * A warning will be printed to the debug log if a different status code is
     * encountered
     *
     * @param code Accepted status code
     */
    void addPassStatusCode (int code);

    /***********************************************************
     * The base path for an OcsJob is always the same. But it could be the case that
     * certain operations need to append something to the URL.
     *
     * This function appends the common id. so <PATH>/<ID>
     */
    void appendPath (string &id);

public:
    /***********************************************************
     * Parse the response and return the status code and the message of the
     * reply (metadata)
     *
     * @param json The reply from OCS
     * @param message The message that is set in the metadata
     * @return The statuscode of the OCS response
     */
    static int getJsonReturnCode (QJsonDocument &json, string &message);

    /***********************************************************
     * @brief Adds header to the request e.g. "If-None-Match"
     * @param headerName a string with the header name
     * @param value a string with the value
     */
    void addRawHeader (QByteArray &headerName, QByteArray &value);

protected slots:

    /***********************************************************
     * Start the OCS request
     */
    void start () override;

signals:

    /***********************************************************
     * Result of the OCS request
     *
     * @param reply the reply
     */
    void jobFinished (QJsonDocument reply, int statusCode);

    /***********************************************************
     * The status code was not one of the expected (passing)
     * status code for this command
     *
     * @param statusCode The actual status code
     * @param message The message provided by the server
     */
    void ocsError (int statusCode, string &message);

    /***********************************************************
     * @brief etagResponseHeaderReceived - signal to report the ETag response header value
     * from ocs api v2
     * @param value - the ETag response header value
     * @param statusCode - the OCS status code : 100 (!) for success
     */
    void etagResponseHeaderReceived (QByteArray &value, int statusCode);

private slots:
    bool finished () override;

private:
    QByteArray _verb;
    QList<QPair<string, string>> _params;
    QVector<int> _passStatusCodes;
    QNetworkRequest _request;
};
}







/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QBuffer>
// #include <QJsonDocument>
// #include <QJsonObject>

namespace Occ {

    Q_LOGGING_CATEGORY (lcOcs, "nextcloud.gui.sharing.ocs", QtInfoMsg)
    
    OcsJob.OcsJob (AccountPtr account)
        : AbstractNetworkJob (account, "") {
        _passStatusCodes.append (OCS_SUCCESS_STATUS_CODE);
        _passStatusCodes.append (OCS_SUCCESS_STATUS_CODE_V2);
        _passStatusCodes.append (OCS_NOT_MODIFIED_STATUS_CODE_V2);
        setIgnoreCredentialFailure (true);
    }
    
    void OcsJob.setVerb (QByteArray &verb) {
        _verb = verb;
    }
    
    void OcsJob.addParam (string &name, string &value) {
        _params.append (qMakePair (name, value));
    }
    
    void OcsJob.addPassStatusCode (int code) {
        _passStatusCodes.append (code);
    }
    
    void OcsJob.appendPath (string &id) {
        setPath (path () + QLatin1Char ('/') + id);
    }
    
    void OcsJob.addRawHeader (QByteArray &headerName, QByteArray &value) {
        _request.setRawHeader (headerName, value);
    }
    
    static QUrlQuery percentEncodeQueryItems (
        const QList<QPair<string, string>> &items) {
        QUrlQuery result;
        // Note : QUrlQuery.setQueryItems () does not fully percent encode
        // the query items, see #5042
        foreach (auto &item, items) {
            result.addQueryItem (
                QUrl.toPercentEncoding (item.first),
                QUrl.toPercentEncoding (item.second));
        }
        return result;
    }
    
    void OcsJob.start () {
        addRawHeader ("Ocs-APIREQUEST", "true");
        addRawHeader ("Content-Type", "application/x-www-form-urlencoded");
    
        auto *buffer = new QBuffer;
    
        QUrlQuery queryItems;
        if (_verb == "GET") {
            queryItems = percentEncodeQueryItems (_params);
        } else if (_verb == "POST" || _verb == "PUT") {
            // Url encode the _postParams and put them in a buffer.
            QByteArray postData;
            Q_FOREACH (auto tmp, _params) {
                if (!postData.isEmpty ()) {
                    postData.append ("&");
                }
                postData.append (QUrl.toPercentEncoding (tmp.first));
                postData.append ("=");
                postData.append (QUrl.toPercentEncoding (tmp.second));
            }
            buffer.setData (postData);
        }
        queryItems.addQueryItem (QLatin1String ("format"), QLatin1String ("json"));
        QUrl url = Utility.concatUrlPath (account ().url (), path (), queryItems);
        sendRequest (_verb, url, _request, buffer);
        AbstractNetworkJob.start ();
    }
    
    bool OcsJob.finished () {
        const QByteArray replyData = reply ().readAll ();
    
        QJsonParseError error;
        string message;
        int statusCode = 0;
        auto json = QJsonDocument.fromJson (replyData, &error);
    
        // when it is null we might have a 304 so get status code from reply () and gives a warning...
        if (error.error != QJsonParseError.NoError) {
            statusCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
            qCWarning (lcOcs) << "Could not parse reply to"
                             << _verb
                             << Utility.concatUrlPath (account ().url (), path ())
                             << _params
                             << error.errorString ()
                             << ":" << replyData;
        } else {
            statusCode  = getJsonReturnCode (json, message);
        }
    
        //... then it checks for the statusCode
        if (!_passStatusCodes.contains (statusCode)) {
            qCWarning (lcOcs) << "Reply to"
                             << _verb
                             << Utility.concatUrlPath (account ().url (), path ())
                             << _params
                             << "has unexpected status code:" << statusCode << replyData;
            emit ocsError (statusCode, message);
    
        } else {
            // save new ETag value
            if (reply ().rawHeaderList ().contains ("ETag"))
                emit etagResponseHeaderReceived (reply ().rawHeader ("ETag"), statusCode);
    
            emit jobFinished (json, statusCode);
        }
        return true;
    }
    
    int OcsJob.getJsonReturnCode (QJsonDocument &json, string &message) {
        //TODO proper checking
        auto meta = json.object ().value ("ocs").toObject ().value ("meta").toObject ();
        int code = meta.value ("statuscode").toInt ();
        message = meta.value ("message").toString ();
    
        return code;
    }
    }
    