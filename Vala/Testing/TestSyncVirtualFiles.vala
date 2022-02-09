/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using namespace Occ;

const int DVSUFFIX APPLICATION_DOTVIRTUALFILE_SUFFIX

bool itemInstruction (ItemCompletedSpy spy, string path, SyncInstructions instr) {
    var item = spy.findItem (path);
    return item.instruction == instr;
}

SyncJournalFileRecord dbRecord (FakeFolder folder, string path) {
    SyncJournalFileRecord record;
    folder.syncJournal ().getFileRecord (path, record);
    return record;
}

void triggerDownload (FakeFolder folder, GLib.ByteArray path) {
    var journal = folder.syncJournal ();
    SyncJournalFileRecord record;
    journal.getFileRecord (path + DVSUFFIX, record);
    if (!record.isValid ())
        return;
    record.type = ItemTypeVirtualFileDownload;
    journal.setFileRecord (record);
    journal.schedulePathForRemoteDiscovery (record.path);
}

void markForDehydration (FakeFolder folder, GLib.ByteArray path) {
    var journal = folder.syncJournal ();
    SyncJournalFileRecord record;
    journal.getFileRecord (path, record);
    if (!record.isValid ())
        return;
    record.type = ItemTypeVirtualFileDehydration;
    journal.setFileRecord (record);
    journal.schedulePathForRemoteDiscovery (record.path);
}

unowned<Vfs> setupVfs (FakeFolder folder) {
    var suffixVfs = unowned<Vfs> (createVfsFromPlugin (Vfs.WithSuffix).release ());
    folder.switchToVfs (suffixVfs);

    // Using this directly doesn't recursively unpin everything and instead leaves
    // the files in the hydration that that they on_signal_start with
    folder.syncJournal ().internalPinStates ().setForPath ("", PinState.PinState.UNSPECIFIED);

    return suffixVfs;
}

class TestSyncVirtualFiles : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_lifecycle_data () {
        QTest.addColumn<bool> ("doLocalDiscovery");

        QTest.newRow ("full local discovery") + true;
        QTest.newRow ("skip local discovery") + false;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_lifecycle () {
        QFETCH (bool, doLocalDiscovery);

        FakeFolder fakeFolder{ FileInfo () };
        setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        ItemCompletedSpy completeSpy (fakeFolder);

        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
            if (!doLocalDiscovery)
                fakeFolder.syncEngine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
        }
        on_signal_cleanup ();

        // Create a virtual file for a new remote file
        fakeFolder.remoteModifier ().mkdir ("A");
        fakeFolder.remoteModifier ().insert ("A/a1", 64);
        var someDate = GLib.DateTime (QDate (1984, 07, 30), QTime (1,3,2));
        fakeFolder.remoteModifier ().setModTime ("A/a1", someDate);
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QCOMPARE (QFileInfo (fakeFolder.localPath () + "A/a1" DVSUFFIX).lastModified (), someDate);
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        QCOMPARE (dbRecord (fakeFolder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        on_signal_cleanup ();

        // Another sync doesn't actually lead to changes
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QCOMPARE (QFileInfo (fakeFolder.localPath () + "A/a1" DVSUFFIX).lastModified (), someDate);
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QCOMPARE (dbRecord (fakeFolder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        QVERIFY (completeSpy.isEmpty ());
        on_signal_cleanup ();

        // Not even when the remote is rediscovered
        fakeFolder.syncJournal ().forceRemoteDiscoveryNextSync ();
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QCOMPARE (QFileInfo (fakeFolder.localPath () + "A/a1" DVSUFFIX).lastModified (), someDate);
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QCOMPARE (dbRecord (fakeFolder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        QVERIFY (completeSpy.isEmpty ());
        on_signal_cleanup ();

        // Neither does a remote change
        fakeFolder.remoteModifier ().appendByte ("A/a1");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_UPDATE_METADATA));
        QCOMPARE (dbRecord (fakeFolder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        QCOMPARE (dbRecord (fakeFolder, "A/a1" DVSUFFIX).fileSize, 65);
        on_signal_cleanup ();

        // If the local virtual file file is removed, it'll just be recreated
        if (!doLocalDiscovery)
            fakeFolder.syncEngine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });
        fakeFolder.localModifier ().remove ("A/a1" DVSUFFIX);
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        QCOMPARE (dbRecord (fakeFolder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        QCOMPARE (dbRecord (fakeFolder, "A/a1" DVSUFFIX).fileSize, 65);
        on_signal_cleanup ();

        // Remote rename is propagated
        fakeFolder.remoteModifier ().rename ("A/a1", "A/a1m");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1m"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1m" DVSUFFIX));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1m"));
        QVERIFY (
            itemInstruction (completeSpy, "A/a1m" DVSUFFIX, CSYNC_INSTRUCTION_RENAME)
            || (itemInstruction (completeSpy, "A/a1m" DVSUFFIX, CSYNC_INSTRUCTION_NEW)
                && itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE)));
        QCOMPARE (dbRecord (fakeFolder, "A/a1m" DVSUFFIX).type, ItemTypeVirtualFile);
        on_signal_cleanup ();

        // Remote remove is propagated
        fakeFolder.remoteModifier ().remove ("A/a1m");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1m" DVSUFFIX));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("A/a1m"));
        QVERIFY (itemInstruction (completeSpy, "A/a1m" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (!dbRecord (fakeFolder, "A/a1" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/a1m" DVSUFFIX).isValid ());
        on_signal_cleanup ();

        // Edge case : Local virtual file but no database entry for some reason
        fakeFolder.remoteModifier ().insert ("A/a2", 64);
        fakeFolder.remoteModifier ().insert ("A/a3", 64);
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a2" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a3" DVSUFFIX));
        on_signal_cleanup ();

        fakeFolder.syncEngine ().journal ().deleteFileRecord ("A/a2" DVSUFFIX);
        fakeFolder.syncEngine ().journal ().deleteFileRecord ("A/a3" DVSUFFIX);
        fakeFolder.remoteModifier ().remove ("A/a3");
        fakeFolder.syncEngine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a2" DVSUFFIX));
        QVERIFY (itemInstruction (completeSpy, "A/a2" DVSUFFIX, CSYNC_INSTRUCTION_UPDATE_METADATA));
        QVERIFY (dbRecord (fakeFolder, "A/a2" DVSUFFIX).isValid ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a3" DVSUFFIX));
        QVERIFY (itemInstruction (completeSpy, "A/a3" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (!dbRecord (fakeFolder, "A/a3" DVSUFFIX).isValid ());
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_conflict () {
        FakeFolder fakeFolder{ FileInfo () };
        setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        ItemCompletedSpy completeSpy (fakeFolder);

        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }
        on_signal_cleanup ();

        // Create a virtual file for a new remote file
        fakeFolder.remoteModifier ().mkdir ("A");
        fakeFolder.remoteModifier ().insert ("A/a1", 64);
        fakeFolder.remoteModifier ().insert ("A/a2", 64);
        fakeFolder.remoteModifier ().mkdir ("B");
        fakeFolder.remoteModifier ().insert ("B/b1", 64);
        fakeFolder.remoteModifier ().insert ("B/b2", 64);
        fakeFolder.remoteModifier ().mkdir ("C");
        fakeFolder.remoteModifier ().insert ("C/c1", 64);
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("B/b2" DVSUFFIX));
        on_signal_cleanup ();

        // A : the correct file and a conflicting file are added, virtual files stay
        // B : same setup, but the virtual files are deleted by the user
        // C : user adds a directory* locally
        fakeFolder.localModifier ().insert ("A/a1", 64);
        fakeFolder.localModifier ().insert ("A/a2", 30);
        fakeFolder.localModifier ().insert ("B/b1", 64);
        fakeFolder.localModifier ().insert ("B/b2", 30);
        fakeFolder.localModifier ().remove ("B/b1" DVSUFFIX);
        fakeFolder.localModifier ().remove ("B/b2" DVSUFFIX);
        fakeFolder.localModifier ().mkdir ("C/c1");
        fakeFolder.localModifier ().insert ("C/c1/foo");
        QVERIFY (fakeFolder.syncOnce ());

        // Everything is CONFLICT since mtimes are different even for a1/b1
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "A/a2", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "B/b1", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "B/b2", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "C/c1", CSYNC_INSTRUCTION_CONFLICT));

        // no virtual file files should remain
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a2" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("B/b1" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("B/b2" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("C/c1" DVSUFFIX));

        // conflict files should exist
        QCOMPARE (fakeFolder.syncJournal ().conflictRecordPaths ().size (), 3);

        // nothing should have the virtual file tag
        QCOMPARE (dbRecord (fakeFolder, "A/a1").type, ItemTypeFile);
        QCOMPARE (dbRecord (fakeFolder, "A/a2").type, ItemTypeFile);
        QCOMPARE (dbRecord (fakeFolder, "B/b1").type, ItemTypeFile);
        QCOMPARE (dbRecord (fakeFolder, "B/b2").type, ItemTypeFile);
        QCOMPARE (dbRecord (fakeFolder, "C/c1").type, ItemTypeFile);
        QVERIFY (!dbRecord (fakeFolder, "A/a1" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/a2" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "B/b1" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "B/b2" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "C/c1" DVSUFFIX).isValid ());

        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_with_normal_sync () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        ItemCompletedSpy completeSpy (fakeFolder);

        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }
        on_signal_cleanup ();

        // No effect sync
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        on_signal_cleanup ();

        // Existing files are propagated just fine in both directions
        fakeFolder.localModifier ().appendByte ("A/a1");
        fakeFolder.localModifier ().insert ("A/a3");
        fakeFolder.remoteModifier ().appendByte ("A/a2");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        on_signal_cleanup ();

        // New files on the remote create virtual files
        fakeFolder.remoteModifier ().insert ("A/new");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/new"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/new" DVSUFFIX));
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/new"));
        QVERIFY (itemInstruction (completeSpy, "A/new" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        QCOMPARE (dbRecord (fakeFolder, "A/new" DVSUFFIX).type, ItemTypeVirtualFile);
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_download () {
        FakeFolder fakeFolder{ FileInfo () };
        setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        ItemCompletedSpy completeSpy (fakeFolder);

        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }
        on_signal_cleanup ();

        // Create a virtual file for remote files
        fakeFolder.remoteModifier ().mkdir ("A");
        fakeFolder.remoteModifier ().insert ("A/a1");
        fakeFolder.remoteModifier ().insert ("A/a2");
        fakeFolder.remoteModifier ().insert ("A/a3");
        fakeFolder.remoteModifier ().insert ("A/a4");
        fakeFolder.remoteModifier ().insert ("A/a5");
        fakeFolder.remoteModifier ().insert ("A/a6");
        fakeFolder.remoteModifier ().insert ("A/a7");
        fakeFolder.remoteModifier ().insert ("A/b1");
        fakeFolder.remoteModifier ().insert ("A/b2");
        fakeFolder.remoteModifier ().insert ("A/b3");
        fakeFolder.remoteModifier ().insert ("A/b4");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a2" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a3" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a4" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a5" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a6" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a7" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/b1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/b2" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/b3" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/b4" DVSUFFIX));
        on_signal_cleanup ();

        // Download by changing the database entry
        triggerDownload (fakeFolder, "A/a1");
        triggerDownload (fakeFolder, "A/a2");
        triggerDownload (fakeFolder, "A/a3");
        triggerDownload (fakeFolder, "A/a4");
        triggerDownload (fakeFolder, "A/a5");
        triggerDownload (fakeFolder, "A/a6");
        triggerDownload (fakeFolder, "A/a7");
        // Download by renaming locally
        fakeFolder.localModifier ().rename ("A/b1" DVSUFFIX, "A/b1");
        fakeFolder.localModifier ().rename ("A/b2" DVSUFFIX, "A/b2");
        fakeFolder.localModifier ().rename ("A/b3" DVSUFFIX, "A/b3");
        fakeFolder.localModifier ().rename ("A/b4" DVSUFFIX, "A/b4");
        // Remote complications
        fakeFolder.remoteModifier ().appendByte ("A/a2");
        fakeFolder.remoteModifier ().remove ("A/a3");
        fakeFolder.remoteModifier ().rename ("A/a4", "A/a4m");
        fakeFolder.remoteModifier ().appendByte ("A/b2");
        fakeFolder.remoteModifier ().remove ("A/b3");
        fakeFolder.remoteModifier ().rename ("A/b4", "A/b4m");
        // Local complications
        fakeFolder.localModifier ().insert ("A/a5");
        fakeFolder.localModifier ().insert ("A/a6");
        fakeFolder.localModifier ().remove ("A/a6" DVSUFFIX);
        fakeFolder.localModifier ().rename ("A/a7" DVSUFFIX, "A/a7");

        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        QCOMPARE (completeSpy.findItem ("A/a1").type, ItemTypeVirtualFileDownload);
        QVERIFY (itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_NONE));
        QVERIFY (itemInstruction (completeSpy, "A/a2", CSYNC_INSTRUCTION_SYNC));
        QCOMPARE (completeSpy.findItem ("A/a2").type, ItemTypeVirtualFileDownload);
        QVERIFY (itemInstruction (completeSpy, "A/a2" DVSUFFIX, CSYNC_INSTRUCTION_NONE));
        QVERIFY (itemInstruction (completeSpy, "A/a3" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (itemInstruction (completeSpy, "A/a4m", CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemInstruction (completeSpy, "A/a4" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (itemInstruction (completeSpy, "A/a5", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "A/a5" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (itemInstruction (completeSpy, "A/a6", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "A/a7", CSYNC_INSTRUCTION_SYNC));
        QVERIFY (itemInstruction (completeSpy, "A/b1", CSYNC_INSTRUCTION_SYNC));
        QVERIFY (itemInstruction (completeSpy, "A/b2", CSYNC_INSTRUCTION_SYNC));
        QVERIFY (itemInstruction (completeSpy, "A/b3", CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (itemInstruction (completeSpy, "A/b4m" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemInstruction (completeSpy, "A/b4", CSYNC_INSTRUCTION_REMOVE));
        QCOMPARE (dbRecord (fakeFolder, "A/a1").type, ItemTypeFile);
        QVERIFY (!dbRecord (fakeFolder, "A/a1" DVSUFFIX).isValid ());
        QCOMPARE (dbRecord (fakeFolder, "A/a2").type, ItemTypeFile);
        QVERIFY (!dbRecord (fakeFolder, "A/a3").isValid ());
        QCOMPARE (dbRecord (fakeFolder, "A/a4m").type, ItemTypeFile);
        QCOMPARE (dbRecord (fakeFolder, "A/a5").type, ItemTypeFile);
        QCOMPARE (dbRecord (fakeFolder, "A/a6").type, ItemTypeFile);
        QCOMPARE (dbRecord (fakeFolder, "A/a7").type, ItemTypeFile);
        QCOMPARE (dbRecord (fakeFolder, "A/b1").type, ItemTypeFile);
        QVERIFY (!dbRecord (fakeFolder, "A/b1" DVSUFFIX).isValid ());
        QCOMPARE (dbRecord (fakeFolder, "A/b2").type, ItemTypeFile);
        QVERIFY (!dbRecord (fakeFolder, "A/b3").isValid ());
        QCOMPARE (dbRecord (fakeFolder, "A/b4m" DVSUFFIX).type, ItemTypeVirtualFile);
        QVERIFY (!dbRecord (fakeFolder, "A/a1" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/a2" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/a3" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/a4" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/a5" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/a6" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/a7" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/b1" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/b2" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/b3" DVSUFFIX).isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/b4" DVSUFFIX).isValid ());

        triggerDownload (fakeFolder, "A/b4m");
        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_download_resume () {
        FakeFolder fakeFolder{ FileInfo () };
        setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        ItemCompletedSpy completeSpy (fakeFolder);

        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
            fakeFolder.syncJournal ().wipeErrorBlocklist ();
        }
        on_signal_cleanup ();

        // Create a virtual file for remote files
        fakeFolder.remoteModifier ().mkdir ("A");
        fakeFolder.remoteModifier ().insert ("A/a1");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        on_signal_cleanup ();

        // Download by changing the database entry
        triggerDownload (fakeFolder, "A/a1");
        fakeFolder.serverErrorPaths ().append ("A/a1", 500);
        QVERIFY (!fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        QVERIFY (itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_NONE));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QCOMPARE (dbRecord (fakeFolder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFileDownload);
        QVERIFY (!dbRecord (fakeFolder, "A/a1").isValid ());
        on_signal_cleanup ();

        fakeFolder.serverErrorPaths ().clear ();
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        QVERIFY (itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_NONE));
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (dbRecord (fakeFolder, "A/a1").type, ItemTypeFile);
        QVERIFY (!dbRecord (fakeFolder, "A/a1" DVSUFFIX).isValid ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_new_files_not_virtual () {
        FakeFolder fakeFolder{ FileInfo () };
        setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        fakeFolder.remoteModifier ().mkdir ("A");
        fakeFolder.remoteModifier ().insert ("A/a1");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));

        fakeFolder.syncJournal ().internalPinStates ().setForPath ("", PinState.PinState.ALWAYS_LOCAL);

        // Create a new remote file, it'll not be virtual
        fakeFolder.remoteModifier ().insert ("A/a2");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a2"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a2" DVSUFFIX));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_download_recursive () {
        FakeFolder fakeFolder{ FileInfo () };
        setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // Create a virtual file for remote files
        fakeFolder.remoteModifier ().mkdir ("A");
        fakeFolder.remoteModifier ().mkdir ("A/Sub");
        fakeFolder.remoteModifier ().mkdir ("A/Sub/SubSub");
        fakeFolder.remoteModifier ().mkdir ("A/Sub2");
        fakeFolder.remoteModifier ().mkdir ("B");
        fakeFolder.remoteModifier ().mkdir ("B/Sub");
        fakeFolder.remoteModifier ().insert ("A/a1");
        fakeFolder.remoteModifier ().insert ("A/a2");
        fakeFolder.remoteModifier ().insert ("A/Sub/a3");
        fakeFolder.remoteModifier ().insert ("A/Sub/a4");
        fakeFolder.remoteModifier ().insert ("A/Sub/SubSub/a5");
        fakeFolder.remoteModifier ().insert ("A/Sub2/a6");
        fakeFolder.remoteModifier ().insert ("B/b1");
        fakeFolder.remoteModifier ().insert ("B/Sub/b2");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a2" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/a3" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/a4" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/SubSub/a5" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub2/a6" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("B/b1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("B/Sub/b2" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a2"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/a3"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/a4"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/SubSub/a5"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub2/a6"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("B/b1"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("B/Sub/b2"));

        // Download All file in the directory A/Sub
        // (as in Folder.downloadVirtualFile)
        fakeFolder.syncJournal ().markVirtualFileForDownloadRecursively ("A/Sub");

        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a2" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/a3" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/a4" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/SubSub/a5" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub2/a6" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("B/b1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("B/Sub/b2" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a2"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/a3"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/a4"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/SubSub/a5"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub2/a6"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("B/b1"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("B/Sub/b2"));

        // Add a file in a subfolder that was downloaded
        // Currently, this continue to add it as a virtual file.
        fakeFolder.remoteModifier ().insert ("A/Sub/SubSub/a7");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/SubSub/a7" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/SubSub/a7"));

        // Now download all files in "A"
        fakeFolder.syncJournal ().markVirtualFileForDownloadRecursively ("A");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a2" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/a3" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/a4" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/SubSub/a5" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub2/a6" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/Sub/SubSub/a7" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("B/b1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("B/Sub/b2" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a2"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/a3"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/a4"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/SubSub/a5"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub2/a6"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/Sub/SubSub/a7"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("B/b1"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("B/Sub/b2"));

        // Now download remaining files in "B"
        fakeFolder.syncJournal ().markVirtualFileForDownloadRecursively ("B");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_rename_to_virtual () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        ItemCompletedSpy completeSpy (fakeFolder);

        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }
        on_signal_cleanup ();

        // If a file is renamed to <name>.owncloud, it becomes virtual
        fakeFolder.localModifier ().rename ("A/a1", "A/a1" DVSUFFIX);
        // If a file is renamed to <random>.owncloud, the rename propagates but the
        // file isn't made virtual the first sync run.
        fakeFolder.localModifier ().rename ("A/a2", "A/rand" DVSUFFIX);
        // dangling virtual files are removed
        fakeFolder.localModifier ().insert ("A/dangling" DVSUFFIX, 1, ' ');
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX).size <= 1);
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_SYNC));
        QCOMPARE (dbRecord (fakeFolder, "A/a1" DVSUFFIX).type, ItemTypeVirtualFile);
        QVERIFY (!dbRecord (fakeFolder, "A/a1").isValid ());

        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a2"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a2" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/rand"));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("A/a2"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/rand"));
        QVERIFY (itemInstruction (completeSpy, "A/rand", CSYNC_INSTRUCTION_RENAME));
        QVERIFY (dbRecord (fakeFolder, "A/rand").type == ItemTypeFile);

        QVERIFY (!fakeFolder.currentLocalState ().find ("A/dangling" DVSUFFIX));
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_rename_virtual () {
        FakeFolder fakeFolder{ FileInfo () };
        setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        ItemCompletedSpy completeSpy (fakeFolder);

        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }
        on_signal_cleanup ();

        fakeFolder.remoteModifier ().insert ("file1", 128, 'C');
        fakeFolder.remoteModifier ().insert ("file2", 256, 'C');
        fakeFolder.remoteModifier ().insert ("file3", 256, 'C');
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentLocalState ().find ("file1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("file2" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("file3" DVSUFFIX));
        on_signal_cleanup ();

        fakeFolder.localModifier ().rename ("file1" DVSUFFIX, "renamed1" DVSUFFIX);
        fakeFolder.localModifier ().rename ("file2" DVSUFFIX, "renamed2" DVSUFFIX);
        triggerDownload (fakeFolder, "file2");
        triggerDownload (fakeFolder, "file3");
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (!fakeFolder.currentLocalState ().find ("file1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("renamed1" DVSUFFIX));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("file1"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("renamed1"));
        QVERIFY (itemInstruction (completeSpy, "renamed1" DVSUFFIX, CSYNC_INSTRUCTION_RENAME));
        QVERIFY (dbRecord (fakeFolder, "renamed1" DVSUFFIX).isValid ());

        // file2 has a conflict between the download request and the rename:
        // the rename wins, the download is ignored
        QVERIFY (!fakeFolder.currentLocalState ().find ("file2"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("file2" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("renamed2" DVSUFFIX));
        QVERIFY (fakeFolder.currentRemoteState ().find ("renamed2"));
        QVERIFY (itemInstruction (completeSpy, "renamed2" DVSUFFIX, CSYNC_INSTRUCTION_RENAME));
        QVERIFY (dbRecord (fakeFolder, "renamed2" DVSUFFIX).type == ItemTypeVirtualFile);

        QVERIFY (itemInstruction (completeSpy, "file3", CSYNC_INSTRUCTION_SYNC));
        QVERIFY (dbRecord (fakeFolder, "file3").type == ItemTypeFile);
        on_signal_cleanup ();

        // Test rename while adding/removing vfs suffix
        fakeFolder.localModifier ().rename ("renamed1" DVSUFFIX, "R1");
        // Contents of file2 could also change at the same time...
        fakeFolder.localModifier ().rename ("file3", "R3" DVSUFFIX);
        QVERIFY (fakeFolder.syncOnce ());
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_rename_virtual2 () {
        FakeFolder fakeFolder{ FileInfo () };
        setupVfs (fakeFolder);
        ItemCompletedSpy completeSpy (fakeFolder);
        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }
        on_signal_cleanup ();

        fakeFolder.remoteModifier ().insert ("case3", 128, 'C');
        fakeFolder.remoteModifier ().insert ("case4", 256, 'C');
        fakeFolder.remoteModifier ().insert ("case5", 256, 'C');
        fakeFolder.remoteModifier ().insert ("case6", 256, 'C');
        QVERIFY (fakeFolder.syncOnce ());

        triggerDownload (fakeFolder, "case4");
        triggerDownload (fakeFolder, "case6");
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentLocalState ().find ("case3" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("case4"));
        QVERIFY (fakeFolder.currentLocalState ().find ("case5" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("case6"));
        on_signal_cleanup ();

        // Case 1 : foo . bar (tested elsewhere)
        // Case 2 : foo.oc . bar.oc (tested elsewhere)

        // Case 3 : foo.oc . bar (database unchanged)
        fakeFolder.localModifier ().rename ("case3" DVSUFFIX, "case3-rename");

        // Case 4 : foo . bar.oc (database unchanged)
        fakeFolder.localModifier ().rename ("case4", "case4-rename" DVSUFFIX);

        // Case 5 : foo.oc . bar.oc (database hydrate)
        fakeFolder.localModifier ().rename ("case5" DVSUFFIX, "case5-rename" DVSUFFIX);
        triggerDownload (fakeFolder, "case5");

        // Case 6 : foo . bar (database dehydrate)
        fakeFolder.localModifier ().rename ("case6", "case6-rename");
        markForDehydration (fakeFolder, "case6");

        QVERIFY (fakeFolder.syncOnce ());

        // Case 3 : the rename went though, hydration is forgotten
        QVERIFY (!fakeFolder.currentLocalState ().find ("case3"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("case3" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("case3-rename"));
        QVERIFY (fakeFolder.currentLocalState ().find ("case3-rename" DVSUFFIX));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("case3"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("case3-rename"));
        QVERIFY (itemInstruction (completeSpy, "case3-rename" DVSUFFIX, CSYNC_INSTRUCTION_RENAME));
        QVERIFY (dbRecord (fakeFolder, "case3-rename" DVSUFFIX).type == ItemTypeVirtualFile);

        // Case 4 : the rename went though, dehydration is forgotten
        QVERIFY (!fakeFolder.currentLocalState ().find ("case4"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("case4" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("case4-rename"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("case4-rename" DVSUFFIX));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("case4"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("case4-rename"));
        QVERIFY (itemInstruction (completeSpy, "case4-rename", CSYNC_INSTRUCTION_RENAME));
        QVERIFY (dbRecord (fakeFolder, "case4-rename").type == ItemTypeFile);

        // Case 5 : the rename went though, hydration is forgotten
        QVERIFY (!fakeFolder.currentLocalState ().find ("case5"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("case5" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("case5-rename"));
        QVERIFY (fakeFolder.currentLocalState ().find ("case5-rename" DVSUFFIX));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("case5"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("case5-rename"));
        QVERIFY (itemInstruction (completeSpy, "case5-rename" DVSUFFIX, CSYNC_INSTRUCTION_RENAME));
        QVERIFY (dbRecord (fakeFolder, "case5-rename" DVSUFFIX).type == ItemTypeVirtualFile);

        // Case 6 : the rename went though, dehydration is forgotten
        QVERIFY (!fakeFolder.currentLocalState ().find ("case6"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("case6" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("case6-rename"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("case6-rename" DVSUFFIX));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("case6"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("case6-rename"));
        QVERIFY (itemInstruction (completeSpy, "case6-rename", CSYNC_INSTRUCTION_RENAME));
        QVERIFY (dbRecord (fakeFolder, "case6-rename").type == ItemTypeFile);
    }

    // Dehydration via sync works
    private void on_signal_test_sync_dehydration () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        setupVfs (fakeFolder);

        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        ItemCompletedSpy completeSpy (fakeFolder);
        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }
        on_signal_cleanup ();

        //
        // Mark for dehydration and check
        //

        markForDehydration (fakeFolder, "A/a1");

        markForDehydration (fakeFolder, "A/a2");
        fakeFolder.remoteModifier ().appendByte ("A/a2");
        // expect : normal dehydration

        markForDehydration (fakeFolder, "B/b1");
        fakeFolder.remoteModifier ().remove ("B/b1");
        // expect : local removal

        markForDehydration (fakeFolder, "B/b2");
        fakeFolder.remoteModifier ().rename ("B/b2", "B/b3");
        // expect : B/b2 is gone, B/b3 is NEW placeholder

        markForDehydration (fakeFolder, "C/c1");
        fakeFolder.localModifier ().appendByte ("C/c1");
        // expect : no dehydration, upload of c1

        markForDehydration (fakeFolder, "C/c2");
        fakeFolder.localModifier ().appendByte ("C/c2");
        fakeFolder.remoteModifier ().appendByte ("C/c2");
        fakeFolder.remoteModifier ().appendByte ("C/c2");
        // expect : no dehydration, conflict

        QVERIFY (fakeFolder.syncOnce ());

        var isDehydrated = [&] (string path) {
            string placeholder = path + DVSUFFIX;
            return !fakeFolder.currentLocalState ().find (path)
                && fakeFolder.currentLocalState ().find (placeholder);
        }
        var hasDehydratedDbEntries = [&] (string path) {
            SyncJournalFileRecord normal, suffix;
            fakeFolder.syncJournal ().getFileRecord (path, normal);
            fakeFolder.syncJournal ().getFileRecord (path + DVSUFFIX, suffix);
            return !normal.isValid () && suffix.isValid () && suffix.type == ItemTypeVirtualFile;
        }

        QVERIFY (isDehydrated ("A/a1"));
        QVERIFY (hasDehydratedDbEntries ("A/a1"));
        QVERIFY (itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_SYNC));
        QCOMPARE (completeSpy.findItem ("A/a1" DVSUFFIX).type, ItemTypeVirtualFileDehydration);
        QCOMPARE (completeSpy.findItem ("A/a1" DVSUFFIX).file, QStringLiteral ("A/a1"));
        QCOMPARE (completeSpy.findItem ("A/a1" DVSUFFIX).renameTarget, QStringLiteral ("A/a1" DVSUFFIX));
        QVERIFY (isDehydrated ("A/a2"));
        QVERIFY (hasDehydratedDbEntries ("A/a2"));
        QVERIFY (itemInstruction (completeSpy, "A/a2" DVSUFFIX, CSYNC_INSTRUCTION_SYNC));
        QCOMPARE (completeSpy.findItem ("A/a2" DVSUFFIX).type, ItemTypeVirtualFileDehydration);

        QVERIFY (!fakeFolder.currentLocalState ().find ("B/b1"));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("B/b1"));
        QVERIFY (itemInstruction (completeSpy, "B/b1", CSYNC_INSTRUCTION_REMOVE));

        QVERIFY (!fakeFolder.currentLocalState ().find ("B/b2"));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("B/b2"));
        QVERIFY (isDehydrated ("B/b3"));
        QVERIFY (hasDehydratedDbEntries ("B/b3"));
        QVERIFY (itemInstruction (completeSpy, "B/b2", CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (itemInstruction (completeSpy, "B/b3" DVSUFFIX, CSYNC_INSTRUCTION_NEW));

        QCOMPARE (fakeFolder.currentRemoteState ().find ("C/c1").size, 25);
        QVERIFY (itemInstruction (completeSpy, "C/c1", CSYNC_INSTRUCTION_SYNC));

        QCOMPARE (fakeFolder.currentRemoteState ().find ("C/c2").size, 26);
        QVERIFY (itemInstruction (completeSpy, "C/c2", CSYNC_INSTRUCTION_CONFLICT));
        on_signal_cleanup ();

        var expectedLocalState = fakeFolder.currentLocalState ();
        var expectedRemoteState = fakeFolder.currentRemoteState ();
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), expectedLocalState);
        QCOMPARE (fakeFolder.currentRemoteState (), expectedRemoteState);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_wipe_virtual_suffix_files () {
        FakeFolder fakeFolder{ FileInfo{} };
        setupVfs (fakeFolder);

        // Create a suffix-vfs baseline

        fakeFolder.remoteModifier ().mkdir ("A");
        fakeFolder.remoteModifier ().mkdir ("A/B");
        fakeFolder.remoteModifier ().insert ("f1");
        fakeFolder.remoteModifier ().insert ("A/a1");
        fakeFolder.remoteModifier ().insert ("A/a3");
        fakeFolder.remoteModifier ().insert ("A/B/b1");
        fakeFolder.localModifier ().mkdir ("A");
        fakeFolder.localModifier ().mkdir ("A/B");
        fakeFolder.localModifier ().insert ("f2");
        fakeFolder.localModifier ().insert ("A/a2");
        fakeFolder.localModifier ().insert ("A/B/b2");

        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentLocalState ().find ("f1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a3" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/B/b1" DVSUFFIX));

        // Make local changes to a3
        fakeFolder.localModifier ().remove ("A/a3" DVSUFFIX);
        fakeFolder.localModifier ().insert ("A/a3" DVSUFFIX, 100);

        // Now wipe the virtuals

        SyncEngine.wipeVirtualFiles (fakeFolder.localPath (), fakeFolder.syncJournal (), *fakeFolder.syncEngine ().syncOptions ().vfs);

        QVERIFY (!fakeFolder.currentLocalState ().find ("f1" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a3" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/B/b1" DVSUFFIX));

        fakeFolder.switchToVfs (unowned<Vfs> (new VfsOff));
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a3" DVSUFFIX)); // regular upload
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_new_virtuals () {
        FakeFolder fakeFolder{ FileInfo () };
        setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        var setPin = [&] (GLib.ByteArray path, PinState state) {
            fakeFolder.syncJournal ().internalPinStates ().setForPath (path, state);
        }

        fakeFolder.remoteModifier ().mkdir ("local");
        fakeFolder.remoteModifier ().mkdir ("online");
        fakeFolder.remoteModifier ().mkdir ("unspec");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        setPin ("local", PinState.PinState.ALWAYS_LOCAL);
        setPin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        setPin ("unspec", PinState.PinState.UNSPECIFIED);

        // Test 1 : root is PinState.UNSPECIFIED
        fakeFolder.remoteModifier ().insert ("file1");
        fakeFolder.remoteModifier ().insert ("online/file1");
        fakeFolder.remoteModifier ().insert ("local/file1");
        fakeFolder.remoteModifier ().insert ("unspec/file1");
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentLocalState ().find ("file1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("online/file1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("local/file1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("unspec/file1" DVSUFFIX));

        // Test 2 : change root to PinState.ALWAYS_LOCAL
        setPin ("", PinState.PinState.ALWAYS_LOCAL);

        fakeFolder.remoteModifier ().insert ("file2");
        fakeFolder.remoteModifier ().insert ("online/file2");
        fakeFolder.remoteModifier ().insert ("local/file2");
        fakeFolder.remoteModifier ().insert ("unspec/file2");
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentLocalState ().find ("file2"));
        QVERIFY (fakeFolder.currentLocalState ().find ("online/file2" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("local/file2"));
        QVERIFY (fakeFolder.currentLocalState ().find ("unspec/file2" DVSUFFIX));

        // root file1 was hydrated due to its new pin state
        QVERIFY (fakeFolder.currentLocalState ().find ("file1"));

        // file1 is unchanged in the explicitly pinned subfolders
        QVERIFY (fakeFolder.currentLocalState ().find ("online/file1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("local/file1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("unspec/file1" DVSUFFIX));

        // Test 3 : change root to VfsItemAvailability.ONLINE_ONLY
        setPin ("", PinState.VfsItemAvailability.ONLINE_ONLY);

        fakeFolder.remoteModifier ().insert ("file3");
        fakeFolder.remoteModifier ().insert ("online/file3");
        fakeFolder.remoteModifier ().insert ("local/file3");
        fakeFolder.remoteModifier ().insert ("unspec/file3");
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentLocalState ().find ("file3" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("online/file3" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("local/file3"));
        QVERIFY (fakeFolder.currentLocalState ().find ("unspec/file3" DVSUFFIX));

        // root file1 was dehydrated due to its new pin state
        QVERIFY (fakeFolder.currentLocalState ().find ("file1" DVSUFFIX));

        // file1 is unchanged in the explicitly pinned subfolders
        QVERIFY (fakeFolder.currentLocalState ().find ("online/file1" DVSUFFIX));
        QVERIFY (fakeFolder.currentLocalState ().find ("local/file1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("unspec/file1" DVSUFFIX));
    }

    // Check what happens if vfs-suffixed files exist on the server or locally
    // while the file is hydrated
    private void on_signal_test_suffix_files_while_local_hydrated () {
        FakeFolder fakeFolder{ FileInfo () };

        ItemCompletedSpy completeSpy (fakeFolder);
        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }
        on_signal_cleanup ();

        // suffixed files are happily synced with Vfs.Off
        fakeFolder.remoteModifier ().mkdir ("A");
        fakeFolder.remoteModifier ().insert ("A/test1" DVSUFFIX, 10, 'A');
        fakeFolder.remoteModifier ().insert ("A/test2" DVSUFFIX, 20, 'A');
        fakeFolder.remoteModifier ().insert ("A/file1" DVSUFFIX, 30, 'A');
        fakeFolder.remoteModifier ().insert ("A/file2", 40, 'A');
        fakeFolder.remoteModifier ().insert ("A/file2" DVSUFFIX, 50, 'A');
        fakeFolder.remoteModifier ().insert ("A/file3", 60, 'A');
        fakeFolder.remoteModifier ().insert ("A/file3" DVSUFFIX, 70, 'A');
        fakeFolder.remoteModifier ().insert ("A/file3" DVSUFFIX DVSUFFIX, 80, 'A');
        fakeFolder.remoteModifier ().insert ("A/remote1" DVSUFFIX, 30, 'A');
        fakeFolder.remoteModifier ().insert ("A/remote2", 40, 'A');
        fakeFolder.remoteModifier ().insert ("A/remote2" DVSUFFIX, 50, 'A');
        fakeFolder.remoteModifier ().insert ("A/remote3", 60, 'A');
        fakeFolder.remoteModifier ().insert ("A/remote3" DVSUFFIX, 70, 'A');
        fakeFolder.remoteModifier ().insert ("A/remote3" DVSUFFIX DVSUFFIX, 80, 'A');
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        on_signal_cleanup ();

        // Enable suffix vfs
        setupVfs (fakeFolder);

        // A simple sync removes the files that are now ignored (?)
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file2" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file3" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // Add a real file where the suffixed file exists
        fakeFolder.localModifier ().insert ("A/test1", 11, 'A');
        fakeFolder.remoteModifier ().insert ("A/test2", 21, 'A');
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/test1", CSYNC_INSTRUCTION_NEW));
        // this isn't fully good since some code requires size == 1 for placeholders
        // (when renaming placeholder to real file). But the alternative would mean
        // special casing this to allow CONFLICT at virtual file creation level. Ew.
        QVERIFY (itemInstruction (completeSpy, "A/test2" DVSUFFIX, CSYNC_INSTRUCTION_UPDATE_METADATA));
        on_signal_cleanup ();

        // Local changes of suffixed file do nothing
        fakeFolder.localModifier ().setContents ("A/file1" DVSUFFIX, 'B');
        fakeFolder.localModifier ().setContents ("A/file2" DVSUFFIX, 'B');
        fakeFolder.localModifier ().setContents ("A/file3" DVSUFFIX, 'B');
        fakeFolder.localModifier ().setContents ("A/file3" DVSUFFIX DVSUFFIX, 'B');
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file2" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file3" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // Remote changes don't do anything either
        fakeFolder.remoteModifier ().setContents ("A/file1" DVSUFFIX, 'C');
        fakeFolder.remoteModifier ().setContents ("A/file2" DVSUFFIX, 'C');
        fakeFolder.remoteModifier ().setContents ("A/file3" DVSUFFIX, 'C');
        fakeFolder.remoteModifier ().setContents ("A/file3" DVSUFFIX DVSUFFIX, 'C');
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file2" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file3" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // Local removal : when not querying server
        fakeFolder.localModifier ().remove ("A/file1" DVSUFFIX);
        fakeFolder.localModifier ().remove ("A/file2" DVSUFFIX);
        fakeFolder.localModifier ().remove ("A/file3" DVSUFFIX);
        fakeFolder.localModifier ().remove ("A/file3" DVSUFFIX DVSUFFIX);
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (completeSpy.findItem ("A/file1" DVSUFFIX).isEmpty ());
        QVERIFY (completeSpy.findItem ("A/file2" DVSUFFIX).isEmpty ());
        QVERIFY (completeSpy.findItem ("A/file3" DVSUFFIX).isEmpty ());
        QVERIFY (completeSpy.findItem ("A/file3" DVSUFFIX DVSUFFIX).isEmpty ());
        on_signal_cleanup ();

        // Local removal : when querying server
        fakeFolder.remoteModifier ().setContents ("A/file1" DVSUFFIX, 'D');
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file2" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file3" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // Remote removal
        fakeFolder.remoteModifier ().remove ("A/remote1" DVSUFFIX);
        fakeFolder.remoteModifier ().remove ("A/remote2" DVSUFFIX);
        fakeFolder.remoteModifier ().remove ("A/remote3" DVSUFFIX);
        fakeFolder.remoteModifier ().remove ("A/remote3" DVSUFFIX DVSUFFIX);
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/remote1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/remote2" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/remote3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/remote3" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // New files with a suffix aren't propagated downwards in the first place
        fakeFolder.remoteModifier ().insert ("A/new1" DVSUFFIX);
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/new1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/new1" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/new1"));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/new1" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/new1" DVSUFFIX DVSUFFIX));
        on_signal_cleanup ();
    }

    // Check what happens if vfs-suffixed files exist on the server or in the database
    private void on_signal_test_extra_files_local_dehydrated () {
        FakeFolder fakeFolder{ FileInfo () };
        setupVfs (fakeFolder);

        ItemCompletedSpy completeSpy (fakeFolder);
        var on_signal_cleanup = [&] () {
            completeSpy.clear ();
        }
        on_signal_cleanup ();

        // create a bunch of local virtual files, in some instances
        // ignore remote files
        fakeFolder.remoteModifier ().mkdir ("A");
        fakeFolder.remoteModifier ().insert ("A/file1", 30, 'A');
        fakeFolder.remoteModifier ().insert ("A/file2", 40, 'A');
        fakeFolder.remoteModifier ().insert ("A/file3", 60, 'A');
        fakeFolder.remoteModifier ().insert ("A/file3" DVSUFFIX, 70, 'A');
        fakeFolder.remoteModifier ().insert ("A/file4", 80, 'A');
        fakeFolder.remoteModifier ().insert ("A/file4" DVSUFFIX, 90, 'A');
        fakeFolder.remoteModifier ().insert ("A/file4" DVSUFFIX DVSUFFIX, 100, 'A');
        fakeFolder.remoteModifier ().insert ("A/file5", 110, 'A');
        fakeFolder.remoteModifier ().insert ("A/file6", 120, 'A');
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/file1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/file1" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/file2"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/file2" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/file3"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/file3" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/file4"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/file4" DVSUFFIX));
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/file4" DVSUFFIX DVSUFFIX));
        QVERIFY (itemInstruction (completeSpy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemInstruction (completeSpy, "A/file2" DVSUFFIX, CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemInstruction (completeSpy, "A/file3" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file4" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file4" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();

        // Create odd extra files locally and remotely
        fakeFolder.localModifier ().insert ("A/file1", 10, 'A');
        fakeFolder.localModifier ().insert ("A/file2" DVSUFFIX DVSUFFIX, 10, 'A');
        fakeFolder.remoteModifier ().insert ("A/file5" DVSUFFIX, 10, 'A');
        fakeFolder.localModifier ().insert ("A/file6", 10, 'A');
        fakeFolder.remoteModifier ().insert ("A/file6" DVSUFFIX, 10, 'A');
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/file1", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "A/file1" DVSUFFIX, CSYNC_INSTRUCTION_REMOVE)); // it's now a pointless real virtual file
        QVERIFY (itemInstruction (completeSpy, "A/file2" DVSUFFIX DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file5" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/file6", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "A/file6" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_availability () {
        FakeFolder fakeFolder{ FileInfo () };
        var vfs = setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        var setPin = [&] (GLib.ByteArray path, PinState state) {
            fakeFolder.syncJournal ().internalPinStates ().setForPath (path, state);
        }

        fakeFolder.remoteModifier ().mkdir ("local");
        fakeFolder.remoteModifier ().mkdir ("local/sub");
        fakeFolder.remoteModifier ().mkdir ("online");
        fakeFolder.remoteModifier ().mkdir ("online/sub");
        fakeFolder.remoteModifier ().mkdir ("unspec");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        setPin ("local", PinState.PinState.ALWAYS_LOCAL);
        setPin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        setPin ("unspec", PinState.PinState.UNSPECIFIED);

        fakeFolder.remoteModifier ().insert ("file1");
        fakeFolder.remoteModifier ().insert ("online/file1");
        fakeFolder.remoteModifier ().insert ("online/file2");
        fakeFolder.remoteModifier ().insert ("local/file1");
        fakeFolder.remoteModifier ().insert ("local/file2");
        fakeFolder.remoteModifier ().insert ("unspec/file1");
        QVERIFY (fakeFolder.syncOnce ());

        // root is unspecified
        QCOMPARE (*vfs.availability ("file1" DVSUFFIX), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);
        QCOMPARE (*vfs.availability ("local"), VfsItemAvailability.PinState.ALWAYS_LOCAL);
        QCOMPARE (*vfs.availability ("local/file1"), VfsItemAvailability.PinState.ALWAYS_LOCAL);
        QCOMPARE (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        QCOMPARE (*vfs.availability ("online/file1" DVSUFFIX), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        QCOMPARE (*vfs.availability ("unspec"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);
        QCOMPARE (*vfs.availability ("unspec/file1" DVSUFFIX), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);

        // Subitem pin states can ruin "pure" availabilities
        setPin ("local/sub", PinState.VfsItemAvailability.ONLINE_ONLY);
        QCOMPARE (*vfs.availability ("local"), VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED);
        setPin ("online/sub", PinState.PinState.UNSPECIFIED);
        QCOMPARE (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);

        triggerDownload (fakeFolder, "unspec/file1");
        setPin ("local/file2", PinState.VfsItemAvailability.ONLINE_ONLY);
        setPin ("online/file2" DVSUFFIX, PinState.PinState.ALWAYS_LOCAL);
        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (*vfs.availability ("unspec"), VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED);
        QCOMPARE (*vfs.availability ("local"), VfsItemAvailability.VfsItemAvailability.MIXED);
        QCOMPARE (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.MIXED);

        QVERIFY (vfs.setPinState ("local", PinState.PinState.ALWAYS_LOCAL));
        QVERIFY (vfs.setPinState ("online", PinState.VfsItemAvailability.ONLINE_ONLY));
        QVERIFY (fakeFolder.syncOnce ());

        QCOMPARE (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        QCOMPARE (*vfs.availability ("local"), VfsItemAvailability.PinState.ALWAYS_LOCAL);

        var r = vfs.availability ("nonexistant");
        QVERIFY (!r);
        QCOMPARE (r.error (), Vfs.AvailabilityError.NO_SUCH_ITEM);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_pin_state_locals () {
        FakeFolder fakeFolder{ FileInfo () };
        var vfs = setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        var setPin = [&] (GLib.ByteArray path, PinState state) {
            fakeFolder.syncJournal ().internalPinStates ().setForPath (path, state);
        }

        fakeFolder.remoteModifier ().mkdir ("local");
        fakeFolder.remoteModifier ().mkdir ("online");
        fakeFolder.remoteModifier ().mkdir ("unspec");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        setPin ("local", PinState.PinState.ALWAYS_LOCAL);
        setPin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        setPin ("unspec", PinState.PinState.UNSPECIFIED);

        fakeFolder.localModifier ().insert ("file1");
        fakeFolder.localModifier ().insert ("online/file1");
        fakeFolder.localModifier ().insert ("online/file2");
        fakeFolder.localModifier ().insert ("local/file1");
        fakeFolder.localModifier ().insert ("unspec/file1");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // root is unspecified
        QCOMPARE (*vfs.pinState ("file1" DVSUFFIX), PinState.PinState.UNSPECIFIED);
        QCOMPARE (*vfs.pinState ("local/file1"), PinState.PinState.ALWAYS_LOCAL);
        QCOMPARE (*vfs.pinState ("online/file1"), PinState.PinState.UNSPECIFIED);
        QCOMPARE (*vfs.pinState ("unspec/file1"), PinState.PinState.UNSPECIFIED);

        // Sync again : bad pin states of new local files usually take effect on second sync
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // When a file in an online-only folder is renamed, it retains its pin
        fakeFolder.localModifier ().rename ("online/file1", "online/file1rename");
        fakeFolder.remoteModifier ().rename ("online/file2", "online/file2rename");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (*vfs.pinState ("online/file1rename"), PinState.PinState.UNSPECIFIED);
        QCOMPARE (*vfs.pinState ("online/file2rename"), PinState.PinState.UNSPECIFIED);

        // When a folder is renamed, the pin states inside should be retained
        fakeFolder.localModifier ().rename ("online", "onlinerenamed1");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (*vfs.pinState ("onlinerenamed1"), PinState.VfsItemAvailability.ONLINE_ONLY);
        QCOMPARE (*vfs.pinState ("onlinerenamed1/file1rename"), PinState.PinState.UNSPECIFIED);

        fakeFolder.remoteModifier ().rename ("onlinerenamed1", "onlinerenamed2");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (*vfs.pinState ("onlinerenamed2"), PinState.VfsItemAvailability.ONLINE_ONLY);
        QCOMPARE (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.PinState.UNSPECIFIED);

        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        // When a file is deleted and later a new file has the same name, the old pin
        // state isn't preserved.
        QCOMPARE (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.PinState.UNSPECIFIED);
        fakeFolder.remoteModifier ().remove ("onlinerenamed2/file1rename");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.VfsItemAvailability.ONLINE_ONLY);
        fakeFolder.remoteModifier ().insert ("onlinerenamed2/file1rename");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.VfsItemAvailability.ONLINE_ONLY);
        QCOMPARE (*vfs.pinState ("onlinerenamed2/file1rename" DVSUFFIX), PinState.VfsItemAvailability.ONLINE_ONLY);

        // When a file is hydrated or dehydrated due to pin state it retains its pin state
        QVERIFY (vfs.setPinState ("onlinerenamed2/file1rename" DVSUFFIX, PinState.PinState.ALWAYS_LOCAL));
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("onlinerenamed2/file1rename"));
        QCOMPARE (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.PinState.ALWAYS_LOCAL);

        QVERIFY (vfs.setPinState ("onlinerenamed2", PinState.PinState.UNSPECIFIED));
        QVERIFY (vfs.setPinState ("onlinerenamed2/file1rename", PinState.VfsItemAvailability.ONLINE_ONLY));
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("onlinerenamed2/file1rename" DVSUFFIX));
        QCOMPARE (*vfs.pinState ("onlinerenamed2/file1rename" DVSUFFIX), PinState.VfsItemAvailability.ONLINE_ONLY);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_incompatible_pins () {
        FakeFolder fakeFolder{ FileInfo () };
        var vfs = setupVfs (fakeFolder);
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        var setPin = [&] (GLib.ByteArray path, PinState state) {
            fakeFolder.syncJournal ().internalPinStates ().setForPath (path, state);
        }

        fakeFolder.remoteModifier ().mkdir ("local");
        fakeFolder.remoteModifier ().mkdir ("online");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());

        setPin ("local", PinState.PinState.ALWAYS_LOCAL);
        setPin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);

        fakeFolder.localModifier ().insert ("local/file1");
        fakeFolder.localModifier ().insert ("online/file1");
        QVERIFY (fakeFolder.syncOnce ());

        markForDehydration (fakeFolder, "local/file1");
        triggerDownload (fakeFolder, "online/file1");

        // the sync sets the changed files pin states to unspecified
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentLocalState ().find ("online/file1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("local/file1" DVSUFFIX));
        QCOMPARE (*vfs.pinState ("online/file1"), PinState.PinState.UNSPECIFIED);
        QCOMPARE (*vfs.pinState ("local/file1" DVSUFFIX), PinState.PinState.UNSPECIFIED);

        // no change on another sync
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("online/file1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("local/file1" DVSUFFIX));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_place_holder_exist () {
        FakeFolder fakeFolder{ FileInfo.A12_B12_C12_S12 () };
        fakeFolder.remoteModifier ().insert ("A/a1" DVSUFFIX, 111);
        fakeFolder.remoteModifier ().insert ("A/hello" DVSUFFIX, 222);
        QVERIFY (fakeFolder.syncOnce ());
        var vfs = setupVfs (fakeFolder);

        ItemCompletedSpy completeSpy (fakeFolder);
        var on_signal_cleanup = [&] () { completeSpy.clear (); };
        on_signal_cleanup ();

        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QVERIFY (itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/hello" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));

        fakeFolder.remoteModifier ().insert ("A/a2" DVSUFFIX);
        fakeFolder.remoteModifier ().insert ("A/hello", 12);
        fakeFolder.localModifier ().insert ("A/igno" DVSUFFIX, 123);
        on_signal_cleanup ();
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/a1" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        QVERIFY (itemInstruction (completeSpy, "A/igno" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));

        // verify that the files are still present
        QCOMPARE (fakeFolder.currentLocalState ().find ("A/hello" DVSUFFIX).size, 222);
        QCOMPARE (*fakeFolder.currentLocalState ().find ("A/hello" DVSUFFIX),
                 *fakeFolder.currentRemoteState ().find ("A/hello" DVSUFFIX));
        QCOMPARE (fakeFolder.currentLocalState ().find ("A/igno" DVSUFFIX).size, 123);

        on_signal_cleanup ();
        // Dehydrate
        QVERIFY (vfs.setPinState ("", PinState.VfsItemAvailability.ONLINE_ONLY));
        QVERIFY (!fakeFolder.syncOnce ());

        QVERIFY (itemInstruction (completeSpy, "A/igno" DVSUFFIX, CSYNC_INSTRUCTION_IGNORE));
        // verify that the files are still present
        QCOMPARE (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX).size, 111);
        QCOMPARE (fakeFolder.currentLocalState ().find ("A/hello" DVSUFFIX).size, 222);
        QCOMPARE (*fakeFolder.currentLocalState ().find ("A/hello" DVSUFFIX),
                 *fakeFolder.currentRemoteState ().find ("A/hello" DVSUFFIX));
        QCOMPARE (*fakeFolder.currentLocalState ().find ("A/a1"),
                 *fakeFolder.currentRemoteState ().find ("A/a1"));
        QCOMPARE (fakeFolder.currentLocalState ().find ("A/igno" DVSUFFIX).size, 123);

        // Now disable vfs and check that all files are still there
        on_signal_cleanup ();
        SyncEngine.wipeVirtualFiles (fakeFolder.localPath (), fakeFolder.syncJournal (), *vfs);
        fakeFolder.switchToVfs (unowned<Vfs> (new VfsOff));
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
        QCOMPARE (fakeFolder.currentLocalState ().find ("A/a1" DVSUFFIX).size, 111);
        QCOMPARE (fakeFolder.currentLocalState ().find ("A/hello").size, 12);
        QCOMPARE (fakeFolder.currentLocalState ().find ("A/hello" DVSUFFIX).size, 222);
        QCOMPARE (fakeFolder.currentLocalState ().find ("A/igno" DVSUFFIX).size, 123);
    }
}

QTEST_GUILESS_MAIN (TestSyncVirtualFiles)