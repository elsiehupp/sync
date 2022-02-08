/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtCore>
//  #include <QtGui>
//  #include <QMessageBox>
//  #include <owncloudgui.h>
//  #include <cstdlib>
//  #include <QWizard>
//  #include <QLoggingCategory>
//  #include <QSslKey>
//  #include <QSslCertificate>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OwncloudWizard class
@ingroup gui
***********************************************************/
class OwncloudWizard : QWizard {

    //  Q_DECLARE_LOGGING_CATEGORY (lc_wizard)

    /***********************************************************
    ***********************************************************/
    public enum LogType {
        LOG_PLAIN,
        LOG_PARAGRAPH
    }


    /***********************************************************
    ***********************************************************/
    private AccountPointer account;
    private WelcomePage welcome_page;
    private OwncloudSetupPage setup_page;
    private OwncloudHttpCredsPage http_creds_page;
    private OwncloudOAuthCredsPage browser_creds_page;
    private Flow2AuthCredsPage flow2Creds_page;
    private OwncloudAdvancedSetupPage advanced_setup_page;
    private Owncloud_wizard_result_page result_page;
    private AbstractCredentialsWizardPage credentials_page = null;
    private WebViewPage web_view_page = null;

    string[] setup_log;

    bool registration = false;

    friend class OwncloudSetupWizard;

    /***********************************************************
    FIXME: Can those be local variables?
    Set from the OwncloudSetupPage, later used from
    OwncloudHttpCredsPage
    ***********************************************************/


    /***********************************************************
    Raw, potentially encrypted pkcs12 bundle provided by the user
    ***********************************************************/
    public GLib.ByteArray client_cert_bundle;


    /***********************************************************
    Password for the pkcs12
    ***********************************************************/
    public GLib.ByteArray client_cert_password;


    /***********************************************************
    Key extracted from pkcs12
    ***********************************************************/
    public QSslKey client_ssl_key;


    /***********************************************************
    Cert extracted from pkcs12
    ***********************************************************/
    public QSslCertificate client_ssl_certificate;


    /***********************************************************
    ***********************************************************/
    public GLib.List<QSslCertificate> client_ssl_ca_certificates;


    signal void clear_pending_requests ();
    signal void determine_auth_type (string );
    signal void connect_to_oc_url (string );
    signal void create_local_and_remote_folders (string , string );
    /***********************************************************
    Make sure to connect to this, rather than on_finished (int)!!
    ***********************************************************/
    signal void basic_setup_finished (int);
    signal void skip_folder_configuration ();
    signal void need_certificate ();
    signal void style_changed ();
    signal void on_activate ();


    /***********************************************************
    ***********************************************************/
    public OwncloudWizard (Gtk.Widget parent = null) {
        base (parent);
        this.account = null;
        this.welcome_page = new WelcomePage (this);
        this.setup_page = new OwncloudSetupPage (this);
        this.http_creds_page = new OwncloudHttpCredsPage (this);
        this.browser_creds_page = new OwncloudOAuthCredsPage (this);
        this.flow2Creds_page = new Flow2AuthCredsPage (this);
        this.advanced_setup_page = new OwncloudAdvancedSetupPage (this);
    //  #ifdef WITH_WEBENGINE
        this.web_view_page = (new WebViewPage (this);
    //  #else // WITH_WEBENGINE
    //      this.web_view_page (null)
    //  #endif // WITH_WEBENGINE {
        object_name ("owncloud_wizard");

        window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        page (WizardCommon.Pages.PAGE_WELCOME, this.welcome_page);
        page (WizardCommon.Pages.PAGE_SERVER_SETUP, this.setup_page);
        page (WizardCommon.Pages.PAGE_HTTP_CREDS, this.http_creds_page);
        page (WizardCommon.Pages.PAGE_OAUTH_CREDS, this.browser_creds_page);
        page (WizardCommon.Pages.PAGE_FLOW2AUTH_CREDS, this.flow2Creds_page);
        page (WizardCommon.Pages.PAGE_ADVANCED_SETUP, this.advanced_setup_page);
    //  #ifdef WITH_WEBENGINE
        page (WizardCommon.Pages.PAGE_WEB_VIEW, this.web_view_page);
    //  #endif WITH_WEBENGINE

        connect (this, &Gtk.Dialog.on_finished, this, &OwncloudWizard.basic_setup_finished);

        // note: on_start Id is set by the calling class depending on if the
        // welcome text is to be shown or not.

        connect (this, &QWizard.current_id_changed, this, &OwncloudWizard.on_current_page_changed);
        connect (this.setup_page, &OwncloudSetupPage.determine_auth_type, this, &OwncloudWizard.determine_auth_type);
        connect (this.http_creds_page, &OwncloudHttpCredsPage.connect_to_oc_url, this, &OwncloudWizard.connect_to_oc_url);
        connect (this.browser_creds_page, &OwncloudOAuthCredsPage.connect_to_oc_url, this, &OwncloudWizard.connect_to_oc_url);
        connect (this.flow2Creds_page, &Flow2AuthCredsPage.connect_to_oc_url, this, &OwncloudWizard.connect_to_oc_url);
    //  #ifdef WITH_WEBENGINE
        connect (this.web_view_page, &WebViewPage.connect_to_oc_url, this, &OwncloudWizard.connect_to_oc_url);
    //  #endif WITH_WEBENGINE
        connect (this.advanced_setup_page, &OwncloudAdvancedSetupPage.create_local_and_remote_folders,
            this, &OwncloudWizard.create_local_and_remote_folders);
        connect (this, &QWizard.custom_button_clicked, this, &OwncloudWizard.skip_folder_configuration);

        Theme theme = Theme.instance ();
        window_title (_("Add %1 account").arg (theme.app_name_gui ()));
        wizard_style (QWizard.Modern_style);
        option (QWizard.No_back_button_on_start_page);
        option (QWizard.No_back_button_on_last_page);
        option (QWizard.No_cancel_button);
        button_text (QWizard.Custom_button1, _("Skip folders configuration"));

        // Change the next buttons size policy since we hide it on the
        // welcome page but want it to fill it's space that we don't get
        // flickering when the page changes
        var next_button_size_policy = button (QWizard.Next_button).size_policy ();
        next_button_size_policy.retain_size_when_hidden (true);
        button (QWizard.Next_button).size_policy (next_button_size_policy);

        // Connect style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        connect (this, &OwncloudWizard.style_changed, this.setup_page, &OwncloudSetupPage.on_style_changed);
        connect (this, &OwncloudWizard.style_changed, this.advanced_setup_page, &OwncloudAdvancedSetupPage.on_style_changed);
        connect (this, &OwncloudWizard.style_changed, this.flow2Creds_page, &Flow2AuthCredsPage.on_style_changed);

        customize_style ();

        // allow Flow2 page to poll on window activation
        connect (this, &OwncloudWizard.on_activate, this.flow2Creds_page, &Flow2AuthCredsPage.on_poll_now);

        adjust_wizard_size ();
        center_window ();
    }


    /***********************************************************
    ***********************************************************/
    public void account (AccountPointer account) {
        this.account = account;
    }


    /***********************************************************
    ***********************************************************/
    public AccountPointer account () {
        return this.account;
    }


    /***********************************************************
    ***********************************************************/
    public void oc_url (string url) {
        this.setup_page.server_url (url);
    }


    /***********************************************************
    ***********************************************************/
    public void oc_url () {
        string url = field ("OCUrl").to_string ().simplified ();
        return url;
    }


    /***********************************************************
    ***********************************************************/
    public bool registration () {
        return this.registration;
    }


    /***********************************************************
    ***********************************************************/
    public void registration (bool registration) {
        this.registration = registration;
    }


    /***********************************************************
    ***********************************************************/
    public string[] selective_sync_blocklist () {
        return this.advanced_setup_page.selective_sync_blocklist ();
    }

    /***********************************************************
    ***********************************************************/
    public string local_folder () {
        return this.advanced_setup_page.local_folder ();
    }


    /***********************************************************
    ***********************************************************/
    public bool use_virtual_file_sync () {
        return this.advanced_setup_page.use_virtual_file_sync ();
    }


    /***********************************************************
    ***********************************************************/
    public bool is_confirm_big_folder_checked () {
        return this.advanced_setup_page.is_confirm_big_folder_checked ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_remote_folder (string remote_folder) {
        this.advanced_setup_page.on_remote_folder (remote_folder);
    }


    /***********************************************************
    ***********************************************************/
    public void on_display_error (string message, bool retry_http_only) {
        switch (current_id ()) {
        case WizardCommon.Pages.PAGE_SERVER_SETUP:
            this.setup_page.on_error_string (message, retry_http_only);
            break;

        case WizardCommon.Pages.PAGE_HTTP_CREDS:
            this.http_creds_page.on_error_string (message);
            break;

        case WizardCommon.Pages.PAGE_ADVANCED_SETUP:
            this.advanced_setup_page.on_error_string (message);
            break;
        }
    }


    /***********************************************************
    ***********************************************************/
    public AbstractCredentials get_credentials () {
        if (this.credentials_page) {
            return this.credentials_page.get_credentials ();
        }

        return null;
    }


    /***********************************************************
    ***********************************************************/
    public void bring_to_top () {
        // bring wizard to top
        OwncloudGui.raise_dialog (this);
    }


    /***********************************************************
    ***********************************************************/
    public void center_window () {
        const var wizard_window = window ();
        const var screen = QGuiApplication.screen_at (wizard_window.position ())
            ? QGuiApplication.screen_at (wizard_window.position ())
            : QGuiApplication.primary_screen ();
        const var screen_geometry = screen.geometry ();
        const var window_geometry = wizard_window.geometry ();
        const var new_window_position = screen_geometry.center () - QPoint (window_geometry.width () / 2, window_geometry.height () / 2);
        wizard_window.move (new_window_position);
    }


    /***********************************************************
    Shows a dialog explaining the virtual files mode and warning about it
    being experimental. Calles the callback with true if enabling was
    chosen.
    ***********************************************************/
    public static void ask_experimental_virtual_files_feature (Gtk.Widget receiver, std.function<void (bool enable)> callback) {
        const var best_vfs_mode = best_available_vfs_mode ();
        QMessageBox msg_box = null;
        QPushButton accept_button = null;
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


    /***********************************************************
    ***********************************************************/
    public void on_auth_type (DetermineAuthTypeJob.AuthType type) {
        this.setup_page.on_auth_type (type);

        if (type == DetermineAuthTypeJob.AuthType.OAUTH) {
            this.credentials_page = this.browser_creds_page;
        } else if (type == DetermineAuthTypeJob.AuthType.LOGIN_FLOW_V2) {
            this.credentials_page = this.flow2Creds_page;
    //  #ifdef WITH_WEBENGINE
        } else if (type == DetermineAuthTypeJob.WEB_VIEW_FLOW) {
            this.credentials_page = this.web_view_page;
    //  #endif WITH_WEBENGINE
        } else { // try Basic auth even for "Unknown"
            this.credentials_page = this.http_creds_page;
        }
        next ();
    }

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_append_to_configuration_log (string message, LogType type) {
        this.setup_log << message;
        GLib.debug (lc_wizard) << "Setup-Log : " << message;
    }


    /***********************************************************
    TODO: update this function
    ***********************************************************/
    public void on_current_page_changed (int identifier) {
        GLib.debug (lc_wizard) << "Current Wizard page changed to " << identifier;

        const var next_button_as_default = [this] () {
            var next_button = qobject_cast<QPushButton> (button (QWizard.Next_button));
            if (next_button) {
                next_button.default (true);
            }
        }

        if (identifier == WizardCommon.Pages.PAGE_WELCOME) {
            // Set next button to just hidden so it retains it's layout
            button (QWizard.Next_button).hidden (true);
            // Need to set it from here, otherwise it has no effect
            this.welcome_page.login_button_default ();
        } else if (
    //  #ifdef WITH_WEBENGINE
            identifier == WizardCommon.Pages.PAGE_WEB_VIEW ||
    //  #endif WITH_WEBENGINE
            identifier == WizardCommon.Pages.PAGE_FLOW2AUTH_CREDS) {
            button_layout ({
                QWizard.Stretch,
                QWizard.Back_button
            });
        } else if (identifier == WizardCommon.Pages.PAGE_ADVANCED_SETUP) {
            button_layout ({
                QWizard.Stretch,
                QWizard.Custom_button1,
                QWizard.Back_button,
                QWizard.Finish_button
            });
            next_button_as_default ();
        } else {
            button_layout ({
                QWizard.Stretch,
                QWizard.Back_button,
                QWizard.Next_button
            });
            next_button_as_default ();
        }

        if (identifier == WizardCommon.Pages.PAGE_SERVER_SETUP) {
            /* emit */ clear_pending_requests ();
        }

        if (identifier == WizardCommon.Pages.PAGE_ADVANCED_SETUP && (this.credentials_page == this.browser_creds_page || this.credentials_page == this.flow2Creds_page)) {
            // For OAuth, disable the back button in the PAGE_ADVANCED_SETUP because we don't want
            // to re-open the browser.
            button (QWizard.Back_button).enabled (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_successful_step () {
        const int identifier (current_id ());

        switch (identifier) {
        case WizardCommon.Pages.PAGE_HTTP_CREDS:
            this.http_creds_page.connected ();
            break;

        case WizardCommon.Pages.PAGE_OAUTH_CREDS:
            this.browser_creds_page.connected ();
            break;

        case WizardCommon.Pages.PAGE_FLOW2AUTH_CREDS:
            this.flow2Creds_page.connected ();
            break;

    //  #ifdef WITH_WEBENGINE
        case WizardCommon.Pages.PAGE_WEB_VIEW:
            this.web_view_page.connected ();
            break;
    //  #endif WITH_WEBENGINE

        case WizardCommon.Pages.PAGE_ADVANCED_SETUP:
            this.advanced_setup_page.directories_created ();
            break;

        case WizardCommon.Pages.PAGE_SERVER_SETUP:
            GLib.warn (lc_wizard, "Should not happen at this stage.");
            break;
        }

        OwncloudGui.raise_dialog (this);
        if (next_id () == -1) {
            disconnect (this, &Gtk.Dialog.on_finished, this, &OwncloudWizard.basic_setup_finished);
            /* emit */ basic_setup_finished (Gtk.Dialog.Accepted);
        } else {
            next ();
        }
    }


    /***********************************************************
    ***********************************************************/
    protected void change_event (QEvent event) {
        switch (event.type ()) {

        case QEvent.StyleChange:
        case QEvent.PaletteChange:
        case QEvent.ThemeChange:
            customize_style ();

            // Notify the other widgets (Dark-/Light-Mode switching)
            /* emit */ style_changed ();
            break;
        case QEvent.ActivationChange:
            if (is_active_window ())
                /* emit */ activate ();
            break;
        default:
            break;
        }

        QWizard.change_event (event);
    }


    /***********************************************************
    ***********************************************************/
    private void customize_style () {
        // HINT : Customize wizard's own style here, if necessary in the future (Dark-/Light-Mode switching)

        // Set background colors
        var wizard_palette = palette ();
        const var background_color = wizard_palette.color (QPalette.Window);
        wizard_palette.on_color (QPalette.Base, background_color);
        // Set separator color
        wizard_palette.on_color (QPalette.Mid, background_color);

        palette (wizard_palette);
    }


    /***********************************************************
    ***********************************************************/
    private void adjust_wizard_size () {
        const var page_sizes = calculate_wizard_page_sizes ();
        const var longest_side = calculate_longest_side_of_wizard_pages (page_sizes);

        resize (QSize (longest_side, longest_side));
    }


    /***********************************************************
    ***********************************************************/
    private int calculate_longest_side_of_wizard_pages (GLib.List<QSize> page_sizes) {
        return std.accumulate (std.cbegin (page_sizes), std.cend (page_sizes), 0, [] (int current, QSize size) {
            return std.max ({
                current, size.width (), size.height ()
            });
        });
    }


    /***********************************************************
    ***********************************************************/
    private GLib.List<QSize> calculate_wizard_page_sizes () {
        GLib.List<QSize> page_sizes;
        const var p_ids = page_ids ();

        std.transform (p_ids.cbegin (), p_ids.cend (), std.back_inserter (page_sizes), [this] (int page_id) {
            var p = page (page_id);
            p.adjust_size ();
            return p.size_hint ();
        });

        return page_sizes;
    }

} // class OwncloudWizard

} // namespace Ui
} // namespace Occ