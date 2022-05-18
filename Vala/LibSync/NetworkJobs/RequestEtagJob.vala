namespace Occ {
namespace LibSync {

/***********************************************************
@class RequestEtagJob

@brief The RequestEtagJob class

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class RequestEtagJob : AbstractNetworkJob {

    internal signal void signal_etag_retrieved (string etag, GLib.DateTime time);
    internal signal void signal_finished_with_result (Result<T, HttpError><string> etag);

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
        buf.open (GLib.IODevice.ReadOnly);
        // assumes ownership
        send_request ("PROPFIND", make_dav_url (path), request, buf);

        if (this.reply.error != GLib.InputStream.NoError) {
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
            GLib.XmlStreamReader reader = new GLib.XmlStreamReader (this.reply);
            reader.add_extra_namespace_declaration (GLib.XmlStreamNamespaceDeclaration ("d", "DAV:"));
            string etag;
            while (!reader.at_end ()) {
                GLib.XmlStreamReader.TokenType type = reader.read_next ();
                if (type == GLib.XmlStreamReader.StartElement && reader.namespace_uri () == "DAV:") {
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
            /* emit */ etag_retrieved (etag, GLib.DateTime.from_string (string.from_utf8 (this.response_timestamp), GLib.RFC2822Date));
            signal_finished_with_result (etag);
        } else {
            HttpError error;
            error.code = http_code;
            error.message = this.error_string;
            signal_finished_with_result (error);
        }
        return true;
    }

} // class RequestEtagJob

} // namespace LibSync
} // namespace Occ
