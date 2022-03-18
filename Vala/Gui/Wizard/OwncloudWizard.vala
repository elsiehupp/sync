/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>
Copyright (C) by Krzesimir Nowak <krzesimir@endocode.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtCore>
//  #include <QtGui>
//  #include <Gtk.MessageBox>
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
public class OwncloudWizard : QWizard {

    /***********************************************************
    ***********************************************************/
    public enum LogType {
        LOG_PLAIN,
        LOG_PARAGRAPH
    }


    /***********************************************************
    ***********************************************************/
    unowned Account account { public get; public set; }
    private WelcomePage welcome_page;
    private OwncloudSetupPage setup_page;
    private OwncloudHttpCredsPage http_creds_page;
    private OwncloudOAuthCredsPage browser_creds_page;
    private Flow2AuthCredsPage flow_2_creds_page;
    private OwncloudAdvancedSetupPage advanced_setup_page;
    private OwncloudWizardResultPage result_page;
    private AbstractCredentialsWizardPage credentials_page = null;
    private WebViewPage web_view_page = null;

    string[] setup_log;

    string oc_url {
        public get {
            return field ("OCUrl").to_string ().simplified ();
        }
        public set {
            this.setup_page.server_url (value);
        }
    }

    bool registration {
        public get {
            return this.registration;
        }
        public set {
            this.registration = value;
        }
    }

    //  friend class OwncloudSetupWizard;

    /***********************************************************
    FIXME: Can those be local variables?
    Set from the OwncloudSetupPage, later used from
    OwncloudHttpCredsPage
    ***********************************************************/


    /***********************************************************
    Raw, potentially encrypted pkcs12 bundle provided by the user
    ***********************************************************/
    public string client_cert_bundle;

    /***********************************************************
    Password for the pkcs12
    ***********************************************************/
    public string client_cert_password;

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

    internal signal void clear_pending_requests ();
    internal signal void determine_auth_type (string value);
    internal signal void connect_to_oc_url (string value);
    internal signal void create_local_and_remote_folders (string value1, string value2);

    /***********************************************************
    Make sure to connect to this, rather than on_signal_finished (int)!!
    ***********************************************************/
    internal signal void basic_setup_finished (int value);
    internal signal void skip_folder_configuration ();
    internal signal void need_certificate ();
    internal signal void signal_style_changed ();
    internal signal void signal_activate ();


    /***********************************************************
    ***********************************************************/
    public OwncloudWizard (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.account = null;
        this.registration = false;
        this.welcome_page = new WelcomePage (this);
        this.setup_page = new OwncloudSetupPage (this);
        this.http_creds_page = new OwncloudHttpCredsPage (this);
        this.browser_creds_page = new OwncloudOAuthCredsPage (this);
        this.flow_2_creds_page = new Flow2AuthCredsPage (this);
        this.advanced_setup_page = new OwncloudAdvancedSetupPage (this);
    //  #ifdef WITH_WEBENGINE
        this.web_view_page = new WebViewPage (this);
    //  #else // WITH_WEBENGINE
    //      this.web_view_page (null)
    //  #endif // WITH_WEBENGINE {
        object_name ("owncloud_wizard");

        window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);
        page (WizardCommon.Pages.PAGE_WELCOME, this.welcome_page);
        page (WizardCommon.Pages.PAGE_SERVER_SETUP, this.setup_page);
        page (WizardCommon.Pages.PAGE_HTTP_CREDS, this.http_creds_page);
        page (WizardCommon.Pages.PAGE_OAUTH_CREDS, this.browser_creds_page);
        page (WizardCommon.Pages.PAGE_FLOW2AUTH_CREDS, this.flow_2_creds_page);
        page (WizardCommon.Pages.PAGE_ADVANCED_SETUP, this.advanced_setup_page);
    //  #ifdef WITH_WEBENGINE
        page (WizardCommon.Pages.PAGE_WEB_VIEW, this.web_view_page);
    //  #endif WITH_WEBENGINE

        this.signal_finished.connect (
            this.basic_setup_finished
        );

        // note: start id is set by the calling class depending on if the
        // welcome text is to be shown or not.

        this.current_id_changed.connect (
            this.on_signal_current_page_changed
        );
        this.setup_page.signal_determine_auth_type.connect (
            this.on_signal_determine_auth_type
        );
        this.http_creds_page.signal_connect_to_oc_url.connect (
            this.on_signal_connect_to_oc_url
        );
        this.browser_creds_page.signal_connect_to_oc_url.connect (
            this.on_signal_connect_to_oc_url
        );
        this.flow_2_creds_page.signal_connect_to_oc_url.connect (
            this.on_signal_connect_to_oc_url
        );
        this.web_view_page.signal_connect_to_oc_url.connect (
            this.on_signal_connect_to_oc_url
        );
        this.advanced_setup_page.signal_create_local_and_remote_folders.connect (
            this.on_signal_create_local_and_remote_folders
        );
        this.custom_button_clicked.connect (
            this.on_signal_skip_folder_configuration
        );

        window_title (_("Add %1 account").printf (Theme.instance.app_name_gui));
        wizard_style (QWizard.ModernStyle);
        option (QWizard.NoBackButtonOnStartPage);
        option (QWizard.NoBackButtonOnLastPage);
        option (QWizard.NoCancelButton);
        button_text (QWizard.CustomButton1, _("Skip folders configuration"));

        // Change the next buttons size policy since we hide it on the
        // welcome page but want it to fill it's space that we don't get
        // flickering when the page changes
        var next_button_size_policy = button (QWizard.NextButton).size_policy ();
        next_button_size_policy.retain_size_when_hidden (true);
        button (QWizard.NextButton).size_policy (next_button_size_policy);

        // Connect signal_style_changed events to our widgets, so they can adapt (Dark-/Light-Mode switching)
        this.signal_style_changed.connect (
            this.setup_page.on_signal_style_changed
        );
        this.signal_style_changed.connect (
            this.advanced_setup_page.on_signal_style_changed
        );
        this.signal_style_changed.connect (
            this.flow_2_creds_page.on_signal_style_changed
        );

        customize_style ();

        // allow Flow2 page to poll on window activation
        this.signal_activate.connect (
            this.flow_2_creds_page.on_signal_poll_now
        );

        adjust_wizard_size ();
        center_window ();
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
    public void on_signal_remote_folder (string remote_folder) {
        this.advanced_setup_page.on_signal_remote_folder (remote_folder);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_display_error (string message, bool retry_http_only) {
        switch (current_id ()) {
        case WizardCommon.Pages.PAGE_SERVER_SETUP:
            this.setup_page.on_signal_error_string (message, retry_http_only);
            break;

        case WizardCommon.Pages.PAGE_HTTP_CREDS:
            this.http_creds_page.on_signal_error_string (message);
            break;

        case WizardCommon.Pages.PAGE_ADVANCED_SETUP:
            this.advanced_setup_page.on_signal_error_string (message);
            break;
        }
    }


    /***********************************************************
    ***********************************************************/
    public AbstractCredentials credentials () {
        if (this.credentials_page) {
            return this.credentials_page.credentials ();
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
        const var screen = Gtk.Application.screen_at (wizard_window.position ())
            ? Gtk.Application.screen_at (wizard_window.position ())
            : Gtk.Application.primary_screen ();
        const var screen_geometry = screen.geometry ();
        const var window_geometry = wizard_window.geometry ();
        const var new_window_position = screen_geometry.center () - QPoint (window_geometry.width () / 2, window_geometry.height () / 2);
        wizard_window.move (new_window_position);
    }


    private delegate void CallBack (bool enable);


    /***********************************************************
    Shows a dialog explaining the virtual files mode and warning about it
    being experimental. Calles the callback with true if enabling was
    chosen.
    ***********************************************************/
    public static void ask_experimental_virtual_files_feature (Gtk.Widget receiver, CallBack callback) {
        const var best_vfs_mode = best_available_vfs_mode ();
        Gtk.MessageBox message_box = null;
        QPushButton accept_button = null;
        switch (best_vfs_mode) {
        case Vfs.WindowsCfApi:
            callback (true);
            return;
        case Vfs.WithSuffix:
            message_box = new Gtk.MessageBox (
                Gtk.MessageBox.Warning,
                _("Enable experimental feature?"),
                _("When the \"virtual files\" mode is enabled no files will be downloaded initially. "
                + "Instead, a tiny \"%1\" file will be created for each file that exists on the server. "
                + "The contents can be downloaded by running these files or by using their context menu."
                + "\n\n"
                + "The virtual files mode is mutually exclusive with selective sync. "
                + "Currently unselected folders will be translated to online-only folders "
                + "and your selective sync settings will be reset."
                + "\n\n"
                + "Switching to this mode will on_signal_abort any currently running synchronization."
                + "\n\n"
                + "This is a new, experimental mode. If you decide to use it, please report any "
                + "issues that come up.")
                    .printf (APPLICATION_DOTVIRTUALFILE_SUFFIX),
                Gtk.MessageBox.NoButton, receiver);
            accept_button = message_box.add_button (_("Enable experimental placeholder mode"), Gtk.MessageBox.AcceptRole);
            message_box.add_button (_("Stay safe"), Gtk.MessageBox.RejectRole);
            break;
        case Vfs.XAttr:
        case Vfs.Off:
            GLib.assert_not_reached ();
        }

        message_box.accepted.connect (
            receiver.on_message_box_accepted
        );
        message_box.open ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_message_box_accepted (CallBack callback, Gtk.MessageBox message_box, QPushButton accept_button) {
        callback (message_box.clicked_button () == accept_button);
        message_box.delete_later ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_auth_type (DetermineAuthTypeJob.AuthType type) {
        this.setup_page.on_signal_auth_type (type);

        if (type == DetermineAuthTypeJob.AuthType.OAUTH) {
            this.credentials_page = this.browser_creds_page;
        } else if (type == DetermineAuthTypeJob.AuthType.LOGIN_FLOW_V2) {
            this.credentials_page = this.flow_2_creds_page;
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
    public void on_signal_append_to_configuration_log (string message, LogType type) {
        this.setup_log + message;
        GLib.debug ("Setup-Log: " + message);
    }


    /***********************************************************
    TODO: update this function
    ***********************************************************/
    public void on_signal_current_page_changed (int identifier) {
        GLib.debug ("Current Wizard page changed to " + identifier);

        if (identifier == WizardCommon.Pages.PAGE_WELCOME) {
            // Set next button to just hidden so it retains it's layout
            button (QWizard.NextButton).hidden (true);
            // Need to set it from here, otherwise it has no effect
            this.welcome_page.login_button_default ();
        } else if (
    //  #ifdef WITH_WEBENGINE
            identifier == WizardCommon.Pages.PAGE_WEB_VIEW ||
    //  #endif WITH_WEBENGINE
            identifier == WizardCommon.Pages.PAGE_FLOW2AUTH_CREDS) {
            button_layout ({
                QWizard.Stretch,
                QWizard.BackButton
            });
        } else if (identifier == WizardCommon.Pages.PAGE_ADVANCED_SETUP) {
            button_layout ({
                QWizard.Stretch,
                QWizard.CustomButton1,
                QWizard.BackButton,
                QWizard.FinishButton
            });
            next_button_as_default ();
        } else {
            button_layout ({
                QWizard.Stretch,
                QWizard.BackButton,
                QWizard.NextButton
            });
            next_button_as_default ();
        }

        if (identifier == WizardCommon.Pages.PAGE_SERVER_SETUP) {
            /* emit */ clear_pending_requests ();
        }

        if (identifier == WizardCommon.Pages.PAGE_ADVANCED_SETUP && (this.credentials_page == this.browser_creds_page || this.credentials_page == this.flow_2_creds_page)) {
            // For OAuth, disable the back button in the PAGE_ADVANCED_SETUP because we don't want
            // to re-open the browser.
            button (QWizard.BackButton).enabled (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void next_button_as_default () {
        var next_button = (QPushButton) button (QWizard.NextButton);
        if (next_button) {
            next_button.default (true);
        }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_successful_step () {
        const int identifier = current_id ();

        switch (identifier) {
        case WizardCommon.Pages.PAGE_HTTP_CREDS:
            this.http_creds_page.connected ();
            break;

        case WizardCommon.Pages.PAGE_OAUTH_CREDS:
            this.browser_creds_page.connected ();
            break;

        case WizardCommon.Pages.PAGE_FLOW2AUTH_CREDS:
            this.flow_2_creds_page.connected ();
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
            GLib.warning ();
            break;
        }

        OwncloudGui.raise_dialog (this);
        if (next_id () == -1) {
            disconnect (this, Gtk.Dialog.signal_finished, this, OwncloudWizard.basic_setup_finished);
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
            /* emit */ signal_style_changed ();
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
        wizard_palette.on_signal_color (QPalette.Base, background_color);
        // Set separator color
        wizard_palette.on_signal_color (QPalette.Mid, background_color);

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
        //  return std.accumulate (
        //      std.cbegin (page_sizes),
        //      std.cend (page_sizes),
        //      0,
        //      [] (int current, QSize size) {
        //      return std.max ({
        //          current, size.width (), size.height ()
        //      });
        //  });
    }


    /***********************************************************
    ***********************************************************/
    private GLib.List<QSize> calculate_wizard_page_sizes () {
        GLib.List<QSize> page_sizes;
        const var p_ids = page_ids ();

        //  std.transform (
        //      p_ids.cbegin (),
        //      p_ids.cend (),
        //      std.back_inserter (page_sizes),
        //      [this] (int page_id) {
        //          var p = page (page_id);
        //          p.adjust_size ();
        //          return p.size_hint ();
        //      }
        //  );

        return page_sizes;
    }

} // class OwncloudWizard

} // namespace Ui
} // namespace Occ