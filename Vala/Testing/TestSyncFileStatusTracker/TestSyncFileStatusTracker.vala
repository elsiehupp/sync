/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>

using Occ;

namespace Testing {

class TestSyncFileStatusTracker : GLib.Object {

    void verifyThatPushMatchesPull (FakeFolder fake_folder, StatusPushSpy statusSpy) {
        string root = fake_folder.local_path ();
        QDirIterator it (root, QDir.AllEntries | QDir.NoDotAndDotDot, QDirIterator.Subdirectories);
        while (it.hasNext ()) {
            string filePath = it.next ().mid (root.size ());
            SyncFileStatus pushedStatus = statusSpy.statusOf (filePath);
            if (pushedStatus != SyncFileStatus ())
                //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus (filePath), pushedStatus);
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetSyncStatusUploadDownload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.local_modifier ().append_byte ("B/b1");
        fake_folder.remote_modifier ().append_byte ("C/c1");
        StatusPushSpy statusSpy (fake_folder.sync_engine ());

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("C/c1"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("B/b2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("C/c2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("C/c1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetSyncStatusNewFileUploadDownload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.local_modifier ().insert ("B/b0");
        fake_folder.remote_modifier ().insert ("C/c0");
        StatusPushSpy statusSpy (fake_folder.sync_engine ());

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("C/c0"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("B/b1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("C/c1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("C/c0"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetSyncStatusNewDirDownload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().mkdir ("D");
        fake_folder.remote_modifier ().insert ("D/d0");
        StatusPushSpy statusSpy (fake_folder.sync_engine ());

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusSync));

        fake_folder.exec_until_item_completed ("D");
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusSync));

        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetSyncStatusNewDirUpload () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.local_modifier ().mkdir ("D");
        fake_folder.local_modifier ().insert ("D/d0");
        StatusPushSpy statusSpy (fake_folder.sync_engine ());

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusSync));

        fake_folder.exec_until_item_completed ("D");
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusSync));

        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetSyncStatusDeleteUpDown () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().remove ("B/b1");
        fake_folder.local_modifier ().remove ("C/c1");
        StatusPushSpy statusSpy (fake_folder.sync_engine ());

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        // Discovered as remotely removed, pending for local removal.
        //  QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("B/b2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("C/c2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void warningStatusForExcludedFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().excludedFiles ().addManualExclude ("A/a1");
        fake_folder.sync_engine ().excludedFiles ().addManualExclude ("B");
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().append_byte ("B/b1");
        StatusPushSpy statusSpy (fake_folder.sync_engine ());

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        QEXPECT_FAIL ("", "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        //  QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusExcluded));

        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        QEXPECT_FAIL ("", "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        //  QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        QEXPECT_FAIL ("", "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        //  QCOMPARE (statusSpy.statusOf ("B/b2"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        // Clears the exclude expr above
        fake_folder.sync_engine ().excludedFiles ().clearManualExcludes ();
        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusSync));
        statusSpy.clear ();

        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void warningStatusForExcludedFile_CasePreserving () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.sync_engine ().excludedFiles ().addManualExclude ("B");
        fake_folder.server_error_paths ().append ("A/a1");
        fake_folder.local_modifier ().append_byte ("A/a1");

        fake_folder.sync_once ();
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("B"), SyncFileStatus (SyncFileStatus.StatusExcluded));

        // Should still get the status for different casing on macOS and Windows.
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("a"), SyncFileStatus (Utility.filesystem_case_preserving () ? SyncFileStatus.StatusWarning : SyncFileStatus.StatusNone));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/A1"), SyncFileStatus (Utility.filesystem_case_preserving () ? SyncFileStatus.StatusError : SyncFileStatus.StatusNone));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("b"), SyncFileStatus (Utility.filesystem_case_preserving () ? SyncFileStatus.StatusExcluded : SyncFileStatus.StatusNone));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetWarningStatusForError () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.server_error_paths ().append ("A/a1");
        fake_folder.server_error_paths ().append ("B/b0");
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().insert ("B/b0");
        StatusPushSpy statusSpy (fake_folder.sync_engine ());

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusSync));
        statusSpy.clear ();

        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusError));
        statusSpy.clear ();

        // Remove the error and on_signal_start a second sync, the blocklist should kick in
        fake_folder.server_error_paths ().clear ();
        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        // A/a1 and B/b0 should be on the block list for the next few seconds
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusError));
        statusSpy.clear ();
        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusError));
        statusSpy.clear ();

        // Start a third sync, this time together with a real file to sync
        fake_folder.local_modifier ().append_byte ("C/c1");
        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        // The root should show SYNC even though there is an error underneath,
        // since C/c1 is syncing and the SYNC status has priority.
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("C/c1"), SyncFileStatus (SyncFileStatus.StatusSync));
        statusSpy.clear ();
        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("C/c1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        // Another sync after clearing the blocklist entry, everything should return to order.
        fake_folder.sync_engine ().journal ().wipeErrorBlocklistEntry ("A/a1");
        fake_folder.sync_engine ().journal ().wipeErrorBlocklistEntry ("B/b0");
        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusSync));
        statusSpy.clear ();
        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetWarningStatusForError_SibblingStartsWithPath () {
        // A is a parent of A/a1, but A/a is not even if it's a substring of A/a1
        FakeFolder fake_folder = new FakeFolder ({string{},{ { "A", { { "a", 4}, { "a1", 4}
            }}}}};
        fake_folder.server_error_paths ().append ("A/a1");
        fake_folder.local_modifier ().append_byte ("A/a1");

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        // The SyncFileStatusTraker won't push any status for all of them, test with a pull.
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a1"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        fake_folder.exec_until_finished ();
        // We use string matching for paths in the implementation,
        // an error should affect only parents and not every path that starts with the problem path.
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (fake_folder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
    }

    // Even for status pushes immediately following each other, macOS
    // can sometimes have 1s delays between updates, so make sure that
    // children are marked as OK before their parents do.
    private on_ void childOKEmittedBeforeParent () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.local_modifier ().append_byte ("B/b1");
        fake_folder.remote_modifier ().append_byte ("C/c1");
        StatusPushSpy statusSpy (fake_folder.sync_engine ());

        fake_folder.sync_once ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QVERIFY (statusSpy.statusEmittedBefore ("B/b1", "B"));
        //  QVERIFY (statusSpy.statusEmittedBefore ("C/c1", "C"));
        //  QVERIFY (statusSpy.statusEmittedBefore ("B", ""));
        //  QVERIFY (statusSpy.statusEmittedBefore ("C", ""));
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("C/c1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void sharedStatus () {
        SyncFileStatus sharedUpToDateStatus (SyncFileStatus.StatusUpToDate);
        sharedUpToDateStatus.setShared (true);

        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.remote_modifier ().insert ("S/s0");
        fake_folder.remote_modifier ().append_byte ("S/s1");
        fake_folder.remote_modifier ().insert ("B/b3");
        fake_folder.remote_modifier ().find ("B/b3").extraDavProperties = "<oc:share-types><oc:share-type>0</oc:share-type></oc:share-types>";
        fake_folder.remote_modifier ().find ("A/a1").isShared = true; // becomes shared
        fake_folder.remote_modifier ().find ("A", true); // change the etags of the parent

        StatusPushSpy statusSpy (fake_folder.sync_engine ());

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        // We don't care about the shared flag for the sync status,
        // Mac and Windows won't show it and we can't know it for new files.
        //  QCOMPARE (statusSpy.statusOf ("S").tag (), SyncFileStatus.StatusSync);
        //  QCOMPARE (statusSpy.statusOf ("S/s0").tag (), SyncFileStatus.StatusSync);
        //  QCOMPARE (statusSpy.statusOf ("S/s1").tag (), SyncFileStatus.StatusSync);

        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("S"), sharedUpToDateStatus);
        QEXPECT_FAIL ("", "We currently only know if a new file is shared on the second sync, after a PROPFIND.", Continue);
        //  QCOMPARE (statusSpy.statusOf ("S/s0"), sharedUpToDateStatus);
        //  QCOMPARE (statusSpy.statusOf ("S/s1"), sharedUpToDateStatus);
        //  QCOMPARE (statusSpy.statusOf ("B/b1").shared (), false);
        //  QCOMPARE (statusSpy.statusOf ("B/b3"), sharedUpToDateStatus);
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), sharedUpToDateStatus);

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void renameError () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        fake_folder.server_error_paths ().append ("A/a1");
        fake_folder.local_modifier ().rename ("A/a1", "A/a1m");
        fake_folder.local_modifier ().rename ("B/b1", "B/b1m");
        StatusPushSpy statusSpy (fake_folder.sync_engine ());

        fake_folder.schedule_sync ();
        fake_folder.exec_until_before_propagation ();

        verifyThatPushMatchesPull (fake_folder, statusSpy);

        //  QCOMPARE (statusSpy.statusOf ("A/a1m"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), statusSpy.statusOf ("A/a1notexist"));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        //  QCOMPARE (statusSpy.statusOf ("B/b1m"), SyncFileStatus (SyncFileStatus.StatusSync));

        fake_folder.exec_until_finished ();
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf ("A/a1m"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), statusSpy.statusOf ("A/a1notexist"));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        //  QCOMPARE (statusSpy.statusOf ("B/b1m"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        //  QVERIFY (!fake_folder.sync_once ());
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        statusSpy.clear ();
        //  QVERIFY (!fake_folder.sync_once ());
        verifyThatPushMatchesPull (fake_folder, statusSpy);
        //  QCOMPARE (statusSpy.statusOf ("A/a1m"), SyncFileStatus (SyncFileStatus.StatusError));
        //  QCOMPARE (statusSpy.statusOf ("A/a1"), statusSpy.statusOf ("A/a1notexist"));
        //  QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        //  QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusNone));
        //  QCOMPARE (statusSpy.statusOf ("B/b1m"), SyncFileStatus (SyncFileStatus.StatusNone));
        statusSpy.clear ();
    }

}

QTEST_GUILESS_MAIN (TestSyncFileStatusTracker)
