/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

namespace Testing {



namespace xattr {
using Occ.XAttrWrapper;
}

const int XAVERIFY_VIRTUAL (folder, path)
    GLib.assert_true (GLib.FileInfo ( (folder).local_path () + (path)).exists ());
    GLib.assert_cmp (GLib.FileInfo ( (folder).local_path () + (path)).size (), 1);
    GLib.assert_true (xattr.hasNextcloudPlaceholderAttributes ( (folder).local_path () + (path)));
    GLib.assert_true (dbRecord ( (folder), (path)).is_valid ());
    GLib.assert_cmp (dbRecord ( (folder), (path)).type, ItemTypeVirtualFile);

const int XAVERIFY_NONVIRTUAL (folder, path)
    GLib.assert_true (GLib.FileInfo ( (folder).local_path () + (path)).exists ());
    GLib.assert_true (!xattr.hasNextcloudPlaceholderAttributes ( (folder).local_path () + (path)));
    GLib.assert_true (dbRecord ( (folder), (path)).is_valid ());
    GLib.assert_cmp (dbRecord ( (folder), (path)).type, ItemTypeFile);

const int CFVERIFY_GONE (folder, path)
    GLib.assert_true (!GLib.FileInfo ( (folder).local_path () + (path)).exists ());
    GLib.assert_true (!dbRecord ( (folder), (path)).is_valid ());

using Occ;

bool itemInstruction (ItemCompletedSpy spy, string path, SyncInstructions instr) {
    var item = spy.find_item (path);
    return item.instruction == instr;
}

SyncJournalFileRecord dbRecord (FakeFolder folder, string path) {
    SyncJournalFileRecord record;
    folder.sync_journal ().get_file_record (path, record);
    return record;
}

void triggerDownload (FakeFolder folder, GLib.ByteArray path) {
    var journal = folder.sync_journal ();
    SyncJournalFileRecord record;
    journal.get_file_record (path, record);
    if (!record.is_valid ())
        return;
    record.type = ItemTypeVirtualFileDownload;
    journal.setFileRecord (record);
    journal.schedulePathForRemoteDiscovery (record.path);
}

void markForDehydration (FakeFolder folder, GLib.ByteArray path) {
    var journal = folder.sync_journal ();
    SyncJournalFileRecord record;
    journal.get_file_record (path, record);
    if (!record.is_valid ())
        return;
    record.type = ItemTypeVirtualFileDehydration;
    journal.setFileRecord (record);
    journal.schedulePathForRemoteDiscovery (record.path);
}

unowned<Vfs> setupVfs (FakeFolder folder) {
    var xattrVfs = unowned<Vfs> (createVfsFromPlugin (Vfs.XAttr).release ());
    GLib.Object.connect (&folder.sync_engine ().syncFileStatusTracker (), &SyncFileStatusTracker.fileStatusChanged,
                     xattrVfs.data (), &Vfs.fileStatusChanged);
    folder.switch_to_vfs (xattrVfs);

    // Using this directly doesn't recursively unpin everything and instead leaves
    // the files in the hydration that that they on_signal_start with
    folder.sync_journal ().internalPinStates ().setForPath (GLib.ByteArray (), PinState.PinState.UNSPECIFIED);

    return xattrVfs;
}

class TestSyncXAttr : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_lifecycle_data () {
        QTest.add_column<bool> ("doLocalDiscovery");

        QTest.new_row ("full local discovery") + true;
        QTest.new_row ("skip local discovery") + false;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_lifecycle () {
        QFETCH (bool, doLocalDiscovery);

        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
            if (!doLocalDiscovery)
                fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM);
        }
        on_signal_cleanup ();

        // Create a virtual file for a new remote file
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1", 64);
        var someDate = GLib.DateTime (QDate (1984, 07, 30), QTime (1,3,2));
        fake_folder.remote_modifier ().set_modification_time ("A/a1", someDate);
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        GLib.assert_cmp (dbRecord (fake_folder, "A/a1").file_size, 64);
        GLib.assert_cmp (GLib.FileInfo (fake_folder.local_path () + "A/a1").last_modified (), someDate);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (itemInstruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_NEW));
        on_signal_cleanup ();

        // Another sync doesn't actually lead to changes
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        GLib.assert_cmp (dbRecord (fake_folder, "A/a1").file_size, 64);
        GLib.assert_cmp (GLib.FileInfo (fake_folder.local_path () + "A/a1").last_modified (), someDate);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (complete_spy.is_empty ());
        on_signal_cleanup ();

        // Not even when the remote is rediscovered
        fake_folder.sync_journal ().forceRemoteDiscoveryNextSync ();
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        GLib.assert_cmp (dbRecord (fake_folder, "A/a1").file_size, 64);
        GLib.assert_cmp (GLib.FileInfo (fake_folder.local_path () + "A/a1").last_modified (), someDate);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (complete_spy.is_empty ());
        on_signal_cleanup ();

        // Neither does a remote change
        fake_folder.remote_modifier ().append_byte ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        GLib.assert_cmp (dbRecord (fake_folder, "A/a1").file_size, 65);
        GLib.assert_cmp (GLib.FileInfo (fake_folder.local_path () + "A/a1").last_modified (), someDate);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (itemInstruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_UPDATE_METADATA));
        GLib.assert_cmp (dbRecord (fake_folder, "A/a1").file_size, 65);
        on_signal_cleanup ();

        // If the local virtual file is removed, this will be propagated remotely
        if (!doLocalDiscovery)
            fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.DATABASE_AND_FILESYSTEM, { "A" });
        fake_folder.local_modifier ().remove ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (itemInstruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (!dbRecord (fake_folder, "A/a1").is_valid ());
        on_signal_cleanup ();

        // Recreate a1 before carrying on with the other tests
        fake_folder.remote_modifier ().insert ("A/a1", 65);
        fake_folder.remote_modifier ().set_modification_time ("A/a1", someDate);
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        GLib.assert_cmp (dbRecord (fake_folder, "A/a1").file_size, 65);
        GLib.assert_cmp (GLib.FileInfo (fake_folder.local_path () + "A/a1").last_modified (), someDate);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (itemInstruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_NEW));
        on_signal_cleanup ();

        // Remote rename is propagated
        fake_folder.remote_modifier ().rename ("A/a1", "A/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "A/a1").exists ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a1m");
        GLib.assert_cmp (dbRecord (fake_folder, "A/a1m").file_size, 65);
        GLib.assert_cmp (GLib.FileInfo (fake_folder.local_path () + "A/a1m").last_modified (), someDate);
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/a1m"));
        GLib.assert_true (
            itemInstruction (complete_spy, "A/a1m", CSYNC_INSTRUCTION_RENAME)
            || (itemInstruction (complete_spy, "A/a1m", CSYNC_INSTRUCTION_NEW)
                && itemInstruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_REMOVE)));
        GLib.assert_true (!dbRecord (fake_folder, "A/a1").is_valid ());
        on_signal_cleanup ();

        // Remote remove is propagated
        fake_folder.remote_modifier ().remove ("A/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "A/a1m").exists ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("A/a1m"));
        GLib.assert_true (itemInstruction (complete_spy, "A/a1m", CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (!dbRecord (fake_folder, "A/a1").is_valid ());
        GLib.assert_true (!dbRecord (fake_folder, "A/a1m").is_valid ());
        on_signal_cleanup ();

        // Edge case : Local virtual file but no database entry for some reason
        fake_folder.remote_modifier ().insert ("A/a2", 32);
        fake_folder.remote_modifier ().insert ("A/a3", 33);
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a2");
        GLib.assert_cmp (dbRecord (fake_folder, "A/a2").file_size, 32);
        XAVERIFY_VIRTUAL (fake_folder, "A/a3");
        GLib.assert_cmp (dbRecord (fake_folder, "A/a3").file_size, 33);
        on_signal_cleanup ();

        fake_folder.sync_engine ().journal ().deleteFileRecord ("A/a2");
        fake_folder.sync_engine ().journal ().deleteFileRecord ("A/a3");
        fake_folder.remote_modifier ().remove ("A/a3");
        fake_folder.sync_engine ().setLocalDiscoveryOptions (LocalDiscoveryStyle.FILESYSTEM_ONLY);
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a2");
        GLib.assert_cmp (dbRecord (fake_folder, "A/a2").file_size, 32);
        GLib.assert_true (itemInstruction (complete_spy, "A/a2", CSYNC_INSTRUCTION_UPDATE_METADATA));
        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "A/a3").exists ());
        GLib.assert_true (itemInstruction (complete_spy, "A/a3", CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (!dbRecord (fake_folder, "A/a3").is_valid ());
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_conflict () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // Create a virtual file for a new remote file
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1", 11);
        fake_folder.remote_modifier ().insert ("A/a2", 12);
        fake_folder.remote_modifier ().mkdir ("B");
        fake_folder.remote_modifier ().insert ("B/b1", 21);
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        XAVERIFY_VIRTUAL (fake_folder, "A/a2");
        XAVERIFY_VIRTUAL (fake_folder, "B/b1");
        GLib.assert_cmp (dbRecord (fake_folder, "A/a1").file_size, 11);
        GLib.assert_cmp (dbRecord (fake_folder, "A/a2").file_size, 12);
        GLib.assert_cmp (dbRecord (fake_folder, "B/b1").file_size, 21);
        on_signal_cleanup ();

        // All the files are touched on the server
        fake_folder.remote_modifier ().append_byte ("A/a1");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().append_byte ("B/b1");

        // A : the correct file and a conflicting file are added
        // B : user adds a directory* locally
        fake_folder.local_modifier ().remove ("A/a1");
        fake_folder.local_modifier ().insert ("A/a1", 12);
        fake_folder.local_modifier ().remove ("A/a2");
        fake_folder.local_modifier ().insert ("A/a2", 10);
        fake_folder.local_modifier ().remove ("B/b1");
        fake_folder.local_modifier ().mkdir ("B/b1");
        fake_folder.local_modifier ().insert ("B/b1/foo");
        GLib.assert_true (fake_folder.sync_once ());

        // Everything is CONFLICT
        GLib.assert_true (itemInstruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (itemInstruction (complete_spy, "A/a2", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (itemInstruction (complete_spy, "B/b1", CSYNC_INSTRUCTION_CONFLICT));

        // conflict files should exist
        GLib.assert_cmp (fake_folder.sync_journal ().conflictRecordPaths ().size (), 2);

        // nothing should have the virtual file tag
        XAVERIFY_NONVIRTUAL (fake_folder, "A/a1");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/a2");
        XAVERIFY_NONVIRTUAL (fake_folder, "B/b1");

        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_with_normal_sync () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // No effect sync
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        on_signal_cleanup ();

        // Existing files are propagated just fine in both directions
        fake_folder.local_modifier ().append_byte ("A/a1");
        fake_folder.local_modifier ().insert ("A/a3");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        on_signal_cleanup ();

        // New files on the remote create virtual files
        fake_folder.remote_modifier ().insert ("A/new", 42);
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/new");
        GLib.assert_cmp (dbRecord (fake_folder, "A/new").file_size, 42);
        GLib.assert_true (fake_folder.current_remote_state ().find ("A/new"));
        GLib.assert_true (itemInstruction (complete_spy, "A/new", CSYNC_INSTRUCTION_NEW));
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_download () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        // Create a virtual file for remote files
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1");
        fake_folder.remote_modifier ().insert ("A/a2");
        fake_folder.remote_modifier ().insert ("A/a3");
        fake_folder.remote_modifier ().insert ("A/a4");
        fake_folder.remote_modifier ().insert ("A/a5");
        fake_folder.remote_modifier ().insert ("A/a6");
        fake_folder.remote_modifier ().insert ("A/a7");
        fake_folder.remote_modifier ().insert ("A/b1");
        fake_folder.remote_modifier ().insert ("A/b2");
        fake_folder.remote_modifier ().insert ("A/b3");
        fake_folder.remote_modifier ().insert ("A/b4");
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        XAVERIFY_VIRTUAL (fake_folder, "A/a2");
        XAVERIFY_VIRTUAL (fake_folder, "A/a3");
        XAVERIFY_VIRTUAL (fake_folder, "A/a4");
        XAVERIFY_VIRTUAL (fake_folder, "A/a5");
        XAVERIFY_VIRTUAL (fake_folder, "A/a6");
        XAVERIFY_VIRTUAL (fake_folder, "A/a7");
        XAVERIFY_VIRTUAL (fake_folder, "A/b1");
        XAVERIFY_VIRTUAL (fake_folder, "A/b2");
        XAVERIFY_VIRTUAL (fake_folder, "A/b3");
        XAVERIFY_VIRTUAL (fake_folder, "A/b4");

        on_signal_cleanup ();

        // Download by changing the database entry
        triggerDownload (fake_folder, "A/a1");
        triggerDownload (fake_folder, "A/a2");
        triggerDownload (fake_folder, "A/a3");
        triggerDownload (fake_folder, "A/a4");
        triggerDownload (fake_folder, "A/a5");
        triggerDownload (fake_folder, "A/a6");
        triggerDownload (fake_folder, "A/a7");
        triggerDownload (fake_folder, "A/b1");
        triggerDownload (fake_folder, "A/b2");
        triggerDownload (fake_folder, "A/b3");
        triggerDownload (fake_folder, "A/b4");

        // Remote complications
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.remote_modifier ().remove ("A/a3");
        fake_folder.remote_modifier ().rename ("A/a4", "A/a4m");
        fake_folder.remote_modifier ().append_byte ("A/b2");
        fake_folder.remote_modifier ().remove ("A/b3");
        fake_folder.remote_modifier ().rename ("A/b4", "A/b4m");

        // Local complications
        fake_folder.local_modifier ().remove ("A/a5");
        fake_folder.local_modifier ().insert ("A/a5");
        fake_folder.local_modifier ().remove ("A/a6");
        fake_folder.local_modifier ().insert ("A/a6");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (itemInstruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_cmp (complete_spy.find_item ("A/a1").type, ItemTypeVirtualFileDownload);
        GLib.assert_true (itemInstruction (complete_spy, "A/a2", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_cmp (complete_spy.find_item ("A/a2").type, ItemTypeVirtualFileDownload);
        GLib.assert_true (itemInstruction (complete_spy, "A/a3", CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (itemInstruction (complete_spy, "A/a4m", CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (itemInstruction (complete_spy, "A/a4", CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (itemInstruction (complete_spy, "A/a5", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (itemInstruction (complete_spy, "A/a6", CSYNC_INSTRUCTION_CONFLICT));
        GLib.assert_true (itemInstruction (complete_spy, "A/a7", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_true (itemInstruction (complete_spy, "A/b1", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_true (itemInstruction (complete_spy, "A/b2", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_true (itemInstruction (complete_spy, "A/b3", CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (itemInstruction (complete_spy, "A/b4m", CSYNC_INSTRUCTION_NEW));
        GLib.assert_true (itemInstruction (complete_spy, "A/b4", CSYNC_INSTRUCTION_REMOVE));

        XAVERIFY_NONVIRTUAL (fake_folder, "A/a1");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/a2");
        CFVERIFY_GONE (fake_folder, "A/a3");
        CFVERIFY_GONE (fake_folder, "A/a4");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/a4m");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/a5");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/a6");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/a7");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/b1");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/b2");
        CFVERIFY_GONE (fake_folder, "A/b3");
        CFVERIFY_GONE (fake_folder, "A/b4");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/b4m");

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_virtual_file_download_resume () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
            fake_folder.sync_journal ().wipe_error_blocklist ();
        }
        on_signal_cleanup ();

        // Create a virtual file for remote files
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        on_signal_cleanup ();

        // Download by changing the database entry
        triggerDownload (fake_folder, "A/a1");
        fake_folder.server_error_paths ().append ("A/a1", 500);
        GLib.assert_true (!fake_folder.sync_once ());
        GLib.assert_true (itemInstruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_true (xattr.hasNextcloudPlaceholderAttributes (fake_folder.local_path () + "A/a1"));
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path () + "A/a1").exists ());
        GLib.assert_cmp (dbRecord (fake_folder, "A/a1").type, ItemTypeVirtualFileDownload);
        on_signal_cleanup ();

        fake_folder.server_error_paths ().clear ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (itemInstruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        XAVERIFY_NONVIRTUAL (fake_folder, "A/a1");
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_new_files_not_virtual () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().insert ("A/a1");
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_VIRTUAL (fake_folder, "A/a1");

        fake_folder.sync_journal ().internalPinStates ().setForPath (GLib.ByteArray (), PinState.PinState.ALWAYS_LOCAL);

        // Create a new remote file, it'll not be virtual
        fake_folder.remote_modifier ().insert ("A/a2");
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_NONVIRTUAL (fake_folder, "A/a2");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_download_recursive () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Create a virtual file for remote files
        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().mkdir ("A/Sub");
        fake_folder.remote_modifier ().mkdir ("A/Sub/SubSub");
        fake_folder.remote_modifier ().mkdir ("A/Sub2");
        fake_folder.remote_modifier ().mkdir ("B");
        fake_folder.remote_modifier ().mkdir ("B/Sub");
        fake_folder.remote_modifier ().insert ("A/a1");
        fake_folder.remote_modifier ().insert ("A/a2");
        fake_folder.remote_modifier ().insert ("A/Sub/a3");
        fake_folder.remote_modifier ().insert ("A/Sub/a4");
        fake_folder.remote_modifier ().insert ("A/Sub/SubSub/a5");
        fake_folder.remote_modifier ().insert ("A/Sub2/a6");
        fake_folder.remote_modifier ().insert ("B/b1");
        fake_folder.remote_modifier ().insert ("B/Sub/b2");
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        XAVERIFY_VIRTUAL (fake_folder, "A/a2");
        XAVERIFY_VIRTUAL (fake_folder, "A/Sub/a3");
        XAVERIFY_VIRTUAL (fake_folder, "A/Sub/a4");
        XAVERIFY_VIRTUAL (fake_folder, "A/Sub/SubSub/a5");
        XAVERIFY_VIRTUAL (fake_folder, "A/Sub2/a6");
        XAVERIFY_VIRTUAL (fake_folder, "B/b1");
        XAVERIFY_VIRTUAL (fake_folder, "B/Sub/b2");

        // Download All file in the directory A/Sub
        // (as in Folder.downloadVirtualFile)
        fake_folder.sync_journal ().markVirtualFileForDownloadRecursively ("A/Sub");

        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        XAVERIFY_VIRTUAL (fake_folder, "A/a2");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/Sub/a3");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/Sub/a4");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/Sub/SubSub/a5");
        XAVERIFY_VIRTUAL (fake_folder, "A/Sub2/a6");
        XAVERIFY_VIRTUAL (fake_folder, "B/b1");
        XAVERIFY_VIRTUAL (fake_folder, "B/Sub/b2");

        // Add a file in a subfolder that was downloaded
        // Currently, this continue to add it as a virtual file.
        fake_folder.remote_modifier ().insert ("A/Sub/SubSub/a7");
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_VIRTUAL (fake_folder, "A/Sub/SubSub/a7");

        // Now download all files in "A"
        fake_folder.sync_journal ().markVirtualFileForDownloadRecursively ("A");
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_NONVIRTUAL (fake_folder, "A/a1");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/a2");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/Sub/a3");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/Sub/a4");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/Sub/SubSub/a5");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/Sub/SubSub/a7");
        XAVERIFY_NONVIRTUAL (fake_folder, "A/Sub2/a6");
        XAVERIFY_VIRTUAL (fake_folder, "B/b1");
        XAVERIFY_VIRTUAL (fake_folder, "B/Sub/b2");

        // Now download remaining files in "B"
        fake_folder.sync_journal ().markVirtualFileForDownloadRecursively ("B");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_rename_virtual () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        ItemCompletedSpy complete_spy (fake_folder);

        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        fake_folder.remote_modifier ().insert ("file1", 128, 'C');
        fake_folder.remote_modifier ().insert ("file2", 256, 'C');
        fake_folder.remote_modifier ().insert ("file3", 256, 'C');
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_VIRTUAL (fake_folder, "file1");
        XAVERIFY_VIRTUAL (fake_folder, "file2");
        XAVERIFY_VIRTUAL (fake_folder, "file3");

        on_signal_cleanup ();

        fake_folder.local_modifier ().rename ("file1", "renamed1");
        fake_folder.local_modifier ().rename ("file2", "renamed2");
        triggerDownload (fake_folder, "file2");
        triggerDownload (fake_folder, "file3");
        GLib.assert_true (fake_folder.sync_once ());

        CFVERIFY_GONE (fake_folder, "file1");
        XAVERIFY_VIRTUAL (fake_folder, "renamed1");

        GLib.assert_true (fake_folder.current_remote_state ().find ("renamed1"));
        GLib.assert_true (itemInstruction (complete_spy, "renamed1", CSYNC_INSTRUCTION_RENAME));

        // file2 has a conflict between the download request and the rename:
        // the rename wins, the download is ignored

        CFVERIFY_GONE (fake_folder, "file2");
        XAVERIFY_VIRTUAL (fake_folder, "renamed2");

        GLib.assert_true (fake_folder.current_remote_state ().find ("renamed2"));
        GLib.assert_true (itemInstruction (complete_spy, "renamed2", CSYNC_INSTRUCTION_RENAME));

        GLib.assert_true (itemInstruction (complete_spy, "file3", CSYNC_INSTRUCTION_SYNC));
        XAVERIFY_NONVIRTUAL (fake_folder, "file3");
        on_signal_cleanup ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_rename_virtual2 () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        setupVfs (fake_folder);
        ItemCompletedSpy complete_spy (fake_folder);
        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        fake_folder.remote_modifier ().insert ("case3", 128, 'C');
        fake_folder.remote_modifier ().insert ("case4", 256, 'C');
        GLib.assert_true (fake_folder.sync_once ());

        triggerDownload (fake_folder, "case4");
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_VIRTUAL (fake_folder, "case3");
        XAVERIFY_NONVIRTUAL (fake_folder, "case4");

        on_signal_cleanup ();

        // Case 1 : non-virtual, foo . bar (tested elsewhere)
        // Case 2 : virtual, foo . bar (tested elsewhere)

        // Case 3 : virtual, foo.oc . bar.oc (database hydrate)
        fake_folder.local_modifier ().rename ("case3", "case3-rename");
        triggerDownload (fake_folder, "case3");

        // Case 4 : non-virtual foo . bar (database dehydrate)
        fake_folder.local_modifier ().rename ("case4", "case4-rename");
        markForDehydration (fake_folder, "case4");

        GLib.assert_true (fake_folder.sync_once ());

        // Case 3 : the rename went though, hydration is forgotten
        CFVERIFY_GONE (fake_folder, "case3");
        XAVERIFY_VIRTUAL (fake_folder, "case3-rename");
        GLib.assert_true (!fake_folder.current_remote_state ().find ("case3"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("case3-rename"));
        GLib.assert_true (itemInstruction (complete_spy, "case3-rename", CSYNC_INSTRUCTION_RENAME));

        // Case 4 : the rename went though, dehydration is forgotten
        CFVERIFY_GONE (fake_folder, "case4");
        XAVERIFY_NONVIRTUAL (fake_folder, "case4-rename");
        GLib.assert_true (!fake_folder.current_remote_state ().find ("case4"));
        GLib.assert_true (fake_folder.current_remote_state ().find ("case4-rename"));
        GLib.assert_true (itemInstruction (complete_spy, "case4-rename", CSYNC_INSTRUCTION_RENAME));
    }

    // Dehydration via sync works
    private void on_signal_test_sync_dehydration () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        setupVfs (fake_folder);

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        ItemCompletedSpy complete_spy (fake_folder);
        var on_signal_cleanup = [&] () {
            complete_spy.clear ();
        }
        on_signal_cleanup ();

        //
        // Mark for dehydration and check
        //

        markForDehydration (fake_folder, "A/a1");

        markForDehydration (fake_folder, "A/a2");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        // expect : normal dehydration

        markForDehydration (fake_folder, "B/b1");
        fake_folder.remote_modifier ().remove ("B/b1");
        // expect : local removal

        markForDehydration (fake_folder, "B/b2");
        fake_folder.remote_modifier ().rename ("B/b2", "B/b3");
        // expect : B/b2 is gone, B/b3 is NEW placeholder

        markForDehydration (fake_folder, "C/c1");
        fake_folder.local_modifier ().append_byte ("C/c1");
        // expect : no dehydration, upload of c1

        markForDehydration (fake_folder, "C/c2");
        fake_folder.local_modifier ().append_byte ("C/c2");
        fake_folder.remote_modifier ().append_byte ("C/c2");
        fake_folder.remote_modifier ().append_byte ("C/c2");
        // expect : no dehydration, conflict

        GLib.assert_true (fake_folder.sync_once ());

        var isDehydrated = [&] (string path) {
            return xattr.hasNextcloudPlaceholderAttributes (fake_folder.local_path () + path)
                && GLib.FileInfo (fake_folder.local_path () + path).exists ();
        }
        var hasDehydratedDbEntries = [&] (string path) {
            SyncJournalFileRecord record;
            fake_folder.sync_journal ().get_file_record (path, record);
            return record.is_valid () && record.type == ItemTypeVirtualFile;
        }

        GLib.assert_true (isDehydrated ("A/a1"));
        GLib.assert_true (hasDehydratedDbEntries ("A/a1"));
        GLib.assert_true (itemInstruction (complete_spy, "A/a1", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_cmp (complete_spy.find_item ("A/a1").type, ItemTypeVirtualFileDehydration);
        GLib.assert_cmp (complete_spy.find_item ("A/a1").file, "A/a1");
        GLib.assert_true (isDehydrated ("A/a2"));
        GLib.assert_true (hasDehydratedDbEntries ("A/a2"));
        GLib.assert_true (itemInstruction (complete_spy, "A/a2", CSYNC_INSTRUCTION_SYNC));
        GLib.assert_cmp (complete_spy.find_item ("A/a2").type, ItemTypeVirtualFileDehydration);

        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "B/b1").exists ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b1"));
        GLib.assert_true (itemInstruction (complete_spy, "B/b1", CSYNC_INSTRUCTION_REMOVE));

        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "B/b2").exists ());
        GLib.assert_true (!fake_folder.current_remote_state ().find ("B/b2"));
        GLib.assert_true (isDehydrated ("B/b3"));
        GLib.assert_true (hasDehydratedDbEntries ("B/b3"));
        GLib.assert_true (itemInstruction (complete_spy, "B/b2", CSYNC_INSTRUCTION_REMOVE));
        GLib.assert_true (itemInstruction (complete_spy, "B/b3", CSYNC_INSTRUCTION_NEW));

        GLib.assert_cmp (fake_folder.current_remote_state ().find ("C/c1").size, 25);
        GLib.assert_true (itemInstruction (complete_spy, "C/c1", CSYNC_INSTRUCTION_SYNC));

        GLib.assert_cmp (fake_folder.current_remote_state ().find ("C/c2").size, 26);
        GLib.assert_true (itemInstruction (complete_spy, "C/c2", CSYNC_INSTRUCTION_CONFLICT));
        on_signal_cleanup ();

        var expectedRemoteState = fake_folder.current_remote_state ();
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_remote_state (), expectedRemoteState);

        GLib.assert_true (isDehydrated ("A/a1"));
        GLib.assert_true (hasDehydratedDbEntries ("A/a1"));
        GLib.assert_true (isDehydrated ("A/a2"));
        GLib.assert_true (hasDehydratedDbEntries ("A/a2"));

        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "B/b1").exists ());
        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path () + "B/b2").exists ());
        GLib.assert_true (isDehydrated ("B/b3"));
        GLib.assert_true (hasDehydratedDbEntries ("B/b3"));

        GLib.assert_true (GLib.FileInfo (fake_folder.local_path () + "C/c1").exists ());
        GLib.assert_true (dbRecord (fake_folder, "C/c1").is_valid ());
        GLib.assert_true (!isDehydrated ("C/c1"));
        GLib.assert_true (!hasDehydratedDbEntries ("C/c1"));

        GLib.assert_true (GLib.FileInfo (fake_folder.local_path () + "C/c2").exists ());
        GLib.assert_true (dbRecord (fake_folder, "C/c2").is_valid ());
        GLib.assert_true (!isDehydrated ("C/c2"));
        GLib.assert_true (!hasDehydratedDbEntries ("C/c2"));
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_wipe_virtual_suffix_files () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo{} };
        setupVfs (fake_folder);

        // Create a suffix-vfs baseline

        fake_folder.remote_modifier ().mkdir ("A");
        fake_folder.remote_modifier ().mkdir ("A/B");
        fake_folder.remote_modifier ().insert ("f1");
        fake_folder.remote_modifier ().insert ("A/a1");
        fake_folder.remote_modifier ().insert ("A/a3");
        fake_folder.remote_modifier ().insert ("A/B/b1");
        fake_folder.local_modifier ().mkdir ("A");
        fake_folder.local_modifier ().mkdir ("A/B");
        fake_folder.local_modifier ().insert ("f2");
        fake_folder.local_modifier ().insert ("A/a2");
        fake_folder.local_modifier ().insert ("A/B/b2");

        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_VIRTUAL (fake_folder, "f1");
        XAVERIFY_VIRTUAL (fake_folder, "A/a1");
        XAVERIFY_VIRTUAL (fake_folder, "A/a3");
        XAVERIFY_VIRTUAL (fake_folder, "A/B/b1");

        // Make local changes to a3
        fake_folder.local_modifier ().remove ("A/a3");
        fake_folder.local_modifier ().insert ("A/a3", 100);

        // Now wipe the virtuals
        SyncEngine.wipeVirtualFiles (fake_folder.local_path (), fake_folder.sync_journal (), *fake_folder.sync_engine ().sync_options ().vfs);

        CFVERIFY_GONE (fake_folder, "f1");
        CFVERIFY_GONE (fake_folder, "A/a1");
        GLib.assert_true (GLib.FileInfo (fake_folder.local_path () + "A/a3").exists ());
        GLib.assert_true (!dbRecord (fake_folder, "A/a3").is_valid ());
        CFVERIFY_GONE (fake_folder, "A/B/b1");

        fake_folder.switch_to_vfs (unowned<Vfs> (new VfsOff));
        ItemCompletedSpy complete_spy (fake_folder);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_local_state ().find ("A"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/B"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/B/b1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/B/b2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("f1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("f2"));

        // a3 has a conflict
        GLib.assert_true (itemInstruction (complete_spy, "A/a3", CSYNC_INSTRUCTION_CONFLICT));

        // conflict files should exist
        GLib.assert_cmp (fake_folder.sync_journal ().conflictRecordPaths ().size (), 1);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_new_virtuals () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        var setPin = [&] (GLib.ByteArray path, PinState state) {
            fake_folder.sync_journal ().internalPinStates ().setForPath (path, state);
        }

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        setPin ("local", PinState.PinState.ALWAYS_LOCAL);
        setPin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        setPin ("unspec", PinState.PinState.UNSPECIFIED);

        // Test 1 : root is PinState.UNSPECIFIED
        fake_folder.remote_modifier ().insert ("file1");
        fake_folder.remote_modifier ().insert ("online/file1");
        fake_folder.remote_modifier ().insert ("local/file1");
        fake_folder.remote_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_VIRTUAL (fake_folder, "file1");
        XAVERIFY_VIRTUAL (fake_folder, "online/file1");
        XAVERIFY_NONVIRTUAL (fake_folder, "local/file1");
        XAVERIFY_VIRTUAL (fake_folder, "unspec/file1");

        // Test 2 : change root to PinState.ALWAYS_LOCAL
        setPin (GLib.ByteArray (), PinState.PinState.ALWAYS_LOCAL);

        fake_folder.remote_modifier ().insert ("file2");
        fake_folder.remote_modifier ().insert ("online/file2");
        fake_folder.remote_modifier ().insert ("local/file2");
        fake_folder.remote_modifier ().insert ("unspec/file2");
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_NONVIRTUAL (fake_folder, "file2");
        XAVERIFY_VIRTUAL (fake_folder, "online/file2");
        XAVERIFY_NONVIRTUAL (fake_folder, "local/file2");
        XAVERIFY_VIRTUAL (fake_folder, "unspec/file2");

        // root file1 was hydrated due to its new pin state
        XAVERIFY_NONVIRTUAL (fake_folder, "file1");

        // file1 is unchanged in the explicitly pinned subfolders
        XAVERIFY_VIRTUAL (fake_folder, "online/file1");
        XAVERIFY_NONVIRTUAL (fake_folder, "local/file1");
        XAVERIFY_VIRTUAL (fake_folder, "unspec/file1");

        // Test 3 : change root to VfsItemAvailability.ONLINE_ONLY
        setPin (GLib.ByteArray (), PinState.VfsItemAvailability.ONLINE_ONLY);

        fake_folder.remote_modifier ().insert ("file3");
        fake_folder.remote_modifier ().insert ("online/file3");
        fake_folder.remote_modifier ().insert ("local/file3");
        fake_folder.remote_modifier ().insert ("unspec/file3");
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_VIRTUAL (fake_folder, "file3");
        XAVERIFY_VIRTUAL (fake_folder, "online/file3");
        XAVERIFY_NONVIRTUAL (fake_folder, "local/file3");
        XAVERIFY_VIRTUAL (fake_folder, "unspec/file3");

        // root file1 was dehydrated due to its new pin state
        XAVERIFY_VIRTUAL (fake_folder, "file1");

        // file1 is unchanged in the explicitly pinned subfolders
        XAVERIFY_VIRTUAL (fake_folder, "online/file1");
        XAVERIFY_NONVIRTUAL (fake_folder, "local/file1");
        XAVERIFY_VIRTUAL (fake_folder, "unspec/file1");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_availability () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        var vfs = setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        var setPin = [&] (GLib.ByteArray path, PinState state) {
            fake_folder.sync_journal ().internalPinStates ().setForPath (path, state);
        }

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("local/sub");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("online/sub");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        setPin ("local", PinState.PinState.ALWAYS_LOCAL);
        setPin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        setPin ("unspec", PinState.PinState.UNSPECIFIED);

        fake_folder.remote_modifier ().insert ("file1");
        fake_folder.remote_modifier ().insert ("online/file1");
        fake_folder.remote_modifier ().insert ("online/file2");
        fake_folder.remote_modifier ().insert ("local/file1");
        fake_folder.remote_modifier ().insert ("local/file2");
        fake_folder.remote_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());

        // root is unspecified
        GLib.assert_cmp (*vfs.availability ("file1"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);
        GLib.assert_cmp (*vfs.availability ("local"), VfsItemAvailability.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (*vfs.availability ("local/file1"), VfsItemAvailability.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.availability ("online/file1"), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.availability ("unspec"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);
        GLib.assert_cmp (*vfs.availability ("unspec/file1"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);

        // Subitem pin states can ruin "pure" availabilities
        setPin ("local/sub", PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.availability ("local"), VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED);
        setPin ("online/sub", PinState.PinState.UNSPECIFIED);
        GLib.assert_cmp (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ALL_DEHYDRATED);

        triggerDownload (fake_folder, "unspec/file1");
        setPin ("local/file2", PinState.VfsItemAvailability.ONLINE_ONLY);
        setPin ("online/file2", PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_cmp (*vfs.availability ("unspec"), VfsItemAvailability.VfsItemAvailability.ALL_HYDRATED);
        GLib.assert_cmp (*vfs.availability ("local"), VfsItemAvailability.VfsItemAvailability.MIXED);
        GLib.assert_cmp (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.MIXED);

        GLib.assert_true (vfs.setPinState ("local", PinState.PinState.ALWAYS_LOCAL));
        GLib.assert_true (vfs.setPinState ("online", PinState.VfsItemAvailability.ONLINE_ONLY));
        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_cmp (*vfs.availability ("online"), VfsItemAvailability.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.availability ("local"), VfsItemAvailability.PinState.ALWAYS_LOCAL);

        var r = vfs.availability ("nonexistant");
        GLib.assert_true (!r);
        GLib.assert_cmp (r.error (), Vfs.AvailabilityError.NO_SUCH_ITEM);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_pin_state_locals () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        var vfs = setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        var setPin = [&] (GLib.ByteArray path, PinState state) {
            fake_folder.sync_journal ().internalPinStates ().setForPath (path, state);
        }

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        fake_folder.remote_modifier ().mkdir ("unspec");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        setPin ("local", PinState.PinState.ALWAYS_LOCAL);
        setPin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);
        setPin ("unspec", PinState.PinState.UNSPECIFIED);

        fake_folder.local_modifier ().insert ("file1");
        fake_folder.local_modifier ().insert ("online/file1");
        fake_folder.local_modifier ().insert ("online/file2");
        fake_folder.local_modifier ().insert ("local/file1");
        fake_folder.local_modifier ().insert ("unspec/file1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // root is unspecified
        GLib.assert_cmp (*vfs.pinState ("file1"), PinState.PinState.UNSPECIFIED);
        GLib.assert_cmp (*vfs.pinState ("local/file1"), PinState.PinState.ALWAYS_LOCAL);
        GLib.assert_cmp (*vfs.pinState ("online/file1"), PinState.PinState.UNSPECIFIED);
        GLib.assert_cmp (*vfs.pinState ("unspec/file1"), PinState.PinState.UNSPECIFIED);

        // Sync again : bad pin states of new local files usually take effect on second sync
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // When a file in an online-only folder is renamed, it retains its pin
        fake_folder.local_modifier ().rename ("online/file1", "online/file1rename");
        fake_folder.remote_modifier ().rename ("online/file2", "online/file2rename");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (*vfs.pinState ("online/file1rename"), PinState.PinState.UNSPECIFIED);
        GLib.assert_cmp (*vfs.pinState ("online/file2rename"), PinState.PinState.UNSPECIFIED);

        // When a folder is renamed, the pin states inside should be retained
        fake_folder.local_modifier ().rename ("online", "onlinerenamed1");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (*vfs.pinState ("onlinerenamed1"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.pinState ("onlinerenamed1/file1rename"), PinState.PinState.UNSPECIFIED);

        fake_folder.remote_modifier ().rename ("onlinerenamed1", "onlinerenamed2");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (*vfs.pinState ("onlinerenamed2"), PinState.VfsItemAvailability.ONLINE_ONLY);
        GLib.assert_cmp (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.PinState.UNSPECIFIED);

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // When a file is deleted and later a new file has the same name, the old pin
        // state isn't preserved.
        GLib.assert_cmp (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.PinState.UNSPECIFIED);
        fake_folder.remote_modifier ().remove ("onlinerenamed2/file1rename");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.VfsItemAvailability.ONLINE_ONLY);
        fake_folder.remote_modifier ().insert ("onlinerenamed2/file1rename");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.VfsItemAvailability.ONLINE_ONLY);

        // When a file is hydrated or dehydrated due to pin state it retains its pin state
        GLib.assert_true (vfs.setPinState ("onlinerenamed2/file1rename", PinState.PinState.ALWAYS_LOCAL));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("onlinerenamed2/file1rename"));
        GLib.assert_cmp (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.PinState.ALWAYS_LOCAL);

        GLib.assert_true (vfs.setPinState ("onlinerenamed2", PinState.PinState.UNSPECIFIED));
        GLib.assert_true (vfs.setPinState ("onlinerenamed2/file1rename", PinState.VfsItemAvailability.ONLINE_ONLY));
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_VIRTUAL (fake_folder, "onlinerenamed2/file1rename");

        GLib.assert_cmp (*vfs.pinState ("onlinerenamed2/file1rename"), PinState.VfsItemAvailability.ONLINE_ONLY);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_incompatible_pins () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        var vfs = setupVfs (fake_folder);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        var setPin = [&] (GLib.ByteArray path, PinState state) {
            fake_folder.sync_journal ().internalPinStates ().setForPath (path, state);
        }

        fake_folder.remote_modifier ().mkdir ("local");
        fake_folder.remote_modifier ().mkdir ("online");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        setPin ("local", PinState.PinState.ALWAYS_LOCAL);
        setPin ("online", PinState.VfsItemAvailability.ONLINE_ONLY);

        fake_folder.local_modifier ().insert ("local/file1");
        fake_folder.local_modifier ().insert ("online/file1");
        GLib.assert_true (fake_folder.sync_once ());

        markForDehydration (fake_folder, "local/file1");
        triggerDownload (fake_folder, "online/file1");

        // the sync sets the changed files pin states to unspecified
        GLib.assert_true (fake_folder.sync_once ());

        XAVERIFY_NONVIRTUAL (fake_folder, "online/file1");
        XAVERIFY_VIRTUAL (fake_folder, "local/file1");
        GLib.assert_cmp (*vfs.pinState ("online/file1"), PinState.PinState.UNSPECIFIED);
        GLib.assert_cmp (*vfs.pinState ("local/file1"), PinState.PinState.UNSPECIFIED);

        // no change on another sync
        GLib.assert_true (fake_folder.sync_once ());
        XAVERIFY_NONVIRTUAL (fake_folder, "online/file1");
        XAVERIFY_VIRTUAL (fake_folder, "local/file1");
    }
}

QTEST_GUILESS_MAIN (TestSyncXAttr)
