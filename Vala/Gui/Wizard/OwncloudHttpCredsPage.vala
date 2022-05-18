/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>
@author Krzesimir Nowak <krzesimir@endocode.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OwncloudHttpCredsPage class
***********************************************************/
public class OwncloudHttpCredsPage : AbstractCredentialsWizardPage {

    /***********************************************************
    ***********************************************************/
    private OwncloudHttpCredsPage instance;
    private bool connected;
    private GLib.ProgressIndicator progress_indicator;
    private OwncloudWizard oc_wizard;


    internal signal void signal_connect_to_ocs_url (string value);


    /***********************************************************
    ***********************************************************/
    public OwncloudHttpCredsPage (Gtk.Widget parent) {
        base ();
        this.instance ();
        this.connected = false;
        this.progress_indicator = new GLib.ProgressIndicator (this);
        this.instance.up_ui (this);

        if (parent) {
            this.oc_wizard = (OwncloudWizard)parent;
        }

        register_field ("OCUser*", this.instance.le_username);
        register_field ("OCPasswd*", this.instance.le_password);

        Theme theme = Theme.instance;
        switch (theme.user_identifier_type) {
        case Theme.UserIdentifierType.USER_NAME:
            // default, handled in instance file
            break;
        case Theme.UserIdentifierType.EMAIL:
            this.instance.username_label.on_signal_text (_("&Email"));
            break;
        case Theme.UserIdentifierType.CUSTOM:
            this.instance.username_label.on_signal_text (theme.custom_user_id);
            break;
        default:
            break;
        }
        this.instance.le_username.placeholder_text (theme.user_id_hint);

        title (WizardCommon.title_template ().printf (_("Connect to %1").printf (Theme.app_name_gui)));
        sub_title (WizardCommon.sub_title_template ().printf (_("Enter user credentials")));

        this.instance.result_layout.add_widget (this.progress_indicator);
        on_signal_stop_spinner ();
        set_up_customization ();
    }


    /***********************************************************
    ***********************************************************/
    public AbstractCredentials credentials {
        public get {
            return new HttpCredentialsGui (this.instance.le_username.text (), this.instance.le_password.text (), this.oc_wizard.client_cert_bundle, this.oc_wizard.client_cert_password);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        WizardCommon.init_error_label (this.instance.error_label);

        var oc_wizard = (OwncloudWizard)wizard ();
        AbstractCredentials credentials = oc_wizard.account.credentials;
        var http_creds = (HttpCredentials)credentials;
        if (http_creds) {
            string user = http_creds.fetch_user ();
            if (!user == "") {
                this.instance.le_username.on_signal_text (user);
            }
        } else {
            GLib.Uri url = oc_wizard.account.url;

            // If the final url does not have a username, check the
            // user specified url too. Sometimes redirects can lose
            // the user:pw information.
            if (url.user_name () == "") {
                url = oc_wizard.oc_url ();
            }

            string user = url.user_name ();
            string password = url.password ();

            if (!user == "") {
                this.instance.le_username.on_signal_text (user);
            }
            if (!password == "") {
                this.instance.le_password.on_signal_text (password);
            }
        }
        this.instance.token_label.on_signal_text (HttpCredentialsGui.request_app_password_text (oc_wizard.account));
        this.instance.token_label.visible (!this.instance.token_label.text () == "");
        this.instance.le_username.focus ();
    }


    /***********************************************************
    ***********************************************************/
    public void clean_up_page () {
        this.instance.le_username = "";
        this.instance.le_password = "";
    }


    /***********************************************************
    ***********************************************************/
    public bool validate_page () {
        if (this.instance.le_username.text () == "" || this.instance.le_password.text () == "") {
            return false;
        }

        if (!this.connected) {
            this.instance.error_label.visible (false);
            on_signal_start_spinner ();

            // Reset cookies to ensure the username / password is actually used
            var oc_wizard = (OwncloudWizard)wizard ();
            oc_wizard.account.clear_cookie_jar ();

            signal_complete_changed ();
            signal_connect_to_ocs_url (field ("OcsUrl").to_string ().simplified ());

            return false;
        } else {
            // Reset, to require another connection attempt next time
            this.connected = false;

            signal_complete_changed ();
            on_signal_stop_spinner ();
            return true;
        }
        return true;
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
    public void connected_true () {
        this.connected = true;
        on_signal_stop_spinner ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_error_string (string error_string) {
        if (error_string == "") {
            this.instance.error_label.visible (false);
        } else {
            this.instance.error_label.visible (true);
            this.instance.error_label.on_signal_text (error_string);
        }
        signal_complete_changed ();
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
        this.instance.result_layout.enabled (true);
        this.progress_indicator.visible (true);
        this.progress_indicator.on_signal_start_animation ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_stop_spinner () {
        this.instance.result_layout.enabled (false);
        this.progress_indicator.visible (false);
        this.progress_indicator.on_signal_stop_animation ();
    }


    /***********************************************************
    ***********************************************************/
    private void set_up_customization () {
        // set defaults for the customize labels.
        this.instance.top_label.hide ();
        this.instance.bottom_label.hide ();

        Theme theme = Theme.instance;
        GLib.Variant variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_TOP);
        if (!variant == null) {
            WizardCommon.set_up_custom_media (variant, this.instance.top_label);
        }

        variant = theme.custom_media (Theme.CustomMediaType.OC_SETUP_BOTTOM);
        WizardCommon.set_up_custom_media (variant, this.instance.bottom_label);
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        if (this.progress_indicator) {
            this.progress_indicator.on_signal_color (GLib.Application.palette ().color (Gtk.Palette.Text));
        }
    }

} // class OwncloudHttpCredsPage

} // namespace Ui
} // namespace Occ
    