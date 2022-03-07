/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QTcpServer>

namespace Testing {

class HttpServer : QTcpServer {

    /***********************************************************
    ***********************************************************/
    public HttpServer (int16 port, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        listen (QHostAddress.Any, port);
    }

    /***********************************************************
    ***********************************************************/
    public void incoming_connection (int socket) {
        if (disabled)
            return;
        QTcpSocket* s = new QTcpSocket (this);
        connect (s, SIGNAL (signal_ready_read ()), this, SLOT (on_signal_read_client ()));
        connect (s, SIGNAL (disconnected ()), this, SLOT (on_signal_discard_client ()));
        s.setSocketDescriptor (socket);
    }

    /***********************************************************
    ***********************************************************/
    private void on_signal_read_client () {
        QTcpSocket* socket = (QTcpSocket*)sender ();
        if (socket.canReadLine ()) {
            string[] tokens = string (socket.readLine ()).split (QRegularExpression ("[ \r\n][ \r\n]*"));
            if (tokens[0] == "GET") {
                QTextStream os = new QTextStream (socket);
                os.setAutoDetectUnicode (true);
                os += "HTTP/1.0 200 Ok\r\n"
                    + "Content-Type : text/html; charset=\"utf-8\"\r\n"
                    + "\r\n"
                    + "<h1>Nothing to see here</h1>\n"
                    + GLib.DateTime.currentDateTimeUtc ().toString ("\n");
                socket.close ();

                QtServiceBase.instance ().logMessage ("Wrote to client");

                if (socket.state () == QTcpSocket.UnconnectedState) {
                    delete socket;
                    QtServiceBase.instance ().logMessage ("Connection closed");
                }
            }
        }
    }


    private void on_signal_discard_client () {
        QTcpSocket* socket = (QTcpSocket*)sender ();
        socket.deleteLater ();

        QtServiceBase.instance ().logMessage ("Connection closed");
    }

}
}
