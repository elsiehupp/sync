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
