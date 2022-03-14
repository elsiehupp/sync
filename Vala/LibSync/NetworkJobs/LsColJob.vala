/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace LibSync {

public class LsColJob : AbstractNetworkJob {

    public GLib.HashTable<string, ExtraFolderInfo> folder_infos;

    /***********************************************************
    Used instead of path () if the url is specified in the constructor
    ***********************************************************/
    private GLib.Uri url;

    /***********************************************************
    Used to specify which properties shall be retrieved.

    The properties can
     - contain no colon : they refer to a property in the DAV :
     - contain a colon : and thus specify an explicit namespace,
       e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
    ***********************************************************/
    public GLib.List<string> properties;


    signal void directory_listing_subfolders (string[] items);
    signal void directory_listing_iterated (string name, GLib.HashTable<string, string> properties);
    signal void finished_with_error (Soup.Reply reply);
    signal void finished_without_error ();


    /***********************************************************
    ***********************************************************/
    public LsColJob.for_path (unowned Account account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public LsColJob.for_url (unowned Account account, GLib.Uri url, GLib.Object parent = new GLib.Object ()) {
        base (account, "", parent);
        this.url = url;
    }


    /***********************************************************
    ***********************************************************/
    public void start () {
        GLib.List<string> properties = this.properties;

        if (properties.is_empty ()) {
            GLib.warning ("Propfind with no properties!");
        }
        string prop_str;
        foreach (string prop in properties) {
            if (prop.contains (':')) {
                int col_index = prop.last_index_of (":");
                var ns = prop.left (col_index);
                if (ns == "http://owncloud.org/ns") {
                    prop_str += "    <oc:" + prop.mid (col_index + 1) + " />\n";
                } else {
                    prop_str += "    <" + prop.mid (col_index + 1) + " xmlns=\"" + ns + "\" />\n";
                }
            } else {
                prop_str += "    <d:" + prop + " />\n";
            }
        }

        Soup.Request request;
        request.raw_header ("Depth", "1");
        string xml = "<?xml version=\"1.0\" ?>\n"
                           + "<d:propfind xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\">\n"
                           + "  <d:prop>\n"
                           + prop_str.bytes () + "  </d:prop>\n"
                           + "</d:propfind>\n";
        var buf = new Soup.Buffer (this);
        buf.data (xml);
        buf.open (QIODevice.ReadOnly);
        if (this.url.is_valid ()) {
            send_request ("PROPFIND", this.url, request, buf);
        } else {
            send_request ("PROPFIND", make_dav_url (path ()), request, buf);
        }
        AbstractNetworkJob.start ();
    }


    /***********************************************************
    TODO: Instead of doing all in this slot, we should
    iteratively parse in ready_read (). This would allow us to
    be more asynchronous in processing while data is coming from
    the network, not all in one big blob at the end.
    ***********************************************************/
    private bool on_signal_finished () {
        GLib.info ("LSCOL of" + reply ().request ().url ()
            + " finished with status " + reply_status_string ());

        string content_type = reply ().header (Soup.Request.ContentTypeHeader).to_string ();
        int http_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        if (http_code == 207 && content_type.contains ("application/xml; charset=utf-8")) {
            LsColXMLParser parser;
            connect (&parser, LsColXMLParser.directory_listing_subfolders,
                this, LsColJob.directory_listing_subfolders);
            connect (&parser, LsColXMLParser.directory_listing_iterated,
                this, LsColJob.directory_listing_iterated);
            connect (&parser, LsColXMLParser.finished_with_error,
                this, LsColJob.finished_with_error);
            connect (&parser, LsColXMLParser.finished_without_error,
                this, LsColJob.finished_without_error);

            string expected_path = reply ().request ().url ().path (); // something like "/owncloud/remote.php/dav/folder"
            if (!parser.parse (reply ().read_all (), this.folder_infos, expected_path)) {
                // XML parse error
                /* emit */ finished_with_error (reply ());
            }
        } else {
            // wrong content type, wrong HTTP code or any other network error
            /* emit */ finished_with_error (reply ());
        }

        return true;
    }

} // class LsColJob

} // namespace LibSync
} // namespace Occ
