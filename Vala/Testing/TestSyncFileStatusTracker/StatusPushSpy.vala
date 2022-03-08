/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

using Occ;

namespace Testing {

class StatusPushSpy : QSignalSpy {

    SyncEngine sync_engine;

    /***********************************************************
    ***********************************************************/
    public StatusPushSpy (SyncEngine sync_engine) {
        base (sync_engine.syncFileStatusTracker (), SIGNAL (fileStatusChanged (string, SyncFileStatus)));
        this.sync_engine (sync_engine);
    }

    /***********************************************************
    ***********************************************************/
    public SyncFileStatus statusOf (string relative_path) {
        GLib.FileInfo file_info = new GLib.FileInfo (this.sync_engine.local_path (), relative_path);
        // Start from the end to get the latest status
        for (int i = size () - 1; i >= 0; --i) {
            if (GLib.FileInfo (at (i)[0].to_string ()) == file_info)
                return at (i)[1].value<SyncFileStatus> ();
        }
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public bool statusEmittedBefore (string firstPath, string secondPath) {
        GLib.FileInfo firstFile = new GLib.FileInfo (this.sync_engine.local_path (), firstPath);
        GLib.FileInfo secondFile = new GLib.FileInfo (this.sync_engine.local_path (), secondPath);
        // Start from the end to get the latest status
        int i = size () - 1;
        for (; i >= 0; --i) {
            if (GLib.FileInfo (at (i)[0].to_string ()) == secondFile)
                break;
            else if (GLib.FileInfo (at (i)[0].to_string ()) == firstFile)
                return false;
        }
        for (; i >= 0; --i) {
            if (GLib.FileInfo (at (i)[0].to_string ()) == firstFile)
                return true;
        }
        return false;
    }
}
}
