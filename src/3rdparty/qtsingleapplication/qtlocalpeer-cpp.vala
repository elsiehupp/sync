/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you certain additional
rights.  These rights are described in the Digia Qt LGPL Exception
version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
****************************************************************************/

// #include <QCoreApplication>
// #include <QDataStream>
// #include <QTime>

#if defined (Q_OS_UNIX)
// #include <ctime>
// #include <unistd.h>
#endif

namespace SharedTools {

static const char ack[] = "ack";

string QtLocalPeer.appSessionId (string &appId) {
    QByteArray idc = appId.toUtf8 ();
    uint16 idNum = qChecksum (idc.constData (), idc.size ());
    //### could do : two 16bit checksums over separate halves of id, for a 32bit result - improved uniqeness probability. Every-other-char split would be best.

    string res = QLatin1String ("qtsingleapplication-")
                 + string.number (idNum, 16);
    res += QLatin1Char ('-') + string.number (.getuid (), 16);
    return res;
}

QtLocalPeer.QtLocalPeer (GLib.Object *parent, string &appId)
    : GLib.Object (parent), id (appId) {
    if (id.isEmpty ())
        id = QCoreApplication.applicationFilePath ();  //### On win, check if this returns .../argv[0] without casefolding; .\MYAPP == .\myapp on Win

    socketName = appSessionId (id);
    server = new QLocalServer (this);
    string lockName = QDir (QDir.tempPath ()).absolutePath ()
                       + QLatin1Char ('/') + socketName
                       + QLatin1String ("-lockfile");
    lockFile.setFileName (lockName);
    lockFile.open (QIODevice.ReadWrite);
}

bool QtLocalPeer.isClient () {
    if (lockFile.isLocked ())
        return false;

    if (!lockFile.lock (QtLockedFile.WriteLock, false))
        return true;

    if (!QLocalServer.removeServer (socketName))
        qWarning ("QtSingleCoreApplication : could not cleanup socket");
    bool res = server.listen (socketName);
    if (!res)
        qWarning ("QtSingleCoreApplication : listen on local socket failed, %s", qPrintable (server.errorString ()));
    GLib.Object.connect (server, &QLocalServer.newConnection, this, &QtLocalPeer.receiveConnection);
    return false;
}

bool QtLocalPeer.sendMessage (string &message, int timeout, bool block) {
    if (!isClient ())
        return false;

    QLocalSocket socket;
    bool connOk = false;
    for (int i = 0; i < 2; i++) {
        // Try twice, in case the other instance is just starting up
        socket.connectToServer (socketName);
        connOk = socket.waitForConnected (timeout/2);
        if (connOk || i)
            break;
        int ms = 250;
        struct timespec ts = { ms / 1000, (ms % 1000) * 1000 * 1000 };
        nanosleep (&ts, nullptr);
    }
    if (!connOk)
        return false;

    QByteArray uMsg (message.toUtf8 ());
    QDataStream ds (&socket);
    ds.writeBytes (uMsg.constData (), uMsg.size ());
    bool res = socket.waitForBytesWritten (timeout);
    res &= socket.waitForReadyRead (timeout); // wait for ack
    res &= (socket.read (qstrlen (ack)) == ack);
    if (block) // block until peer disconnects
        socket.waitForDisconnected (-1);
    return res;
}

void QtLocalPeer.receiveConnection () {
    QLocalSocket* socket = server.nextPendingConnection ();
    if (!socket)
        return;

    // Why doesn't Qt have a blocking stream that takes care of this shait???
    while (socket.bytesAvailable () < static_cast<int> (sizeof (uint32))) {
        if (!socket.isValid ()) // stale request
            return;
        socket.waitForReadyRead (1000);
    }
    QDataStream ds (socket);
    QByteArray uMsg;
    uint32 remaining = 0;
    ds >> remaining;
    uMsg.resize (remaining);
    int got = 0;
    char* uMsgBuf = uMsg.data ();
    //qDebug () << "RCV : remaining" << remaining;
    do {
        got = ds.readRawData (uMsgBuf, remaining);
        remaining -= got;
        uMsgBuf += got;
        //qDebug () << "RCV : got" << got << "remaining" << remaining;
    } while (remaining && got >= 0 && socket.waitForReadyRead (2000));
    //### error check : got<0
    if (got < 0) {
        qWarning () << "QtLocalPeer : Message reception failed" << socket.errorString ();
        delete socket;
        return;
    }
    // ### async this
    string message = string.fromUtf8 (uMsg.constData (), uMsg.size ());
    socket.write (ack, qstrlen (ack));
    socket.waitForBytesWritten (1000);
    emit messageReceived (message, socket); // ## (might take a long time to return)
}

} // namespace SharedTools
