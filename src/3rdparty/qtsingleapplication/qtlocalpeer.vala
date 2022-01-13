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

// #include <QLocalServer>
// #include <QLocalSocket>
// #include <QDir>

namespace SharedTools {

class QtLocalPeer : GLib.Object {

public:
    QtLocalPeer (GLib.Object *parent = nullptr, string &appId = string ());
    bool isClient ();
    bool sendMessage (string &message, int timeout, bool block);
    string applicationId () { return id; }
    static string appSessionId (string &appId);

signals:
    void messageReceived (string &message, GLib.Object *socket);

protected slots:
    void receiveConnection ();

protected:
    string id;
    string socketName;
    QLocalServer* server;
    QtLockedFile lockFile;
};

} // namespace SharedTools
