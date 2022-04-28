namespace Occ {
namespace Common {

public class Config : GLib.Object {

    public const string APPLICATION_NAME = "Nextcloud";
    public const string APPLICATION_SHORTNAME = "Nextcloud";
    public const string APPLICATION_EXECUTABLE = "nextcloud";
    public const string APPLICATION_DOMAIN = "nextcloud.com";
    public const string APPLICATION_VENDOR = "Nextcloud GmbH";
    public const string APPLICATION_UPDATE_URL = "https://updates.nextcloud.org/client/"; // "URL for updater"
    public const string APPLICATION_HELP_URL = ""; // "URL for the help menu" )
    public const string APPLICATION_ICON_NAME = "Nextcloud";
    public const string APPLICATION_ICON_SET = "SVG";
    public const string APPLICATION_SERVER_URL = ""; // "URL for the server to use. If entered, the UI field will be pre-filled with it" )
    public const bool APPLICATION_SERVER_URL_ENFORCE = true; // If set and APPLICATION_SERVER_URL is defined, the server can only connect to the pre-defined URL
    public const string APPLICATION_REV_DOMAIN = "com.nextcloud.desktopclient";
    public const string APPLICATION_VIRTUALFILE_SUFFIX = "nextcloud"; // "Virtual file suffix (not including the .)")
    public const bool APPLICATION_OCSP_STAPLING_ENABLED = false;
    public const bool APPLICATION_FORBID_BAD_SSL = false;

    public const string LINUX_PACKAGE_SHORTNAME = "nextcloud";
    public const string LINUX_APPLICATION_ID = APPLICATION_REV_DOMAIN + "." + LINUX_PACKAGE_SHORTNAME;

    public const string THEME_CLASS = "NextcloudTheme";

    // set( THEME_INCLUDE          "${OEM_THEME_DIR}/mytheme.h" )
    // set( APPLICATION_LICENSE    "${OEM_THEME_DIR}/license.txt )

    public const bool WITH_CRASHREPORTER = false; // "Build crashreporter"
    //  set( CRASHREPORTER_SUBMIT_URL "https://crash-reports.owncloud.com/submit" CACHE STRING "URL for crash reporter" )
    //  set( CRASHREPORTER_ICON ":/owncloud-icon.png" )

    //  // Updater options
    public const bool BUILD_UPDATER = false; // "Build updater""Build updater"

    public const bool WITH_PROVIDERS = true; // "Build with providers list"

    public const bool ENFORCE_VIRTUAL_FILES_SYNC_FOLDER = false; // "Enforce use of virtual files sync folder when available"

    //  // Theming options
    public const string NEXTCLOUD_BACKGROUND_COLOR = "//0082c9"; //  "Default Nextcloud background color"
    public const string APPLICATION_WIZARD_HEADER_BACKGROUND_COLOR = NEXTCLOUD_BACKGROUND_COLOR; // "Hex color of the wizard header background")
    public const string APPLICATION_WIZARD_HEADER_TITLE_COLOR = "//ffffff"; // "Hex color of the text in the wizard header")
    public const bool APPLICATION_WIZARD_USE_CUSTOM_LOGO = true; // "Use the logo from ':/client/theme/colored/wizard_logo.(png|svg)' else the default application icon is used" ON )

} // class Config

} // namespace Common
} // namespace Occ
