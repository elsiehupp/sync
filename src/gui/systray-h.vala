/*
Copyright (C) by Cédric Bellegarde <gnumdk@gmail.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QSystemTrayIcon>

// #include <QQmlNetworkAccessManagerFactory>

class QQmlApplicationEngine;
class QWindow;

namespace Occ {

class AccessManagerFactory : QQmlNetworkAccessManagerFactory {
public:
    AccessManagerFactory ();

    QNetworkAccessManager* create (GLib.Object *parent) override;
};

#ifdef Q_OS_OSX
bool canOsXSendUserNotification ();
void sendOsXUserNotification (QString &title, QString &message);
void setTrayWindowLevelAndVisibleOnAllSpaces (QWindow *window);
#endif

/**
@brief The Systray class
@ingroup gui
*/
class Systray
   : QSystemTrayIcon {

    Q_PROPERTY (QString windowTitle READ windowTitle CONSTANT)
    Q_PROPERTY (bool useNormalWindow READ useNormalWindow CONSTANT)

public:
    static Systray *instance ();
    ~Systray () override = default;

    enum class TaskBarPosition { Bottom, Left, Top, Right };
    Q_ENUM (TaskBarPosition);

    void setTrayEngine (QQmlApplicationEngine *trayEngine);
    void create ();
    void showMessage (QString &title, QString &message, MessageIcon icon = Information);
    void setToolTip (QString &tip);
    bool isOpen ();
    QString windowTitle ();
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
    void openShareDialog (QString &sharePath, QString &localPath);
    void showFileActivityDialog (QString &sharePath, QString &localPath);

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

} // namespace Occ

#endif //SYSTRAY_H
