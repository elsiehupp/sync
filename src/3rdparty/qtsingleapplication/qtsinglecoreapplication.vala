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

namespace SharedTools {


class QtSingleCoreApplication : QCoreApplication {

public:
    QtSingleCoreApplication (int &argc, char **argv);
    QtSingleCoreApplication (string &id, int &argc, char **argv);

    bool isRunning ();
    string id ();
    void setBlock (bool value);

public slots:
    bool sendMessage (string &message, int timeout = 5000);

signals:
    void messageReceived (string &message);

private:
    QtLocalPeer* peer;
    bool block;
};

} // namespace SharedTools
