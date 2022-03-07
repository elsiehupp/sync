/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

static void applyPermissionsFromName (FileInfo info) {
    static QRegularExpression rx ("this.PERM_ ([^this.]*)this.[^/]*$");
    var m = rx.match (info.name);
    if (m.hasMatch ()) {
        info.permissions = RemotePermissions.fromServerString (m.captured (1));
    }

    for (FileInfo sub : info.children)
        applyPermissionsFromName (sub);
}

// Check if the expected rows in the DB are non-empty. Note that in some cases they might be, then we cannot use this function
// https://github.com/owncloud/client/issues/2038
static void assertCsyncJournalOk (SyncJournalDb journal) {
    // The DB is openend in locked mode : close to allow us to access.
    journal.close ();

    SqlDatabase database;
    //  QVERIFY (database.openReadOnly (journal.databaseFilePath ()));
    SqlQuery q ("SELECT count (*) from metadata where length (file_identifier) == 0", database);
    //  QVERIFY (q.exec ());
    //  QVERIFY (q.next ().hasData);
    //  QCOMPARE (q.intValue (0), 0);
}

SyncFileItemPtr findDiscoveryItem (SyncFileItemVector spy, string path) {
    for (var item : spy) {
        if (item.destination () == path)
            return item;
    }
    return SyncFileItemPtr (new SyncFileItem);
}

bool itemInstruction (ItemCompletedSpy spy, string path, SyncInstructions instr) {
    var item = spy.findItem (path);
    return item.instruction == instr;
}

bool discoveryInstruction (SyncFileItemVector spy, string path, SyncInstructions instr) {
    var item = findDiscoveryItem (spy, path);
    return item.instruction == instr;
}

class TestPermissions : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void t7pl () {
        FakeFolder fake_folder = new FakeFolder ( FileInfo ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Some of this test depends on the order of discovery. With threading
        // that order becomes effectively random, but we want to make sure to test
        // all cases and thus disable threading.
        var syncOpts = fake_folder.sync_engine ().syncOptions ();
        syncOpts.parallelNetworkJobs = 1;
        fake_folder.sync_engine ().setSyncOptions (syncOpts);

        const int cannotBeModifiedSize = 133;
        const int canBeModifiedSize = 144;

        //create some files
        var insertIn = [&] (string directory) {
            fake_folder.remote_modifier ().insert (directory + "normalFile_PERM_WVND_.data", 100 );
            fake_folder.remote_modifier ().insert (directory + "cannotBeRemoved_PERM_WVN_.data", 101 );
            fake_folder.remote_modifier ().insert (directory + "canBeRemoved_PERM_D_.data", 102 );
            fake_folder.remote_modifier ().insert (directory + "cannotBeModified_PERM_DVN_.data", cannotBeModifiedSize , 'A');
            fake_folder.remote_modifier ().insert (directory + "canBeModified_PERM_W_.data", canBeModifiedSize );
        }

        //put them in some directories
        fake_folder.remote_modifier ().mkdir ("normalDirectory_PERM_CKDNV_");
        insertIn ("normalDirectory_PERM_CKDNV_/");
        fake_folder.remote_modifier ().mkdir ("readonlyDirectory_PERM_M_" );
        insertIn ("readonlyDirectory_PERM_M_/" );
        fake_folder.remote_modifier ().mkdir ("readonlyDirectory_PERM_M_/subdir_PERM_CK_");
        fake_folder.remote_modifier ().mkdir ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_");
        fake_folder.remote_modifier ().insert ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normalFile_PERM_WVND_.data", 100);
        applyPermissionsFromName (fake_folder.remote_modifier ());

        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
        assertCsyncJournalOk (fake_folder.sync_journal ());
        GLib.info ("Do some changes and see how they propagate");

        //1. remove the file than cannot be removed
        //  (they should be recovered)
        fake_folder.local_modifier ().remove ("normalDirectory_PERM_CKDNV_/cannotBeRemoved_PERM_WVN_.data");
        fake_folder.local_modifier ().remove ("readonlyDirectory_PERM_M_/cannotBeRemoved_PERM_WVN_.data");

        //2. remove the file that can be removed
        //  (they should properly be gone)
        var removeReadOnly = [&] (string file)  {
            //  QVERIFY (!GLib.FileInfo (fake_folder.local_path () + file).permission (GLib.File.WriteOwner));
            GLib.File (fake_folder.local_path () + file).setPermissions (GLib.File.WriteOwner | GLib.File.ReadOwner);
            fake_folder.local_modifier ().remove (file);
        }
        removeReadOnly ("normalDirectory_PERM_CKDNV_/canBeRemoved_PERM_D_.data");
        removeReadOnly ("readonlyDirectory_PERM_M_/canBeRemoved_PERM_D_.data");

        //3. Edit the files that cannot be modified
        //  (they should be recovered, and a conflict shall be created)
        var editReadOnly = [&] (string file)  {
            //  QVERIFY (!GLib.FileInfo (fake_folder.local_path () + file).permission (GLib.File.WriteOwner));
            GLib.File (fake_folder.local_path () + file).setPermissions (GLib.File.WriteOwner | GLib.File.ReadOwner);
            fake_folder.local_modifier ().append_byte (file);
        }
        editReadOnly ("normalDirectory_PERM_CKDNV_/cannotBeModified_PERM_DVN_.data");
        editReadOnly ("readonlyDirectory_PERM_M_/cannotBeModified_PERM_DVN_.data");

        //4. Edit other files
        //  (they should be uploaded)
        fake_folder.local_modifier ().append_byte ("normalDirectory_PERM_CKDNV_/canBeModified_PERM_W_.data");
        fake_folder.local_modifier ().append_byte ("readonlyDirectory_PERM_M_/canBeModified_PERM_W_.data");

        //5. Create a new file in a read write folder
        // (should be uploaded)
        fake_folder.local_modifier ().insert ("normalDirectory_PERM_CKDNV_/newFile_PERM_WDNV_.data", 106 );
        applyPermissionsFromName (fake_folder.remote_modifier ());

        //do the sync
        //  QVERIFY (fake_folder.sync_once ());
        assertCsyncJournalOk (fake_folder.sync_journal ());
        var current_local_state = fake_folder.current_local_state ();

        //1.
        // File should be recovered
        //  QVERIFY (current_local_state.find ("normalDirectory_PERM_CKDNV_/cannotBeRemoved_PERM_WVN_.data"));
        //  QVERIFY (current_local_state.find ("readonlyDirectory_PERM_M_/cannotBeRemoved_PERM_WVN_.data"));

        //2.
        // File should be deleted
        //  QVERIFY (!current_local_state.find ("normalDirectory_PERM_CKDNV_/canBeRemoved_PERM_D_.data"));
        //  QVERIFY (!current_local_state.find ("readonlyDirectory_PERM_M_/canBeRemoved_PERM_D_.data"));

        //3.
        // File should be recovered
        //  QCOMPARE (current_local_state.find ("normalDirectory_PERM_CKDNV_/cannotBeModified_PERM_DVN_.data").size, cannotBeModifiedSize);
        //  QCOMPARE (current_local_state.find ("readonlyDirectory_PERM_M_/cannotBeModified_PERM_DVN_.data").size, cannotBeModifiedSize);
        // and conflict created
        var c1 = find_conflict (current_local_state, "normalDirectory_PERM_CKDNV_/cannotBeModified_PERM_DVN_.data");
        //  QVERIFY (c1);
        //  QCOMPARE (c1.size, cannotBeModifiedSize + 1);
        var c2 = find_conflict (current_local_state, "readonlyDirectory_PERM_M_/cannotBeModified_PERM_DVN_.data");
        //  QVERIFY (c2);
        //  QCOMPARE (c2.size, cannotBeModifiedSize + 1);
        // remove the conflicts for the next state comparison
        fake_folder.local_modifier ().remove (c1.path ());
        fake_folder.local_modifier ().remove (c2.path ());

        //4. File should be updated, that's tested by assertLocalAndRemoteDir
        //  QCOMPARE (current_local_state.find ("normalDirectory_PERM_CKDNV_/canBeModified_PERM_W_.data").size, canBeModifiedSize + 1);
        //  QCOMPARE (current_local_state.find ("readonlyDirectory_PERM_M_/canBeModified_PERM_W_.data").size, canBeModifiedSize + 1);

        //5.
        // the file should be in the server and local
        //  QVERIFY (current_local_state.find ("normalDirectory_PERM_CKDNV_/newFile_PERM_WDNV_.data"));

        // Both side should still be the same
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // Next test

        //6. Create a new file in a read only folder
        // (they should not be uploaded)
        fake_folder.local_modifier ().insert ("readonlyDirectory_PERM_M_/newFile_PERM_WDNV_.data", 105 );

        applyPermissionsFromName (fake_folder.remote_modifier ());
        // error : can't upload to read_only
        //  QVERIFY (!fake_folder.sync_once ());

        assertCsyncJournalOk (fake_folder.sync_journal ());
        current_local_state = fake_folder.current_local_state ();

        //6.
        // The file should not exist on the remote, but still be there
        //  QVERIFY (current_local_state.find ("readonlyDirectory_PERM_M_/newFile_PERM_WDNV_.data"));
        //  QVERIFY (!fake_folder.current_remote_state ().find ("readonlyDirectory_PERM_M_/newFile_PERM_WDNV_.data"));
        // remove it so next test succeed.
        fake_folder.local_modifier ().remove ("readonlyDirectory_PERM_M_/newFile_PERM_WDNV_.data");
        // Both side should still be the same
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        //######################################################################
        GLib.info ( "remove the read only directory" );
        // . It must be recovered
        fake_folder.local_modifier ().remove ("readonlyDirectory_PERM_M_");
        applyPermissionsFromName (fake_folder.remote_modifier ());
        //  QVERIFY (fake_folder.sync_once ());
        assertCsyncJournalOk (fake_folder.sync_journal ());
        current_local_state = fake_folder.current_local_state ();
        //  QVERIFY (current_local_state.find ("readonlyDirectory_PERM_M_/cannotBeRemoved_PERM_WVN_.data"));
        //  QVERIFY (current_local_state.find ("readonlyDirectory_PERM_M_/subdir_PERM_CK_"));
        // the subdirectory had delete permissions, so the contents were deleted
        //  QVERIFY (!current_local_state.find ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_"));
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // restore
        fake_folder.remote_modifier ().mkdir ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_");
        fake_folder.remote_modifier ().insert ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normalFile_PERM_WVND_.data");
        applyPermissionsFromName (fake_folder.remote_modifier ());
        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        //######################################################################
        GLib.info ( "move a directory in a outside read only folder" );

        //Missing directory should be restored
        //new directory should be uploaded
        fake_folder.local_modifier ().rename ("readonlyDirectory_PERM_M_/subdir_PERM_CK_", "normalDirectory_PERM_CKDNV_/subdir_PERM_CKDNV_");
        applyPermissionsFromName (fake_folder.remote_modifier ());
        //  QVERIFY (fake_folder.sync_once ());
        current_local_state = fake_folder.current_local_state ();

        // old name restored
        //  QVERIFY (current_local_state.find ("readonlyDirectory_PERM_M_/subdir_PERM_CK_"));
        // contents moved (had move permissions)
        //  QVERIFY (!current_local_state.find ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_"));
        //  QVERIFY (!current_local_state.find ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normalFile_PERM_WVND_.data"));

        // new still exist  (and is uploaded)
        //  QVERIFY (current_local_state.find ("normalDirectory_PERM_CKDNV_/subdir_PERM_CKDNV_/subsubdir_PERM_CKDNV_/normalFile_PERM_WVND_.data"));

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        // restore for further tests
        fake_folder.remote_modifier ().mkdir ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_");
        fake_folder.remote_modifier ().insert ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normalFile_PERM_WVND_.data");
        applyPermissionsFromName (fake_folder.remote_modifier ());
        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        //######################################################################
        GLib.info ( "rename a directory in a read only folder and move a directory to a read-only" );

        // do a sync to update the database
        applyPermissionsFromName (fake_folder.remote_modifier ());
        //  QVERIFY (fake_folder.sync_once ());
        assertCsyncJournalOk (fake_folder.sync_journal ());

        //  QVERIFY (fake_folder.current_local_state ().find ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normalFile_PERM_WVND_.data" ));

        //1. rename a directory in a read only folder
        //Missing directory should be restored
        //new directory should stay but not be uploaded
        fake_folder.local_modifier ().rename ("readonlyDirectory_PERM_M_/subdir_PERM_CK_", "readonlyDirectory_PERM_M_/newname_PERM_CK_"  );

        //2. move a directory from read to read only  (move the directory from previous step)
        fake_folder.local_modifier ().rename ("normalDirectory_PERM_CKDNV_/subdir_PERM_CKDNV_", "readonlyDirectory_PERM_M_/moved_PERM_CK_" );

        // error : can't upload to read_only!
        //  QVERIFY (!fake_folder.sync_once ());
        current_local_state = fake_folder.current_local_state ();

        //1.
        // old name restored
        //  QVERIFY (current_local_state.find ("readonlyDirectory_PERM_M_/subdir_PERM_CK_" ));
        // including contents
        //  QVERIFY (current_local_state.find ("readonlyDirectory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normalFile_PERM_WVND_.data" ));
        // new still exist
        //  QVERIFY (current_local_state.find ("readonlyDirectory_PERM_M_/newname_PERM_CK_/subsubdir_PERM_CKDNV_/normalFile_PERM_WVND_.data" ));
        // but is not on server : so remove it localy for the future comarison
        fake_folder.local_modifier ().remove ("readonlyDirectory_PERM_M_/newname_PERM_CK_");

        //2.
        // old removed
        //  QVERIFY (!current_local_state.find ("normalDirectory_PERM_CKDNV_/subdir_PERM_CKDNV_"));
        // but still on the server : the rename causing an error meant the deletes didn't execute
        //  QVERIFY (fake_folder.current_remote_state ().find ("normalDirectory_PERM_CKDNV_/subdir_PERM_CKDNV_"));
        // new still there
        //  QVERIFY (current_local_state.find ("readonlyDirectory_PERM_M_/moved_PERM_CK_/subsubdir_PERM_CKDNV_/normalFile_PERM_WVND_.data" ));
        //but not on server
        fake_folder.local_modifier ().remove ("readonlyDirectory_PERM_M_/moved_PERM_CK_");
        fake_folder.remote_modifier ().remove ("normalDirectory_PERM_CKDNV_/subdir_PERM_CKDNV_");

        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        //######################################################################
        GLib.info ( "multiple restores of a file create different conflict files" );

        fake_folder.remote_modifier ().insert ("readonlyDirectory_PERM_M_/cannotBeModified_PERM_DVN_.data");
        applyPermissionsFromName (fake_folder.remote_modifier ());
        //  QVERIFY (fake_folder.sync_once ());

        editReadOnly ("readonlyDirectory_PERM_M_/cannotBeModified_PERM_DVN_.data");
        fake_folder.local_modifier ().set_contents ("readonlyDirectory_PERM_M_/cannotBeModified_PERM_DVN_.data", 's');
        //do the sync
        applyPermissionsFromName (fake_folder.remote_modifier ());
        //  QVERIFY (fake_folder.sync_once ());
        assertCsyncJournalOk (fake_folder.sync_journal ());

        QThread.sleep (1); // make sure changes have different mtime
        editReadOnly ("readonlyDirectory_PERM_M_/cannotBeModified_PERM_DVN_.data");
        fake_folder.local_modifier ().set_contents ("readonlyDirectory_PERM_M_/cannotBeModified_PERM_DVN_.data", 'd');

        //do the sync
        applyPermissionsFromName (fake_folder.remote_modifier ());
        //  QVERIFY (fake_folder.sync_once ());
        assertCsyncJournalOk (fake_folder.sync_journal ());

        // there should be two conflict files
        current_local_state = fake_folder.current_local_state ();
        int count = 0;
        while (var i = find_conflict (current_local_state, "readonlyDirectory_PERM_M_/cannotBeModified_PERM_DVN_.data")) {
            //  QVERIFY ( (i.content_char == 's') || (i.content_char == 'd'));
            fake_folder.local_modifier ().remove (i.path ());
            current_local_state = fake_folder.current_local_state ();
            count++;
        }
        //  QCOMPARE (count, 2);
        //  QCOMPARE (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ static void setAllPerm (FileInfo file_info, RemotePermissions perm) {
        file_info.permissions = perm;
        for (var subFi : file_info.children)
            setAllPerm (&subFi, perm);
    }

    // What happens if the source can't be moved or the target can't be created?
    private void testForbiddenMoves () {
        FakeFolder fake_folder = new FakeFolder (FileInfo{}};

        // Some of this test depends on the order of discovery. With threading
        // that order becomes effectively random, but we want to make sure to test
        // all cases and thus disable threading.
        var syncOpts = fake_folder.sync_engine ().syncOptions ();
        syncOpts.parallelNetworkJobs = 1;
        fake_folder.sync_engine ().setSyncOptions (syncOpts);

        var lm = fake_folder.local_modifier ();
        var rm = fake_folder.remote_modifier ();
        rm.mkdir ("allowed");
        rm.mkdir ("norename");
        rm.mkdir ("nomove");
        rm.mkdir ("nocreatefile");
        rm.mkdir ("nocreatedir");
        rm.mkdir ("zallowed"); // order of discovery matters

        rm.mkdir ("allowed/sub");
        rm.mkdir ("allowed/sub2");
        rm.insert ("allowed/file");
        rm.insert ("allowed/sub/file");
        rm.insert ("allowed/sub2/file");
        rm.mkdir ("norename/sub");
        rm.insert ("norename/file");
        rm.insert ("norename/sub/file");
        rm.mkdir ("nomove/sub");
        rm.insert ("nomove/file");
        rm.insert ("nomove/sub/file");
        rm.mkdir ("zallowed/sub");
        rm.mkdir ("zallowed/sub2");
        rm.insert ("zallowed/file");
        rm.insert ("zallowed/sub/file");
        rm.insert ("zallowed/sub2/file");

        setAllPerm (rm.find ("norename"), RemotePermissions.fromServerString ("WDVCK"));
        setAllPerm (rm.find ("nomove"), RemotePermissions.fromServerString ("WDNCK"));
        setAllPerm (rm.find ("nocreatefile"), RemotePermissions.fromServerString ("WDNVK"));
        setAllPerm (rm.find ("nocreatedir"), RemotePermissions.fromServerString ("WDNVC"));

        //  QVERIFY (fake_folder.sync_once ());

        // Renaming errors
        lm.rename ("norename/file", "norename/file_renamed");
        lm.rename ("norename/sub", "norename/sub_renamed");
        // Moving errors
        lm.rename ("nomove/file", "allowed/file_moved");
        lm.rename ("nomove/sub", "allowed/sub_moved");
        // Createfile errors
        lm.rename ("allowed/file", "nocreatefile/file");
        lm.rename ("zallowed/file", "nocreatefile/zfile");
        lm.rename ("allowed/sub", "nocreatefile/sub"); // TODO : probably forbidden because it contains file children?
        // Createdir errors
        lm.rename ("allowed/sub2", "nocreatedir/sub2");
        lm.rename ("zallowed/sub2", "nocreatedir/zsub2");

        // also hook into discovery!!
        SyncFileItemVector discovery;
        connect (&fake_folder.sync_engine (), &SyncEngine.aboutToPropagate, this, [&discovery] (var v) { discovery = v; });
        ItemCompletedSpy completeSpy (fake_folder);
        //  QVERIFY (!fake_folder.sync_once ());

        // if renaming doesn't work, just delete+create
        //  QVERIFY (itemInstruction (completeSpy, "norename/file", CSYNC_INSTRUCTION_REMOVE));
        //  QVERIFY (itemInstruction (completeSpy, "norename/sub", CSYNC_INSTRUCTION_NONE));
        //  QVERIFY (discoveryInstruction (discovery, "norename/sub", CSYNC_INSTRUCTION_REMOVE));
        //  QVERIFY (itemInstruction (completeSpy, "norename/file_renamed", CSYNC_INSTRUCTION_NEW));
        //  QVERIFY (itemInstruction (completeSpy, "norename/sub_renamed", CSYNC_INSTRUCTION_NEW));
        // the contents can this.move_
        //  QVERIFY (itemInstruction (completeSpy, "norename/sub_renamed/file", CSYNC_INSTRUCTION_RENAME));

        // simiilarly forbidding moves becomes delete+create
        //  QVERIFY (itemInstruction (completeSpy, "nomove/file", CSYNC_INSTRUCTION_REMOVE));
        //  QVERIFY (itemInstruction (completeSpy, "nomove/sub", CSYNC_INSTRUCTION_NONE));
        //  QVERIFY (discoveryInstruction (discovery, "nomove/sub", CSYNC_INSTRUCTION_REMOVE));
        // nomove/sub/file is removed as part of the directory
        //  QVERIFY (itemInstruction (completeSpy, "allowed/file_moved", CSYNC_INSTRUCTION_NEW));
        //  QVERIFY (itemInstruction (completeSpy, "allowed/sub_moved", CSYNC_INSTRUCTION_NEW));
        //  QVERIFY (itemInstruction (completeSpy, "allowed/sub_moved/file", CSYNC_INSTRUCTION_NEW));

        // when moving to an invalid target, the targets should be an error
        //  QVERIFY (itemInstruction (completeSpy, "nocreatefile/file", CSYNC_INSTRUCTION_ERROR));
        //  QVERIFY (itemInstruction (completeSpy, "nocreatefile/zfile", CSYNC_INSTRUCTION_ERROR));
        //  QVERIFY (itemInstruction (completeSpy, "nocreatefile/sub", CSYNC_INSTRUCTION_RENAME)); // TODO : What does a real server say?
        //  QVERIFY (itemInstruction (completeSpy, "nocreatedir/sub2", CSYNC_INSTRUCTION_ERROR));
        //  QVERIFY (itemInstruction (completeSpy, "nocreatedir/zsub2", CSYNC_INSTRUCTION_ERROR));

        // and the sources of the invalid moves should be restored, not deleted
        // (depending on the order of discovery a follow-up sync is needed)
        //  QVERIFY (itemInstruction (completeSpy, "allowed/file", CSYNC_INSTRUCTION_NONE));
        //  QVERIFY (itemInstruction (completeSpy, "allowed/sub2", CSYNC_INSTRUCTION_NONE));
        //  QVERIFY (itemInstruction (completeSpy, "zallowed/file", CSYNC_INSTRUCTION_NEW));
        //  QVERIFY (itemInstruction (completeSpy, "zallowed/sub2", CSYNC_INSTRUCTION_NEW));
        //  QVERIFY (itemInstruction (completeSpy, "zallowed/sub2/file", CSYNC_INSTRUCTION_NEW));
        //  QCOMPARE (fake_folder.sync_engine ().isAnotherSyncNeeded (), ImmediateFollowUp);

        // A follow-up sync will restore allowed/file and allowed/sub2 and maintain the nocreatedir/file errors
        completeSpy.clear ();
        //  QVERIFY (!fake_folder.sync_once ());

        //  QVERIFY (itemInstruction (completeSpy, "nocreatefile/file", CSYNC_INSTRUCTION_ERROR));
        //  QVERIFY (itemInstruction (completeSpy, "nocreatefile/zfile", CSYNC_INSTRUCTION_ERROR));
        //  QVERIFY (itemInstruction (completeSpy, "nocreatedir/sub2", CSYNC_INSTRUCTION_ERROR));
        //  QVERIFY (itemInstruction (completeSpy, "nocreatedir/zsub2", CSYNC_INSTRUCTION_ERROR));

        //  QVERIFY (itemInstruction (completeSpy, "allowed/file", CSYNC_INSTRUCTION_NEW));
        //  QVERIFY (itemInstruction (completeSpy, "allowed/sub2", CSYNC_INSTRUCTION_NEW));
        //  QVERIFY (itemInstruction (completeSpy, "allowed/sub2/file", CSYNC_INSTRUCTION_NEW));

        var cls = fake_folder.current_local_state ();
        //  QVERIFY (cls.find ("allowed/file"));
        //  QVERIFY (cls.find ("allowed/sub2"));
        //  QVERIFY (cls.find ("zallowed/file"));
        //  QVERIFY (cls.find ("zallowed/sub2"));
        //  QVERIFY (cls.find ("zallowed/sub2/file"));
    }

    // Test for issue #7293
    private void testAllowedMoveForbiddenDelete () {
         FakeFolder fake_folder = new FakeFolder (FileInfo{}};

        // Some of this test depends on the order of discovery. With threading
        // that order becomes effectively random, but we want to make sure to test
        // all cases and thus disable threading.
        var syncOpts = fake_folder.sync_engine ().syncOptions ();
        syncOpts.parallelNetworkJobs = 1;
        fake_folder.sync_engine ().setSyncOptions (syncOpts);

        var lm = fake_folder.local_modifier ();
        var rm = fake_folder.remote_modifier ();
        rm.mkdir ("changeonly");
        rm.mkdir ("changeonly/sub1");
        rm.insert ("changeonly/sub1/file1");
        rm.insert ("changeonly/sub1/filetorname1a");
        rm.insert ("changeonly/sub1/filetorname1z");
        rm.mkdir ("changeonly/sub2");
        rm.insert ("changeonly/sub2/file2");
        rm.insert ("changeonly/sub2/filetorname2a");
        rm.insert ("changeonly/sub2/filetorname2z");

        setAllPerm (rm.find ("changeonly"), RemotePermissions.fromServerString ("NSV"));

        //  QVERIFY (fake_folder.sync_once ());

        lm.rename ("changeonly/sub1/filetorname1a", "changeonly/sub1/aaa1_renamed");
        lm.rename ("changeonly/sub1/filetorname1z", "changeonly/sub1/zzz1_renamed");

        lm.rename ("changeonly/sub2/filetorname2a", "changeonly/sub2/aaa2_renamed");
        lm.rename ("changeonly/sub2/filetorname2z", "changeonly/sub2/zzz2_renamed");

        lm.rename ("changeonly/sub1", "changeonly/aaa");
        lm.rename ("changeonly/sub2", "changeonly/zzz");

        var expectedState = fake_folder.current_local_state ();

        //  QVERIFY (fake_folder.sync_once ());
        //  QCOMPARE (fake_folder.current_local_state (), expectedState);
        //  QCOMPARE (fake_folder.current_remote_state (), expectedState);
    }
}

QTEST_GUILESS_MAIN (TestPermissions)
