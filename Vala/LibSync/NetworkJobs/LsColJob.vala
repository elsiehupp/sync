/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

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
    public GLib.HashMap<string, ExtraFolderInfo> this.folder_infos;


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
    void directory_listing_subfolders (string[] items);
    void directory_listing_iterated (string name, GLib.HashMap<string, string> properties);
    void finished_with_error (Soup.Reply reply);
    void finished_without_error ();


    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.List<GLib.ByteArray> this.properties;
    private GLib.Uri this.url; // Used instead of path () if the url is specified in the constructor





    LsColJob.LsColJob (AccountPointer account, string path, GLib.Object parent)
        : AbstractNetworkJob (account, path, parent) {
    }

    LsColJob.LsColJob (AccountPointer account, GLib.Uri url, GLib.Object parent)
        : AbstractNetworkJob (account, "", parent)
        , this.url (url) {
    }

    void LsColJob.set_properties (GLib.List<GLib.ByteArray> properties) {
        this.properties = properties;
    }

    GLib.List<GLib.ByteArray> LsColJob.properties () {
        return this.properties;
    }

    void LsColJob.on_start () {
        GLib.List<GLib.ByteArray> properties = this.properties;

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

        Soup.Request req;
        req.set_raw_header ("Depth", "1");
        GLib.ByteArray xml ("<?xml version=\"1.0\" ?>\n"
                    "<d:propfind xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\">\n"
                    "  <d:prop>\n"
            + prop_str + "  </d:prop>\n"
                        "</d:propfind>\n");
        var buf = new Soup.Buffer (this);
        buf.set_data (xml);
        buf.open (QIODevice.ReadOnly);
        if (this.url.is_valid ()) {
            send_request ("PROPFIND", this.url, req, buf);
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

        string content_type = reply ().header (Soup.Request.ContentTypeHeader).to_string ();
        int http_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
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
};