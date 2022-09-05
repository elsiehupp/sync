
namespace Occ {
namespace LibSync {

/***********************************************************
@class TokenCredentialsAccessManager
***********************************************************/
public class TokenCredentialsAccessManager { //: Soup.ClientContext {

    //  private const TokenCredentials credentials;

    //  //  public friend class TokenCredentials;

    //  public TokenCredentialsAccessManager (TokenCredentials credentials, GLib.Object parent = new GLib.Object ()) {
    //      base (parent);
    //      this.credentials = credentials;
    //  }


    //  protected GLib.InputStream create_request (Operation operation, Soup.Request request, GLib.OutputStream outgoing_data) {
    //      if (this.credentials.user () == "" || this.credentials.password () == "") {
    //          GLib.warning ("Empty user/password provided!");
    //      }

    //      Soup.Request request = new Soup.Request (request);

    //      string cred_hash = (this.credentials.user ().to_utf8 () + ":" + this.credentials.password ().to_utf8 ()).to_base64 ();
    //      request.raw_header ("Authorization", "Basic " + cred_hash);

    //      // A pre-authenticated cookie
    //      string token = this.credentials.token.to_utf8 ();
    //      if (token.length > 0) {
    //          raw_cookie (token, request.url);
    //      }

    //      return Soup.ClientContext.create_request (operation, request, outgoing_data);
    //  }

} // class TokenCredentialsAccessManager

} // namespace LibSync
} // namespace Occ
