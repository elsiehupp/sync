/***********************************************************
Copyright (C) 2014 Digia Plc and/or its subsidiary (-ies).
Contact : http://www.qt-project.org/legal

This file is part of Qt Creator.

<LGPLv2.1-or-later-Boilerplate>

In addition, as a special exception, Digia gives you
certain additional rights.  These rights are described in
the Digia Qt LGPL Exception version 1.1, included in the
file LGPL_EXCEPTION.txt in this package.
***********************************************************/

//  #include <Gtk.Application>

namespace SharedTools {

public class QtSingleCoreApplication : Gtk.Application {

    /***********************************************************
    ***********************************************************/
    private QtLocalPeer peer;
    private bool block;


    internal signal void signal_message_received (string message);


    /***********************************************************
    ***********************************************************/
    public QtSingleCoreApplication (int argc, char **argv) {
        base (argc, argv);
        peer = new QtLocalPeer (this);
        block = false;
        peer.signal_message_received.connect (
            this.signal_message_received);
    }


    /***********************************************************
    ***********************************************************/
    public QtSingleCoreApplication (string app_id, int argc, char **argv) {
        base (argc, argv);
        peer = new QtLocalPeer (this, app_id);
        peer.signal_message_received.connect (
            this.signal_message_received
        );
    }

    /***********************************************************
    ***********************************************************/
    public bool is_running () {
        return peer.is_client ();
    }

    /***********************************************************
    ***********************************************************/
    public string identifier () {
        return peer.application_id ();
    }

    /***********************************************************
    ***********************************************************/
    public void set_block (bool value) {
        block = value;
    }

    /***********************************************************
    ***********************************************************/
    public bool on_send_message (string message, int timeout = 5000) {
        return peer.on_send_message (message, timeout, block);
    }

} // class QtSingleCoreApplication

} // namespace SharedTools
    