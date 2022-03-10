/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

/***********************************************************
@brief Send a Proppatch request

Setting the desired p

WARNING : Untested!

@ingroup libsync
***********************************************************/
class ProppatchJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    GLib.HashTable<GLib.ByteArray, GLib.ByteArray> properties {
        public get {
            return this.properties;
        }
        /***********************************************************
        Used to specify which properties shall be set.

        The property keys can
        - contain no colon : they refer to a property in the DAV :
        - contain a colon : and thus specify an explicit namespace,
        e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
        ***********************************************************/
        public set {
            this.properties = value;
        }
    }

    signal void on_signal_success ();
    signal void finished_with_error ();

    /***********************************************************
    ***********************************************************/
    public ProppatchJob.for_account (AccountPointer account, string path, GLib.Object parent = new GLib.Object ()) {
        base (account, path, parent);
    }


    /***********************************************************
    ***********************************************************/
    public new void on_signal_start () {
        if (this.properties.is_empty ()) {
            GLib.warning ("Proppatch with no properties!");
        }
        Soup.Request request;

        GLib.ByteArray prop_str;
        QMapIterator<GLib.ByteArray, GLib.ByteArray> it = new QMapIterator<GLib.ByteArray, GLib.ByteArray> (this.properties);
        while (it.has_next ()) {
            it.next ();
            GLib.ByteArray key_name = it.key ();
            GLib.ByteArray key_ns;
            if (key_name.contains (':')) {
                int col_index = key_name.last_index_of (":");
                key_ns = key_name.left (col_index);
                key_name = key_name.mid (col_index + 1);
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
                           + "<d:propertyupdate xmlns:d=\"DAV:\">\n"
                           + "  <d:set><d:prop>\n"
                           + prop_str.bytes () + "  </d:prop></d:set>\n"
                           + "</d:propertyupdate>\n";

        var buf = new Soup.Buffer (this);
        buf.data (xml);
        buf.open (QIODevice.ReadOnly);
        send_request ("PROPPATCH", make_dav_url (path ()), request, buf);
        AbstractNetworkJob.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        GLib.info ("PROPPATCH of" + reply ().request ().url ()
            + " finished with status " + reply_status_string ());

        int http_result_code = reply ().attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        if (http_result_code == 207) {
            /* emit */ success ();
        } else {
            GLib.warning ("*not* successful, http result code is" + http_result_code
                + (http_result_code == 302 ? reply ().header (Soup.Request.LocationHeader).to_string (): ""));
            /* emit */ finished_with_error ();
        }
        return true;
    }

} // class ProppatchJob

} // namespace Occ
