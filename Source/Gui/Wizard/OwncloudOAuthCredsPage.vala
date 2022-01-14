/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QVariant>
// #include <QMenu>
// #include <QClipboard>

// #pragma once

// #include <QList>
// #include <QMap>
// #include <QNetwork_cookie>
// #include <QUrl>
// #include <QPointer>

namespace Occ {

class Owncloud_oAuth_creds_page : Abstract_credentials_wizard_page {
public:
    Owncloud_oAuth_creds_page ();

    AbstractCredentials *get_credentials () const override;

    void initialize_page () override;
    void cleanup_page () override;
    int next_id () const override;
    void set_connected ();
    bool is_complete () const override;

public slots:
    void async_auth_result (OAuth.Result, string &user, string &token,
        const string &reniew_token);

signals:
    void connect_to_oCUrl (string &);

public:
    string _user;
    string _token;
    string _refresh_token;
    QScopedPointer<OAuth> _async_auth;
    Ui_Owncloud_oAuth_creds_page _ui;

protected slots:
    void slot_open_browser ();
    void slot_copy_link_to_clipboard ();
};

    Owncloud_oAuth_creds_page.Owncloud_oAuth_creds_page ()
        : Abstract_credentials_wizard_page () {
        _ui.setup_ui (this);
    
        Theme *theme = Theme.instance ();
        _ui.top_label.hide ();
        _ui.bottom_label.hide ();
        QVariant variant = theme.custom_media (Theme.o_c_setup_top);
        Wizard_common.setup_custom_media (variant, _ui.top_label);
        variant = theme.custom_media (Theme.o_c_setup_bottom);
        Wizard_common.setup_custom_media (variant, _ui.bottom_label);
    
        Wizard_common.init_error_label (_ui.error_label);
    
        set_title (Wizard_common.title_template ().arg (tr ("Connect to %1").arg (Theme.instance ().app_name_g_u_i ())));
        set_sub_title (Wizard_common.sub_title_template ().arg (tr ("Login in your browser")));
    
        connect (_ui.open_link_button, &QCommand_link_button.clicked, this, &Owncloud_oAuth_creds_page.slot_open_browser);
        connect (_ui.copy_link_button, &QCommand_link_button.clicked, this, &Owncloud_oAuth_creds_page.slot_copy_link_to_clipboard);
    }
    
    void Owncloud_oAuth_creds_page.initialize_page () {
        auto *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        Q_ASSERT (oc_wizard);
        oc_wizard.account ().set_credentials (CredentialsFactory.create ("http"));
        _async_auth.reset (new OAuth (oc_wizard.account ().data (), this));
        connect (_async_auth.data (), &OAuth.result, this, &Owncloud_oAuth_creds_page.async_auth_result, Qt.QueuedConnection);
        _async_auth.start ();
    
        // Don't hide the wizard (avoid user confusion)!
        //wizard ().hide ();
    }
    
    void Occ.Owncloud_oAuth_creds_page.cleanup_page () {
        // The next or back button was activated, show the wizard again
        wizard ().show ();
        _async_auth.reset ();
    }
    
    void Owncloud_oAuth_creds_page.async_auth_result (OAuth.Result r, string &user,
        const string &token, string &refresh_token) {
        switch (r) {
        case OAuth.NotSupported : {
            /* OAuth not supported (can't open browser), fallback to HTTP credentials */
            auto *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
            oc_wizard.back ();
            oc_wizard.set_auth_type (DetermineAuthTypeJob.Basic);
            break;
        }
        case OAuth.Error:
            /* Error while getting the access token.  (Timeout, or the server did not accept our client credentials */
            _ui.error_label.show ();
            wizard ().show ();
            break;
        case OAuth.LoggedIn : {
            _token = token;
            _user = user;
            _refresh_token = refresh_token;
            auto *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
            Q_ASSERT (oc_wizard);
            emit connect_to_oCUrl (oc_wizard.account ().url ().to_string ());
            break;
        }
        }
    }
    
    int Owncloud_oAuth_creds_page.next_id () {
        return Wizard_common.Page_Advanced_setup;
    }
    
    void Owncloud_oAuth_creds_page.set_connected () {
        wizard ().show ();
    }
    
    AbstractCredentials *Owncloud_oAuth_creds_page.get_credentials () {
        auto *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        Q_ASSERT (oc_wizard);
        return new HttpCredentialsGui (_user, _token, _refresh_token,
            oc_wizard._client_cert_bundle, oc_wizard._client_cert_password);
    }
    
    bool Owncloud_oAuth_creds_page.is_complete () {
        return false; /* We can never go forward manually */
    }
    
    void Owncloud_oAuth_creds_page.slot_open_browser () {
        if (_ui.error_label)
            _ui.error_label.hide ();
    
        qobject_cast<OwncloudWizard> (wizard ()).account ().clear_cookie_jar (); // #6574
    
        if (_async_auth)
            _async_auth.open_browser ();
    }
    
    void Owncloud_oAuth_creds_page.slot_copy_link_to_clipboard () {
        if (_async_auth)
            QApplication.clipboard ().set_text (_async_auth.authorisation_link ().to_string (QUrl.FullyEncoded));
    }
    
    } // namespace Occ
    