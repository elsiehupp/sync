namespace Occ {
namespace Testing {

/***********************************************************
@class TestDownloadRecursive

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestDownloadRecursive : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private static TestDownloadRecursive () {
        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
        set_up_vfs (fake_folder);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

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
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a3" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a4" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/SubSub/a5" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub2/a6" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/b1" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/Sub/b2" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a3"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a4"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/SubSub/a5"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub2/a6"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/Sub/b2"));

        // Download All file in the directory A/Sub
        // (as in Folder.download_virtual_file)
        fake_folder.sync_journal ().mark_virtual_file_for_download_recursively ("A/Sub");

        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a3" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a4" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/SubSub/a5" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub2/a6" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/b1" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/Sub/b2" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a4"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/SubSub/a5"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub2/a6"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/Sub/b2"));

        // Add a file in a subfolder that was downloaded
        // Currently, this continue to add it as a virtual file.
        fake_folder.remote_modifier ().insert ("A/Sub/SubSub/a7");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/SubSub/a7" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/SubSub/a7"));

        // Now download all files in "A"
        fake_folder.sync_journal ().mark_virtual_file_for_download_recursively ("A");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a1" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/a2" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a3" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/a4" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/SubSub/a5" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub2/a6" + DVSUFFIX));
        GLib.assert_true (!fake_folder.current_local_state ().find ("A/Sub/SubSub/a7" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/b1" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("B/Sub/b2" + DVSUFFIX));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a1"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/a2"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a3"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/a4"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/SubSub/a5"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub2/a6"));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/Sub/SubSub/a7"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/b1"));
        GLib.assert_true (!fake_folder.current_local_state ().find ("B/Sub/b2"));

        // Now download remaining files in "B"
        fake_folder.sync_journal ().mark_virtual_file_for_download_recursively ("B");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }

} // class TestDownloadRecursive

} // namespace Testing
} // namespace Occ
