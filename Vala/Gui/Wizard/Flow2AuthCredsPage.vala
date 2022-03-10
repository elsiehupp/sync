/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QVBoxLayout>
//  #include <QNetworkCookie>
//  #include <QPointer>

namespace Occ {
namespace Ui {

class Flow2AuthCredsPage : AbstractCredentialsWizardPage {

    /***********************************************************
    ***********************************************************/
    public string user;
    public string app_password;

    /***********************************************************
    ***********************************************************/
    private Flow2AuthWidget flow_2_auth_widget = null;
    private QVBoxLayout layout = null;

    signal void connect_to_oc_url (string value);
    signal void poll_now ();
    signal void signal_style_changed ();

    /***********************************************************
    ***********************************************************/
    public Flow2AuthCredsPage () {
        base ();
        this.layout = new QVBoxLayout (this);

        this.flow_2_auth_widget = new Flow2AuthWidget ();
        this.layout.add_widget (this.flow_2_auth_widget);

        connect (
            this.flow_2_auth_widget,
            Flow2AuthWidget.auth_result,
            this,
            Flow2AuthCredsPage.on_signal_flow_2_auth_result
        );

        // Connect signal_style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        connect (
            this,
            Flow2AuthCredsPage.signal_style_changed,
            this.flow_2_auth_widget,
            Flow2AuthWidget.on_signal_style_changed
        );

        // allow Flow2 page to poll on window activation
        connect (
            this,
            Flow2AuthCredsPage.poll_now,
            this.flow_2_auth_widget,
            Flow2AuthWidget.on_signal_poll_now
        );
    }


    /***********************************************************
    ***********************************************************/
    public AbstractCredentials get_credentials () {
        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        //  Q_ASSERT (oc_wizard);
        return new WebFlowCredentials (
                    this.user,
                    this.app_password,
                    oc_wizard.client_ssl_certificate,
                    oc_wizard.client_ssl_key,
                    oc_wizard.client_ssl_ca_certificates
        );
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        //  Q_ASSERT (oc_wizard);
        oc_wizard.account ().credentials (CredentialsFactory.create ("http"));

        if (this.flow_2_auth_widget)
            this.flow_2_auth_widget.start_auth (oc_wizard.account ().data ());

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
        this.app_password.clear ();
        this.user.clear ();
    }


    /***********************************************************
    ***********************************************************/
    public int next_id () {
        return WizardCommon.Pages.PAGE_ADVANCED_SETUP;
    }


    /***********************************************************
    ***********************************************************/
    public void connected () {
        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        //  Q_ASSERT (oc_wizard);

        // bring wizard to top
        oc_wizard.bring_to_top ();
    }


    /***********************************************************
    ***********************************************************/
    public bool is_complete () {
        return false; /* We can never go forward manually */
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_flow_2_auth_result (Flow2Auth.Result result, string error_string, string user, string app_password) {
        //  Q_UNUSED (error_string)
        switch (result) {
            case Flow2Auth.NotSupported: {
                /* Flow2Auth not supported (can't open browser) */
                wizard ().show ();

                /* Don't fallback to HTTP credentials */
                /*OwncloudWizard oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
                oc_wizard.back ();
                oc_wizard.on_signal_auth_type (DetermineAuthTypeJob.AuthType.BASIC);*/
                break;
            }
            case Flow2Auth.Error:
                /* Error while getting the access token.  (Timeout, or the server did not accept our client credentials */
                wizard ().show ();
                break;
            case Flow2Auth.LoggedIn: {
                this.user = user;
                this.app_password = app_password;
                var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
                //  Q_ASSERT (oc_wizard);

                /* emit */ connect_to_oc_url (oc_wizard.account ().url ().to_string ());
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
