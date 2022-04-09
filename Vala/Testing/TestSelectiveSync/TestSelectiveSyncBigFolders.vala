/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <syncengine.h>

namespace Occ {
namespace Testing {

public class TestSelectiveSyncBigFolders : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestSelectiveSyncBigFolders () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        SyncOptions options;
        options.new_big_folder_size_limit = 20000; // 20 K
        fake_folder.sync_engine.set_sync_options (options);

        GLib.List<string> size_requests;
        fake_folder.set_server_override (this.override_delegate);

        GLib.SignalSpy signal_new_big_folder = new GLib.SignalSpy (fake_folder.sync_engine, SyncEngine.signal_new_big_folder);

        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().create_directory ("A/new_big_dir");
        fake_folder.remote_modifier ().create_directory ("A/new_big_dir/sub_directory");
        fake_folder.remote_modifier ().insert ("A/new_big_dir/sub_directory/big_file", options.new_big_folder_size_limit + 10);
        fake_folder.remote_modifier ().insert ("A/new_big_dir/sub_directory/small_file", 10);

        fake_folder.remote_modifier ().create_directory ("B/new_small_dir");
        fake_folder.remote_modifier ().create_directory ("B/new_small_dir/sub_directory");
        fake_folder.remote_modifier ().insert ("B/new_small_dir/sub_directory/small_file", 10);

        // Because the test system don't do that automatically
        fake_folder.remote_modifier ().find ("A/new_big_dir").extra_dav_properties = "<oc:size>20020</oc:size>";
        fake_folder.remote_modifier ().find ("A/new_big_dir/sub_directory").extra_dav_properties = "<oc:size>20020</oc:size>";
        fake_folder.remote_modifier ().find ("B/new_small_dir").extra_dav_properties = "<oc:size>10</oc:size>";
        fake_folder.remote_modifier ().find ("B/new_small_dir/sub_directory").extra_dav_properties = "<oc:size>10</oc:size>";

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (signal_new_big_folder.length == 1);
        GLib.assert_true (signal_new_big_folder.first ()[0].to_string () == "A/new_big_dir");
        GLib.assert_true (signal_new_big_folder.first ()[1].to_bool () == false);
        signal_new_big_folder == "";

        GLib.assert_true (size_requests.length == 2); // "A/new_big_dir" and "B/new_small_dir";
        GLib.assert_true (size_requests.filter ("/sub_directory").length == 0); // at no point we should request the size of the subdirectories
        size_requests == "";

        var old_sync = fake_folder.current_local_state ();
        // syncing again should do the same
        fake_folder.sync_engine.journal.schedule_path_for_remote_discovery ("A/new_big_dir");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == old_sync);
        GLib.assert_true (signal_new_big_folder.length == 1); // (since we don't have a real FolderConnection, the files were not added to any list)
        signal_new_big_folder == "";
        GLib.assert_true (size_requests.length == 1); // "A/new_big_dir";
        size_requests == "";

        // Simulate that we accept all files by seting a wildcard allow list
        fake_folder.sync_engine.journal.set_selective_sync_list (
            SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST,
            { "/" }
        );
        fake_folder.sync_engine.journal.schedule_path_for_remote_discovery ("A/new_big_dir");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (signal_new_big_folder.length == 0);
        GLib.assert_true (size_requests.length == 0);
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private GLib.InputStream override_delegate (Soup.Operation operation, Soup.Request request, GLib.OutputStream device) {
        // Record what path we are querying for the size
        if (request.attribute (Soup.Request.CustomVerbAttribute) == "PROPFIND") {
            if (device.read_all ().contains ("<size ")) {
                size_requests.append (request.url.path);
            }
        }
        return null;
    }

} // class TestSelectiveSyncBigFolders

} // namespace Testing
} // namespace Occ
