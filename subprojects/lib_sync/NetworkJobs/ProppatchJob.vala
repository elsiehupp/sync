/***********************************************************
***********************************************************/

namespace Occ {
namespace LibSync {

/***********************************************************
@class ProppatchJob

@brief Send a Proppatch request

Setting the desired p

WARNING : Untested!

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class ProppatchJob : AbstractNetworkJob {

    /***********************************************************
    ***********************************************************/
    GLib.HashTable<string, string> properties {
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

    internal signal void signal_success ();
    internal signal void signal_finished_with_error ();

    /***********************************************************
    ***********************************************************/
    public ProppatchJob.for_account (Account account, string path) {
        //  base (account, path);
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        //  if (this.properties.length == 0) {
        //      GLib.warning ("Proppatch with no properties!");
        //  }
        //  Soup.Request request = new Soup.Request ();

        //  string prop_str;
        //  GLib.MapIterator<string, string> it = new GLib.MapIterator<string, string> (this.properties);
        //  while (it.has_next ()) {
        //      it.next ();
        //      string key_name = it.key ();
        //      string key_namespace;
        //      if (key_name.contains (':')) {
        //          int col_index = key_name.last_index_of (":");
        //          key_namespace = key_name.left (col_index);
        //          key_name = key_name.mid (col_index + 1);
        //      }

        //      prop_str += "    <" + key_name;
        //      if (key_namespace != "") {
        //          prop_str += " xmlns=\"" + key_namespace + "\" ";
        //      }
        //      prop_str += ">";
        //      prop_str += it.value ();
        //      prop_str += "</" + key_name + ">\n";
        //  }
        //  string xml = "<?xml version=\"1.0\" ?>\n"
        //                     + "<d:propertyupdate xmlns:d=\"DAV:\">\n"
        //                     + "  <d:set><d:prop>\n"
        //                     + prop_str.bytes () + "  </d:prop></d:set>\n"
        //                     + "</d:propertyupdate>\n";

        //  var buf = new Soup.Buffer (this);
        //  buf.data (xml);
        //  buf.open (GLib.IODevice.ReadOnly);
        //  send_request ("PROPPATCH", make_dav_url (path), request, buf);
        //  AbstractNetworkJob.start ();
    }


    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        //  GLib.info ("PROPPATCH of" + this.reply.request ().url
        //      + " finished with status " + reply_status_string ());

        //  int http_result_code = this.reply.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();

        //  if (http_result_code == 207) {
        //      signal_success ();
        //  } else {
        //      GLib.warning ("*not* successful, http result code is" + http_result_code
        //          + (http_result_code == 302 ? this.reply.header (Soup.Request.LocationHeader).to_string (): ""));
        //      signal_finished_with_error ();
        //  }
        //  return true;
    }

} // class ProppatchJob

} // namespace LibSync
} // namespace Occ
