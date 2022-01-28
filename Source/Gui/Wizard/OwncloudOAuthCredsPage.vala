/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QVariant>
// #include <QMenu>
// #include <QClipboard>

// #pragma once

// #include <GLib.List>
// #include <QMap>
// #include <QNetworkCookie>
// #include <QUrl>
// #include <QPointer>

namespace Occ {

class Owncloud_oauth_creds_page : Abstract_credentials_wizard_page {

    public Owncloud_oauth_creds_page ();

    public AbstractCredentials get_credentials () override;

    public void initialize_page () override;
    public void cleanup_page () override;
    public int next_id () override;
    public void set_connected ();


    public bool is_complete () override;


    public void on_async_auth_result (OAuth.Result, string user, string token,
        const string reniew_token);

signals:
    void connect_to_oc_url (string );


    public string _user;
    public string _token;
    public string _refresh_token;
    public QScopedPointer<OAuth> _async_auth;
    public Ui_Owncloud_oauth_creds_page _ui;

protected slots:
    void on_open_browser ();
    void on_copy_link_to_clipboard ();
};

    Owncloud_oauth_creds_page.Owncloud_oauth_creds_page ()
        : Abstract_credentials_wizard_page () {
        _ui.setup_ui (this);

        Theme theme = Theme.instance ();
        _ui.top_label.hide ();
        _ui.bottom_label.hide ();
        QVariant variant = theme.custom_media (Theme.o_c_setup_top);
        WizardCommon.setup_custom_media (variant, _ui.top_label);
        variant = theme.custom_media (Theme.o_c_setup_bottom);
        WizardCommon.setup_custom_media (variant, _ui.bottom_label);

        WizardCommon.init_error_label (_ui.error_label);

        set_title (WizardCommon.title_template ().arg (tr ("Connect to %1").arg (Theme.instance ().app_name_gui ())));
        set_sub_title (WizardCommon.sub_title_template ().arg (tr ("Login in your browser")));

        connect (_ui.open_link_button, &QCommand_link_button.clicked, this, &Owncloud_oauth_creds_page.on_open_browser);
        connect (_ui.copy_link_button, &QCommand_link_button.clicked, this, &Owncloud_oauth_creds_page.on_copy_link_to_clipboard);
    }

    void Owncloud_oauth_creds_page.initialize_page () {
        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        Q_ASSERT (oc_wizard);
        oc_wizard.account ().set_credentials (CredentialsFactory.create ("http"));
        _async_auth.on_reset (new OAuth (oc_wizard.account ().data (), this));
        connect (_async_auth.data (), &OAuth.result, this, &Owncloud_oauth_creds_page.on_async_auth_result, Qt.QueuedConnection);
        _async_auth.on_start ();

        // Don't hide the wizard (avoid user confusion)!
        //wizard ().hide ();
    }

    void Occ.Owncloud_oauth_creds_page.cleanup_page () {
        // The next or back button was activated, show the wizard again
        wizard ().show ();
        _async_auth.on_reset ();
    }

    void Owncloud_oauth_creds_page.on_async_auth_result (OAuth.Result r, string user,
        const string token, string refresh_token) {
        switch (r) {
        case OAuth.NotSupported: {
            /* OAuth not supported (can't open browser), fallback to HTTP credentials */
            var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
            oc_wizard.back ();
            oc_wizard.on_set_auth_type (DetermineAuthTypeJob.Basic);
            break;
        }
        case OAuth.Error:
            /* Error while getting the access token.  (Timeout, or the server did not accept our client credentials */
            _ui.error_label.show ();
            wizard ().show ();
            break;
        case OAuth.LoggedIn: {
            _token = token;
            _user = user;
            _refresh_token = refresh_token;
            var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
            Q_ASSERT (oc_wizard);
            emit connect_to_oc_url (oc_wizard.account ().url ().to_string ());
            break;
        }
        }
    }

    int Owncloud_oauth_creds_page.next_id () {
        return WizardCommon.Page_Advanced_setup;
    }

    void Owncloud_oauth_creds_page.set_connected () {
        wizard ().show ();
    }

    AbstractCredentials *Owncloud_oauth_creds_page.get_credentials () {
        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        Q_ASSERT (oc_wizard);
        return new HttpCredentialsGui (_user, _token, _refresh_token,
            oc_wizard._client_cert_bundle, oc_wizard._client_cert_password);
    }

    bool Owncloud_oauth_creds_page.is_complete () {
        return false; /* We can never go forward manually */
    }

    void Owncloud_oauth_creds_page.on_open_browser () {
        if (_ui.error_label)
            _ui.error_label.hide ();

        qobject_cast<OwncloudWizard> (wizard ()).account ().clear_cookie_jar (); // #6574

        if (_async_auth)
            _async_auth.open_browser ();
    }

    void Owncloud_oauth_creds_page.on_copy_link_to_clipboard () {
        if (_async_auth)
            QApplication.clipboard ().on_set_text (_async_auth.authorisation_link ().to_string (QUrl.FullyEncoded));
    }

    } // namespace Occ
    