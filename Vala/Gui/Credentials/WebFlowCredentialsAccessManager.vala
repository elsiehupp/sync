


namespace {
    const char USER_C[] = "user";
    const char CLIENT_CERTIFICATE_PEM_C[] = "this.client_certificate_pem";
    const char CLIENT_KEY_PEM_C[] = "this.client_key_pem";
    const char client_ca_certificate_pemC[] = "this.client_ca_certificate_pem";
} // ns

class WebFlowCredentialsAccessManager : AccessManager {

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentialsAccessManager (WebFlowCredentials credentials, GLib.Object parent = new GLib.Object ())
        : AccessManager (parent)
        this.credentials (credentials) {
    }


    protected Soup.Reply create_request (Operation op, QNetworkRequest request, QIODevice outgoing_data) override {
        QNetworkRequest req (request);
        if (!req.attribute (WebFlowCredentials.DontAddCredentialsAttribute).to_bool ()) {
            if (this.credentials && !this.credentials.password ().is_empty ()) {
                GLib.ByteArray cred_hash = GLib.ByteArray (this.credentials.user ().to_utf8 () + ":" + this.credentials.password ().to_utf8 ()).to_base64 ();
                req.set_raw_header ("Authorization", "Basic " + cred_hash);
            }
        }

        if (this.credentials && !this.credentials.client_ssl_key.is_null () && !this.credentials.client_ssl_certificate.is_null ()) {
            // SSL configuration
            QSslConfiguration ssl_configuration = req.ssl_configuration ();
            ssl_configuration.set_local_certificate (this.credentials.client_ssl_certificate);
            ssl_configuration.set_private_key (this.credentials.client_ssl_key);

            // Merge client side CA with system CA
            var ca = ssl_configuration.system_ca_certificates ();
            ca.append (this.credentials.client_ssl_ca_certificates);
            ssl_configuration.set_ca_certificates (ca);

            req.set_ssl_configuration (ssl_configuration);
        }

        return AccessManager.create_request (op, req, outgoing_data);
    }


    // The credentials object dies along with the account, while the QNAM might
    // outlive both.
    private QPointer<const WebFlowCredentials> this.credentials;
}

#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
static void add_settings_to_job (Account account, QKeychain.Job job) {
    Q_UNUSED (account)
    var settings = ConfigFile.settings_with_group (Theme.instance ().app_name ());
    settings.set_parent (job); // make the job parent to make setting deleted properly
    job.set_settings (settings.release ());
}
#endif