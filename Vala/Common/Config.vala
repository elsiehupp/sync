namespace Occ {
namespace Common {

public class Config : GLib.Object {

    public const string APPLICATION_NAME = "Nextcloud";
    public const string APPLICATION_SHORTNAME = "Nextcloud";
    public const string APPLICATION_EXECUTABLE = "nextcloud";
    public const string APPLICATION_DOMAIN = "nextcloud.com";
    public const string APPLICATION_VENDOR = "Nextcloud GmbH";

    /***********************************************************
    URL for updater
    ***********************************************************/
    public const string APPLICATION_UPDATE_URL = "https://updates.nextcloud.org/client/";

    /***********************************************************
    URL for the help menu
    ***********************************************************/
    public const string APPLICATION_HELP_URL = "";
    public const string APPLICATION_ICON_NAME = "Nextcloud";
    public const string APPLICATION_ICON_SET = "SVG";

    /***********************************************************
    URL for the server to use. If entered, the UI field will be
    pre-filled with it.
    ***********************************************************/
    public const string APPLICATION_SERVER_URL = "";

    /***********************************************************
    If set and APPLICATION_SERVER_URL is defined, the server can
    only connect to the pre-defined URL.
    ***********************************************************/
    public const bool APPLICATION_SERVER_URL_ENFORCE = true;
    public const string APPLICATION_REV_DOMAIN = "com.nextcloud.desktopclient";

    /***********************************************************
    Virtual file suffix (not including the .)
    ***********************************************************/
    public const string APPLICATION_VIRTUALFILE_SUFFIX = "nextcloud";
    public const bool APPLICATION_OCSP_STAPLING_ENABLED = false;
    public const bool APPLICATION_FORBID_BAD_SSL = false;

    public const string LINUX_PACKAGE_SHORTNAME = "nextcloud";
    public const string LINUX_APPLICATION_ID = APPLICATION_REV_DOMAIN + "." + LINUX_PACKAGE_SHORTNAME;

    public const string THEME_CLASS = "NextcloudTheme";

    public const string THEME_INCLUDE = "${OEM_THEME_DIR}/mytheme.h";
    public const string APPLICATION_LICENSE = "${OEM_THEME_DIR}/license.txt";

    /***********************************************************
    Build crash reporter
    ***********************************************************/
    public const bool WITH_CRASHREPORTER = false;

    /***********************************************************
    ***********************************************************/
    public const string CRASHREPORTER_SUBMIT_URL = "https://crash-reports.owncloud.com/submit"; // CACHE STRING "URL for crash reporter";
    public const string RASHREPORTER_ICON = ":/owncloud-icon.png";

    /***********************************************************
    Updater Options
    ***********************************************************/

    /***********************************************************
    Build updater
    ***********************************************************/
    public const bool BUILD_UPDATER = false;

    /***********************************************************
    Build with providers list
    ***********************************************************/
    public const bool WITH_PROVIDERS = true;

    /***********************************************************
    Enforce use of virtual files sync folder when available
    ***********************************************************/
    public const bool ENFORCE_VIRTUAL_FILES_SYNC_FOLDER = false;

    /***********************************************************
    Theming Options
    ***********************************************************/

    /***********************************************************
    Default Nextcloud background color
    ***********************************************************/
    public const string NEXTCLOUD_BACKGROUND_COLOR = "//0082c9";

    /***********************************************************
    Hex color of the wizard header background
    ***********************************************************/
    public const string APPLICATION_WIZARD_HEADER_BACKGROUND_COLOR = NEXTCLOUD_BACKGROUND_COLOR;

    /***********************************************************
    Hex color of the text in the wizard header
    ***********************************************************/
    public const string APPLICATION_WIZARD_HEADER_TITLE_COLOR = "//ffffff";

    /***********************************************************
    Use the logo from ':/client/theme/colored/wizard_logo.(png|svg)'
    else the default application icon is used
    ***********************************************************/
    public const bool APPLICATION_WIZARD_USE_CUSTOM_LOGO = true;

} // class Config

} // namespace Common
} // namespace Occ
