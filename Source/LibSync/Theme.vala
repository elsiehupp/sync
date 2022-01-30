/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QtCore>
#ifndef TOKEN_AUTH_ONLY
// #include <QtGui>
// #include <QStyle>
// #include <QApplication>
#endif
// #include <QSslSocket>
// #include <QSvgRenderer>

#ifdef THEME_INCLUDE
const int Mirall Occ // namespace hack to make old themes work
const int QUOTEME (M) #M
const int INCLUDE_FILE (M) QUOTEME (M)
#include INCLUDE_FILE (THEME_INCLUDE)
#undef Mirall
#endif

// #include <QIcon>

class GLib.Object;
class QPalette;

namespace Occ {


/***********************************************************
@brief The Theme class
@ingroup libsync
***********************************************************/
class Theme : GLib.Object {
    Q_PROPERTY (bool branded READ is_branded CONSTANT)
    Q_PROPERTY (string app_name_gui READ app_name_gui CONSTANT)
    Q_PROPERTY (string app_name READ app_name CONSTANT)
    Q_PROPERTY (GLib.Uri state_online_image_source READ state_online_image_source CONSTANT)
    Q_PROPERTY (GLib.Uri state_offline_image_source READ state_offline_image_source CONSTANT)
    Q_PROPERTY (GLib.Uri status_online_image_source READ status_online_image_source CONSTANT)
    Q_PROPERTY (GLib.Uri status_do_not_disturb_image_source READ status_do_not_disturb_image_source CONSTANT)
    Q_PROPERTY (GLib.Uri status_away_image_source READ status_away_image_source CONSTANT)
    Q_PROPERTY (GLib.Uri status_invisible_image_source READ status_invisible_image_source CONSTANT)
#ifndef TOKEN_AUTH_ONLY
    Q_PROPERTY (QIcon folder_disabled_icon READ folder_disabled_icon CONSTANT)
    Q_PROPERTY (QIcon folder_offline_icon READ folder_offline_icon CONSTANT)
    Q_PROPERTY (QIcon application_icon READ application_icon CONSTANT)
#endif
    Q_PROPERTY (string version READ version CONSTANT)
    Q_PROPERTY (string help_url READ help_url CONSTANT)
    Q_PROPERTY (string conflict_help_url READ conflict_help_url CONSTANT)
    Q_PROPERTY (string override_server_url READ override_server_url)
    Q_PROPERTY (bool force_override_server_url READ force_override_server_url)
#ifndef TOKEN_AUTH_ONLY
    Q_PROPERTY (QColor wizard_header_title_color READ wizard_header_title_color CONSTANT)
    Q_PROPERTY (QColor wizard_header_background_color READ wizard_header_background_color CONSTANT)
#endif
    Q_PROPERTY (string update_check_url READ update_check_url CONSTANT)

    Q_PROPERTY (QColor error_box_text_color READ error_box_text_color CONSTANT)
    Q_PROPERTY (QColor error_box_background_color READ error_box_background_color CONSTANT)
    Q_PROPERTY (QColor error_box_border_color READ error_box_border_color CONSTANT)

    /***********************************************************
    ***********************************************************/
    public enum Custom_media_type {
        o_c_setup_top, // own_cloud connect page
        o_c_setup_side,
        o_c_setup_bottom,
        o_c_setup_result_top // own_cloud connect result page
    };


    /***********************************************************
    returns a singleton instance.
    ***********************************************************/
    public static Theme instance ();

    ~Theme () override;


    /***********************************************************
    @brief is_branded indicates if the current application is
    branded

    By default, it is considered
    different from "Nextcloud".

    @return true if branded, false otherwise
    ***********************************************************/
    public virtual bool is_branded ();


    /***********************************************************
    @brief app_name_gui - Human readable application name.

    Use and redefine this if
    special chars and such.

    By default, the name is derived from the APPLICATION_NAME
    cmake variable.

    @return string with human readable app name.
    ***********************************************************/
    public virtual string app_name_gui ();


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
    public virtual string app_name ();


    /***********************************************************
    @brief Returns full path to an online state icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri state_online_image_source ();


    /***********************************************************
    @brief Returns full path to an offline state icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri state_offline_image_source ();


    /***********************************************************
    @brief Returns full path to an online user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri status_online_image_source ();


    /***********************************************************
    @brief Returns full path to an do not disturb user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri status_do_not_disturb_image_source ();


    /***********************************************************
    @brief Returns full path to an away user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri status_away_image_source ();


    /***********************************************************
    @brief Returns full path to an invisible user status icon
    @return GLib.Uri full path to an icon
    ***********************************************************/
    public GLib.Uri status_invisible_image_source ();

    /***********************************************************
    ***********************************************************/
    public GLib.Uri sync_status_ok ();

    /***********************************************************
    ***********************************************************/
    public GLib.Uri sync_status_error ();

    /***********************************************************
    ***********************************************************/
    public GLib.Uri sync_status_running ();

    /***********************************************************
    ***********************************************************/
    public GLib.Uri sync_status_pause ();

    /***********************************************************
    ***********************************************************/
    public GLib.Uri sync_status_warning ();

    /***********************************************************
    ***********************************************************/
    public GLib.Uri folder_offline ();


    /***********************************************************
    @brief config_file_name
    @return the name of the config file.
    ***********************************************************/
    public virtual string config_file_name ();

#ifndef TOKEN_AUTH_ONLY
    public static string hidpi_file_name (string file_name, QPaint_device dev = nullptr);

    /***********************************************************
    ***********************************************************/
    public static string hidpi_file_name (string icon_name, QColor &background_color, QPaint_device dev = nullptr);

    /***********************************************************
    ***********************************************************/
    public static bool is_hidpi (QPaint_device dev = nullptr);


    /***********************************************************
    Get an sync state icon
    ***********************************************************/
    public virtual QIcon sync_state_icon (SyncResult.Status, bool sys_tray = false);

    /***********************************************************
    ***********************************************************/
    public virtual QIcon folder_disabled_icon ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public virtual QIcon application_icon ();

    /***********************************************************
    ***********************************************************/
    public 
    public virtual string status_header_text (SyncResult.Status);


    public virtual string version ();


    /***********************************************************
    Characteristics: bool if more than one sync folder is allowed
    ***********************************************************/
    public virtual bool single_sync_folder ();


    /***********************************************************
    When true, client works with multiple accounts.
    ***********************************************************/
    public public virtual bool multi_account ();


    /***********************************************************
    URL to documentation.

    This is opened in the browser when the "Help" action is
    selected from the tray menu.

    If the function is overridden to return an empty string the
    action is removed from the menu.

    Defaults to Nextclouds client documentation website.
    ***********************************************************/
    public virtual string help_url ();


    /***********************************************************
    The url to use for showing help on conflicts.

    If the function is overridden to return an empty string no
    help link will be sh

    Defaults to help_url () + "conflicts.html", which is a page
    in ownCloud's client documentation website. If help_url ()
    is empty, this function will also return the empty string.
    ***********************************************************/
    public virtual string conflict_help_url ();


    /***********************************************************
    Setting a value here will pre-define the server url.

    The respective UI controls will be disabled only if
    force_override_server_url () is true
    ***********************************************************/
    public virtual string override_server_url ();


    /***********************************************************
    Enforce a pre-defined server url.

    When true, the respective UI controls will be disabled
    ***********************************************************/
    public virtual bool force_override_server_url ();


    /***********************************************************
    Enable OCSP stapling for SSL handshakes

    When true, peer will be requested for Online Certificate
    Status Protocol response
    ***********************************************************/
    public virtual bool enable_stapling_oCSP ();


    /***********************************************************
    Enforce SSL validity

    When true, trusting the untrusted certificate is not allowed
    ***********************************************************/
    public virtual bool forbid_bad_s_sL ();


    /***********************************************************
    This is only usefull when previous version had a different
    override_server_url with a different auth type in that case
    you should then specify "http" or "shibboleth". Normally
    this should be left empty.
    ***********************************************************/
    public virtual string force_config_auth_type ();


    /***********************************************************
    The default folder name without path on the server at setup
    time.
    ***********************************************************/
    public virtual string default_server_folder ();


    /***********************************************************
    The default folder name without path on the client side at
    setup time.
    ***********************************************************/
    public virtual string default_client_folder ();


    /***********************************************************
    Override to encforce a particular locale, i.e. "de" or "pt_BR"
    ***********************************************************/
    public virtual string enforced_locale () {
        return "";
    }


    /***********************************************************
    colored, white or black
    ***********************************************************/
    public string systray_icon_flavor (bool mono);

#ifndef TOKEN_AUTH_ONLY
    /***********************************************************
    Override to use a string or a custom image name.
    The default implementation will try to look up
    :/client/theme/<type>.png
    ***********************************************************/
    public virtual QVariant custom_media (Custom_media_type type);


    /***********************************************************
    @return color for the setup wizard
    ***********************************************************/
    public virtual QColor wizard_header_title_color ();


    /***********************************************************
    @return color for the setup wizard.
    ***********************************************************/
    public virtual QColor wizard_header_background_color ();

    /***********************************************************
    ***********************************************************/
    public virtual QPixmap wizard_application_logo ();


    /***********************************************************
    @return logo for the setup wizard.
    ***********************************************************/
    public virtual QPixmap wizard_header_logo ();


    /***********************************************************
    The default implementation creates a
    background based on
    \ref wizard_header_title_color ().

    @return banner for the setup wizard.
    ***********************************************************/
    public virtual QPixmap wizard_header_banner ();
#endif

    /***********************************************************
    The SHA sum of the released git commit
    ***********************************************************/
    public string git_sHA1 ();


    /***********************************************************
    About dialog contents
    ***********************************************************/
    public virtual string about ();


    /***********************************************************
    Legal notice dialog version detail contents
    ***********************************************************/
    virtual string about_details ();


    /***********************************************************
    Define if the systray icons should be using mono design
    ***********************************************************/
    public void set_systray_use_mono_icons (bool mono);


    /***********************************************************
    Retrieve wether to use mono icons for systray
    ***********************************************************/
    public bool systray_use_mono_icons ();


    /***********************************************************
    Check if mono icons are available
    ***********************************************************/
    public bool mono_icons_available ();


    /***********************************************************
    @brief Where to check for new Updates.
    ***********************************************************/
    public virtual string update_check_url ();


    /***********************************************************
    When true, the setup wizard will show the selective sync
    dialog by default and default to nothing selected
    ***********************************************************/
    public virtual bool wizard_selective_sync_default_nothing ();


    /***********************************************************
    Default option for the new_big_folder_size_limit. Size in MB
    of the maximum size of folder before we ask the confirmation.
    Set -1 to never ask confirmation. 0 to ask confirmation for
    every folder.
    ***********************************************************/
    public virtual int64 new_big_folder_size_limit ();


    /***********************************************************
    Hide the checkbox that says "Ask for confirmation before
    synchronizing folders larger than X MB" in the account wizard
    ***********************************************************/
    public virtual bool wizard_hide_folder_size_limit_checkbox ();


    /***********************************************************
    Hide the checkbox that says "Ask for confirmation before
    synchronizing external storages" in the account wizard
    ***********************************************************/
    public virtual bool wizard_hide_external_storage_confirmation_checkbox ();


    /***********************************************************
    @brief Sharing options

    Allow link sharing and or user/group sharing
    ***********************************************************/
    public virtual bool link_sharing ();


    /***********************************************************
    ***********************************************************/
    public virtual bool user_group_sharing ();


    /***********************************************************
    If this returns true, the user cannot configure the proxy
    in the network settings. The proxy settings will be disabled
    in the configuration dialog.

    Default returns false.
    ***********************************************************/
    public virtual bool force_system_network_proxy ();


    /***********************************************************
    @brief How to handle the user_iD

    @value User_iDUser_name Wizard asks for user name a
    @value User_iDEmail Wizard asks for an email as ID
    @value User_iDCustom Specify string in \ref custom_user_iD
    ***********************************************************/
    public enum User_iDType {
        User_iDUser_name = 0,
        User_iDEmail,
        User_iDCustom
    };


    /***********************************************************
    @brief What to display as the user_iD (e.g. in the wizards)

    @return User_iDType.User_iDUser_name, unless reimplemented
    ***********************************************************/
    public virtual User_iDType user_iDType ();


    /***********************************************************
    @brief Allows to customize the type of user ID (e.g. user
    name, email)

    @note This string cannot be translated, but is still
    useful for referencing brand name IDs (e.g. "ACME ID", when
    using ACME.)

    @return An empty string, unless reimplemented
    ***********************************************************/
    public virtual string custom_user_iD ();


    /***********************************************************
    @brief Demo string to be displayed when no text has been
    entered for the user id (e.g. mylogin@company.com)

    @return An empty string, unless reimplemented
    ***********************************************************/
    public virtual string user_iDHint ();


    /***********************************************************
    @brief Postfix that will be enforced in a URL. e.g.
           ".myhosting.com".

    @return An empty string, unless reimplemented
    ***********************************************************/
    public virtual string wizard_url_postfix ();


    /***********************************************************
    @brief String that will be shown as long as no text has
    been entered by the user.

    @return An empty string, unless reimplemented
    ***********************************************************/
    public virtual string wizard_url_hint ();


    /***********************************************************
    @brief the server folder that should be queried for the
    quota information

    This can be configured to show the quota infromation for a
    different folder than the root. This is the folder on which
    the client will do PROPFIND calls to get
    "quota-available-bytes" and "quota-used-bytes"

    Default: "/"
    ***********************************************************/
    public virtual string quota_base_folder ();


    /***********************************************************
    The OAuth client_id, secret pair.
    Note that client that change these value cannot connect to
    un-branded owncloud servers.
    ***********************************************************/
    public virtual string oauth_client_id ();


    /***********************************************************
    ***********************************************************/
    public virtual string oauth_client_secret ();


    /***********************************************************
    @brief What should be output for the --version command line
    switch.

    By default, it's a combination of app_name (), version (),
    the GIT SHA1 and some important dependency versions.
    ***********************************************************/
    public virtual string version_switch_output ();
	
	/***********************************************************
    @brief Request suitable QIcon resource depending on the
    background colour of the parent widget.

    This should be replaced (TODO) by a real theming
    implementation for the client UI
    (actually 2019/09/13 only systray theming).
    ***********************************************************/
	public virtual QIcon ui_theme_icon (string icon_name, bool ui_has_dark_bg);


    /***********************************************************
    @brief Perform a calculation to check if a colour is dark or
    light and accounts for different sensitivity of the human eye.

    @return True if the specified colour is dark.

    2019/12/08 : Moved here from SettingsDialog.
    ***********************************************************/
    public static bool is_dark_color (QColor &color);


    /***********************************************************
    @brief Return the colour to be used for HTML links (e.g.
    used in QLabel), based on the current app palette or given
    colour (Dark-/Light-Mode switching).

    @return Background-aware colour for HTML links, based on
    the current app palette or given colour.

    2019/12/08 : Implemented for the Dark Mode on macOS,
    because the app palette can not account for that (Qt 5.12.5).
    ***********************************************************/
    public static QColor get_background_aware_link_color (QColor &background_color);


    /***********************************************************
    @brief Return the colour to be used for HTML links (e.g.
    used in QLabel), based on the current app palette
    (Dark-/Light-Mode switching).

    @return Background-aware colour for HTML links, based on
    the current app palette.

    2019/12/08: Implemented for the Dark Mode on macOS, because
    the app palette can not account for that (Qt 5.12.5).
    ***********************************************************/
    public static QColor get_background_aware_link_color ();


    /***********************************************************
    @brief Appends a CSS-style colour value to all HTML link
    tags in a given string, based on the current app palette or
    given colour (Dark-/Light-Mode switching).

    2019/12/08: Implemented for the Dark Mode on macOS, because
    the app palette can not account for that (Qt 5.12.5).

    This way we also avoid having certain strings re-translated
    on Transifex.
    ***********************************************************/
    public static void replace_link_color_string_background_aware (string link_string, QColor &background_color);


    /***********************************************************
    @brief Appends a CSS-style colour value to all HTML link
    tags in a given string, based on the current app palette
    (Dark-/Light-Mode switching).

    2019/12/08 : Implemented for the Dark Mode on macOS,
    because the app palette can not account for that (Qt 5.12.5).

    This way we also avoid having certain strings re-translated
    on Transifex.
    ***********************************************************/
    public static void replace_link_color_string_background_aware (string link_string);


    /***********************************************************
    @brief Appends a CSS-style colour value to all HTML link
    tags in a given string, as specified by new_color.

    2019/12/19: Implemented for the Dark Mode on macOS, because
    the app palette can not account for that (Qt 5.12.5).

    This way we also avoid having certain strings re-translated
    on Transifex.
    ***********************************************************/
    public static void replace_link_color_string (string link_string, QColor &new_color);


    /***********************************************************
    @brief Creates a colour-aware icon based on the specified
    palette's base colour.

    @return QIcon, colour-aware (inverted on dark backgrounds).

    2019/12/09 : Moved here from SettingsDialog.
    ***********************************************************/
    public static QIcon create_color_aware_icon (string name, QPalette &palette);


    /***********************************************************
    @brief Creates a colour-aware icon based on the app
    palette's base colour (Dark-/Light-Mode switching).

    @return QIcon, colour-aware (inverted on dark backgrounds).

    2019/12/09 : Moved here from SettingsDialog.
    ***********************************************************/
    public static QIcon create_color_aware_icon (string name);


    /***********************************************************
    @brief Creates a colour-aware pixmap based on the specified
    palette's base colour.

    @return QPixmap, colour-aware (inverted on dark backgrounds).

    2019/12/09 : Adapted from create_color_aware_icon.
    ***********************************************************/
    public static QPixmap create_color_aware_pixmap (string name, QPalette &palette);


    /***********************************************************
    @brief Creates a colour-aware pixmap based on the app
    palette's base colour (Dark-/Light-Mode switching).

    @return QPixmap, colour-aware (inverted on dark backgrounds).

    2019/12/09: Adapted from create_color_aware_icon.
    ***********************************************************/
    public static QPixmap create_color_aware_pixmap (string name);


    /***********************************************************
    @brief Whether to show the option to create folders using
    "virtual files".

    By default, the options are not shown unless experimental
    options are manually enabled in the configuration file.
    ***********************************************************/
    public virtual bool show_virtual_files_option ();

    /***********************************************************
    ***********************************************************/
    public virtual bool enforce_virtual_files_sync_folder ();


    /***********************************************************
    @return color for the Error_box text.
    ***********************************************************/
    public virtual QColor error_box_text_color ();


    /***********************************************************
    @return color for the Error_box background.
    ***********************************************************/
    public virtual QColor error_box_background_color ();


    /***********************************************************
    @return color for the Error_box border.
    ***********************************************************/
    public virtual QColor error_box_border_color ();

    /***********************************************************
    ***********************************************************/
    public static constexpr const char theme_prefix = ":/client/theme/";


#ifndef TOKEN_AUTH_ONLY
    protected QIcon theme_icon (string name, bool sys_tray = false);
#endif
    /***********************************************************
    @brief Generates image path in the resources
    @param name Name of the image file
    @param size Size in the power of two (16, 32, 64, etc.)
    @param sys_tray Whether the image requested is for Systray
        or not
    @return string image path in the resources
    ***********************************************************/
    protected string theme_image_path (string name, int size = -1, bool sys_tray = false);
    protected Theme ();

signals:
    void systray_use_mono_icons_changed (bool);


    /***********************************************************
    ***********************************************************/
    private Theme (Theme const &);

    /***********************************************************
    ***********************************************************/
    private 
    private static Theme _instance;
    private bool _mono = false;
#ifndef TOKEN_AUTH_ONLY
    private mutable QHash<string, QIcon> _icon_cache;
#endif
};
}









namespace {

GLib.Uri image_path_to_url (string image_path) {
    if (image_path.starts_with (':')) {
        var url = GLib.Uri ();
        url.set_scheme (QStringLiteral ("qrc"));
        url.set_path (image_path.mid (1));
        return url;
    } else {
        return GLib.Uri.from_local_file (image_path);
    }
}

bool should_prefer_svg () {
    return GLib.ByteArray (APPLICATION_ICON_SET).to_upper () == QByteArrayLiteral ("SVG");
}

Theme *Theme._instance = nullptr;

Theme *Theme.instance () {
    if (!_instance) {
        _instance = new THEME_CLASS;
        // some themes may not call the base ctor
        _instance._mono = false;
    }
    return _instance;
}

Theme.~Theme () = default;

string Theme.status_header_text (SyncResult.Status status) {
    string result_str;

    switch (status) {
    case SyncResult.Undefined:
        result_str = QCoreApplication.translate ("theme", "Status undefined");
        break;
    case SyncResult.NotYetStarted:
        result_str = QCoreApplication.translate ("theme", "Waiting to on_start sync");
        break;
    case SyncResult.Sync_running:
        result_str = QCoreApplication.translate ("theme", "Sync is running");
        break;
    case SyncResult.Success:
        result_str = QCoreApplication.translate ("theme", "Sync Success");
        break;
    case SyncResult.Problem:
        result_str = QCoreApplication.translate ("theme", "Sync Success, some files were ignored.");
        break;
    case SyncResult.Error:
        result_str = QCoreApplication.translate ("theme", "Sync Error");
        break;
    case SyncResult.Setup_error:
        result_str = QCoreApplication.translate ("theme", "Setup Error");
        break;
    case SyncResult.Sync_prepare:
        result_str = QCoreApplication.translate ("theme", "Preparing to sync");
        break;
    case SyncResult.Sync_abort_requested:
        result_str = QCoreApplication.translate ("theme", "Aborting …");
        break;
    case SyncResult.Paused:
        result_str = QCoreApplication.translate ("theme", "Sync is paused");
        break;
    }
    return result_str;
}

bool Theme.is_branded () {
    return app_name_gui () != QStringLiteral ("Nextcloud");
}

string Theme.app_name_gui () {
    return APPLICATION_NAME;
}

string Theme.app_name () {
    return APPLICATION_SHORTNAME;
}

GLib.Uri Theme.state_online_image_source () {
    return image_path_to_url (theme_image_path ("state-ok"));
}

GLib.Uri Theme.state_offline_image_source () {
    return image_path_to_url (theme_image_path ("state-offline", 16));
}

GLib.Uri Theme.status_online_image_source () {
    return image_path_to_url (theme_image_path ("user-status-online", 16));
}

GLib.Uri Theme.status_do_not_disturb_image_source () {
    return image_path_to_url (theme_image_path ("user-status-dnd", 16));
}

GLib.Uri Theme.status_away_image_source () {
    return image_path_to_url (theme_image_path ("user-status-away", 16));
}

GLib.Uri Theme.status_invisible_image_source () {
    return image_path_to_url (theme_image_path ("user-status-invisible", 64));
}

GLib.Uri Theme.sync_status_ok () {
    return image_path_to_url (theme_image_path ("state-ok", 16));
}

GLib.Uri Theme.sync_status_error () {
    return image_path_to_url (theme_image_path ("state-error", 16));
}

GLib.Uri Theme.sync_status_running () {
    return image_path_to_url (theme_image_path ("state-sync", 16));
}

GLib.Uri Theme.sync_status_pause () {
    return image_path_to_url (theme_image_path ("state-pause", 16));
}

GLib.Uri Theme.sync_status_warning () {
    return image_path_to_url (theme_image_path ("state-warning", 16));
}

GLib.Uri Theme.folder_offline () {
    return image_path_to_url (theme_image_path ("state-offline"));
}

string Theme.version () {
    return MIRALL_VERSION_STRING;
}

string Theme.config_file_name () {
    return QStringLiteral (APPLICATION_EXECUTABLE ".cfg");
}

#ifndef TOKEN_AUTH_ONLY

QIcon Theme.application_icon () {
    return theme_icon (QStringLiteral (APPLICATION_ICON_NAME "-icon"));
}

/***********************************************************
helper to load a icon from either the icon theme the desktop provides or from
the apps Qt resources.
***********************************************************/
QIcon Theme.theme_icon (string name, bool sys_tray) {
    string flavor;
    if (sys_tray) {
        flavor = systray_icon_flavor (_mono);
    } else {
        flavor = QLatin1String ("colored");
    }

    string key = name + "," + flavor;
    QIcon &cached = _icon_cache[key];
    if (cached.is_null ()) {
        if (QIcon.has_theme_icon (name)) {
            // use from theme
            return cached = QIcon.from_theme (name);
        }

        const string svg_name = string (Theme.theme_prefix) + string.from_latin1 ("%1/%2.svg").arg (flavor).arg (name);
        QSvgRenderer renderer (svg_name);
        const var create_pixmap_from_svg = [&renderer] (int size) {
            QImage img (size, size, QImage.Format_ARGB32);
            img.fill (Qt.Global_color.transparent);
            QPainter img_painter (&img);
            renderer.render (&img_painter);
            return QPixmap.from_image (img);
        };

        const var load_pixmap = [flavor, name] (int size) {
            const string pixmap_name = string (Theme.theme_prefix) + string.from_latin1 ("%1/%2-%3.png").arg (flavor).arg (name).arg (size);
            return QPixmap (pixmap_name);
        };

        const var use_svg = should_prefer_svg ();
        const var sizes = use_svg
            ? QVector<int> {
                16, 32, 64, 128, 256 }
            : QVector<int> {
                16, 22, 32, 48, 64, 128, 256, 512, 1024 };
        for (int size : sizes) {
            var px = use_svg ? create_pixmap_from_svg (size) : load_pixmap (size);
            if (px.is_null ()) {
                continue;
            }
            // HACK, get rid of it by supporting FDO icon themes, this is really just emulating ubuntu-mono
            if (qgetenv ("DESKTOP_SESSION") == "ubuntu") {
                QBitmap mask = px.create_mask_from_color (Qt.white, Qt.Mask_out_color);
                QPainter p (&px);
                p.set_pen (QColor ("#dfdbd2"));
                p.draw_pixmap (px.rect (), mask, mask.rect ());
            }
            cached.add_pixmap (px);
        }
    }

    return cached;
}

string Theme.theme_image_path (string name, int size, bool sys_tray) {
    const var flavor = (!is_branded () && sys_tray) ? systray_icon_flavor (_mono) : QLatin1String ("colored");
    const var use_svg = should_prefer_svg ();

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

bool Theme.is_hidpi (QPaint_device dev) {
    const var device_pixel_ratio = dev ? dev.device_pixel_ratio () : q_app.primary_screen ().device_pixel_ratio ();
    return device_pixel_ratio > 1;
}

QIcon Theme.ui_theme_icon (string icon_name, bool ui_has_dark_bg) {
    string icon_path = string (Theme.theme_prefix) + (ui_has_dark_bg ? "white/" : "black/") + icon_name;
    std.string icn_path = icon_path.to_utf8 ().const_data ();
    return QIcon (QPixmap (icon_path));
}

string Theme.hidpi_file_name (string file_name, QPaint_device dev) {
    if (!Theme.is_hidpi (dev)) {
        return file_name;
    }
    // try to find a 2x version

    const int dot_index = file_name.last_index_of ('.');
    if (dot_index != -1) {
        string at2xfile_name = file_name;
        at2xfile_name.insert (dot_index, QStringLiteral ("@2x"));
        if (GLib.File.exists (at2xfile_name)) {
            return at2xfile_name;
        }
    }
    return file_name;
}

string Theme.hidpi_file_name (string icon_name, QColor &background_color, QPaint_device dev) {
    const var is_dark_background = Theme.is_dark_color (background_color);

    const string icon_path = string (Theme.theme_prefix) + (is_dark_background ? "white/" : "black/") + icon_name;

    return Theme.hidpi_file_name (icon_path, dev);
}

#endif

Theme.Theme ()
    : GLib.Object (nullptr) {
}

// If this option returns true, the client only supports one folder to sync.
// The Add-Button is removed accordingly.
bool Theme.single_sync_folder () {
    return false;
}

bool Theme.multi_account () {
    return true;
}

string Theme.default_server_folder () {
    return QLatin1String ("/");
}

string Theme.help_url () {
#ifdef APPLICATION_HELP_URL
    return string.from_latin1 (APPLICATION_HELP_URL);
#else
    return string.from_latin1 ("https://docs.nextcloud.com/desktop/%1.%2/").arg (MIRALL_VERSION_MAJOR).arg (MIRALL_VERSION_MINOR);
#endif
}

string Theme.conflict_help_url () {
    var base_url = help_url ();
    if (base_url.is_empty ())
        return "";
    if (!base_url.ends_with ('/'))
        base_url.append ('/');
    return base_url + QStringLiteral ("conflicts.html");
}

string Theme.override_server_url () {
#ifdef APPLICATION_SERVER_URL
    return string.from_latin1 (APPLICATION_SERVER_URL);
#else
    return "";
#endif
}

bool Theme.force_override_server_url () {
#ifdef APPLICATION_SERVER_URL_ENFORCE
    return true;
#else
    return false;
#endif
}

bool Theme.enable_stapling_oCSP () {
#ifdef APPLICATION_OCSP_STAPLING_ENABLED
    return true;
#else
    return false;
#endif
}

bool Theme.forbid_bad_s_sL () {
#ifdef APPLICATION_FORBID_BAD_SSL
    return true;
#else
    return false;
#endif
}

string Theme.force_config_auth_type () {
    return "";
}

string Theme.default_client_folder () {
    return app_name ();
}

string Theme.systray_icon_flavor (bool mono) {
    string flavor;
    if (mono) {
        flavor = Utility.has_dark_systray () ? QLatin1String ("white") : QLatin1String ("black");
    } else {
        flavor = QLatin1String ("colored");
    }
    return flavor;
}

void Theme.set_systray_use_mono_icons (bool mono) {
    _mono = mono;
    emit systray_use_mono_icons_changed (mono);
}

bool Theme.systray_use_mono_icons () {
    return _mono;
}

bool Theme.mono_icons_available () {
    string theme_dir = string (Theme.theme_prefix) + string.from_latin1 ("%1/").arg (Theme.instance ().systray_icon_flavor (true));
    return QDir (theme_dir).exists ();
}

string Theme.update_check_url () {
    return APPLICATION_UPDATE_URL;
}

int64 Theme.new_big_folder_size_limit () {
    // Default to 500MB
    return 500;
}

bool Theme.wizard_hide_external_storage_confirmation_checkbox () {
    return false;
}

bool Theme.wizard_hide_folder_size_limit_checkbox () {
    return false;
}

string Theme.git_sHA1 () {
    string dev_string;
#ifdef GIT_SHA1
    const string github_prefix (QLatin1String (
        "https://github.com/nextcloud/desktop/commit/"));
    const string git_sha1 (QLatin1String (GIT_SHA1));
    dev_string = QCoreApplication.translate ("nextcloud_theme.about ()",
        "<p><small>Built from Git revision <a href=\"%1\">%2</a>"
        " on %3, %4 using Qt %5, %6</small></p>")
                    .arg (github_prefix + git_sha1)
                    .arg (git_sha1.left (6))
                    .arg (__DATE__)
                    .arg (__TIME__)
                    .arg (q_version ())
                    .arg (QSslSocket.ssl_library_version_"");
#endif
    return dev_string;
}

string Theme.about () {
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

    dev_string += _("<p><small>Using virtual files plugin : %1</small></p>")
                     .arg (Vfs.mode_to_string (best_available_vfs_mode ()));
    dev_string += QStringLiteral ("<br>%1")
              .arg (QSysInfo.product_type () % '-' % QSysInfo.kernel_version ());

    return dev_string;
}

string Theme.about_details () {
    string dev_string;
    dev_string = _("<p>Version %1. For more information please click <a href='%2'>here</a>.</p>")
              .arg (MIRALL_VERSION_STRING)
              .arg (help_url ());

    dev_string += _("<p>This release was supplied by %1</p>")
              .arg (APPLICATION_VENDOR);

    dev_string += git_sHA1 ();

    return dev_string;
}

#ifndef TOKEN_AUTH_ONLY
QVariant Theme.custom_media (Custom_media_type type) {
    QVariant re;
    string key;

    switch (type) {
    case o_c_setup_top:
        key = QLatin1String ("o_c_setup_top");
        break;
    case o_c_setup_side:
        key = QLatin1String ("o_c_setup_side");
        break;
    case o_c_setup_bottom:
        key = QLatin1String ("o_c_setup_bottom");
        break;
    case o_c_setup_result_top:
        key = QLatin1String ("o_c_setup_result_top");
        break;
    }

    string img_path = string (Theme.theme_prefix) + string.from_latin1 ("colored/%1.png").arg (key);
    if (GLib.File.exists (img_path)) {
        QPixmap pix (img_path);
        if (pix.is_null ()) {
            // pixmap loading hasn't succeeded. We take the text instead.
            re.set_value (key);
        } else {
            re.set_value (pix);
        }
    }
    return re;
}

QIcon Theme.sync_state_icon (SyncResult.Status status, bool sys_tray) {
    // FIXME : Mind the size!
    string status_icon;

    switch (status) {
    case SyncResult.Undefined:
        // this can happen if no sync connections are configured.
        status_icon = QLatin1String ("state-warning");
        break;
    case SyncResult.NotYetStarted:
    case SyncResult.Sync_running:
        status_icon = QLatin1String ("state-sync");
        break;
    case SyncResult.Sync_abort_requested:
    case SyncResult.Paused:
        status_icon = QLatin1String ("state-pause");
        break;
    case SyncResult.Sync_prepare:
    case SyncResult.Success:
        status_icon = QLatin1String ("state-ok");
        break;
    case SyncResult.Problem:
        status_icon = QLatin1String ("state-warning");
        break;
    case SyncResult.Error:
    case SyncResult.Setup_error:
    // FIXME : Use state-problem once we have an icon.
    default:
        status_icon = QLatin1String ("state-error");
    }

    return theme_icon (status_icon, sys_tray);
}

QIcon Theme.folder_disabled_icon () {
    return theme_icon (QLatin1String ("state-pause"));
}

QIcon Theme.folder_offline_icon (bool sys_tray) {
    return theme_icon (QLatin1String ("state-offline"), sys_tray);
}

QColor Theme.wizard_header_title_color () {
    return {APPLICATION_WIZARD_HEADER_TITLE_COLOR};
}

QColor Theme.wizard_header_background_color () {
    return {APPLICATION_WIZARD_HEADER_BACKGROUND_COLOR};
}

QPixmap Theme.wizard_application_logo () {
    if (!Theme.is_branded ()) {
        return QPixmap (Theme.hidpi_file_name (string (Theme.theme_prefix) + "colored/wizard-nextcloud.png"));
    }
#ifdef APPLICATION_WIZARD_USE_CUSTOM_LOGO
    const var use_svg = should_prefer_svg ();
    const string logo_base_path = string (Theme.theme_prefix) + QStringLiteral ("colored/wizard_logo");
    if (use_svg) {
        const var max_height = Theme.is_hidpi () ? 200 : 100;
        const var max_width = 2 * max_height;
        const var icon = QIcon (logo_base_path + ".svg");
        const var size = icon.actual_size (QSize (max_width, max_height));
        return icon.pixmap (size);
    } else {
        return QPixmap (hidpi_file_name (logo_base_path + ".png"));
    }
#else
    const var size = Theme.is_hidpi () ? : 200 : 100;
    return application_icon ().pixmap (size);
#endif
}

QPixmap Theme.wizard_header_logo () {
#ifdef APPLICATION_WIZARD_USE_CUSTOM_LOGO
    const var use_svg = should_prefer_svg ();
    const string logo_base_path = string (Theme.theme_prefix) + QStringLiteral ("colored/wizard_logo");
    if (use_svg) {
        const var max_height = 64;
        const var max_width = 2 * max_height;
        const var icon = QIcon (logo_base_path + ".svg");
        const var size = icon.actual_size (QSize (max_width, max_height));
        return icon.pixmap (size);
    } else {
        return QPixmap (hidpi_file_name (logo_base_path + ".png"));
    }
#else
    return application_icon ().pixmap (64);
#endif
}

QPixmap Theme.wizard_header_banner () {
    QColor c = wizard_header_background_color ();
    if (!c.is_valid ())
        return QPixmap ();

    QSize size (750, 78);
    if (var screen = q_app.primary_screen ()) {
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
#endif

bool Theme.wizard_selective_sync_default_nothing () {
    return false;
}

bool Theme.link_sharing () {
    return true;
}

bool Theme.user_group_sharing () {
    return true;
}

bool Theme.force_system_network_proxy () {
    return false;
}

Theme.User_iDType Theme.user_iDType () {
    return User_iDType.User_iDUser_name;
}

string Theme.custom_user_iD () {
    return "";
}

string Theme.user_iDHint () {
    return "";
}

string Theme.wizard_url_postfix () {
    return "";
}

string Theme.wizard_url_hint () {
    return "";
}

string Theme.quota_base_folder () {
    return QLatin1String ("/");
}

string Theme.oauth_client_id () {
    return "xd_xOt13JKxym1B1Qc_encf2XDk_lAex_m_bFwi_t9j6Efhh_hFJhs2KM9jbj_tmf8JBXE69";
}

string Theme.oauth_client_secret () {
    return "UBntm_lj_c2y_yCe_hwsyj73Uwo9TAaec_aet_rw_mw0x_ycv_nL9y_rd_l_s_ui0h_uAHfv_c_hFe_fh";
}

string Theme.version_switch_output () {
    string help_text;
    QTextStream stream (&help_text);
    stream << app_name ()
           << QLatin1String (" version ")
           << version () << Qt.endl;
#ifdef GIT_SHA1
    stream << "Git revision " << GIT_SHA1 << Qt.endl;
#endif
    stream << "Using Qt " << q_version () << ", built against Qt " << QT_VERSION_STR << Qt.endl;

    if (!QGuiApplication.platform_name ().is_empty ())
        stream << "Using Qt platform plugin '" << QGuiApplication.platform_name () << "'" << Qt.endl;

    stream << "Using '" << QSslSocket.ssl_library_version_"" << "'" << Qt.endl;
    stream << "Running on " << Utility.platform_name () << ", " << QSysInfo.current_cpu_architecture () << Qt.endl;
    return help_text;
}

bool Theme.is_dark_color (QColor &color) {
    // account for different sensitivity of the human eye to certain colors
    double treshold = 1.0 - (0.299 * color.red () + 0.587 * color.green () + 0.114 * color.blue ()) / 255.0;
    return treshold > 0.5;
}

QColor Theme.get_background_aware_link_color (QColor &background_color) {
    return {
        (is_dark_color (background_color) ? QColor ("#6193dc") : QGuiApplication.palette ().color (QPalette.Link))
    };
}

QColor Theme.get_background_aware_link_color () {
    return get_background_aware_link_color (QGuiApplication.palette ().base ().color ());
}

void Theme.replace_link_color_string_background_aware (string link_string, QColor &background_color) {
    replace_link_color_string (link_string, get_background_aware_link_color (background_color));
}

void Theme.replace_link_color_string_background_aware (string link_string) {
    replace_link_color_string_background_aware (link_string, QGuiApplication.palette ().color (QPalette.Base));
}

void Theme.replace_link_color_string (string link_string, QColor &new_color) {
    link_string.replace (QRegularExpression (" (<a href|<a style='color:# ([a-z_a-Z0-9]{6});' href)"), string.from_latin1 ("<a style='color:%1;' href").arg (new_color.name ()));
}

QIcon Theme.create_color_aware_icon (string name, QPalette &palette) {
    QSvgRenderer renderer (name);
    QImage img (64, 64, QImage.Format_ARGB32);
    img.fill (Qt.Global_color.transparent);
    QPainter img_painter (&img);
    QImage inverted (64, 64, QImage.Format_ARGB32);
    inverted.fill (Qt.Global_color.transparent);
    QPainter inv_painter (&inverted);

    renderer.render (&img_painter);
    renderer.render (&inv_painter);

    inverted.invert_pixels (QImage.Invert_rgb);

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

QIcon Theme.create_color_aware_icon (string name) {
    return create_color_aware_icon (name, QGuiApplication.palette ());
}

QPixmap Theme.create_color_aware_pixmap (string name, QPalette &palette) {
    QImage img (name);
    QImage inverted (img);
    inverted.invert_pixels (QImage.Invert_rgb);

    QPixmap pixmap;
    if (Theme.is_dark_color (palette.color (QPalette.Base))) {
        pixmap = QPixmap.from_image (inverted);
    } else {
        pixmap = QPixmap.from_image (img);
    }
    return pixmap;
}

QPixmap Theme.create_color_aware_pixmap (string name) {
    return create_color_aware_pixmap (name, QGuiApplication.palette ());
}

bool Theme.show_virtual_files_option () {
    const var vfs_mode = best_available_vfs_mode ();
    return ConfigFile ().show_experimental_options () || vfs_mode == Vfs.WindowsCfApi;
}

bool Theme.enforce_virtual_files_sync_folder () {
    const var vfs_mode = best_available_vfs_mode ();
    return ENFORCE_VIRTUAL_FILES_SYNC_FOLDER && vfs_mode != Occ.Vfs.Off;
}

QColor Theme.error_box_text_color () {
    return QColor{"white"};
}

QColor Theme.error_box_background_color () {
    return QColor{"red"};
}

QColor Theme.error_box_border_color () {
    return QColor{"black"};
}

} // end namespace client
