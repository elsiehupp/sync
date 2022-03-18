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
public class RequestEtagJob : AbstractNetworkJob {

    internal signal void signal_etag_retrieved (string etag, GLib.DateTime time);
    internal signal void signal_finished_with_result (HttpResult<string> etag);

    /***********************************************************
    ***********************************************************/
    public RequestEtagJob.for_account (Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        Soup.Request request = new Soup.Request ();
        request.raw_header ("Depth", "0");

        string xml = "<?xml version=\"1.0\" ?>\n"
                           + "<d:propfind xmlns:d=\"DAV:\">\n"
                           + "  <d:prop>\n"
                           + "    <d:getetag/>\n"
                           + "  </d:prop>\n"
                           + "</d:propfind>\n";
        var buf = new Soup.Buffer (this);
        buf.data (xml);
        buf.open (QIODevice.ReadOnly);
        // assumes ownership
        send_request ("PROPFIND", make_dav_url (path), request, buf);

        if (this.reply.error != Soup.Reply.NoError) {
            GLib.warning ("Request network error: " + this.reply.error_string);
        }
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        GLib.info ("Request Etag of" + this.reply.request ().url
            + " finished with status " +  reply_status_string ());

        var http_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (http_code == 207) {
            // Parse DAV response
            QXmlStreamReader reader = new QXmlStreamReader (this.reply);
            reader.add_extra_namespace_declaration (QXmlStreamNamespaceDeclaration ("d", "DAV:"));
            string etag;
            while (!reader.at_end ()) {
                QXmlStreamReader.TokenType type = reader.read_next ();
                if (type == QXmlStreamReader.StartElement && reader.namespace_uri () == "DAV:") {
                    string name = reader.name ().to_string ();
                    if (name == "getetag") {
                        var etag_text = reader.read_element_text ();
                        var parsed_tag = parse_etag (etag_text.to_utf8 ());
                        if (!parsed_tag == "") {
                            etag += parsed_tag;
                        } else {
                            etag += etag_text.to_utf8 ();
                        }
                    }
                }
            }
            /* emit */ etag_retrieved (etag, GLib.DateTime.from_string (string.from_utf8 (this.response_timestamp), Qt.RFC2822Date));
            /* emit */ signal_finished_with_result (etag);
        } else {
            HttpError error;
            error.code = http_code;
            error.message = this.error_string;
            /* emit */ signal_finished_with_result (error);
        }
        return true;
    }

} // class RequestEtagJob

} // namespace LibSync
} // namespace Occ
