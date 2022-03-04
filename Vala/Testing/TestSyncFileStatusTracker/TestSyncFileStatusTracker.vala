/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>

using Occ;

namespace Testing {

class TestSyncFileStatusTracker : GLib.Object {

    void verifyThatPushMatchesPull (FakeFolder fakeFolder, StatusPushSpy statusSpy) {
        string root = fakeFolder.local_path ();
        QDirIterator it (root, QDir.AllEntries | QDir.NoDotAndDotDot, QDirIterator.Subdirectories);
        while (it.hasNext ()) {
            string filePath = it.next ().mid (root.size ());
            SyncFileStatus pushedStatus = statusSpy.statusOf (filePath);
            if (pushedStatus != SyncFileStatus ())
                QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus (filePath), pushedStatus);
        }
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetSyncStatusUploadDownload () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.local_modifier ().append_byte ("B/b1");
        fakeFolder.remote_modifier ().append_byte ("C/c1");
        StatusPushSpy statusSpy (fakeFolder.sync_engine ());

        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("C/c1"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("B/b2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("C/c2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("C/c1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetSyncStatusNewFileUploadDownload () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.local_modifier ().insert ("B/b0");
        fakeFolder.remote_modifier ().insert ("C/c0");
        StatusPushSpy statusSpy (fakeFolder.sync_engine ());

        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("C/c0"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("B/b1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("C/c1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("C/c0"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetSyncStatusNewDirDownload () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.remote_modifier ().mkdir ("D");
        fakeFolder.remote_modifier ().insert ("D/d0");
        StatusPushSpy statusSpy (fakeFolder.sync_engine ());

        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusSync));

        fakeFolder.exec_until_item_completed ("D");
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusSync));

        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetSyncStatusNewDirUpload () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.local_modifier ().mkdir ("D");
        fakeFolder.local_modifier ().insert ("D/d0");
        StatusPushSpy statusSpy (fakeFolder.sync_engine ());

        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusSync));

        fakeFolder.exec_until_item_completed ("D");
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusSync));

        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("D"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("D/d0"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetSyncStatusDeleteUpDown () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.remote_modifier ().remove ("B/b1");
        fakeFolder.local_modifier ().remove ("C/c1");
        StatusPushSpy statusSpy (fakeFolder.sync_engine ());

        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        // Discovered as remotely removed, pending for local removal.
        QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("B/b2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("C/c2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void warningStatusForExcludedFile () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().excludedFiles ().addManualExclude ("A/a1");
        fakeFolder.sync_engine ().excludedFiles ().addManualExclude ("B");
        fakeFolder.local_modifier ().append_byte ("A/a1");
        fakeFolder.local_modifier ().append_byte ("B/b1");
        StatusPushSpy statusSpy (fakeFolder.sync_engine ());

        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        QEXPECT_FAIL ("", "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusExcluded));

        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        QEXPECT_FAIL ("", "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        QEXPECT_FAIL ("", "csync will stop at ignored directories without traversing children, so we don't currently push the status for newly ignored children of an ignored directory.", Continue);
        QCOMPARE (statusSpy.statusOf ("B/b2"), SyncFileStatus (SyncFileStatus.StatusExcluded));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        // Clears the exclude expr above
        fakeFolder.sync_engine ().excludedFiles ().clearManualExcludes ();
        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusSync));
        statusSpy.clear ();

        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void warningStatusForExcludedFile_CasePreserving () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.sync_engine ().excludedFiles ().addManualExclude ("B");
        fakeFolder.server_error_paths ().append ("A/a1");
        fakeFolder.local_modifier ().append_byte ("A/a1");

        fakeFolder.sync_once ();
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("B"), SyncFileStatus (SyncFileStatus.StatusExcluded));

        // Should still get the status for different casing on macOS and Windows.
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("a"), SyncFileStatus (Utility.fsCasePreserving () ? SyncFileStatus.StatusWarning : SyncFileStatus.StatusNone));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/A1"), SyncFileStatus (Utility.fsCasePreserving () ? SyncFileStatus.StatusError : SyncFileStatus.StatusNone));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("b"), SyncFileStatus (Utility.fsCasePreserving () ? SyncFileStatus.StatusExcluded : SyncFileStatus.StatusNone));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetWarningStatusForError () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.server_error_paths ().append ("A/a1");
        fakeFolder.server_error_paths ().append ("B/b0");
        fakeFolder.local_modifier ().append_byte ("A/a1");
        fakeFolder.local_modifier ().insert ("B/b0");
        StatusPushSpy statusSpy (fakeFolder.sync_engine ());

        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusSync));
        statusSpy.clear ();

        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusError));
        statusSpy.clear ();

        // Remove the error and on_signal_start a second sync, the blocklist should kick in
        fakeFolder.server_error_paths ().clear ();
        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        // A/a1 and B/b0 should be on the block list for the next few seconds
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusError));
        statusSpy.clear ();
        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusError));
        statusSpy.clear ();

        // Start a third sync, this time together with a real file to sync
        fakeFolder.local_modifier ().append_byte ("C/c1");
        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        // The root should show SYNC even though there is an error underneath,
        // since C/c1 is syncing and the SYNC status has priority.
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("C/c1"), SyncFileStatus (SyncFileStatus.StatusSync));
        statusSpy.clear ();
        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a2"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("C/c1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        // Another sync after clearing the blocklist entry, everything should return to order.
        fakeFolder.sync_engine ().journal ().wipeErrorBlocklistEntry ("A/a1");
        fakeFolder.sync_engine ().journal ().wipeErrorBlocklistEntry ("B/b0");
        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusSync));
        statusSpy.clear ();
        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("A/a1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B/b0"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void parentsGetWarningStatusForError_SibblingStartsWithPath () {
        // A is a parent of A/a1, but A/a is not even if it's a substring of A/a1
        FakeFolder fakeFolder{{string{},{ { "A", { { "a", 4}, { "a1", 4}
            }}}}};
        fakeFolder.server_error_paths ().append ("A/a1");
        fakeFolder.local_modifier ().append_byte ("A/a1");

        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        // The SyncFileStatusTraker won't push any status for all of them, test with a pull.
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a1"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a"), SyncFileStatus (SyncFileStatus.StatusUpToDate));

        fakeFolder.exec_until_finished ();
        // We use string matching for paths in the implementation,
        // an error should affect only parents and not every path that starts with the problem path.
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a1"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (fakeFolder.sync_engine ().syncFileStatusTracker ().fileStatus ("A/a"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
    }

    // Even for status pushes immediately following each other, macOS
    // can sometimes have 1s delays between updates, so make sure that
    // children are marked as OK before their parents do.
    private on_ void childOKEmittedBeforeParent () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.local_modifier ().append_byte ("B/b1");
        fakeFolder.remote_modifier ().append_byte ("C/c1");
        StatusPushSpy statusSpy (fakeFolder.sync_engine ());

        fakeFolder.sync_once ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QVERIFY (statusSpy.statusEmittedBefore ("B/b1", "B"));
        QVERIFY (statusSpy.statusEmittedBefore ("C/c1", "C"));
        QVERIFY (statusSpy.statusEmittedBefore ("B", ""));
        QVERIFY (statusSpy.statusEmittedBefore ("C", ""));
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B/b1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("C"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("C/c1"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
    }


    /***********************************************************
    ***********************************************************/
    private on_ void sharedStatus () {
        SyncFileStatus sharedUpToDateStatus (SyncFileStatus.StatusUpToDate);
        sharedUpToDateStatus.setShared (true);

        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.remote_modifier ().insert ("S/s0");
        fakeFolder.remote_modifier ().append_byte ("S/s1");
        fakeFolder.remote_modifier ().insert ("B/b3");
        fakeFolder.remote_modifier ().find ("B/b3").extraDavProperties = "<oc:share-types><oc:share-type>0</oc:share-type></oc:share-types>";
        fakeFolder.remote_modifier ().find ("A/a1").isShared = true; // becomes shared
        fakeFolder.remote_modifier ().find ("A", true); // change the etags of the parent

        StatusPushSpy statusSpy (fakeFolder.sync_engine ());

        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        // We don't care about the shared flag for the sync status,
        // Mac and Windows won't show it and we can't know it for new files.
        QCOMPARE (statusSpy.statusOf ("S").tag (), SyncFileStatus.StatusSync);
        QCOMPARE (statusSpy.statusOf ("S/s0").tag (), SyncFileStatus.StatusSync);
        QCOMPARE (statusSpy.statusOf ("S/s1").tag (), SyncFileStatus.StatusSync);

        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("S"), sharedUpToDateStatus);
        QEXPECT_FAIL ("", "We currently only know if a new file is shared on the second sync, after a PROPFIND.", Continue);
        QCOMPARE (statusSpy.statusOf ("S/s0"), sharedUpToDateStatus);
        QCOMPARE (statusSpy.statusOf ("S/s1"), sharedUpToDateStatus);
        QCOMPARE (statusSpy.statusOf ("B/b1").shared (), false);
        QCOMPARE (statusSpy.statusOf ("B/b3"), sharedUpToDateStatus);
        QCOMPARE (statusSpy.statusOf ("A/a1"), sharedUpToDateStatus);

        QCOMPARE (fakeFolder.current_local_state (), fakeFolder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void renameError () {
        FakeFolder fakeFolder{FileInfo.A12_B12_C12_S12 ()};
        fakeFolder.server_error_paths ().append ("A/a1");
        fakeFolder.local_modifier ().rename ("A/a1", "A/a1m");
        fakeFolder.local_modifier ().rename ("B/b1", "B/b1m");
        StatusPushSpy statusSpy (fakeFolder.sync_engine ());

        fakeFolder.schedule_sync ();
        fakeFolder.exec_until_before_propagation ();

        verifyThatPushMatchesPull (fakeFolder, statusSpy);

        QCOMPARE (statusSpy.statusOf ("A/a1m"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("A/a1"), statusSpy.statusOf ("A/a1notexist"));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusSync));
        QCOMPARE (statusSpy.statusOf ("B/b1m"), SyncFileStatus (SyncFileStatus.StatusSync));

        fakeFolder.exec_until_finished ();
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf ("A/a1m"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (statusSpy.statusOf ("A/a1"), statusSpy.statusOf ("A/a1notexist"));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        QCOMPARE (statusSpy.statusOf ("B/b1m"), SyncFileStatus (SyncFileStatus.StatusUpToDate));
        statusSpy.clear ();

        QVERIFY (!fakeFolder.sync_once ());
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        statusSpy.clear ();
        QVERIFY (!fakeFolder.sync_once ());
        verifyThatPushMatchesPull (fakeFolder, statusSpy);
        QCOMPARE (statusSpy.statusOf ("A/a1m"), SyncFileStatus (SyncFileStatus.StatusError));
        QCOMPARE (statusSpy.statusOf ("A/a1"), statusSpy.statusOf ("A/a1notexist"));
        QCOMPARE (statusSpy.statusOf ("A"), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf (""), SyncFileStatus (SyncFileStatus.StatusWarning));
        QCOMPARE (statusSpy.statusOf ("B"), SyncFileStatus (SyncFileStatus.StatusNone));
        QCOMPARE (statusSpy.statusOf ("B/b1m"), SyncFileStatus (SyncFileStatus.StatusNone));
        statusSpy.clear ();
    }

}

QTEST_GUILESS_MAIN (TestSyncFileStatusTracker)
