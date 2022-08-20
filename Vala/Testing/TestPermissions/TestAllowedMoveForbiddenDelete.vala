namespace Occ {
namespace Testing {

/***********************************************************
@class TestAllowedMoveForbiddenDelete

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestAllowedMoveForbiddenDelete : AbstractTestPermissions {

//    /***********************************************************
//    Test for issue #7293
//    ***********************************************************/
//    private TestAllowedMoveForbiddenDelete () {
//        FakeFolder fake_folder = new FakeFolder (new FileInfo ());

//       // Some of this test depends on the order of discovery. With threading
//       // that order becomes effectively random, but we want to make sure to test
//       // all cases and thus disable threading.
//       var sync_opts = fake_folder.sync_engine.sync_options ();
//       sync_opts.parallel_network_jobs = 1;
//       fake_folder.sync_engine.set_sync_options (sync_opts);

//       var lm = fake_folder.local_modifier;
//       var rm = fake_folder.remote_modifier ();
//       rm.mkdir ("changeonly");
//       rm.mkdir ("changeonly/sub1");
//       rm.insert ("changeonly/sub1/file1");
//       rm.insert ("changeonly/sub1/filetorname1a");
//       rm.insert ("changeonly/sub1/filetorname1z");
//       rm.mkdir ("changeonly/sub2");
//       rm.insert ("changeonly/sub2/file2");
//       rm.insert ("changeonly/sub2/filetorname2a");
//       rm.insert ("changeonly/sub2/filetorname2z");

//       on_set_all_perm (rm.find ("changeonly"), Common.RemotePermissions.from_server_string ("NSV"));

//       GLib.assert_true (fake_folder.sync_once ());

//       lm.rename ("changeonly/sub1/filetorname1a", "changeonly/sub1/aaa1_renamed");
//       lm.rename ("changeonly/sub1/filetorname1z", "changeonly/sub1/zzz1_renamed");

//       lm.rename ("changeonly/sub2/filetorname2a", "changeonly/sub2/aaa2_renamed");
//       lm.rename ("changeonly/sub2/filetorname2z", "changeonly/sub2/zzz2_renamed");

//       lm.rename ("changeonly/sub1", "changeonly/aaa");
//       lm.rename ("changeonly/sub2", "changeonly/zzz");

//       var expected_state = fake_folder.current_local_state ();

//       GLib.assert_true (fake_folder.sync_once ());
//       GLib.assert_true (fake_folder.current_local_state () == expected_state);
//       GLib.assert_true (fake_folder.current_remote_state () == expected_state);
   }

} // class TestAllowedMoveForbiddenDelete

} // namespace Testing
} // namespace Occ
