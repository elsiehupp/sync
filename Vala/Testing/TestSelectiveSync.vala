/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

//  #include <QtTest>
//  #include <syncengine.h>

using Occ;

namespace Testing {

class TestSelectiveSync : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private void testSelectiveSyncBigFolders () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        SyncOptions options;
        options.newBigFolderSizeLimit = 20000; // 20 K
        fake_folder.sync_engine ().set_sync_options (options);

        string[] sizeRequests;
        fake_folder.set_server_override ((Soup.Operation operation, Soup.Request request, QIODevice device) => {
            // Record what path we are querying for the size
            if (request.attribute (Soup.Request.CustomVerbAttribute) == "PROPFIND") {
                if (device.read_all ().contains ("<size ")) {
                    sizeRequests.append (request.url ().path ());
                }
            }
            return null;
        });

        QSignalSpy newBigFolder (&fake_folder.sync_engine (), &SyncEngine.newBigFolder);

        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());

        fake_folder.remote_modifier ().create_directory ("A/newBigDir");
        fake_folder.remote_modifier ().create_directory ("A/newBigDir/sub_directory");
        fake_folder.remote_modifier ().insert ("A/newBigDir/sub_directory/bigFile", options.newBigFolderSizeLimit + 10);
        fake_folder.remote_modifier ().insert ("A/newBigDir/sub_directory/smallFile", 10);

        fake_folder.remote_modifier ().create_directory ("B/newSmallDir");
        fake_folder.remote_modifier ().create_directory ("B/newSmallDir/sub_directory");
        fake_folder.remote_modifier ().insert ("B/newSmallDir/sub_directory/smallFile", 10);

        // Because the test system don't do that automatically
        fake_folder.remote_modifier ().find ("A/newBigDir").extra_dav_properties = "<oc:size>20020</oc:size>";
        fake_folder.remote_modifier ().find ("A/newBigDir/sub_directory").extra_dav_properties = "<oc:size>20020</oc:size>";
        fake_folder.remote_modifier ().find ("B/newSmallDir").extra_dav_properties = "<oc:size>10</oc:size>";
        fake_folder.remote_modifier ().find ("B/newSmallDir/sub_directory").extra_dav_properties = "<oc:size>10</oc:size>";

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_cmp (newBigFolder.count (), 1);
        GLib.assert_cmp (newBigFolder.first ()[0].to_string (), string ("A/newBigDir"));
        GLib.assert_cmp (newBigFolder.first ()[1].to_bool (), false);
        newBigFolder.clear ();

        GLib.assert_cmp (sizeRequests.count (), 2); // "A/newBigDir" and "B/newSmallDir";
        GLib.assert_cmp (sizeRequests.filter ("/sub_directory").count (), 0); // at no point we should request the size of the subdirectories
        sizeRequests.clear ();

        var oldSync = fake_folder.current_local_state ();
        // syncing again should do the same
        fake_folder.sync_engine ().journal ().schedulePathForRemoteDiscovery (string ("A/newBigDir"));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (fake_folder.current_local_state (), oldSync);
        GLib.assert_cmp (newBigFolder.count (), 1); // (since we don't have a real Folder, the files were not added to any list)
        newBigFolder.clear ();
        GLib.assert_cmp (sizeRequests.count (), 1); // "A/newBigDir";
        sizeRequests.clear ();

        // Simulate that we accept all files by seting a wildcard allow list
        fake_folder.sync_engine ().journal ().set_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_ALLOWLIST,
            string[] () + "/");
        fake_folder.sync_engine ().journal ().schedulePathForRemoteDiscovery (string ("A/newBigDir"));
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_cmp (newBigFolder.count (), 0);
        GLib.assert_cmp (sizeRequests.count (), 0);
        GLib.assert_cmp (fake_folder.current_local_state (), fake_folder.current_remote_state ());
    }
}

QTEST_GUILESS_MAIN (TestSelectiveSync)
