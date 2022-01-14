

// #include <string>
// #include <QJsonDocument>
// #include <QDebug>
// #include <QLoggingCategory>
// #include <QFileInfo>
// #include <QDir>
// #include <QJsonObject>
// #include <QXmlStreamReader>
// #include <QXml_stream_namespace_declaration>
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
_job = new Sign_publi
_job.set_csr ( csr
connect (_job.
_job.start
\encode

@ingroup libsync
***********************************************************/
class Sign_public_key_api_job : AbstractNetworkJob {
public:
    Sign_public_key_api_job (AccountPtr &account, string &path, GLib.Object *parent = nullptr);

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
@brief Job to upload the Private_key that return JSON

To be
\code
_job = new Store_private_key_api_jo
_job.set_private_key
connect (_job.
_job.start
\encode

@ingroup libsync
***********************************************************/
class Store_private_key_api_job : AbstractNetworkJob {
public:
    Store_private_key_api_job (AccountPtr &account, string &path, GLib.Object *parent = nullptr);

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
class Set_encryption_flag_api_job : AbstractNetworkJob {
public:
    enum Flag_action {
        Clear = 0,
        Set = 1
    };

    Set_encryption_flag_api_job (AccountPtr &account, QByteArray &file_id, Flag_action flag_action = Set, GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray &file_id);
    void error (QByteArray &file_id, int http_return_code);

private:
    QByteArray _file_id;
    Flag_action _flag_action = Set;
};

class Lock_encrypt_folder_api_job : AbstractNetworkJob {
public:
    Lock_encrypt_folder_api_job (AccountPtr &account, QByteArray& file_id, GLib.Object *parent = nullptr);

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

class Unlock_encrypt_folder_api_job : AbstractNetworkJob {
public:
    Unlock_encrypt_folder_api_job (
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

class Store_meta_data_api_job : AbstractNetworkJob {
public:
    Store_meta_data_api_job (
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

class Update_metadata_api_job : AbstractNetworkJob {
public:
    Update_metadata_api_job (
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

class Get_metadata_api_job : AbstractNetworkJob {
public:
    Get_metadata_api_job (
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

class Delete_metadata_api_job : AbstractNetworkJob {
public:
    Delete_metadata_api_job (
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



Get_metadata_api_job.Get_metadata_api_job (AccountPtr& account,
                                    const QByteArray& file_id,
                                    GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("meta-data/") + file_id, parent), _file_id (file_id) {
}

void Get_metadata_api_job.start () {
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

bool Get_metadata_api_job.finished () {
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

Store_meta_data_api_job.Store_meta_data_api_job (AccountPtr& account,
                                                 const QByteArray& file_id,
                                                 const QByteArray& b64Metadata,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("meta-data/") + file_id, parent), _file_id (file_id), _b64Metadata (b64Metadata) {
}

void Store_meta_data_api_job.start () {
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

bool Store_meta_data_api_job.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
		if (ret_code != 200) {
			q_c_info (lc_cse_job ()) << "error sending the metadata" << path () << error_string () << ret_code;
			emit error (_file_id, ret_code);
		}

		q_c_info (lc_cse_job ()) << "Metadata submited to the server successfully";
		emit success (_file_id);
    return true;
}

Update_metadata_api_job.Update_metadata_api_job (AccountPtr& account,
                                                 const QByteArray& file_id,
                                                 const QByteArray& b64Metadata,
                                                 const QByteArray& token,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("meta-data/") + file_id, parent)
, _file_id (file_id),
_b64Metadata (b64Metadata),
_token (token) {
}

void Update_metadata_api_job.start () {
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

bool Update_metadata_api_job.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
		if (ret_code != 200) {
			q_c_info (lc_cse_job ()) << "error updating the metadata" << path () << error_string () << ret_code;
			emit error (_file_id, ret_code);
		}

		q_c_info (lc_cse_job ()) << "Metadata submited to the server successfully";
		emit success (_file_id);
    return true;
}

Unlock_encrypt_folder_api_job.Unlock_encrypt_folder_api_job (AccountPtr& account,
                                                 const QByteArray& file_id,
                                                 const QByteArray& token,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("lock/") + file_id, parent), _file_id (file_id), _token (token) {
}

void Unlock_encrypt_folder_api_job.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    req.set_raw_header ("e2e-token", _token);

    QUrl url = Utility.concat_url_path (account ().url (), path ());
    send_request ("DELETE", url, req);

    AbstractNetworkJob.start ();
    q_c_info (lc_cse_job ()) << "Starting the request to unlock.";
}

bool Unlock_encrypt_folder_api_job.finished () {
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

Delete_metadata_api_job.Delete_metadata_api_job (AccountPtr& account,
                                                  const QByteArray& file_id,
                                                 GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("meta-data/") + file_id, parent), _file_id (file_id) {
}

void Delete_metadata_api_job.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");

    QUrl url = Utility.concat_url_path (account ().url (), path ());
    send_request ("DELETE", url, req);

    AbstractNetworkJob.start ();
    q_c_info (lc_cse_job ()) << "Starting the request to remove the metadata.";
}

bool Delete_metadata_api_job.finished () {
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

Lock_encrypt_folder_api_job.Lock_encrypt_folder_api_job (AccountPtr& account, QByteArray& file_id, GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("lock/") + file_id, parent), _file_id (file_id) {
}

void Lock_encrypt_folder_api_job.start () {
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

bool Lock_encrypt_folder_api_job.finished () {
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

Set_encryption_flag_api_job.Set_encryption_flag_api_job (AccountPtr& account, QByteArray& file_id, Flag_action flag_action, GLib.Object* parent)
 : AbstractNetworkJob (account, e2ee_base_url () + QStringLiteral ("encrypted/") + file_id, parent), _file_id (file_id), _flag_action (flag_action) {
}

void Set_encryption_flag_api_job.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    QUrl url = Utility.concat_url_path (account ().url (), path ());

    q_c_info (lc_cse_job ()) << "marking the file with id" << _file_id << "as" << (_flag_action == Set ? "encrypted" : "non-encrypted") << ".";

    send_request (_flag_action == Set ? "PUT" : "DELETE", url, req);

    AbstractNetworkJob.start ();
}

bool Set_encryption_flag_api_job.finished () {
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

Store_private_key_api_job.Store_private_key_api_job (AccountPtr& account, string& path, GLib.Object* parent)
 : AbstractNetworkJob (account, path, parent) {
}

void Store_private_key_api_job.set_private_key (QByteArray& priv_key) {
    QByteArray data = "private_key=";
    data += QUrl.to_percent_encoding (priv_key);
    _priv_key.set_data (data);
}

void Store_private_key_api_job.start () {
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

bool Store_private_key_api_job.finished () {
    int ret_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (ret_code != 200)
        q_c_info (lc_store_private_key_api_job ()) << "Sending private key ended with"  << path () << error_string () << ret_code;

    QJsonParseError error;
    auto json = QJsonDocument.from_json (reply ().read_all (), &error);
    emit json_received (json, reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ());
    return true;
}

Sign_public_key_api_job.Sign_public_key_api_job (AccountPtr& account, string& path, GLib.Object* parent)
 : AbstractNetworkJob (account, path, parent) {
}

void Sign_public_key_api_job.set_csr (QByteArray& csr) {
    QByteArray data = "csr=";
    data += QUrl.to_percent_encoding (csr);
    _csr.set_data (data);
}

void Sign_public_key_api_job.start () {
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

bool Sign_public_key_api_job.finished () {
    q_c_info (lc_store_private_key_api_job ()) << "Sending CSR ended with"  << path () << error_string () << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute);

    QJsonParseError error;
    auto json = QJsonDocument.from_json (reply ().read_all (), &error);
    emit json_received (json, reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ());
    return true;
}

}
