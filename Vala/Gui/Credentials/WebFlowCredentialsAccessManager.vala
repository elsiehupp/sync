
namespace Occ {
namespace Ui {

public class WebFlowCredentialsAccessManager : AccessManager {

    private const string USER_C = "user";
    private const string CLIENT_CERTIFICATE_PEM_C = "this.client_certificate_pem";
    private const string CLIENT_KEY_PEM_C = "this.client_key_pem";
    private const string client_ca_certificate_pemC = "this.client_ca_certificate_pem";

    /***********************************************************
    The credentials object dies along with the account, while
    the QNAM might outlive both.
    ***********************************************************/
    private QPointer<const WebFlowCredentials> credentials;

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentialsAccessManager (WebFlowCredentials credentials, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.credentials = credentials;
    }


    /***********************************************************
    ***********************************************************/
    protected override Soup.Reply create_request (Operation operation, Soup.Request request, QIODevice outgoing_data) {
        Soup.Request req (request);
        if (!req.attribute (WebFlowCredentials.DontAddCredentialsAttribute).to_bool ()) {
            if (this.credentials && !this.credentials.password ().is_empty ()) {
                GLib.ByteArray cred_hash = GLib.ByteArray (this.credentials.user ().to_utf8 () + ":" + this.credentials.password ().to_utf8 ()).to_base64 ();
                req.raw_header ("Authorization", "Basic " + cred_hash);
            }
        }

        if (this.credentials && !this.credentials.client_ssl_key.is_null () && !this.credentials.client_ssl_certificate.is_null ()) {
            // SSL configuration
            QSslConfiguration ssl_configuration = req.ssl_configuration ();
            ssl_configuration.local_certificate (this.credentials.client_ssl_certificate);
            ssl_configuration.private_key (this.credentials.client_ssl_key);

            // Merge client side CA with system CA
            var ca = ssl_configuration.system_ca_certificates ();
            ca.append (this.credentials.client_ssl_ca_certificates);
            ssl_configuration.ca_certificates (ca);

            req.ssl_configuration (ssl_configuration);
        }

        return AccessManager.create_request (operation, req, outgoing_data);
    }


    /***********************************************************
    #if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    ***********************************************************/
    private static void add_settings_to_job (Account account, QKeychain.Job job) {
        //  Q_UNUSED (account)
        var settings = ConfigFile.settings_with_group (Theme.instance ().app_name ());
        settings.parent (job); // make the job parent to make setting deleted properly
        job.settings (settings.release ());
    }

} // class WebFlowCredentialsAccessManager

} // namespace Ui
} // namespace Occ
