/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QJsonDocument>
// #include <QLoggingCategory>
// #include <QNetworkRequest>
// #include <QNetworkAccessManager>
// #include <QNetworkReply>
// #include <QNetworkRequest>
// #include <QSslConfiguration>
// #include <QSsl_cipher>
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
// #include <QPainter_path>
#endif

// #include <QBuffer>
// #include <QUrlQuery>
// #include <QJsonDocument>
// #include <functional>


namespace Occ {

/***********************************************************
Strips quotes and gzip annotations */
QByteArray parse_etag (char *header);

struct Http_error {
    int code; // HTTP error code
    string message;
};

template <typename T>
using Http_result = Result<T, Http_error>;

/***********************************************************
@brief The Entity_exists_job class
@ingroup libsync
***********************************************************/
class Entity_exists_job : AbstractNetworkJob {
public:
    Entity_exists_job (AccountPtr account, string &path, GLib.Object *parent = nullptr);
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
class Delete_api_job : AbstractNetworkJob {
public:
    Delete_api_job (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    void start () override;

signals:
    void result (int http_code);

private slots:
    bool finished () override;
};

struct Extra_folder_info {
    QByteArray file_id;
    int64 size = -1;
};

/***********************************************************
@brief The Ls_col_job class
@ingroup libsync
***********************************************************/
class Ls_col_xMLParser : GLib.Object {
public:
    Ls_col_xMLParser ();

    bool parse (QByteArray &xml,
               QHash<string, Extra_folder_info> *sizes,
               const string &expected_path);

signals:
    void directory_listing_subfolders (QStringList &items);
    void directory_listing_iterated (string &name, QMap<string, string> &properties);
    void finished_with_error (QNetworkReply *reply);
    void finished_without_error ();
};

class Ls_col_job : AbstractNetworkJob {
public:
    Ls_col_job (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    Ls_col_job (AccountPtr account, QUrl &url, GLib.Object *parent = nullptr);
    void start () override;
    QHash<string, Extra_folder_info> _folder_infos;

    /***********************************************************
    Used to specify which properties shall be retrieved.
    
    The properties can
     - contain no colon : they refer to a property in the DAV : 
     - contain a colon : and thus specify an explicit namespace,
       e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
    ***********************************************************/
    void set_properties (QList<QByteArray> properties);
    QList<QByteArray> properties ();

signals:
    void directory_listing_subfolders (QStringList &items);
    void directory_listing_iterated (string &name, QMap<string, string> &properties);
    void finished_with_error (QNetworkReply *reply);
    void finished_without_error ();

private slots:
    bool finished () override;

private:
    QList<QByteArray> _properties;
    QUrl _url; // Used instead of path () if the url is specified in the constructor
};

/***********************************************************
@brief The PropfindJob class

Setting the desired properties with set_properties

Note that this job is only for querying one item.
There is also the Ls_col_job which can be used to list collections

@ingroup libsync
***********************************************************/
class PropfindJob : AbstractNetworkJob {
public:
    PropfindJob (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    void start () override;

    /***********************************************************
    Used to specify which properties shall be retrieved.
    
    The properties can
     - contain no colon : they refer to a property in the DAV : 
     - contain a colon : and thus specify an explicit namespace,
       e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
    ***********************************************************/
    void set_properties (QList<QByteArray> properties);
    QList<QByteArray> properties ();

signals:
    void result (QVariantMap &values);
    void finished_with_error (QNetworkReply *reply = nullptr);

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
class Avatar_job : AbstractNetworkJob {
public:
    /***********************************************************
    @param user_id The user for which to obtain the avatar
    @param size The size of the avatar (square so size*size)
    ***********************************************************/
    Avatar_job (AccountPtr account, string &user_id, int size, GLib.Object *parent = nullptr);

    void start () override;

    /***********************************************************
    The retrieved avatar images don't have the circle shape by default */
    static QImage make_circular_avatar (QImage &base_avatar);

signals:
    /***********************************************************
    @brief avatar_pixmap - returns either a valid pixmap or not.
    ***********************************************************/

    void avatar_pixmap (QImage &);

private slots:
    bool finished () override;

private:
    QUrl _avatar_url;
};
#endif

/***********************************************************
@brief Send a Proppatch request

Setting the desired p

WARNING : Untested!

@ingroup libsync
***********************************************************/
class Proppatch_job : AbstractNetworkJob {
public:
    Proppatch_job (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    void start () override;

    /***********************************************************
    Used to specify which properties shall be set.
    
    The property keys can
     - contain no colon : they refer to a property in the DAV : 
     - contain a colon : and thus specify an explicit namespace,
       e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
    ***********************************************************/
    void set_properties (QMap<QByteArray, QByteArray> properties);
    QMap<QByteArray, QByteArray> properties ();

signals:
    void success ();
    void finished_with_error ();

private slots:
    bool finished () override;

private:
    QMap<QByteArray, QByteArray> _properties;
};

/***********************************************************
@brief The Mk_col_job class
@ingroup libsync
***********************************************************/
class Mk_col_job : AbstractNetworkJob {
    QUrl _url; // Only used if the constructor taking a url is taken.
    QMap<QByteArray, QByteArray> _extra_headers;

public:
    Mk_col_job (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    Mk_col_job (AccountPtr account, string &path, QMap<QByteArray, QByteArray> &extra_headers, GLib.Object *parent = nullptr);
    Mk_col_job (AccountPtr account, QUrl &url,
        const QMap<QByteArray, QByteArray> &extra_headers, GLib.Object *parent = nullptr);
    void start () override;

signals:
    void finished_with_error (QNetworkReply *reply);
    void finished_without_error ();

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
    static string version_string (QJsonObject &info);
    static bool installed (QJsonObject &info);

signals:
    /***********************************************************
    Emitted when a status.php was successfully read.

    \a url see _server_status_url (does not include "/status.php")
    \a info The status.php reply information
    ***********************************************************/
    void instance_found (QUrl &url, QJsonObject &info);

    /***********************************************************
    Emitted on invalid status.php reply.

    \a reply is never null
    ***********************************************************/
    void instance_not_found (QNetworkReply *reply);

    /***********************************************************
    A timeout occurred.

    \a url The specific url where the timeout happened.
    ***********************************************************/
    void timeout (QUrl &url);

private:
    bool finished () override;
    void on_timed_out () override;
private slots:
    virtual void meta_data_changed_slot ();
    virtual void encrypted_slot ();
    void slot_redirected (QNetworkReply *reply, QUrl &target_url, int redirect_count);

private:
    bool _subdir_fallback;

    /***********************************************************
    The permanent-redirect adjusted account url.

    Note that temporary redirects or a permanent redirect behind a temporary
    one do not affect this url.
    ***********************************************************/
    QUrl _server_url;

    /***********************************************************
    Keep track of how many permanent redirect were applied. */
    int _permanent_redirects;
};

/***********************************************************
@brief The Request_etag_job class
***********************************************************/
class Request_etag_job : AbstractNetworkJob {
public:
    Request_etag_job (AccountPtr account, string &path, GLib.Object *parent = nullptr);
    void start () override;

signals:
    void etag_retrieved (QByteArray &etag, QDateTime &time);
    void finished_with_result (Http_result<QByteArray> &etag);

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
    @brief add_query_params - add more parameters to the ocs call
    @param params : list pairs of strings containing the parameter name and the value.
    
    All parameters from the passed list are appended to the query. Not
    that the format=json para
    need to be set this way.

    This function needs to be called before start () obviously.
    ***********************************************************/
    void add_query_params (QUrlQuery &params);
    void add_raw_header (QByteArray &header_name, QByteArray &value);

    void set_body (QJsonDocument &body);

    void set_verb (Verb value);

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

    /***********************************************************
    @brief etag_response_header_received - signal to report the ETag response header value
    from ocs api v2
    @param value - the ETag response header value
    @param status_code - the OCS status code : 100 (!) for success
    ***********************************************************/
    void etag_response_header_received (QByteArray &value, int status_code);

    /***********************************************************
    @brief desktop_notification_status_received - signal to report if notifications are allowed
    @param status - set desktop notifications allowed status
    ***********************************************************/
    void allow_desktop_notifications_changed (bool is_allowed);

private:
    QByteArray _body;
    QUrlQuery _additional_params;
    QNetworkRequest _request;

    Verb _verb = Verb.Get;

    QByteArray verb_to_string ();
};

/***********************************************************
@brief Checks with auth type to use for a server
@ingroup libsync
***********************************************************/
class DetermineAuthTypeJob : GLib.Object {
public:
    enum AuthType {
        No_auth_type, // used only before we got a chance to probe the server
#ifdef WITH_WEBENGINE
        Web_view_flow,
#endif // WITH_WEBENGINE
        Basic, // also the catch-all fallback for backwards compatibility reasons
        OAuth,
        Login_flow_v2
    };
    Q_ENUM (AuthType)

    DetermineAuthTypeJob (AccountPtr account, GLib.Object *parent = nullptr);
    void start ();
signals:
    void auth_type (AuthType);

private:
    void check_all_done ();

    AccountPtr _account;
    AuthType _result_get = No_auth_type;
    AuthType _result_propfind = No_auth_type;
    AuthType _result_old_flow = No_auth_type;
    bool _get_done = false;
    bool _propfind_done = false;
    bool _old_flow_done = false;
};

/***********************************************************
@brief A basic job around a network request without extra funtionality
@ingroup libsync

Primarily adds timeout and redirection handling.
***********************************************************/
class SimpleNetworkJob : AbstractNetworkJob {
public:
    SimpleNetworkJob (AccountPtr account, GLib.Object *parent = nullptr);

    QNetworkReply *start_request (QByteArray &verb, QUrl &url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice *request_body = nullptr);

signals:
    void finished_signal (QNetworkReply *reply);
private slots:
    bool finished () override;
};

/***********************************************************
@brief Runs a PROPFIND to figure out the private link url

The numeric_file_id is used only to build the deprecated_private_link_url
locally as a fallback. If it's empty an
will be called with an empty string.

The job and signal connections are parented to the target GLib.Object.

Note : target_fun is guaranteed to be called only through the event
loop and never directly.
***********************************************************/
void fetch_private_link_url (
    AccountPtr account, string &remote_path,
    const QByteArray &numeric_file_id, GLib.Object *target,
    std.function<void (string &url)> target_fun);



const int not_modified_status_code = 304;

QByteArray parse_etag (char *header) {
    if (!header)
        return QByteArray ();
    QByteArray arr = header;

    // Weak E-Tags can appear when gzip compression is on, see #3946
    if (arr.starts_with ("W/"))
        arr = arr.mid (2);

    // https://github.com/owncloud/client/issues/1195
    arr.replace ("-gzip", "");

    if (arr.length () >= 2 && arr.starts_with ('"') && arr.ends_with ('"')) {
        arr = arr.mid (1, arr.length () - 2);
    }
    return arr;
}

Request_etag_job.Request_etag_job (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

void Request_etag_job.start () {
    QNetworkRequest req;
    req.set_raw_header ("Depth", "0");

    QByteArray xml ("<?xml version=\"1.0\" ?>\n"
                   "<d:propfind xmlns:d=\"DAV:\">\n"
                   "  <d:prop>\n"
                   "    <d:getetag/>\n"
                   "  </d:prop>\n"
                   "</d:propfind>\n");
    auto *buf = new QBuffer (this);
    buf.set_data (xml);
    buf.open (QIODevice.Read_only);
    // assumes ownership
    send_request ("PROPFIND", make_dav_url (path ()), req, buf);

    if (reply ().error () != QNetworkReply.NoError) {
        q_c_warning (lc_etag_job) << "request network error : " << reply ().error_string ();
    }
    AbstractNetworkJob.start ();
}

bool Request_etag_job.finished () {
    q_c_info (lc_etag_job) << "Request Etag of" << reply ().request ().url () << "FINISHED WITH STATUS"
                      <<  reply_status_string ();

    auto http_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (http_code == 207) {
        // Parse DAV response
        QXmlStreamReader reader (reply ());
        reader.add_extra_namespace_declaration (QXml_stream_namespace_declaration (QStringLiteral ("d"), QStringLiteral ("DAV:")));
        QByteArray etag;
        while (!reader.at_end ()) {
            QXmlStreamReader.Token_type type = reader.read_next ();
            if (type == QXmlStreamReader.Start_element && reader.namespace_uri () == QLatin1String ("DAV:")) {
                string name = reader.name ().to_string ();
                if (name == QLatin1String ("getetag")) {
                    auto etag_text = reader.read_element_text ();
                    auto parsed_tag = parse_etag (etag_text.to_utf8 ());
                    if (!parsed_tag.is_empty ()) {
                        etag += parsed_tag;
                    } else {
                        etag += etag_text.to_utf8 ();
                    }
                }
            }
        }
        emit etag_retrieved (etag, QDateTime.from_string (string.from_utf8 (_response_timestamp), Qt.RFC2822Date));
        emit finished_with_result (etag);
    } else {
        emit finished_with_result (Http_error{ http_code, error_string () });
    }
    return true;
}

/****************************************************************************/

Mk_col_job.Mk_col_job (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

Mk_col_job.Mk_col_job (AccountPtr account, string &path, QMap<QByteArray, QByteArray> &extra_headers, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent)
    , _extra_headers (extra_headers) {
}

Mk_col_job.Mk_col_job (AccountPtr account, QUrl &url,
    const QMap<QByteArray, QByteArray> &extra_headers, GLib.Object *parent)
    : AbstractNetworkJob (account, string (), parent)
    , _url (url)
    , _extra_headers (extra_headers) {
}

void Mk_col_job.start () {
    // add 'Content-Length : 0' header (see https://github.com/owncloud/client/issues/3256)
    QNetworkRequest req;
    req.set_raw_header ("Content-Length", "0");
    for (auto it = _extra_headers.const_begin (); it != _extra_headers.const_end (); ++it) {
        req.set_raw_header (it.key (), it.value ());
    }

    // assumes ownership
    if (_url.is_valid ()) {
        send_request ("MKCOL", _url, req);
    } else {
        send_request ("MKCOL", make_dav_url (path ()), req);
    }
    AbstractNetworkJob.start ();
}

bool Mk_col_job.finished () {
    q_c_info (lc_mk_col_job) << "MKCOL of" << reply ().request ().url () << "FINISHED WITH STATUS"
                       << reply_status_string ();

    if (reply ().error () != QNetworkReply.NoError) {
        Q_EMIT finished_with_error (reply ());
    } else {
        Q_EMIT finished_without_error ();
    }
    return true;
}

/****************************************************************************/
// supposed to read <D:collection> when pointing to <D:resourcetype><D:collection></D:resourcetype>..
static string read_contents_as_string (QXmlStreamReader &reader) {
    string result;
    int level = 0;
    do {
        QXmlStreamReader.Token_type type = reader.read_next ();
        if (type == QXmlStreamReader.Start_element) {
            level++;
            result += "<" + reader.name ().to_string () + ">";
        } else if (type == QXmlStreamReader.Characters) {
            result += reader.text ();
        } else if (type == QXmlStreamReader.End_element) {
            level--;
            if (level < 0) {
                break;
            }
            result += "</" + reader.name ().to_string () + ">";
        }

    } while (!reader.at_end ());
    return result;
}

Ls_col_xMLParser.Ls_col_xMLParser () = default;

bool Ls_col_xMLParser.parse (QByteArray &xml, QHash<string, Extra_folder_info> *file_info, string &expected_path) {
    // Parse DAV response
    QXmlStreamReader reader (xml);
    reader.add_extra_namespace_declaration (QXml_stream_namespace_declaration ("d", "DAV:"));

    QStringList folders;
    string current_href;
    QMap<string, string> current_tmp_properties;
    QMap<string, string> current_http200Properties;
    bool current_props_have_http200 = false;
    bool inside_propstat = false;
    bool inside_prop = false;
    bool inside_multi_status = false;

    while (!reader.at_end ()) {
        QXmlStreamReader.Token_type type = reader.read_next ();
        string name = reader.name ().to_string ();
        // Start elements with DAV:
        if (type == QXmlStreamReader.Start_element && reader.namespace_uri () == QLatin1String ("DAV:")) {
            if (name == QLatin1String ("href")) {
                // We don't use URL encoding in our request URL (which is the expected path) (QNAM will do it for us)
                // but the result will have URL encoding..
                string href_string = QUrl.from_local_file (QUrl.from_percent_encoding (reader.read_element_text ().to_utf8 ()))
                        .adjusted (QUrl.Normalize_path_segments)
                        .path ();
                if (!href_string.starts_with (expected_path)) {
                    q_c_warning (lc_ls_col_job) << "Invalid href" << href_string << "expected starting with" << expected_path;
                    return false;
                }
                current_href = href_string;
            } else if (name == QLatin1String ("response")) {
            } else if (name == QLatin1String ("propstat")) {
                inside_propstat = true;
            } else if (name == QLatin1String ("status") && inside_propstat) {
                string http_status = reader.read_element_text ();
                if (http_status.starts_with ("HTTP/1.1 200")) {
                    current_props_have_http200 = true;
                } else {
                    current_props_have_http200 = false;
                }
            } else if (name == QLatin1String ("prop")) {
                inside_prop = true;
                continue;
            } else if (name == QLatin1String ("multistatus")) {
                inside_multi_status = true;
                continue;
            }
        }

        if (type == QXmlStreamReader.Start_element && inside_propstat && inside_prop) {
            // All those elements are properties
            string property_content = read_contents_as_string (reader);
            if (name == QLatin1String ("resourcetype") && property_content.contains ("collection")) {
                folders.append (current_href);
            } else if (name == QLatin1String ("size")) {
                bool ok = false;
                auto s = property_content.to_long_long (&ok);
                if (ok && file_info) {
                    (*file_info)[current_href].size = s;
                }
            } else if (name == QLatin1String ("fileid")) {
                (*file_info)[current_href].file_id = property_content.to_utf8 ();
            }
            current_tmp_properties.insert (reader.name ().to_string (), property_content);
        }

        // End elements with DAV:
        if (type == QXmlStreamReader.End_element) {
            if (reader.namespace_uri () == QLatin1String ("DAV:")) {
                if (reader.name () == "response") {
                    if (current_href.ends_with ('/')) {
                        current_href.chop (1);
                    }
                    emit directory_listing_iterated (current_href, current_http200Properties);
                    current_href.clear ();
                    current_http200Properties.clear ();
                } else if (reader.name () == "propstat") {
                    inside_propstat = false;
                    if (current_props_have_http200) {
                        current_http200Properties = QMap<string, string> (current_tmp_properties);
                    }
                    current_tmp_properties.clear ();
                    current_props_have_http200 = false;
                } else if (reader.name () == "prop") {
                    inside_prop = false;
                }
            }
        }
    }

    if (reader.has_error ()) {
        // XML Parser error? Whatever had been emitted before will come as directory_listing_iterated
        q_c_warning (lc_ls_col_job) << "ERROR" << reader.error_string () << xml;
        return false;
    } else if (!inside_multi_status) {
        q_c_warning (lc_ls_col_job) << "ERROR no Web_dAV response?" << xml;
        return false;
    } else {
        emit directory_listing_subfolders (folders);
        emit finished_without_error ();
    }
    return true;
}

/****************************************************************************/

Ls_col_job.Ls_col_job (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

Ls_col_job.Ls_col_job (AccountPtr account, QUrl &url, GLib.Object *parent)
    : AbstractNetworkJob (account, string (), parent)
    , _url (url) {
}

void Ls_col_job.set_properties (QList<QByteArray> properties) {
    _properties = properties;
}

QList<QByteArray> Ls_col_job.properties () {
    return _properties;
}

void Ls_col_job.start () {
    QList<QByteArray> properties = _properties;

    if (properties.is_empty ()) {
        q_c_warning (lc_ls_col_job) << "Propfind with no properties!";
    }
    QByteArray prop_str;
    foreach (QByteArray &prop, properties) {
        if (prop.contains (':')) {
            int col_idx = prop.last_index_of (":");
            auto ns = prop.left (col_idx);
            if (ns == "http://owncloud.org/ns") {
                prop_str += "    <oc:" + prop.mid (col_idx + 1) + " />\n";
            } else {
                prop_str += "    <" + prop.mid (col_idx + 1) + " xmlns=\"" + ns + "\" />\n";
            }
        } else {
            prop_str += "    <d:" + prop + " />\n";
        }
    }

    QNetworkRequest req;
    req.set_raw_header ("Depth", "1");
    QByteArray xml ("<?xml version=\"1.0\" ?>\n"
                   "<d:propfind xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\">\n"
                   "  <d:prop>\n"
        + prop_str + "  </d:prop>\n"
                    "</d:propfind>\n");
    auto *buf = new QBuffer (this);
    buf.set_data (xml);
    buf.open (QIODevice.Read_only);
    if (_url.is_valid ()) {
        send_request ("PROPFIND", _url, req, buf);
    } else {
        send_request ("PROPFIND", make_dav_url (path ()), req, buf);
    }
    AbstractNetworkJob.start ();
}

// TODO : Instead of doing all in this slot, we should iteratively parse in ready_read (). This
// would allow us to be more asynchronous in processing while data is coming from the network,
// not all in one big blob at the end.
bool Ls_col_job.finished () {
    q_c_info (lc_ls_col_job) << "LSCOL of" << reply ().request ().url () << "FINISHED WITH STATUS"
                       << reply_status_string ();

    string content_type = reply ().header (QNetworkRequest.ContentTypeHeader).to_string ();
    int http_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (http_code == 207 && content_type.contains ("application/xml; charset=utf-8")) {
        Ls_col_xMLParser parser;
        connect (&parser, &Ls_col_xMLParser.directory_listing_subfolders,
            this, &Ls_col_job.directory_listing_subfolders);
        connect (&parser, &Ls_col_xMLParser.directory_listing_iterated,
            this, &Ls_col_job.directory_listing_iterated);
        connect (&parser, &Ls_col_xMLParser.finished_with_error,
            this, &Ls_col_job.finished_with_error);
        connect (&parser, &Ls_col_xMLParser.finished_without_error,
            this, &Ls_col_job.finished_without_error);

        string expected_path = reply ().request ().url ().path (); // something like "/owncloud/remote.php/dav/folder"
        if (!parser.parse (reply ().read_all (), &_folder_infos, expected_path)) {
            // XML parse error
            emit finished_with_error (reply ());
        }
    } else {
        // wrong content type, wrong HTTP code or any other network error
        emit finished_with_error (reply ());
    }

    return true;
}

/****************************************************************************/

namespace {
    const char statusphp_c[] = "status.php";
    const char nextcloud_dir_c[] = "nextcloud/";
}

CheckServerJob.CheckServerJob (AccountPtr account, GLib.Object *parent)
    : AbstractNetworkJob (account, QLatin1String (statusphp_c), parent)
    , _subdir_fallback (false)
    , _permanent_redirects (0) {
    set_ignore_credential_failure (true);
    connect (this, &AbstractNetworkJob.redirected,
        this, &CheckServerJob.slot_redirected);
}

void CheckServerJob.start () {
    _server_url = account ().url ();
    send_request ("GET", Utility.concat_url_path (_server_url, path ()));
    connect (reply (), &QNetworkReply.meta_data_changed, this, &CheckServerJob.meta_data_changed_slot);
    connect (reply (), &QNetworkReply.encrypted, this, &CheckServerJob.encrypted_slot);
    AbstractNetworkJob.start ();
}

void CheckServerJob.on_timed_out () {
    q_c_warning (lc_check_server_job) << "TIMEOUT";
    if (reply () && reply ().is_running ()) {
        emit timeout (reply ().url ());
    } else if (!reply ()) {
        q_c_warning (lc_check_server_job) << "Timeout even there was no reply?";
    }
    delete_later ();
}

string CheckServerJob.version (QJsonObject &info) {
    return info.value (QLatin1String ("version")).to_string ();
}

string CheckServerJob.version_string (QJsonObject &info) {
    return info.value (QLatin1String ("versionstring")).to_string ();
}

bool CheckServerJob.installed (QJsonObject &info) {
    return info.value (QLatin1String ("installed")).to_bool ();
}

static void merge_ssl_configuration_for_ssl_button (QSslConfiguration &config, AccountPtr account) {
    if (config.peer_certificate_chain ().length () > 0) {
        account._peer_certificate_chain = config.peer_certificate_chain ();
    }
    if (!config.session_cipher ().is_null ()) {
        account._session_cipher = config.session_cipher ();
    }
    if (config.session_ticket ().length () > 0) {
        account._session_ticket = config.session_ticket ();
    }
}

void CheckServerJob.encrypted_slot () {
    merge_ssl_configuration_for_ssl_button (reply ().ssl_configuration (), account ());
}

void CheckServerJob.slot_redirected (QNetworkReply *reply, QUrl &target_url, int redirect_count) {
    QByteArray slash_status_php ("/");
    slash_status_php.append (statusphp_c);

    int http_code = reply.attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    string path = target_url.path ();
    if ( (http_code == 301 || http_code == 308) // permanent redirection
        && redirect_count == _permanent_redirects // don't apply permanent redirects after a temporary one
        && path.ends_with (slash_status_php)) {
        _server_url = target_url;
        _server_url.set_path (path.left (path.size () - slash_status_php.size ()));
        q_c_info (lc_check_server_job) << "status.php was permanently redirected to"
                                 << target_url << "new server url is" << _server_url;
        ++_permanent_redirects;
    }
}

void CheckServerJob.meta_data_changed_slot () {
    account ().set_ssl_configuration (reply ().ssl_configuration ());
    merge_ssl_configuration_for_ssl_button (reply ().ssl_configuration (), account ());
}

bool CheckServerJob.finished () {
    if (reply ().request ().url ().scheme () == QLatin1String ("https")
        && reply ().ssl_configuration ().session_ticket ().is_empty ()
        && reply ().error () == QNetworkReply.NoError) {
        q_c_warning (lc_check_server_job) << "No SSL session identifier / session ticket is used, this might impact sync performance negatively.";
    }

    merge_ssl_configuration_for_ssl_button (reply ().ssl_configuration (), account ());

    // The server installs to /owncloud. Let's try that if the file wasn't found
    // at the original location
    if ( (reply ().error () == QNetworkReply.ContentNotFoundError) && (!_subdir_fallback)) {
        _subdir_fallback = true;
        set_path (QLatin1String (nextcloud_dir_c) + QLatin1String (statusphp_c));
        start ();
        q_c_info (lc_check_server_job) << "Retrying with" << reply ().url ();
        return false;
    }

    QByteArray body = reply ().peek (4 * 1024);
    int http_status = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (body.is_empty () || http_status != 200) {
        q_c_warning (lc_check_server_job) << "error : status.php replied " << http_status << body;
        emit instance_not_found (reply ());
    } else {
        QJsonParseError error;
        auto status = QJsonDocument.from_json (body, &error);
        // empty or invalid response
        if (error.error != QJsonParseError.NoError || status.is_null ()) {
            q_c_warning (lc_check_server_job) << "status.php from server is not valid JSON!" << body << reply ().request ().url () << error.error_string ();
        }

        q_c_info (lc_check_server_job) << "status.php returns : " << status << " " << reply ().error () << " Reply : " << reply ();
        if (status.object ().contains ("installed")) {
            emit instance_found (_server_url, status.object ());
        } else {
            q_c_warning (lc_check_server_job) << "No proper answer on " << reply ().url ();
            emit instance_not_found (reply ());
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

    if (properties.is_empty ()) {
        q_c_warning (lc_ls_col_job) << "Propfind with no properties!";
    }
    QNetworkRequest req;
    // Always have a higher priority than the propagator because we use this from the UI
    // and really want this to be done first (no matter what internal scheduling QNAM uses).
    // Also possibly useful for avoiding false timeouts.
    req.set_priority (QNetworkRequest.High_priority);
    req.set_raw_header ("Depth", "0");
    QByteArray prop_str;
    foreach (QByteArray &prop, properties) {
        if (prop.contains (':')) {
            int col_idx = prop.last_index_of (":");
            prop_str += "    <" + prop.mid (col_idx + 1) + " xmlns=\"" + prop.left (col_idx) + "\" />\n";
        } else {
            prop_str += "    <d:" + prop + " />\n";
        }
    }
    QByteArray xml = "<?xml version=\"1.0\" ?>\n"
                     "<d:propfind xmlns:d=\"DAV:\">\n"
                     "  <d:prop>\n"
        + prop_str + "  </d:prop>\n"
                    "</d:propfind>\n";

    auto *buf = new QBuffer (this);
    buf.set_data (xml);
    buf.open (QIODevice.Read_only);
    send_request ("PROPFIND", make_dav_url (path ()), req, buf);

    AbstractNetworkJob.start ();
}

void PropfindJob.set_properties (QList<QByteArray> properties) {
    _properties = properties;
}

QList<QByteArray> PropfindJob.properties () {
    return _properties;
}

bool PropfindJob.finished () {
    q_c_info (lc_propfind_job) << "PROPFIND of" << reply ().request ().url () << "FINISHED WITH STATUS"
                          << reply_status_string ();

    int http_result_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    if (http_result_code == 207) {
        // Parse DAV response
        QXmlStreamReader reader (reply ());
        reader.add_extra_namespace_declaration (QXml_stream_namespace_declaration ("d", "DAV:"));

        QVariantMap items;
        // introduced to nesting is ignored
        QStack<string> cur_element;

        while (!reader.at_end ()) {
            QXmlStreamReader.Token_type type = reader.read_next ();
            if (type == QXmlStreamReader.Start_element) {
                if (!cur_element.is_empty () && cur_element.top () == QLatin1String ("prop")) {
                    items.insert (reader.name ().to_string (), reader.read_element_text (QXmlStreamReader.Skip_child_elements));
                } else {
                    cur_element.push (reader.name ().to_string ());
                }
            }
            if (type == QXmlStreamReader.End_element) {
                if (cur_element.top () == reader.name ()) {
                    cur_element.pop ();
                }
            }
        }
        if (reader.has_error ()) {
            q_c_warning (lc_propfind_job) << "XML parser error : " << reader.error_string ();
            emit finished_with_error (reply ());
        } else {
            emit result (items);
        }
    } else {
        q_c_warning (lc_propfind_job) << "*not* successful, http result code is" << http_result_code
                                 << (http_result_code == 302 ? reply ().header (QNetworkRequest.Location_header).to_string () : QLatin1String (""));
        emit finished_with_error (reply ());
    }
    return true;
}

/****************************************************************************/

#ifndef TOKEN_AUTH_ONLY
Avatar_job.Avatar_job (AccountPtr account, string &user_id, int size, GLib.Object *parent)
    : AbstractNetworkJob (account, string (), parent) {
    if (account.server_version_int () >= Account.make_server_version (10, 0, 0)) {
        _avatar_url = Utility.concat_url_path (account.url (), string ("remote.php/dav/avatars/%1/%2.png").arg (user_id, string.number (size)));
    } else {
        _avatar_url = Utility.concat_url_path (account.url (), string ("index.php/avatar/%1/%2").arg (user_id, string.number (size)));
    }
}

void Avatar_job.start () {
    QNetworkRequest req;
    send_request ("GET", _avatar_url, req);
    AbstractNetworkJob.start ();
}

QImage Avatar_job.make_circular_avatar (QImage &base_avatar) {
    if (base_avatar.is_null ()) {
        return {};
    }

    int dim = base_avatar.width ();

    QImage avatar (dim, dim, QImage.Format_ARGB32);
    avatar.fill (Qt.transparent);

    QPainter painter (&avatar);
    painter.set_render_hint (QPainter.Antialiasing);

    QPainter_path path;
    path.add_ellipse (0, 0, dim, dim);
    painter.set_clip_path (path);

    painter.draw_image (0, 0, base_avatar);
    painter.end ();

    return avatar;
}

bool Avatar_job.finished () {
    int http_result_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    QImage av_image;

    if (http_result_code == 200) {
        QByteArray png_data = reply ().read_all ();
        if (png_data.size ()) {
            if (av_image.load_from_data (png_data)) {
                q_c_debug (lc_avatar_job) << "Retrieved Avatar pixmap!";
            }
        }
    }
    emit (avatar_pixmap (av_image));
    return true;
}
#endif

/****************************************************************************/

Proppatch_job.Proppatch_job (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

void Proppatch_job.start () {
    if (_properties.is_empty ()) {
        q_c_warning (lc_proppatch_job) << "Proppatch with no properties!";
    }
    QNetworkRequest req;

    QByteArray prop_str;
    QMapIterator<QByteArray, QByteArray> it (_properties);
    while (it.has_next ()) {
        it.next ();
        QByteArray key_name = it.key ();
        QByteArray key_ns;
        if (key_name.contains (':')) {
            int col_idx = key_name.last_index_of (":");
            key_ns = key_name.left (col_idx);
            key_name = key_name.mid (col_idx + 1);
        }

        prop_str += "    <" + key_name;
        if (!key_ns.is_empty ()) {
            prop_str += " xmlns=\"" + key_ns + "\" ";
        }
        prop_str += ">";
        prop_str += it.value ();
        prop_str += "</" + key_name + ">\n";
    }
    QByteArray xml = "<?xml version=\"1.0\" ?>\n"
                     "<d:propertyupdate xmlns:d=\"DAV:\">\n"
                     "  <d:set><d:prop>\n"
        + prop_str + "  </d:prop></d:set>\n"
                    "</d:propertyupdate>\n";

    auto *buf = new QBuffer (this);
    buf.set_data (xml);
    buf.open (QIODevice.Read_only);
    send_request ("PROPPATCH", make_dav_url (path ()), req, buf);
    AbstractNetworkJob.start ();
}

void Proppatch_job.set_properties (QMap<QByteArray, QByteArray> properties) {
    _properties = properties;
}

QMap<QByteArray, QByteArray> Proppatch_job.properties () {
    return _properties;
}

bool Proppatch_job.finished () {
    q_c_info (lc_proppatch_job) << "PROPPATCH of" << reply ().request ().url () << "FINISHED WITH STATUS"
                           << reply_status_string ();

    int http_result_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    if (http_result_code == 207) {
        emit success ();
    } else {
        q_c_warning (lc_proppatch_job) << "*not* successful, http result code is" << http_result_code
                                  << (http_result_code == 302 ? reply ().header (QNetworkRequest.Location_header).to_string () : QLatin1String (""));
        emit finished_with_error ();
    }
    return true;
}

/****************************************************************************/

Entity_exists_job.Entity_exists_job (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

void Entity_exists_job.start () {
    send_request ("HEAD", make_account_url (path ()));
    AbstractNetworkJob.start ();
}

bool Entity_exists_job.finished () {
    emit exists (reply ());
    return true;
}

/****************************************************************************/

JsonApiJob.JsonApiJob (AccountPtr &account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {
}

void JsonApiJob.add_query_params (QUrlQuery &params) {
    _additional_params = params;
}

void JsonApiJob.add_raw_header (QByteArray &header_name, QByteArray &value) {
   _request.set_raw_header (header_name, value);
}

void JsonApiJob.set_body (QJsonDocument &body) {
    _body = body.to_json ();
    q_c_debug (lc_json_api_job) << "Set body for request:" << _body;
    if (!_body.is_empty ()) {
        _request.set_header (QNetworkRequest.ContentTypeHeader, "application/json");
    }
}

void JsonApiJob.set_verb (Verb value) {
    _verb = value;
}

QByteArray JsonApiJob.verb_to_string () {
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
    add_raw_header ("OCS-APIREQUEST", "true");
    auto query = _additional_params;
    query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
    QUrl url = Utility.concat_url_path (account ().url (), path (), query);
    const auto http_verb = verb_to_string ();
    if (!_body.is_empty ()) {
        send_request (http_verb, url, _request, _body);
    } else {
        send_request (http_verb, url, _request);
    }
    AbstractNetworkJob.start ();
}

bool JsonApiJob.finished () {
    q_c_info (lc_json_api_job) << "JsonApiJob of" << reply ().request ().url () << "FINISHED WITH STATUS"
                         << reply_status_string ();

    int status_code = 0;
    int http_status_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (reply ().error () != QNetworkReply.NoError) {
        q_c_warning (lc_json_api_job) << "Network error : " << path () << error_string () << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute);
        status_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
        emit json_received (QJsonDocument (), status_code);
        return true;
    }

    string json_str = string.from_utf8 (reply ().read_all ());
    if (json_str.contains ("<?xml version=\"1.0\"?>")) {
        const QRegularExpression rex ("<statuscode> (\\d+)</statuscode>");
        const auto rex_match = rex.match (json_str);
        if (rex_match.has_match ()) {
            // this is a error message coming back from ocs.
            status_code = rex_match.captured (1).to_int ();
        }
    } else if (json_str.is_empty () && http_status_code == not_modified_status_code){
        q_c_warning (lc_json_api_job) << "Nothing changed so nothing to retrieve - status code : " << http_status_code;
        status_code = http_status_code;
    } else {
        const QRegularExpression rex (R" ("statuscode" : (\d+))");
        // example : "{"ocs":{"meta":{"status":"ok","statuscode":100,"message":null},"data":{"version":{"major":8,"minor":"... (504)
        const auto rx_match = rex.match (json_str);
        if (rx_match.has_match ()) {
            status_code = rx_match.captured (1).to_int ();
        }
    }

    // save new ETag value
    if (reply ().raw_header_list ().contains ("ETag"))
        emit etag_response_header_received (reply ().raw_header ("ETag"), status_code);

    const auto desktop_notifications_allowed = reply ().raw_header (QByteArray ("X-Nextcloud-User-Status"));
    if (!desktop_notifications_allowed.is_empty ()) {
        emit allow_desktop_notifications_changed (desktop_notifications_allowed == "online");
    }

    QJsonParseError error;
    auto json = QJsonDocument.from_json (json_str.to_utf8 (), &error);
    // empty or invalid response and status code is != 304 because json_str is expected to be empty
    if ( (error.error != QJsonParseError.NoError || json.is_null ()) && http_status_code != not_modified_status_code) {
        q_c_warning (lc_json_api_job) << "invalid JSON!" << json_str << error.error_string ();
        emit json_received (json, status_code);
        return true;
    }

    emit json_received (json, status_code);
    return true;
}

DetermineAuthTypeJob.DetermineAuthTypeJob (AccountPtr account, GLib.Object *parent)
    : GLib.Object (parent)
    , _account (account) {
}

void DetermineAuthTypeJob.start () {
    q_c_info (lc_determine_auth_type_job) << "Determining auth type for" << _account.dav_url ();

    QNetworkRequest req;
    // Prevent HttpCredentialsAccessManager from setting an Authorization header.
    req.set_attribute (HttpCredentials.DontAddCredentialsAttribute, true);
    // Don't reuse previous auth credentials
    req.set_attribute (QNetworkRequest.Authentication_reuse_attribute, QNetworkRequest.Manual);

    // Start three parallel requests

    // 1. determines whether it's a basic auth server
    auto get = _account.send_request ("GET", _account.url (), req);

    // 2. checks the HTTP auth method.
    auto propfind = _account.send_request ("PROPFIND", _account.dav_url (), req);

    // 3. Determines if the old flow has to be used (GS for now)
    auto old_flow_required = new JsonApiJob (_account, "/ocs/v2.php/cloud/capabilities", this);

    get.set_timeout (30 * 1000);
    propfind.set_timeout (30 * 1000);
    old_flow_required.set_timeout (30 * 1000);
    get.set_ignore_credential_failure (true);
    propfind.set_ignore_credential_failure (true);
    old_flow_required.set_ignore_credential_failure (true);

    connect (get, &SimpleNetworkJob.finished_signal, this, [this, get] () {
        const auto reply = get.reply ();
        const auto www_authenticate_header = reply.raw_header ("WWW-Authenticate");
        if (reply.error () == QNetworkReply.AuthenticationRequiredError
            && (www_authenticate_header.starts_with ("Basic") || www_authenticate_header.starts_with ("Bearer"))) {
            _result_get = Basic;
        } else {
            _result_get = Login_flow_v2;
        }
        _get_done = true;
        check_all_done ();
    });
    connect (propfind, &SimpleNetworkJob.finished_signal, this, [this] (QNetworkReply *reply) {
        auto auth_challenge = reply.raw_header ("WWW-Authenticate").to_lower ();
        if (auth_challenge.contains ("bearer ")) {
            _result_propfind = OAuth;
        } else {
            if (auth_challenge.is_empty ()) {
                q_c_warning (lc_determine_auth_type_job) << "Did not receive WWW-Authenticate reply to auth-test PROPFIND";
            } else {
                q_c_warning (lc_determine_auth_type_job) << "Unknown WWW-Authenticate reply to auth-test PROPFIND:" << auth_challenge;
            }
            _result_propfind = Basic;
        }
        _propfind_done = true;
        check_all_done ();
    });
    connect (old_flow_required, &JsonApiJob.json_received, this, [this] (QJsonDocument &json, int status_code) {
        if (status_code == 200) {
            _result_old_flow = Login_flow_v2;

            auto data = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("capabilities").to_object ();
            auto gs = data.value ("globalscale");
            if (gs != QJsonValue.Undefined) {
                auto flow = gs.to_object ().value ("desktoplogin");
                if (flow != QJsonValue.Undefined) {
                    if (flow.to_int () == 1) {
#ifdef WITH_WEBENGINE
                        _result_old_flow = Web_view_flow;
#else // WITH_WEBENGINE
                        q_c_warning (lc_determine_auth_type_job) << "Server does only support flow1, but this client was compiled without support for flow1";
#endif // WITH_WEBENGINE
                    }
                }
            }
        } else {
            _result_old_flow = Basic;
        }
        _old_flow_done = true;
        check_all_done ();
    });

    old_flow_required.start ();
}

void DetermineAuthTypeJob.check_all_done () {
    // Do not conitunue until eve
    if (!_get_done || !_propfind_done || !_old_flow_done) {
        return;
    }

    Q_ASSERT (_result_get != No_auth_type);
    Q_ASSERT (_result_propfind != No_auth_type);
    Q_ASSERT (_result_old_flow != No_auth_type);

    auto result = _result_propfind;

#ifdef WITH_WEBENGINE
    // Web_view_flow > OAuth > Basic
    if (_account.server_version_int () >= Account.make_server_version (12, 0, 0)) {
        result = Web_view_flow;
    }
#endif // WITH_WEBENGINE

    // Login_flow_v2 > Web_view_flow > OAuth > Basic
    if (_account.server_version_int () >= Account.make_server_version (16, 0, 0)) {
        result = Login_flow_v2;
    }

#ifdef WITH_WEBENGINE
    // If we determined that we need the webview flow (GS for example) then we switch to that
    if (_result_old_flow == Web_view_flow) {
        result = Web_view_flow;
    }
#endif // WITH_WEBENGINE

    // If we determined that a simple get gave us an authentication required error
    // then the server enforces basic auth and we got no choice but to use this
    if (_result_get == Basic) {
        result = Basic;
    }

    q_c_info (lc_determine_auth_type_job) << "Auth type for" << _account.dav_url () << "is" << result;
    emit auth_type (result);
    delete_later ();
}

SimpleNetworkJob.SimpleNetworkJob (AccountPtr account, GLib.Object *parent)
    : AbstractNetworkJob (account, string (), parent) {
}

QNetworkReply *SimpleNetworkJob.start_request (QByteArray &verb, QUrl &url,
    QNetworkRequest req, QIODevice *request_body) {
    auto reply = send_request (verb, url, req, request_body);
    start ();
    return reply;
}

bool SimpleNetworkJob.finished () {
    emit finished_signal (reply ());
    return true;
}

Delete_api_job.Delete_api_job (AccountPtr account, string &path, GLib.Object *parent)
    : AbstractNetworkJob (account, path, parent) {

}

void Delete_api_job.start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    QUrl url = Utility.concat_url_path (account ().url (), path ());
    send_request ("DELETE", url, req);
    AbstractNetworkJob.start ();
}

bool Delete_api_job.finished () {
    q_c_info (lc_json_api_job) << "JsonApiJob of" << reply ().request ().url () << "FINISHED WITH STATUS"
                         << reply ().error ()
                         << (reply ().error () == QNetworkReply.NoError ? QLatin1String ("") : error_string ());

    int http_status = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    if (reply ().error () != QNetworkReply.NoError) {
        q_c_warning (lc_json_api_job) << "Network error : " << path () << error_string () << http_status;
        emit result (http_status);
        return true;
    }

    const auto reply_data = string.from_utf8 (reply ().read_all ());
    q_c_info (lc_json_api_job ()) << "TMX Delete Job" << reply_data;
    emit result (http_status);
    return true;
}

void fetch_private_link_url (AccountPtr account, string &remote_path,
    const QByteArray &numeric_file_id, GLib.Object *target,
    std.function<void (string &url)> target_fun) {
    string old_url;
    if (!numeric_file_id.is_empty ())
        old_url = account.deprecated_private_link_url (numeric_file_id).to_string (QUrl.FullyEncoded);

    // Retrieve the new link by PROPFIND
    auto *job = new PropfindJob (account, remote_path, target);
    job.set_properties (
        QList<QByteArray> ()
        << "http://owncloud.org/ns:fileid" // numeric file id for fallback private link generation
        << "http://owncloud.org/ns:privatelink");
    job.set_timeout (10 * 1000);
    GLib.Object.connect (job, &PropfindJob.result, target, [=] (QVariantMap &result) {
        auto private_link_url = result["privatelink"].to_string ();
        auto numeric_file_id = result["fileid"].to_byte_array ();
        if (!private_link_url.is_empty ()) {
            target_fun (private_link_url);
        } else if (!numeric_file_id.is_empty ()) {
            target_fun (account.deprecated_private_link_url (numeric_file_id).to_string (QUrl.FullyEncoded));
        } else {
            target_fun (old_url);
        }
    });
    GLib.Object.connect (job, &PropfindJob.finished_with_error, target, [=] (QNetworkReply *) {
        target_fun (old_url);
    });
    job.start ();
}

} // namespace Occ
