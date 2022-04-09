/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestPropagatePermissions : AbstractTestSyncEngine {

    /***********************************************************
    ***********************************************************/
    private TestPropagatePermissions () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        var perm = GLib.FileDevice.Permission (0x7704); // user/owner : rwx, group : r, other : -
        GLib.File.set_permissions (fake_folder.local_path + "A/a1", perm);
        GLib.File.set_permissions (fake_folder.local_path + "A/a2", perm);
        fake_folder.sync_once (); // get the metadata-only change out of the way
        fake_folder.remote_modifier ().append_byte ("A/a1");
        fake_folder.remote_modifier ().append_byte ("A/a2");
        fake_folder.local_modifier.append_byte ("A/a2");
        fake_folder.local_modifier.append_byte ("A/a2");
        fake_folder.sync_once (); // perms should be preserved
        GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a1").permissions () == perm);
        GLib.assert_true (new FileInfo (fake_folder.local_path + "A/a2").permissions () == perm);

        var conflict_name = fake_folder.sync_journal ().conflict_record (fake_folder.sync_journal ().conflict_record_paths ().first ()).path;
        GLib.assert_true (conflict_name.contains ("A/a2"));
        GLib.assert_true (new FileInfo (fake_folder.local_path + conflict_name).permissions () == perm);
    }

} // class TestPropagatePermissions

} // namespace Testing
} // namespace Occ
