

// #include <string>
// #include <QJsonDocument>
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

namespace Occ {
/* Here are all of the network jobs for the client side encryption.
anything that goes thru the server and expects a response, is here.
***********************************************************/

/***********************************************************
@brief Job to sigh the CSR that return JSON

To be
\code
_job = new SignPubli
_job.set_csr ( csr
connect (_job.
_job.start
\encode

@ingroup libsync
***********************************************************/
class SignPublicKeyApiJob : AbstractNetworkJob {
public:
    SignPublicKeyApiJob (AccountPtr &account, string &path, GLib.Object *parent = nullptr);

    /***********************************************************
    @brief set_csr - the CSR with the public key.
    This function needs to be called before start () obviously.
    ***********************************************************/
    void set_csr (QByteArray& csr);

public slots:
    void start () override;

protected:
    bool finished () override;
signals:

    /***********************************************************
    @brief json_received - signal to report the json answer from ocs
    @param json - the parsed json document
    @param status_code - the OCS status code : 100 (!) for success
    ***********************************************************/
    void json_received (QJsonDocument &json, int status_code);

private:
    QBuffer _csr;
};

/***********************************************************
@brief Job to upload the PrivateKey that return JSON

To be
\code
_job = new StorePrivateKeyApiJob
_job.set_private_key
connect (_job.
_job.start
\encode

@ingroup libsync
***********************************************************/
class StorePrivateKeyApiJob : AbstractNetworkJob {
public:
    StorePrivateKeyApiJob (AccountPtr &account, string &path, GLib.Object *parent = nullptr);

    /***********************************************************
    @brief set_csr - the CSR with the public key.
    This function needs to be called before start () obviously.
    ***********************************************************/
    void set_private_key (QByteArray& private_key);

public slots:
    void start () override;

protected:
    bool finished () override;
signals:

    /***********************************************************
    @brief json_received - signal to report the json answer from ocs
    @param json - the parsed json document
    @param status_code - the OCS status code : 100 (!) for success
    ***********************************************************/
    void json_received (QJsonDocument &json, int status_code);

private:
    QBuffer _priv_key;
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

    SetEncryptionFlagApiJob (AccountPtr &account, QByteArray &file_id, FlagAction flag_action = Set, GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray &file_id);
    void error (QByteArray &file_id, int http_return_code);

private:
    QByteArray _file_id;
    FlagAction _flag_action = Set;
};

class LockEncryptFolderApiJob : AbstractNetworkJob {
public:
    LockEncryptFolderApiJob (AccountPtr &account, QByteArray& file_id, GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& file_id, QByteArray& token);
    void error (QByteArray& file_id, int httpd_error_code);

private:
    QByteArray _file_id;
};

class UnlockEncryptFolderApiJob : AbstractNetworkJob {
public:
    UnlockEncryptFolderApiJob (
        const AccountPtr &account,
        const QByteArray& file_id,
        const QByteArray& token,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& file_id);
    void error (QByteArray& file_id, int http_return_code);

private:
    QByteArray _file_id;
    QByteArray _token;
    QBuffer *_token_buf;
};

class StoreMetaDataApiJob : AbstractNetworkJob {
public:
    StoreMetaDataApiJob (
        const AccountPtr &account,
        const QByteArray& file_id,
        const QByteArray& b64Metadata,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& file_id);
    void error (QByteArray& file_id, int http_return_code);

private:
    QByteArray _file_id;
    QByteArray _b64Metadata;
};

class UpdateMetadataApiJob : AbstractNetworkJob {
public:
    UpdateMetadataApiJob (
        const AccountPtr &account,
        const QByteArray& file_id,
        const QByteArray& b64Metadata,
        const QByteArray& locked_token,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& file_id);
    void error (QByteArray& file_id, int http_return_code);

private:
    QByteArray _file_id;
    QByteArray _b64Metadata;
    QByteArray _token;
};

class GetMetadataApiJob : AbstractNetworkJob {
public:
    GetMetadataApiJob (
        const AccountPtr &account,
        const QByteArray& file_id,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void json_received (QJsonDocument &json, int status_code);
    void error (QByteArray& file_id, int http_return_code);

private:
    QByteArray _file_id;
};

class DeleteMetadataApiJob : AbstractNetworkJob {
public:
    DeleteMetadataApiJob (
        const AccountPtr &account,
        const QByteArray& file_id,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& file_id);
    void error (QByteArray& file_id, int http_error_code);

private:
    QByteArray _file_id;
};



GetMetadataApiJob.GetMetadataApiJob (AccountPtr& account,
                                    const QByteArray& file_id,
                                    GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("meta-data/") + file_id, parent), _file_id (file_id) {
}

void GetMetadataApiJob.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    QUrlQuery query;
    query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concat_url_path (account ().url (), path ());
    url.set_query (query);

    q_c_info (lc_cse_job ()) << "Requesting the metadata for the file_id" << _file_id << "as encrypted";
    send_request ("GET", url, req);
    AbstractNetworkJob.start ();
}

bool GetMetadataApiJob.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (ret_code != 200) {
        q_c_info (lc_cse_job ()) << "error requesting the metadata" << path () << error_string () << ret_code;
        emit error (_file_id, ret_code);
        return true;
    }
    QJsonParseError error;
    auto json = QJsonDocument.from_json (reply ().read_all (), &error);
    emit json_received (json, reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ());
    return true;
}

StoreMetaDataApiJob.StoreMetaDataApiJob (AccountPtr& account,
                                                 const QByteArray& file_id,
                                                 const QByteArray& b64Metadata,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("meta-data/") + file_id, parent), _file_id (file_id), _b64Metadata (b64Metadata) {
}

void StoreMetaDataApiJob.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    req.set_header (QNetworkRequest.ContentTypeHeader, QByteArrayLiteral ("application/x-www-form-urlencoded"));
    QUrlQuery query;
    query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concat_url_path (account ().url (), path ());
    url.set_query (query);

    QByteArray data = QByteArray ("meta_data=") + QUrl.to_percent_encoding (_b64Metadata);
    auto buffer = new QBuffer (this);
    buffer.set_data (data);

    q_c_info (lc_cse_job ()) << "sending the metadata for the file_id" << _file_id << "as encrypted";
    send_request ("POST", url, req, buffer);
    AbstractNetworkJob.start ();
}

bool StoreMetaDataApiJob.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
		if (ret_code != 200) {
			q_c_info (lc_cse_job ()) << "error sending the metadata" << path () << error_string () << ret_code;
			emit error (_file_id, ret_code);
		}

		q_c_info (lc_cse_job ()) << "Metadata submited to the server successfully";
		emit success (_file_id);
    return true;
}

UpdateMetadataApiJob.UpdateMetadataApiJob (AccountPtr& account,
                                                 const QByteArray& file_id,
                                                 const QByteArray& b64Metadata,
                                                 const QByteArray& token,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("meta-data/") + file_id, parent)
, _file_id (file_id),
_b64Metadata (b64Metadata),
_token (token) {
}

void UpdateMetadataApiJob.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    req.set_header (QNetworkRequest.ContentTypeHeader, QByteArrayLiteral ("application/x-www-form-urlencoded"));

    QUrlQuery url_query;
    url_query.add_query_item (QStringLiteral ("format"), QStringLiteral ("json"));
    url_query.add_query_item (QStringLiteral ("e2e-token"), _token);

    QUrl url = Utility.concat_url_path (account ().url (), path ());
    url.set_query (url_query);

    QUrlQuery params;
    params.add_query_item ("meta_data",QUrl.to_percent_encoding (_b64Metadata));
    params.add_query_item ("e2e-token", _token);

    QByteArray data = params.query ().to_local8Bit ();
    auto buffer = new QBuffer (this);
    buffer.set_data (data);

    q_c_info (lc_cse_job ()) << "updating the metadata for the file_id" << _file_id << "as encrypted";
    send_request ("PUT", url, req, buffer);
    AbstractNetworkJob.start ();
}

bool UpdateMetadataApiJob.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
		if (ret_code != 200) {
			q_c_info (lc_cse_job ()) << "error updating the metadata" << path () << error_string () << ret_code;
			emit error (_file_id, ret_code);
		}

		q_c_info (lc_cse_job ()) << "Metadata submited to the server successfully";
		emit success (_file_id);
    return true;
}

UnlockEncryptFolderApiJob.UnlockEncryptFolderApiJob (AccountPtr& account,
                                                 const QByteArray& file_id,
                                                 const QByteArray& token,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("lock/") + file_id, parent), _file_id (file_id), _token (token) {
}

void UnlockEncryptFolderApiJob.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    req.set_raw_header ("e2e-token", _token);

    QUrl url = Utility.concat_url_path (account ().url (), path ());
    send_request ("DELETE", url, req);

    AbstractNetworkJob.start ();
    q_c_info (lc_cse_job ()) << "Starting the request to unlock.";
}

bool UnlockEncryptFolderApiJob.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (ret_code != 200) {
        q_c_info (lc_cse_job ()) << "error unlocking file" << path () << error_string () << ret_code;
        q_c_info (lc_cse_job ()) << "Full Error Log" << reply ().read_all ();
        emit error (_file_id, ret_code);
        return true;
    }
    emit success (_file_id);
    return true;
}

DeleteMetadataApiJob.DeleteMetadataApiJob (AccountPtr& account,
                                                  const QByteArray& file_id,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("meta-data/") + file_id, parent), _file_id (file_id) {
}

void DeleteMetadataApiJob.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");

    QUrl url = Utility.concat_url_path (account ().url (), path ());
    send_request ("DELETE", url, req);

    AbstractNetworkJob.start ();
    q_c_info (lc_cse_job ()) << "Starting the request to remove the metadata.";
}

bool DeleteMetadataApiJob.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (ret_code != 200) {
        q_c_info (lc_cse_job ()) << "error removing metadata for" << path () << error_string () << ret_code;
        q_c_info (lc_cse_job ()) << "Full Error Log" << reply ().read_all ();
        emit error (_file_id, ret_code);
        return true;
    }
    emit success (_file_id);
    return true;
}

LockEncryptFolderApiJob.LockEncryptFolderApiJob (AccountPtr& account, QByteArray& file_id, GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("lock/") + file_id, parent), _file_id (file_id) {
}

void LockEncryptFolderApiJob.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    QUrlQuery query;
    query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concat_url_path (account ().url (), path ());
    url.set_query (query);

    q_c_info (lc_cse_job ()) << "locking the folder with id" << _file_id << "as encrypted";
    send_request ("POST", url, req);
    AbstractNetworkJob.start ();
}

bool LockEncryptFolderApiJob.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (ret_code != 200) {
        q_c_info (lc_cse_job ()) << "error locking file" << path () << error_string () << ret_code;
        emit error (_file_id, ret_code);
        return true;
    }

    QJsonParseError error;
    auto json = QJsonDocument.from_json (reply ().read_all (), &error);
    auto obj = json.object ().to_variant_map ();
    auto token = obj["ocs"].to_map ()["data"].to_map ()["e2e-token"].to_byte_array ();
    q_c_info (lc_cse_job ()) << "got json:" << token;

    //TODO : Parse the token and submit.
    emit success (_file_id, token);
    return true;
}

SetEncryptionFlagApiJob.SetEncryptionFlagApiJob (AccountPtr& account, QByteArray& file_id, FlagAction flag_action, GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("encrypted/") + file_id, parent), _file_id (file_id), _flag_action (flag_action) {
}

void SetEncryptionFlagApiJob.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    QUrl url = Utility.concat_url_path (account ().url (), path ());

    q_c_info (lc_cse_job ()) << "marking the file with id" << _file_id << "as" << (_flag_action == Set ? "encrypted" : "non-encrypted") << ".";

    send_request (_flag_action == Set ? "PUT" : "DELETE", url, req);

    AbstractNetworkJob.start ();
}

bool SetEncryptionFlagApiJob.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    q_c_info (lc_cse_job ()) << "Encryption Flag Return" << reply ().read_all ();
    if (ret_code == 200) {
        emit success (_file_id);
    } else {
        q_c_info (lc_cse_job ()) << "Setting the encrypted flag failed with" << path () << error_string () << ret_code;
        emit error (_file_id, ret_code);
    }
    return true;
}

StorePrivateKeyApiJob.StorePrivateKeyApiJob (AccountPtr& account, string& path, GLib.Object* parent)
 : AbstractNetworkJob (account, path, parent) {
}

void StorePrivateKeyApiJob.set_private_key (QByteArray& priv_key) {
    QByteArray data = "private_key=";
    data += QUrl.to_percent_encoding (priv_key);
    _priv_key.set_data (data);
}

void StorePrivateKeyApiJob.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    QUrlQuery query;
    query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concat_url_path (account ().url (), path ());
    url.set_query (query);

    q_c_info (lc_store_private_key_api_job) << "Sending the private key" << _priv_key.data ();
    send_request ("POST", url, req, &_priv_key);
    AbstractNetworkJob.start ();
}

bool StorePrivateKeyApiJob.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (ret_code != 200)
        q_c_info (lc_store_private_key_api_job ()) << "Sending private key ended with"  << path () << error_string () << ret_code;

    QJsonParseError error;
    auto json = QJsonDocument.from_json (reply ().read_all (), &error);
    emit json_received (json, reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ());
    return true;
}

SignPublicKeyApiJob.SignPublicKeyApiJob (AccountPtr& account, string& path, GLib.Object* parent)
 : AbstractNetworkJob (account, path, parent) {
}

void SignPublicKeyApiJob.set_csr (QByteArray& csr) {
    QByteArray data = "csr=";
    data += QUrl.to_percent_encoding (csr);
    _csr.set_data (data);
}

void SignPublicKeyApiJob.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    req.set_header (QNetworkRequest.ContentTypeHeader, QByteArrayLiteral ("application/x-www-form-urlencoded"));
    QUrlQuery query;
    query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concat_url_path (account ().url (), path ());
    url.set_query (query);

    q_c_info (lc_sign_public_key_api_job) << "Sending the CSR" << _csr.data ();
    send_request ("POST", url, req, &_csr);
    AbstractNetworkJob.start ();
}

bool SignPublicKeyApiJob.finished () {
    q_c_info (lc_store_private_key_api_job ()) << "Sending CSR ended with"  << path () << error_string () << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute);

    QJsonParseError error;
    auto json = QJsonDocument.from_json (reply ().read_all (), &error);
    emit json_received (json, reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ());
    return true;
}

}
