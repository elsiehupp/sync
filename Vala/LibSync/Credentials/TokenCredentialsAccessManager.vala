
class TokenCredentialsAccessManager : AccessManager {

    private const TokenCredentials credentials;

    //  public friend class TokenCredentials;

    public TokenCredentialsAccessManager (TokenCredentials credentials, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.credentials = credentials;
    }


    protected Soup.Reply create_request (Operation op, Soup.Request request, QIODevice outgoing_data) {
        if (this.credentials.user ().is_empty () || this.credentials.password ().is_empty ()) {
            GLib.warn ("Empty user/password provided!";
        }

        Soup.Request req (request);

        GLib.ByteArray cred_hash = GLib.ByteArray (this.credentials.user ().to_utf8 () + ":" + this.credentials.password ().to_utf8 ()).to_base64 ();
        req.raw_header (GLib.ByteArray ("Authorization"), GLib.ByteArray ("Basic ") + cred_hash);

        // A pre-authenticated cookie
        GLib.ByteArray token = this.credentials.token.to_utf8 ();
        if (token.length () > 0) {
            raw_cookie (token, request.url ());
        }

        return AccessManager.create_request (op, req, outgoing_data);
    }

} // class TokenCredentialsAccessManager

} // namespace Occ
