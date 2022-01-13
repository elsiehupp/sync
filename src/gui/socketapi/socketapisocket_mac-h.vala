/*
Copyright (C) by Jocelyn Turcotte <jturcotte@woboq.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QAbstractSocket>
// #include <QIODevice>

class SocketApiSocketPrivate;

class SocketApiSocket : QIODevice {
public:
    SocketApiSocket (GLib.Object *parent, SocketApiSocketPrivate *p);
    ~SocketApiSocket ();

    int64 readData (char *data, int64 maxlen) override;
    int64 writeData (char *data, int64 len) override;

    bool isSequential () const override { return true; }
    int64 bytesAvailable () const override;
    bool canReadLine () const override;

signals:
    void disconnected ();

private:
    // Use Qt's p-impl system to hide objective-c types from C++ code including this file
    Q_DECLARE_PRIVATE (SocketApiSocket)
    QScopedPointer<SocketApiSocketPrivate> d_ptr;
    friend class SocketApiServerPrivate;
};

class SocketApiServer : GLib.Object {
public:
    SocketApiServer ();
    ~SocketApiServer ();

    void close ();
    bool listen (QString &name);
    SocketApiSocket *nextPendingConnection ();

    static bool removeServer (QString &) { return false; }

signals:
    void newConnection ();

private:
    Q_DECLARE_PRIVATE (SocketApiServer)
    QScopedPointer<SocketApiServerPrivate> d_ptr;
};
