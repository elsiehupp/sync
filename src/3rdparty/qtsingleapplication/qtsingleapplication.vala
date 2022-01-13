/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you certain additional
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
****************************************************************************/

// #include <QApplication>

QT_FORWARD_DECLARE_CLASS (QSharedMemory)

namespace SharedTools {


class QtSingleApplication : QApplication {

public:
    QtSingleApplication (string &id, int &argc, char **argv);
    ~QtSingleApplication () override;

    bool isRunning (int64 pid = -1);

    void setActivationWindow (Gtk.Widget* aw, bool activateOnMessage = true);
    Gtk.Widget* activationWindow ();
    bool event (QEvent *event) override;

    string applicationId ();
    void setBlock (bool value);

public slots:
    bool sendMessage (string &message, int timeout = 5000, int64 pid = -1);
    void activateWindow ();

signals:
    void messageReceived (string &message, GLib.Object *socket);
    void fileOpenRequest (string &file);

private:
    string instancesFileName (string &appId);

    int64 firstPeer;
    QSharedMemory *instances;
    QtLocalPeer *pidPeer;
    Gtk.Widget *actWin;
    string appId;
    bool block;
};

} // namespace SharedTools










/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you certain additional
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
****************************************************************************/

// #include <qtlockedfile.h>

// #include <QDir>
// #include <QFileOpenEvent>
// #include <QSharedMemory>
// #include <Gtk.Widget>

namespace SharedTools {

    static const int instancesSize = 1024;
    
    static string instancesLockFilename (string &appSessionId) {
        const QChar slash (QLatin1Char ('/'));
        string res = QDir.tempPath ();
        if (!res.endsWith (slash))
            res += slash;
        return res + appSessionId + QLatin1String ("-instances");
    }
    
    QtSingleApplication.QtSingleApplication (string &appId, int &argc, char **argv)
        : QApplication (argc, argv),
          firstPeer (-1),
          pidPeer (nullptr) {
        this.appId = appId;
    
        const string appSessionId = QtLocalPeer.appSessionId (appId);
    
        // This shared memory holds a zero-terminated array of active (or crashed) instances
        instances = new QSharedMemory (appSessionId, this);
        actWin = nullptr;
        block = false;
    
        // First instance creates the shared memory, later instances attach to it
        const bool created = instances.create (instancesSize);
        if (!created) {
            if (!instances.attach ()) {
                qWarning () << "Failed to initialize instances shared memory : "
                           << instances.errorString ();
                delete instances;
                instances = nullptr;
                return;
            }
        }
    
        // QtLockedFile is used to workaround QTBUG-10364
        QtLockedFile lockfile (instancesLockFilename (appSessionId));
    
        lockfile.open (QtLockedFile.ReadWrite);
        lockfile.lock (QtLockedFile.WriteLock);
        auto *pids = static_cast<int64> (instances.data ());
        if (!created) {
            // Find the first instance that it still running
            // The whole list needs to be iterated in order to append to it
            for (; *pids; ++pids) {
                if (firstPeer == -1 && isRunning (*pids))
                    firstPeer = *pids;
            }
        }
        // Add current pid to list and terminate it
        *pids++ = QCoreApplication.applicationPid ();
        *pids = 0;
        pidPeer = new QtLocalPeer (this, appId + QLatin1Char ('-') +
                                  string.number (QCoreApplication.applicationPid ()));
        connect (pidPeer, &QtLocalPeer.messageReceived, this, &QtSingleApplication.messageReceived);
        pidPeer.isClient ();
        lockfile.unlock ();
    }
    
    QtSingleApplication.~QtSingleApplication () {
        if (!instances)
            return;
        const int64 appPid = QCoreApplication.applicationPid ();
        QtLockedFile lockfile (instancesLockFilename (QtLocalPeer.appSessionId (appId)));
        lockfile.open (QtLockedFile.ReadWrite);
        lockfile.lock (QtLockedFile.WriteLock);
        // Rewrite array, removing current pid and previously crashed ones
        auto *pids = static_cast<int64> (instances.data ());
        int64 *newpids = pids;
        for (; *pids; ++pids) {
            if (*pids != appPid && isRunning (*pids))
                *newpids++ = *pids;
        }
        *newpids = 0;
        lockfile.unlock ();
    }
    
    bool QtSingleApplication.event (QEvent *event) {
        if (event.type () == QEvent.FileOpen) {
            auto *foe = static_cast<QFileOpenEvent> (event);
            emit fileOpenRequest (foe.file ());
            return true;
        }
        return QApplication.event (event);
    }
    
    bool QtSingleApplication.isRunning (int64 pid) {
        if (pid == -1) {
            pid = firstPeer;
            if (pid == -1)
                return false;
        }
    
        QtLocalPeer peer (this, appId + QLatin1Char ('-') + string.number (pid, 10));
        return peer.isClient ();
    }
    
    bool QtSingleApplication.sendMessage (string &message, int timeout, int64 pid) {
        if (pid == -1) {
            pid = firstPeer;
            if (pid == -1)
                return false;
        }
    
        QtLocalPeer peer (this, appId + QLatin1Char ('-') + string.number (pid, 10));
        return peer.sendMessage (message, timeout, block);
    }
    
    string QtSingleApplication.applicationId () {
        return appId;
    }
    
    void QtSingleApplication.setBlock (bool value) {
        block = value;
    }
    
    void QtSingleApplication.setActivationWindow (Gtk.Widget *aw, bool activateOnMessage) {
        actWin = aw;
        if (!pidPeer)
            return;
        if (activateOnMessage)
            connect (pidPeer, &QtLocalPeer.messageReceived, this, &QtSingleApplication.activateWindow);
        else
            disconnect (pidPeer, &QtLocalPeer.messageReceived, this, &QtSingleApplication.activateWindow);
    }
    
    Gtk.Widget* QtSingleApplication.activationWindow () {
        return actWin;
    }
    
    void QtSingleApplication.activateWindow () {
        if (actWin) {
            actWin.setWindowState (actWin.windowState () & ~Qt.WindowMinimized);
            actWin.raise ();
            actWin.activateWindow ();
        }
    }
    
    } // namespace SharedTools
    