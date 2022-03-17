/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

using Occ;

namespace Testing {

public class StatusPushSpy : QSignalSpy {

    SyncEngine sync_engine;

    /***********************************************************
    ***********************************************************/
    public StatusPushSpy (SyncEngine sync_engine) {
        base (sync_engine.sync_file_status_tracker, SIGNAL (signal_file_status_changed (string, SyncFileStatus)));
        this.sync_engine (sync_engine);
    }


    /***********************************************************
    ***********************************************************/
    public SyncFileStatus status_of (string relative_path) {
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
    public bool status_emitted_before (string first_path, string second_path) {
        GLib.FileInfo first_file = new GLib.FileInfo (this.sync_engine.local_path (), first_path);
        GLib.FileInfo second_file = new GLib.FileInfo (this.sync_engine.local_path (), second_path);
        // Start from the end to get the latest status
        int i = size () - 1;
        for (; i >= 0; --i) {
            if (GLib.FileInfo (at (i)[0].to_string ()) == second_file)
                break;
            else if (GLib.FileInfo (at (i)[0].to_string ()) == first_file)
                return false;
        }
        for (; i >= 0; --i) {
            if (GLib.FileInfo (at (i)[0].to_string ()) == first_file)
                return true;
        }
        return false;
    }
}
}
