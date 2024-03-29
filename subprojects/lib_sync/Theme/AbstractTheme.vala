namespace Occ {
namespace LibSync {

/***********************************************************
@class Theme

@brief The Theme class

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class Theme { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum CustomMediaType {
        /***********************************************************
        ownCloud connect page
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
    public static Theme instance {
        public get {
            if (Theme.instance == null) {
                Theme.instance = new Theme ();
                // some themes may not call the base ctor
                Theme.mono = false;
            }
            return Theme.instance;
        }
        private set {
            Theme.instance = value;
        }
    }


    private static Gtk.IconTheme icon_theme {
        private get {
            if (Theme.icon_theme == null) {
                Theme.icon_theme = Gtk.IconTheme.get_default ();
            }
            return Theme.icon_theme;
        }
        private set {
            Theme.icon_theme = value;
        }
    }

    private static bool mono = false;
    /***********************************************************
    Define if the systray icons should be using mono design
    Retrieve wether to use mono icons for systray
    ***********************************************************/
    public static bool systray_use_mono_icons {
        public get {
            return Theme.mono;
        }
        public set {
            Theme.mono = value;
            signal_systray_use_mono_icons_changed (mono);
        }
    }

//  #ifndef TOKEN_AUTH_ONLY
    // mutable
    private GLib.HashTable<string, Gtk.IconInfo> icon_cache;
//  #endif


    /***********************************************************
    ***********************************************************/
    internal signal void signal_systray_use_mono_icons_changed (bool value);


    /***********************************************************
    ***********************************************************/
    protected Theme () {
        //  base (null);
    }


    /***********************************************************
    @brief is_branded indicates if the current application is
    branded

    By default, it is considered
    different from "Nextcloud".

    @return true if branded, false otherwise
    ***********************************************************/
    public static bool is_branded {
        public get {
            return app_name_gui != "Nextcloud";
        }
    }


    /***********************************************************
    @brief app_name_gui - Human readable application name.

    Use and redefine this if
    special chars and such.

    By default, the name is derived from the APPLICATION_NAME
    cmake variable.

    @return string with human readable app name.
    ***********************************************************/
    public static string app_name_gui {
        public get {
            return Common.Config.APPLICATION_NAME;
        }
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
    \ref app_name_gui.

    @return string with app name.
    ***********************************************************/
    public static string app_name {
        public get {
            return Common.Config.APPLICATION_SHORTNAME;
        }
    }


    /***********************************************************
    @brief Returns full path to an online state icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public static GLib.Uri state_online_image_source {
        public get {
            return image_path_to_url (theme_image_path ("state-ok"));
        }
    }


    /***********************************************************
    @brief Returns full path to an offline state icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public static GLib.Uri state_offline_image_source {
        public get {
            return image_path_to_url (theme_image_path ("state-offline", 16));
        }
    }


    /***********************************************************
    @brief Returns full path to an online user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public static GLib.Uri status_online_image_source {
        public get {
            return image_path_to_url (theme_image_path ("user-status-online", 16));
        }
    }


    /***********************************************************
    @brief Returns full path to an do not disturb user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public static GLib.Uri status_do_not_disturb_image_source {
        public get {
            return image_path_to_url (theme_image_path ("user-status-dnd", 16));
        }
    }


    /***********************************************************
    @brief Returns full path to an away user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public static GLib.Uri status_away_image_source {
        public get {
            return image_path_to_url (theme_image_path ("user-status-away", 16));
        }
    }


    /***********************************************************
    @brief Returns full path to an invisible user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public static GLib.Uri status_invisible_image_source {
        public get {
            return image_path_to_url (theme_image_path ("user-status-invisible", 64));
        }
    }


    /***********************************************************
    ***********************************************************/
    public static GLib.Uri sync_status_ok {
        public get {
            return image_path_to_url (theme_image_path ("state-ok", 16));
        }
    }


    /***********************************************************
    ***********************************************************/
    public static GLib.Uri sync_status_error {
        public get {
            return image_path_to_url (theme_image_path ("state-error", 16));
        }
    }


    /***********************************************************
    ***********************************************************/
    public static GLib.Uri sync_status_running {
        public get {
            return image_path_to_url (theme_image_path ("state-sync", 16));
        }
    }


    /***********************************************************
    ***********************************************************/
    public static GLib.Uri sync_status_pause {
        public get {
            //  return image_path_to_url (theme_image_path ("state-pause", 16));
        }
    }


    /***********************************************************
    ***********************************************************/
    public static GLib.Uri sync_status_warning {
        public get {
            //  return image_path_to_url (theme_image_path ("state-warning", 16));
        }
    }


    /***********************************************************
    ***********************************************************/
    public static GLib.Uri folder_offline {
        public get {
            //  return image_path_to_url (theme_image_path ("state-offline"));
        }
    }


    /***********************************************************
    @brief config_filename
    @return the name of the config file.
    ***********************************************************/
    public static string config_filename {
        public get {
            return Common.Config.APPLICATION_EXECUTABLE + ".config";
        }
    }


    /***********************************************************
    ***********************************************************/
//  #ifndef TOKEN_AUTH_ONLY
    public static string hidpi_filename (
        string filename,
        Gdk.Monitor monitor
    ) {
        //  if (!Theme.is_hidpi (monitor)) {
        //      return filename;
        //  }
        //  // try to find a 2x version

        //  int dot_index = filename.last_index_of (".");
        //  if (dot_index != -1) {
        //      string at2xfilename = filename;
        //      at2xfilename.insert (dot_index, "@2x");
        //      if (GLib.File.exists (at2xfilename)) {
        //          return at2xfilename;
        //      }
        //  }
        //  return filename;
    }


    /***********************************************************
    ***********************************************************/
    public static string hidpi_filename_for_color (
        string icon_name,
        Gdk.RGBA background_color,
        Gdk.Monitor monitor
    ) {
        //  return Theme.hidpi_filename (Theme.THEME_PREFIX + (Theme.is_dark_color (background_color) ? "white/": "black/") + icon_name, monitor);
    }


    /***********************************************************
    ***********************************************************/
    public static bool is_hidpi (
        Gdk.Monitor monitor
    ) {
        //  var device_pixel_ratio = monitor != null ? monitor.scale_factor : Gdk.Display.get_default ().get_default_screen ().get_primary_monitor ().scale_factor;
        //  return device_pixel_ratio > 1;
    }


    /***********************************************************
    Get an sync state icon
    ***********************************************************/
    public static Gtk.IconInfo sync_state_icon (
        SyncResult.Status status,
        bool sys_tray = false
    ) {
        //  // FIXME: Mind the size!
        //  string status_icon;

        //  switch (status) {
        //  case SyncResult.Status.UNDEFINED:
        //      // this can happen if no sync connections are configured.
        //      status_icon = "state-warning";
        //      break;
        //  case SyncResult.Status.NOT_YET_STARTED:
        //  case SyncResult.Status.SYNC_RUNNING:
        //      status_icon = "state-sync";
        //      break;
        //  case SyncResult.Status.SYNC_ABORT_REQUESTED:
        //  case SyncResult.Status.PAUSED:
        //      status_icon = "state-pause";
        //      break;
        //  case SyncResult.Status.SYNC_PREPARE:
        //  case SyncResult.Status.SUCCESS:
        //      status_icon = "state-ok";
        //      break;
        //  case SyncResult.Status.PROBLEM:
        //      status_icon = "state-warning";
        //      break;
        //  case SyncResult.Status.ERROR:
        //  case SyncResult.Status.SETUP_ERROR:
        //  // FIXME: Use state-problem once we have an icon.
        //  default:
        //      status_icon = "state-error";
        //  }

        //  return theme_icon (status_icon, sys_tray);
    }


    /***********************************************************
    ***********************************************************/
    public static Gtk.IconInfo folder_disabled_icon {
        public get {
            return theme_icon ("state-pause");
        }
    }


    /***********************************************************
    ***********************************************************/
    public static Gtk.IconInfo folder_offline_icon {
        public get {
            return theme_icon ("state-offline", false);
        }
    }


    /***********************************************************
    ***********************************************************/
    public static Gtk.IconInfo folder_offline_icon_for_tray {
        public get {
            return theme_icon ("state-offline", true);
        }
    }


    /***********************************************************
    ***********************************************************/
    public static Gtk.IconInfo application_icon {
        public get {
            return theme_icon (APPLICATION_ICON_NAME + "-icon");
        }
    }


    /***********************************************************
    ***********************************************************/
    public static string status_header_text (SyncResult.Status status) {
        //  string result_str;

        //  switch (status) {
        //  case SyncResult.Status.UNDEFINED:
        //      return _("theme", "Status undefined");
        //  case SyncResult.Status.NOT_YET_STARTED:
        //      return _("theme", "Waiting to start sync");
        //  case SyncResult.Status.SYNC_RUNNING:
        //      return _("theme", "Sync is running");
        //  case SyncResult.Status.SUCCESS:
        //      return _("theme", "Sync Success");
        //  case SyncResult.Status.PROBLEM:
        //      return _("theme", "Sync Success, some files were ignored.");
        //  case SyncResult.Status.ERROR:
        //      return _("theme", "Sync Error");
        //  case SyncResult.Status.SETUP_ERROR:
        //      return _("theme", "Setup Error");
        //  case SyncResult.Status.SYNC_PREPARE:
        //      return _("theme", "Preparing to sync");
        //  case SyncResult.Status.SYNC_ABORT_REQUESTED:
        //      return _("theme", "Aborting …");
        //  case SyncResult.Status.PAUSED:
        //      return _("theme", "Sync is paused");
        //  }
        //  return "";
    }


    /***********************************************************
    ***********************************************************/
    public static string version;


    /***********************************************************
    Characteristics: bool if more than one sync folder is allowed

    If this option returns true, the client only supports one
    folder to sync.
    The Add-Button is removed accordingly.
    ***********************************************************/
    public static bool single_sync_folder {
        public get {
            return false;
        }
    }


    /***********************************************************
    When true, client works with multiple accounts.
    ***********************************************************/
    public static bool multi_account {
        public get {
            return true;
        }
    }


    /***********************************************************
    URL to documentation.

    This is opened in the browser when the "Help" action is
    selected from the tray menu.

    If the function is overridden to return an empty string the
    action is removed from the menu.

    Defaults to Nextclouds client documentation website.
    ***********************************************************/
    public static string help_url {
        public get {
            return Common.Config.APPLICATION_HELP_URL;
        }
    }


    /***********************************************************
    The url to use for showing help on conflicts.

    If the function is overridden to return an empty string no
    help link will be sh

    Defaults to help_url + "conflicts.html", which is a page
    in ownCloud's client documentation website. If help_url
    is empty, this function will also return the empty string.
    ***********************************************************/
    public static string conflict_help_url {
        public get {
            var base_url = help_url;
            if (base_url == "") {
                return "";
            }
            if (!base_url.has_suffix ("/")) {
                base_url += "/";
            }
            return base_url + "conflicts.html";
        }
    }


    /***********************************************************
    Setting a value here will pre-define the server url.

    The respective UI controls will be disabled only if
    force_override_server_url is true
    ***********************************************************/
    public static string override_server_url {
        public get {
            return Common.Config.APPLICATION_SERVER_URL;
        }
    }


    /***********************************************************
    Enforce a pre-defined server url.

    When true, the respective UI controls will be disabled
    ***********************************************************/
    public static bool force_override_server_url {
        public get {
            return Common.Config.APPLICATION_SERVER_URL_ENFORCE;
        }
    }


    /***********************************************************
    Enable OCSP stapling for SSL handshakes

    When true, peer will be requested for Online Certificate
    Status Protocol response
    ***********************************************************/
    public static bool enable_stapling_ocsp {
        public get {
            return Common.Config.APPLICATION_OCSP_STAPLING_ENABLED;
        }
    }


    /***********************************************************
    Enforce SSL validity

    When true, trusting the untrusted certificate is not allowed
    ***********************************************************/
    public static bool forbid_bad_ssl {
        public get {
            return Common.Config.APPLICATION_FORBID_BAD_SSL;
        }
    }


    /***********************************************************
    This is only usefull when previous version had a different
    override_server_url with a different auth type in that case
    you should then specify "http" or "shibboleth". Normally
    this should be left empty.
    ***********************************************************/
    public static string force_config_auth_type {
        public get {
            return "";
        }
    }


    /***********************************************************
    The default folder name without path on the server at setup
    time.
    ***********************************************************/
    public static string default_server_folder {
        public get {
            return "/";
        }
    }


    /***********************************************************
    The default folder name without path on the client side at
    setup time.
    ***********************************************************/
    public static string default_client_folder {
        public get {
            return app_name;
        }
    }


    /***********************************************************
    Override to encforce a particular locale, i.e. "de" or "pt_BR"
    ***********************************************************/
    public static string enforced_locale {
        public get {
            return "";
        }
    }


    /***********************************************************
    colored, white or black
    ***********************************************************/
    public static string systray_icon_flavor (bool mono) {
        //  string flavor;
        //  if (mono) {
        //      flavor = Utility.has_dark_systray () ? "white": "black";
        //  } else {
        //      flavor = "colored";
        //  }
        //  return flavor;
    }

//  #ifndef TOKEN_AUTH_ONLY
    /***********************************************************
    Override to use a string or a custom image name.
    The default implementation will try to look up
    :/client/theme/<type>.png
    ***********************************************************/
    public static GLib.Variant custom_media (CustomMediaType type) {
        //  GLib.Variant re;
        //  string key;

        //  switch (type) {
        //  case CustomMediaType.OC_SETUP_TOP:
        //      key = "CustomMediaType.OC_SETUP_TOP";
        //      break;
        //  case CustomMediaType.OC_SETUP_SIDE:
        //      key = "CustomMediaType.OC_SETUP_SIDE";
        //      break;
        //  case CustomMediaType.OC_SETUP_BOTTOM:
        //      key = "CustomMediaType.OC_SETUP_BOTTOM";
        //      break;
        //  case CustomMediaType.OC_SETUP_RESULT_BOTTOM:
        //      key = "CustomMediaType.OC_SETUP_RESULT_BOTTOM";
        //      break;
        //  }

        //  string img_path = Theme.THEME_PREFIX + "colored/%1.png".printf (key);
        //  if (GLib.File.exists (img_path)) {
        //      Gdk.Pixbuf pix = new Gdk.Pixbuf (img_path);
        //      if (pix == null) {
        //          // pixmap loading hasn't succeeded. We take the text instead.
        //          re.value (key);
        //      } else {
        //          re.value (pix);
        //      }
        //  }
        //  return re;
    }


    /***********************************************************
    @return color for the setup wizard
    ***********************************************************/
    public static Gdk.RGBA wizard_header_title_color {
        public get {
            return Gdk.RGBA (APPLICATION_WIZARD_HEADER_TITLE_COLOR);
        }
    }


    /***********************************************************
    @return color for the setup wizard.
    ***********************************************************/
    public static Gdk.RGBA wizard_header_background_color {
        public get {
            return Gdk.RGBA (APPLICATION_WIZARD_HEADER_BACKGROUND_COLOR);
        }
    }


    /***********************************************************
    ***********************************************************/
    public static Gdk.Pixbuf wizard_application_logo {
        public get {
            if (!Theme.is_branded) {
                return new Gdk.Pixbuf (Theme.hidpi_filename (Theme.THEME_PREFIX + "colored/wizard-nextcloud.png"));
            }
        // #ifdef APPLICATION_WIZARD_USE_CUSTOM_LOGO
            string logo_base_path = Theme.THEME_PREFIX + "colored/wizard_logo";
            if (should_prefer_svg) {
                var max_height = Theme.is_hidpi () ? 200 : 100;
                var max_width = 2 * max_height;
                var icon = new Gtk.IconInfo (logo_base_path + ".svg");
                var size = icon.actual_size (Gdk.Rectangle (max_width, max_height));
                return icon.pixmap (size);
            } else {
                return new Gdk.Pixbuf (hidpi_filename (logo_base_path + ".png"));
            }
        // #else
            var size = Theme.is_hidpi () ? 200 : 100;
            return application_icon.pixmap (size);
        // #endif
        }
    }


    /***********************************************************
    @return logo for the setup wizard.
    ***********************************************************/
    public static Gdk.Pixbuf wizard_header_logo {
        public get {
        // #ifdef APPLICATION_WIZARD_USE_CUSTOM_LOGO
            string logo_base_path = Theme.THEME_PREFIX + "colored/wizard_logo";
            if (should_prefer_svg) {
                var max_height = 64;
                var max_width = 2 * max_height;
                var icon = new Gtk.IconInfo (logo_base_path + ".svg");
                var size = icon.actual_size (Gdk.Rectangle (max_width, max_height));
                return icon.pixmap (size);
            } else {
                return new Gdk.Pixbuf (hidpi_filename (logo_base_path + ".png"));
            }
        // #else
            return application_icon.pixmap (64);
        // #endif
        }
    }


    /***********************************************************
    The default implementation creates a
    background based on
    \ref wizard_header_title_color.

    @return banner for the setup wizard.
    ***********************************************************/
    public static Gdk.Pixbuf wizard_header_banner {
        public get {
            Gdk.RGBA c = wizard_header_background_color;
            if (!c.is_valid) {
                return new Gdk.Pixbuf ();
            }

            Gdk.Rectangle size = Gdk.Rectangle (750, 78);
            var monitor = Gdk.Display.get_default ().get_default_screen ().get_primary_monitor ();
            if (monitor) {
                // Adjust the the size if there is a different DPI. (Issue #6156)
                // Indeed, this size need to be big enough to for the banner height, and the wizard's width
                var ratio = monitor.logical_dots_per_inch () / 96.0;
                if (ratio > 1.0) {
                    size *= ratio;
                }
            }
            Gdk.Pixbuf pix = new Gdk.Pixbuf (size);
            pix.fill (wizard_header_background_color);
            return pix;
        }
    }
//  #endif

    /***********************************************************
    The SHA sum of the released git commit
    ***********************************************************/
    public static string git_sha1 {
        public get {
            string dev_string;
        // #ifdef GIT_SHA1
            string github_prefix =
                "https://github.com/nextcloud/desktop/commit/";
            string git_sha1 = GIT_SHA1;
            dev_string = _("nextcloud_theme.about"
                         + "<p><small>Built from Git revision <a href=\"%1\">%2</a>"
                         + " on %3, %4 using Qt %5, %6</small></p>")
                            .printf (github_prefix + git_sha1)
                            .printf (git_sha1.left (6))
                            .printf (__DATE__)
                            .printf (__TIME__)
                            .printf (q_version ())
                            .printf (GLib.SslSocket.ssl_library_version_string ());
        // #endif
            return dev_string;
        }
    }


    /***********************************************************
    About dialog contents
    ***********************************************************/
    public static string about {
        public get {
            //  return MIRALL_VERSION_STRING;
            // Shorten Qt's OS name: "macOS Mojave (10.14)" . "macOS"
            GLib.List<string> os_string_list = Utility.platform_name ().split (' ');
            string os_name = os_string_list.at (0);

            string dev_string;
            // : Example text: "<p>Nextcloud Desktop Client</p>"   (%1 is the application name)
            dev_string = _("<p>%1 Desktop Client</p>")
                    .printf (Common.Config.APPLICATION_NAME);

            dev_string += _("<p>Version %1. For more information please click <a href='%2'>here</a>.</p>")
                    .printf (Common.NextcloudVersion.MIRALL_VERSION + " (%1)".printf (os_name))
                    .printf (help_url);

            dev_string += _("<p><small>Using files plugin : %1</small></p>")
                            .printf (Common.AbstractVfs.Mode.to_string (this.best_available_vfs_mode));
            dev_string += "<br>%1"
                    .printf (GLib.SysInfo.product_type () % '-' % GLib.SysInfo.kernel_version ());

            return dev_string;
        }
    }


    /***********************************************************
    Legal notice dialog version detail contents
    ***********************************************************/
    public static string about_details {
        public get {
            string dev_string;
            dev_string = _("<p>Version %1. For more information please click <a href='%2'>here</a>.</p>")
                    .printf (Common.NextcloudVersion.MIRALL_VERSION_STRING)
                    .printf (help_url);

            dev_string += _("<p>This release was supplied by %1</p>")
                    .printf (Common.Config.APPLICATION_VENDOR);

            dev_string += git_sha1;

            return dev_string;
        }
    }


    /***********************************************************
    Check if mono icons are available
    ***********************************************************/
    public static bool mono_icons_available {
        public get {
            string theme_dir = Theme.THEME_PREFIX + "%1/".printf (Theme.systray_icon_flavor (true));
            return new GLib.Dir (theme_dir).exists ();
        }
    }


    /***********************************************************
    @brief Where to check for new Updates.
    ***********************************************************/
    public static string update_check_url {
        public get {
            return Common.Config.APPLICATION_UPDATE_URL;
        }
    }


    /***********************************************************
    When true, the setup wizard will show the selective sync
    dialog by default and default to nothing selected
    ***********************************************************/
    public static bool wizard_selective_sync_default_nothing {
        public get {
            return false;
        }
    }


    /***********************************************************
    Default option for the new_big_folder_size_limit. Size in MB
    of the maximum size of folder before we ask the confirmation.
    Set -1 to never ask confirmation. 0 to ask confirmation for
    every folder.
    ***********************************************************/
    public static int64 new_big_folder_size_limit {
        public get {
            // Default to 500MB
            return 500;
        }
    }


    /***********************************************************
    Hide the checkbox that says "Ask for confirmation before
    synchronizing folders larger than X MB" in the account wizard
    ***********************************************************/
    public static bool wizard_hide_folder_size_limit_checkbox {
        public get {
            return false;
        }
    }


    /***********************************************************
    Hide the checkbox that says "Ask for confirmation before
    synchronizing external storages" in the account wizard
    ***********************************************************/
    public static bool wizard_hide_external_storage_confirmation_checkbox {
        public get {
            return false;
        }
    }


    /***********************************************************
    @brief Sharing options

    Allow link sharing and or user/group sharing
    ***********************************************************/
    public static bool link_sharing {
        public get {
            return true;
        }
    }


    /***********************************************************
    ***********************************************************/
    public static bool user_group_sharing {
        public get {
            return true;
        }
    }


    /***********************************************************
    If this returns true, the user cannot configure the proxy
    in the network settings. The proxy settings will be disabled
    in the configuration dialog.

    Default returns false.
    ***********************************************************/
    public static bool force_system_network_proxy {
        public get {
            return false;
        }
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
    public static UserIdentifierType user_identifier_type {
        public get {
            return UserIdentifierType.USER_NAME;
        }
    }


    /***********************************************************
    @brief Allows to customize the type of user ID (e.g. user
    name, email)

    @note This string cannot be translated, but is still
    useful for referencing brand name IDs (e.g. "ACME ID", when
    using ACME.)

    @return An empty string, unless reimplemented
    ***********************************************************/
    public static string custom_user_id {
        public get {
            return "";
        }
    }


    /***********************************************************
    @brief Demo string to be displayed when no text has been
    entered for the user identifier (e.g. mylogin@company.com)

    @return An empty string, unless reimplemented
    ***********************************************************/
    public static string user_id_hint {
        public get {
            return "";
        }
    }


    /***********************************************************
    @brief Postfix that will be enforced in a URL. e.g.
        //     ".myhosting.com".

    @return An empty string, unless reimplemented
    ***********************************************************/
    public static string wizard_url_postfix {
        public get {
            return "";
        }
    }


    /***********************************************************
    @brief String that will be shown as long as no text has
    been entered by the user.

    @return An empty string, unless reimplemented
    ***********************************************************/
    public static string wizard_url_hint {
        public get {
            return "";
        }
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
    public static string quota_base_folder {
        public get {
            return "/";
        }
    }


    /***********************************************************
    The OAuth client_id, secret pair.
    Note that client that change these value cannot connect to
    un-branded owncloud servers.
    ***********************************************************/
    public static string oauth_client_id {
        public get {
            return "xdXOt13JKxym1B1QcEncf2XDkLAexMBFwiT9j6EfhhHFJhs2KM9jbjTmf8JBXE69";
        }
    }


    /***********************************************************
    ***********************************************************/
    public static string oauth_client_secret {
        public get {
            return "UBntmLjC2yYCeHwsyj73Uwo9TAaecAetRwMw0xYcvNL9yRdLSUi0hUAHfvCHFeFh";
        }
    }


    /***********************************************************
    @brief What should be output for the --version command line
    switch.

    By default, it's a combination of app_name, version,
    the GIT SHA1 and some important dependency versions.
    ***********************************************************/
    public static string version_switch_output {
        public get {
            string help_text;
            help_text += app_name + " version " + version + "\n";
        // #ifdef GIT_SHA1
            help_text += "Git revision " + GIT_SHA1 + "\n";
        // #endif
            //  help_text += "Using Qt " + q_version () + ", built against Qt " + GLib.T_VERSION_STR + "\n";

            if (!GLib.Application.platform_name () == "") {
                help_text += "Using Qt platform plugin '" + GLib.Application.platform_name () + "'\n";
            }

            help_text += "Using '" + GLib.SslSocket.ssl_library_version_string () + "'\n";
            help_text += "Running on " + Utility.platform_name () + ", " + GLib.SysInfo.current_cpu_architecture () + "\n";
            return help_text;
        }
    }
	
	/***********************************************************
    @brief Request suitable Gtk.IconInfo resource depending on the
    background colour of the parent widget.

    This should be replaced (TODO) by a real theming
    implementation for the client UI
    (actually 2019/09/13 only systray theming).
    ***********************************************************/
    public static Gtk.IconInfo ui_theme_icon (
        string icon_name,
        bool ui_has_dark_background
    ) {
        //  string icon_path = Theme.THEME_PREFIX + (ui_has_dark_background ? "white/": "black/") + icon_name;
        //  string icn_path = icon_path.to_utf8 ().const_data ();
        //  return new Gtk.IconInfo (Gdk.Pixbuf (icon_path));
    }


    /***********************************************************
    @brief Perform a calculation to check if a colour is dark or
    light and accounts for different sensitivity of the human eye.

    @return True if the specified colour is dark.

    2019/12/08 : Moved here from SettingsDialog.
    ***********************************************************/
    public static bool is_dark_color (Gdk.RGBA color) {
        //  // account for different sensitivity of the human eye to certain colors
        //  double threshold = 1.0 - (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255.0;
        //  return threshold > 0.5;
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
    public static Gdk.RGBA get_background_aware_link_color (Gdk.RGBA background_color = GLib.Application.palette ().base ().color ()) {
        //  return is_dark_color (background_color) ? Gdk.RGBA ("#6193dc") { //: GLib.Application.palette ().color (Gtk.Palette.Link);
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
    public static void replace_link_color_string_background_aware (string link_string, Gdk.RGBA background_color = GLib.Application.palette ().color (Gtk.Palette.Base)) {
        //  replace_link_color_string (link_string, get_background_aware_link_color (background_color));
    }


    /***********************************************************
    @brief Appends a CSS-style colour value to all HTML link
    tags in a given string, as specified by new_color.

    2019/12/19: Implemented for the Dark Mode on macOS, because
    the app palette can not account for that (Qt 5.12.5).

    This way we also avoid having certain strings re-translated
    on Transifex.
    ***********************************************************/
    public static void replace_link_color_string (string link_string, Gdk.RGBA new_color) {
        //  link_string.replace (new GLib.Regex (" (<a href|<a style='color:# ([a-z_a-Z0-9]{6});' href)"), "<a style='color:%1;' href".printf (new_color.name ()));
    }


    /***********************************************************
    @brief Creates a colour-aware icon based on the specified
    palette's base colour (Dark-/Light-Mode switching).

    @return Gtk.IconInfo, colour-aware (inverted on dark backgrounds).

    2019/12/09: Moved here from SettingsDialog.
    ***********************************************************/
    public static Gtk.IconInfo create_color_aware_icon (string name, Gtk.Palette palette = GLib.Application.palette ()) {
        //  GLib.SvgRenderer renderer = new GLib.SvgRenderer (name);
        //  Gtk.Image img = new Gtk.Image (64, 64, Gtk.Image.FormatARGB32);
        //  img.fill (GLib.GlobalColor.transparent);
        //  GLib.Painter img_painter = new GLib.Painter  (img);
        //  Gtk.Image inverted = new Gtk.Image (64, 64, Gtk.Image.FormatARGB32);
        //  inverted.fill (GLib.GlobalColor.transparent);
        //  GLib.Painter inv_painter = new GLib.Painter (inverted);

        //  renderer.render (img_painter);
        //  renderer.render (inv_painter);

        //  inverted.invert_pixels (Gtk.Image.InvertRgb);

        //  Gtk.IconInfo icon;
        //  if (Theme.is_dark_color (palette.color (Gtk.Palette.Base))) {
        //      icon.add_pixmap (Gdk.Pixbuf.from_image (inverted));
        //  } else {
        //      icon.add_pixmap (Gdk.Pixbuf.from_image (img));
        //  }
        //  if (Theme.is_dark_color (palette.color (Gtk.Palette.HighlightedText))) {
        //      icon.add_pixmap (Gdk.Pixbuf.from_image (img), Gtk.IconInfo.Normal, Gtk.IconInfo.On);
        //  } else {
        //      icon.add_pixmap (Gdk.Pixbuf.from_image (inverted), Gtk.IconInfo.Normal, Gtk.IconInfo.On);
        //  }
        //  return icon;
    }


    /***********************************************************
    @brief Creates a colour-aware pixmap based on the specified
    palette's base colour (Dark-/Light-Mode switching).

    @return Gdk.Pixbuf, colour-aware (inverted on dark backgrounds).

    2019/12/09: Adapted from create_color_aware_icon.
    ***********************************************************/
    public static Gdk.Pixbuf create_color_aware_pixmap (string name, Gtk.Palette palette = GLib.Application.palette ()) {
        //  Gtk.Image img = new Gtk.Image (name);
        //  Gtk.Image inverted = new Gtk.Image (img);
        //  inverted.invert_pixels (Gtk.Image.InvertRgb);

        //  Gdk.Pixbuf pixmap;
        //  if (Theme.is_dark_color (palette.color (Gtk.Palette.Base))) {
        //      pixmap = Gdk.Pixbuf.from_image (inverted);
        //  } else {
        //      pixmap = Gdk.Pixbuf.from_image (img);
        //  }
        //  return pixmap;
    }


    /***********************************************************
    @brief Whether to show the option to create folders using
    "files".

    By default, the options are not shown unless experimental
    options are manually enabled in the configuration file.
    ***********************************************************/
    public static bool show_virtual_files_option {
        public get {
            return new ConfigFile ().show_experimental_options () || Theme.best_available_vfs_mode == Common.AbstractVfs.WindowsCfApi;
        }
    }


    /***********************************************************
    ***********************************************************/
    public static bool enforce_virtual_files_sync_folder {
        public get {
            return ENFORCE_VIRTUAL_FILES_SYNC_FOLDER && Theme.best_available_vfs_mode != Common.AbstractVfs.Off;
        }
    }


    /***********************************************************
    @return color for the ErrorBox text.
    ***********************************************************/
    public static Gdk.RGBA error_box_text_color {
        public get {
            return Gdk.RGBA ("white");
        }
    }


    /***********************************************************
    @return color for the ErrorBox background.
    ***********************************************************/
    public static Gdk.RGBA error_box_background_color {
        public get {
            return Gdk.RGBA ("red");
        }
    }


    /***********************************************************
    @return color for the ErrorBox border.
    ***********************************************************/
    public static Gdk.RGBA error_box_border_color {
        public get {
            return Gdk.RGBA ("black");
        }
    }


    /***********************************************************
    ***********************************************************/
    public const string THEME_PREFIX = ":/client/theme/";


    /***********************************************************
    helper to load a icon from either the icon theme the desktop
    provides or from the apps Qt resources.
    ***********************************************************/
//  #ifndef TOKEN_AUTH_ONLY
    protected Gtk.IconInfo theme_icon (string name, bool sys_tray = false) {
        //  string flavor;
        //  if (sys_tray) {
        //      flavor = systray_icon_flavor (this.mono);
        //  } else {
        //      flavor = "colored";
        //  }

        //  string key = name + "," + flavor;
        //  Gtk.IconInfo cached = this.icon_cache[key];
        //  if (cached == null) {
        //      if (Theme.icon_theme.has_icon (name)) {
        //          // use from theme
        //          return cached = Theme.icon_theme.choose_icon (name);
        //      }

        //      GLib.SvgRenderer renderer = new GLib.SvgRenderer (Theme.THEME_PREFIX + "%1/%2.svg".printf (flavor).printf (name));

        //      GLib.List<int> sizes = new GLib.List<int> ();
        //      sizes.append (16);
        //      if (!should_prefer_svg) {
        //          sizes.append (22);
        //      }
        //      sizes.append (32);
        //      if (!should_prefer_svg) {
        //          sizes.append (48);
        //      }
        //      sizes.append (64);
        //      sizes.append (128);
        //      sizes.append (256);
        //      if (!should_prefer_svg) {
        //          sizes.append (512);
        //          sizes.append (1024);
        //      }
        //      foreach (int size in sizes) {
        //          var px = should_prefer_svg ? create_pixmap_from_svg (size) : load_pixmap (size);
        //          if (px == null) {
        //              continue;
        //          }
        //          // HACK, get rid of it by supporting FDO icon themes, this is really just emulating ubuntu-mono
        //          if (GLib.Environment.get_variable ("DESKTOP_SESSION") == "ubuntu") {
        //              GLib.Bitmap mask = px.create_mask_from_color (GLib.white, GLib.MaskOutColor);
        //              GLib.Painter p = new GLib.Painter (px);
        //              p.pen (Gdk.RGBA ("#dfdbd2"));
        //              p.draw_pixmap (px.rect (), mask, mask.rect ());
        //          }
        //          cached.add_pixmap (px);
        //      }
        //  }

        //  return cached;
    }


    private static Gdk.Pixbuf create_pixmap_from_svg (GLib.SvgRenderer renderer, int size) {
        //  Gtk.Image img = new Gtk.Image (size, size, Gtk.Image.FormatARGB32);
        //  img.fill (GLib.GlobalColor.transparent);
        //  GLib.Painter img_painter = new GLib.Painter (img);
        //  renderer.render (img_painter);
        //  return Gdk.Pixbuf.from_image (img);
    }


    private static Gdk.Pixbuf load_pixmap (string flavor, string name, int size) {
        //  return new Gdk.Pixbuf (Theme.THEME_PREFIX + "%1/%2-%3.png".printf (flavor).printf (name).printf (size));
    }
//  #endif


    /***********************************************************
    @brief Generates image path in the resources
    @param name Name of the image file
    @param size Size in the power of two (16, 32, 64, etc.)
    @param sys_tray Whether the image requested is for Systray
        //  or not
    @return string image path in the resources
    ***********************************************************/
    protected static string theme_image_path (
        //  string name,
        //  int size = -1,
        //  bool sys_tray = false
    ) {
        //  var flavor = (!is_branded && sys_tray) ? systray_icon_flavor (Theme.mono): "colored";

        //  // branded client may have several sizes of the same icon
        //  string file_path = (should_prefer_svg || size <= 0)
        //          ? Theme.THEME_PREFIX + "%1/%2".printf (flavor).printf (name)
        //          : Theme.THEME_PREFIX + "%1/%2-%3".printf (flavor).printf (name).printf (size);

        //  // Use the SVG as fallback if a PNG is missing so that we get a chance to display something
        //  if (should_prefer_svg) {
        //      return file_path + ".svg";
        //  } else if (GLib.File.exists (png_path)) {
        //      return file_path + ".png";
        //  } else {
        //      return file_path + ".svg";
        //  }
    }


    private static unowned GLib.Uri image_path_to_url (string image_path) {
        //  if (image_path.has_prefix (":")) {
        //      var url = new GLib.Uri ();
        //      url.scheme ("qrc");
        //      url.path (image_path.mid (1));
        //      return url;
        //  } else {
        //      return GLib.Uri.from_local_file (image_path);
        //  }
    }


    private static bool should_prefer_svg {
        public get {
            return Common.Config.APPLICATION_ICON_SET.to_upper () == "SVG";
        }
    }

} // class Theme

} // namespace LibSync
} // namespace Occ
