/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QtCore>
//  #include TOKEN_A
//  #include <QtGui>
//  #include <QStyle>
//  #include <QApplicatio
//  #include <QSslSocket>
//  #include <QSvgRenderer>

//  #ifdef THEME_INCLUDE
//  const int Mirall Occ // namespace hack to make old themes work
//  const int QUOTEME (M) #M
//  const int INCLUDE_FILE (M) QUOTEME (M)
//  #include INCLUDE_FILE (THEME_INCLUDE)
//  #undef Mirall
//  #endif

//  #include <QIcon>

namespace Occ {


/***********************************************************
@brief The Theme class
@ingroup libsync
***********************************************************/
class Theme : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum CustomMediaType {
        /***********************************************************
        onwCloud connect page
        ***********************************************************/
        OC_SETUP_TOP,
        OC_SETUP_SIDE,
        OC_SETUP_BOTTOM,
        /***********************************************************
        ownCloud connect result page
        ***********************************************************/
        OC_SETUP_RESULT_BOTTOM
    }

    /***********************************************************
    returns a singleton instance.
    ***********************************************************/
    static Theme instance {
        public get {
            if (Theme.instance == null) {
                Theme.instance = new THEME_CLASS ();
                // some themes may not call the base ctor
                Theme.instance.mono = false;
            }
            return Theme.instance;
        }
        private set {
            Theme.instance = value;
        }
    }

    private bool mono = false;
    /***********************************************************
    Define if the systray icons should be using mono design
    Retrieve wether to use mono icons for systray
    ***********************************************************/
    bool systray_use_mono_icons {
        public get {
            return this.mono;
        }
        public set {
            this.mono = value;
            /* emit */ systray_use_mono_icons_changed (mono);
        }
    }

//  #ifndef TOKEN_AUTH_ONLY
    // mutable
    private GLib.HashTable<string, QIcon> icon_cache;
//  #endif


    /***********************************************************
    ***********************************************************/
    signal void systray_use_mono_icons_changed (bool value);


    /***********************************************************
    ***********************************************************/
    protected Theme () {
        base (null);
    }


    /***********************************************************
    @brief is_branded indicates if the current application is
    branded

    By default, it is considered
    different from "Nextcloud".

    @return true if branded, false otherwise
    ***********************************************************/
    public bool is_branded () {
        return app_name_gui () != "Nextcloud";
    }


    /***********************************************************
    @brief app_name_gui - Human readable application name.

    Use and redefine this if
    special chars and such.

    By default, the name is derived from the APPLICATION_NAME
    cmake variable.

    @return string with human readable app name.
    ***********************************************************/
    public string app_name_gui () {
        return APPLICATION_NAME;
    }


    /***********************************************************
    @brief app_name - Application name (short)

    Use and redefine this as an application name. Keep it
    straight as it is used for config files etc. If yo
    name in the GUI, redefine app_name_gui.

    By default, the name is derived from
    cmake variable, and should be the same. This method is only
    reimplementable for legacy reasons.

    Warning: Do not modify this value, as many things, e.g.
    settings depend on it! You most likely want to modify
    \ref app_name_gui ().

    @return string with app name.
    ***********************************************************/
    public string app_name () {
        return APPLICATION_SHORTNAME;
    }


    /***********************************************************
    @brief Returns full path to an online state icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri state_online_image_source () {
        return image_path_to_url (theme_image_path ("state-ok"));
    }


    /***********************************************************
    @brief Returns full path to an offline state icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri state_offline_image_source () {
        return image_path_to_url (theme_image_path ("state-offline", 16));
    }


    /***********************************************************
    @brief Returns full path to an online user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri status_online_image_source () {
        return image_path_to_url (theme_image_path ("user-status-online", 16));
    }


    /***********************************************************
    @brief Returns full path to an do not disturb user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri status_do_not_disturb_image_source () {
        return image_path_to_url (theme_image_path ("user-status-dnd", 16));
    }


    /***********************************************************
    @brief Returns full path to an away user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri status_away_image_source () {
        return image_path_to_url (theme_image_path ("user-status-away", 16));
    }


    /***********************************************************
    @brief Returns full path to an invisible user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri status_invisible_image_source () {
        return image_path_to_url (theme_image_path ("user-status-invisible", 64));
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri sync_status_ok () {
        return image_path_to_url (theme_image_path ("state-ok", 16));
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri sync_status_error () {
        return image_path_to_url (theme_image_path ("state-error", 16));
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri sync_status_running () {
        return image_path_to_url (theme_image_path ("state-sync", 16));
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri sync_status_pause () {
        return image_path_to_url (theme_image_path ("state-pause", 16));
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri sync_status_warning () {
        return image_path_to_url (theme_image_path ("state-warning", 16));
    }


    /***********************************************************
    ***********************************************************/
    public GLib.Uri folder_offline () {
        return image_path_to_url (theme_image_path ("state-offline"));
    }


    /***********************************************************
    @brief config_filename
    @return the name of the config file.
    ***********************************************************/
    public string config_filename () {
        return APPLICATION_EXECUTABLE + ".config";
    }


    /***********************************************************
    ***********************************************************/
//  #ifndef TOKEN_AUTH_ONLY
    public static string hidpi_filename (string filename, QPaint_device dev = null) {
        if (!Theme.is_hidpi (dev)) {
            return filename;
        }
        // try to find a 2x version

        int dot_index = filename.last_index_of ('.');
        if (dot_index != -1) {
            string at2xfilename = filename;
            at2xfilename.insert (dot_index, "@2x");
            if (GLib.File.exists (at2xfilename)) {
                return at2xfilename;
            }
        }
        return filename;
    }


    /***********************************************************
    ***********************************************************/
    public static string hidpi_filename_for_color (string icon_name, Gtk.Color background_color, QPaint_device dev = null) {
        var is_dark_background = Theme.is_dark_color (background_color);

        const string icon_path = Theme.theme_prefix + (is_dark_background ? "white/" : "black/") + icon_name;

        return Theme.hidpi_filename (icon_path, dev);
    }


    /***********************************************************
    ***********************************************************/
    public static bool is_hidpi (QPaint_device dev = null) {
        var device_pixel_ratio = dev ? dev.device_pixel_ratio () : Gtk.Application.primary_screen ().device_pixel_ratio ();
        return device_pixel_ratio > 1;
    }


    /***********************************************************
    Get an sync state icon
    ***********************************************************/
    public QIcon sync_state_icon (SyncResult.Status status, bool sys_tray = false) {
        // FIXME : Mind the size!
        string status_icon;

        switch (status) {
        case SyncResult.Status.UNDEFINED:
            // this can happen if no sync connections are configured.
            status_icon = "state-warning";
            break;
        case SyncResult.Status.NOT_YET_STARTED:
        case SyncResult.Status.SYNC_RUNNING:
            status_icon = "state-sync";
            break;
        case SyncResult.Status.SYNC_ABORT_REQUESTED:
        case SyncResult.Status.PAUSED:
            status_icon = "state-pause";
            break;
        case SyncResult.Status.SYNC_PREPARE:
        case SyncResult.Status.SUCCESS:
            status_icon = "state-ok";
            break;
        case SyncResult.Status.PROBLEM:
            status_icon = "state-warning";
            break;
        case SyncResult.Status.ERROR:
        case SyncResult.Status.SETUP_ERROR:
        // FIXME : Use state-problem once we have an icon.
        default:
            status_icon = "state-error";
        }

        return theme_icon (status_icon, sys_tray);
    }


    /***********************************************************
    ***********************************************************/
    public QIcon folder_disabled_icon () {
        return theme_icon ("state-pause");
    }


    /***********************************************************
    ***********************************************************/
    public QIcon folder_offline_icon (bool sys_tray) {
        return theme_icon ("state-offline", sys_tray);
    }


    /***********************************************************
    ***********************************************************/
    public QIcon application_icon () {
        return theme_icon (APPLICATION_ICON_NAME + "-icon");
    }


    /***********************************************************
    ***********************************************************/
    public string status_header_text (SyncResult.Status status) {
        string result_str;

        switch (status) {
        case SyncResult.Status.UNDEFINED:
            return _("theme", "Status undefined");
        case SyncResult.Status.NOT_YET_STARTED:
            return _("theme", "Waiting to on_signal_start sync");
        case SyncResult.Status.SYNC_RUNNING:
            return _("theme", "Sync is running");
        case SyncResult.Status.SUCCESS:
            return _("theme", "Sync Success");
        case SyncResult.Status.PROBLEM:
            return _("theme", "Sync Success, some files were ignored.");
        case SyncResult.Status.ERROR:
            return _("theme", "Sync Error");
        case SyncResult.Status.SETUP_ERROR:
            return _("theme", "Setup Error");
        case SyncResult.Status.SYNC_PREPARE:
            return _("theme", "Preparing to sync");
        case SyncResult.Status.SYNC_ABORT_REQUESTED:
            return _("theme", "Aborting …");
        case SyncResult.Status.PAUSED:
            return _("theme", "Sync is paused");
        }
        return "";
    }


    /***********************************************************
    ***********************************************************/
    public string version ();


    /***********************************************************
    Characteristics: bool if more than one sync folder is allowed
    
    If this option returns true, the client only supports one
    folder to sync.
    The Add-Button is removed accordingly.
    ***********************************************************/
    public bool single_sync_folder () {
        return false;
    }


    /***********************************************************
    When true, client works with multiple accounts.
    ***********************************************************/
    public bool multi_account () {
        return true;
    }


    /***********************************************************
    URL to documentation.

    This is opened in the browser when the "Help" action is
    selected from the tray menu.

    If the function is overridden to return an empty string the
    action is removed from the menu.

    Defaults to Nextclouds client documentation website.
    ***********************************************************/
    public string help_url () {
        return APPLICATION_HELP_URL;
    }


    /***********************************************************
    The url to use for showing help on conflicts.

    If the function is overridden to return an empty string no
    help link will be sh

    Defaults to help_url () + "conflicts.html", which is a page
    in ownCloud's client documentation website. If help_url ()
    is empty, this function will also return the empty string.
    ***********************************************************/
    public string conflict_help_url () {
        var base_url = help_url ();
        if (base_url.is_empty ())
            return "";
        if (!base_url.has_suffix ('/'))
            base_url.append ('/');
        return base_url + "conflicts.html";
    }


    /***********************************************************
    Setting a value here will pre-define the server url.

    The respective UI controls will be disabled only if
    force_override_server_url () is true
    ***********************************************************/
    public string override_server_url () {
        return APPLICATION_SERVER_URL;
    }


    /***********************************************************
    Enforce a pre-defined server url.

    When true, the respective UI controls will be disabled
    ***********************************************************/
    public bool force_override_server_url () {
        return APPLICATION_SERVER_URL_ENFORCE;
    }


    /***********************************************************
    Enable OCSP stapling for SSL handshakes

    When true, peer will be requested for Online Certificate
    Status Protocol response
    ***********************************************************/
    public bool enable_stapling_ocsp () {
        return APPLICATION_OCSP_STAPLING_ENABLED;
    }


    /***********************************************************
    Enforce SSL validity

    When true, trusting the untrusted certificate is not allowed
    ***********************************************************/
    public bool forbid_bad_ssl () {
        return APPLICATION_FORBID_BAD_SSL;
    }


    /***********************************************************
    This is only usefull when previous version had a different
    override_server_url with a different auth type in that case
    you should then specify "http" or "shibboleth". Normally
    this should be left empty.
    ***********************************************************/
    public string force_config_auth_type () {
        return "";
    }


    /***********************************************************
    The default folder name without path on the server at setup
    time.
    ***********************************************************/
    public string default_server_folder () {
        return "/";
    }


    /***********************************************************
    The default folder name without path on the client side at
    setup time.
    ***********************************************************/
    public string default_client_folder () {
        return app_name ();
    }


    /***********************************************************
    Override to encforce a particular locale, i.e. "de" or "pt_BR"
    ***********************************************************/
    public string enforced_locale () {
        return "";
    }


    /***********************************************************
    colored, white or black
    ***********************************************************/
    public string systray_icon_flavor (bool mono) {
        string flavor;
        if (mono) {
            flavor = Utility.has_dark_systray () ? "white" : "black";
        } else {
            flavor = "colored";
        }
        return flavor;
    }

//  #ifndef TOKEN_AUTH_ONLY
    /***********************************************************
    Override to use a string or a custom image name.
    The default implementation will try to look up
    :/client/theme/<type>.png
    ***********************************************************/
    public GLib.Variant custom_media (CustomMediaType type) {
        GLib.Variant re;
        string key;

        switch (type) {
        case CustomMediaType.OC_SETUP_TOP:
            key = "CustomMediaType.OC_SETUP_TOP";
            break;
        case CustomMediaType.OC_SETUP_SIDE:
            key = "CustomMediaType.OC_SETUP_SIDE";
            break;
        case CustomMediaType.OC_SETUP_BOTTOM:
            key = "CustomMediaType.OC_SETUP_BOTTOM";
            break;
        case CustomMediaType.OC_SETUP_RESULT_BOTTOM:
            key = "CustomMediaType.OC_SETUP_RESULT_BOTTOM"\;
            break;
        }

        string img_path = string (Theme.theme_prefix) + string.from_latin1 ("colored/%1.png").arg (key);
        if (GLib.File.exists (img_path)) {
            QPixmap pix (img_path);
            if (pix.is_null ()) {
                // pixmap loading hasn't succeeded. We take the text instead.
                re.value (key);
            } else {
                re.value (pix);
            }
        }
        return re;
    }


    /***********************************************************
    @return color for the setup wizard
    ***********************************************************/
    public Gtk.Color wizard_header_title_color () {
        return {APPLICATION_WIZARD_HEADER_TITLE_COLOR};
    }


    /***********************************************************
    @return color for the setup wizard.
    ***********************************************************/
    public Gtk.Color wizard_header_background_color () {
        return {APPLICATION_WIZARD_HEADER_BACKGROUND_COLOR};
    }


    /***********************************************************
    ***********************************************************/
    public QPixmap wizard_application_logo () {
        if (!Theme.is_branded ()) {
            return QPixmap (Theme.hidpi_filename (string (Theme.theme_prefix) + "colored/wizard-nextcloud.png"));
        }
    // #ifdef APPLICATION_WIZARD_USE_CUSTOM_LOGO
        var use_svg = should_prefer_svg ();
        const string logo_base_path = string (Theme.theme_prefix) + "colored/wizard_logo";
        if (use_svg) {
            var max_height = Theme.is_hidpi () ? 200 : 100;
            var max_width = 2 * max_height;
            var icon = new Gtk.Icon (logo_base_path + ".svg");
            var size = icon.actual_size (QSize (max_width, max_height));
            return icon.pixmap (size);
        } else {
            return QPixmap (hidpi_filename (logo_base_path + ".png"));
        }
    // #else
        var size = Theme.is_hidpi () ? : 200 : 100;
        return application_icon ().pixmap (size);
    // #endif
    }


    /***********************************************************
    @return logo for the setup wizard.
    ***********************************************************/
    public QPixmap wizard_header_logo () {
    // #ifdef APPLICATION_WIZARD_USE_CUSTOM_LOGO
        var use_svg = should_prefer_svg ();
        const string logo_base_path = string (Theme.theme_prefix) + "colored/wizard_logo";
        if (use_svg) {
            var max_height = 64;
            var max_width = 2 * max_height;
            var icon = new Gtk.Icon (logo_base_path + ".svg");
            var size = icon.actual_size (QSize (max_width, max_height));
            return icon.pixmap (size);
        } else {
            return QPixmap (hidpi_filename (logo_base_path + ".png"));
        }
    // #else
        return application_icon ().pixmap (64);
    // #endif
    }


    /***********************************************************
    The default implementation creates a
    background based on
    \ref wizard_header_title_color ().

    @return banner for the setup wizard.
    ***********************************************************/
    public QPixmap wizard_header_banner () {
        Gtk.Color c = wizard_header_background_color ();
        if (!c.is_valid ())
            return QPixmap ();

        QSize size (750, 78);
        if (var screen = Gtk.Application.primary_screen ()) {
            // Adjust the the size if there is a different DPI. (Issue #6156)
            // Indeed, this size need to be big enough to for the banner height, and the wizard's width
            var ratio = screen.logical_dots_per_inch () / 96.;
            if (ratio > 1.)
                size *= ratio;
        }
        QPixmap pix (size);
        pix.fill (wizard_header_background_color ());
        return pix;
    }
//  #endif

    /***********************************************************
    The SHA sum of the released git commit
    ***********************************************************/
    public string git_sha1 () {
        string dev_string;
    // #ifdef GIT_SHA1
        const string github_prefix =
            "https://github.com/nextcloud/desktop/commit/";
        const string git_sha1 = GIT_SHA1;
        dev_string = _("nextcloud_theme.about ()",
            "<p><small>Built from Git revision <a href=\"%1\">%2</a>"
            " on %3, %4 using Qt %5, %6</small></p>")
                        .arg (github_prefix + git_sha1)
                        .arg (git_sha1.left (6))
                        .arg (__DATE__)
                        .arg (__TIME__)
                        .arg (q_version ())
                        .arg (QSslSocket.ssl_library_version_string ());
    // #endif
        return dev_string;
    }


    /***********************************************************
    About dialog contents
    ***********************************************************/
    public string about () {
        //  return MIRALL_VERSION_STRING;
        // Shorten Qt's OS name : "macOS Mojave (10.14)" . "macOS"
        string[] os_string_list = Utility.platform_name ().split (' ');
        string os_name = os_string_list.at (0);

        string dev_string;
        // : Example text : "<p>Nextcloud Desktop Client</p>"   (%1 is the application name)
        dev_string = _("<p>%1 Desktop Client</p>")
                .arg (APPLICATION_NAME);

        dev_string += _("<p>Version %1. For more information please click <a href='%2'>here</a>.</p>")
                .arg (string.from_latin1 (MIRALL_STRINGIFY (MIRALL_VERSION)) + string (" (%1)").arg (os_name))
                .arg (help_url ());

        dev_string += _("<p><small>Using files plugin : %1</small></p>")
                        .arg (Vfs.Mode.to_string (best_available_vfs_mode ()));
        dev_string += "<br>%1"
                .arg (QSysInfo.product_type () % '-' % QSysInfo.kernel_version ());

        return dev_string;
    }


    /***********************************************************
    Legal notice dialog version detail contents
    ***********************************************************/
    string about_details () {
        string dev_string;
        dev_string = _("<p>Version %1. For more information please click <a href='%2'>here</a>.</p>")
                .arg (MIRALL_VERSION_STRING)
                .arg (help_url ());

        dev_string += _("<p>This release was supplied by %1</p>")
                .arg (APPLICATION_VENDOR);

        dev_string += git_sha1 ();

        return dev_string;
    }




    /***********************************************************
    Check if mono icons are available
    ***********************************************************/
    public bool mono_icons_available () {
        string theme_dir = string (Theme.theme_prefix) + string.from_latin1 ("%1/").arg (Theme.instance ().systray_icon_flavor (true));
        return QDir (theme_dir).exists ();
    }


    /***********************************************************
    @brief Where to check for new Updates.
    ***********************************************************/
    public string update_check_url () {
        return APPLICATION_UPDATE_URL;
    }


    /***********************************************************
    When true, the setup wizard will show the selective sync
    dialog by default and default to nothing selected
    ***********************************************************/
    public bool wizard_selective_sync_default_nothing () {
        return false;
    }


    /***********************************************************
    Default option for the new_big_folder_size_limit. Size in MB
    of the maximum size of folder before we ask the confirmation.
    Set -1 to never ask confirmation. 0 to ask confirmation for
    every folder.
    ***********************************************************/
    public int64 new_big_folder_size_limit () {
        // Default to 500MB
        return 500;
    }


    /***********************************************************
    Hide the checkbox that says "Ask for confirmation before
    synchronizing folders larger than X MB" in the account wizard
    ***********************************************************/
    public bool wizard_hide_folder_size_limit_checkbox () {
        return false;
    }


    /***********************************************************
    Hide the checkbox that says "Ask for confirmation before
    synchronizing external storages" in the account wizard
    ***********************************************************/
    public bool wizard_hide_external_storage_confirmation_checkbox () {
        return false;
    }


    /***********************************************************
    @brief Sharing options

    Allow link sharing and or user/group sharing
    ***********************************************************/
    public bool link_sharing () {
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public bool user_group_sharing () {
        return true;
    }


    /***********************************************************
    If this returns true, the user cannot configure the proxy
    in the network settings. The proxy settings will be disabled
    in the configuration dialog.

    Default returns false.
    ***********************************************************/
    public bool force_system_network_proxy () {
        return false;
    }


    /***********************************************************
    @brief How to handle the user identifier

    @value UserIdentifierType.USER_NAME Wizard asks for user name a
    @value UserIdentifierType.EMAIL Wizard asks for an email as ID
    @value UserIdentifierType.CUSTOM Specify string in \ref custom_user_id
    ***********************************************************/
    public enum UserIdentifierType {
        USER_NAME = 0,
        EMAIL,
        CUSTOM
    }


    /***********************************************************
    @brief What to display as the user identifier (e.g. in the wizards)

    @return UserIdentifierType.USER_NAME, unless reimplemented
    ***********************************************************/
    public UserIdentifierType user_identifier_type () {
        return UserIdentifierType.USER_NAME;
    }


    /***********************************************************
    @brief Allows to customize the type of user ID (e.g. user
    name, email)

    @note This string cannot be translated, but is still
    useful for referencing brand name IDs (e.g. "ACME ID", when
    using ACME.)

    @return An empty string, unless reimplemented
    ***********************************************************/
    public string custom_user_id () {
        return "";
    }


    /***********************************************************
    @brief Demo string to be displayed when no text has been
    entered for the user identifier (e.g. mylogin@company.com)

    @return An empty string, unless reimplemented
    ***********************************************************/
    public string user_id_hint () {
        return "";
    }


    /***********************************************************
    @brief Postfix that will be enforced in a URL. e.g.
           ".myhosting.com".

    @return An empty string, unless reimplemented
    ***********************************************************/
    public string wizard_url_postfix () {
        return "";
    }


    /***********************************************************
    @brief String that will be shown as long as no text has
    been entered by the user.

    @return An empty string, unless reimplemented
    ***********************************************************/
    public string WIZARD_URL_HINT () {
        return "";
    }


    /***********************************************************
    @brief the server folder that should be queried for the
    quota information

    This can be configured to show the quota infromation for a
    different folder than the root. This is the folder on which
    the client will do PROPFIND calls to get
    "quota-available-bytes" and "quota-used-bytes"

    Default: "/"
    ***********************************************************/
    public string quota_base_folder () {
        return "/";
    }


    /***********************************************************
    The OAuth client_id, secret pair.
    Note that client that change these value cannot connect to
    un-branded owncloud servers.
    ***********************************************************/
    public string oauth_client_id () {
        return "xd_xOt13JKxym1B1Qc_encf2XDk_lAex_m_bFwi_t9j6Efhh_hFJhs2KM9jbj_tmf8JBXE69";
    }


    /***********************************************************
    ***********************************************************/
    public string oauth_client_secret () {
        return "UBntm_lj_c2y_yCe_hwsyj73Uwo9TAaec_aet_rw_mw0x_ycv_nL9y_rd_l_s_ui0h_uAHfv_c_hFe_fh";
    }


    /***********************************************************
    @brief What should be output for the --version command line
    switch.

    By default, it's a combination of app_name (), version (),
    the GIT SHA1 and some important dependency versions.
    ***********************************************************/
    public string version_switch_output () {
        string help_text;
        QTextStream stream = new QTextStream (&help_text);
        stream += app_name ();
        stream += " version ";
        stream += version () + Qt.endl;
    // #ifdef GIT_SHA1
        stream += "Git revision " + GIT_SHA1 + Qt.endl;
    // #endif
        stream += "Using Qt " + q_version () + ", built against Qt " + QT_VERSION_STR + Qt.endl;

        if (!QGuiApplication.platform_name ().is_empty ())
            stream += "Using Qt platform plugin '" + QGuiApplication.platform_name () + "'" + Qt.endl;

        stream += "Using '" + QSslSocket.ssl_library_version_string () + "'" + Qt.endl;
        stream += "Running on " + Utility.platform_name (", " + QSysInfo.current_cpu_architecture () + Qt.endl;
        return help_text;
    }
	
	/***********************************************************
    @brief Request suitable QIcon resource depending on the
    background colour of the parent widget.

    This should be replaced (TODO) by a real theming
    implementation for the client UI
    (actually 2019/09/13 only systray theming).
    ***********************************************************/
	public QIcon ui_theme_icon (string icon_name, bool ui_has_dark_background) {
        string icon_path = string (Theme.theme_prefix) + (ui_has_dark_background ? "white/" : "black/") + icon_name;
        string icn_path = icon_path.to_utf8 ().const_data ();
        return new Gtk.Icon (QPixmap (icon_path));
    }


    /***********************************************************
    @brief Perform a calculation to check if a colour is dark or
    light and accounts for different sensitivity of the human eye.

    @return True if the specified colour is dark.

    2019/12/08 : Moved here from SettingsDialog.
    ***********************************************************/
    public static bool is_dark_color (Gtk.Color color) {
        // account for different sensitivity of the human eye to certain colors
        double treshold = 1.0 - (0.299 * color.red () + 0.587 * color.green () + 0.114 * color.blue ()) / 255.0;
        return treshold > 0.5;
    }


    /***********************************************************
    @brief Return the colour to be used for HTML links (e.g.
    used in Gtk.Label), based on the current app palette or given
    colour (Dark-/Light-Mode switching).
    @brief Return the colour to be used for HTML links (e.g.
    used in Gtk.Label), based on the current app palette
    (Dark-/Light-Mode switching).

    @return Background-aware colour for HTML links, based on
    the current app palette or given colour.
    @return Background-aware colour for HTML links, based on
    the current app palette.

    2019/12/08 : Implemented for the Dark Mode on macOS,
    because the app palette can not account for that (Qt 5.12.5).
    2019/12/08: Implemented for the Dark Mode on macOS, because
    the app palette can not account for that (Qt 5.12.5).
    ***********************************************************/
    public static Gtk.Color get_background_aware_link_color (Gtk.Color background_color = QGuiApplication.palette ().base ().color ()) {
        return is_dark_color (background_color) ? Gtk.Color ("#6193dc") : QGuiApplication.palette ().color (QPalette.Link)
    }


    /***********************************************************
    @brief Appends a CSS-style colour value to all HTML link
    tags in a given string, based on the current app palette or
    given colour (Dark-/Light-Mode switching).

    2019/12/08: Implemented for the Dark Mode on macOS, because
    the app palette can not account for that (Qt 5.12.5).

    This way we also avoid having certain strings re-translated
    on Transifex.
    ***********************************************************/
    public static void replace_link_color_string_background_aware (string link_string, Gtk.Color background_color = QGuiApplication.palette ().color (QPalette.Base)) {
        replace_link_color_string (link_string, get_background_aware_link_color (background_color));
    }


    /***********************************************************
    @brief Appends a CSS-style colour value to all HTML link
    tags in a given string, as specified by new_color.

    2019/12/19: Implemented for the Dark Mode on macOS, because
    the app palette can not account for that (Qt 5.12.5).

    This way we also avoid having certain strings re-translated
    on Transifex.
    ***********************************************************/
    public static void replace_link_color_string (string link_string, Gtk.Color new_color) {
        link_string.replace (QRegularExpression (" (<a href|<a style='color:# ([a-z_a-Z0-9]{6});' href)"), string.from_latin1 ("<a style='color:%1;' href").arg (new_color.name ()));
    }


    /***********************************************************
    @brief Creates a colour-aware icon based on the specified
    palette's base colour (Dark-/Light-Mode switching).

    @return QIcon, colour-aware (inverted on dark backgrounds).

    2019/12/09: Moved here from SettingsDialog.
    ***********************************************************/
    public static QIcon create_color_aware_icon (string name, QPalette palette = QGuiApplication.palette ()) {
        QSvgRenderer renderer = new QSvgRenderer (name);
        Gtk.Image img = new Gtk.Image (64, 64, Gtk.Image.Format_ARGB32);
        img.fill (Qt.Global_color.transparent);
        QPainter img_painter = new QPainter  (&img);
        Gtk.Image inverted = new Gtk.Image (64, 64, Gtk.Image.Format_ARGB32);
        inverted.fill (Qt.Global_color.transparent);
        QPainter inv_painter (&inverted);

        renderer.render (&img_painter);
        renderer.render (&inv_painter);

        inverted.invert_pixels (Gtk.Image.Invert_rgb);

        QIcon icon;
        if (Theme.is_dark_color (palette.color (QPalette.Base))) {
            icon.add_pixmap (QPixmap.from_image (inverted));
        } else {
            icon.add_pixmap (QPixmap.from_image (img));
        }
        if (Theme.is_dark_color (palette.color (QPalette.Highlighted_text))) {
            icon.add_pixmap (QPixmap.from_image (img), QIcon.Normal, QIcon.On);
        } else {
            icon.add_pixmap (QPixmap.from_image (inverted), QIcon.Normal, QIcon.On);
        }
        return icon;
    }


    /***********************************************************
    @brief Creates a colour-aware pixmap based on the specified
    palette's base colour (Dark-/Light-Mode switching).

    @return QPixmap, colour-aware (inverted on dark backgrounds).

    2019/12/09: Adapted from create_color_aware_icon.
    ***********************************************************/
    public static QPixmap create_color_aware_pixmap (string name, QPalette palette = QGuiApplication.palette ()) {
        Gtk.Image img = new Gtk.Image (name);
        Gtk.Image inverted = new Gtk.Image (img);
        inverted.invert_pixels (Gtk.Image.Invert_rgb);

        QPixmap pixmap;
        if (Theme.is_dark_color (palette.color (QPalette.Base))) {
            pixmap = QPixmap.from_image (inverted);
        } else {
            pixmap = QPixmap.from_image (img);
        }
        return pixmap;
    }


    /***********************************************************
    @brief Whether to show the option to create folders using
    "files".

    By default, the options are not shown unless experimental
    options are manually enabled in the configuration file.
    ***********************************************************/
    public bool show_virtual_files_option () {
        var vfs_mode = best_available_vfs_mode ();
        return ConfigFile ().show_experimental_options () || vfs_mode == Vfs.WindowsCfApi;
    }


    /***********************************************************
    ***********************************************************/
    public bool enforce_virtual_files_sync_folder () {
        var vfs_mode = best_available_vfs_mode ();
        return ENFORCE_VIRTUAL_FILES_SYNC_FOLDER && vfs_mode != Occ.Vfs.Off;
    }


    /***********************************************************
    @return color for the Error_box text.
    ***********************************************************/
    public Gtk.Color error_box_text_color () {
        return new Gtk.Color ("white");
    }


    /***********************************************************
    @return color for the Error_box background.
    ***********************************************************/
    public Gtk.Color error_box_background_color ();
    Gtk.Color Theme.error_box_background_color () {
        return new Gtk.Color ("red");
    }


    /***********************************************************
    @return color for the Error_box border.
    ***********************************************************/
    public Gtk.Color error_box_border_color () {
        return new Gtk.Color ("black");
    }


    /***********************************************************
    ***********************************************************/
    public const string theme_prefix = ":/client/theme/";


    /***********************************************************
    helper to load a icon from either the icon theme the desktop
    provides or from the apps Qt resources.
    ***********************************************************/
//  #ifndef TOKEN_AUTH_ONLY
    protected QIcon theme_icon (string name, bool sys_tray = false) {
        string flavor;
        if (sys_tray) {
            flavor = systray_icon_flavor (this.mono);
        } else {
            flavor = "colored";
        }

        string key = name + "," + flavor;
        QIcon cached = this.icon_cache[key];
        if (cached.is_null ()) {
            if (QIcon.has_theme_icon (name)) {
                // use from theme
                return cached = QIcon.from_theme (name);
            }

            const string svg_name = string (Theme.theme_prefix) + string.from_latin1 ("%1/%2.svg").arg (flavor).arg (name);
            QSvgRenderer renderer (svg_name);
            var create_pixmap_from_svg = [&renderer] (int size) {
                Gtk.Image img (size, size, Gtk.Image.Format_ARGB32);
                img.fill (Qt.Global_color.transparent);
                QPainter img_painter (&img);
                renderer.render (&img_painter);
                return QPixmap.from_image (img);
            }

            var load_pixmap = [flavor, name] (int size) {
                const string pixmap_name = string (Theme.theme_prefix) + string.from_latin1 ("%1/%2-%3.png").arg (flavor).arg (name).arg (size);
                return QPixmap (pixmap_name);
            }

            var use_svg = should_prefer_svg ();
            var sizes = use_svg
                ? GLib.List<int> {
                    16, 32, 64, 128, 256 }
                : GLib.List<int> {
                    16, 22, 32, 48, 64, 128, 256, 512, 1024 };
            foreach (int size in sizes) {
                var px = use_svg ? create_pixmap_from_svg (size) : load_pixmap (size);
                if (px.is_null ()) {
                    continue;
                }
                // HACK, get rid of it by supporting FDO icon themes, this is really just emulating ubuntu-mono
                if (qgetenv ("DESKTOP_SESSION") == "ubuntu") {
                    QBitmap mask = px.create_mask_from_color (Qt.white, Qt.Mask_out_color);
                    QPainter p (&px);
                    p.pen (Gtk.Color ("#dfdbd2"));
                    p.draw_pixmap (px.rect (), mask, mask.rect ());
                }
                cached.add_pixmap (px);
            }
        }

        return cached;
    }
//  #endif
    /***********************************************************
    @brief Generates image path in the resources
    @param name Name of the image file
    @param size Size in the power of two (16, 32, 64, etc.)
    @param sys_tray Whether the image requested is for Systray
        or not
    @return string image path in the resources
    ***********************************************************/
    protected string theme_image_path (string name, int size = -1, bool sys_tray = false) {
        var flavor = (!is_branded () && sys_tray) ? systray_icon_flavor (this.mono) : "colored";
        var use_svg = should_prefer_svg ();

        // branded client may have several sizes of the same icon
        const string file_path = (use_svg || size <= 0)
                ? string (Theme.theme_prefix) + string.from_latin1 ("%1/%2").arg (flavor).arg (name)
                : string (Theme.theme_prefix) + string.from_latin1 ("%1/%2-%3").arg (flavor).arg (name).arg (size);

        const string svg_path = file_path + ".svg";
        if (use_svg) {
            return svg_path;
        }

        const string png_path = file_path + ".png";
        // Use the SVG as fallback if a PNG is missing so that we get a chance to display something
        if (GLib.File.exists (png_path)) {
            return png_path;
        } else {
            return svg_path;
        }
    }


    private static GLib.Uri image_path_to_url (string image_path) {
        if (image_path.starts_with (':')) {
            var url = GLib.Uri ();
            url.scheme ("qrc");
            url.path (image_path.mid (1));
            return url;
        } else {
            return GLib.Uri.from_local_file (image_path);
        }
    }

    private static bool should_prefer_svg () {
        return GLib.ByteArray (APPLICATION_ICON_SET).to_upper () == QByteArrayLiteral ("SVG");
    }
}

} // end namespace client
