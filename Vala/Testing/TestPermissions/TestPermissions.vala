/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <syncengine.h>

namespace Occ {
namespace Testing {

public class TestPermissions : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void t7pl () {
        FakeFolder fake_folder = new FakeFolder (FileInfo ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Some of this test depends on the order of discovery. With threading
        // that order becomes effectively random, but we want to make sure to test
        // all cases and thus disable threading.
        var sync_opts = fake_folder.sync_engine.sync_options ();
        sync_opts.parallel_network_jobs = 1;
        fake_folder.sync_engine.set_sync_options (sync_opts);

        const int cannot_be_modified_size = 133;
        const int can_be_modified_size = 144;

        //put them in some directories
        fake_folder.remote_modifier ().mkdir ("normal_directory_PERM_CKDNV_");
        insert_in ("normal_directory_PERM_CKDNV_/");
        fake_folder.remote_modifier ().mkdir ("readonly_directory_PERM_M_" );
        insert_in ("readonly_directory_PERM_M_/" );
        fake_folder.remote_modifier ().mkdir ("readonly_directory_PERM_M_/subdir_PERM_CK_");
        fake_folder.remote_modifier ().mkdir ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_");
        fake_folder.remote_modifier ().insert ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normal_file_PERM_WVND_.data", 100);
        apply_permissions_from_name (fake_folder.remote_modifier ());

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        assert_csync_journal_ok (fake_folder.sync_journal ());
        GLib.info ("Do some changes and see how they propagate");

        //1. remove the file than cannot be removed
        //  (they should be recovered)
        fake_folder.local_modifier.remove ("normal_directory_PERM_CKDNV_/cannot_be_removed_PERM_WVN_.data");
        fake_folder.local_modifier.remove ("readonly_directory_PERM_M_/cannot_be_removed_PERM_WVN_.data");

        //2. remove the file that can be removed
        //  (they should properly be gone)
        remove_read_only ("normal_directory_PERM_CKDNV_/can_be_removed_PERM_D_.data");
        remove_read_only ("readonly_directory_PERM_M_/can_be_removed_PERM_D_.data");

        //3. Edit the files that cannot be modified
        //  (they should be recovered, and a conflict shall be created)
        edit_read_only ("normal_directory_PERM_CKDNV_/cannot_be_modified_PERM_DVN_.data");
        edit_read_only ("readonly_directory_PERM_M_/cannot_be_modified_PERM_DVN_.data");

        //4. Edit other files
        //  (they should be uploaded)
        fake_folder.local_modifier.append_byte ("normal_directory_PERM_CKDNV_/can_be_modified_PERM_W_.data");
        fake_folder.local_modifier.append_byte ("readonly_directory_PERM_M_/can_be_modified_PERM_W_.data");

        //5. Create a new file in a read write folder
        // (should be uploaded)
        fake_folder.local_modifier.insert ("normal_directory_PERM_CKDNV_/new_file_PERM_WDNV_.data", 106 );
        apply_permissions_from_name (fake_folder.remote_modifier ());

        //do the sync
        GLib.assert_true (fake_folder.sync_once ());
        assert_csync_journal_ok (fake_folder.sync_journal ());
        var current_local_state = fake_folder.current_local_state ();

        //1.
        // File should be recovered
        GLib.assert_true (current_local_state.find ("normal_directory_PERM_CKDNV_/cannot_be_removed_PERM_WVN_.data"));
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/cannot_be_removed_PERM_WVN_.data"));

        //2.
        // File should be deleted
        GLib.assert_true (!current_local_state.find ("normal_directory_PERM_CKDNV_/can_be_removed_PERM_D_.data"));
        GLib.assert_true (!current_local_state.find ("readonly_directory_PERM_M_/can_be_removed_PERM_D_.data"));

        //3.
        // File should be recovered
        GLib.assert_true (current_local_state.find ("normal_directory_PERM_CKDNV_/cannot_be_modified_PERM_DVN_.data").size == cannot_be_modified_size);
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/cannot_be_modified_PERM_DVN_.data").size == cannot_be_modified_size);
        // and conflict created
        var c1 = find_conflict (current_local_state, "normal_directory_PERM_CKDNV_/cannot_be_modified_PERM_DVN_.data");
        GLib.assert_true (c1);
        GLib.assert_true (c1.size == cannot_be_modified_size + 1);
        var c2 = find_conflict (current_local_state, "readonly_directory_PERM_M_/cannot_be_modified_PERM_DVN_.data");
        GLib.assert_true (c2);
        GLib.assert_true (c2.size == cannot_be_modified_size + 1);
        // remove the conflicts for the next state comparison
        fake_folder.local_modifier.remove (c1.path);
        fake_folder.local_modifier.remove (c2.path);

        //4. File should be updated, that's tested by assert_local_and_remote_dir
        GLib.assert_true (current_local_state.find ("normal_directory_PERM_CKDNV_/can_be_modified_PERM_W_.data").size == can_be_modified_size + 1);
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/can_be_modified_PERM_W_.data").size == can_be_modified_size + 1);

        //5.
        // the file should be in the server and local
        GLib.assert_true (current_local_state.find ("normal_directory_PERM_CKDNV_/new_file_PERM_WDNV_.data"));

        // Both side should still be the same
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Next test

        //6. Create a new file in a read only folder
        // (they should not be uploaded)
        fake_folder.local_modifier.insert ("readonly_directory_PERM_M_/new_file_PERM_WDNV_.data", 105 );

        apply_permissions_from_name (fake_folder.remote_modifier ());
        // error : can't upload to read_only
        GLib.assert_true (!fake_folder.sync_once ());

        assert_csync_journal_ok (fake_folder.sync_journal ());
        current_local_state = fake_folder.current_local_state ();

        //6.
        // The file should not exist on the remote, but still be there
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/new_file_PERM_WDNV_.data"));
        GLib.assert_true (!fake_folder.current_remote_state ().find ("readonly_directory_PERM_M_/new_file_PERM_WDNV_.data"));
        // remove it so next test succeed.
        fake_folder.local_modifier.remove ("readonly_directory_PERM_M_/new_file_PERM_WDNV_.data");
        // Both side should still be the same
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //######################################################################
        GLib.info ( "remove the read only directory" );
        // . It must be recovered
        fake_folder.local_modifier.remove ("readonly_directory_PERM_M_");
        apply_permissions_from_name (fake_folder.remote_modifier ());
        GLib.assert_true (fake_folder.sync_once ());
        assert_csync_journal_ok (fake_folder.sync_journal ());
        current_local_state = fake_folder.current_local_state ();
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/cannot_be_removed_PERM_WVN_.data"));
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/subdir_PERM_CK_"));
        // the subdirectory had delete permissions, so the contents were deleted
        GLib.assert_true (!current_local_state.find ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_"));
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // restore
        fake_folder.remote_modifier ().mkdir ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_");
        fake_folder.remote_modifier ().insert ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normal_file_PERM_WVND_.data");
        apply_permissions_from_name (fake_folder.remote_modifier ());
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //######################################################################
        GLib.info ( "move a directory in a outside read only folder" );

        //Missing directory should be restored
        //new directory should be uploaded
        fake_folder.local_modifier.rename ("readonly_directory_PERM_M_/subdir_PERM_CK_", "normal_directory_PERM_CKDNV_/subdir_PERM_CKDNV_");
        apply_permissions_from_name (fake_folder.remote_modifier ());
        GLib.assert_true (fake_folder.sync_once ());
        current_local_state = fake_folder.current_local_state ();

        // old name restored
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/subdir_PERM_CK_"));
        // contents moved (had move permissions)
        GLib.assert_true (!current_local_state.find ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_"));
        GLib.assert_true (!current_local_state.find ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normal_file_PERM_WVND_.data"));

        // new still exist  (and is uploaded)
        GLib.assert_true (current_local_state.find ("normal_directory_PERM_CKDNV_/subdir_PERM_CKDNV_/subsubdir_PERM_CKDNV_/normal_file_PERM_WVND_.data"));

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // restore for further tests
        fake_folder.remote_modifier ().mkdir ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_");
        fake_folder.remote_modifier ().insert ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normal_file_PERM_WVND_.data");
        apply_permissions_from_name (fake_folder.remote_modifier ());
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //######################################################################
        GLib.info ( "rename a directory in a read only folder and move a directory to a read-only" );

        // do a sync to update the database
        apply_permissions_from_name (fake_folder.remote_modifier ());
        GLib.assert_true (fake_folder.sync_once ());
        assert_csync_journal_ok (fake_folder.sync_journal ());

        GLib.assert_true (fake_folder.current_local_state ().find ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normal_file_PERM_WVND_.data" ));

        //1. rename a directory in a read only folder
        //Missing directory should be restored
        //new directory should stay but not be uploaded
        fake_folder.local_modifier.rename ("readonly_directory_PERM_M_/subdir_PERM_CK_", "readonly_directory_PERM_M_/newname_PERM_CK_"  );

        //2. move a directory from read to read only  (move the directory from previous step)
        fake_folder.local_modifier.rename ("normal_directory_PERM_CKDNV_/subdir_PERM_CKDNV_", "readonly_directory_PERM_M_/moved_PERM_CK_" );

        // error : can't upload to read_only!
        GLib.assert_true (!fake_folder.sync_once ());
        current_local_state = fake_folder.current_local_state ();

        //1.
        // old name restored
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/subdir_PERM_CK_" ));
        // including contents
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/subdir_PERM_CK_/subsubdir_PERM_CKDNV_/normal_file_PERM_WVND_.data" ));
        // new still exist
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/newname_PERM_CK_/subsubdir_PERM_CKDNV_/normal_file_PERM_WVND_.data" ));
        // but is not on server : so remove it localy for the future comarison
        fake_folder.local_modifier.remove ("readonly_directory_PERM_M_/newname_PERM_CK_");

        //2.
        // old removed
        GLib.assert_true (!current_local_state.find ("normal_directory_PERM_CKDNV_/subdir_PERM_CKDNV_"));
        // but still on the server : the rename causing an error meant the deletes didn't execute
        GLib.assert_true (fake_folder.current_remote_state ().find ("normal_directory_PERM_CKDNV_/subdir_PERM_CKDNV_"));
        // new still there
        GLib.assert_true (current_local_state.find ("readonly_directory_PERM_M_/moved_PERM_CK_/subsubdir_PERM_CKDNV_/normal_file_PERM_WVND_.data" ));
        //but not on server
        fake_folder.local_modifier.remove ("readonly_directory_PERM_M_/moved_PERM_CK_");
        fake_folder.remote_modifier ().remove ("normal_directory_PERM_CKDNV_/subdir_PERM_CKDNV_");

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        //######################################################################
        GLib.info ( "multiple restores of a file create different conflict files" );

        fake_folder.remote_modifier ().insert ("readonly_directory_PERM_M_/cannot_be_modified_PERM_DVN_.data");
        apply_permissions_from_name (fake_folder.remote_modifier ());
        GLib.assert_true (fake_folder.sync_once ());

        edit_read_only ("readonly_directory_PERM_M_/cannot_be_modified_PERM_DVN_.data");
        fake_folder.local_modifier.set_contents ("readonly_directory_PERM_M_/cannot_be_modified_PERM_DVN_.data", 's');
        //do the sync
        apply_permissions_from_name (fake_folder.remote_modifier ());
        GLib.assert_true (fake_folder.sync_once ());
        assert_csync_journal_ok (fake_folder.sync_journal ());

        QThread.sleep (1); // make sure changes have different mtime
        edit_read_only ("readonly_directory_PERM_M_/cannot_be_modified_PERM_DVN_.data");
        fake_folder.local_modifier.set_contents ("readonly_directory_PERM_M_/cannot_be_modified_PERM_DVN_.data", 'd');

        //do the sync
        apply_permissions_from_name (fake_folder.remote_modifier ());
        GLib.assert_true (fake_folder.sync_once ());
        assert_csync_journal_ok (fake_folder.sync_journal ());

        // there should be two conflict files
        current_local_state = fake_folder.current_local_state ();
        int count = 0;
        var i = find_conflict (current_local_state, "readonly_directory_PERM_M_/cannot_be_modified_PERM_DVN_.data");
        while (i) {
            GLib.assert_true ( (i.content_char == 's') || (i.content_char == 'd'));
            fake_folder.local_modifier.remove (i.path);
            current_local_state = fake_folder.current_local_state ();
            count++;
            i = find_conflict (current_local_state, "readonly_directory_PERM_M_/cannot_be_modified_PERM_DVN_.data");
        }
        GLib.assert_true (count == 2);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    // Create some files
    private void insert_in (FakeFolder fake_folder, string directory, int cannot_be_modified_size) {
        fake_folder.remote_modifier ().insert (directory + "normal_file_PERM_WVND_.data", 100 );
        fake_folder.remote_modifier ().insert (directory + "cannot_be_removed_PERM_WVN_.data", 101 );
        fake_folder.remote_modifier ().insert (directory + "can_be_removed_PERM_D_.data", 102 );
        fake_folder.remote_modifier ().insert (directory + "cannot_be_modified_PERM_DVN_.data", cannot_be_modified_size, 'A');
        fake_folder.remote_modifier ().insert (directory + "can_be_modified_PERM_W_.data", can_be_modified_size);
    }


    private void remove_read_only (FakeFolder fake_folder, string file) {
        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path + file).permission (GLib.File.WriteOwner));
        GLib.File (fake_folder.local_path + file).set_permissions (GLib.File.WriteOwner | GLib.File.ReadOwner);
        fake_folder.local_modifier.remove (file);
    }


    private void edit_read_only (FakeFolder fake_folder, string file)  {
        GLib.assert_true (!GLib.FileInfo (fake_folder.local_path + file).permission (GLib.File.WriteOwner));
        GLib.File (fake_folder.local_path + file).set_permissions (GLib.File.WriteOwner | GLib.File.ReadOwner);
        fake_folder.local_modifier.append_byte (file);
    }


    /***********************************************************
    ***********************************************************/
    private static void on_set_all_perm (FileInfo file_info, RemotePermissions remote_permissions) {
        file_info.permissions = remote_permissions;
        foreach (var sub_file_info in file_info.children) {
            on_set_all_perm (sub_file_info, remote_permissions);
        }
    }

    // What happens if the source can't be moved or the target can't be created?
    private void test_forbidden_moves () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());

        // Some of this test depends on the order of discovery. With threading
        // that order becomes effectively random, but we want to make sure to test
        // all cases and thus disable threading.
        var sync_opts = fake_folder.sync_engine.sync_options ();
        sync_opts.parallel_network_jobs = 1;
        fake_folder.sync_engine.set_sync_options (sync_opts);

        var lm = fake_folder.local_modifier;
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

        on_set_all_perm (rm.find ("norename"), RemotePermissions.from_server_string ("WDVCK"));
        on_set_all_perm (rm.find ("nomove"), RemotePermissions.from_server_string ("WDNCK"));
        on_set_all_perm (rm.find ("nocreatefile"), RemotePermissions.from_server_string ("WDNVK"));
        on_set_all_perm (rm.find ("nocreatedir"), RemotePermissions.from_server_string ("WDNVC"));

        GLib.assert_true (fake_folder.sync_once ());

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
        fake_folder.sync_engine.signal_about_to_propagate.connect (
            this.on_signal_sync_engine_about_to_propagate
        );
        ItemCompletedSpy complete_spy = new ItemCompletedSpy (fake_folder);
        GLib.assert_true (!fake_folder.sync_once ());

        // if renaming doesn't work, just delete+create
        GLib.assert_true (item_instruction (complete_spy, "norename/file", CSync.SyncInstructions.REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "norename/sub", CSync.SyncInstructions.NONE));
        GLib.assert_true (discovery_instruction (discovery, "norename/sub", CSync.SyncInstructions.REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "norename/file_renamed", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "norename/sub_renamed", CSync.SyncInstructions.NEW));
        // the contents can this.move_
        GLib.assert_true (item_instruction (complete_spy, "norename/sub_renamed/file", CSync.SyncInstructions.RENAME));

        // simiilarly forbidding moves becomes delete+create
        GLib.assert_true (item_instruction (complete_spy, "nomove/file", CSync.SyncInstructions.REMOVE));
        GLib.assert_true (item_instruction (complete_spy, "nomove/sub", CSync.SyncInstructions.NONE));
        GLib.assert_true (discovery_instruction (discovery, "nomove/sub", CSync.SyncInstructions.REMOVE));
        // nomove/sub/file is removed as part of the directory
        GLib.assert_true (item_instruction (complete_spy, "allowed/file_moved", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "allowed/sub_moved", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "allowed/sub_moved/file", CSync.SyncInstructions.NEW));

        // when moving to an invalid target, the targets should be an error
        GLib.assert_true (item_instruction (complete_spy, "nocreatefile/file", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatefile/zfile", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatefile/sub", CSync.SyncInstructions.RENAME)); // TODO : What does a real server say?
        GLib.assert_true (item_instruction (complete_spy, "nocreatedir/sub2", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatedir/zsub2", CSync.SyncInstructions.ERROR));

        // and the sources of the invalid moves should be restored, not deleted
        // (depending on the order of discovery a follow-up sync is needed)
        GLib.assert_true (item_instruction (complete_spy, "allowed/file", CSync.SyncInstructions.NONE));
        GLib.assert_true (item_instruction (complete_spy, "allowed/sub2", CSync.SyncInstructions.NONE));
        GLib.assert_true (item_instruction (complete_spy, "zallowed/file", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "zallowed/sub2", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "zallowed/sub2/file", CSync.SyncInstructions.NEW));
        GLib.assert_true (fake_folder.sync_engine.is_another_sync_needed () == ImmediateFollowUp);

        // A follow-up sync will restore allowed/file and allowed/sub2 and maintain the nocreatedir/file errors
        complete_spy.clear ();
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (item_instruction (complete_spy, "nocreatefile/file", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatefile/zfile", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatedir/sub2", CSync.SyncInstructions.ERROR));
        GLib.assert_true (item_instruction (complete_spy, "nocreatedir/zsub2", CSync.SyncInstructions.ERROR));

        GLib.assert_true (item_instruction (complete_spy, "allowed/file", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "allowed/sub2", CSync.SyncInstructions.NEW));
        GLib.assert_true (item_instruction (complete_spy, "allowed/sub2/file", CSync.SyncInstructions.NEW));

        var cls = fake_folder.current_local_state ();
        GLib.assert_true (cls.find ("allowed/file"));
        GLib.assert_true (cls.find ("allowed/sub2"));
        GLib.assert_true (cls.find ("zallowed/file"));
        GLib.assert_true (cls.find ("zallowed/sub2"));
        GLib.assert_true (cls.find ("zallowed/sub2/file"));
    }


    private void on_signal_sync_engine_about_to_propagate (SyncFileItemVector *discovery, SyncFileItemVector v) {
        discovery = *v;
    }


    // Test for issue #7293
    private void test_allowed_move_forbidden_delete () {
         FakeFolder fake_folder = new FakeFolder (new FileInfo ());

        // Some of this test depends on the order of discovery. With threading
        // that order becomes effectively random, but we want to make sure to test
        // all cases and thus disable threading.
        var sync_opts = fake_folder.sync_engine.sync_options ();
        sync_opts.parallel_network_jobs = 1;
        fake_folder.sync_engine.set_sync_options (sync_opts);

        var lm = fake_folder.local_modifier;
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

        on_set_all_perm (rm.find ("changeonly"), RemotePermissions.from_server_string ("NSV"));

        GLib.assert_true (fake_folder.sync_once ());

        lm.rename ("changeonly/sub1/filetorname1a", "changeonly/sub1/aaa1_renamed");
        lm.rename ("changeonly/sub1/filetorname1z", "changeonly/sub1/zzz1_renamed");

        lm.rename ("changeonly/sub2/filetorname2a", "changeonly/sub2/aaa2_renamed");
        lm.rename ("changeonly/sub2/filetorname2z", "changeonly/sub2/zzz2_renamed");

        lm.rename ("changeonly/sub1", "changeonly/aaa");
        lm.rename ("changeonly/sub2", "changeonly/zzz");

        var expected_state = fake_folder.current_local_state ();

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == expected_state);
        GLib.assert_true (fake_folder.current_remote_state () == expected_state);
    }

    static void apply_permissions_from_name (FileInfo info) {
        QRegularExpression regular_expression = new QRegularExpression ("this.PERM_ ([^this.]*)this.[^/]*$");
        var m = regular_expression.match (info.name);
        if (m.has_match ()) {
            info.permissions = RemotePermissions.from_server_string (m.captured (1));
        }
    
        foreach (FileInfo sub in info.children) {
            apply_permissions_from_name (sub);
        }
    }
    
    // Check if the expected rows in the DB are non-empty. Note that in some cases they might be, then we cannot use this function
    // https://github.com/owncloud/client/issues/2038
    static void assert_csync_journal_ok (SyncJournalDb journal) {
        // The DB is openend in locked mode : close to allow us to access.
        journal.close ();
    
        SqlDatabase database;
        GLib.assert_true (database.open_read_only (journal.database_file_path));
        SqlQuery q = new SqlQuery ("SELECT count (*) from metadata where length (file_identifier) == 0", database);
        GLib.assert_true (q.exec ());
        GLib.assert_true (q.next ().has_data);
        GLib.assert_true (q.int_value (0) == 0);
    }
    
    SyncFileItemPtr find_discovery_item (SyncFileItemVector spy, string path) {
        foreach (var item in spy) {
            if (item.destination () == path) {
                return item;
            }
        }
        return new SyncFileItemPtr (new SyncFileItem ());
    }
    
    bool item_instruction (ItemCompletedSpy spy, string path, CSync.SyncInstructions instr) {
        var item = spy.find_item (path);
        return item.instruction == instr;
    }
    
    bool discovery_instruction (SyncFileItemVector spy, string path, CSync.SyncInstructions instr) {
        var item = find_discovery_item (spy, path);
        return item.instruction == instr;
    }

} // class TestPermissions
} // namespace Testing
} // namespace Occ
