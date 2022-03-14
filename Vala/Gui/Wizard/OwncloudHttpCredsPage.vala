/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OwncloudHttpCredsPage class
***********************************************************/
public class OwncloudHttpCredsPage : AbstractCredentialsWizardPage {

    /***********************************************************
    ***********************************************************/
    private Ui.OwncloudHttpCredsPage ui;
    private bool connected;
    private QProgressIndicator progress_indicator;
    private OwncloudWizard oc_wizard;


    signal void connect_to_oc_url (string value);


    /***********************************************************
    ***********************************************************/
    public OwncloudHttpCredsPage (Gtk.Widget parent) {
        base ();
        this.ui ();
        this.connected = false;
        this.progress_indicator = new QProgressIndicator (this);
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
            this.ui.username_label.on_signal_text (_("&Email"));
            break;
        case Theme.UserIdentifierType.CUSTOM:
            this.ui.username_label.on_signal_text (theme.custom_user_id ());
            break;
        default:
            break;
        }
        this.ui.le_username.placeholder_text (theme.user_id_hint ());

        title (WizardCommon.title_template ().printf (_("Connect to %1").printf (Theme.instance ().app_name_gui ())));
        sub_title (WizardCommon.sub_title_template ().printf (_("Enter user credentials")));

        this.ui.result_layout.add_widget (this.progress_indicator);
        on_signal_stop_spinner ();
        set_up_customization ();
    }


    /***********************************************************
    ***********************************************************/
    public AbstractCredentials credentials () {
        return new HttpCredentialsGui (this.ui.le_username.text (), this.ui.le_password.text (), this.oc_wizard.client_cert_bundle, this.oc_wizard.client_cert_password);
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        WizardCommon.init_error_label (this.ui.error_label);

        var oc_wizard = qobject_cast<OwncloudWizard> (wizard ());
        AbstractCredentials credentials = oc_wizard.account ().credentials ();
        var http_creds = qobject_cast<HttpCredentials> (credentials);
        if (http_creds) {
            const string user = http_creds.fetch_user ();
            if (!user.is_empty ()) {
                this.ui.le_username.on_signal_text (user);
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
                this.ui.le_username.on_signal_text (user);
            }
            if (!password.is_empty ()) {
                this.ui.le_password.on_signal_text (password);
            }
        }
        this.ui.token_label.on_signal_text (HttpCredentialsGui.request_app_password_text (oc_wizard.account ().data ()));
        this.ui.token_label.visible (!this.ui.token_label.text ().is_empty ());
        this.ui.le_username.focus ();
    }


    /***********************************************************
    ***********************************************************/
    public void clean_up_page () {
        this.ui.le_username.clear ();
        this.ui.le_password.clear ();
    }


    /***********************************************************
    ***********************************************************/
    public bool validate_page () {
        if (this.ui.le_username.text ().is_empty () || this.ui.le_password.text ().is_empty ()) {
            return false;
        }

        if (!this.connected) {
            this.ui.error_label.visible (false);
            on_signal_start_spinner ();

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
            on_signal_stop_spinner ();
            return true;
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public int next_id () {
        return WizardCommon.Pages.PAGE_ADVANCED_SETUP;
    }


    /***********************************************************
    ***********************************************************/
    public void connected_true () {
        this.connected = true;
        on_signal_stop_spinner ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_error_string (string error_string) {
        if (error_string == "") {
            this.ui.error_label.visible (false);
        } else {
            this.ui.error_label.visible (true);
            this.ui.error_label.on_signal_text (error_string);
        }
        /* emit */ complete_changed ();
        on_signal_stop_spinner ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_start_spinner () {
        this.ui.result_layout.enabled (true);
        this.progress_indicator.visible (true);
        this.progress_indicator.on_signal_start_animation ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_stop_spinner () {
        this.ui.result_layout.enabled (false);
        this.progress_indicator.visible (false);
        this.progress_indicator.on_signal_stop_animation ();
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_customization () {
        // set defaults for the customize labels.
        this.ui.top_label.hide ();
        this.ui.bottom_label.hide ();

        Theme theme = Theme.instance ();
        GLib.Variant variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_TOP);
        if (!variant.is_null ()) {
            WizardCommon.set_up_custom_media (variant, this.ui.top_label);
        }

        variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_BOTTOM);
        WizardCommon.set_up_custom_media (variant, this.ui.bottom_label);
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        if (this.progress_indicator) {
            this.progress_indicator.on_signal_color (QGuiApplication.palette ().color (QPalette.Text));
        }
    }

} // class OwncloudHttpCredsPage

} // namespace Ui
} // namespace Occ
    