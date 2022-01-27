/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QDir>
// #include <QFileDialog>
// #include <QUrl>
// #include <QTimer>
// #include <QPushButton>
// #include <QMessageBox>
// #include <QSsl>
// #include <QSslCertificate>
// #include <QNetworkAccessManager>
// #include <QPropertyAnimation>
// #include <QGraphics_pixmap_item>
// #include <QBuffer>

// #include <QWizard>

#include "../addcertificatedialog.h"


namespace Occ {

/***********************************************************
@brief The Owncloud_setup_page class
@ingroup gui
***********************************************************/
class Owncloud_setup_page : QWizard_page {

    public Owncloud_setup_page (Gtk.Widget *parent = nullptr);
    ~Owncloud_setup_page () override;

    public bool is_complete () override;
    public void initialize_page () override;
    public int next_id () override;
    public void set_server_url (string );
    public void set_allow_password_storage (bool);
    public bool validate_page () override;
    public string url ();
    public string local_folder ();
    public void on_set_remote_folder (string remote_folder);
    public void set_multiple_folders_exist (bool exist);
    public void on_set_auth_type (DetermineAuthTypeJob.AuthType type);


    public void on_set_error_string (string , bool retry_http_only);
    public void on_start_spinner ();
    public void on_stop_spinner ();
    public void on_certificate_accepted ();
    public void on_style_changed ();

protected slots:
    void on_url_changed (string );
    void on_url_edit_finished ();

    void setup_customization ();

signals:
    void determine_auth_type (string );


    private void set_logo ();
    private void customize_style ();
    private void setup_server_address_description_label ();

    private Ui_Owncloud_setup_page _ui;

    private string _o_c_url;
    private string _oc_user;
    private bool _auth_type_known = false;
    private bool _checking = false;
    private DetermineAuthTypeJob.AuthType _auth_type = DetermineAuthTypeJob.Basic;

    private QProgress_indicator _progress_indi;
    private OwncloudWizard _oc_wizard;
    private AddCertificateDialog *add_cert_dial = nullptr;
};

    Owncloud_setup_page.Owncloud_setup_page (Gtk.Widget *parent)
        : QWizard_page ()
        , _progress_indi (new QProgress_indicator (this))
        , _oc_wizard (qobject_cast<OwncloudWizard> (parent)) {
        _ui.setup_ui (this);

        setup_server_address_description_label ();

        Theme *theme = Theme.instance ();
        if (theme.override_server_url ().is_empty ()) {
            _ui.le_url.set_postfix (theme.wizard_url_postfix ());
            _ui.le_url.set_placeholder_text (theme.wizard_url_hint ());
        } else if (Theme.instance ().force_override_server_url ()) {
            _ui.le_url.set_enabled (false);
        }

        register_field (QLatin1String ("OCUrl*"), _ui.le_url);

        auto size_policy = _progress_indi.size_policy ();
        size_policy.set_retain_size_when_hidden (true);
        _progress_indi.set_size_policy (size_policy);

        _ui.progress_layout.add_widget (_progress_indi);
        on_stop_spinner ();

        setup_customization ();

        on_url_changed (QLatin1String ("")); // don't jitter UI
        connect (_ui.le_url, &QLineEdit.text_changed, this, &Owncloud_setup_page.on_url_changed);
        connect (_ui.le_url, &QLineEdit.editing_finished, this, &Owncloud_setup_page.on_url_edit_finished);

        add_cert_dial = new AddCertificateDialog (this);
        connect (add_cert_dial, &Gtk.Dialog.accepted, this, &Owncloud_setup_page.on_certificate_accepted);
    }

    void Owncloud_setup_page.set_logo () {
        _ui.logo_label.set_pixmap (Theme.instance ().wizard_application_logo ());
    }

    void Owncloud_setup_page.setup_server_address_description_label () {
        const auto app_name = Theme.instance ().app_name_g_u_i ();
        _ui.server_address_description_label.on_set_text (tr ("The link to your %1 web interface when you open it in the browser.", "%1 will be replaced with the application name").arg (app_name));
    }

    void Owncloud_setup_page.set_server_url (string new_url) {
        _oc_wizard.set_registration (false);
        _o_c_url = new_url;
        if (_o_c_url.is_empty ()) {
            _ui.le_url.clear ();
            return;
        }

        _ui.le_url.on_set_text (_o_c_url);
    }

    void Owncloud_setup_page.setup_customization () {
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

        auto le_url_palette = _ui.le_url.palette ();
        le_url_palette.on_set_color (QPalette.Text, Qt.black);
        le_url_palette.on_set_color (QPalette.Base, Qt.white);
        _ui.le_url.set_palette (le_url_palette);
    }

    // slot hit from text_changed of the url entry field.
    void Owncloud_setup_page.on_url_changed (string url) {
        // Need to set next button as default button here because
        // otherwise the on OSX the next button does not stay the default
        // button
        auto next_button = qobject_cast<QPushButton> (_oc_wizard.button (QWizard.Next_button));
        if (next_button) {
            next_button.set_default (true);
        }

        _auth_type_known = false;

        string new_url = url;
        if (url.ends_with ("index.php")) {
            new_url.chop (9);
        }
        if (_oc_wizard && _oc_wizard.account ()) {
            string web_dav_path = _oc_wizard.account ().dav_path ();
            if (url.ends_with (web_dav_path)) {
                new_url.chop (web_dav_path.length ());
            }
            if (web_dav_path.ends_with (QLatin1Char ('/'))) {
                web_dav_path.chop (1); // cut off the slash
                if (url.ends_with (web_dav_path)) {
                    new_url.chop (web_dav_path.length ());
                }
            }
        }
        if (new_url != url) {
            _ui.le_url.on_set_text (new_url);
        }
    }

    void Owncloud_setup_page.on_url_edit_finished () {
        string url = _ui.le_url.full_text ();
        if (QUrl (url).is_relative () && !url.is_empty ()) {
            // no scheme defined, set one
            url.prepend ("https://");
            _ui.le_url.set_full_text (url);
        }
    }

    bool Owncloud_setup_page.is_complete () {
        return !_ui.le_url.text ().is_empty () && !_checking;
    }

    void Owncloud_setup_page.initialize_page () {
        customize_style ();

        WizardCommon.init_error_label (_ui.error_label);

        _auth_type_known = false;
        _checking = false;

        QAbstractButton *next_button = wizard ().button (QWizard.Next_button);
        auto *push_button = qobject_cast<QPushButton> (next_button);
        if (push_button) {
            push_button.set_default (true);
        }

        _ui.le_url.set_focus ();

        const auto is_server_url_overridden = !Theme.instance ().override_server_url ().is_empty ();
        if (is_server_url_overridden && !Theme.instance ().force_override_server_url ()) {
            // If the url is overwritten but we don't force to use that url
            // Just focus the next button to let the user navigate quicker
            if (next_button) {
                next_button.set_focus ();
            }
        } else if (is_server_url_overridden) {
            // If the overwritten url is not empty and we force this overwritten url
            // we just check the server type and switch to next page
            // immediately.
            set_commit_page (true);
            // Hack : set_commit_page () changes caption, but after an error this page could still be visible
            set_button_text (QWizard.Commit_button, tr ("&Next >"));
            validate_page ();
            set_visible (false);
        }
    }

    int Owncloud_setup_page.next_id () {
        switch (_auth_type) {
        case DetermineAuthTypeJob.Basic:
            return WizardCommon.Page_Http_creds;
        case DetermineAuthTypeJob.OAuth:
            return WizardCommon.Page_OAuth_creds;
        case DetermineAuthTypeJob.LoginFlowV2:
            return WizardCommon.Page_Flow2Auth_creds;
    #ifdef WITH_WEBENGINE
        case DetermineAuthTypeJob.WebViewFlow:
            return WizardCommon.Page_Web_view;
    #endif // WITH_WEBENGINE
        case DetermineAuthTypeJob.NoAuthType:
            return WizardCommon.Page_Http_creds;
        }
        Q_UNREACHABLE ();
    }

    string Owncloud_setup_page.url () {
        string url = _ui.le_url.full_text ().simplified ();
        return url;
    }

    bool Owncloud_setup_page.validate_page () {
        if (!_auth_type_known) {
            on_url_edit_finished ();
            string u = url ();
            QUrl qurl (u);
            if (!qurl.is_valid () || qurl.host ().is_empty ()) {
                on_set_error_string (tr ("Server address does not seem to be valid"), false);
                return false;
            }

            on_set_error_string (string (), false);
            _checking = true;
            on_start_spinner ();
            emit complete_changed ();

            emit determine_auth_type (u);
            return false;
        } else {
            // connecting is running
            on_stop_spinner ();
            _checking = false;
            emit complete_changed ();
            return true;
        }
    }

    void Owncloud_setup_page.on_set_auth_type (DetermineAuthTypeJob.AuthType type) {
        _auth_type_known = true;
        _auth_type = type;
        on_stop_spinner ();
    }

    void Owncloud_setup_page.on_set_error_string (string err, bool retry_http_only) {
        if (err.is_empty ()) {
            _ui.error_label.set_visible (false);
        } else {
            if (retry_http_only) {
                QUrl url (_ui.le_url.full_text ());
                if (url.scheme () == "https") {
                    // Ask the user how to proceed when connecting to a https:// URL fails.
                    // It is possible that the server is secured with client-side TLS certificates,
                    // but that it has no way of informing the owncloud client that this is the case.

                    Owncloud_connection_method_dialog dialog;
                    dialog.set_url (url);
                    // FIXME : Synchronous dialogs are not so nice because of event loop recursion
                    int ret_val = dialog.exec ();

                    switch (ret_val) {
                    case Owncloud_connection_method_dialog.No_TLS : {
                        url.set_scheme ("http");
                        _ui.le_url.set_full_text (url.to_string ());
                        // skip ahead to next page, since the user would expect us to retry automatically
                        wizard ().next ();
                    } break;
                    case Owncloud_connection_method_dialog.Client_Side_TLS:
                        add_cert_dial.show ();
                        break;
                    case Owncloud_connection_method_dialog.Closed:
                    case Owncloud_connection_method_dialog.Back:
                    default:
                        // No-op.
                        break;
                    }
                }
            }

            _ui.error_label.set_visible (true);
            _ui.error_label.on_set_text (err);
        }
        _checking = false;
        emit complete_changed ();
        on_stop_spinner ();
    }

    void Owncloud_setup_page.on_start_spinner () {
        _ui.progress_layout.set_enabled (true);
        _progress_indi.set_visible (true);
        _progress_indi.on_start_animation ();
    }

    void Owncloud_setup_page.on_stop_spinner () {
        _ui.progress_layout.set_enabled (false);
        _progress_indi.set_visible (false);
        _progress_indi.on_stop_animation ();
    }

    string subject_info_helper (QSslCertificate &cert, GLib.ByteArray &qa) {
        return cert.subject_info (qa).join (QLatin1Char ('/'));
    }

    //called during the validation of the client certificate.
    void Owncloud_setup_page.on_certificate_accepted () {
        QFile cert_file (add_cert_dial.get_certificate_path ());
        cert_file.open (QFile.ReadOnly);
        GLib.ByteArray cert_data = cert_file.read_all ();
        GLib.ByteArray cert_password = add_cert_dial.get_certificate_passwd ().to_local8Bit ();

        QBuffer cert_data_buffer (&cert_data);
        cert_data_buffer.open (QIODevice.ReadOnly);
        if (QSslCertificate.import_pkcs12 (&cert_data_buffer,
                &_oc_wizard._client_ssl_key, &_oc_wizard._client_ssl_certificate,
                &_oc_wizard._client_ssl_ca_certificates, cert_password)) {
            _oc_wizard._client_cert_bundle = cert_data;
            _oc_wizard._client_cert_password = cert_password;

            add_cert_dial.reinit (); // FIXME : Why not just have this only created on use?

            // The extracted SSL key and cert gets added to the QSslConfiguration in check_server ()
            validate_page ();
        } else {
            add_cert_dial.show_error_message (tr ("Could not load certificate. Maybe wrong password?"));
            add_cert_dial.show ();
        }
    }

    Owncloud_setup_page.~Owncloud_setup_page () = default;

    void Owncloud_setup_page.on_style_changed () {
        customize_style ();
    }

    void Owncloud_setup_page.customize_style () {
        set_logo ();

        if (_progress_indi) {
            const auto is_dark_background = Theme.is_dark_color (palette ().window ().color ());
            if (is_dark_background) {
                _progress_indi.on_set_color (Qt.white);
            } else {
                _progress_indi.on_set_color (Qt.black);
            }
        }

        WizardCommon.customize_hint_label (_ui.server_address_description_label);
    }

    } // namespace Occ
    