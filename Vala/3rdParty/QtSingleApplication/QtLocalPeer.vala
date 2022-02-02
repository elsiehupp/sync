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

// #include <QLocal_server>
// #include <QLocal_socket>
// #include <QDir>

namespace SharedTools {

class QtLocalPeer : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public QtLocalPeer (GLib.Object parent = new GLib.Object (), string app_id = "");

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool on_send_message (string message, int timeout, bool block);


    public string application_id () {
        return id;
    }


    /***********************************************************
    ***********************************************************/
    public static string app_session_id (string app_id);

signals:
    void message_received (string message, GLib.Object socket);

protected slots:
    void receive_connection ();


    protected string id;
    protected string socket_name;
    protected QLocal_server* server;
    protected QtLockedFile lock_file;
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

// #include <QCoreApplication>
// #include <QDataStream>
// #include <QTime>

#if defined (Q_OS_UNIX)
// #include <ctime>
// #include <unistd.h>
#endif

namespace SharedTools {

static const char ack[] = "ack";

string QtLocalPeer.app_session_id (string app_id) {
    GLib.ByteArray idc = app_id.to_utf8 ();
    uint16 id_num = q_checksum (idc.const_data (), idc.size ());
    //### could do : two 16bit checksums over separate halves of id, for a 32bit result - improved uniqeness probability. Every-other-char split would be best.

    string res = "qtsingleapplication-" + string.number (id_num, 16);
    res += '-' + string.number (.getuid (), 16);
    return res;
}

QtLocalPeer.QtLocalPeer (GLib.Object parent, string app_id)
    : GLib.Object (parent), id (app_id) {
    if (id.is_empty ())
        id = QCoreApplication.application_file_path ();  //### On win, check if this returns .../argv[0] without casefolding; .\MYAPP == .\myapp on Win

    socket_name = app_session_id (id);
    server = new QLocal_server (this);
    string lock_name = QDir (QDir.temp_path ()).absolute_path ()
                       + '/' + socket_name
                       + "-lockfile";
    lock_file.set_filename (lock_name);
    lock_file.open (QIODevice.ReadWrite);
}

bool QtLocalPeer.is_client () {
    if (lock_file.is_locked ())
        return false;

    if (!lock_file.lock (QtLockedFile.LockMode.WRITE_LOCK, false))
        return true;

    if (!QLocal_server.remove_server (socket_name))
        q_warning ("Qt_singleCoreApplication : could not on_cleanup socket");
    bool res = server.listen (socket_name);
    if (!res)
        q_warning ("Qt_singleCoreApplication : listen on local socket failed, %s", q_printable (server.error_string ()));
    GLib.Object.connect (server, &QLocal_server.new_connection, this, &QtLocalPeer.receive_connection);
    return false;
}

bool QtLocalPeer.on_send_message (string message, int timeout, bool block) {
    if (!is_client ())
        return false;

    QLocal_socket socket;
    bool conn_ok = false;
    for (int i = 0; i < 2; i++) {
        // Try twice, in case the other instance is just starting up
        socket.connect_to_server (socket_name);
        conn_ok = socket.wait_for_connected (timeout/2);
        if (conn_ok || i)
            break;
        int ms = 250;
        struct timespec ts = {
            ms / 1000, (ms % 1000) * 1000 * 1000
        };
        nanosleep (&ts, nullptr);
    }
    if (!conn_ok)
        return false;

    GLib.ByteArray u_msg (message.to_utf8 ());
    QDataStream ds (&socket);
    ds.write_bytes (u_msg.const_data (), u_msg.size ());
    bool res = socket.wait_for_bytes_written (timeout);
    res &= socket.wait_for_ready_read (timeout); // wait for ack
    res &= (socket.read (qstrlen (ack)) == ack);
    if (block) // block until peer disconnects
        socket.wait_for_disconnected (-1);
    return res;
}

void QtLocalPeer.receive_connection () {
    QLocal_socket* socket = server.next_pending_connection ();
    if (!socket)
        return;

    // Why doesn't Qt have a blocking stream that takes care of this shait???
    while (socket.bytes_available () < static_cast<int> (sizeof (uint32))) {
        if (!socket.is_valid ()) // stale request
            return;
        socket.wait_for_ready_read (1000);
    }
    QDataStream ds (socket);
    GLib.ByteArray u_msg;
    uint32 remaining = 0;
    ds >> remaining;
    u_msg.resize (remaining);
    int got = 0;
    char* u_msg_buf = u_msg.data ();
    //q_debug () << "RCV : remaining" << remaining;
    do {
        got = ds.read_raw_data (u_msg_buf, remaining);
        remaining -= got;
        u_msg_buf += got;
        //q_debug () << "RCV : got" << got << "remaining" << remaining;
    } while (remaining && got >= 0 && socket.wait_for_ready_read (2000));
    //### error check : got<0
    if (got < 0) {
        q_warning () << "QtLocalPeer : Message reception failed" << socket.error_string ();
        delete socket;
        return;
    }
    // ### async this
    string message = string.from_utf8 (u_msg.const_data (), u_msg.size ());
    socket.write (ack, qstrlen (ack));
    socket.wait_for_bytes_written (1000);
    /* emit */ message_received (message, socket); // ## (might take a long time to return)
}

} // namespace SharedTools
