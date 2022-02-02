/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/


using namespace Occ;

class StatusPushSpy : QSignalSpy {
    SyncEngine this.syncEngine;

    /***********************************************************
    ***********************************************************/
    public StatusPushSpy (SyncEngine syncEngine)
        : QSignalSpy (&syncEngine.syncFileStatusTracker (), SIGNAL (fileStatusChanged (string&, SyncFileStatus)))
        , this.syncEngine (syncEngine) { }


    /***********************************************************
    ***********************************************************/
    public SyncFileStatus statusOf (string relativePath) {
        QFileInfo file (this.syncEngine.localPath (), relativePath);
        // Start from the end to get the latest status
        for (int i = size () - 1; i >= 0; --i) {
            if (QFileInfo (at (i)[0].toString ()) == file)
                return at (i)[1].value<SyncFileStatus> ();
        }
        return {};
    }


    /***********************************************************
    ***********************************************************/
    public bool statusEmittedBefore (string firstPath, string secondPath) {
        QFileInfo firstFile (this.syncEngine.localPath (), firstPath);
        QFileInfo secondFile (this.syncEngine.localPath (), secondPath);
        // Start from the end to get the latest status
        int i = size () - 1;
        for (; i >= 0; --i) {
            if (QFileInfo (at (i)[0].toString ()) == secondFile)
                break;
            else if (QFileInfo (at (i)[0].toString ()) == firstFile)
                return false;
        }
        for (; i >= 0; --i) {
            if (QFileInfo (at (i)[0].toString ()) == firstFile)
                return true;
        }
        return false;
    }
};