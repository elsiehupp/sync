/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDirectoryInitialModTime : AbstractTestSyncEngine {

//    /***********************************************************
//    Check that server mtime is set on directories on initial
//    propagation
//    ***********************************************************/
//    private TestDirectoryInitialModTime () {
//        FakeFolder fake_folder = new FakeFolder (new FileInfo ());
//        fake_folder.remote_modifier ().mkdir ("foo");
//        fake_folder.remote_modifier ().insert ("foo/bar");
//        var datetime = GLib.DateTime.current_date_time ();
//        datetime.set_secs_since_epoch (datetime.to_seconds_since_epoch ()); // wipe ms
//        fake_folder.remote_modifier ().find ("foo").last_modified = datetime;

//        GLib.assert_true (fake_folder.sync_once ());
//        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

//        GLib.assert_true (new FileInfo (fake_folder.local_path + "foo").last_modified () == datetime);
//    }

} // class TestDirectoryInitialModTime

} // namespace Testing
} // namespace Occ
