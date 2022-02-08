/***********************************************************
Copyright (C) by Klaas Freitag <freitag@kde.org>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/
namespace Occ {

class HttpCredentialsAccessManager : AccessManager {

    /***********************************************************
    The credentials object dies along with the account, while
    the QNAM might outlive both.
    ***********************************************************/
    private QPointer<const HttpCredentials> this.credentials;


    public HttpCredentialsAccessManager (HttpCredentials credentials, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.credentials = credentials;
    }


    protected Soup.Reply create_request (Operation op, Soup.Request request, QIODevice outgoing_data) {
        Soup.Request reques (request);
        if (!reques.attribute (HttpCredentials.DontAddCredentialsAttribute).to_bool ()) {
            if (this.credentials && !this.credentials.password ().is_empty ()) {
                if (this.credentials.is_using_oauth ()) {
                    reques.raw_header ("Authorization", "Bearer " + this.credentials.password ().to_utf8 ());
                } else {
                    GLib.ByteArray cred_hash = GLib.ByteArray (this.credentials.user ().to_utf8 () + ":" + this.credentials.password ().to_utf8 ()).to_base64 ();
                    reques.raw_header ("Authorization", "Basic " + cred_hash);
                }
            } else if (!request.url ().password ().is_empty ()) {
                // Typically the requests to get or refresh the OAuth access token. The client
                // credentials are put in the URL from the code making the request.
                GLib.ByteArray cred_hash = request.url ().user_info ().to_utf8 ().to_base64 ();
                reques.raw_header ("Authorization", "Basic " + cred_hash);
            }
        }

        if (this.credentials && !this.credentials.client_ssl_key.is_null () && !this.credentials.client_ssl_certificate.is_null ()) {
            // SSL configuration
            QSslConfiguration ssl_configuration = reques.ssl_configuration ();
            ssl_configuration.local_certificate (this.credentials.client_ssl_certificate);
            ssl_configuration.private_key (this.credentials.client_ssl_key);
            reques.ssl_configuration (ssl_configuration);
        }

        var reply = AccessManager.create_request (op, reques, outgoing_data);

        if (this.credentials.is_renewing_oauth_token) {
            // We know this is going to fail, but we have no way to queue it there, so we will
            // simply restart the job after the failure.
            reply.property (NEED_RETRY_C, true);
        }

        return reply;
    }

} // class HttpCredentialsAccessManager

} // namespace Occ
