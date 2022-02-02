/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QTcpServer>

class HttpServer : QTcpServer {

    /***********************************************************
    ***********************************************************/
    public HttpServer (int16 port, GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void incomingConnection (int socket);

    /***********************************************************
    ***********************************************************/
    private void on_read_client ();
    private void on_discard_client ();
}














/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

HttpServer.HttpServer (uint16 port, GLib.Object parent)
    : QTcpServer (parent) {
    listen (QHostAddress.Any, port);
}

void HttpServer.on_read_client () {
    QTcpSocket* socket = (QTcpSocket*)sender ();
    if (socket.canReadLine ()) {
        string[] tokens = string (socket.readLine ()).split (QRegularExpression ("[ \r\n][ \r\n]*"));
        if (tokens[0] == "GET") {
            QTextStream os (socket);
            os.setAutoDetectUnicode (true);
            os << "HTTP/1.0 200 Ok\r\n"
                "Content-Type : text/html; charset=\"utf-8\"\r\n"
                "\r\n"
                "<h1>Nothing to see here</h1>\n"
                << GLib.DateTime.currentDateTimeUtc ().toString () << "\n";
            socket.close ();

            QtServiceBase.instance ().logMessage ("Wrote to client");

            if (socket.state () == QTcpSocket.UnconnectedState) {
                delete socket;
                QtServiceBase.instance ().logMessage ("Connection closed");
            }
        }
    }
}
void HttpServer.on_discard_client () {
    QTcpSocket* socket = (QTcpSocket*)sender ();
    socket.deleteLater ();

    QtServiceBase.instance ().logMessage ("Connection closed");
}

void HttpServer.incomingConnection (int socket) {
    if (disabled)
        return;
    QTcpSocket* s = new QTcpSocket (this);
    connect (s, SIGNAL (readyRead ()), this, SLOT (on_read_client ()));
    connect (s, SIGNAL (disconnected ()), this, SLOT (on_discard_client ()));
    s.setSocketDescriptor (socket);
}
