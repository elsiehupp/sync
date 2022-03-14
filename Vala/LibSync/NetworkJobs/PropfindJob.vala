/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@brief The PropfindJob class

Setting the desired properties with properties

Note that this job is only for querying one item.
There is also the LsColJob which can be used to list collections

@ingroup libsync
***********************************************************/
public class PropfindJob : AbstractNetworkJob {

    /***********************************************************
    Used to specify which properties shall be retrieved.

    The properties can
     - contain no colon : they refer to a property in the DAV :
     - contain a colon : and thus specify an explicit namespace,
       e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
    ***********************************************************/
    public GLib.List<string> properties;

    signal void signal_result (GLib.HashTable<string, GLib.Variant> values);
    signal void finished_with_error (Soup.Reply reply = null);

    /***********************************************************
    ***********************************************************/
    public PropfindJob.for_account (unowned Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public void start () {
        GLib.List<string> properties = this.properties;

        if (properties.is_empty ()) {
            GLib.warning ("Propfind with no properties!");
        }
        Soup.Request request;
        // Always have a higher priority than the propagator because we use this from the UI
        // and really want this to be done first (no matter what internal scheduling QNAM uses).
        // Also possibly useful for avoiding false timeouts.
        request.priority (Soup.Request.HighPriority);
        request.raw_header ("Depth", "0");
        string prop_str;
        foreach (string prop in properties) {
            if (prop.contains (':')) {
                int col_index = prop.last_index_of (":");
                prop_str += "    <" + prop.mid (col_index + 1) + " xmlns=\"" + prop.left (col_index) + "\" />\n";
            } else {
                prop_str += "    <d:" + prop + " />\n";
            }
        }
        string xml = "<?xml version=\"1.0\" ?>\n"
                        + "<d:propfind xmlns:d=\"DAV:\">\n"
                        + "  <d:prop>\n"
                        + prop_str + "  </d:prop>\n"
                        + "</d:propfind>\n";

        var buf = new Soup.Buffer (this);
        buf.data (xml);
        buf.open (QIODevice.ReadOnly);
        send_request ("PROPFIND", make_dav_url (path ()), request, buf);

        AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        GLib.info ("PROPFIND of" + reply ().request ().url ()
                  + " finished with status " + reply_status_string ());

        int http_result_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        if (http_result_code == 207) {
            // Parse DAV response
            QXmlStreamReader reader = new QXmlStreamReader (reply ());
            reader.add_extra_namespace_declaration (QXmlStreamNamespaceDeclaration ("d", "DAV:"));

            GLib.HashTable<string, GLib.Variant> items;
            // introduced to nesting is ignored
            GLib.List<string> current_element; // should be a LIFO stack

            while (!reader.at_end ()) {
                QXmlStreamReader.TokenType type = reader.read_next ();
                if (type == QXmlStreamReader.StartElement) {
                    if (!current_element.is_empty () && current_element.top () == "prop") {
                        items.insert (reader.name ().to_string (), reader.read_element_text (QXmlStreamReader.SkipChildElements));
                    } else {
                        current_element.push (reader.name ().to_string ());
                    }
                }
                if (type == QXmlStreamReader.EndElement) {
                    if (current_element.top () == reader.name ()) {
                        current_element.pop ();
                    }
                }
            }
            if (reader.has_error ()) {
                GLib.warning ("XML parser error: " + reader.error_string ());
                /* emit */ finished_with_error (reply ());
            } else {
                /* emit */ signal_result (items);
            }
        } else {
            GLib.warning ("*not* successful, http result code is" + http_result_code
                + (http_result_code == 302 ? reply ().header (Soup.Request.LocationHeader).to_string (): ""));
            /* emit */ finished_with_error (reply ());
        }
        return true;
    }

} // class PropfindJob

} // namespace LibSync
} // namespace Occ
