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


class Qt_singleCoreApplication : QCoreApplication {

    /***********************************************************
    ***********************************************************/
    public Qt_singleCoreApplication (int argc, char **argv);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string id ();

    /***********************************************************
    ***********************************************************/
    public 
    public void set_block (bool value);


    public bool on_send_message (string message, int timeout = 5000);

signals:
    void message_received (string message);


    /***********************************************************
    ***********************************************************/
    private QtLocalPeer* peer;
    private bool block;
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

namespace SharedTools {

    Qt_singleCoreApplication.Qt_singleCoreApplication (int argc, char **argv)
        : QCoreApplication (argc, argv) {
        peer = new QtLocalPeer (this);
        block = false;
        connect (peer, &QtLocalPeer.message_received, this, &Qt_singleCoreApplication.message_received);
    }

    Qt_singleCoreApplication.Qt_singleCoreApplication (string app_id, int argc, char **argv)
        : QCoreApplication (argc, argv) {
        peer = new QtLocalPeer (this, app_id);
        connect (peer, &QtLocalPeer.message_received, this, &Qt_singleCoreApplication.message_received);
    }

    bool Qt_singleCoreApplication.is_running () {
        return peer.is_client ();
    }

    bool Qt_singleCoreApplication.on_send_message (string message, int timeout) {
        return peer.on_send_message (message, timeout, block);
    }

    string Qt_singleCoreApplication.id () {
        return peer.application_id ();
    }

    void Qt_singleCoreApplication.set_block (bool value) {
        block = value;
    }

    } // namespace SharedTools
    