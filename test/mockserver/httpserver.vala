/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QTcpServer>

class HttpServer : QTcpServer {
     Q_OBJECT
 public:
    HttpServer (int16 port, GLib.Object* parent = nullptr);
    void incomingConnection (int socket);

 private slots:
     void readClient ();
     void discardClient ();
 };














 /***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

HttpServer.HttpServer (uint16 port, GLib.Object* parent)
    : QTcpServer (parent) {
    listen (QHostAddress.Any, port);
}

void HttpServer.readClient () {
    QTcpSocket* socket = (QTcpSocket*)sender ();
    if (socket.canReadLine ()) {
        QStringList tokens = string (socket.readLine ()).split (QRegularExpression ("[ \r\n][ \r\n]*"));
        if (tokens[0] == "GET") {
            QTextStream os (socket);
            os.setAutoDetectUnicode (true);
            os << "HTTP/1.0 200 Ok\r\n"
                "Content-Type : text/html; charset=\"utf-8\"\r\n"
                "\r\n"
                "<h1>Nothing to see here</h1>\n"
                << QDateTime.currentDateTimeUtc ().toString () << "\n";
            socket.close ();

            QtServiceBase.instance ().logMessage ("Wrote to client");

            if (socket.state () == QTcpSocket.UnconnectedState) {
                delete socket;
                QtServiceBase.instance ().logMessage ("Connection closed");
            }
        }
    }
}
void HttpServer.discardClient () {
    QTcpSocket* socket = (QTcpSocket*)sender ();
    socket.deleteLater ();

    QtServiceBase.instance ().logMessage ("Connection closed");
}

void HttpServer.incomingConnection (int socket) {
    if (disabled)
        return;
    QTcpSocket* s = new QTcpSocket (this);
    connect (s, SIGNAL (readyRead ()), this, SLOT (readClient ()));
    connect (s, SIGNAL (disconnected ()), this, SLOT (discardClient ()));
    s.setSocketDescriptor (socket);
}
