/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QMenu>
//  #include <QClipboard>
//  #pragma once
//  #include <QNetworkCookie>
//  #include <QPointer>

namespace Occ {
namespace Ui {

class Owncloud_oauth_creds_page : Abstract_credentials_wizard_page {

    /***********************************************************
    ***********************************************************/
    public Owncloud_oauth_creds_page ();

    /***********************************************************
    ***********************************************************/
    public AbstractCredentials get_credentials () override;

    /***********************************************************
    ***********************************************************/
    public void initialize_page () override;
    public void cleanup_page () override;
    public int next_id () override;
    public void connected ();


    /***********************************************************
    ***********************************************************/
    public bool is_complete () override;

    /***********************************************************
    ***********************************************************/
    public void on_async_auth_result (OAuth.Result, string user, string token,
        const string reniew_token);

signals:
    void connect_to_oc_url (string );


    /***********************************************************
    ***********************************************************/
    public string this.user;
    public string this.token;
    public string this.refresh_token;
    public QScopedPointer<OAuth> this.async_auth;
    public Ui_Owncloud_oauth_creds_page this.ui;

protected slots:
    void on_open_browser ();
    void on_copy_link_to_clipboard ();
}

    Owncloud_oauth_creds_page.Owncloud_oauth_creds_page ()
        : Abstract_credentials_wizard_page () {
        this.ui.up_ui (this);

        Theme theme = Theme.instance ();
        this.ui.top_label.hide ();
        this.ui.bottom_label.hide ();
        GLib.Variant variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_TOP);
        WizardCommon.setup_custom_media (variant, this.ui.top_label);
        variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_BOTTOM);
        WizardCommon.setup_custom_media (variant, this.ui.bottom_label);

        WizardCommon.init_error_label (this.ui.error_label);

        title (WizardCommon.title_template ().arg (_("Connect to %1").arg (Theme.instance ().app_name_gui ())));
        sub_title (WizardCommon.sub_title_template ().arg (_("Login in your browser")));

        connect (this.ui.open_link_button, &QCommand_link_button.clicked, this, &Owncloud_oauth_creds_page.on_open_browser);
        connect (this.ui.copy_link_button, &QCommand_link_button.clicked, this, &Owncloud_oauth_creds_page.on_copy_link_to_clipboard);
    }

    void Owncloud_oauth_creds_page.initialize_page () {
        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        //  Q_ASSERT (oc_wizard);
        oc_wizard.account ().credentials (CredentialsFactory.create ("http"));
        this.async_auth.on_reset (new OAuth (oc_wizard.account ().data (), this));
        connect (this.async_auth.data (), &OAuth.result, this, &Owncloud_oauth_creds_page.on_async_auth_result, Qt.QueuedConnection);
        this.async_auth.on_start ();

        // Don't hide the wizard (avoid user confusion)!
        //wizard ().hide ();
    }

    void Occ.Owncloud_oauth_creds_page.cleanup_page () {
        // The next or back button was activated, show the wizard again
        wizard ().show ();
        this.async_auth.on_reset ();
    }

    void Owncloud_oauth_creds_page.on_async_auth_result (OAuth.Result r, string user,
        const string token, string refresh_token) {
        switch (r) {
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

    int Owncloud_oauth_creds_page.next_id () {
        return WizardCommon.Page_Advanced_setup;
    }

    void Owncloud_oauth_creds_page.connected () {
        wizard ().show ();
    }

    AbstractCredentials *Owncloud_oauth_creds_page.get_credentials () {
        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        //  Q_ASSERT (oc_wizard);
        return new HttpCredentialsGui (this.user, this.token, this.refresh_token,
            oc_wizard.client_cert_bundle, oc_wizard.client_cert_password);
    }

    bool Owncloud_oauth_creds_page.is_complete () {
        return false; /* We can never go forward manually */
    }

    void Owncloud_oauth_creds_page.on_open_browser () {
        if (this.ui.error_label)
            this.ui.error_label.hide ();

        qobject_cast<OwncloudWizard> (wizard ()).account ().clear_cookie_jar (); // #6574

        if (this.async_auth)
            this.async_auth.open_browser ();
    }

    void Owncloud_oauth_creds_page.on_copy_link_to_clipboard () {
        if (this.async_auth)
            QApplication.clipboard ().on_text (this.async_auth.authorisation_link ().to_string (GLib.Uri.FullyEncoded));
    }

    } // namespace Occ
    