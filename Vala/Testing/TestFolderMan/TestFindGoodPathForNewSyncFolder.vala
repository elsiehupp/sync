namespace Occ {
namespace Testing {

/***********************************************************
@class TestFindGoodPathForNewSyncFolder

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestFindGoodPathForNewSyncFolder : AbstractTestFolderMan {

    /***********************************************************
    ***********************************************************/
    private TestFindGoodPathForNewSyncFolder () {
        //  base ();
        //  // SETUP

        //  GLib.TemporaryDir directory;
        //  LibSync.ConfigFile.set_configuration_directory (directory.path); // we don't want to pollute the user's config file
        //  GLib.assert_true (directory.is_valid);
        //  GLib.Dir dir2 = new GLib.Dir (directory.path);
        //  GLib.assert_true (dir2.mkpath ("sub/own_cloud1/folder/file"));
        //  GLib.assert_true (dir2.mkpath ("own_cloud"));
        //  GLib.assert_true (dir2.mkpath ("own_cloud2"));
        //  GLib.assert_true (dir2.mkpath ("own_cloud2/foo"));
        //  GLib.assert_true (dir2.mkpath ("sub/free"));
        //  GLib.assert_true (dir2.mkpath ("free2/sub"));
        //  string directory_path = dir2.canonical_path;

        //  GLib.assert_true (folder_manager == this.folder_manager);
        //  GLib.assert_true (folder_manager.add_folder (account_state, folder_definition (directory_path + "/sub/own_cloud/")));
        //  GLib.assert_true (folder_manager.add_folder (account_state, folder_definition (directory_path + "/own_cloud2/")));

        //  // TEST

        //  GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/oc", url) ==
        //      directory_path + "/oc");
        //  GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud", url) ==
        //      directory_path + "/own_cloud3");
        //  GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud2", url) ==
        //      directory_path + "/own_cloud22");
        //  GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud2/foo", url) ==
        //      directory_path + "/own_cloud2/foo");
        //  GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud2/bar", url) ==
        //      directory_path + "/own_cloud2/bar");
        //  GLib.assert_true (folder_manager.find_good_path_for_new_sync_folder (directory_path + "/sub", url) ==
        //      directory_path + "/sub2");

        //  // REMOVE own_cloud2 from the filesystem, but keep a folder sync'ed to it.
        //  // We should still not suggest this folder as a new folder.
        //  new GLib.Dir (directory_path + "/own_cloud2/").remove_recursively ();
        //  GLib.assert_true (
        //      folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud", url) ==
        //      directory_path + "/own_cloud3"
        //  );
        //  GLib.assert_true (
        //      folder_manager.find_good_path_for_new_sync_folder (directory_path + "/own_cloud2", url) ==
        //      directory_path + "/own_cloud22"
        //  );
    }

} // class TestFindGoodPathForNewSyncFolder

} // namespace Testing
} // namespace Occ
