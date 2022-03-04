/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QDir>
//  #include <QFileDialog>
//  #include <QTimer>
//  #include <QPushButton>
//  #include <QMessageBox>
//  #include <QSsl>
//  #include <QSslCertificate>
//  #include <QNetworkAccessManager>
//  #include <QPropertyAnimation>
//  #include <QGraphics_pixmap_item>
//  #include <QBuffer>
//  #include <QWizard>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OwncloudSetupPage class
@ingroup gui
***********************************************************/
class OwncloudSetupPage : QWizardPage {
    /***********************************************************
    ***********************************************************/
    private Ui.OwncloudeSetupPage ui;

    /***********************************************************
    ***********************************************************/
    private string oc_url;
    private string oc_user;
    private bool auth_type_known = false;
    private bool checking = false;
    private DetermineAuthTypeJob.AuthType auth_type = DetermineAuthTypeJob.AuthType.BASIC;

    /***********************************************************
    ***********************************************************/
    private QProgressIndicator progress_indi;
    private OwncloudWizard oc_wizard;
    private AddCertificateDialog add_cert_dial = null;


    signal void determine_auth_type (string value);


    /***********************************************************
    ***********************************************************/
    public OwncloudSetupPage (Gtk.Widget parent = null) {
        base ();
        this.progress_indi = new QProgressIndicator (this);
        this.oc_wizard = (OwncloudWizard)parent;
        this.ui.up_ui (this);

        setup_server_address_description_label ();

        Theme theme = Theme.instance ();
        if (theme.override_server_url ().is_empty ()) {
            this.ui.le_url.postfix (theme.wizard_url_postfix ());
            this.ui.le_url.placeholder_text (theme.WIZARD_URL_HINT);
        } else if (Theme.instance ().force_override_server_url ()) {
            this.ui.le_url.enabled (false);
        }

        register_field (QLatin1String ("OCUrl*"), this.ui.le_url);

        var size_policy = this.progress_indi.size_policy ();
        size_policy.retain_size_when_hidden (true);
        this.progress_indi.size_policy (size_policy);

        this.ui.progress_layout.add_widget (this.progress_indi);
        on_signal_stop_spinner ();

        set_up_customization ();

        on_signal_url_changed (QLatin1String ("")); // don't jitter UI
        connect (this.ui.le_url, &QLineEdit.text_changed, this, &OwncloudSetupPage.on_signal_url_changed);
        connect (this.ui.le_url, &QLineEdit.editing_finished, this, &OwncloudSetupPage.on_signal_url_edit_finished);

        add_cert_dial = new AddCertificateDialog (this);
        connect (add_cert_dial, &Gtk.Dialog.accepted, this, &OwncloudSetupPage.on_signal_certificate_accepted);
    }


    /***********************************************************
    ***********************************************************/
    public bool is_complete () {
        return !this.ui.le_url.text ().is_empty () && !this.checking;
    }


    /***********************************************************
    ***********************************************************/
    public void initialize_page () {
        customize_style ();

        WizardCommon.init_error_label (this.ui.error_label);

        this.auth_type_known = false;
        this.checking = false;

        QAbstractButton next_button = wizard ().button (QWizard.NextButton);
        var push_button = qobject_cast<QPushButton> (next_button);
        if (push_button) {
            push_button.default (true);
        }

        this.ui.le_url.focus ();

        const var is_server_url_overridden = !Theme.instance ().override_server_url ().is_empty ();
        if (is_server_url_overridden && !Theme.instance ().force_override_server_url ()) {
            // If the url is overwritten but we don't force to use that url
            // Just focus the next button to let the user navigate quicker
            if (next_button) {
                next_button.focus ();
            }
        } else if (is_server_url_overridden) {
            // If the overwritten url is not empty and we force this overwritten url
            // we just check the server type and switch to next page
            // immediately.
            commit_page (true);
            // Hack : commit_page () changes caption, but after an error this page could still be visible
            button_text (QWizard.Commit_button, _("&Next >"));
            validate_page ();
            visible (false);
        }
    }

    /***********************************************************
    ***********************************************************/
    public bool validate_page () {
        if (!this.auth_type_known) {
            on_signal_url_edit_finished ();
            string u = url ();
            GLib.Uri qurl (u);
            if (!qurl.is_valid () || qurl.host ().is_empty ()) {
                on_signal_error_string (_("Server address does not seem to be valid"), false);
                return false;
            }

            on_signal_error_string ("", false);
            this.checking = true;
            on_signal_start_spinner ();
            /* emit */ complete_changed ();

            /* emit */ determine_auth_type (u);
            return false;
        } else {
            // connecting is running
            on_signal_stop_spinner ();
            this.checking = false;
            /* emit */ complete_changed ();
            return true;
        }
    }


    /***********************************************************
    ***********************************************************/
    public int next_id () {
        switch (this.auth_type) {
        case DetermineAuthTypeJob.AuthType.BASIC:
            return WizardCommon.Pages.PAGE_HTTP_CREDS;
        case DetermineAuthTypeJob.AuthType.OAUTH:
            return WizardCommon.Pages.PAGE_OAUTH_CREDS;
        case DetermineAuthTypeJob.AuthType.LOGIN_FLOW_V2:
            return WizardCommon.Pages.PAGE_FLOW2AUTH_CREDS;
    //  #ifdef WITH_WEBENGINE
        case DetermineAuthTypeJob.WEB_VIEW_FLOW:
            return WizardCommon.Pages.PAGE_WEB_VIEW;
    //  #endif WITH_WEBENGINE
        case DetermineAuthTypeJob.NO_AUTH_TYPE:
            return WizardCommon.Pages.PAGE_HTTP_CREDS;
        }
        Q_UNREACHABLE ();
    }


    /***********************************************************
    ***********************************************************/
    public void server_url (string new_url) {
        this.oc_wizard.registration (false);
        this.oc_url = new_url;
        if (this.oc_url.is_empty ()) {
            this.ui.le_url.clear ();
            return;
        }

        this.ui.le_url.on_signal_text (this.oc_url);
    }


    /***********************************************************
    ***********************************************************/
    //  public void allow_password_storage (bool);


    /***********************************************************
    ***********************************************************/
    public string url () {
        string url = this.ui.le_url.full_text ().simplified ();
        return url;
    }


    /***********************************************************
    ***********************************************************/
    //  public void on_signal_remote_folder (string remote_fo);


    /***********************************************************
    ***********************************************************/
    public void on_signal_auth_type (DetermineAuthTypeJob.AuthType type) {
        this.auth_type_known = true;
        this.auth_type = type;
        on_signal_stop_spinner ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_error_string (string err, bool retry_http_only) {
        if (err.is_empty ()) {
            this.ui.error_label.visible (false);
        } else {
            if (retry_http_only) {
                GLib.Uri url (this.ui.le_url.full_text ());
                if (url.scheme () == "https") {
                    // Ask the user how to proceed when connecting to a https:// URL fails.
                    // It is possible that the server is secured with client-side TLS certificates,
                    // but that it has no way of informing the owncloud client that this is the case.

                    OwncloudConnectionMethodDialog dialog;
                    dialog.url (url);
                    // FIXME : Synchronous dialogs are not so nice because of event loop recursion
                    int ret_val = dialog.exec ();

                    switch (ret_val) {
                    case OwncloudConnectionMethodDialog.No_TLS: {
                        url.scheme ("http");
                        this.ui.le_url.full_text (url.to_string ());
                        // skip ahead to next page, since the user would expect us to retry automatically
                        wizard ().next ();
                    } break;
                    case OwncloudConnectionMethodDialog.Client_Side_TLS:
                        add_cert_dial.show ();
                        break;
                    case OwncloudConnectionMethodDialog.Closed:
                    case OwncloudConnectionMethodDialog.Back:
                    default:
                        // No-operation.
                        break;
                    }
                }
            }

            this.ui.error_label.visible (true);
            this.ui.error_label.on_signal_text (err);
        }
        this.checking = false;
        /* emit */ complete_changed ();
        on_signal_stop_spinner ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start_spinner () {
        this.ui.progress_layout.enabled (true);
        this.progress_indi.visible (true);
        this.progress_indi.on_signal_start_animation ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_stop_spinner () {
        this.ui.progress_layout.enabled (false);
        this.progress_indi.visible (false);
        this.progress_indi.on_signal_stop_animation ();
    }


    /***********************************************************
    Called during the validation of the client certificate.
    ***********************************************************/
    public void on_signal_certificate_accepted () {
        GLib.File cert_file (add_cert_dial.get_certificate_path ());
        cert_file.open (GLib.File.ReadOnly);
        GLib.ByteArray cert_data = cert_file.read_all ();
        GLib.ByteArray cert_password = add_cert_dial.get_certificate_password ().to_local8Bit ();

        QBuffer cert_data_buffer (&cert_data);
        cert_data_buffer.open (QIODevice.ReadOnly);
        if (QSslCertificate.import_pkcs12 (&cert_data_buffer,
                this.oc_wizard.client_ssl_key, this.oc_wizard.client_ssl_certificate,
                this.oc_wizard.client_ssl_ca_certificates, cert_password)) {
            this.oc_wizard.client_cert_bundle = cert_data;
            this.oc_wizard.client_cert_password = cert_password;

            add_cert_dial.reinit (); // FIXME : Why not just have this only created on use?

            // The extracted SSL key and cert gets added to the QSslConfiguration in check_server ()
            validate_page ();
        } else {
            add_cert_dial.show_error_message (_("Could not load certificate. Maybe wrong password?"));
            add_cert_dial.show ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_style_changed () {
        customize_style ();
    }


    /***********************************************************
    Slot hit from text_changed of the url entry field.
    ***********************************************************/
    protected void on_signal_url_changed (string url) {
        // Need to set next button as default button here because
        // otherwise the on OSX the next button does not stay the default
        // button
        var next_button = qobject_cast<QPushButton> (this.oc_wizard.button (QWizard.NextButton));
        if (next_button) {
            next_button.default (true);
        }

        this.auth_type_known = false;

        string new_url = url;
        if (url.ends_with ("index.php")) {
            new_url.chop (9);
        }
        if (this.oc_wizard && this.oc_wizard.account ()) {
            string web_dav_path = this.oc_wizard.account ().dav_path ();
            if (url.ends_with (web_dav_path)) {
                new_url.chop (web_dav_path.length ());
            }
            if (web_dav_path.ends_with ('/')) {
                web_dav_path.chop (1); // cut off the slash
                if (url.ends_with (web_dav_path)) {
                    new_url.chop (web_dav_path.length ());
                }
            }
        }
        if (new_url != url) {
            this.ui.le_url.on_signal_text (new_url);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_url_edit_finished () {
        string url = this.ui.le_url.full_text ();
        if (GLib.Uri (url).is_relative () && !url.is_empty ()) {
            // no scheme defined, set one
            url.prepend ("https://");
            this.ui.le_url.full_text (url);
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void set_up_customization () {
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

        var le_url_palette = this.ui.le_url.palette ();
        le_url_palette.on_signal_color (QPalette.Text, Qt.black);
        le_url_palette.on_signal_color (QPalette.Base, Qt.white);
        this.ui.le_url.palette (le_url_palette);
    }


    /***********************************************************
    ***********************************************************/
    private void logo () {
        this.ui.logo_label.pixmap (Theme.instance ().wizard_application_logo ());
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        logo ();

        if (this.progress_indi) {
            const var is_dark_background = Theme.is_dark_color (palette ().window ().color ());
            if (is_dark_background) {
                this.progress_indi.on_signal_color (Qt.white);
            } else {
                this.progress_indi.on_signal_color (Qt.black);
            }
        }

        WizardCommon.customize_hint_label (this.ui.server_address_description_label);
    }


    /***********************************************************
    ***********************************************************/
    private void setup_server_address_description_label () {
        const var app_name = Theme.instance ().app_name_gui ();
        this.ui.server_address_description_label.on_signal_text (_("The link to your %1 web interface when you open it in the browser.", "%1 will be replaced with the application name").arg (app_name));
    }


    /***********************************************************
    ***********************************************************/
    private static string subject_info_helper (QSslCertificate cert, GLib.ByteArray qa) {
        return cert.subject_info (qa).join ('/');
    }

} // class OwncloudSetupPage

} // namespace Ui
} // namespace Occ
    