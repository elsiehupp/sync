/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

namespace xattr {
using namespace Occ.XAttrWrapper;
}

const int XAVERIFY_VIRTUAL (folder, path)
    QVERIFY (QFileInfo ( (folder).localPath () + (path)).exists ());
    QCOMPARE (QFileInfo ( (folder).localPath () + (path)).size (), 1);
    QVERIFY (xattr.hasNextcloudPlaceholderAttributes ( (folder).localPath () + (path)));
    QVERIFY (dbRecord ( (folder), (path)).isValid ());
    QCOMPARE (dbRecord ( (folder), (path)).type, ItemTypeVirtualFile);

const int XAVERIFY_NONVIRTUAL (folder, path)
    QVERIFY (QFileInfo ( (folder).localPath () + (path)).exists ());
    QVERIFY (!xattr.hasNextcloudPlaceholderAttributes ( (folder).localPath () + (path)));
    QVERIFY (dbRecord ( (folder), (path)).isValid ());
    QCOMPARE (dbRecord ( (folder), (path)).type, ItemTypeFile);

const int CFVERIFY_GONE (folder, path)
    QVERIFY (!QFileInfo ( (folder).localPath () + (path)).exists ());
    QVERIFY (!dbRecord ( (folder), (path)).isValid ());

using namespace Occ;

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
    journal.getFileRecord (path, record);
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
    var xattrVfs = unowned<Vfs> (createVfsFromPlugin (Vfs.XAttr).release ());
    GLib.Object.connect (&folder.syncEngine ().syncFileStatusTracker (), &SyncFileStatusTracker.fileStatusChanged,
                     xattrVfs.data (), &Vfs.fileStatusChanged);
    folder.switchToVfs (xattrVfs);

    // Using this directly doesn't recursively unpin everything and instead leaves
    // the files in the hydration that that they on_signal_start with
    folder.syncJournal ().internalPinStates ().setForPath (GLib.ByteArray (), PinState.PinState.UNSPECIFIED);

    return xattrVfs;
}

class TestSyncXAttr : GLib.Object {

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
        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        QCOMPARE (dbRecord (fakeFolder, "A/a1").fileSize, 64);
        QCOMPARE (QFileInfo (fakeFolder.localPath () + "A/a1").lastModified (), someDate);
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_NEW));
        on_signal_cleanup ();

        // Another sync doesn't actually lead to changes
        QVERIFY (fakeFolder.syncOnce ());
        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        QCOMPARE (dbRecord (fakeFolder, "A/a1").fileSize, 64);
        QCOMPARE (QFileInfo (fakeFolder.localPath () + "A/a1").lastModified (), someDate);
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (completeSpy.isEmpty ());
        on_signal_cleanup ();

        // Not even when the remote is rediscovered
        fakeFolder.syncJournal ().forceRemoteDiscoveryNextSync ();
        QVERIFY (fakeFolder.syncOnce ());
        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        QCOMPARE (dbRecord (fakeFolder, "A/a1").fileSize, 64);
        QCOMPARE (QFileInfo (fakeFolder.localPath () + "A/a1").lastModified (), someDate);
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (completeSpy.isEmpty ());
        on_signal_cleanup ();

        // Neither does a remote change
        fakeFolder.remoteModifier ().appendByte ("A/a1");
        QVERIFY (fakeFolder.syncOnce ());
        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        QCOMPARE (dbRecord (fakeFolder, "A/a1").fileSize, 65);
        QCOMPARE (QFileInfo (fakeFolder.localPath () + "A/a1").lastModified (), someDate);
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_UPDATE_METADATA));
        QCOMPARE (dbRecord (fakeFolder, "A/a1").fileSize, 65);
        on_signal_cleanup ();

        // If the local virtual file is removed, this will be propagated remotely
        if (!doLocalDiscovery)
            fakeFolder.syncEngine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });
        fakeFolder.localModifier ().remove ("A/a1");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (!fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (!dbRecord (fakeFolder, "A/a1").isValid ());
        on_signal_cleanup ();

        // Recreate a1 before carrying on with the other tests
        fakeFolder.remoteModifier ().insert ("A/a1", 65);
        fakeFolder.remoteModifier ().setModTime ("A/a1", someDate);
        QVERIFY (fakeFolder.syncOnce ());
        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        QCOMPARE (dbRecord (fakeFolder, "A/a1").fileSize, 65);
        QCOMPARE (QFileInfo (fakeFolder.localPath () + "A/a1").lastModified (), someDate);
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_NEW));
        on_signal_cleanup ();

        // Remote rename is propagated
        fakeFolder.remoteModifier ().rename ("A/a1", "A/a1m");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!QFileInfo (fakeFolder.localPath () + "A/a1").exists ());
        XAVERIFY_VIRTUAL (fakeFolder, "A/a1m");
        QCOMPARE (dbRecord (fakeFolder, "A/a1m").fileSize, 65);
        QCOMPARE (QFileInfo (fakeFolder.localPath () + "A/a1m").lastModified (), someDate);
        QVERIFY (!fakeFolder.currentRemoteState ().find ("A/a1"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/a1m"));
        QVERIFY (
            itemInstruction (completeSpy, "A/a1m", CSYNC_INSTRUCTION_RENAME)
            || (itemInstruction (completeSpy, "A/a1m", CSYNC_INSTRUCTION_NEW)
                && itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_REMOVE)));
        QVERIFY (!dbRecord (fakeFolder, "A/a1").isValid ());
        on_signal_cleanup ();

        // Remote remove is propagated
        fakeFolder.remoteModifier ().remove ("A/a1m");
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (!QFileInfo (fakeFolder.localPath () + "A/a1m").exists ());
        QVERIFY (!fakeFolder.currentRemoteState ().find ("A/a1m"));
        QVERIFY (itemInstruction (completeSpy, "A/a1m", CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (!dbRecord (fakeFolder, "A/a1").isValid ());
        QVERIFY (!dbRecord (fakeFolder, "A/a1m").isValid ());
        on_signal_cleanup ();

        // Edge case : Local virtual file but no database entry for some reason
        fakeFolder.remoteModifier ().insert ("A/a2", 32);
        fakeFolder.remoteModifier ().insert ("A/a3", 33);
        QVERIFY (fakeFolder.syncOnce ());
        XAVERIFY_VIRTUAL (fakeFolder, "A/a2");
        QCOMPARE (dbRecord (fakeFolder, "A/a2").fileSize, 32);
        XAVERIFY_VIRTUAL (fakeFolder, "A/a3");
        QCOMPARE (dbRecord (fakeFolder, "A/a3").fileSize, 33);
        on_signal_cleanup ();

        fakeFolder.syncEngine ().journal ().deleteFileRecord ("A/a2");
        fakeFolder.syncEngine ().journal ().deleteFileRecord ("A/a3");
        fakeFolder.remoteModifier ().remove ("A/a3");
        fakeFolder.syncEngine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        QVERIFY (fakeFolder.syncOnce ());
        XAVERIFY_VIRTUAL (fakeFolder, "A/a2");
        QCOMPARE (dbRecord (fakeFolder, "A/a2").fileSize, 32);
        QVERIFY (itemInstruction (completeSpy, "A/a2", CSYNC_INSTRUCTION_UPDATE_METADATA));
        QVERIFY (!QFileInfo (fakeFolder.localPath () + "A/a3").exists ());
        QVERIFY (itemInstruction (completeSpy, "A/a3", CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (!dbRecord (fakeFolder, "A/a3").isValid ());
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
        fakeFolder.remoteModifier ().insert ("A/a1", 11);
        fakeFolder.remoteModifier ().insert ("A/a2", 12);
        fakeFolder.remoteModifier ().mkdir ("B");
        fakeFolder.remoteModifier ().insert ("B/b1", 21);
        QVERIFY (fakeFolder.syncOnce ());
        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a2");
        XAVERIFY_VIRTUAL (fakeFolder, "B/b1");
        QCOMPARE (dbRecord (fakeFolder, "A/a1").fileSize, 11);
        QCOMPARE (dbRecord (fakeFolder, "A/a2").fileSize, 12);
        QCOMPARE (dbRecord (fakeFolder, "B/b1").fileSize, 21);
        on_signal_cleanup ();

        // All the files are touched on the server
        fakeFolder.remoteModifier ().appendByte ("A/a1");
        fakeFolder.remoteModifier ().appendByte ("A/a2");
        fakeFolder.remoteModifier ().appendByte ("B/b1");

        // A : the correct file and a conflicting file are added
        // B : user adds a directory* locally
        fakeFolder.localModifier ().remove ("A/a1");
        fakeFolder.localModifier ().insert ("A/a1", 12);
        fakeFolder.localModifier ().remove ("A/a2");
        fakeFolder.localModifier ().insert ("A/a2", 10);
        fakeFolder.localModifier ().remove ("B/b1");
        fakeFolder.localModifier ().mkdir ("B/b1");
        fakeFolder.localModifier ().insert ("B/b1/foo");
        QVERIFY (fakeFolder.syncOnce ());

        // Everything is CONFLICT
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "A/a2", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "B/b1", CSYNC_INSTRUCTION_CONFLICT));

        // conflict files should exist
        QCOMPARE (fakeFolder.syncJournal ().conflictRecordPaths ().size (), 2);

        // nothing should have the virtual file tag
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a1");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a2");
        XAVERIFY_NONVIRTUAL (fakeFolder, "B/b1");

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
        fakeFolder.remoteModifier ().insert ("A/new", 42);
        QVERIFY (fakeFolder.syncOnce ());
        XAVERIFY_VIRTUAL (fakeFolder, "A/new");
        QCOMPARE (dbRecord (fakeFolder, "A/new").fileSize, 42);
        QVERIFY (fakeFolder.currentRemoteState ().find ("A/new"));
        QVERIFY (itemInstruction (completeSpy, "A/new", CSYNC_INSTRUCTION_NEW));
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

        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a2");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a3");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a4");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a5");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a6");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a7");
        XAVERIFY_VIRTUAL (fakeFolder, "A/b1");
        XAVERIFY_VIRTUAL (fakeFolder, "A/b2");
        XAVERIFY_VIRTUAL (fakeFolder, "A/b3");
        XAVERIFY_VIRTUAL (fakeFolder, "A/b4");

        on_signal_cleanup ();

        // Download by changing the database entry
        triggerDownload (fakeFolder, "A/a1");
        triggerDownload (fakeFolder, "A/a2");
        triggerDownload (fakeFolder, "A/a3");
        triggerDownload (fakeFolder, "A/a4");
        triggerDownload (fakeFolder, "A/a5");
        triggerDownload (fakeFolder, "A/a6");
        triggerDownload (fakeFolder, "A/a7");
        triggerDownload (fakeFolder, "A/b1");
        triggerDownload (fakeFolder, "A/b2");
        triggerDownload (fakeFolder, "A/b3");
        triggerDownload (fakeFolder, "A/b4");

        // Remote complications
        fakeFolder.remoteModifier ().appendByte ("A/a2");
        fakeFolder.remoteModifier ().remove ("A/a3");
        fakeFolder.remoteModifier ().rename ("A/a4", "A/a4m");
        fakeFolder.remoteModifier ().appendByte ("A/b2");
        fakeFolder.remoteModifier ().remove ("A/b3");
        fakeFolder.remoteModifier ().rename ("A/b4", "A/b4m");

        // Local complications
        fakeFolder.localModifier ().remove ("A/a5");
        fakeFolder.localModifier ().insert ("A/a5");
        fakeFolder.localModifier ().remove ("A/a6");
        fakeFolder.localModifier ().insert ("A/a6");

        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        QCOMPARE (completeSpy.findItem ("A/a1").type, ItemTypeVirtualFileDownload);
        QVERIFY (itemInstruction (completeSpy, "A/a2", CSYNC_INSTRUCTION_SYNC));
        QCOMPARE (completeSpy.findItem ("A/a2").type, ItemTypeVirtualFileDownload);
        QVERIFY (itemInstruction (completeSpy, "A/a3", CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (itemInstruction (completeSpy, "A/a4m", CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemInstruction (completeSpy, "A/a4", CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (itemInstruction (completeSpy, "A/a5", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "A/a6", CSYNC_INSTRUCTION_CONFLICT));
        QVERIFY (itemInstruction (completeSpy, "A/a7", CSYNC_INSTRUCTION_SYNC));
        QVERIFY (itemInstruction (completeSpy, "A/b1", CSYNC_INSTRUCTION_SYNC));
        QVERIFY (itemInstruction (completeSpy, "A/b2", CSYNC_INSTRUCTION_SYNC));
        QVERIFY (itemInstruction (completeSpy, "A/b3", CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (itemInstruction (completeSpy, "A/b4m", CSYNC_INSTRUCTION_NEW));
        QVERIFY (itemInstruction (completeSpy, "A/b4", CSYNC_INSTRUCTION_REMOVE));

        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a1");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a2");
        CFVERIFY_GONE (fakeFolder, "A/a3");
        CFVERIFY_GONE (fakeFolder, "A/a4");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a4m");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a5");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a6");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a7");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/b1");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/b2");
        CFVERIFY_GONE (fakeFolder, "A/b3");
        CFVERIFY_GONE (fakeFolder, "A/b4");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/b4m");

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
        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        on_signal_cleanup ();

        // Download by changing the database entry
        triggerDownload (fakeFolder, "A/a1");
        fakeFolder.serverErrorPaths ().append ("A/a1", 500);
        QVERIFY (!fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        QVERIFY (xattr.hasNextcloudPlaceholderAttributes (fakeFolder.localPath () + "A/a1"));
        QVERIFY (QFileInfo (fakeFolder.localPath () + "A/a1").exists ());
        QCOMPARE (dbRecord (fakeFolder, "A/a1").type, ItemTypeVirtualFileDownload);
        on_signal_cleanup ();

        fakeFolder.serverErrorPaths ().clear ();
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a1");
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
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
        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");

        fakeFolder.syncJournal ().internalPinStates ().setForPath (GLib.ByteArray (), PinState.PinState.ALWAYS_LOCAL);

        // Create a new remote file, it'll not be virtual
        fakeFolder.remoteModifier ().insert ("A/a2");
        QVERIFY (fakeFolder.syncOnce ());

        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a2");
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

        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a2");
        XAVERIFY_VIRTUAL (fakeFolder, "A/Sub/a3");
        XAVERIFY_VIRTUAL (fakeFolder, "A/Sub/a4");
        XAVERIFY_VIRTUAL (fakeFolder, "A/Sub/SubSub/a5");
        XAVERIFY_VIRTUAL (fakeFolder, "A/Sub2/a6");
        XAVERIFY_VIRTUAL (fakeFolder, "B/b1");
        XAVERIFY_VIRTUAL (fakeFolder, "B/Sub/b2");

        // Download All file in the directory A/Sub
        // (as in Folder.downloadVirtualFile)
        fakeFolder.syncJournal ().markVirtualFileForDownloadRecursively ("A/Sub");

        QVERIFY (fakeFolder.syncOnce ());

        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a2");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/Sub/a3");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/Sub/a4");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/Sub/SubSub/a5");
        XAVERIFY_VIRTUAL (fakeFolder, "A/Sub2/a6");
        XAVERIFY_VIRTUAL (fakeFolder, "B/b1");
        XAVERIFY_VIRTUAL (fakeFolder, "B/Sub/b2");

        // Add a file in a subfolder that was downloaded
        // Currently, this continue to add it as a virtual file.
        fakeFolder.remoteModifier ().insert ("A/Sub/SubSub/a7");
        QVERIFY (fakeFolder.syncOnce ());

        XAVERIFY_VIRTUAL (fakeFolder, "A/Sub/SubSub/a7");

        // Now download all files in "A"
        fakeFolder.syncJournal ().markVirtualFileForDownloadRecursively ("A");
        QVERIFY (fakeFolder.syncOnce ());

        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a1");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/a2");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/Sub/a3");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/Sub/a4");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/Sub/SubSub/a5");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/Sub/SubSub/a7");
        XAVERIFY_NONVIRTUAL (fakeFolder, "A/Sub2/a6");
        XAVERIFY_VIRTUAL (fakeFolder, "B/b1");
        XAVERIFY_VIRTUAL (fakeFolder, "B/Sub/b2");

        // Now download remaining files in "B"
        fakeFolder.syncJournal ().markVirtualFileForDownloadRecursively ("B");
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentLocalState (), fakeFolder.currentRemoteState ());
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

        XAVERIFY_VIRTUAL (fakeFolder, "file1");
        XAVERIFY_VIRTUAL (fakeFolder, "file2");
        XAVERIFY_VIRTUAL (fakeFolder, "file3");

        on_signal_cleanup ();

        fakeFolder.localModifier ().rename ("file1", "renamed1");
        fakeFolder.localModifier ().rename ("file2", "renamed2");
        triggerDownload (fakeFolder, "file2");
        triggerDownload (fakeFolder, "file3");
        QVERIFY (fakeFolder.syncOnce ());

        CFVERIFY_GONE (fakeFolder, "file1");
        XAVERIFY_VIRTUAL (fakeFolder, "renamed1");

        QVERIFY (fakeFolder.currentRemoteState ().find ("renamed1"));
        QVERIFY (itemInstruction (completeSpy, "renamed1", CSYNC_INSTRUCTION_RENAME));

        // file2 has a conflict between the download request and the rename:
        // the rename wins, the download is ignored

        CFVERIFY_GONE (fakeFolder, "file2");
        XAVERIFY_VIRTUAL (fakeFolder, "renamed2");

        QVERIFY (fakeFolder.currentRemoteState ().find ("renamed2"));
        QVERIFY (itemInstruction (completeSpy, "renamed2", CSYNC_INSTRUCTION_RENAME));

        QVERIFY (itemInstruction (completeSpy, "file3", CSYNC_INSTRUCTION_SYNC));
        XAVERIFY_NONVIRTUAL (fakeFolder, "file3");
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
        QVERIFY (fakeFolder.syncOnce ());

        triggerDownload (fakeFolder, "case4");
        QVERIFY (fakeFolder.syncOnce ());

        XAVERIFY_VIRTUAL (fakeFolder, "case3");
        XAVERIFY_NONVIRTUAL (fakeFolder, "case4");

        on_signal_cleanup ();

        // Case 1 : non-virtual, foo . bar (tested elsewhere)
        // Case 2 : virtual, foo . bar (tested elsewhere)

        // Case 3 : virtual, foo.oc . bar.oc (database hydrate)
        fakeFolder.localModifier ().rename ("case3", "case3-rename");
        triggerDownload (fakeFolder, "case3");

        // Case 4 : non-virtual foo . bar (database dehydrate)
        fakeFolder.localModifier ().rename ("case4", "case4-rename");
        markForDehydration (fakeFolder, "case4");

        QVERIFY (fakeFolder.syncOnce ());

        // Case 3 : the rename went though, hydration is forgotten
        CFVERIFY_GONE (fakeFolder, "case3");
        XAVERIFY_VIRTUAL (fakeFolder, "case3-rename");
        QVERIFY (!fakeFolder.currentRemoteState ().find ("case3"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("case3-rename"));
        QVERIFY (itemInstruction (completeSpy, "case3-rename", CSYNC_INSTRUCTION_RENAME));

        // Case 4 : the rename went though, dehydration is forgotten
        CFVERIFY_GONE (fakeFolder, "case4");
        XAVERIFY_NONVIRTUAL (fakeFolder, "case4-rename");
        QVERIFY (!fakeFolder.currentRemoteState ().find ("case4"));
        QVERIFY (fakeFolder.currentRemoteState ().find ("case4-rename"));
        QVERIFY (itemInstruction (completeSpy, "case4-rename", CSYNC_INSTRUCTION_RENAME));
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
            return xattr.hasNextcloudPlaceholderAttributes (fakeFolder.localPath () + path)
                && QFileInfo (fakeFolder.localPath () + path).exists ();
        }
        var hasDehydratedDbEntries = [&] (string path) {
            SyncJournalFileRecord record;
            fakeFolder.syncJournal ().getFileRecord (path, record);
            return record.isValid () && record.type == ItemTypeVirtualFile;
        }

        QVERIFY (isDehydrated ("A/a1"));
        QVERIFY (hasDehydratedDbEntries ("A/a1"));
        QVERIFY (itemInstruction (completeSpy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        QCOMPARE (completeSpy.findItem ("A/a1").type, ItemTypeVirtualFileDehydration);
        QCOMPARE (completeSpy.findItem ("A/a1").file, QStringLiteral ("A/a1"));
        QVERIFY (isDehydrated ("A/a2"));
        QVERIFY (hasDehydratedDbEntries ("A/a2"));
        QVERIFY (itemInstruction (completeSpy, "A/a2", CSYNC_INSTRUCTION_SYNC));
        QCOMPARE (completeSpy.findItem ("A/a2").type, ItemTypeVirtualFileDehydration);

        QVERIFY (!QFileInfo (fakeFolder.localPath () + "B/b1").exists ());
        QVERIFY (!fakeFolder.currentRemoteState ().find ("B/b1"));
        QVERIFY (itemInstruction (completeSpy, "B/b1", CSYNC_INSTRUCTION_REMOVE));

        QVERIFY (!QFileInfo (fakeFolder.localPath () + "B/b2").exists ());
        QVERIFY (!fakeFolder.currentRemoteState ().find ("B/b2"));
        QVERIFY (isDehydrated ("B/b3"));
        QVERIFY (hasDehydratedDbEntries ("B/b3"));
        QVERIFY (itemInstruction (completeSpy, "B/b2", CSYNC_INSTRUCTION_REMOVE));
        QVERIFY (itemInstruction (completeSpy, "B/b3", CSYNC_INSTRUCTION_NEW));

        QCOMPARE (fakeFolder.currentRemoteState ().find ("C/c1").size, 25);
        QVERIFY (itemInstruction (completeSpy, "C/c1", CSYNC_INSTRUCTION_SYNC));

        QCOMPARE (fakeFolder.currentRemoteState ().find ("C/c2").size, 26);
        QVERIFY (itemInstruction (completeSpy, "C/c2", CSYNC_INSTRUCTION_CONFLICT));
        on_signal_cleanup ();

        var expectedRemoteState = fakeFolder.currentRemoteState ();
        QVERIFY (fakeFolder.syncOnce ());
        QCOMPARE (fakeFolder.currentRemoteState (), expectedRemoteState);

        QVERIFY (isDehydrated ("A/a1"));
        QVERIFY (hasDehydratedDbEntries ("A/a1"));
        QVERIFY (isDehydrated ("A/a2"));
        QVERIFY (hasDehydratedDbEntries ("A/a2"));

        QVERIFY (!QFileInfo (fakeFolder.localPath () + "B/b1").exists ());
        QVERIFY (!QFileInfo (fakeFolder.localPath () + "B/b2").exists ());
        QVERIFY (isDehydrated ("B/b3"));
        QVERIFY (hasDehydratedDbEntries ("B/b3"));

        QVERIFY (QFileInfo (fakeFolder.localPath () + "C/c1").exists ());
        QVERIFY (dbRecord (fakeFolder, "C/c1").isValid ());
        QVERIFY (!isDehydrated ("C/c1"));
        QVERIFY (!hasDehydratedDbEntries ("C/c1"));

        QVERIFY (QFileInfo (fakeFolder.localPath () + "C/c2").exists ());
        QVERIFY (dbRecord (fakeFolder, "C/c2").isValid ());
        QVERIFY (!isDehydrated ("C/c2"));
        QVERIFY (!hasDehydratedDbEntries ("C/c2"));
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

        XAVERIFY_VIRTUAL (fakeFolder, "f1");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a1");
        XAVERIFY_VIRTUAL (fakeFolder, "A/a3");
        XAVERIFY_VIRTUAL (fakeFolder, "A/B/b1");

        // Make local changes to a3
        fakeFolder.localModifier ().remove ("A/a3");
        fakeFolder.localModifier ().insert ("A/a3", 100);

        // Now wipe the virtuals
        SyncEngine.wipeVirtualFiles (fakeFolder.localPath (), fakeFolder.syncJournal (), *fakeFolder.syncEngine ().syncOptions ().vfs);

        CFVERIFY_GONE (fakeFolder, "f1");
        CFVERIFY_GONE (fakeFolder, "A/a1");
        QVERIFY (QFileInfo (fakeFolder.localPath () + "A/a3").exists ());
        QVERIFY (!dbRecord (fakeFolder, "A/a3").isValid ());
        CFVERIFY_GONE (fakeFolder, "A/B/b1");

        fakeFolder.switchToVfs (unowned<Vfs> (new VfsOff));
        ItemCompletedSpy completeSpy (fakeFolder);
        QVERIFY (fakeFolder.syncOnce ());

        QVERIFY (fakeFolder.currentLocalState ().find ("A"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/B"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/B/b1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/B/b2"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a2"));
        QVERIFY (fakeFolder.currentLocalState ().find ("A/a3"));
        QVERIFY (fakeFolder.currentLocalState ().find ("f1"));
        QVERIFY (fakeFolder.currentLocalState ().find ("f2"));

        // a3 has a conflict
        QVERIFY (itemInstruction (completeSpy, "A/a3", CSYNC_INSTRUCTION_CONFLICT));

        // conflict files should exist
        QCOMPARE (fakeFolder.syncJournal ().conflictRecordPaths ().size (), 1);
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

        XAVERIFY_VIRTUAL (fakeFolder, "file1");
        XAVERIFY_VIRTUAL (fakeFolder, "online/file1");
        XAVERIFY_NONVIRTUAL (fakeFolder, "local/file1");
        XAVERIFY_VIRTUAL (fakeFolder, "unspec/file1");

        // Test 2 : change root to PinState.ALWAYS_LOCAL
        setPin (GLib.ByteArray (), PinState.PinState.ALWAYS_LOCAL);

        fakeFolder.remoteModifier ().insert ("file2");
        fakeFolder.remoteModifier ().insert ("online/file2");
        fakeFolder.remoteModifier ().insert ("local/file2");
        fakeFolder.remoteModifier ().insert ("unspec/file2");
        QVERIFY (fakeFolder.syncOnce ());

        XAVERIFY_NONVIRTUAL (fakeFolder, "file2");
        XAVERIFY_VIRTUAL (fakeFolder, "online/file2");
        XAVERIFY_NONVIRTUAL (fakeFolder, "local/file2");
        XAVERIFY_VIRTUAL (fakeFolder, "unspec/file2");

        // root file1 was hydrated due to its new pin state
        XAVERIFY_NONVIRTUAL (fakeFolder, "file1");

        // file1 is unchanged in the explicitly pinned subfolders
        XAVERIFY_VIRTUAL (fakeFolder, "online/file1");
        XAVERIFY_NONVIRTUAL (fakeFolder, "local/file1");
        XAVERIFY_VIRTUAL (fakeFolder, "unspec/file1");

        // Test 3 : change root to VfsItemAvailability.ONLINE_ONLY
        setPin (GLib.ByteArray (), PinState.VfsItemAvailability.ONLINE_ONLY);

        fakeFolder.remoteModifier ().insert ("file3");
        fakeFolder.remoteModifier ().insert ("online/file3");
        fakeFolder.remoteModifier ().insert ("local/file3");
        fakeFolder.remoteModifier ().insert ("unspec/file3");
        QVERIFY (fakeFolder.syncOnce ());

        XAVERIFY_VIRTUAL (fakeFolder, "file3");
        XAVERIFY_VIRTUAL (fakeFolder, "online/file3");
        XAVERIFY_NONVIRTUAL (fakeFolder, "local/file3");
        XAVERIFY_VIRTUAL (fakeFolder, "unspec/file3");

        // root file1 was dehydrated due to its new pin state
        XAVERIFY_VIRTUAL (fakeFolder, "file1");

        // file1 is unchanged in the explicitly pinned subfolders
        XAVERIFY_VIRTUAL (fakeFolder, "online/file1");
        XAVERIFY_NONVIRTUAL (fakeFolder, "local/file1");
        XAVERIFY_VIRTUAL (fakeFolder, "unspec/file1");
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
        QCOMPARE (*vfs.availability ("file1"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);
        QCOMPARE (*vfs.availability ("local"), VfsItemAvailability.PinState.ALWAYS_LOCAL);
        QCOMPARE (*vfs.availability ("local/file1"), VfsItemAvailability.PinState.ALWAYS_LOCAL);
        QCOMPARE (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        QCOMPARE (*vfs.availability ("online/file1"), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        QCOMPARE (*vfs.availability ("unspec"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);
        QCOMPARE (*vfs.availability ("unspec/file1"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);

        // Subitem pin states can ruin "pure" availabilities
        setPin ("local/sub", PinState.VfsItemAvailability.ONLINE_ONLY);
        QCOMPARE (*vfs.availability ("local"), VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED);
        setPin ("online/sub", PinState.PinState.UNSPECIFIED);
        QCOMPARE (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);

        triggerDownload (fakeFolder, "unspec/file1");
        setPin ("local/file2", PinState.VfsItemAvailability.ONLINE_ONLY);
        setPin ("online/file2", PinState.PinState.ALWAYS_LOCAL);
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
        QCOMPARE (*vfs.pinState ("file1"), PinState.PinState.UNSPECIFIED);
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

        // When a file is hydrated or dehydrated due to pin state it retains its pin state
        QVERIFY (vfs.setPinState ("onlinerenamed2/file1rename", PinState.PinState.ALWAYS_LOCAL));
        QVERIFY (fakeFolder.syncOnce ());
        QVERIFY (fakeFolder.currentLocalState ().find ("onlinerenamed2/file1rename"));
        QCOMPARE (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.PinState.ALWAYS_LOCAL);

        QVERIFY (vfs.setPinState ("onlinerenamed2", PinState.PinState.UNSPECIFIED));
        QVERIFY (vfs.setPinState ("onlinerenamed2/file1rename", PinState.VfsItemAvailability.ONLINE_ONLY));
        QVERIFY (fakeFolder.syncOnce ());

        XAVERIFY_VIRTUAL (fakeFolder, "onlinerenamed2/file1rename");

        QCOMPARE (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.VfsItemAvailability.ONLINE_ONLY);
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

        XAVERIFY_NONVIRTUAL (fakeFolder, "online/file1");
        XAVERIFY_VIRTUAL (fakeFolder, "local/file1");
        QCOMPARE (*vfs.pinState ("online/file1"), PinState.PinState.UNSPECIFIED);
        QCOMPARE (*vfs.pinState ("local/file1"), PinState.PinState.UNSPECIFIED);

        // no change on another sync
        QVERIFY (fakeFolder.syncOnce ());
        XAVERIFY_NONVIRTUAL (fakeFolder, "online/file1");
        XAVERIFY_VIRTUAL (fakeFolder, "local/file1");
    }
}

QTEST_GUILESS_MAIN (TestSyncXAttr)