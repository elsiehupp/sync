namespace Occ {
namespace LibSync {

/***********************************************************
@brief The Soup.ClientContext class

@author Krzesimir Nowak <krzesimir@endocode.com>

@copyright GPLv3 or Later
***********************************************************/
public class AccessManager { //: Soup.Session {

    //  /***********************************************************
    //  ***********************************************************/
    //  public AccessManager (GLib.Object parent = new GLib.Object ()) {
    //      base (parent);

    //      cookie_jar (new CookieJar ());
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public static string generate_request_id () {
    //      return GLib.Uuid.create_uuid ().to_byte_array (GLib.Uuid.WithoutBraces);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  protected GLib.InputStream create_request (Soup.Session.Operation operation, Soup.Request request, GLib.OutputStream outgoing_data = null) {
    //      Soup.Request new_request = new Soup.Request (request);

    //      // Respect request specific user agent if any
    //      if (!new_request.header (Soup.Request.UserAgentHeader).is_valid) {
    //          new_request.header (Soup.Request.UserAgentHeader, Utility.user_agent_string ());
    //      }

    //      // Some firewalls reject requests that have a "User-Agent" but no "Accept" header
    //      new_request.raw_header ("Accept", "*/*");

    //      string verb = new_request.attribute (Soup.Request.CustomVerbAttribute).to_byte_array ();
    //      // For PROPFIND (assumed to be a WebDAV operation), set xml/utf8 as content type/encoding
    //      // This needs extension
    //      if (verb == "PROPFIND") {
    //          new_request.header (Soup.Request.ContentTypeHeader, "text/xml; charset=utf-8");
    //      }

    //      // Generate a new request identifier
    //      string request_id = generate_request_id ();
    //      GLib.info (operation + verb + new_request.url.to_string () + "has X-Request-ID " + request_id);
    //      new_request.raw_header ("X-Request-ID", request_id);

    //  // #if GLib.T_VERSION >= GLib.T_VERSION_CHECK (5, 9, 4)
    //      // only enable HTTP2 with Qt 5.9.4 because old Qt have too many bugs (e.g. GLib.TBUG-64359 is fixed in >= Qt 5.9.4)
    //      if (new_request.url.scheme () == "https") { // Not for "http" { //: GLib.TBUG-61397
    //          // http2 seems to cause issues, as with our recommended server setup we don't support http2, disable it by default for now
    //          bool http2_enabled_env = q_environment_variable_int_value ("OWNCLOUD_HTTP2_ENABLED") == 1;

    //          new_request.attribute (Soup.Request.HTTP2AllowedAttribute, http2_enabled_env);
    //      }
    //  // #endif

    //      var reply = Soup.Session.create_request (operation, new_request, outgoing_data);
    //      HttpLogger.log_request (reply, operation, outgoing_data);
    //      return reply;
    //  }

} // class Soup.ClientContext

} // namespace LibSync
} // namespace Occ
    //  