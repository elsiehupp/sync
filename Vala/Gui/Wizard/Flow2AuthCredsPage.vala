/***********************************************************
@author Olivier Goffart <ogoffart@woboq.com>
@author Michael Schuster <michael@schuster.ms>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.VBoxLayout>
//  #include <GLib.NetworkCookie>
//  #include <GLib.Pointer>

namespace Occ {
namespace Ui {

public class Flow2AuthCredsPage : AbstractCredentialsWizardPage {

    /***********************************************************
    ***********************************************************/
    public string user;
    public string app_password;

    /***********************************************************
    ***********************************************************/
    private Flow2AuthWidget flow_2_auth_widget = null;
    private GLib.VBoxLayout layout = null;

    internal signal void connect_to_oc_url (string value);
    internal signal void poll_now ();
    internal signal void signal_style_changed ();

    /***********************************************************
    ***********************************************************/
    public Flow2AuthCredsPage () {
        base ();
        this.layout = new GLib.VBoxLayout (this);

        this.flow_2_auth_widget = new Flow2AuthWidget ();
        this.layout.add_widget (this.flow_2_auth_widget);

        this.flow_2_auth_widget.signal_auth_result.connect (
            this.on_signal_flow_2_auth_result
        );

        // Connect signal_style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        this.signal_style_changed.connect (
            this.flow_2_auth_widget.on_signal_style_changed
        );

        // allow Flow2 page to poll on window activation
        this.signal_poll_now.connect (
            this.flow_2_auth_widget.signal_poll_now
        );
    }


    /***********************************************************
    ***********************************************************/
    public AbstractCredentials credentials  {
        public get {
            OwncloudWizard oc_wizard = (OwncloudWizard) wizard ();
            //  GLib.assert_true (oc_wizard);
            return new WebFlowCredentials (
                        this.user,
                        this.app_password,
                        oc_wizard.client_ssl_certificate,
                        oc_wizard.client_ssl_key,
                        oc_wizard.client_ssl_ca_certificates
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        var oc_wizard = (OwncloudWizard)wizard ();
        //  GLib.assert_true (oc_wizard);
        oc_wizard.account.credentials (CredentialsFactory.create ("http"));

        if (this.flow_2_auth_widget)
            this.flow_2_auth_widget.start_auth (oc_wizard.account);

        // Don't hide the wizard (avoid user confusion)!
        //wizard ().hide ();

        this.flow_2_auth_widget.on_signal_style_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public void clean_up_page () {
        // The next or back button was activated, show the wizard again
        wizard ().show ();
        if (this.flow_2_auth_widget)
            this.flow_2_auth_widget.reset_auth ();

        // Forget sensitive data
        this.app_password == "";
        this.user == "";
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
    public void connected () {
        var oc_wizard = (OwncloudWizard)wizard ();
        //  GLib.assert_true (oc_wizard);

        // bring wizard to top
        oc_wizard.bring_to_top ();
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
    public void on_signal_flow_2_auth_result (Flow2Auth.Result result, string error_string, string user, string app_password) {
        //  Q_UNUSED (error_string)
        switch (result) {
            case Flow2Auth.Result.NOT_SUPPORTED: {
                /* Flow2Auth not supported (can't open browser) */
                wizard ().show ();

                /* Don't fallback to HTTP credentials */
                /*OwncloudWizard oc_wizard = (OwncloudWizard)wizard ();
                oc_wizard.back ();
                oc_wizard.on_signal_auth_type (DetermineAuthTypeJob.AuthType.BASIC);*/
                break;
            }
            case Flow2Auth.Error:
                /* Error while getting the access token.  (Timeout, or the server did not accept our client credentials */
                wizard ().show ();
                break;
            case Flow2Auth.Result.LOGGED_IN: {
                this.user = user;
                this.app_password = app_password;
                var oc_wizard = (OwncloudWizard)wizard ();
                //  GLib.assert_true (oc_wizard);

                /* emit */ connect_to_oc_url (oc_wizard.account.url.to_string ());
                break;
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_poll_now () {
        /* emit */ poll_now ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        /* emit */ signal_style_changed ();
    }

} // class Flow2AuthCredsPage

} // namespace Ui
} // namespace Occ
