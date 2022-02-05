/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief The RequestEtagJob class
***********************************************************/
class RequestEtagJob : AbstractNetworkJob {

    signal void on_etag_retrieved (GLib.ByteArray etag, GLib.DateTime time);
    signal void finished_with_result (HttpResult<GLib.ByteArray> etag);

    /***********************************************************
    ***********************************************************/
    public RequestEtagJob (AccountPointer account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public void on_start () {
        Soup.Request req;
        req.set_raw_header ("Depth", "0");

        GLib.ByteArray xml ("<?xml version=\"1.0\" ?>\n"
                    "<d:propfind xmlns:d=\"DAV:\">\n"
                    "  <d:prop>\n"
                    "    <d:getetag/>\n"
                    "  </d:prop>\n"
                    "</d:propfind>\n");
        var buf = new Soup.Buffer (this);
        buf.set_data (xml);
        buf.open (QIODevice.ReadOnly);
        // assumes ownership
        send_request ("PROPFIND", make_dav_url (path ()), req, buf);

        if (reply ().error () != Soup.Reply.NoError) {
            GLib.warn (lc_etag_job) << "request network error : " << reply ().error_string ();
        }
        AbstractNetworkJob.on_start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_finished () {
        GLib.Info (lc_etag_job) << "Request Etag of" << reply ().request ().url () << "FINISHED WITH STATUS"
                        <<  reply_status_string ();

        var http_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (http_code == 207) {
            // Parse DAV response
            QXmlStreamReader reader (reply ());
            reader.add_extra_namespace_declaration (QXmlStreamNamespaceDeclaration (QStringLiteral ("d"), QStringLiteral ("DAV:")));
            GLib.ByteArray etag;
            while (!reader.at_end ()) {
                QXmlStreamReader.TokenType type = reader.read_next ();
                if (type == QXmlStreamReader.StartElement && reader.namespace_uri () == QLatin1String ("DAV:")) {
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
            /* emit */ finished_with_result (HttpError {
                http_code, error_string ()
            });
        }
        return true;
    }

} // class RequestEtagJob

} // namespace Occ
