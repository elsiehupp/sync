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
// #include <QSslCipher>
// #include <QBuffer>
// #include <QXmlStreamReader>
// #include <string[]>
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

// #include <QBuffer>
// #include <QUrlQuery>
// #include <QJsonDocument>
// #include <functional>


namespace Occ {

/***********************************************************
Strips quotes and gzip annotations
***********************************************************/
GLib.ByteArray parse_etag (char header);

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

    /***********************************************************
    ***********************************************************/
    public EntityExistsJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void on_start () override;

signals:
    void exists (QNetworkReply *);


    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;
};

/***********************************************************
@brief sends a DELETE http request to a url.

See Nextcloud API usage for the possible DELETE requests.

This does not* delete files, it does a http request.
***********************************************************/
class DeleteApiJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public DeleteApiJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void on_start () override;

signals:
    void result (int http_code);


    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;
};

struct ExtraFolderInfo {
    GLib.ByteArray file_id;
    int64 size = -1;
};

/***********************************************************
@brief The LsColJob class
@ingroup libsync
***********************************************************/
class LsColXMLParser : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public LsColXMLParser ();

    /***********************************************************
    ***********************************************************/
    public bool parse (GLib.ByteArray xml,
               QHash<string, ExtraFolderInfo> *sizes,
               const string expected_path);

signals:
    void directory_listing_subfolders (string[] &items);
    void directory_listing_iterated (string name, QMap<string, string> &properties);
    void finished_with_error (QNetworkReply reply);
    void finished_without_error ();
};

class LsColJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public LsColJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    public void on_start () override;
    public QHash<string, ExtraFolderInfo> _folder_infos;


    /***********************************************************
    Used to specify which properties shall be retrieved.

    The properties can
     - contain no colon : they refer to a property in the DAV :
     - contain a colon : and thus specify an explicit namespace,
       e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
    ***********************************************************/
    public void set_properties (GLib.List<GLib.ByteArray> properties);


    /***********************************************************
    ***********************************************************/
    public GLib.List<GLib.ByteArray> properties ();

signals:
    void directory_listing_subfolders (string[] &items);
    void directory_listing_iterated (string name, QMap<string, string> &properties);
    void finished_with_error (QNetworkReply reply);
    void finished_without_error ();


    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.List<GLib.ByteArray> _properties;
    private GLib.Uri _url; // Used instead of path () if the url is specified in the constructor
};

/***********************************************************
@brief The PropfindJob class

Setting the desired properties with set_properties

Note that this job is only for querying one item.
There is also the LsColJob which can be used to list collections

@ingroup libsync
***********************************************************/
class PropfindJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public PropfindJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void on_start () override;


    /***********************************************************
    Used to specify which properties shall be retrieved.

    The properties can
     - contain no colon : they refer to a property in the DAV :
     - contain a colon : and thus specify an explicit namespace,
       e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
    ***********************************************************/
    public void set_properties (GLib.List<GLib.ByteArray> properties);


    /***********************************************************
    ***********************************************************/
    public GLib.List<GLib.ByteArray> properties ();

signals:
    void result (QVariantMap &values);
    void finished_with_error (QNetworkReply reply = nullptr);


    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.List<GLib.ByteArray> _properties;
};

#ifndef TOKEN_AUTH_ONLY
/***********************************************************
@brief Retrieves the account users avatar from the server using a GET request.

If the server does not have the avatar, the result Pixmap is empty.

@ingroup libsync
***********************************************************/
class AvatarJob : AbstractNetworkJob {

    /***********************************************************
    @param user_id The user for which to obtain the avatar
    @param size The size of the avatar (square so size*size)
    ***********************************************************/
    public AvatarJob (AccountPointer account, string user_id, int size, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public void on_start () override;


    /***********************************************************
    The retrieved avatar images don't have the circle shape by default
    ***********************************************************/
    public static QImage make_circular_avatar (QImage &base_avatar);

signals:
    /***********************************************************
    @brief avatar_pixmap - returns either a valid pixmap or not.
    ***********************************************************/

    void avatar_pixmap (QImage &);


    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.Uri _avatar_url;
};
#endif

/***********************************************************
@brief Send a Proppatch request

Setting the desired p

WARNING : Untested!

@ingroup libsync
***********************************************************/
class ProppatchJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public ProppatchJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void on_start () override;


    /***********************************************************
    Used to specify which properties shall be set.

    The property keys can
     - contain no colon : they refer to a property in the DAV :
     - contain a colon : and thus specify an explicit namespace,
       e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
    ***********************************************************/
    public void set_properties (QMap<GLib.ByteArray, GLib.ByteArray> properties);


    /***********************************************************
    ***********************************************************/
    public QMap<GLib.ByteArray, GLib.ByteArray> properties ();

signals:
    void on_success ();
    void finished_with_error ();


    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;

    /***********************************************************
    ***********************************************************/
    private 
    private QMap<GLib.ByteArray, GLib.ByteArray> _properties;
};

/***********************************************************
@brief The MkColJob class
@ingroup libsync
***********************************************************/
class MkColJob : AbstractNetworkJob {
    GLib.Uri _url; // Only used if the constructor taking a url is taken.
    QMap<GLib.ByteArray, GLib.ByteArray> _extra_headers;


    /***********************************************************
    ***********************************************************/
    public MkColJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public MkColJob (AccountPointer account, GLib.Uri url,);

    /***********************************************************
    ***********************************************************/
    public 
    public st QMap<GLib.ByteArray, GLib.ByteArray> &extra_headers, GLib.Object parent = new GLib.Object ());


    public void on_start () override;

signals:
    void finished_with_error (QNetworkReply reply);
    void finished_without_error ();


    /***********************************************************
    ***********************************************************/
    private bool on_finished () override;
};

/***********************************************************
@brief The CheckServerJob class
@ingroup libsync
***********************************************************/
class CheckServerJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public CheckServerJob (AccountPointer account, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public static string version_string (QJsonObject &info);


    public static bool installed (QJsonObject &info);

signals:
    /***********************************************************
    Emitted when a status.php was successfully read.

    \a url see _server_status_url (does not include "/status.php")
    \a info The status.php reply information
    ***********************************************************/
    void instance_found (GLib.Uri url, QJsonObject &info);


    /***********************************************************
    Emitted on invalid status.php reply.

    \a reply is never null
    ***********************************************************/
    void instance_not_found (QNetworkReply reply);


    /***********************************************************
    A timeout occurred.

    \a url The specific url where the timeout happened.
    ***********************************************************/
    void timeout (GLib.Uri url);


    /***********************************************************
    ***********************************************************/
    private bool on_finished () override;

    /***********************************************************
    ***********************************************************/
    private 
    private on_ virtual void meta_data_changed_slot ();
    private on_ virtual void encrypted_slot ();
    private void on_redirected (QNetworkReply reply, GLib.Uri target_url, int redirect_count);


    /***********************************************************
    ***********************************************************/
    private bool _subdir_fallback;


    /***********************************************************
    The permanent-redirect adjusted account url.

    Note that temporary redirects or a permanent redirect behind a temporary
    one do not affect this url.
    ***********************************************************/
    private GLib.Uri _server_url;


    /***********************************************************
    Keep track of how many permanent redirect were applied.
    ***********************************************************/
    private int _permanent_redirects;
};

/***********************************************************
@brief The RequestEtagJob class
***********************************************************/
class RequestEtagJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public RequestEtagJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void on_start () override;

signals:
    void on_etag_retrieved (GLib.ByteArray etag, GLib.DateTime &time);
    void finished_with_result (HttpResult<GLib.ByteArray> &etag);


    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;
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

    /***********************************************************
    ***********************************************************/
    public enum class Verb {
        Get,
        Post,
        Put,
        Delete,
    };

    /***********************************************************
    ***********************************************************/
    public JsonApiJob (AccountPointer &account, string path, GLib.Object parent = new GLib.Object ());


    /***********************************************************
    @brief add_query_params - add more parameters to the ocs call
    @param parameters : list pairs of strings containing the parameter name and the value.

    All parameters from the passed list are appended to the query. Not
    that the format=json para
    need to be set this way.

    This function needs to be called before on_start () obviously.
    ***********************************************************/
    public void add_query_params (QUrlQuery &parameters);


    /***********************************************************
    ***********************************************************/
    public void add_raw_header (GLib.ByteArray header_name, GLib.ByteArray value);

    /***********************************************************
    ***********************************************************/
    public void set_body (QJsonDocument &body);

    /***********************************************************
    ***********************************************************/
    public void set_verb (Verb value);

    /***********************************************************
    ***********************************************************/
    public 
    public on_ void on_start () override;


    protected bool on_finished () override;
signals:

    /***********************************************************
    @brief json_received - signal to report the json answer from ocs
    @param json - the parsed json document
    @param status_code - the OCS status code : 100 (!) for on_success
    ***********************************************************/
    void json_received (QJsonDocument &json, int status_code);


    /***********************************************************
    @brief etag_response_header_received - signal to report the ETag response header value
    from ocs api v2
    @param value - the ETag response header value
    @param status_code - the OCS status code : 100 (!) for on_success
    ***********************************************************/
    void etag_response_header_received (GLib.ByteArray value, int status_code);


    /***********************************************************
    @brief desktop_notification_status_received - signal to report if notifications are allowed
    @param status - set desktop notifications allowed status
    ***********************************************************/
    void allow_desktop_notifications_changed (bool is_allowed);


    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray _body;
    private QUrlQuery _additional_params;
    private QNetworkRequest _request;

    /***********************************************************
    ***********************************************************/
    private Verb _verb = Verb.Get;

    /***********************************************************
    ***********************************************************/
    private GLib.ByteArray verb_to_"";
};

/***********************************************************
@brief Checks with auth type to use for a server
@ingroup libsync
***********************************************************/
class DetermineAuthTypeJob : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum AuthType {
        NoAuthType, // used only before we got a chance to probe the server
#ifdef WITH_WEBENGINE
        WebViewFlow,
#endif // WITH_WEBENGINE
        Basic, // also the catch-all fallback for backwards compatibility reasons
        OAuth,
        LoginFlowV2
    };
    Q_ENUM (AuthType)

    /***********************************************************
    ***********************************************************/
    public DetermineAuthTypeJob (AccountPointer account, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void on_start ();
signals:
    void auth_type (AuthType);


    /***********************************************************
    ***********************************************************/
    private void check_all_done ();

    /***********************************************************
    ***********************************************************/
    private AccountPointer _account;
    private AuthType _result_get = NoAuthType;
    private AuthType _result_propfind = NoAuthType;
    private AuthType _result_old_flow = NoAuthType;
    private bool _get_done = false;
    private bool _propfind_done = false;
    private bool _old_flow_done = false;
};

/***********************************************************
@brief A basic job around a network request without extra funtionality
@ingroup libsync

Primarily adds timeout and redirection handling.
***********************************************************/
class SimpleNetworkJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    public SimpleNetworkJob (AccountPointer account, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public QNetworkReply start_request (GLib.ByteArray verb, GLib.Uri url,
        QNetworkRequest req = QNetworkRequest (),
        QIODevice request_body = nullptr);

signals:
    void finished_signal (QNetworkReply reply);

    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;
};

/***********************************************************
@brief Runs a PROPFIND to figure out the private link url

The numeric_file_id is used only to build the deprecated_private_link_url
locally as a fallback. If it's empty an
will be called with an empty string.

The job and signal connections are parented to the target GLib.Object.

Note: target_fun is guaranteed to be called only through the event
loop and never directly.
***********************************************************/
void fetch_private_link_url (
    AccountPointer account, string remote_path,
    const GLib.ByteArray numeric_file_id, GLib.Object target,
    std.function<void (string url)> target_fun);



const int not_modified_status_code = 304;

GLib.ByteArray parse_etag (char header) {
    if (!header)
        return GLib.ByteArray ();
    GLib.ByteArray arr = header;

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

RequestEtagJob.RequestEtagJob (AccountPointer account, string path, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent) {
}

void RequestEtagJob.on_start () {
    QNetworkRequest req;
    req.set_raw_header ("Depth", "0");

    GLib.ByteArray xml ("<?xml version=\"1.0\" ?>\n"
                   "<d:propfind xmlns:d=\"DAV:\">\n"
                   "  <d:prop>\n"
                   "    <d:getetag/>\n"
                   "  </d:prop>\n"
                   "</d:propfind>\n");
    var buf = new QBuffer (this);
    buf.set_data (xml);
    buf.open (QIODevice.ReadOnly);
    // assumes ownership
    send_request ("PROPFIND", make_dav_url (path ()), req, buf);

    if (reply ().error () != QNetworkReply.NoError) {
        GLib.warn (lc_etag_job) << "request network error : " << reply ().error_string ();
    }
    AbstractNetworkJob.on_start ();
}

bool RequestEtagJob.on_finished () {
    q_c_info (lc_etag_job) << "Request Etag of" << reply ().request ().url () << "FINISHED WITH STATUS"
                      <<  reply_status_"";

    var http_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (http_code == 207) {
        // Parse DAV response
        QXmlStreamReader reader (reply ());
        reader.add_extra_namespace_declaration (QXmlStreamNamespaceDeclaration (QStringLiteral ("d"), QStringLiteral ("DAV:")));
        GLib.ByteArray etag;
        while (!reader.at_end ()) {
            QXmlStreamReader.TokenType type = reader.read_next ();
            if (type == QXmlStreamReader.StartElement && reader.namespace_uri () == QLatin1String ("DAV:")) {
                string name = reader.name ().to_"";
                if (name == QLatin1String ("getetag")) {
                    var etag_text = reader.read_element_text ();
                    var parsed_tag = parse_etag (etag_text.to_utf8 ());
                    if (!parsed_tag.is_empty ()) {
                        etag += parsed_tag;
                    } else {
                        etag += etag_text.to_utf8 ();
                    }
                }
            }
        }
        emit etag_retrieved (etag, GLib.DateTime.from_string (string.from_utf8 (_response_timestamp), Qt.RFC2822Date));
        emit finished_with_result (etag);
    } else {
        emit finished_with_result (HttpError {
            http_code, error_string ()
        });
    }
    return true;
}

/****************************************************************************/

MkColJob.MkColJob (AccountPointer account, string path, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent) {
}

MkColJob.MkColJob (AccountPointer account, string path, QMap<GLib.ByteArray, GLib.ByteArray> &extra_headers, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent)
    , _extra_headers (extra_headers) {
}

MkColJob.MkColJob (AccountPointer account, GLib.Uri url,
    const QMap<GLib.ByteArray, GLib.ByteArray> &extra_headers, GLib.Object parent)
    : AbstractNetworkJob (account, "", parent)
    , _url (url)
    , _extra_headers (extra_headers) {
}

void MkColJob.on_start () {
    // add 'Content-Length : 0' header (see https://github.com/owncloud/client/issues/3256)
    QNetworkRequest req;
    req.set_raw_header ("Content-Length", "0");
    for (var it = _extra_headers.const_begin (); it != _extra_headers.const_end (); ++it) {
        req.set_raw_header (it.key (), it.value ());
    }

    // assumes ownership
    if (_url.is_valid ()) {
        send_request ("MKCOL", _url, req);
    } else {
        send_request ("MKCOL", make_dav_url (path ()), req);
    }
    AbstractNetworkJob.on_start ();
}

bool MkColJob.on_finished () {
    q_c_info (lc_mk_col_job) << "MKCOL of" << reply ().request ().url () << "FINISHED WITH STATUS"
                       << reply_status_"";

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
        QXmlStreamReader.TokenType type = reader.read_next ();
        if (type == QXmlStreamReader.StartElement) {
            level++;
            result += "<" + reader.name ().to_"" + ">";
        } else if (type == QXmlStreamReader.Characters) {
            result += reader.text ();
        } else if (type == QXmlStreamReader.EndElement) {
            level--;
            if (level < 0) {
                break;
            }
            result += "</" + reader.name ().to_"" + ">";
        }

    } while (!reader.at_end ());
    return result;
}

LsColXMLParser.LsColXMLParser () = default;

bool LsColXMLParser.parse (GLib.ByteArray xml, QHash<string, ExtraFolderInfo> *file_info, string expected_path) {
    // Parse DAV response
    QXmlStreamReader reader (xml);
    reader.add_extra_namespace_declaration (QXmlStreamNamespaceDeclaration ("d", "DAV:"));

    string[] folders;
    string current_href;
    QMap<string, string> current_tmp_properties;
    QMap<string, string> current_http200Properties;
    bool current_props_have_http200 = false;
    bool inside_propstat = false;
    bool inside_prop = false;
    bool inside_multi_status = false;

    while (!reader.at_end ()) {
        QXmlStreamReader.TokenType type = reader.read_next ();
        string name = reader.name ().to_"";
        // Start elements with DAV:
        if (type == QXmlStreamReader.StartElement && reader.namespace_uri () == QLatin1String ("DAV:")) {
            if (name == QLatin1String ("href")) {
                // We don't use URL encoding in our request URL (which is the expected path) (QNAM will do it for us)
                // but the result will have URL encoding..
                string href_string = GLib.Uri.from_local_file (GLib.Uri.from_percent_encoding (reader.read_element_text ().to_utf8 ()))
                        .adjusted (GLib.Uri.NormalizePathSegments)
                        .path ();
                if (!href_string.starts_with (expected_path)) {
                    GLib.warn (lc_ls_col_job) << "Invalid href" << href_string << "expected starting with" << expected_path;
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

        if (type == QXmlStreamReader.StartElement && inside_propstat && inside_prop) {
            // All those elements are properties
            string property_content = read_contents_as_string (reader);
            if (name == QLatin1String ("resourcetype") && property_content.contains ("collection")) {
                folders.append (current_href);
            } else if (name == QLatin1String ("size")) {
                bool ok = false;
                var s = property_content.to_long_long (&ok);
                if (ok && file_info) {
                    (*file_info)[current_href].size = s;
                }
            } else if (name == QLatin1String ("fileid")) {
                (*file_info)[current_href].file_id = property_content.to_utf8 ();
            }
            current_tmp_properties.insert (reader.name ().to_"", property_content);
        }

        // End elements with DAV:
        if (type == QXmlStreamReader.EndElement) {
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
        GLib.warn (lc_ls_col_job) << "ERROR" << reader.error_string () << xml;
        return false;
    } else if (!inside_multi_status) {
        GLib.warn (lc_ls_col_job) << "ERROR no WebDAV response?" << xml;
        return false;
    } else {
        emit directory_listing_subfolders (folders);
        emit finished_without_error ();
    }
    return true;
}

/****************************************************************************/

LsColJob.LsColJob (AccountPointer account, string path, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent) {
}

LsColJob.LsColJob (AccountPointer account, GLib.Uri url, GLib.Object parent)
    : AbstractNetworkJob (account, "", parent)
    , _url (url) {
}

void LsColJob.set_properties (GLib.List<GLib.ByteArray> properties) {
    _properties = properties;
}

GLib.List<GLib.ByteArray> LsColJob.properties () {
    return _properties;
}

void LsColJob.on_start () {
    GLib.List<GLib.ByteArray> properties = _properties;

    if (properties.is_empty ()) {
        GLib.warn (lc_ls_col_job) << "Propfind with no properties!";
    }
    GLib.ByteArray prop_str;
    foreach (GLib.ByteArray prop, properties) {
        if (prop.contains (':')) {
            int col_idx = prop.last_index_of (":");
            var ns = prop.left (col_idx);
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
    GLib.ByteArray xml ("<?xml version=\"1.0\" ?>\n"
                   "<d:propfind xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\">\n"
                   "  <d:prop>\n"
        + prop_str + "  </d:prop>\n"
                    "</d:propfind>\n");
    var buf = new QBuffer (this);
    buf.set_data (xml);
    buf.open (QIODevice.ReadOnly);
    if (_url.is_valid ()) {
        send_request ("PROPFIND", _url, req, buf);
    } else {
        send_request ("PROPFIND", make_dav_url (path ()), req, buf);
    }
    AbstractNetworkJob.on_start ();
}

// TODO : Instead of doing all in this slot, we should iteratively parse in ready_read (). This
// would allow us to be more asynchronous in processing while data is coming from the network,
// not all in one big blob at the end.
bool LsColJob.on_finished () {
    q_c_info (lc_ls_col_job) << "LSCOL of" << reply ().request ().url () << "FINISHED WITH STATUS"
                       << reply_status_"";

    string content_type = reply ().header (QNetworkRequest.ContentTypeHeader).to_"";
    int http_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (http_code == 207 && content_type.contains ("application/xml; charset=utf-8")) {
        LsColXMLParser parser;
        connect (&parser, &LsColXMLParser.directory_listing_subfolders,
            this, &LsColJob.directory_listing_subfolders);
        connect (&parser, &LsColXMLParser.directory_listing_iterated,
            this, &LsColJob.directory_listing_iterated);
        connect (&parser, &LsColXMLParser.finished_with_error,
            this, &LsColJob.finished_with_error);
        connect (&parser, &LsColXMLParser.finished_without_error,
            this, &LsColJob.finished_without_error);

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

CheckServerJob.CheckServerJob (AccountPointer account, GLib.Object parent)
    : AbstractNetworkJob (account, QLatin1String (statusphp_c), parent)
    , _subdir_fallback (false)
    , _permanent_redirects (0) {
    set_ignore_credential_failure (true);
    connect (this, &AbstractNetworkJob.redirected,
        this, &CheckServerJob.on_redirected);
}

void CheckServerJob.on_start () {
    _server_url = account ().url ();
    send_request ("GET", Utility.concat_url_path (_server_url, path ()));
    connect (reply (), &QNetworkReply.meta_data_changed, this, &CheckServerJob.meta_data_changed_slot);
    connect (reply (), &QNetworkReply.encrypted, this, &CheckServerJob.encrypted_slot);
    AbstractNetworkJob.on_start ();
}

void CheckServerJob.on_timed_out () {
    GLib.warn (lc_check_server_job) << "TIMEOUT";
    if (reply () && reply ().is_running ()) {
        emit timeout (reply ().url ());
    } else if (!reply ()) {
        GLib.warn (lc_check_server_job) << "Timeout even there was no reply?";
    }
    delete_later ();
}

string CheckServerJob.version (QJsonObject &info) {
    return info.value (QLatin1String ("version")).to_"";
}

string CheckServerJob.version_string (QJsonObject &info) {
    return info.value (QLatin1String ("versionstring")).to_"";
}

bool CheckServerJob.installed (QJsonObject &info) {
    return info.value (QLatin1String ("installed")).to_bool ();
}

static void merge_ssl_configuration_for_ssl_button (QSslConfiguration &config, AccountPointer account) {
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

void CheckServerJob.on_redirected (QNetworkReply reply, GLib.Uri target_url, int redirect_count) {
    GLib.ByteArray slash_status_php ("/");
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

bool CheckServerJob.on_finished () {
    if (reply ().request ().url ().scheme () == QLatin1String ("https")
        && reply ().ssl_configuration ().session_ticket ().is_empty ()
        && reply ().error () == QNetworkReply.NoError) {
        GLib.warn (lc_check_server_job) << "No SSL session identifier / session ticket is used, this might impact sync performance negatively.";
    }

    merge_ssl_configuration_for_ssl_button (reply ().ssl_configuration (), account ());

    // The server installs to /owncloud. Let's try that if the file wasn't found
    // at the original location
    if ( (reply ().error () == QNetworkReply.ContentNotFoundError) && (!_subdir_fallback)) {
        _subdir_fallback = true;
        set_path (QLatin1String (nextcloud_dir_c) + QLatin1String (statusphp_c));
        on_start ();
        q_c_info (lc_check_server_job) << "Retrying with" << reply ().url ();
        return false;
    }

    GLib.ByteArray body = reply ().peek (4 * 1024);
    int http_status = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (body.is_empty () || http_status != 200) {
        GLib.warn (lc_check_server_job) << "error : status.php replied " << http_status << body;
        emit instance_not_found (reply ());
    } else {
        QJsonParseError error;
        var status = QJsonDocument.from_json (body, &error);
        // empty or invalid response
        if (error.error != QJsonParseError.NoError || status.is_null ()) {
            GLib.warn (lc_check_server_job) << "status.php from server is not valid JSON!" << body << reply ().request ().url () << error.error_string ();
        }

        q_c_info (lc_check_server_job) << "status.php returns : " << status << " " << reply ().error () << " Reply : " << reply ();
        if (status.object ().contains ("installed")) {
            emit instance_found (_server_url, status.object ());
        } else {
            GLib.warn (lc_check_server_job) << "No proper answer on " << reply ().url ();
            emit instance_not_found (reply ());
        }
    }
    return true;
}

/****************************************************************************/

PropfindJob.PropfindJob (AccountPointer account, string path, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent) {
}

void PropfindJob.on_start () {
    GLib.List<GLib.ByteArray> properties = _properties;

    if (properties.is_empty ()) {
        GLib.warn (lc_ls_col_job) << "Propfind with no properties!";
    }
    QNetworkRequest req;
    // Always have a higher priority than the propagator because we use this from the UI
    // and really want this to be done first (no matter what internal scheduling QNAM uses).
    // Also possibly useful for avoiding false timeouts.
    req.set_priority (QNetworkRequest.HighPriority);
    req.set_raw_header ("Depth", "0");
    GLib.ByteArray prop_str;
    foreach (GLib.ByteArray prop, properties) {
        if (prop.contains (':')) {
            int col_idx = prop.last_index_of (":");
            prop_str += "    <" + prop.mid (col_idx + 1) + " xmlns=\"" + prop.left (col_idx) + "\" />\n";
        } else {
            prop_str += "    <d:" + prop + " />\n";
        }
    }
    GLib.ByteArray xml = "<?xml version=\"1.0\" ?>\n"
                     "<d:propfind xmlns:d=\"DAV:\">\n"
                     "  <d:prop>\n"
        + prop_str + "  </d:prop>\n"
                    "</d:propfind>\n";

    var buf = new QBuffer (this);
    buf.set_data (xml);
    buf.open (QIODevice.ReadOnly);
    send_request ("PROPFIND", make_dav_url (path ()), req, buf);

    AbstractNetworkJob.on_start ();
}

void PropfindJob.set_properties (GLib.List<GLib.ByteArray> properties) {
    _properties = properties;
}

GLib.List<GLib.ByteArray> PropfindJob.properties () {
    return _properties;
}

bool PropfindJob.on_finished () {
    q_c_info (lc_propfind_job) << "PROPFIND of" << reply ().request ().url () << "FINISHED WITH STATUS"
                          << reply_status_"";

    int http_result_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    if (http_result_code == 207) {
        // Parse DAV response
        QXmlStreamReader reader (reply ());
        reader.add_extra_namespace_declaration (QXmlStreamNamespaceDeclaration ("d", "DAV:"));

        QVariantMap items;
        // introduced to nesting is ignored
        QStack<string> cur_element;

        while (!reader.at_end ()) {
            QXmlStreamReader.TokenType type = reader.read_next ();
            if (type == QXmlStreamReader.StartElement) {
                if (!cur_element.is_empty () && cur_element.top () == QLatin1String ("prop")) {
                    items.insert (reader.name ().to_"", reader.read_element_text (QXmlStreamReader.SkipChildElements));
                } else {
                    cur_element.push (reader.name ().to_"");
                }
            }
            if (type == QXmlStreamReader.EndElement) {
                if (cur_element.top () == reader.name ()) {
                    cur_element.pop ();
                }
            }
        }
        if (reader.has_error ()) {
            GLib.warn (lc_propfind_job) << "XML parser error : " << reader.error_string ();
            emit finished_with_error (reply ());
        } else {
            emit result (items);
        }
    } else {
        GLib.warn (lc_propfind_job) << "*not* successful, http result code is" << http_result_code
                                 << (http_result_code == 302 ? reply ().header (QNetworkRequest.LocationHeader).to_"" : QLatin1String (""));
        emit finished_with_error (reply ());
    }
    return true;
}

/****************************************************************************/

#ifndef TOKEN_AUTH_ONLY
AvatarJob.AvatarJob (AccountPointer account, string user_id, int size, GLib.Object parent)
    : AbstractNetworkJob (account, "", parent) {
    if (account.server_version_int () >= Account.make_server_version (10, 0, 0)) {
        _avatar_url = Utility.concat_url_path (account.url (), string ("remote.php/dav/avatars/%1/%2.png").arg (user_id, string.number (size)));
    } else {
        _avatar_url = Utility.concat_url_path (account.url (), string ("index.php/avatar/%1/%2").arg (user_id, string.number (size)));
    }
}

void AvatarJob.on_start () {
    QNetworkRequest req;
    send_request ("GET", _avatar_url, req);
    AbstractNetworkJob.on_start ();
}

QImage AvatarJob.make_circular_avatar (QImage &base_avatar) {
    if (base_avatar.is_null ()) {
        return {};
    }

    int dim = base_avatar.width ();

    QImage avatar (dim, dim, QImage.Format_ARGB32);
    avatar.fill (Qt.transparent);

    QPainter painter (&avatar);
    painter.set_render_hint (QPainter.Antialiasing);

    QPainterPath path;
    path.add_ellipse (0, 0, dim, dim);
    painter.set_clip_path (path);

    painter.draw_image (0, 0, base_avatar);
    painter.end ();

    return avatar;
}

bool AvatarJob.on_finished () {
    int http_result_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    QImage av_image;

    if (http_result_code == 200) {
        GLib.ByteArray png_data = reply ().read_all ();
        if (png_data.size ()) {
            if (av_image.load_from_data (png_data)) {
                GLib.debug (lc_avatar_job) << "Retrieved Avatar pixmap!";
            }
        }
    }
    emit (avatar_pixmap (av_image));
    return true;
}
#endif

/****************************************************************************/

ProppatchJob.ProppatchJob (AccountPointer account, string path, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent) {
}

void ProppatchJob.on_start () {
    if (_properties.is_empty ()) {
        GLib.warn (lc_proppatch_job) << "Proppatch with no properties!";
    }
    QNetworkRequest req;

    GLib.ByteArray prop_str;
    QMapIterator<GLib.ByteArray, GLib.ByteArray> it (_properties);
    while (it.has_next ()) {
        it.next ();
        GLib.ByteArray key_name = it.key ();
        GLib.ByteArray key_ns;
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
    GLib.ByteArray xml = "<?xml version=\"1.0\" ?>\n"
                     "<d:propertyupdate xmlns:d=\"DAV:\">\n"
                     "  <d:set><d:prop>\n"
        + prop_str + "  </d:prop></d:set>\n"
                    "</d:propertyupdate>\n";

    var buf = new QBuffer (this);
    buf.set_data (xml);
    buf.open (QIODevice.ReadOnly);
    send_request ("PROPPATCH", make_dav_url (path ()), req, buf);
    AbstractNetworkJob.on_start ();
}

void ProppatchJob.set_properties (QMap<GLib.ByteArray, GLib.ByteArray> properties) {
    _properties = properties;
}

QMap<GLib.ByteArray, GLib.ByteArray> ProppatchJob.properties () {
    return _properties;
}

bool ProppatchJob.on_finished () {
    q_c_info (lc_proppatch_job) << "PROPPATCH of" << reply ().request ().url () << "FINISHED WITH STATUS"
                           << reply_status_"";

    int http_result_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    if (http_result_code == 207) {
        emit success ();
    } else {
        GLib.warn (lc_proppatch_job) << "*not* successful, http result code is" << http_result_code
                                  << (http_result_code == 302 ? reply ().header (QNetworkRequest.LocationHeader).to_"" : QLatin1String (""));
        emit finished_with_error ();
    }
    return true;
}

/****************************************************************************/

EntityExistsJob.EntityExistsJob (AccountPointer account, string path, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent) {
}

void EntityExistsJob.on_start () {
    send_request ("HEAD", make_account_url (path ()));
    AbstractNetworkJob.on_start ();
}

bool EntityExistsJob.on_finished () {
    emit exists (reply ());
    return true;
}

/****************************************************************************/

JsonApiJob.JsonApiJob (AccountPointer &account, string path, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent) {
}

void JsonApiJob.add_query_params (QUrlQuery &parameters) {
    _additional_params = parameters;
}

void JsonApiJob.add_raw_header (GLib.ByteArray header_name, GLib.ByteArray value) {
   _request.set_raw_header (header_name, value);
}

void JsonApiJob.set_body (QJsonDocument &body) {
    _body = body.to_json ();
    GLib.debug (lc_json_api_job) << "Set body for request:" << _body;
    if (!_body.is_empty ()) {
        _request.set_header (QNetworkRequest.ContentTypeHeader, "application/json");
    }
}

void JsonApiJob.set_verb (Verb value) {
    _verb = value;
}

GLib.ByteArray JsonApiJob.verb_to_"" {
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

void JsonApiJob.on_start () {
    add_raw_header ("OCS-APIREQUEST", "true");
    var query = _additional_params;
    query.add_query_item (QLatin1String ("format"), QLatin1String ("json"));
    GLib.Uri url = Utility.concat_url_path (account ().url (), path (), query);
    const var http_verb = verb_to_"";
    if (!_body.is_empty ()) {
        send_request (http_verb, url, _request, _body);
    } else {
        send_request (http_verb, url, _request);
    }
    AbstractNetworkJob.on_start ();
}

bool JsonApiJob.on_finished () {
    q_c_info (lc_json_api_job) << "JsonApiJob of" << reply ().request ().url () << "FINISHED WITH STATUS"
                         << reply_status_"";

    int status_code = 0;
    int http_status_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
    if (reply ().error () != QNetworkReply.NoError) {
        GLib.warn (lc_json_api_job) << "Network error : " << path () << error_string () << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute);
        status_code = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();
        emit json_received (QJsonDocument (), status_code);
        return true;
    }

    string json_str = string.from_utf8 (reply ().read_all ());
    if (json_str.contains ("<?xml version=\"1.0\"?>")) {
        const QRegularExpression rex ("<statuscode> (\\d+)</statuscode>");
        const var rex_match = rex.match (json_str);
        if (rex_match.has_match ()) {
            // this is a error message coming back from ocs.
            status_code = rex_match.captured (1).to_int ();
        }
    } else if (json_str.is_empty () && http_status_code == not_modified_status_code){
        GLib.warn (lc_json_api_job) << "Nothing changed so nothing to retrieve - status code : " << http_status_code;
        status_code = http_status_code;
    } else {
        const QRegularExpression rex (R" ("statuscode" : (\d+))");
        // example : "{"ocs":{"meta":{"status":"ok","statuscode":100,"message":null},"data":{"version":{"major":8,"minor":"... (504)
        const var rx_match = rex.match (json_str);
        if (rx_match.has_match ()) {
            status_code = rx_match.captured (1).to_int ();
        }
    }

    // save new ETag value
    if (reply ().raw_header_list ().contains ("ETag"))
        emit etag_response_header_received (reply ().raw_header ("ETag"), status_code);

    const var desktop_notifications_allowed = reply ().raw_header (GLib.ByteArray ("X-Nextcloud-User-Status"));
    if (!desktop_notifications_allowed.is_empty ()) {
        emit allow_desktop_notifications_changed (desktop_notifications_allowed == "online");
    }

    QJsonParseError error;
    var json = QJsonDocument.from_json (json_str.to_utf8 (), &error);
    // empty or invalid response and status code is != 304 because json_str is expected to be empty
    if ( (error.error != QJsonParseError.NoError || json.is_null ()) && http_status_code != not_modified_status_code) {
        GLib.warn (lc_json_api_job) << "invalid JSON!" << json_str << error.error_string ();
        emit json_received (json, status_code);
        return true;
    }

    emit json_received (json, status_code);
    return true;
}

DetermineAuthTypeJob.DetermineAuthTypeJob (AccountPointer account, GLib.Object parent)
    : GLib.Object (parent)
    , _account (account) {
}

void DetermineAuthTypeJob.on_start () {
    q_c_info (lc_determine_auth_type_job) << "Determining auth type for" << _account.dav_url ();

    QNetworkRequest req;
    // Prevent HttpCredentialsAccessManager from setting an Authorization header.
    req.set_attribute (HttpCredentials.DontAddCredentialsAttribute, true);
    // Don't reuse previous auth credentials
    req.set_attribute (QNetworkRequest.AuthenticationReuseAttribute, QNetworkRequest.Manual);

    // Start three parallel requests

    // 1. determines whether it's a basic auth server
    var get = _account.send_request ("GET", _account.url (), req);

    // 2. checks the HTTP auth method.
    var propfind = _account.send_request ("PROPFIND", _account.dav_url (), req);

    // 3. Determines if the old flow has to be used (GS for now)
    var old_flow_required = new JsonApiJob (_account, "/ocs/v2.php/cloud/capabilities", this);

    get.on_set_timeout (30 * 1000);
    propfind.on_set_timeout (30 * 1000);
    old_flow_required.on_set_timeout (30 * 1000);
    get.set_ignore_credential_failure (true);
    propfind.set_ignore_credential_failure (true);
    old_flow_required.set_ignore_credential_failure (true);

    connect (get, &SimpleNetworkJob.finished_signal, this, [this, get] () {
        const var reply = get.reply ();
        const var www_authenticate_header = reply.raw_header ("WWW-Authenticate");
        if (reply.error () == QNetworkReply.AuthenticationRequiredError
            && (www_authenticate_header.starts_with ("Basic") || www_authenticate_header.starts_with ("Bearer"))) {
            _result_get = Basic;
        } else {
            _result_get = LoginFlowV2;
        }
        _get_done = true;
        check_all_done ();
    });
    connect (propfind, &SimpleNetworkJob.finished_signal, this, [this] (QNetworkReply reply) {
        var auth_challenge = reply.raw_header ("WWW-Authenticate").to_lower ();
        if (auth_challenge.contains ("bearer ")) {
            _result_propfind = OAuth;
        } else {
            if (auth_challenge.is_empty ()) {
                GLib.warn (lc_determine_auth_type_job) << "Did not receive WWW-Authenticate reply to auth-test PROPFIND";
            } else {
                GLib.warn (lc_determine_auth_type_job) << "Unknown WWW-Authenticate reply to auth-test PROPFIND:" << auth_challenge;
            }
            _result_propfind = Basic;
        }
        _propfind_done = true;
        check_all_done ();
    });
    connect (old_flow_required, &JsonApiJob.json_received, this, [this] (QJsonDocument &json, int status_code) {
        if (status_code == 200) {
            _result_old_flow = LoginFlowV2;

            var data = json.object ().value ("ocs").to_object ().value ("data").to_object ().value ("capabilities").to_object ();
            var gs = data.value ("globalscale");
            if (gs != QJsonValue.Undefined) {
                var flow = gs.to_object ().value ("desktoplogin");
                if (flow != QJsonValue.Undefined) {
                    if (flow.to_int () == 1) {
#ifdef WITH_WEBENGINE
                        _result_old_flow = WebViewFlow;
#else // WITH_WEBENGINE
                        GLib.warn (lc_determine_auth_type_job) << "Server does only support flow1, but this client was compiled without support for flow1";
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

    old_flow_required.on_start ();
}

void DetermineAuthTypeJob.check_all_done () {
    // Do not conitunue until eve
    if (!_get_done || !_propfind_done || !_old_flow_done) {
        return;
    }

    Q_ASSERT (_result_get != NoAuthType);
    Q_ASSERT (_result_propfind != NoAuthType);
    Q_ASSERT (_result_old_flow != NoAuthType);

    var result = _result_propfind;

#ifdef WITH_WEBENGINE
    // WebViewFlow > OAuth > Basic
    if (_account.server_version_int () >= Account.make_server_version (12, 0, 0)) {
        result = WebViewFlow;
    }
#endif // WITH_WEBENGINE

    // LoginFlowV2 > WebViewFlow > OAuth > Basic
    if (_account.server_version_int () >= Account.make_server_version (16, 0, 0)) {
        result = LoginFlowV2;
    }

#ifdef WITH_WEBENGINE
    // If we determined that we need the webview flow (GS for example) then we switch to that
    if (_result_old_flow == WebViewFlow) {
        result = WebViewFlow;
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

SimpleNetworkJob.SimpleNetworkJob (AccountPointer account, GLib.Object parent)
    : AbstractNetworkJob (account, "", parent) {
}

QNetworkReply *SimpleNetworkJob.start_request (GLib.ByteArray verb, GLib.Uri url,
    QNetworkRequest req, QIODevice request_body) {
    var reply = send_request (verb, url, req, request_body);
    on_start ();
    return reply;
}

bool SimpleNetworkJob.on_finished () {
    emit finished_signal (reply ());
    return true;
}

DeleteApiJob.DeleteApiJob (AccountPointer account, string path, GLib.Object parent)
    : AbstractNetworkJob (account, path, parent) {

}

void DeleteApiJob.on_start () {
    QNetworkRequest req;
    req.set_raw_header ("OCS-APIREQUEST", "true");
    GLib.Uri url = Utility.concat_url_path (account ().url (), path ());
    send_request ("DELETE", url, req);
    AbstractNetworkJob.on_start ();
}

bool DeleteApiJob.on_finished () {
    q_c_info (lc_json_api_job) << "JsonApiJob of" << reply ().request ().url () << "FINISHED WITH STATUS"
                         << reply ().error ()
                         << (reply ().error () == QNetworkReply.NoError ? QLatin1String ("") : error_string ());

    int http_status = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).to_int ();

    if (reply ().error () != QNetworkReply.NoError) {
        GLib.warn (lc_json_api_job) << "Network error : " << path () << error_string () << http_status;
        emit result (http_status);
        return true;
    }

    const var reply_data = string.from_utf8 (reply ().read_all ());
    q_c_info (lc_json_api_job ()) << "TMX Delete Job" << reply_data;
    emit result (http_status);
    return true;
}

void fetch_private_link_url (AccountPointer account, string remote_path,
    const GLib.ByteArray numeric_file_id, GLib.Object target,
    std.function<void (string url)> target_fun) {
    string old_url;
    if (!numeric_file_id.is_empty ())
        old_url = account.deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded);

    // Retrieve the new link by PROPFIND
    var job = new PropfindJob (account, remote_path, target);
    job.set_properties (
        GLib.List<GLib.ByteArray> ()
        << "http://owncloud.org/ns:fileid" // numeric file id for fallback private link generation
        << "http://owncloud.org/ns:privatelink");
    job.on_set_timeout (10 * 1000);
    GLib.Object.connect (job, &PropfindJob.result, target, [=] (QVariantMap &result) {
        var private_link_url = result["privatelink"].to_"";
        var numeric_file_id = result["fileid"].to_byte_array ();
        if (!private_link_url.is_empty ()) {
            target_fun (private_link_url);
        } else if (!numeric_file_id.is_empty ()) {
            target_fun (account.deprecated_private_link_url (numeric_file_id).to_string (GLib.Uri.FullyEncoded));
        } else {
            target_fun (old_url);
        }
    });
    GLib.Object.connect (job, &PropfindJob.finished_with_error, target, [=] (QNetworkReply *) {
        target_fun (old_url);
    });
    job.on_start ();
}

} // namespace Occ
