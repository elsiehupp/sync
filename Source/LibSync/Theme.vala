/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QIcon>
// #include <GLib.Object>

class GLib.Object;
class QPalette;

namespace Occ {


/***********************************************************
@brief The Theme class
@ingroup libsync
***********************************************************/
class Theme : GLib.Object {
    Q_PROPERTY (bool branded READ isBranded CONSTANT)
    Q_PROPERTY (string appNameGUI READ appNameGUI CONSTANT)
    Q_PROPERTY (string appName READ appName CONSTANT)
    Q_PROPERTY (QUrl stateOnlineImageSource READ stateOnlineImageSource CONSTANT)
    Q_PROPERTY (QUrl stateOfflineImageSource READ stateOfflineImageSource CONSTANT)
    Q_PROPERTY (QUrl statusOnlineImageSource READ statusOnlineImageSource CONSTANT)
    Q_PROPERTY (QUrl statusDoNotDisturbImageSource READ statusDoNotDisturbImageSource CONSTANT)
    Q_PROPERTY (QUrl statusAwayImageSource READ statusAwayImageSource CONSTANT)
    Q_PROPERTY (QUrl statusInvisibleImageSource READ statusInvisibleImageSource CONSTANT)
#ifndef TOKEN_AUTH_ONLY
    Q_PROPERTY (QIcon folderDisabledIcon READ folderDisabledIcon CONSTANT)
    Q_PROPERTY (QIcon folderOfflineIcon READ folderOfflineIcon CONSTANT)
    Q_PROPERTY (QIcon applicationIcon READ applicationIcon CONSTANT)
#endif
    Q_PROPERTY (string version READ version CONSTANT)
    Q_PROPERTY (string helpUrl READ helpUrl CONSTANT)
    Q_PROPERTY (string conflictHelpUrl READ conflictHelpUrl CONSTANT)
    Q_PROPERTY (string overrideServerUrl READ overrideServerUrl)
    Q_PROPERTY (bool forceOverrideServerUrl READ forceOverrideServerUrl)
#ifndef TOKEN_AUTH_ONLY
    Q_PROPERTY (QColor wizardHeaderTitleColor READ wizardHeaderTitleColor CONSTANT)
    Q_PROPERTY (QColor wizardHeaderBackgroundColor READ wizardHeaderBackgroundColor CONSTANT)
#endif
    Q_PROPERTY (string updateCheckUrl READ updateCheckUrl CONSTANT)

    Q_PROPERTY (QColor errorBoxTextColor READ errorBoxTextColor CONSTANT)
    Q_PROPERTY (QColor errorBoxBackgroundColor READ errorBoxBackgroundColor CONSTANT)
    Q_PROPERTY (QColor errorBoxBorderColor READ errorBoxBorderColor CONSTANT)
public:
    enum CustomMediaType {
        oCSetupTop, // ownCloud connect page
        oCSetupSide,
        oCSetupBottom,
        oCSetupResultTop // ownCloud connect result page
    };

    /* returns a singleton instance. */
    static Theme *instance ();

    ~Theme () override;

    /***********************************************************
     * @brief isBranded indicates if the current application is branded
     *
     * By default, it is considered branded if the APPLICATION_NAME is
     * different from "Nextcloud".
     *
     * @return true if branded, false otherwise
     */
    virtual bool isBranded ();

    /***********************************************************
     * @brief appNameGUI - Human readable application name.
     *
     * Use and redefine this if the human readable name contains spaces,
     * special chars and such.
     *
     * By default, the name is derived from the APPLICATION_NAME
     * cmake variable.
     *
     * @return string with human readable app name.
     */
    virtual string appNameGUI ();

    /***********************************************************
     * @brief appName - Application name (short)
     *
     * Use and redefine this as an application name. Keep it straight as
     * it is used for config files etc. If you need a more sophisticated
     * name in the GUI, redefine appNameGUI.
     *
     * By default, the name is derived from the APPLICATION_SHORTNAME
     * cmake variable, and should be the same. This method is only
     * reimplementable for legacy reasons.
     *
     * Warning : Do not modify this value, as many things, e.g. settings
     * depend on it! You most likely want to modify \ref appNameGUI ().
     *
     * @return string with app name.
     */
    virtual string appName ();

    /***********************************************************
     * @brief Returns full path to an online state icon
     * @return QUrl full path to an icon
     */
    QUrl stateOnlineImageSource ();

    /***********************************************************
     * @brief Returns full path to an offline state icon
     * @return QUrl full path to an icon
     */
    QUrl stateOfflineImageSource ();

    /***********************************************************
     * @brief Returns full path to an online user status icon
     * @return QUrl full path to an icon
     */
    QUrl statusOnlineImageSource ();

    /***********************************************************
     * @brief Returns full path to an do not disturb user status icon
     * @return QUrl full path to an icon
     */
    QUrl statusDoNotDisturbImageSource ();

    /***********************************************************
     * @brief Returns full path to an away user status icon
     * @return QUrl full path to an icon
     */
    QUrl statusAwayImageSource ();

    /***********************************************************
     * @brief Returns full path to an invisible user status icon
     * @return QUrl full path to an icon
     */
    QUrl statusInvisibleImageSource ();

    QUrl syncStatusOk ();

    QUrl syncStatusError ();

    QUrl syncStatusRunning ();

    QUrl syncStatusPause ();

    QUrl syncStatusWarning ();

    QUrl folderOffline ();

    /***********************************************************
     * @brief configFileName
     * @return the name of the config file.
     */
    virtual string configFileName ();

#ifndef TOKEN_AUTH_ONLY
    static string hidpiFileName (string &fileName, QPaintDevice *dev = nullptr);

    static string hidpiFileName (string &iconName, QColor &backgroundColor, QPaintDevice *dev = nullptr);

    static bool isHidpi (QPaintDevice *dev = nullptr);

    /***********************************************************
      * get an sync state icon
      */
    virtual QIcon syncStateIcon (SyncResult.Status, bool sysTray = false) const;

    virtual QIcon folderDisabledIcon ();
    virtual QIcon folderOfflineIcon (bool sysTray = false) const;
    virtual QIcon applicationIcon ();
#endif

    virtual string statusHeaderText (SyncResult.Status) const;
    virtual string version ();

    /***********************************************************
     * Characteristics : bool if more than one sync folder is allowed
     */
    virtual bool singleSyncFolder ();

    /***********************************************************
     * When true, client works with multiple accounts.
     */
    virtual bool multiAccount ();

    /***********************************************************
    * URL to documentation.
    *
    * This is opened in the browser when the "Help" action is selected from the tray menu.
    *
    * If the function is overridden to return an empty string the action is removed from
    * the menu.
    *
    * Defaults to Nextclouds client documentation website.
    */
    virtual string helpUrl ();

    /***********************************************************
     * The url to use for showing help on conflicts.
     *
     * If the function is overridden to return an empty string no help link will be shown.
     *
     * Defaults to helpUrl () + "conflicts.html", which is a page in ownCloud's client
     * documentation website. If helpUrl () is empty, this function will also return the
     * empty string.
     */
    virtual string conflictHelpUrl ();

    /***********************************************************
     * Setting a value here will pre-define the server url.
     *
     * The respective UI controls will be disabled only if forceOverrideServerUrl () is true
     */
    virtual string overrideServerUrl ();

    /***********************************************************
     * Enforce a pre-defined server url.
     *
     * When true, the respective UI controls will be disabled
     */
    virtual bool forceOverrideServerUrl ();

    /***********************************************************
     * Enable OCSP stapling for SSL handshakes
     *
     * When true, peer will be requested for Online Certificate Status Protocol response
     */
    virtual bool enableStaplingOCSP ();

    /***********************************************************
     * Enforce SSL validity
     *
     * When true, trusting the untrusted certificate is not allowed
     */
    virtual bool forbidBadSSL ();

    /***********************************************************
     * This is only usefull when previous version had a different overrideServerUrl
     * with a different auth type in that case You should then specify "http" or "shibboleth".
     * Normaly this should be left empty.
     */
    virtual string forceConfigAuthType ();

    /***********************************************************
     * The default folder name without path on the server at setup time.
     */
    virtual string defaultServerFolder ();

    /***********************************************************
     * The default folder name without path on the client side at setup time.
     */
    virtual string defaultClientFolder ();

    /***********************************************************
     * Override to encforce a particular locale, i.e. "de" or "pt_BR"
     */
    virtual string enforcedLocale () { return string (); }

    /** colored, white or black */
    string systrayIconFlavor (bool mono) const;

#ifndef TOKEN_AUTH_ONLY
    /***********************************************************
     * Override to use a string or a custom image name.
     * The default implementation will try to look up
     * :/client/theme/<type>.png
     */
    virtual QVariant customMedia (CustomMediaType type);

    /** @return color for the setup wizard */
    virtual QColor wizardHeaderTitleColor ();

    /** @return color for the setup wizard. */
    virtual QColor wizardHeaderBackgroundColor ();

    virtual QPixmap wizardApplicationLogo ();

    /** @return logo for the setup wizard. */
    virtual QPixmap wizardHeaderLogo ();

    /***********************************************************
     * The default implementation creates a
     * background based on
     * \ref wizardHeaderTitleColor ().
     *
     * @return banner for the setup wizard.
     */
    virtual QPixmap wizardHeaderBanner ();
#endif

    /***********************************************************
     * The SHA sum of the released git commit
     */
    string gitSHA1 ();

    /***********************************************************
     * About dialog contents
     */
    virtual string about ();

    /***********************************************************
     * Legal notice dialog version detail contents
     */
    virtual string aboutDetails ();

    /***********************************************************
     * Define if the systray icons should be using mono design
     */
    void setSystrayUseMonoIcons (bool mono);

    /***********************************************************
     * Retrieve wether to use mono icons for systray
     */
    bool systrayUseMonoIcons ();

    /***********************************************************
     * Check if mono icons are available
     */
    bool monoIconsAvailable ();

    /***********************************************************
     * @brief Where to check for new Updates.
     */
    virtual string updateCheckUrl ();

    /***********************************************************
     * When true, the setup wizard will show the selective sync dialog by default and default
     * to nothing selected
     */
    virtual bool wizardSelectiveSyncDefaultNothing ();

    /***********************************************************
     * Default option for the newBigFolderSizeLimit.
     * Size in MB of the maximum size of folder before we ask the confirmation.
     * Set -1 to never ask confirmation.  0 to ask confirmation for every folder.
     **/
    virtual int64 newBigFolderSizeLimit ();

    /***********************************************************
     * Hide the checkbox that says "Ask for confirmation before synchronizing folders larger than X MB"
     * in the account wizard
     */
    virtual bool wizardHideFolderSizeLimitCheckbox ();
    /***********************************************************
     * Hide the checkbox that says "Ask for confirmation before synchronizing external storages"
     * in the account wizard
     */
    virtual bool wizardHideExternalStorageConfirmationCheckbox ();

    /***********************************************************
     * @brief Sharing options
     *
     * Allow link sharing and or user/group sharing
     */
    virtual bool linkSharing ();
    virtual bool userGroupSharing ();

    /***********************************************************
     * If this returns true, the user cannot configure the proxy in the network settings.
     * The proxy settings will be disabled in the configuration dialog.
     * Default returns false.
     */
    virtual bool forceSystemNetworkProxy ();

    /***********************************************************
     * @brief How to handle the userID
     *
     * @value UserIDUserName Wizard asks for user name as ID
     * @value UserIDEmail Wizard asks for an email as ID
     * @value UserIDCustom Specify string in \ref customUserID
     */
    enum UserIDType { UserIDUserName = 0,
        UserIDEmail,
        UserIDCustom };

    /** @brief What to display as the userID (e.g. in the wizards)
     *
     *  @return UserIDType.UserIDUserName, unless reimplemented
     */
    virtual UserIDType userIDType ();

    /***********************************************************
     * @brief Allows to customize the type of user ID (e.g. user name, email)
     *
     * @note This string cannot be translated, but is still useful for
     *       referencing brand name IDs (e.g. "ACME ID", when using ACME.)
     *
     * @return An empty string, unless reimplemented
     */
    virtual string customUserID ();

    /***********************************************************
     * @brief Demo string to be displayed when no text has been
     *        entered for the user id (e.g. mylogin@company.com)
     *
     * @return An empty string, unless reimplemented
     */
    virtual string userIDHint ();

    /***********************************************************
     * @brief Postfix that will be enforced in a URL. e.g.
     *        ".myhosting.com".
     *
     * @return An empty string, unless reimplemented
     */
    virtual string wizardUrlPostfix ();

    /***********************************************************
     * @brief String that will be shown as long as no text has been entered by the user.
     *
     * @return An empty string, unless reimplemented
     */
    virtual string wizardUrlHint ();

    /***********************************************************
     * @brief the server folder that should be queried for the quota information
     *
     * This can be configured to show the quota infromation for a different
     * folder than the root. This is the folder on which the client will do
     * PROPFIND calls to get "quota-available-bytes" and "quota-used-bytes"
     *
     * Defaults : "/"
     */
    virtual string quotaBaseFolder ();

    /***********************************************************
     * The OAuth client_id, secret pair.
     * Note that client that change these value cannot connect to un-branded owncloud servers.
     */
    virtual string oauthClientId ();
    virtual string oauthClientSecret ();

    /***********************************************************
     * @brief What should be output for the --version command line switch.
     *
     * By default, it's a combination of appName (), version (), the GIT SHA1 and some
     * important dependency versions.
     */
    virtual string versionSwitchOutput ();
	
	/***********************************************************
    * @brief Request suitable QIcon resource depending on the background colour of the parent widget.
    *
    * This should be replaced (TODO) by a real theming implementation for the client UI
    * (actually 2019/09/13 only systray theming).
    */
	virtual QIcon uiThemeIcon (string &iconName, bool uiHasDarkBg) const;

    /***********************************************************
     * @brief Perform a calculation to check if a colour is dark or light and accounts for different sensitivity of the human eye.
     *
     * @return True if the specified colour is dark.
     *
     * 2019/12/08 : Moved here from SettingsDialog.
     */
    static bool isDarkColor (QColor &color);

    /***********************************************************
     * @brief Return the colour to be used for HTML links (e.g. used in QLabel), based on the current app palette or given colour (Dark-/Light-Mode switching).
     *
     * @return Background-aware colour for HTML links, based on the current app palette or given colour.
     *
     * 2019/12/08 : Implemented for the Dark Mode on macOS, because the app palette can not account for that (Qt 5.12.5).
     */
    static QColor getBackgroundAwareLinkColor (QColor &backgroundColor);

    /***********************************************************
     * @brief Return the colour to be used for HTML links (e.g. used in QLabel), based on the current app palette (Dark-/Light-Mode switching).
     *
     * @return Background-aware colour for HTML links, based on the current app palette.
     *
     * 2019/12/08 : Implemented for the Dark Mode on macOS, because the app palette can not account for that (Qt 5.12.5).
     */
    static QColor getBackgroundAwareLinkColor ();

    /***********************************************************
     * @brief Appends a CSS-style colour value to all HTML link tags in a given string, based on the current app palette or given colour (Dark-/Light-Mode switching).
     *
     * 2019/12/08 : Implemented for the Dark Mode on macOS, because the app palette can not account for that (Qt 5.12.5).
     *
     * This way we also avoid having certain strings re-translated on Transifex.
     */
    static void replaceLinkColorStringBackgroundAware (string &linkString, QColor &backgroundColor);

    /***********************************************************
     * @brief Appends a CSS-style colour value to all HTML link tags in a given string, based on the current app palette (Dark-/Light-Mode switching).
     *
     * 2019/12/08 : Implemented for the Dark Mode on macOS, because the app palette can not account for that (Qt 5.12.5).
     *
     * This way we also avoid having certain strings re-translated on Transifex.
     */
    static void replaceLinkColorStringBackgroundAware (string &linkString);

    /***********************************************************
     * @brief Appends a CSS-style colour value to all HTML link tags in a given string, as specified by newColor.
     *
     * 2019/12/19 : Implemented for the Dark Mode on macOS, because the app palette can not account for that (Qt 5.12.5).
     *
     * This way we also avoid having certain strings re-translated on Transifex.
     */
    static void replaceLinkColorString (string &linkString, QColor &newColor);

    /***********************************************************
     * @brief Creates a colour-aware icon based on the specified palette's base colour.
     *
     * @return QIcon, colour-aware (inverted on dark backgrounds).
     *
     * 2019/12/09 : Moved here from SettingsDialog.
     */
    static QIcon createColorAwareIcon (string &name, QPalette &palette);

    /***********************************************************
     * @brief Creates a colour-aware icon based on the app palette's base colour (Dark-/Light-Mode switching).
     *
     * @return QIcon, colour-aware (inverted on dark backgrounds).
     *
     * 2019/12/09 : Moved here from SettingsDialog.
     */
    static QIcon createColorAwareIcon (string &name);

    /***********************************************************
     * @brief Creates a colour-aware pixmap based on the specified palette's base colour.
     *
     * @return QPixmap, colour-aware (inverted on dark backgrounds).
     *
     * 2019/12/09 : Adapted from createColorAwareIcon.
     */
    static QPixmap createColorAwarePixmap (string &name, QPalette &palette);

    /***********************************************************
     * @brief Creates a colour-aware pixmap based on the app palette's base colour (Dark-/Light-Mode switching).
     *
     * @return QPixmap, colour-aware (inverted on dark backgrounds).
     *
     * 2019/12/09 : Adapted from createColorAwareIcon.
     */
    static QPixmap createColorAwarePixmap (string &name);

    /***********************************************************
     * @brief Whether to show the option to create folders using "virtual files".
     *
     * By default, the options are not shown unless experimental options are
     * manually enabled in the configuration file.
     */
    virtual bool showVirtualFilesOption ();

    virtual bool enforceVirtualFilesSyncFolder ();

    /** @return color for the ErrorBox text. */
    virtual QColor errorBoxTextColor ();

    /** @return color for the ErrorBox background. */
    virtual QColor errorBoxBackgroundColor ();

    /** @return color for the ErrorBox border. */
    virtual QColor errorBoxBorderColor ();

    static constexpr const char *themePrefix = ":/client/theme/";

protected:
#ifndef TOKEN_AUTH_ONLY
    QIcon themeIcon (string &name, bool sysTray = false) const;
#endif
    /***********************************************************
     * @brief Generates image path in the resources
     * @param name Name of the image file
     * @param size Size in the power of two (16, 32, 64, etc.)
     * @param sysTray Whether the image requested is for Systray or not
     * @return string image path in the resources
     **/
    string themeImagePath (string &name, int size = -1, bool sysTray = false) const;
    Theme ();

signals:
    void systrayUseMonoIconsChanged (bool);

private:
    Theme (Theme const &);
    Theme &operator= (Theme const &);

    static Theme *_instance;
    bool _mono = false;
#ifndef TOKEN_AUTH_ONLY
    mutable QHash<string, QIcon> _iconCache;
#endif
};
}








/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
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

namespace {

QUrl imagePathToUrl (string &imagePath) {
    if (imagePath.startsWith (':')) {
        auto url = QUrl ();
        url.setScheme (QStringLiteral ("qrc"));
        url.setPath (imagePath.mid (1));
        return url;
    } else {
        return QUrl.fromLocalFile (imagePath);
    }
}

bool shouldPreferSvg () {
    return QByteArray (APPLICATION_ICON_SET).toUpper () == QByteArrayLiteral ("SVG");
}

}

namespace Occ {

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

string Theme.statusHeaderText (SyncResult.Status status) {
    string resultStr;

    switch (status) {
    case SyncResult.Undefined:
        resultStr = QCoreApplication.translate ("theme", "Status undefined");
        break;
    case SyncResult.NotYetStarted:
        resultStr = QCoreApplication.translate ("theme", "Waiting to start sync");
        break;
    case SyncResult.SyncRunning:
        resultStr = QCoreApplication.translate ("theme", "Sync is running");
        break;
    case SyncResult.Success:
        resultStr = QCoreApplication.translate ("theme", "Sync Success");
        break;
    case SyncResult.Problem:
        resultStr = QCoreApplication.translate ("theme", "Sync Success, some files were ignored.");
        break;
    case SyncResult.Error:
        resultStr = QCoreApplication.translate ("theme", "Sync Error");
        break;
    case SyncResult.SetupError:
        resultStr = QCoreApplication.translate ("theme", "Setup Error");
        break;
    case SyncResult.SyncPrepare:
        resultStr = QCoreApplication.translate ("theme", "Preparing to sync");
        break;
    case SyncResult.SyncAbortRequested:
        resultStr = QCoreApplication.translate ("theme", "Aborting …");
        break;
    case SyncResult.Paused:
        resultStr = QCoreApplication.translate ("theme", "Sync is paused");
        break;
    }
    return resultStr;
}

bool Theme.isBranded () {
    return appNameGUI () != QStringLiteral ("Nextcloud");
}

string Theme.appNameGUI () {
    return APPLICATION_NAME;
}

string Theme.appName () {
    return APPLICATION_SHORTNAME;
}

QUrl Theme.stateOnlineImageSource () {
    return imagePathToUrl (themeImagePath ("state-ok"));
}

QUrl Theme.stateOfflineImageSource () {
    return imagePathToUrl (themeImagePath ("state-offline", 16));
}

QUrl Theme.statusOnlineImageSource () {
    return imagePathToUrl (themeImagePath ("user-status-online", 16));
}

QUrl Theme.statusDoNotDisturbImageSource () {
    return imagePathToUrl (themeImagePath ("user-status-dnd", 16));
}

QUrl Theme.statusAwayImageSource () {
    return imagePathToUrl (themeImagePath ("user-status-away", 16));
}

QUrl Theme.statusInvisibleImageSource () {
    return imagePathToUrl (themeImagePath ("user-status-invisible", 64));
}

QUrl Theme.syncStatusOk () {
    return imagePathToUrl (themeImagePath ("state-ok", 16));
}

QUrl Theme.syncStatusError () {
    return imagePathToUrl (themeImagePath ("state-error", 16));
}

QUrl Theme.syncStatusRunning () {
    return imagePathToUrl (themeImagePath ("state-sync", 16));
}

QUrl Theme.syncStatusPause () {
    return imagePathToUrl (themeImagePath ("state-pause", 16));
}

QUrl Theme.syncStatusWarning () {
    return imagePathToUrl (themeImagePath ("state-warning", 16));
}

QUrl Theme.folderOffline () {
    return imagePathToUrl (themeImagePath ("state-offline"));
}

string Theme.version () {
    return MIRALL_VERSION_STRING;
}

string Theme.configFileName () {
    return QStringLiteral (APPLICATION_EXECUTABLE ".cfg");
}

#ifndef TOKEN_AUTH_ONLY

QIcon Theme.applicationIcon () {
    return themeIcon (QStringLiteral (APPLICATION_ICON_NAME "-icon"));
}

/***********************************************************
helper to load a icon from either the icon theme the desktop provides or from
the apps Qt resources.
***********************************************************/
QIcon Theme.themeIcon (string &name, bool sysTray) {
    string flavor;
    if (sysTray) {
        flavor = systrayIconFlavor (_mono);
    } else {
        flavor = QLatin1String ("colored");
    }

    string key = name + "," + flavor;
    QIcon &cached = _iconCache[key];
    if (cached.isNull ()) {
        if (QIcon.hasThemeIcon (name)) {
            // use from theme
            return cached = QIcon.fromTheme (name);
        }

        const string svgName = string (Theme.themePrefix) + string.fromLatin1 ("%1/%2.svg").arg (flavor).arg (name);
        QSvgRenderer renderer (svgName);
        const auto createPixmapFromSvg = [&renderer] (int size) {
            QImage img (size, size, QImage.Format_ARGB32);
            img.fill (Qt.GlobalColor.transparent);
            QPainter imgPainter (&img);
            renderer.render (&imgPainter);
            return QPixmap.fromImage (img);
        };

        const auto loadPixmap = [flavor, name] (int size) {
            const string pixmapName = string (Theme.themePrefix) + string.fromLatin1 ("%1/%2-%3.png").arg (flavor).arg (name).arg (size);
            return QPixmap (pixmapName);
        };

        const auto useSvg = shouldPreferSvg ();
        const auto sizes = useSvg ? QVector<int>{ 16, 32, 64, 128, 256 }
                                  : QVector<int>{ 16, 22, 32, 48, 64, 128, 256, 512, 1024 };
        for (int size : sizes) {
            auto px = useSvg ? createPixmapFromSvg (size) : loadPixmap (size);
            if (px.isNull ()) {
                continue;
            }
            // HACK, get rid of it by supporting FDO icon themes, this is really just emulating ubuntu-mono
            if (qgetenv ("DESKTOP_SESSION") == "ubuntu") {
                QBitmap mask = px.createMaskFromColor (Qt.white, Qt.MaskOutColor);
                QPainter p (&px);
                p.setPen (QColor ("#dfdbd2"));
                p.drawPixmap (px.rect (), mask, mask.rect ());
            }
            cached.addPixmap (px);
        }
    }

    return cached;
}

string Theme.themeImagePath (string &name, int size, bool sysTray) {
    const auto flavor = (!isBranded () && sysTray) ? systrayIconFlavor (_mono) : QLatin1String ("colored");
    const auto useSvg = shouldPreferSvg ();

    // branded client may have several sizes of the same icon
    const string filePath = (useSvg || size <= 0)
            ? string (Theme.themePrefix) + string.fromLatin1 ("%1/%2").arg (flavor).arg (name)
            : string (Theme.themePrefix) + string.fromLatin1 ("%1/%2-%3").arg (flavor).arg (name).arg (size);

    const string svgPath = filePath + ".svg";
    if (useSvg) {
        return svgPath;
    }

    const string pngPath = filePath + ".png";
    // Use the SVG as fallback if a PNG is missing so that we get a chance to display something
    if (QFile.exists (pngPath)) {
        return pngPath;
    } else {
        return svgPath;
    }
}

bool Theme.isHidpi (QPaintDevice *dev) {
    const auto devicePixelRatio = dev ? dev.devicePixelRatio () : qApp.primaryScreen ().devicePixelRatio ();
    return devicePixelRatio > 1;
}

QIcon Theme.uiThemeIcon (string &iconName, bool uiHasDarkBg) {
    string iconPath = string (Theme.themePrefix) + (uiHasDarkBg ? "white/" : "black/") + iconName;
    std.string icnPath = iconPath.toUtf8 ().constData ();
    return QIcon (QPixmap (iconPath));
}

string Theme.hidpiFileName (string &fileName, QPaintDevice *dev) {
    if (!Theme.isHidpi (dev)) {
        return fileName;
    }
    // try to find a 2x version

    const int dotIndex = fileName.lastIndexOf (QLatin1Char ('.'));
    if (dotIndex != -1) {
        string at2xfileName = fileName;
        at2xfileName.insert (dotIndex, QStringLiteral ("@2x"));
        if (QFile.exists (at2xfileName)) {
            return at2xfileName;
        }
    }
    return fileName;
}

string Theme.hidpiFileName (string &iconName, QColor &backgroundColor, QPaintDevice *dev) {
    const auto isDarkBackground = Theme.isDarkColor (backgroundColor);

    const string iconPath = string (Theme.themePrefix) + (isDarkBackground ? "white/" : "black/") + iconName;

    return Theme.hidpiFileName (iconPath, dev);
}

#endif

Theme.Theme ()
    : GLib.Object (nullptr) {
}

// If this option returns true, the client only supports one folder to sync.
// The Add-Button is removed accordingly.
bool Theme.singleSyncFolder () {
    return false;
}

bool Theme.multiAccount () {
    return true;
}

string Theme.defaultServerFolder () {
    return QLatin1String ("/");
}

string Theme.helpUrl () {
#ifdef APPLICATION_HELP_URL
    return string.fromLatin1 (APPLICATION_HELP_URL);
#else
    return string.fromLatin1 ("https://docs.nextcloud.com/desktop/%1.%2/").arg (MIRALL_VERSION_MAJOR).arg (MIRALL_VERSION_MINOR);
#endif
}

string Theme.conflictHelpUrl () {
    auto baseUrl = helpUrl ();
    if (baseUrl.isEmpty ())
        return string ();
    if (!baseUrl.endsWith ('/'))
        baseUrl.append ('/');
    return baseUrl + QStringLiteral ("conflicts.html");
}

string Theme.overrideServerUrl () {
#ifdef APPLICATION_SERVER_URL
    return string.fromLatin1 (APPLICATION_SERVER_URL);
#else
    return string ();
#endif
}

bool Theme.forceOverrideServerUrl () {
#ifdef APPLICATION_SERVER_URL_ENFORCE
    return true;
#else
    return false;
#endif
}

bool Theme.enableStaplingOCSP () {
#ifdef APPLICATION_OCSP_STAPLING_ENABLED
    return true;
#else
    return false;
#endif
}

bool Theme.forbidBadSSL () {
#ifdef APPLICATION_FORBID_BAD_SSL
    return true;
#else
    return false;
#endif
}

string Theme.forceConfigAuthType () {
    return string ();
}

string Theme.defaultClientFolder () {
    return appName ();
}

string Theme.systrayIconFlavor (bool mono) {
    string flavor;
    if (mono) {
        flavor = Utility.hasDarkSystray () ? QLatin1String ("white") : QLatin1String ("black");
    } else {
        flavor = QLatin1String ("colored");
    }
    return flavor;
}

void Theme.setSystrayUseMonoIcons (bool mono) {
    _mono = mono;
    emit systrayUseMonoIconsChanged (mono);
}

bool Theme.systrayUseMonoIcons () {
    return _mono;
}

bool Theme.monoIconsAvailable () {
    string themeDir = string (Theme.themePrefix) + string.fromLatin1 ("%1/").arg (Theme.instance ().systrayIconFlavor (true));
    return QDir (themeDir).exists ();
}

string Theme.updateCheckUrl () {
    return APPLICATION_UPDATE_URL;
}

int64 Theme.newBigFolderSizeLimit () {
    // Default to 500MB
    return 500;
}

bool Theme.wizardHideExternalStorageConfirmationCheckbox () {
    return false;
}

bool Theme.wizardHideFolderSizeLimitCheckbox () {
    return false;
}

string Theme.gitSHA1 () {
    string devString;
#ifdef GIT_SHA1
    const string githubPrefix (QLatin1String (
        "https://github.com/nextcloud/desktop/commit/"));
    const string gitSha1 (QLatin1String (GIT_SHA1));
    devString = QCoreApplication.translate ("nextcloudTheme.about ()",
        "<p><small>Built from Git revision <a href=\"%1\">%2</a>"
        " on %3, %4 using Qt %5, %6</small></p>")
                    .arg (githubPrefix + gitSha1)
                    .arg (gitSha1.left (6))
                    .arg (__DATE__)
                    .arg (__TIME__)
                    .arg (qVersion ())
                    .arg (QSslSocket.sslLibraryVersionString ());
#endif
    return devString;
}

string Theme.about () {
    // Shorten Qt's OS name : "macOS Mojave (10.14)" . "macOS"
    QStringList osStringList = Utility.platformName ().split (QLatin1Char (' '));
    string osName = osStringList.at (0);

    string devString;
    // : Example text : "<p>Nextcloud Desktop Client</p>"   (%1 is the application name)
    devString = tr ("<p>%1 Desktop Client</p>")
              .arg (APPLICATION_NAME);

    devString += tr ("<p>Version %1. For more information please click <a href='%2'>here</a>.</p>")
              .arg (string.fromLatin1 (MIRALL_STRINGIFY (MIRALL_VERSION)) + string (" (%1)").arg (osName))
              .arg (helpUrl ());

    devString += tr ("<p><small>Using virtual files plugin : %1</small></p>")
                     .arg (Vfs.modeToString (bestAvailableVfsMode ()));
    devString += QStringLiteral ("<br>%1")
              .arg (QSysInfo.productType () % QLatin1Char ('-') % QSysInfo.kernelVersion ());

    return devString;
}

string Theme.aboutDetails () {
    string devString;
    devString = tr ("<p>Version %1. For more information please click <a href='%2'>here</a>.</p>")
              .arg (MIRALL_VERSION_STRING)
              .arg (helpUrl ());

    devString += tr ("<p>This release was supplied by %1</p>")
              .arg (APPLICATION_VENDOR);

    devString += gitSHA1 ();

    return devString;
}

#ifndef TOKEN_AUTH_ONLY
QVariant Theme.customMedia (CustomMediaType type) {
    QVariant re;
    string key;

    switch (type) {
    case oCSetupTop:
        key = QLatin1String ("oCSetupTop");
        break;
    case oCSetupSide:
        key = QLatin1String ("oCSetupSide");
        break;
    case oCSetupBottom:
        key = QLatin1String ("oCSetupBottom");
        break;
    case oCSetupResultTop:
        key = QLatin1String ("oCSetupResultTop");
        break;
    }

    string imgPath = string (Theme.themePrefix) + string.fromLatin1 ("colored/%1.png").arg (key);
    if (QFile.exists (imgPath)) {
        QPixmap pix (imgPath);
        if (pix.isNull ()) {
            // pixmap loading hasn't succeeded. We take the text instead.
            re.setValue (key);
        } else {
            re.setValue (pix);
        }
    }
    return re;
}

QIcon Theme.syncStateIcon (SyncResult.Status status, bool sysTray) {
    // FIXME : Mind the size!
    string statusIcon;

    switch (status) {
    case SyncResult.Undefined:
        // this can happen if no sync connections are configured.
        statusIcon = QLatin1String ("state-warning");
        break;
    case SyncResult.NotYetStarted:
    case SyncResult.SyncRunning:
        statusIcon = QLatin1String ("state-sync");
        break;
    case SyncResult.SyncAbortRequested:
    case SyncResult.Paused:
        statusIcon = QLatin1String ("state-pause");
        break;
    case SyncResult.SyncPrepare:
    case SyncResult.Success:
        statusIcon = QLatin1String ("state-ok");
        break;
    case SyncResult.Problem:
        statusIcon = QLatin1String ("state-warning");
        break;
    case SyncResult.Error:
    case SyncResult.SetupError:
    // FIXME : Use state-problem once we have an icon.
    default:
        statusIcon = QLatin1String ("state-error");
    }

    return themeIcon (statusIcon, sysTray);
}

QIcon Theme.folderDisabledIcon () {
    return themeIcon (QLatin1String ("state-pause"));
}

QIcon Theme.folderOfflineIcon (bool sysTray) {
    return themeIcon (QLatin1String ("state-offline"), sysTray);
}

QColor Theme.wizardHeaderTitleColor () {
    return {APPLICATION_WIZARD_HEADER_TITLE_COLOR};
}

QColor Theme.wizardHeaderBackgroundColor () {
    return {APPLICATION_WIZARD_HEADER_BACKGROUND_COLOR};
}

QPixmap Theme.wizardApplicationLogo () {
    if (!Theme.isBranded ()) {
        return QPixmap (Theme.hidpiFileName (string (Theme.themePrefix) + "colored/wizard-nextcloud.png"));
    }
#ifdef APPLICATION_WIZARD_USE_CUSTOM_LOGO
    const auto useSvg = shouldPreferSvg ();
    const string logoBasePath = string (Theme.themePrefix) + QStringLiteral ("colored/wizard_logo");
    if (useSvg) {
        const auto maxHeight = Theme.isHidpi () ? 200 : 100;
        const auto maxWidth = 2 * maxHeight;
        const auto icon = QIcon (logoBasePath + ".svg");
        const auto size = icon.actualSize (QSize (maxWidth, maxHeight));
        return icon.pixmap (size);
    } else {
        return QPixmap (hidpiFileName (logoBasePath + ".png"));
    }
#else
    const auto size = Theme.isHidpi () ? : 200 : 100;
    return applicationIcon ().pixmap (size);
#endif
}

QPixmap Theme.wizardHeaderLogo () {
#ifdef APPLICATION_WIZARD_USE_CUSTOM_LOGO
    const auto useSvg = shouldPreferSvg ();
    const string logoBasePath = string (Theme.themePrefix) + QStringLiteral ("colored/wizard_logo");
    if (useSvg) {
        const auto maxHeight = 64;
        const auto maxWidth = 2 * maxHeight;
        const auto icon = QIcon (logoBasePath + ".svg");
        const auto size = icon.actualSize (QSize (maxWidth, maxHeight));
        return icon.pixmap (size);
    } else {
        return QPixmap (hidpiFileName (logoBasePath + ".png"));
    }
#else
    return applicationIcon ().pixmap (64);
#endif
}

QPixmap Theme.wizardHeaderBanner () {
    QColor c = wizardHeaderBackgroundColor ();
    if (!c.isValid ())
        return QPixmap ();

    QSize size (750, 78);
    if (auto screen = qApp.primaryScreen ()) {
        // Adjust the the size if there is a different DPI. (Issue #6156)
        // Indeed, this size need to be big enough to for the banner height, and the wizard's width
        auto ratio = screen.logicalDotsPerInch () / 96.;
        if (ratio > 1.)
            size *= ratio;
    }
    QPixmap pix (size);
    pix.fill (wizardHeaderBackgroundColor ());
    return pix;
}
#endif

bool Theme.wizardSelectiveSyncDefaultNothing () {
    return false;
}

bool Theme.linkSharing () {
    return true;
}

bool Theme.userGroupSharing () {
    return true;
}

bool Theme.forceSystemNetworkProxy () {
    return false;
}

Theme.UserIDType Theme.userIDType () {
    return UserIDType.UserIDUserName;
}

string Theme.customUserID () {
    return string ();
}

string Theme.userIDHint () {
    return string ();
}

string Theme.wizardUrlPostfix () {
    return string ();
}

string Theme.wizardUrlHint () {
    return string ();
}

string Theme.quotaBaseFolder () {
    return QLatin1String ("/");
}

string Theme.oauthClientId () {
    return "xdXOt13JKxym1B1QcEncf2XDkLAexMBFwiT9j6EfhhHFJhs2KM9jbjTmf8JBXE69";
}

string Theme.oauthClientSecret () {
    return "UBntmLjC2yYCeHwsyj73Uwo9TAaecAetRwMw0xYcvNL9yRdLSUi0hUAHfvCHFeFh";
}

string Theme.versionSwitchOutput () {
    string helpText;
    QTextStream stream (&helpText);
    stream << appName ()
           << QLatin1String (" version ")
           << version () << Qt.endl;
#ifdef GIT_SHA1
    stream << "Git revision " << GIT_SHA1 << Qt.endl;
#endif
    stream << "Using Qt " << qVersion () << ", built against Qt " << QT_VERSION_STR << Qt.endl;

    if (!QGuiApplication.platformName ().isEmpty ())
        stream << "Using Qt platform plugin '" << QGuiApplication.platformName () << "'" << Qt.endl;

    stream << "Using '" << QSslSocket.sslLibraryVersionString () << "'" << Qt.endl;
    stream << "Running on " << Utility.platformName () << ", " << QSysInfo.currentCpuArchitecture () << Qt.endl;
    return helpText;
}

bool Theme.isDarkColor (QColor &color) {
    // account for different sensitivity of the human eye to certain colors
    double treshold = 1.0 - (0.299 * color.red () + 0.587 * color.green () + 0.114 * color.blue ()) / 255.0;
    return treshold > 0.5;
}

QColor Theme.getBackgroundAwareLinkColor (QColor &backgroundColor) {
    return { (isDarkColor (backgroundColor) ? QColor ("#6193dc") : QGuiApplication.palette ().color (QPalette.Link))};
}

QColor Theme.getBackgroundAwareLinkColor () {
    return getBackgroundAwareLinkColor (QGuiApplication.palette ().base ().color ());
}

void Theme.replaceLinkColorStringBackgroundAware (string &linkString, QColor &backgroundColor) {
    replaceLinkColorString (linkString, getBackgroundAwareLinkColor (backgroundColor));
}

void Theme.replaceLinkColorStringBackgroundAware (string &linkString) {
    replaceLinkColorStringBackgroundAware (linkString, QGuiApplication.palette ().color (QPalette.Base));
}

void Theme.replaceLinkColorString (string &linkString, QColor &newColor) {
    linkString.replace (QRegularExpression (" (<a href|<a style='color:# ([a-zA-Z0-9]{6});' href)"), string.fromLatin1 ("<a style='color:%1;' href").arg (newColor.name ()));
}

QIcon Theme.createColorAwareIcon (string &name, QPalette &palette) {
    QSvgRenderer renderer (name);
    QImage img (64, 64, QImage.Format_ARGB32);
    img.fill (Qt.GlobalColor.transparent);
    QPainter imgPainter (&img);
    QImage inverted (64, 64, QImage.Format_ARGB32);
    inverted.fill (Qt.GlobalColor.transparent);
    QPainter invPainter (&inverted);

    renderer.render (&imgPainter);
    renderer.render (&invPainter);

    inverted.invertPixels (QImage.InvertRgb);

    QIcon icon;
    if (Theme.isDarkColor (palette.color (QPalette.Base))) {
        icon.addPixmap (QPixmap.fromImage (inverted));
    } else {
        icon.addPixmap (QPixmap.fromImage (img));
    }
    if (Theme.isDarkColor (palette.color (QPalette.HighlightedText))) {
        icon.addPixmap (QPixmap.fromImage (img), QIcon.Normal, QIcon.On);
    } else {
        icon.addPixmap (QPixmap.fromImage (inverted), QIcon.Normal, QIcon.On);
    }
    return icon;
}

QIcon Theme.createColorAwareIcon (string &name) {
    return createColorAwareIcon (name, QGuiApplication.palette ());
}

QPixmap Theme.createColorAwarePixmap (string &name, QPalette &palette) {
    QImage img (name);
    QImage inverted (img);
    inverted.invertPixels (QImage.InvertRgb);

    QPixmap pixmap;
    if (Theme.isDarkColor (palette.color (QPalette.Base))) {
        pixmap = QPixmap.fromImage (inverted);
    } else {
        pixmap = QPixmap.fromImage (img);
    }
    return pixmap;
}

QPixmap Theme.createColorAwarePixmap (string &name) {
    return createColorAwarePixmap (name, QGuiApplication.palette ());
}

bool Theme.showVirtualFilesOption () {
    const auto vfsMode = bestAvailableVfsMode ();
    return ConfigFile ().showExperimentalOptions () || vfsMode == Vfs.WindowsCfApi;
}

bool Theme.enforceVirtualFilesSyncFolder () {
    const auto vfsMode = bestAvailableVfsMode ();
    return ENFORCE_VIRTUAL_FILES_SYNC_FOLDER && vfsMode != Occ.Vfs.Off;
}

QColor Theme.errorBoxTextColor () {
    return QColor{"white"};
}

QColor Theme.errorBoxBackgroundColor () {
    return QColor{"red"};
}

QColor Theme.errorBoxBorderColor () {
    return QColor{"black"};
}

} // end namespace client
