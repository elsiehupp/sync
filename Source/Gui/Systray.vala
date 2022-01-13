/***********************************************************
Copyright (C) by Cédric Bellegarde <gnumdk@gmail.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QCursor>
// #include <QGuiApplication>
// #include <QQmlApplicationEngine>
// #include <QQmlContext>
// #include <QQuickWindow>
// #include <QScreen>
// #include <QMenu>

#ifdef USE_FDO_NOTIFICATIONS
// #include <QDBusConnection>
// #include <QDBusInterface>
// #include <QDBusMessage>
// #include <QDBusPendingCall>
const int NOTIFICATIONS_SERVICE "org.freedesktop.Notifications"
const int NOTIFICATIONS_PATH "/org/freedesktop/Notifications"
const int NOTIFICATIONS_IFACE "org.freedesktop.Notifications"
#endif

// #include <QSystemTrayIcon>

// #include <QQmlNetworkAccessManagerFactory>

class QWindow;

namespace Occ {

class AccessManagerFactory : QQmlNetworkAccessManagerFactory {
public:
    AccessManagerFactory ();

    QNetworkAccessManager* create (GLib.Object *parent) override;
};

#ifdef Q_OS_OSX
bool canOsXSendUserNotification ();
void sendOsXUserNotification (string &title, string &message);
void setTrayWindowLevelAndVisibleOnAllSpaces (QWindow *window);
#endif

/***********************************************************
@brief The Systray class
@ingroup gui
***********************************************************/
class Systray
   : QSystemTrayIcon {

    Q_PROPERTY (string windowTitle READ windowTitle CONSTANT)
    Q_PROPERTY (bool useNormalWindow READ useNormalWindow CONSTANT)

public:
    static Systray *instance ();
    ~Systray () override = default;

    enum class TaskBarPosition { Bottom, Left, Top, Right };
    Q_ENUM (TaskBarPosition);

    void setTrayEngine (QQmlApplicationEngine *trayEngine);
    void create ();
    void showMessage (string &title, string &message, MessageIcon icon = Information);
    void setToolTip (string &tip);
    bool isOpen ();
    string windowTitle ();
    bool useNormalWindow ();

    Q_INVOKABLE void pauseResumeSync ();
    Q_INVOKABLE bool syncIsPaused ();
    Q_INVOKABLE void setOpened ();
    Q_INVOKABLE void setClosed ();
    Q_INVOKABLE void positionWindow (QQuickWindow *window) const;
    Q_INVOKABLE void forceWindowInit (QQuickWindow *window) const;

signals:
    void currentUserChanged ();
    void openAccountWizard ();
    void openMainDialog ();
    void openSettings ();
    void openHelp ();
    void shutdown ();

    void hideWindow ();
    void showWindow ();
    void openShareDialog (string &sharePath, string &localPath);
    void showFileActivityDialog (string &sharePath, string &localPath);

public slots:
    void slotNewUserSelected ();

private slots:
    void slotUnpauseAllFolders ();
    void slotPauseAllFolders ();

private:
    void setPauseOnAllFoldersHelper (bool pause);

    static Systray *_instance;
    Systray ();

    QScreen *currentScreen ();
    QRect currentScreenRect ();
    QPoint computeWindowReferencePoint ();
    QPoint calcTrayIconCenter ();
    TaskBarPosition taskbarOrientation ();
    QRect taskbarGeometry ();
    QPoint computeWindowPosition (int width, int height) const;

    bool _isOpen = false;
    bool _syncIsPaused = true;
    QPointer<QQmlApplicationEngine> _trayEngine;

    AccessManagerFactory _accessManagerFactory;
};


Systray *Systray._instance = nullptr;

Systray *Systray.instance () {
    if (!_instance) {
        _instance = new Systray ();
    }
    return _instance;
}

void Systray.setTrayEngine (QQmlApplicationEngine *trayEngine) {
    _trayEngine = trayEngine;

    _trayEngine.setNetworkAccessManagerFactory (&_accessManagerFactory);

    _trayEngine.addImportPath ("qrc:/qml/theme");
    _trayEngine.addImageProvider ("avatars", new ImageProvider);
    _trayEngine.addImageProvider (QLatin1String ("svgimage-custom-color"), new Occ.Ui.SvgImageProvider);
    _trayEngine.addImageProvider (QLatin1String ("unified-search-result-icon"), new UnifiedSearchResultImageProvider);
}

Systray.Systray ()
    : QSystemTrayIcon (nullptr) {
    qmlRegisterSingletonType<UserModel> ("com.nextcloud.desktopclient", 1, 0, "UserModel",
        [] (QQmlEngine *, QJSEngine *) . GLib.Object * {
            return UserModel.instance ();
        }
    );

    qmlRegisterSingletonType<UserAppsModel> ("com.nextcloud.desktopclient", 1, 0, "UserAppsModel",
        [] (QQmlEngine *, QJSEngine *) . GLib.Object * {
            return UserAppsModel.instance ();
        }
    );

    qmlRegisterSingletonType<Systray> ("com.nextcloud.desktopclient", 1, 0, "Theme",
        [] (QQmlEngine *, QJSEngine *) . GLib.Object * {
            return Theme.instance ();
        }
    );

    qmlRegisterSingletonType<Systray> ("com.nextcloud.desktopclient", 1, 0, "Systray",
        [] (QQmlEngine *, QJSEngine *) . GLib.Object * {
            return Systray.instance ();
        }
    );

    qmlRegisterType<WheelHandler> ("com.nextcloud.desktopclient", 1, 0, "WheelHandler");

    auto contextMenu = new QMenu ();
    if (AccountManager.instance ().accounts ().isEmpty ()) {
        contextMenu.addAction (tr ("Add account"), this, &Systray.openAccountWizard);
    } else {
        contextMenu.addAction (tr ("Open main dialog"), this, &Systray.openMainDialog);
    }

    auto pauseAction = contextMenu.addAction (tr ("Pause sync"), this, &Systray.slotPauseAllFolders);
    auto resumeAction = contextMenu.addAction (tr ("Resume sync"), this, &Systray.slotUnpauseAllFolders);
    contextMenu.addAction (tr ("Settings"), this, &Systray.openSettings);
    contextMenu.addAction (tr ("Exit %1").arg (Theme.instance ().appNameGUI ()), this, &Systray.shutdown);
    setContextMenu (contextMenu);

    connect (contextMenu, &QMenu.aboutToShow, [=] {
        const auto folders = FolderMan.instance ().map ();

        const auto allPaused = std.all_of (std.cbegin (folders), std.cend (folders), [] (Folder *f) { return f.syncPaused (); });
        const auto pauseText = folders.size () > 1 ? tr ("Pause sync for all") : tr ("Pause sync");
        pauseAction.setText (pauseText);
        pauseAction.setVisible (!allPaused);
        pauseAction.setEnabled (!allPaused);

        const auto anyPaused = std.any_of (std.cbegin (folders), std.cend (folders), [] (Folder *f) { return f.syncPaused (); });
        const auto resumeText = folders.size () > 1 ? tr ("Resume sync for all") : tr ("Resume sync");
        resumeAction.setText (resumeText);
        resumeAction.setVisible (anyPaused);
        resumeAction.setEnabled (anyPaused);
    });

    connect (UserModel.instance (), &UserModel.newUserSelected,
        this, &Systray.slotNewUserSelected);
    connect (UserModel.instance (), &UserModel.addAccount,
            this, &Systray.openAccountWizard);

    connect (AccountManager.instance (), &AccountManager.accountAdded,
        this, &Systray.showWindow);
}

void Systray.create () {
    if (_trayEngine) {
        if (!AccountManager.instance ().accounts ().isEmpty ()) {
            _trayEngine.rootContext ().setContextProperty ("activityModel", UserModel.instance ().currentActivityModel ());
        }
        _trayEngine.load (QStringLiteral ("qrc:/qml/src/gui/tray/Window.qml"));
    }
    hideWindow ();
    emit activated (QSystemTrayIcon.ActivationReason.Unknown);

    const auto folderMap = FolderMan.instance ().map ();
    for (auto *folder : folderMap) {
        if (!folder.syncPaused ()) {
            _syncIsPaused = false;
            break;
        }
    }
}

void Systray.slotNewUserSelected () {
    if (_trayEngine) {
        // Change ActivityModel
        _trayEngine.rootContext ().setContextProperty ("activityModel", UserModel.instance ().currentActivityModel ());
    }

    // Rebuild App list
    UserAppsModel.instance ().buildAppList ();
}

void Systray.slotUnpauseAllFolders () {
    setPauseOnAllFoldersHelper (false);
}

void Systray.slotPauseAllFolders () {
    setPauseOnAllFoldersHelper (true);
}

void Systray.setPauseOnAllFoldersHelper (bool pause) {
    // For some reason we get the raw pointer from Folder.accountState ()
    // that's why we need a list of raw pointers for the call to contains
    // later on...
    const auto accounts = [=] {
        const auto ptrList = AccountManager.instance ().accounts ();
        auto result = QList<AccountState> ();
        result.reserve (ptrList.size ());
        std.transform (std.cbegin (ptrList), std.cend (ptrList), std.back_inserter (result), [] (AccountStatePtr &account) {
            return account.data ();
        });
        return result;
    } ();
    const auto folders = FolderMan.instance ().map ();
    for (auto f : folders) {
        if (accounts.contains (f.accountState ())) {
            f.setSyncPaused (pause);
            if (pause) {
                f.slotTerminateSync ();
            }
        }
    }
}

bool Systray.isOpen () {
    return _isOpen;
}

string Systray.windowTitle () {
    return Theme.instance ().appNameGUI ();
}

bool Systray.useNormalWindow () {
    if (!isSystemTrayAvailable ()) {
        return true;
    }

    ConfigFile cfg;
    return cfg.showMainDialogAsNormalWindow ();
}

Q_INVOKABLE void Systray.setOpened () {
    _isOpen = true;
}

Q_INVOKABLE void Systray.setClosed () {
    _isOpen = false;
}

void Systray.showMessage (string &title, string &message, MessageIcon icon) {
#ifdef USE_FDO_NOTIFICATIONS
    if (QDBusInterface (NOTIFICATIONS_SERVICE, NOTIFICATIONS_PATH, NOTIFICATIONS_IFACE).isValid ()) {
        const QVariantMap hints = {{QStringLiteral ("desktop-entry"), LINUX_APPLICATION_ID}};
        QList<QVariant> args = QList<QVariant> () << APPLICATION_NAME << uint32 (0) << APPLICATION_ICON_NAME
                                                 << title << message << QStringList () << hints << int32 (-1);
        QDBusMessage method = QDBusMessage.createMethodCall (NOTIFICATIONS_SERVICE, NOTIFICATIONS_PATH, NOTIFICATIONS_IFACE, "Notify");
        method.setArguments (args);
        QDBusConnection.sessionBus ().asyncCall (method);
    } else
#endif
#ifdef Q_OS_OSX
        if (canOsXSendUserNotification ()) {
        sendOsXUserNotification (title, message);
    } else
#endif {
        QSystemTrayIcon.showMessage (title, message, icon);
    }
}

void Systray.setToolTip (string &tip) {
    QSystemTrayIcon.setToolTip (tr ("%1 : %2").arg (Theme.instance ().appNameGUI (), tip));
}

bool Systray.syncIsPaused () {
    return _syncIsPaused;
}

void Systray.pauseResumeSync () {
    if (_syncIsPaused) {
        _syncIsPaused = false;
        slotUnpauseAllFolders ();
    } else {
        _syncIsPaused = true;
        slotPauseAllFolders ();
    }
}

/***************************************************************************/
/* Helper functions for cross-platform tray icon position and taskbar orientation detection */
/***************************************************************************/

void Systray.positionWindow (QQuickWindow *window) {
    if (!useNormalWindow ()) {
        window.setScreen (currentScreen ());
        const auto position = computeWindowPosition (window.width (), window.height ());
        window.setPosition (position);
    }
}

void Systray.forceWindowInit (QQuickWindow *window) {
    // HACK : At least on Windows, if the systray window is not shown at least once
    // it can prevent session handling to carry on properly, so we show/hide it here
    // this shouldn't flicker
    window.show ();
    window.hide ();
}

QScreen *Systray.currentScreen () {
    const auto screens = QGuiApplication.screens ();
    const auto cursorPos = QCursor.pos ();

    for (auto screen : screens) {
        if (screen.geometry ().contains (cursorPos)) {
            return screen;
        }
    }

    // Didn't find anything matching the cursor position,
    // falling back to the primary screen
    return QGuiApplication.primaryScreen ();
}

Systray.TaskBarPosition Systray.taskbarOrientation () {
    const auto screenRect = currentScreenRect ();
    const auto trayIconCenter = calcTrayIconCenter ();

    const auto distBottom = screenRect.bottom () - trayIconCenter.y ();
    const auto distRight = screenRect.right () - trayIconCenter.x ();
    const auto distLeft = trayIconCenter.x () - screenRect.left ();
    const auto distTop = trayIconCenter.y () - screenRect.top ();

    const auto minDist = std.min ({distRight, distTop, distBottom});

    if (minDist == distBottom) {
        return TaskBarPosition.Bottom;
    } else if (minDist == distLeft) {
        return TaskBarPosition.Left;
    } else if (minDist == distTop) {
        return TaskBarPosition.Top;
    } else {
        return TaskBarPosition.Right;
    }
}

// TODO : Get real taskbar dimensions Linux as well
QRect Systray.taskbarGeometry () {
    if (taskbarOrientation () == TaskBarPosition.Bottom || taskbarOrientation () == TaskBarPosition.Top) {
        auto screenWidth = currentScreenRect ().width ();
        return {0, 0, screenWidth, 32};
    } else {
        auto screenHeight = currentScreenRect ().height ();
        return {0, 0, 32, screenHeight};
    }
}

QRect Systray.currentScreenRect () {
    const auto screen = currentScreen ();
    Q_ASSERT (screen);
    return screen.geometry ();
}

QPoint Systray.computeWindowReferencePoint () {
    constexpr auto spacing = 4;
    const auto trayIconCenter = calcTrayIconCenter ();
    const auto taskbarRect = taskbarGeometry ();
    const auto taskbarScreenEdge = taskbarOrientation ();
    const auto screenRect = currentScreenRect ();

    qCDebug (lcSystray) << "screenRect:" << screenRect;
    qCDebug (lcSystray) << "taskbarRect:" << taskbarRect;
    qCDebug (lcSystray) << "taskbarScreenEdge:" << taskbarScreenEdge;
    qCDebug (lcSystray) << "trayIconCenter:" << trayIconCenter;

    switch (taskbarScreenEdge) {
    case TaskBarPosition.Bottom:
        return {
            trayIconCenter.x (),
            screenRect.bottom () - taskbarRect.height () - spacing
        };
    case TaskBarPosition.Left:
        return {
            screenRect.left () + taskbarRect.width () + spacing,
            trayIconCenter.y ()
        };
    case TaskBarPosition.Top:
        return {
            trayIconCenter.x (),
            screenRect.top () + taskbarRect.height () + spacing
        };
    case TaskBarPosition.Right:
        return {
            screenRect.right () - taskbarRect.width () - spacing,
            trayIconCenter.y ()
        };
    }
    Q_UNREACHABLE ();
}

QPoint Systray.computeWindowPosition (int width, int height) {
    const auto referencePoint = computeWindowReferencePoint ();

    const auto taskbarScreenEdge = taskbarOrientation ();
    const auto screenRect = currentScreenRect ();

    const auto topLeft = [=] () {
        switch (taskbarScreenEdge) {
        case TaskBarPosition.Bottom:
            return referencePoint - QPoint (width / 2, height);
        case TaskBarPosition.Left:
            return referencePoint;
        case TaskBarPosition.Top:
            return referencePoint - QPoint (width / 2, 0);
        case TaskBarPosition.Right:
            return referencePoint - QPoint (width, 0);
        }
        Q_UNREACHABLE ();
    } ();
    const auto bottomRight = topLeft + QPoint (width, height);
    const auto windowRect = [=] () {
        const auto rect = QRect (topLeft, bottomRight);
        auto offset = QPoint ();

        if (rect.left () < screenRect.left ()) {
            offset.setX (screenRect.left () - rect.left () + 4);
        } else if (rect.right () > screenRect.right ()) {
            offset.setX (screenRect.right () - rect.right () - 4);
        }

        if (rect.top () < screenRect.top ()) {
            offset.setY (screenRect.top () - rect.top () + 4);
        } else if (rect.bottom () > screenRect.bottom ()) {
            offset.setY (screenRect.bottom () - rect.bottom () - 4);
        }

        return rect.translated (offset);
    } ();

    qCDebug (lcSystray) << "taskbarScreenEdge:" << taskbarScreenEdge;
    qCDebug (lcSystray) << "screenRect:" << screenRect;
    qCDebug (lcSystray) << "windowRect (reference)" << QRect (topLeft, bottomRight);
    qCDebug (lcSystray) << "windowRect (adjusted)" << windowRect;

    return windowRect.topLeft ();
}

QPoint Systray.calcTrayIconCenter () {
    // On Linux, fall back to mouse position (assuming tray icon is activated by mouse click)
    return QCursor.pos (currentScreen ());
}

AccessManagerFactory.AccessManagerFactory ()
    : QQmlNetworkAccessManagerFactory () {
}

QNetworkAccessManager* AccessManagerFactory.create (GLib.Object *parent) {
    return new AccessManager (parent);
}

} // namespace Occ
