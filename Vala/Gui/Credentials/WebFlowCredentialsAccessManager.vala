
namespace Occ {
namespace Ui {

public class WebFlowCredentialsAccessManager : LibSync.Soup.ClientContext {

    private const string USER_C = "user";
    private const string CLIENT_CERTIFICATE_PEM_C = "this.client_certificate_pem";
    private const string CLIENT_KEY_PEM_C = "this.client_key_pem";
    private const string CLIENT_CA_CERTIFICATE_PEM_C = "this.client_ca_certificate_pem";

    /***********************************************************
    The credentials object dies along with the account, while
    the GLib.NAM might outlive both.
    ***********************************************************/
    private WebFlowCredentials credentials { private get; construct; }

    /***********************************************************
    ***********************************************************/
    public WebFlowCredentialsAccessManager (WebFlowCredentials credentials, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        this.credentials = credentials;
    }


    /***********************************************************
    ***********************************************************/
    protected override GLib.InputStream create_request (Operation operation, Soup.Request request, GLib.OutputStream outgoing_data) {
        Soup.Request req = new Soup.Request (request);
        if (!req.attribute (WebFlowCredentials.DontAddCredentialsAttribute).to_bool ()) {
            if (this.credentials && !this.credentials.password () == "") {
                string cred_hash = (this.credentials.user ().to_utf8 () + ":" + this.credentials.password ().to_utf8 ()).to_base64 ();
                req.raw_header ("Authorization", "Basic " + cred_hash);
            }
        }

        if (this.credentials && !this.credentials.client_ssl_key == null && !this.credentials.client_ssl_certificate == null) {
            // SSL configuration
            GLib.SslConfiguration ssl_configuration = req.ssl_configuration ();
            ssl_configuration.local_certificate (this.credentials.client_ssl_certificate);
            ssl_configuration.private_key (this.credentials.client_ssl_key);

            // Merge client side CA with system CA
            var ca = ssl_configuration.system_ca_certificates ();
            ca.append (this.credentials.client_ssl_ca_certificates);
            ssl_configuration.ca_certificates (ca);

            req.ssl_configuration (ssl_configuration);
        }

        return LibSync.Soup.ClientContext.create_request (operation, req, outgoing_data);
    }


    /***********************************************************
    #if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    ***********************************************************/
    private static void add_settings_to_job (Account account, Secret.Collection.Job qkeychain_job) {
        //  Q_UNUSED (account)
        var settings = ConfigFile.settings_with_group (Theme.app_name);
        settings.parent (qkeychain_job); // make the qkeychain_job parent to make setting deleted properly
        qkeychain_job.settings (settings.release ());
    }

} // class WebFlowCredentialsAccessManager

} // namespace Ui
} // namespace Occ
