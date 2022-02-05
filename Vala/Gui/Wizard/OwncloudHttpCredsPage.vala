/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief The Owncloud_http_creds_page class
***********************************************************/
class Owncloud_http_creds_page : Abstract_credentials_wizard_page {

    /***********************************************************
    ***********************************************************/
    public Owncloud_http_creds_page (Gtk.Widget parent);

    /***********************************************************
    ***********************************************************/
    public AbstractCredentials get_credentials () override;

    /***********************************************************
    ***********************************************************/
    public void initialize_page () override;
    public void cleanup_page () override;
    public bool validate_page () override;
    public int next_id () override;
    public void connected ();


    /***********************************************************
    ***********************************************************/
    public void on_error_string (string err);

signals:
    void connect_to_oc_url (string );


    /***********************************************************
    ***********************************************************/
    public void on_style_changed ();


    /***********************************************************
    ***********************************************************/
    private void on_start_spinner ();
    private void on_stop_spinner ();
    private void setup_customization ();
    private void customize_style ();

    /***********************************************************
    ***********************************************************/
    private Ui_Owncloud_http_creds_page this.ui;
    private bool this.connected;
    private QProgress_indicator this.progress_indi;
    private OwncloudWizard this.oc_wizard;
}

    Owncloud_http_creds_page.Owncloud_http_creds_page (Gtk.Widget parent)
        : Abstract_credentials_wizard_page ()
        this.ui ()
        this.connected (false)
        this.progress_indi (new QProgress_indicator (this)) {
        this.ui.up_ui (this);

        if (parent) {
            this.oc_wizard = qobject_cast<OwncloudWizard> (parent);
        }

        register_field (QLatin1String ("OCUser*"), this.ui.le_username);
        register_field (QLatin1String ("OCPasswd*"), this.ui.le_password);

        Theme theme = Theme.instance ();
        switch (theme.user_identifier_type ()) {
        case Theme.UserIdentifierType.USER_NAME:
            // default, handled in ui file
            break;
        case Theme.UserIdentifierType.EMAIL:
            this.ui.username_label.on_text (_("&Email"));
            break;
        case Theme.UserIdentifierType.CUSTOM:
            this.ui.username_label.on_text (theme.custom_user_id ());
            break;
        default:
            break;
        }
        this.ui.le_username.placeholder_text (theme.user_id_hint ());

        title (WizardCommon.title_template ().arg (_("Connect to %1").arg (Theme.instance ().app_name_gui ())));
        sub_title (WizardCommon.sub_title_template ().arg (_("Enter user credentials")));

        this.ui.result_layout.add_widget (this.progress_indi);
        on_stop_spinner ();
        setup_customization ();
    }

    void Owncloud_http_creds_page.setup_customization () {
        // set defaults for the customize labels.
        this.ui.top_label.hide ();
        this.ui.bottom_label.hide ();

        Theme theme = Theme.instance ();
        GLib.Variant variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_TOP);
        if (!variant.is_null ()) {
            WizardCommon.setup_custom_media (variant, this.ui.top_label);
        }

        variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_BOTTOM);
        WizardCommon.setup_custom_media (variant, this.ui.bottom_label);
    }

    void Owncloud_http_creds_page.initialize_page () {
        WizardCommon.init_error_label (this.ui.error_label);

        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        AbstractCredentials credentials = oc_wizard.account ().credentials ();
        var http_creds = qobject_cast<HttpCredentials> (credentials);
        if (http_creds) {
            const string user = http_creds.fetch_user ();
            if (!user.is_empty ()) {
                this.ui.le_username.on_text (user);
            }
        } else {
            GLib.Uri url = oc_wizard.account ().url ();

            // If the final url does not have a username, check the
            // user specified url too. Sometimes redirects can lose
            // the user:pw information.
            if (url.user_name ().is_empty ()) {
                url = oc_wizard.oc_url ();
            }

            const string user = url.user_name ();
            const string password = url.password ();

            if (!user.is_empty ()) {
                this.ui.le_username.on_text (user);
            }
            if (!password.is_empty ()) {
                this.ui.le_password.on_text (password);
            }
        }
        this.ui.token_label.on_text (HttpCredentialsGui.request_app_password_text (oc_wizard.account ().data ()));
        this.ui.token_label.visible (!this.ui.token_label.text ().is_empty ());
        this.ui.le_username.focus ();
    }

    void Owncloud_http_creds_page.cleanup_page () {
        this.ui.le_username.clear ();
        this.ui.le_password.clear ();
    }

    bool Owncloud_http_creds_page.validate_page () {
        if (this.ui.le_username.text ().is_empty () || this.ui.le_password.text ().is_empty ()) {
            return false;
        }

        if (!this.connected) {
            this.ui.error_label.visible (false);
            on_start_spinner ();

            // Reset cookies to ensure the username / password is actually used
            var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
            oc_wizard.account ().clear_cookie_jar ();

            /* emit */ complete_changed ();
            /* emit */ connect_to_oc_url (field ("OCUrl").to_string ().simplified ());

            return false;
        } else {
            // Reset, to require another connection attempt next time
            this.connected = false;

            /* emit */ complete_changed ();
            on_stop_spinner ();
            return true;
        }
        return true;
    }

    int Owncloud_http_creds_page.next_id () {
        return WizardCommon.Page_Advanced_setup;
    }

    void Owncloud_http_creds_page.connected () {
        this.connected = true;
        on_stop_spinner ();
    }

    void Owncloud_http_creds_page.on_start_spinner () {
        this.ui.result_layout.enabled (true);
        this.progress_indi.visible (true);
        this.progress_indi.on_start_animation ();
    }

    void Owncloud_http_creds_page.on_stop_spinner () {
        this.ui.result_layout.enabled (false);
        this.progress_indi.visible (false);
        this.progress_indi.on_stop_animation ();
    }

    void Owncloud_http_creds_page.on_error_string (string err) {
        if (err.is_empty ()) {
            this.ui.error_label.visible (false);
        } else {
            this.ui.error_label.visible (true);
            this.ui.error_label.on_text (err);
        }
        /* emit */ complete_changed ();
        on_stop_spinner ();
    }

    AbstractCredentials *Owncloud_http_creds_page.get_credentials () {
        return new HttpCredentialsGui (this.ui.le_username.text (), this.ui.le_password.text (), this.oc_wizard.client_cert_bundle, this.oc_wizard.client_cert_password);
    }

    void Owncloud_http_creds_page.on_style_changed () {
        customize_style ();
    }

    void Owncloud_http_creds_page.customize_style () {
        if (this.progress_indi)
            this.progress_indi.on_color (QGuiApplication.palette ().color (QPalette.Text));
    }

    } // namespace Occ
    