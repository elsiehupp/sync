namespace SharedTools {

/***********************************************************
@class class QtSingleCoreApplication

@author 2014 Digia Plc and/or its subsidiary (-ies).

This file is part of Qt Creator.

@copyright LGPLv2.1 or later
***********************************************************/
public class QtSingleCoreApplication { //: GLib.Application {

//    /***********************************************************
//    ***********************************************************/
//    private QtLocalPeer peer;
//    public bool block { private get; public set; }


//    internal signal void signal_message_received (string message);


//    /***********************************************************
//    ***********************************************************/
//    public QtSingleCoreApplication (int argc, char **argv) {
//        base (argc, argv);
//        peer = new QtLocalPeer (this);
//        this.block = false;
//        peer.signal_message_received.connect (
//            this.signal_message_received);
//    }


//    /***********************************************************
//    ***********************************************************/
//    public QtSingleCoreApplication.with_app_id (string app_id, int argc, char **argv) {
//        base (argc, argv);
//        peer = new QtLocalPeer (this, app_id);
//        peer.signal_message_received.connect (
//            this.signal_message_received
//        );
//    }

//    /***********************************************************
//    ***********************************************************/
//    public bool is_running {
//        public get {
//            return peer.is_client ();
//        }
//    }

//    /***********************************************************
//    ***********************************************************/
//    public string identifier {
//        public get {
//            return peer.application_id ();
//        }
//    }

//    /***********************************************************
//    ***********************************************************/
//    public bool on_send_message (string message, int timeout = 5000) {
//        return peer.on_send_message (message, timeout, block);
//    }

} // class QtSingleCoreApplication

} // namespace SharedTools
//    