/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

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
    void result (QVariantMap values);
    void finished_with_error (Soup.Reply reply = nullptr);


    /***********************************************************
    ***********************************************************/
    private on_ bool on_finished () override;

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.List<GLib.ByteArray> this.properties;






    PropfindJob.PropfindJob (AccountPointer account, string path, GLib.Object parent)
        : AbstractNetworkJob (account, path, parent) {
    }

    void PropfindJob.on_start () {
        GLib.List<GLib.ByteArray> properties = this.properties;

        if (properties.is_empty ()) {
            GLib.warn (lc_ls_col_job) << "Propfind with no properties!";
        }
        Soup.Request req;
        // Always have a higher priority than the propagator because we use this from the UI
        // and really want this to be done first (no matter what internal scheduling QNAM uses).
        // Also possibly useful for avoiding false timeouts.
        req.set_priority (Soup.Request.HighPriority);
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

        var buf = new Soup.Buffer (this);
        buf.set_data (xml);
        buf.open (QIODevice.ReadOnly);
        send_request ("PROPFIND", make_dav_url (path ()), req, buf);

        AbstractNetworkJob.on_start ();
    }

    void PropfindJob.set_properties (GLib.List<GLib.ByteArray> properties) {
        this.properties = properties;
    }

    GLib.List<GLib.ByteArray> PropfindJob.properties () {
        return this.properties;
    }

    bool PropfindJob.on_finished () {
        q_c_info (lc_propfind_job) << "PROPFIND of" << reply ().request ().url () << "FINISHED WITH STATUS"
                            << reply_status_"";

        int http_result_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

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
                        items.insert (reader.name ().to_string (), reader.read_element_text (QXmlStreamReader.SkipChildElements));
                    } else {
                        cur_element.push (reader.name ().to_string ());
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
                /* emit */ finished_with_error (reply ());
            } else {
                /* emit */ result (items);
            }
        } else {
            GLib.warn (lc_propfind_job) << "*not* successful, http result code is" << http_result_code
                                    << (http_result_code == 302 ? reply ().header (Soup.Request.LocationHeader).to_string () : QLatin1String (""));
            /* emit */ finished_with_error (reply ());
        }
        return true;
    }

};