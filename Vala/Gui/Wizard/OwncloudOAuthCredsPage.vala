/***********************************************************
@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Menu>
//  #include <GLib.Clipboard>
//  #include <GLib.NetworkCookie>
//  #include <GLib.Pointer>

namespace Occ {
namespace Ui {

public class OwncloudOAuthCredsPage : AbstractCredentialsWizardPage {

    /***********************************************************
    ***********************************************************/
    public string user;
    public string token;
    public string refresh_token;
    public OAuth async_auth;
    public OwncloudeOAuthCredsPage instance;


    internal signal void connect_to_oc_url (string value);


    /***********************************************************
    ***********************************************************/
    public OwncloudOAuthCredsPage () {
        base ();
        this.instance.up_ui (this);

        Theme theme = Theme.instance;
        this.instance.top_label.hide ();
        this.instance.bottom_label.hide ();
        GLib.Variant variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_TOP);
        WizardCommon.set_up_custom_media (variant, this.instance.top_label);
        variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_BOTTOM);
        WizardCommon.set_up_custom_media (variant, this.instance.bottom_label);

        WizardCommon.init_error_label (this.instance.error_label);

        title (WizardCommon.title_template ().printf (_("Connect to %1").printf (Theme.app_name_gui)));
        sub_title (WizardCommon.sub_title_template ().printf (_("Login in your browser")));

        this.instance.open_link_button.clicked.connect (
            this.on_signal_open_browser
        );
        this.instance.copy_link_button.clicked.connect (
            this.on_signal_copy_link_to_clipboard
        );
    }


    /***********************************************************
    ***********************************************************/
    public AbstractCredentials credentials {
        public get {
            OwncloudWizard oc_wizard = (OwncloudWizard) wizard ();
            //  GLib.assert_true (oc_wizard);
            return new HttpCredentialsGui (
                this.user, this.token, this.refresh_token,
                oc_wizard.client_cert_bundle,
                oc_wizard.client_cert_password
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        var oc_wizard = (OwncloudWizard)wizard ();
        //  GLib.assert_true (oc_wizard);
        oc_wizard.account.credentials (CredentialsFactory.create ("http"));
        this.async_auth.on_signal_reset (new OAuth (oc_wizard.account, this));
        this.async_auth.signal_result.connect (
            this.on_signal_async_auth_result // GLib.QueuedConnection
        );
        this.async_auth.on_signal_start ();

        // Don't hide the wizard (avoid user confusion)!
        //wizard ().hide ();
    }


    /***********************************************************
    ***********************************************************/
    public void clean_up_page () {
        // The next or back button was activated, show the wizard again
        wizard ().show ();
        this.async_auth.on_signal_reset ();
    }


    /***********************************************************
    ***********************************************************/
    public int next_id {
        public get {
            return WizardCommon.Pages.PAGE_ADVANCED_SETUP;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void connected (){
        wizard ().show ();
    }


    /***********************************************************
    We can never go forward manually
    ***********************************************************/
    public bool is_complete {
        public get {
            return false;
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_async_auth_result (OAuth.Result result_string, string user,
        string token, string refresh_token) {
        switch (result_string) {
        case OAuth.Result.NOT_SUPPORTED: {
            /* OAuth not supported (can't open browser), fallback to HTTP credentials */
            var oc_wizard = (OwncloudWizard)wizard ();
            oc_wizard.back ();
            oc_wizard.on_signal_auth_type (DetermineAuthTypeJob.AuthType.BASIC);
            break;
        }
        case OAuth.Error:
            /* Error while getting the access token.  (Timeout, or the server did not accept our client credentials */
            this.instance.error_label.show ();
            wizard ().show ();
            break;
        case OAuth.Result.LOGGED_IN: {
            this.token = token;
            this.user = user;
            this.refresh_token = refresh_token;
            var oc_wizard = (OwncloudWizard)wizard ();
            //  GLib.assert_true (oc_wizard);
            /* emit */ connect_to_oc_url (oc_wizard.account.url.to_string ());
            break;
        }
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_open_browser () {
        if (this.instance.error_label)
            this.instance.error_label.hide ();

        (OwncloudWizard)wizard ().account.clear_cookie_jar (); // #6574

        if (this.async_auth)
            this.async_auth.open_browser ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_copy_link_to_clipboard () {
        if (this.async_auth)
            GLib.Application.clipboard ().on_signal_text (this.async_auth.authorisation_link ().to_string (GLib.Uri.FullyEncoded));
    }

} // class OwncloudOAuthCredsPage

} // namespace Ui
} // namespace Occ
    