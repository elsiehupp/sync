/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QMenu>
//  #include <QClipboard>
//  #include <QNetworkCookie>
//  #include <QPointer>

namespace Occ {
namespace Ui {

class OwncloudOAuthCredsPage : AbstractCredentialsWizardPage {

    /***********************************************************
    ***********************************************************/
    public string user;
    public string token;
    public string refresh_token;
    public QScopedPointer<OAuth> async_auth;
    public Ui.OwncloudeOAuthCredsPage ui;


    signal void connect_to_oc_url (string value);


    /***********************************************************
    ***********************************************************/
    public OwncloudOAuthCredsPage () {
        base () {
        this.ui.up_ui (this);

        Theme theme = Theme.instance ();
        this.ui.top_label.hide ();
        this.ui.bottom_label.hide ();
        GLib.Variant variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_TOP);
        WizardCommon.set_up_custom_media (variant, this.ui.top_label);
        variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_BOTTOM);
        WizardCommon.set_up_custom_media (variant, this.ui.bottom_label);

        WizardCommon.init_error_label (this.ui.error_label);

        title (WizardCommon.title_template ().arg (_("Connect to %1").arg (Theme.instance ().app_name_gui ())));
        sub_title (WizardCommon.sub_title_template ().arg (_("Login in your browser")));

        connect (this.ui.open_link_button, &QCommand_link_button.clicked, this, &OwncloudOAuthCredsPage.on_open_browser);
        connect (this.ui.copy_link_button, &QCommand_link_button.clicked, this, &OwncloudOAuthCredsPage.on_copy_link_to_clipboard);
    }


    /***********************************************************
    ***********************************************************/
    public AbstractCredentials get_credentials () {
        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        //  Q_ASSERT (oc_wizard);
        return new HttpCredentialsGui (this.user, this.token, this.refresh_token,
            oc_wizard.client_cert_bundle, oc_wizard.client_cert_password);
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        //  Q_ASSERT (oc_wizard);
        oc_wizard.account ().credentials (CredentialsFactory.create ("http"));
        this.async_auth.on_reset (new OAuth (oc_wizard.account ().data (), this));
        connect (this.async_auth.data (), &OAuth.result, this, &OwncloudOAuthCredsPage.on_async_auth_result, Qt.QueuedConnection);
        this.async_auth.on_start ();

        // Don't hide the wizard (avoid user confusion)!
        //wizard ().hide ();
    }


    /***********************************************************
    ***********************************************************/
    public void clean_up_page () {
        // The next or back button was activated, show the wizard again
        wizard ().show ();
        this.async_auth.on_reset ();
    }


    /***********************************************************
    ***********************************************************/
    public int next_id () {
        return WizardCommon.Pages.PAGE_ADVANCED_SETUP;
    }


    /***********************************************************
    ***********************************************************/
    public void connected (){
        wizard ().show ();
    }


    /***********************************************************
    ***********************************************************/
    public bool is_complete () {
        return false; /* We can never go forward manually */
    }


    /***********************************************************
    ***********************************************************/
    public void on_async_auth_result (OAuth.Result result_string, string user,
        string token, string refresh_token) {
        switch (result_string) {
        case OAuth.NotSupported: {
            /* OAuth not supported (can't open browser), fallback to HTTP credentials */
            var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
            oc_wizard.back ();
            oc_wizard.on_auth_type (DetermineAuthTypeJob.AuthType.BASIC);
            break;
        }
        case OAuth.Error:
            /* Error while getting the access token.  (Timeout, or the server did not accept our client credentials */
            this.ui.error_label.show ();
            wizard ().show ();
            break;
        case OAuth.LoggedIn: {
            this.token = token;
            this.user = user;
            this.refresh_token = refresh_token;
            var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
            //  Q_ASSERT (oc_wizard);
            /* emit */ connect_to_oc_url (oc_wizard.account ().url ().to_string ());
            break;
        }
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_open_browser () {
        if (this.ui.error_label)
            this.ui.error_label.hide ();

        qobject_cast<OwncloudWizard> (wizard ()).account ().clear_cookie_jar (); // #6574

        if (this.async_auth)
            this.async_auth.open_browser ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_copy_link_to_clipboard () {
        if (this.async_auth)
            QApplication.clipboard ().on_text (this.async_auth.authorisation_link ().to_string (GLib.Uri.FullyEncoded));
    }

} // class OwncloudOAuthCredsPage

} // namespace Ui
} // namespace Occ
    