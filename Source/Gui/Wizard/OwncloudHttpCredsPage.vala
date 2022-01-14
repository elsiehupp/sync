/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/


namespace Occ {

/***********************************************************
@brief The Owncloud_http_creds_page class
***********************************************************/
class Owncloud_http_creds_page : Abstract_credentials_wizard_page {
public:
    Owncloud_http_creds_page (Gtk.Widget *parent);

    AbstractCredentials *get_credentials () const override;

    void initialize_page () override;
    void cleanup_page () override;
    bool validate_page () override;
    int next_id () const override;
    void set_connected ();
    void set_error_string (string &err);

signals:
    void connect_to_oCUrl (string &);

public slots:
    void slot_style_changed ();

private:
    void start_spinner ();
    void stop_spinner ();
    void setup_customization ();
    void customize_style ();

    Ui_Owncloud_http_creds_page _ui;
    bool _connected;
    QProgress_indicator *_progress_indi;
    OwncloudWizard *_oc_wizard;
};

    Owncloud_http_creds_page.Owncloud_http_creds_page (Gtk.Widget *parent)
        : Abstract_credentials_wizard_page ()
        , _ui ()
        , _connected (false)
        , _progress_indi (new QProgress_indicator (this)) {
        _ui.setup_ui (this);

        if (parent) {
            _oc_wizard = qobject_cast<OwncloudWizard> (parent);
        }

        register_field (QLatin1String ("OCUser*"), _ui.le_username);
        register_field (QLatin1String ("OCPasswd*"), _ui.le_password);

        Theme *theme = Theme.instance ();
        switch (theme.user_iDType ()) {
        case Theme.User_iDUser_name:
            // default, handled in ui file
            break;
        case Theme.User_iDEmail:
            _ui.username_label.set_text (tr ("&Email"));
            break;
        case Theme.User_iDCustom:
            _ui.username_label.set_text (theme.custom_user_iD ());
            break;
        default:
            break;
        }
        _ui.le_username.set_placeholder_text (theme.user_iDHint ());

        set_title (WizardCommon.title_template ().arg (tr ("Connect to %1").arg (Theme.instance ().app_name_g_u_i ())));
        set_sub_title (WizardCommon.sub_title_template ().arg (tr ("Enter user credentials")));

        _ui.result_layout.add_widget (_progress_indi);
        stop_spinner ();
        setup_customization ();
    }

    void Owncloud_http_creds_page.setup_customization () {
        // set defaults for the customize labels.
        _ui.top_label.hide ();
        _ui.bottom_label.hide ();

        Theme *theme = Theme.instance ();
        QVariant variant = theme.custom_media (Theme.o_c_setup_top);
        if (!variant.is_null ()) {
            WizardCommon.setup_custom_media (variant, _ui.top_label);
        }

        variant = theme.custom_media (Theme.o_c_setup_bottom);
        WizardCommon.setup_custom_media (variant, _ui.bottom_label);
    }

    void Owncloud_http_creds_page.initialize_page () {
        WizardCommon.init_error_label (_ui.error_label);

        auto *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        AbstractCredentials *cred = oc_wizard.account ().credentials ();
        auto *http_creds = qobject_cast<HttpCredentials> (cred);
        if (http_creds) {
            const string user = http_creds.fetch_user ();
            if (!user.is_empty ()) {
                _ui.le_username.set_text (user);
            }
        } else {
            QUrl url = oc_wizard.account ().url ();

            // If the final url does not have a username, check the
            // user specified url too. Sometimes redirects can lose
            // the user:pw information.
            if (url.user_name ().is_empty ()) {
                url = oc_wizard.oc_url ();
            }

            const string user = url.user_name ();
            const string password = url.password ();

            if (!user.is_empty ()) {
                _ui.le_username.set_text (user);
            }
            if (!password.is_empty ()) {
                _ui.le_password.set_text (password);
            }
        }
        _ui.token_label.set_text (HttpCredentialsGui.request_app_password_text (oc_wizard.account ().data ()));
        _ui.token_label.set_visible (!_ui.token_label.text ().is_empty ());
        _ui.le_username.set_focus ();
    }

    void Owncloud_http_creds_page.cleanup_page () {
        _ui.le_username.clear ();
        _ui.le_password.clear ();
    }

    bool Owncloud_http_creds_page.validate_page () {
        if (_ui.le_username.text ().is_empty () || _ui.le_password.text ().is_empty ()) {
            return false;
        }

        if (!_connected) {
            _ui.error_label.set_visible (false);
            start_spinner ();

            // Reset cookies to ensure the username / password is actually used
            auto *oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
            oc_wizard.account ().clear_cookie_jar ();

            emit complete_changed ();
            emit connect_to_oCUrl (field ("OCUrl").to_string ().simplified ());

            return false;
        } else {
            // Reset, to require another connection attempt next time
            _connected = false;

            emit complete_changed ();
            stop_spinner ();
            return true;
        }
        return true;
    }

    int Owncloud_http_creds_page.next_id () {
        return WizardCommon.Page_Advanced_setup;
    }

    void Owncloud_http_creds_page.set_connected () {
        _connected = true;
        stop_spinner ();
    }

    void Owncloud_http_creds_page.start_spinner () {
        _ui.result_layout.set_enabled (true);
        _progress_indi.set_visible (true);
        _progress_indi.start_animation ();
    }

    void Owncloud_http_creds_page.stop_spinner () {
        _ui.result_layout.set_enabled (false);
        _progress_indi.set_visible (false);
        _progress_indi.stop_animation ();
    }

    void Owncloud_http_creds_page.set_error_string (string &err) {
        if (err.is_empty ()) {
            _ui.error_label.set_visible (false);
        } else {
            _ui.error_label.set_visible (true);
            _ui.error_label.set_text (err);
        }
        emit complete_changed ();
        stop_spinner ();
    }

    AbstractCredentials *Owncloud_http_creds_page.get_credentials () {
        return new HttpCredentialsGui (_ui.le_username.text (), _ui.le_password.text (), _oc_wizard._client_cert_bundle, _oc_wizard._client_cert_password);
    }

    void Owncloud_http_creds_page.slot_style_changed () {
        customize_style ();
    }

    void Owncloud_http_creds_page.customize_style () {
        if (_progress_indi)
            _progress_indi.set_color (QGuiApplication.palette ().color (QPalette.Text));
    }

    } // namespace Occ
    