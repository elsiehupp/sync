namespace Occ {
namespace Testing {

/***********************************************************
@class TestT7pl

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestT7pl : AbstractTestPermissions {

    /***********************************************************
    ***********************************************************/
    private TestT7pl () {
        FakeFolder fake_folder = new FakeFolder (FileInfo ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Some of this test depends on the order of discovery. With threading
        // that order becomes effectively random, but we want to make sure to test
        // all cases and thus disable threading.
        var sync_opts = fake_folder.sync_engine.sync_options ();
        sync_opts.parallel_network_jobs = 1;
        fake_folder.sync_engine.set_sync_options (sync_opts);

        int cannot_be_modified_size = 133;
        int can_be_modified_size = 144;

        // Put them in some directories
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

        GLib.Thread.sleep (1); // make sure changes have different mtime
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

} // class TestT7pl

} // namespace Testing
} // namespace Occ
