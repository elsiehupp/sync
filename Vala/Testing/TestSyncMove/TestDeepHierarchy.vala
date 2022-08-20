/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDeepHierarchy : AbstractTestSyncMove {

//    /***********************************************************
//    ***********************************************************/
//    private TestDeepHierarchy () {
//        GLib.FETCH (bool, local);
//        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
//        var modifier = local ? fake_folder.local_modifier : fake_folder.remote_modifier ();

//        modifier.mkdir ("FolA");
//        modifier.mkdir ("FolA/FolB");
//        modifier.mkdir ("FolA/FolB/FolC");
//        modifier.mkdir ("FolA/FolB/FolC/FolD");
//        modifier.mkdir ("FolA/FolB/FolC/FolD/FolE");
//        modifier.insert ("FolA/FileA.txt");
//        modifier.insert ("FolA/FolB/FileB.txt");
//        modifier.insert ("FolA/FolB/FolC/FileC.txt");
//        modifier.insert ("FolA/FolB/FolC/FolD/FileD.txt");
//        modifier.insert ("FolA/FolB/FolC/FolD/FolE/FileE.txt");
//        GLib.assert_true (fake_folder.sync_once ());

//        OperationCounter counter;
//        fake_folder.set_server_override (counter.functor ());

//        modifier.insert ("FolA/FileA2.txt");
//        modifier.insert ("FolA/FolB/FileB2.txt");
//        modifier.insert ("FolA/FolB/FolC/FileC2.txt");
//        modifier.insert ("FolA/FolB/FolC/FolD/FileD2.txt");
//        modifier.insert ("FolA/FolB/FolC/FolD/FolE/FileE2.txt");
//        modifier.rename ("FolA", "FolA_Renamed");
//        modifier.rename ("FolA_Renamed/FolB", "FolB_Renamed");
//        modifier.rename ("FolB_Renamed/FolC", "FolA");
//        modifier.rename ("FolA/FolD", "FolA/FolD_Renamed");
//        modifier.mkdir ("FolB_Renamed/New");
//        modifier.rename ("FolA/FolD_Renamed/FolE", "FolB_Renamed/New/FolE");
//        var expected = local ? fake_folder.current_local_state () : fake_folder.current_remote_state ();
//        GLib.assert_true (fake_folder.sync_once ());
//        GLib.assert_true (fake_folder.current_local_state () == expected);
//        GLib.assert_true (fake_folder.current_remote_state () == expected);
//        GLib.assert_true (counter.number_of_delete == local ? 1 : 0); // FolC was is renamed to an existing name, so it is not considered as renamed
//        // There was 5 inserts
//        GLib.assert_true (counter.number_of_get == local ? 0 : 5);
//        GLib.assert_true (counter.number_of_put == local ? 5 : 0);
//    }

} // class TestDeepHierarchy

} // namespace Testing
} // namespace Occ
