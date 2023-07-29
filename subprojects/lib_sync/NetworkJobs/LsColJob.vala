namespace Occ {
namespace LibSync {

/***********************************************************
@class LscolJob

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class LscolJob : AbstractNetworkJob {

    public GLib.HashTable<string, ExtraFolderInfo> folder_infos;

    /***********************************************************
    Used instead of this.path if the url is specified in the constructor
    ***********************************************************/
    private GLib.Uri url;

    /***********************************************************
    Used to specify which properties shall be retrieved.

    The properties can
    //   - contain no colon : they refer to a property in the DAV :
    //   - contain a colon : and thus specify an explicit namespace,
        // e.g. "ns:with:colons:bar", which is "bar" in the "ns:with:colons" namespace
    ***********************************************************/
    public GLib.List<string> properties;


    internal signal void signal_directory_listing_subfolders (GLib.List<string> items);
    internal signal void signal_directory_listing_iterated (string name, GLib.HashTable<string, string> properties);
    internal signal void signal_finished_with_error (GLib.InputStream input_stream);
    internal signal void signal_finished_without_error ();


    /***********************************************************
    ***********************************************************/
    public LscolJob.for_path (Account account, string path) {
        //  base (account, path);
    }


    /***********************************************************
    ***********************************************************/
    public LscolJob.for_url (Account account, GLib.Uri url) {
        //  base (account, "");
        //  this.url = url;
    }


    /***********************************************************
    ***********************************************************/
    public new void start () {
        //  GLib.List<string> properties = this.properties;

        //  if (properties.length () == 0) {
        //      GLib.warning ("Propfind with no properties!");
        //  }
        //  string prop_str;
        //  foreach (string prop in properties) {
        //      if (prop.contains (":")) {
        //          int col_index = prop.last_index_of (":");
        //          var ns = prop.left (col_index);
        //          if (ns == "http://owncloud.org/ns") {
        //              prop_str += "    <oc:" + prop.mid (col_index + 1) + " />\n";
        //          } else {
        //              prop_str += "    <" + prop.mid (col_index + 1) + " xmlns=\"" + ns + "\" />\n";
        //          }
        //      } else {
        //          prop_str += "    <d:" + prop + " />\n";
        //      }
        //  }

        //  Soup.Request request = new Soup.Request ();
        //  request.raw_header ("Depth", "1");
        //  string xml = "<?xml version=\"1.0\" ?>\n"
        //                     + "<d:propfind xmlns:d=\"DAV:\" xmlns:oc=\"http://owncloud.org/ns\">\n"
        //                     + "  <d:prop>\n"
        //                     + prop_str.bytes () + "  </d:prop>\n"
        //                     + "</d:propfind>\n";
        //  var buf = new Soup.Buffer (this);
        //  buf.data (xml);
        //  buf.open (GLib.IODevice.ReadOnly);
        //  if (this.url.is_valid != null) {
        //      send_request ("PROPFIND", this.url, request, buf);
        //  } else {
        //      send_request ("PROPFIND", make_dav_url (path), request, buf);
        //  }
        //  AbstractNetworkJob.start ();
    }


    /***********************************************************
    TODO: Instead of doing all in this slot, we should
    iteratively parse in ready_read (). This would allow us to
    be more asynchronous in processing while data is coming from
    the network, not all in one big blob at the end.
    ***********************************************************/
    private bool on_signal_finished () {
        //  GLib.info ("LSCOL of" + this.input_stream.request ().url
        //      + " finished with status " + input_stream_status_string ());

        //  string content_type = this.input_stream.header (Soup.Request.ContentTypeHeader).to_string ();
        //  int http_code = this.input_stream.attribute (Soup.Request.HttpStatusCodeAttribute).to_int ();
        //  if (http_code == 207 && content_type.contains ("application/xml; charset=utf-8")) {
        //      LscolXMLParser lscol_xml_parser;
        //      lscol_xml_parser.signal_directory_listing_subfolders.connect (
        //          this.on_signal_directory_listing_subfolders
        //      );
        //      lscol_xml_parser.signal_directory_listing_iterated.connect (
        //          this.on_signal_directory_listing_iterated
        //      );
        //      lscol_xml_parser.signal_finished_with_error.connect (
        //          this.on_signal_finished_with_error
        //      );
        //      lscol_xml_parser.signal_finished_without_error.connect (
        //          this.on_signal_finished_without_error
        //      );

        //      string expected_path = this.input_stream.request ().url.path; // something like "/owncloud/remote.php/dav/folder"
        //      if (!lscol_xml_parser.parse (this.input_stream.read_all (), this.folder_infos, expected_path)) {
        //          // XML parse error
        //          signal_finished_with_error (this.input_stream);
        //      }
        //  } else {
        //      // wrong content type, wrong HTTP code or any other network error
        //      signal_finished_with_error (this.input_stream);
        //  }

        //  return true;
    }

} // class LscolJob

} // namespace LibSync
} // namespace Occ
