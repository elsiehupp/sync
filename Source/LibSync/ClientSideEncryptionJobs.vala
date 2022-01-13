#ifndef CLIENTSIDEENCRYPTIONJOBS_H
const int CLIENTSIDEENCRYPTIONJOBS_H

// #include <string>
// #include <QJsonDocument>

namespace Occ {
/* Here are all of the network jobs for the client side encryption.
anything that goes thru the server and expects a response, is here.
***********************************************************/

/***********************************************************
@brief Job to sigh the CSR that return JSON

To be
\code
_job = new SignPubli
_job.setCsr ( csr
connect (_job.
_job.start
\encode

@ingroup libsync
***********************************************************/
class SignPublicKeyApiJob : AbstractNetworkJob {
public:
    SignPublicKeyApiJob (AccountPtr &account, string &path, GLib.Object *parent = nullptr);

    /***********************************************************
     * @brief setCsr - the CSR with the public key.
     * This function needs to be called before start () obviously.
     */
    void setCsr (QByteArray& csr);

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

private:
    QBuffer _csr;
};

/***********************************************************
@brief Job to upload the PrivateKey that return JSON

To be
\code
_job = new StorePrivateKeyApiJo
_job.setPrivateKey
connect (_job.
_job.start
\encode

@ingroup libsync
***********************************************************/
class StorePrivateKeyApiJob : AbstractNetworkJob {
public:
    StorePrivateKeyApiJob (AccountPtr &account, string &path, GLib.Object *parent = nullptr);

    /***********************************************************
     * @brief setCsr - the CSR with the public key.
     * This function needs to be called before start () obviously.
     */
    void setPrivateKey (QByteArray& privateKey);

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

private:
    QBuffer _privKey;
};

/***********************************************************
@brief Job to mark a folder as encrypted JSON

To be
\code
_job = new Set
 connect (
_job.start ();
\encode

@ingroup libsync
***********************************************************/
class SetEncryptionFlagApiJob : AbstractNetworkJob {
public:
    enum FlagAction {
        Clear = 0,
        Set = 1
    };

    SetEncryptionFlagApiJob (AccountPtr &account, QByteArray &fileId, FlagAction flagAction = Set, GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray &fileId);
    void error (QByteArray &fileId, int httpReturnCode);

private:
    QByteArray _fileId;
    FlagAction _flagAction = Set;
};

class LockEncryptFolderApiJob : AbstractNetworkJob {
public:
    LockEncryptFolderApiJob (AccountPtr &account, QByteArray& fileId, GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& fileId, QByteArray& token);
    void error (QByteArray& fileId, int httpdErrorCode);

private:
    QByteArray _fileId;
};

class UnlockEncryptFolderApiJob : AbstractNetworkJob {
public:
    UnlockEncryptFolderApiJob (
        const AccountPtr &account,
        const QByteArray& fileId,
        const QByteArray& token,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& fileId);
    void error (QByteArray& fileId, int httpReturnCode);

private:
    QByteArray _fileId;
    QByteArray _token;
    QBuffer *_tokenBuf;
};

class StoreMetaDataApiJob : AbstractNetworkJob {
public:
    StoreMetaDataApiJob (
        const AccountPtr &account,
        const QByteArray& fileId,
        const QByteArray& b64Metadata,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& fileId);
    void error (QByteArray& fileId, int httpReturnCode);

private:
    QByteArray _fileId;
    QByteArray _b64Metadata;
};

class UpdateMetadataApiJob : AbstractNetworkJob {
public:
    UpdateMetadataApiJob (
        const AccountPtr &account,
        const QByteArray& fileId,
        const QByteArray& b64Metadata,
        const QByteArray& lockedToken,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& fileId);
    void error (QByteArray& fileId, int httpReturnCode);

private:
    QByteArray _fileId;
    QByteArray _b64Metadata;
    QByteArray _token;
};

class GetMetadataApiJob : AbstractNetworkJob {
public:
    GetMetadataApiJob (
        const AccountPtr &account,
        const QByteArray& fileId,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void jsonReceived (QJsonDocument &json, int statusCode);
    void error (QByteArray& fileId, int httpReturnCode);

private:
    QByteArray _fileId;
};

class DeleteMetadataApiJob : AbstractNetworkJob {
public:
    DeleteMetadataApiJob (
        const AccountPtr &account,
        const QByteArray& fileId,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& fileId);
    void error (QByteArray& fileId, int httpErrorCode);

private:
    QByteArray _fileId;
};

}
#endif







// #include <QDebug>
// #include <QLoggingCategory>
// #include <QFileInfo>
// #include <QDir>
// #include <QJsonObject>
// #include <QXmlStreamReader>
// #include <QXmlStreamNamespaceDeclaration>
// #include <QStack>
// #include <QInputDialog>
// #include <QLineEdit>

Q_LOGGING_CATEGORY (lcSignPublicKeyApiJob, "nextcloud.sync.networkjob.sendcsr", QtInfoMsg)
Q_LOGGING_CATEGORY (lcStorePrivateKeyApiJob, "nextcloud.sync.networkjob.storeprivatekey", QtInfoMsg)
Q_LOGGING_CATEGORY (lcCseJob, "nextcloud.sync.networkjob.clientsideencrypt", QtInfoMsg)

namespace Occ {

GetMetadataApiJob.GetMetadataApiJob (AccountPtr& account,
                                    const QByteArray& fileId,
                                    GLib.Object* parent)
 : AbstractNetworkJob (account, e2eeBaseUrl () + QStringLiteral ("meta-data/") + fileId, parent), _fileId (fileId) {
}

void GetMetadataApiJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("OCS-APIREQUEST", "true");
    QUrlQuery query;
    query.addQueryItem (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concatUrlPath (account ().url (), path ());
    url.setQuery (query);

    qCInfo (lcCseJob ()) << "Requesting the metadata for the fileId" << _fileId << "as encrypted";
    sendRequest ("GET", url, req);
    AbstractNetworkJob.start ();
}

bool GetMetadataApiJob.finished () {
    int retCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    if (retCode != 200) {
        qCInfo (lcCseJob ()) << "error requesting the metadata" << path () << errorString () << retCode;
        emit error (_fileId, retCode);
        return true;
    }
    QJsonParseError error;
    auto json = QJsonDocument.fromJson (reply ().readAll (), &error);
    emit jsonReceived (json, reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ());
    return true;
}

StoreMetaDataApiJob.StoreMetaDataApiJob (AccountPtr& account,
                                                 const QByteArray& fileId,
                                                 const QByteArray& b64Metadata,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2eeBaseUrl () + QStringLiteral ("meta-data/") + fileId, parent), _fileId (fileId), _b64Metadata (b64Metadata) {
}

void StoreMetaDataApiJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("OCS-APIREQUEST", "true");
    req.setHeader (QNetworkRequest.ContentTypeHeader, QByteArrayLiteral ("application/x-www-form-urlencoded"));
    QUrlQuery query;
    query.addQueryItem (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concatUrlPath (account ().url (), path ());
    url.setQuery (query);

    QByteArray data = QByteArray ("metaData=") + QUrl.toPercentEncoding (_b64Metadata);
    auto buffer = new QBuffer (this);
    buffer.setData (data);

    qCInfo (lcCseJob ()) << "sending the metadata for the fileId" << _fileId << "as encrypted";
    sendRequest ("POST", url, req, buffer);
    AbstractNetworkJob.start ();
}

bool StoreMetaDataApiJob.finished () {
    int retCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
		if (retCode != 200) {
			qCInfo (lcCseJob ()) << "error sending the metadata" << path () << errorString () << retCode;
			emit error (_fileId, retCode);
		}

		qCInfo (lcCseJob ()) << "Metadata submited to the server successfully";
		emit success (_fileId);
    return true;
}

UpdateMetadataApiJob.UpdateMetadataApiJob (AccountPtr& account,
                                                 const QByteArray& fileId,
                                                 const QByteArray& b64Metadata,
                                                 const QByteArray& token,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2eeBaseUrl () + QStringLiteral ("meta-data/") + fileId, parent)
, _fileId (fileId),
_b64Metadata (b64Metadata),
_token (token) {
}

void UpdateMetadataApiJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("OCS-APIREQUEST", "true");
    req.setHeader (QNetworkRequest.ContentTypeHeader, QByteArrayLiteral ("application/x-www-form-urlencoded"));

    QUrlQuery urlQuery;
    urlQuery.addQueryItem (QStringLiteral ("format"), QStringLiteral ("json"));
    urlQuery.addQueryItem (QStringLiteral ("e2e-token"), _token);

    QUrl url = Utility.concatUrlPath (account ().url (), path ());
    url.setQuery (urlQuery);

    QUrlQuery params;
    params.addQueryItem ("metaData",QUrl.toPercentEncoding (_b64Metadata));
    params.addQueryItem ("e2e-token", _token);

    QByteArray data = params.query ().toLocal8Bit ();
    auto buffer = new QBuffer (this);
    buffer.setData (data);

    qCInfo (lcCseJob ()) << "updating the metadata for the fileId" << _fileId << "as encrypted";
    sendRequest ("PUT", url, req, buffer);
    AbstractNetworkJob.start ();
}

bool UpdateMetadataApiJob.finished () {
    int retCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
		if (retCode != 200) {
			qCInfo (lcCseJob ()) << "error updating the metadata" << path () << errorString () << retCode;
			emit error (_fileId, retCode);
		}

		qCInfo (lcCseJob ()) << "Metadata submited to the server successfully";
		emit success (_fileId);
    return true;
}

UnlockEncryptFolderApiJob.UnlockEncryptFolderApiJob (AccountPtr& account,
                                                 const QByteArray& fileId,
                                                 const QByteArray& token,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2eeBaseUrl () + QStringLiteral ("lock/") + fileId, parent), _fileId (fileId), _token (token) {
}

void UnlockEncryptFolderApiJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("OCS-APIREQUEST", "true");
    req.setRawHeader ("e2e-token", _token);

    QUrl url = Utility.concatUrlPath (account ().url (), path ());
    sendRequest ("DELETE", url, req);

    AbstractNetworkJob.start ();
    qCInfo (lcCseJob ()) << "Starting the request to unlock.";
}

bool UnlockEncryptFolderApiJob.finished () {
    int retCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    if (retCode != 200) {
        qCInfo (lcCseJob ()) << "error unlocking file" << path () << errorString () << retCode;
        qCInfo (lcCseJob ()) << "Full Error Log" << reply ().readAll ();
        emit error (_fileId, retCode);
        return true;
    }
    emit success (_fileId);
    return true;
}

DeleteMetadataApiJob.DeleteMetadataApiJob (AccountPtr& account,
                                                  const QByteArray& fileId,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2eeBaseUrl () + QStringLiteral ("meta-data/") + fileId, parent), _fileId (fileId) {
}

void DeleteMetadataApiJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("OCS-APIREQUEST", "true");

    QUrl url = Utility.concatUrlPath (account ().url (), path ());
    sendRequest ("DELETE", url, req);

    AbstractNetworkJob.start ();
    qCInfo (lcCseJob ()) << "Starting the request to remove the metadata.";
}

bool DeleteMetadataApiJob.finished () {
    int retCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    if (retCode != 200) {
        qCInfo (lcCseJob ()) << "error removing metadata for" << path () << errorString () << retCode;
        qCInfo (lcCseJob ()) << "Full Error Log" << reply ().readAll ();
        emit error (_fileId, retCode);
        return true;
    }
    emit success (_fileId);
    return true;
}

LockEncryptFolderApiJob.LockEncryptFolderApiJob (AccountPtr& account, QByteArray& fileId, GLib.Object* parent)
 : AbstractNetworkJob (account, e2eeBaseUrl () + QStringLiteral ("lock/") + fileId, parent), _fileId (fileId) {
}

void LockEncryptFolderApiJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("OCS-APIREQUEST", "true");
    QUrlQuery query;
    query.addQueryItem (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concatUrlPath (account ().url (), path ());
    url.setQuery (query);

    qCInfo (lcCseJob ()) << "locking the folder with id" << _fileId << "as encrypted";
    sendRequest ("POST", url, req);
    AbstractNetworkJob.start ();
}

bool LockEncryptFolderApiJob.finished () {
    int retCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    if (retCode != 200) {
        qCInfo (lcCseJob ()) << "error locking file" << path () << errorString () << retCode;
        emit error (_fileId, retCode);
        return true;
    }

    QJsonParseError error;
    auto json = QJsonDocument.fromJson (reply ().readAll (), &error);
    auto obj = json.object ().toVariantMap ();
    auto token = obj["ocs"].toMap ()["data"].toMap ()["e2e-token"].toByteArray ();
    qCInfo (lcCseJob ()) << "got json:" << token;

    //TODO : Parse the token and submit.
    emit success (_fileId, token);
    return true;
}

SetEncryptionFlagApiJob.SetEncryptionFlagApiJob (AccountPtr& account, QByteArray& fileId, FlagAction flagAction, GLib.Object* parent)
 : AbstractNetworkJob (account, e2eeBaseUrl () + QStringLiteral ("encrypted/") + fileId, parent), _fileId (fileId), _flagAction (flagAction) {
}

void SetEncryptionFlagApiJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("OCS-APIREQUEST", "true");
    QUrl url = Utility.concatUrlPath (account ().url (), path ());

    qCInfo (lcCseJob ()) << "marking the file with id" << _fileId << "as" << (_flagAction == Set ? "encrypted" : "non-encrypted") << ".";

    sendRequest (_flagAction == Set ? "PUT" : "DELETE", url, req);

    AbstractNetworkJob.start ();
}

bool SetEncryptionFlagApiJob.finished () {
    int retCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    qCInfo (lcCseJob ()) << "Encryption Flag Return" << reply ().readAll ();
    if (retCode == 200) {
        emit success (_fileId);
    } else {
        qCInfo (lcCseJob ()) << "Setting the encrypted flag failed with" << path () << errorString () << retCode;
        emit error (_fileId, retCode);
    }
    return true;
}

StorePrivateKeyApiJob.StorePrivateKeyApiJob (AccountPtr& account, string& path, GLib.Object* parent)
 : AbstractNetworkJob (account, path, parent) {
}

void StorePrivateKeyApiJob.setPrivateKey (QByteArray& privKey) {
    QByteArray data = "privateKey=";
    data += QUrl.toPercentEncoding (privKey);
    _privKey.setData (data);
}

void StorePrivateKeyApiJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("OCS-APIREQUEST", "true");
    QUrlQuery query;
    query.addQueryItem (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concatUrlPath (account ().url (), path ());
    url.setQuery (query);

    qCInfo (lcStorePrivateKeyApiJob) << "Sending the private key" << _privKey.data ();
    sendRequest ("POST", url, req, &_privKey);
    AbstractNetworkJob.start ();
}

bool StorePrivateKeyApiJob.finished () {
    int retCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
    if (retCode != 200)
        qCInfo (lcStorePrivateKeyApiJob ()) << "Sending private key ended with"  << path () << errorString () << retCode;

    QJsonParseError error;
    auto json = QJsonDocument.fromJson (reply ().readAll (), &error);
    emit jsonReceived (json, reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ());
    return true;
}

SignPublicKeyApiJob.SignPublicKeyApiJob (AccountPtr& account, string& path, GLib.Object* parent)
 : AbstractNetworkJob (account, path, parent) {
}

void SignPublicKeyApiJob.setCsr (QByteArray& csr) {
    QByteArray data = "csr=";
    data += QUrl.toPercentEncoding (csr);
    _csr.setData (data);
}

void SignPublicKeyApiJob.start () {
    QNetworkRequest req;
    req.setRawHeader ("OCS-APIREQUEST", "true");
    req.setHeader (QNetworkRequest.ContentTypeHeader, QByteArrayLiteral ("application/x-www-form-urlencoded"));
    QUrlQuery query;
    query.addQueryItem (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concatUrlPath (account ().url (), path ());
    url.setQuery (query);

    qCInfo (lcSignPublicKeyApiJob) << "Sending the CSR" << _csr.data ();
    sendRequest ("POST", url, req, &_csr);
    AbstractNetworkJob.start ();
}

bool SignPublicKeyApiJob.finished () {
    qCInfo (lcStorePrivateKeyApiJob ()) << "Sending CSR ended with"  << path () << errorString () << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute);

    QJsonParseError error;
    auto json = QJsonDocument.fromJson (reply ().readAll (), &error);
    emit jsonReceived (json, reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ());
    return true;
}

}
