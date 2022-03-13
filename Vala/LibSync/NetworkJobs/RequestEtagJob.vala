/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The RequestEtagJob class
***********************************************************/
class RequestEtagJob : AbstractNetworkJob {

    signal void on_signal_etag_retrieved (GLib.ByteArray etag, GLib.DateTime time);
    signal void finished_with_result (HttpResult<GLib.ByteArray> etag);

    /***********************************************************
    ***********************************************************/
    public RequestEtagJob.for_account (unowned Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public new void on_signal_start () {
        Soup.Request request;
        request.raw_header ("Depth", "0");

        GLib.ByteArray xml = "<?xml version=\"1.0\" ?>\n"
                           + "<d:propfind xmlns:d=\"DAV:\">\n"
                           + "  <d:prop>\n"
                           + "    <d:getetag/>\n"
                           + "  </d:prop>\n"
                           + "</d:propfind>\n";
        var buf = new Soup.Buffer (this);
        buf.data (xml);
        buf.open (QIODevice.ReadOnly);
        // assumes ownership
        send_request ("PROPFIND", make_dav_url (path ()), request, buf);

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warning ("Request network error: " + reply ().error_string ());
        }
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        GLib.info ("Request Etag of" + reply ().request ().url ()
            + " finished with status " +  reply_status_string ());

        var http_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (http_code == 207) {
            // Parse DAV response
            QXmlStreamReader reader = new QXmlStreamReader (reply ());
            reader.add_extra_namespace_declaration (QXmlStreamNamespaceDeclaration ("d", "DAV:"));
            GLib.ByteArray etag;
            while (!reader.at_end ()) {
                QXmlStreamReader.TokenType type = reader.read_next ();
                if (type == QXmlStreamReader.StartElement && reader.namespace_uri () == "DAV:") {
                    string name = reader.name ().to_string ();
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
            /* emit */ etag_retrieved (etag, GLib.DateTime.from_string (string.from_utf8 (this.response_timestamp), Qt.RFC2822Date));
            /* emit */ finished_with_result (etag);
        } else {
            HttpError error;
            error.code = http_code;
            error.message = error_string ();
            /* emit */ finished_with_result (error);
        }
        return true;
    }

} // class RequestEtagJob

} // namespace LibSync
} // namespace Occ
