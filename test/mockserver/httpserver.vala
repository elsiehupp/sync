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
