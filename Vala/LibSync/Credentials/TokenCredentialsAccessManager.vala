
namespace Occ {
namespace LibSync {

public class TokenCredentialsAccessManager : AccessManager {

    private const TokenCredentials credentials;

    //  public friend class TokenCredentials;

    public TokenCredentialsAccessManager (TokenCredentials credentials, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.credentials = credentials;
    }


    protected Soup.Reply create_request (Operation operation, Soup.Request request, QIODevice outgoing_data) {
        if (this.credentials.user ().is_empty () || this.credentials.password ().is_empty ()) {
            GLib.warning ("Empty user/password provided!";
        }

        Soup.Request request (request);

        string cred_hash = new string (this.credentials.user ().to_utf8 () + ":" + this.credentials.password ().to_utf8 ()).to_base64 ();
        request.raw_header (string ("Authorization"), string ("Basic ") + cred_hash);

        // A pre-authenticated cookie
        string token = this.credentials.token.to_utf8 ();
        if (token.length () > 0) {
            raw_cookie (token, request.url ());
        }

        return AccessManager.create_request (operation, request, outgoing_data);
    }

} // class TokenCredentialsAccessManager

} // namespace LibSync
} // namespace Occ
