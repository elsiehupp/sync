/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

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
    private QMap<GLib.ByteArray, GLib.ByteArray> this.properties;






    ProppatchJob.ProppatchJob (AccountPointer account, string path, GLib.Object parent)
        : AbstractNetworkJob (account, path, parent) {
    }

    void ProppatchJob.on_start () {
        if (this.properties.is_empty ()) {
            GLib.warn (lc_proppatch_job) << "Proppatch with no properties!";
        }
        Soup.Request req;

        GLib.ByteArray prop_str;
        QMapIterator<GLib.ByteArray, GLib.ByteArray> it (this.properties);
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

        var buf = new Soup.Buffer (this);
        buf.set_data (xml);
        buf.open (QIODevice.ReadOnly);
        send_request ("PROPPATCH", make_dav_url (path ()), req, buf);
        AbstractNetworkJob.on_start ();
    }

    void ProppatchJob.set_properties (QMap<GLib.ByteArray, GLib.ByteArray> properties) {
        this.properties = properties;
    }

    QMap<GLib.ByteArray, GLib.ByteArray> ProppatchJob.properties () {
        return this.properties;
    }

    bool ProppatchJob.on_finished () {
        q_c_info (lc_proppatch_job) << "PROPPATCH of" << reply ().request ().url () << "FINISHED WITH STATUS"
                            << reply_status_"";

        int http_result_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        if (http_result_code == 207) {
            /* emit */ success ();
        } else {
            GLib.warn (lc_proppatch_job) << "*not* successful, http result code is" << http_result_code
                                    << (http_result_code == 302 ? reply ().header (Soup.Request.LocationHeader).to_string () : QLatin1String (""));
            /* emit */ finished_with_error ();
        }
        return true;
    }

};