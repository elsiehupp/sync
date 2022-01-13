/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QCoreApplication>

int main (int argc, char* argv[]) {
  QCoreApplication app (argc, argv);
  HttpServer server;
  return app.exec ();
}
