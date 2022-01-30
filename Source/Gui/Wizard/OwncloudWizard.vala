/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QtCore>
// #include <QtGui>
// #include <QMessageBox>
// #include <owncloudgui.h>

// #include <cstdlib>

// #include <QWizard>
// #include <QLoggingCategory>
// #include <QSslKey>
// #include <QSslCertificate>

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lc_wizard)

class Owncloud_oauth_creds_page;
class Abstract_credentials_wizard_page;

/***********************************************************
@brief The OwncloudWizard class
@ingroup gui
***********************************************************/
class OwncloudWizard : QWizard {

    public enum Log_type {
        Log_plain,
        Log_paragraph
    };

    public OwncloudWizard (Gtk.Widget parent = nullptr);

    public void set_account (AccountPointer account);


    public AccountPointer account ();


    public void set_oCUrl (string );


    public bool registration ();


    public void set_registration (bool registration);

    public void setup_custom_media (QVariant, QLabel *);


    public string oc_url ();


    public string local_folder ();


    public string[] selective_sync_blocklist ();


    public bool use_virtual_file_sync ();


    public bool is_confirm_big_folder_checked ();

    public void on_display_error (string , bool retry_http_only);


    public AbstractCredentials get_credentials ();

    public void bring_to_top ();


    public void center_window ();


    /***********************************************************
    Shows a dialog explaining the virtual files mode and warning about it
    being experimental. Calles the callback with true if enabling was
    chosen.
    ***********************************************************/
    public static void ask_experimental_virtual_files_feature (Gtk.Widget receiver, std.function<void (bool enable)> &callback);

    // FIXME : Can those be local variables?
    // Set from the Owncloud_setup_page, later used from Owncloud_http_creds_page
    public GLib.ByteArray _client_cert_bundle; // raw, potentially encrypted pkcs12 bundle provided by the user
    public GLib.ByteArray _client_cert_password; // password for the pkcs12
    public QSslKey _client_ssl_key; // key extracted from pkcs12
    public QSslCertificate _client_ssl_certificate; // cert extracted from pkcs12
    public GLib.List<QSslCertificate> _client_ssl_ca_certificates;


    public void on_set_auth_type (DetermineAuthTypeJob.AuthType type);


    public void on_set_remote_folder (string );


    public void on_append_to_configuration_log (string msg, Log_type type = Log_paragraph);


    public void on_current_page_changed (int);


    public void on_successful_step ();

signals:
    void clear_pending_requests ();
    void determine_auth_type (string );
    void connect_to_oc_url (string );
    void create_local_and_remote_folders (string , string );
    // make sure to connect to this, rather than on_finished (int)!!
    void basic_setup_finished (int);
    void skip_folder_configuration ();
    void need_certificate ();
    void style_changed ();
    void on_activate ();


    protected void change_event (QEvent *) override;


    private void customize_style ();
    private void adjust_wizard_size ();
    private int calculate_longest_side_of_wizard_pages (GLib.List<QSize> &page_sizes);
    private GLib.List<QSize> calculate_wizard_page_sizes ();

    private AccountPointer _account;
    private Welcome_page _welcome_page;
    private Owncloud_setup_page _setup_page;
    private Owncloud_http_creds_page _http_creds_page;
    private Owncloud_oauth_creds_page _browser_creds_page;
    private Flow2Auth_creds_page _flow2Creds_page;
    private Owncloud_advanced_setup_page _advanced_setup_page;
    private Owncloud_wizard_result_page _result_page;
    private Abstract_credentials_wizard_page _credentials_page = nullptr;
    private Web_view_page _web_view_page = nullptr;

    string[] _setup_log;

    bool _registration = false;

    friend class OwncloudSetupWizard;
};


    OwncloudWizard.OwncloudWizard (Gtk.Widget parent)
        : QWizard (parent)
        , _account (nullptr)
        , _welcome_page (new Welcome_page (this))
        , _setup_page (new Owncloud_setup_page (this))
        , _http_creds_page (new Owncloud_http_creds_page (this))
        , _browser_creds_page (new Owncloud_oauth_creds_page)
        , _flow2Creds_page (new Flow2Auth_creds_page)
        , _advanced_setup_page (new Owncloud_advanced_setup_page (this))
    #ifdef WITH_WEBENGINE
        , _web_view_page (new Web_view_page (this))
    #else // WITH_WEBENGINE
        , _web_view_page (nullptr)
    #endif // WITH_WEBENGINE {
        set_object_name ("owncloud_wizard");

        set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        set_page (WizardCommon.Page_Welcome, _welcome_page);
        set_page (WizardCommon.Page_Server_setup, _setup_page);
        set_page (WizardCommon.Page_Http_creds, _http_creds_page);
        set_page (WizardCommon.Page_OAuth_creds, _browser_creds_page);
        set_page (WizardCommon.Page_Flow2Auth_creds, _flow2Creds_page);
        set_page (WizardCommon.Page_Advanced_setup, _advanced_setup_page);
    #ifdef WITH_WEBENGINE
        set_page (WizardCommon.Page_Web_view, _web_view_page);
    #endif // WITH_WEBENGINE

        connect (this, &Gtk.Dialog.on_finished, this, &OwncloudWizard.basic_setup_finished);

        // note : on_start Id is set by the calling class depending on if the
        // welcome text is to be shown or not.

        connect (this, &QWizard.current_id_changed, this, &OwncloudWizard.on_current_page_changed);
        connect (_setup_page, &Owncloud_setup_page.determine_auth_type, this, &OwncloudWizard.determine_auth_type);
        connect (_http_creds_page, &Owncloud_http_creds_page.connect_to_oc_url, this, &OwncloudWizard.connect_to_oc_url);
        connect (_browser_creds_page, &Owncloud_oauth_creds_page.connect_to_oc_url, this, &OwncloudWizard.connect_to_oc_url);
        connect (_flow2Creds_page, &Flow2Auth_creds_page.connect_to_oc_url, this, &OwncloudWizard.connect_to_oc_url);
    #ifdef WITH_WEBENGINE
        connect (_web_view_page, &Web_view_page.connect_to_oc_url, this, &OwncloudWizard.connect_to_oc_url);
    #endif // WITH_WEBENGINE
        connect (_advanced_setup_page, &Owncloud_advanced_setup_page.create_local_and_remote_folders,
            this, &OwncloudWizard.create_local_and_remote_folders);
        connect (this, &QWizard.custom_button_clicked, this, &OwncloudWizard.skip_folder_configuration);

        Theme theme = Theme.instance ();
        set_window_title (_("Add %1 account").arg (theme.app_name_gui ()));
        set_wizard_style (QWizard.Modern_style);
        set_option (QWizard.No_back_button_on_start_page);
        set_option (QWizard.No_back_button_on_last_page);
        set_option (QWizard.No_cancel_button);
        set_button_text (QWizard.Custom_button1, _("Skip folders configuration"));

        // Change the next buttons size policy since we hide it on the
        // welcome page but want it to fill it's space that we don't get
        // flickering when the page changes
        var next_button_size_policy = button (QWizard.Next_button).size_policy ();
        next_button_size_policy.set_retain_size_when_hidden (true);
        button (QWizard.Next_button).set_size_policy (next_button_size_policy);

        // Connect style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        connect (this, &OwncloudWizard.style_changed, _setup_page, &Owncloud_setup_page.on_style_changed);
        connect (this, &OwncloudWizard.style_changed, _advanced_setup_page, &Owncloud_advanced_setup_page.on_style_changed);
        connect (this, &OwncloudWizard.style_changed, _flow2Creds_page, &Flow2Auth_creds_page.on_style_changed);

        customize_style ();

        // allow Flow2 page to poll on window activation
        connect (this, &OwncloudWizard.on_activate, _flow2Creds_page, &Flow2Auth_creds_page.on_poll_now);

        adjust_wizard_size ();
        center_window ();
    }

    void OwncloudWizard.center_window () {
        const var wizard_window = window ();
        const var screen = QGuiApplication.screen_at (wizard_window.pos ())
            ? QGuiApplication.screen_at (wizard_window.pos ())
            : QGuiApplication.primary_screen ();
        const var screen_geometry = screen.geometry ();
        const var window_geometry = wizard_window.geometry ();
        const var new_window_position = screen_geometry.center () - QPoint (window_geometry.width () / 2, window_geometry.height () / 2);
        wizard_window.move (new_window_position);
    }

    void OwncloudWizard.adjust_wizard_size () {
        const var page_sizes = calculate_wizard_page_sizes ();
        const var longest_side = calculate_longest_side_of_wizard_pages (page_sizes);

        resize (QSize (longest_side, longest_side));
    }

    GLib.List<QSize> OwncloudWizard.calculate_wizard_page_sizes () {
        GLib.List<QSize> page_sizes;
        const var p_ids = page_ids ();

        std.transform (p_ids.cbegin (), p_ids.cend (), std.back_inserter (page_sizes), [this] (int page_id) {
            var p = page (page_id);
            p.adjust_size ();
            return p.size_hint ();
        });

        return page_sizes;
    }

    int OwncloudWizard.calculate_longest_side_of_wizard_pages (GLib.List<QSize> &page_sizes) {
        return std.accumulate (std.cbegin (page_sizes), std.cend (page_sizes), 0, [] (int current, QSize &size) {
            return std.max ({
                current, size.width (), size.height ()
            });
        });
    }

    void OwncloudWizard.set_account (AccountPointer account) {
        _account = account;
    }

    AccountPointer OwncloudWizard.account () {
        return _account;
    }

    string OwncloudWizard.local_folder () {
        return (_advanced_setup_page.local_folder ());
    }

    string[] OwncloudWizard.selective_sync_blocklist () {
        return _advanced_setup_page.selective_sync_blocklist ();
    }

    bool OwncloudWizard.use_virtual_file_sync () {
        return _advanced_setup_page.use_virtual_file_sync ();
    }

    bool OwncloudWizard.is_confirm_big_folder_checked () {
        return _advanced_setup_page.is_confirm_big_folder_checked ();
    }

    string OwncloudWizard.oc_url () {
        string url = field ("OCUrl").to_string ().simplified ();
        return url;
    }

    bool OwncloudWizard.registration () {
        return _registration;
    }

    void OwncloudWizard.set_registration (bool registration) {
        _registration = registration;
    }

    void OwncloudWizard.on_set_remote_folder (string remote_folder) {
        _advanced_setup_page.on_set_remote_folder (remote_folder);
    }

    void OwncloudWizard.on_successful_step () {
        const int id (current_id ());

        switch (id) {
        case WizardCommon.Page_Http_creds:
            _http_creds_page.set_connected ();
            break;

        case WizardCommon.Page_OAuth_creds:
            _browser_creds_page.set_connected ();
            break;

        case WizardCommon.Page_Flow2Auth_creds:
            _flow2Creds_page.set_connected ();
            break;

    #ifdef WITH_WEBENGINE
        case WizardCommon.Page_Web_view:
            _web_view_page.set_connected ();
            break;
    #endif // WITH_WEBENGINE

        case WizardCommon.Page_Advanced_setup:
            _advanced_setup_page.directories_created ();
            break;

        case WizardCommon.Page_Server_setup:
            GLib.warn (lc_wizard, "Should not happen at this stage.");
            break;
        }

        OwncloudGui.raise_dialog (this);
        if (next_id () == -1) {
            disconnect (this, &Gtk.Dialog.on_finished, this, &OwncloudWizard.basic_setup_finished);
            emit basic_setup_finished (Gtk.Dialog.Accepted);
        } else {
            next ();
        }
    }

    void OwncloudWizard.on_set_auth_type (DetermineAuthTypeJob.AuthType type) {
        _setup_page.on_set_auth_type (type);

        if (type == DetermineAuthTypeJob.OAuth) {
            _credentials_page = _browser_creds_page;
        } else if (type == DetermineAuthTypeJob.LoginFlowV2) {
            _credentials_page = _flow2Creds_page;
    #ifdef WITH_WEBENGINE
        } else if (type == DetermineAuthTypeJob.WebViewFlow) {
            _credentials_page = _web_view_page;
    #endif // WITH_WEBENGINE
        } else { // try Basic auth even for "Unknown"
            _credentials_page = _http_creds_page;
        }
        next ();
    }

    // TODO : update this function
    void OwncloudWizard.on_current_page_changed (int id) {
        GLib.debug (lc_wizard) << "Current Wizard page changed to " << id;

        const var set_next_button_as_default = [this] () {
            var next_button = qobject_cast<QPushButton> (button (QWizard.Next_button));
            if (next_button) {
                next_button.set_default (true);
            }
        };

        if (id == WizardCommon.Page_Welcome) {
            // Set next button to just hidden so it retains it's layout
            button (QWizard.Next_button).set_hidden (true);
            // Need to set it from here, otherwise it has no effect
            _welcome_page.set_login_button_default ();
        } else if (
    #ifdef WITH_WEBENGINE
            id == WizardCommon.Page_Web_view ||
    #endif // WITH_WEBENGINE
            id == WizardCommon.Page_Flow2Auth_creds) {
            set_button_layout ({
                QWizard.Stretch,
                QWizard.Back_button
            });
        } else if (id == WizardCommon.Page_Advanced_setup) {
            set_button_layout ({
                QWizard.Stretch,
                QWizard.Custom_button1,
                QWizard.Back_button,
                QWizard.Finish_button
            });
            set_next_button_as_default ();
        } else {
            set_button_layout ({
                QWizard.Stretch,
                QWizard.Back_button,
                QWizard.Next_button
            });
            set_next_button_as_default ();
        }

        if (id == WizardCommon.Page_Server_setup) {
            emit clear_pending_requests ();
        }

        if (id == WizardCommon.Page_Advanced_setup && (_credentials_page == _browser_creds_page || _credentials_page == _flow2Creds_page)) {
            // For OAuth, disable the back button in the Page_Advanced_setup because we don't want
            // to re-open the browser.
            button (QWizard.Back_button).set_enabled (false);
        }
    }

    void OwncloudWizard.on_display_error (string msg, bool retry_http_only) {
        switch (current_id ()) {
        case WizardCommon.Page_Server_setup:
            _setup_page.on_set_error_string (msg, retry_http_only);
            break;

        case WizardCommon.Page_Http_creds:
            _http_creds_page.on_set_error_string (msg);
            break;

        case WizardCommon.Page_Advanced_setup:
            _advanced_setup_page.on_set_error_string (msg);
            break;
        }
    }

    void OwncloudWizard.on_append_to_configuration_log (string msg, Log_type /*type*/) {
        _setup_log << msg;
        GLib.debug (lc_wizard) << "Setup-Log : " << msg;
    }

    void OwncloudWizard.set_oCUrl (string url) {
        _setup_page.set_server_url (url);
    }

    AbstractCredentials *OwncloudWizard.get_credentials () {
        if (_credentials_page) {
            return _credentials_page.get_credentials ();
        }

        return nullptr;
    }

    void OwncloudWizard.change_event (QEvent e) {
        switch (e.type ()) {
        case QEvent.StyleChange:
        case QEvent.PaletteChange:
        case QEvent.ThemeChange:
            customize_style ();

            // Notify the other widgets (Dark-/Light-Mode switching)
            emit style_changed ();
            break;
        case QEvent.ActivationChange:
            if (is_active_window ())
                emit activate ();
            break;
        default:
            break;
        }

        QWizard.change_event (e);
    }

    void OwncloudWizard.customize_style () {
        // HINT : Customize wizard's own style here, if necessary in the future (Dark-/Light-Mode switching)

        // Set background colors
        var wizard_palette = palette ();
        const var background_color = wizard_palette.color (QPalette.Window);
        wizard_palette.on_set_color (QPalette.Base, background_color);
        // Set separator color
        wizard_palette.on_set_color (QPalette.Mid, background_color);

        set_palette (wizard_palette);
    }

    void OwncloudWizard.bring_to_top () {
        // bring wizard to top
        OwncloudGui.raise_dialog (this);
    }

    void OwncloudWizard.ask_experimental_virtual_files_feature (Gtk.Widget receiver, std.function<void (bool enable)> &callback) {
        const var best_vfs_mode = best_available_vfs_mode ();
        QMessageBox msg_box = nullptr;
        QPushButton accept_button = nullptr;
        switch (best_vfs_mode) {
        case Vfs.WindowsCfApi:
            callback (true);
            return;
        case Vfs.WithSuffix:
            msg_box = new QMessageBox (
                QMessageBox.Warning,
                _("Enable experimental feature?"),
                _("When the \"virtual files\" mode is enabled no files will be downloaded initially. "
                   "Instead, a tiny \"%1\" file will be created for each file that exists on the server. "
                   "The contents can be downloaded by running these files or by using their context menu."
                   "\n\n"
                   "The virtual files mode is mutually exclusive with selective sync. "
                   "Currently unselected folders will be translated to online-only folders "
                   "and your selective sync settings will be reset."
                   "\n\n"
                   "Switching to this mode will on_abort any currently running synchronization."
                   "\n\n"
                   "This is a new, experimental mode. If you decide to use it, please report any "
                   "issues that come up.")
                    .arg (APPLICATION_DOTVIRTUALFILE_SUFFIX),
                QMessageBox.NoButton, receiver);
            accept_button = msg_box.add_button (_("Enable experimental placeholder mode"), QMessageBox.AcceptRole);
            msg_box.add_button (_("Stay safe"), QMessageBox.RejectRole);
            break;
        case Vfs.XAttr:
        case Vfs.Off:
            Q_UNREACHABLE ();
        }

        connect (msg_box, &QMessageBox.accepted, receiver, [callback, msg_box, accept_button] {
            callback (msg_box.clicked_button () == accept_button);
            msg_box.delete_later ();
        });
        msg_box.open ();
    }

    } // end namespace
    