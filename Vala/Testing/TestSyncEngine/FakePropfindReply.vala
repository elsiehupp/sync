/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class FakePropfindReply : FakeReply {

    /***********************************************************
    ***********************************************************/
    public string payload;

    /***********************************************************
    ***********************************************************/
    public FakePropfindReply (FileInfo remote_root_file_info, Soup.Operation operation, Soup.Request request) {
        //  base ();
        //  set_request (request);
        //  set_url (request.url);
        //  set_operation (operation);
        //  open (GLib.IODevice.ReadOnly);

        //  string filename = get_file_path_from_url (request.url);
        //  GLib.assert_true (!filename == null); // for root, it should be empty
        //  FileInfo file_info = remote_root_file_info.find (filename);
        //  if (!file_info) {
        //      GLib.Object.invoke_method (this, "respond_404", GLib.QueuedConnection);
        //      return;
        //  }
        //  string prefix = request.url.path.left (request.url.path.size () - filename.size ());

        //  // Don't care about the request and just return a full propfind
        //  string dav_uri = "DAV:";
        //  string oc_uri = "http://owncloud.org/ns";
        //  GLib.OutputStream buffer = new GLib.OutputStream (payload);
        //  buffer.open (GLib.IODevice.WriteOnly);
        //  GLib.XmlStreamWriter xml = new GLib.XmlStreamWriter (buffer);
        //  xml.write_namespace (dav_uri, "d");
        //  xml.write_namespace (oc_uri, "oc");
        //  xml.write_start_document ();
        //  xml.write_start_element (dav_uri, "multistatus");

        //  write_file_response (file_info);
        //  foreach (FileInfo child_file_info in file_info.children) {
        //      write_file_response (child_file_info);
        //  }
        //  xml.write_end_element (); // multistatus
        //  xml.write_end_document ();

        //  GLib.Object.invoke_method (this, "respond", GLib.QueuedConnection);
    }


    private void write_file_response (FileInfo file_info) {
        //  xml.write_start_element (dav_uri, "response");

        //  var url = GLib.Uri.to_percent_encoding (file_info.absolute_path, "/");
        //  if (!url.has_suffix (char ("/"))) {
        //      url.append (char ("/"));
        //  }
        //  string href = Utility.concat_url_path (prefix, url).path;
        //  xml.write_text_element (dav_uri, "href", href);
        //  xml.write_start_element (dav_uri, "propstat");
        //  xml.write_start_element (dav_uri, "prop");

        //  if (file_info.is_directory) {
        //      xml.write_start_element (dav_uri, "resourcetype");
        //      xml.write_empty_element (dav_uri, "collection");
        //      xml.write_end_element (); // resourcetype
        //  } else {
        //      xml.write_empty_element (dav_uri, "resourcetype");
        //  }

        //  var gmt_date = file_info.last_modified.to_utc ();
        //  var string_date = GLib.Locale.c ().to_string (gmt_date, "ddd, dd MMM yyyy HH:mm:ss 'GMT'");
        //  xml.write_text_element (dav_uri, "getlastmodified", string_date);
        //  xml.write_text_element (dav_uri, "getcontentlength", file_info.size.to_string ());
        //  xml.write_text_element (dav_uri, "getetag", "\"%1\"".printf (file_info.etag));
        //  xml.write_text_element (oc_uri, "permissions", !file_info.permissions == null ? file_info.permissions.to_string () : file_info.is_shared ? "SRDNVCKW": "RDNVCKW");
        //  xml.write_text_element (oc_uri, "identifier", file_info.file_identifier);
        //  xml.write_text_element (oc_uri, "checksums", file_info.checksums);
        //  buffer.write (file_info.extra_dav_properties);
        //  xml.write_end_element (); // prop
        //  xml.write_text_element (dav_uri, "status", "HTTP/1.1 200 OK");
        //  xml.write_end_element (); // propstat
        //  xml.write_end_element (); // response
    }


    /***********************************************************
    ***********************************************************/
    public void respond () {
        //  set_header (Soup.Request.ContentLengthHeader, payload.size ());
        //  set_header (Soup.Request.ContentTypeHeader, "application/xml; charset=utf-8");
        //  set_attribute (Soup.Request.HttpStatusCodeAttribute, 207);
        //  set_finished (true);
        //  signal_meta_data_changed ();
        //  if (bytes_available ()) {
        //      signal_ready_read ();
        //  }
        //  signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public void respond_404 () {
        //  set_attribute (Soup.Request.HttpStatusCodeAttribute, 404);
        //  set_error (InternalServerError, "Not Found");
        //  signal_meta_data_changed ();
        //  signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override bool on_signal_abort () {
        //  return false; // only run once
    }


    /***********************************************************
    ***********************************************************/
    public override int64 bytes_available () {
        //  return payload.size () + GLib.IODevice.bytes_available ();
    }


    /***********************************************************
    ***********************************************************/
    public override int64 read_data (char *data, int64 maxlen) {
        //  int64 len = std.min ((int64) payload.size (), maxlen);
        //  std.copy (payload.cbegin (), payload.cbegin () + len, data);
        //  payload.remove (0, (int) (len));
        //  return len;
    }

} // class FakePropfindReply
} // namespace Testing
} // namespace Occ
