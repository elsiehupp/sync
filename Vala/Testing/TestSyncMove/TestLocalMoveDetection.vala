/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestLocalMoveDetection : AbstractTestSyncMove {

    /***********************************************************
    ***********************************************************/
    private TestLocalMoveDetection () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());

        int number_of_put = 0;
        int number_of_delete = 0;
        fake_folder.set_server_override (this.override_delegate_local_move_detection);

        // For directly editing the remote checksum
        FileInfo remote_info = fake_folder.remote_modifier ();

        // Simple move causing a remote rename
        fake_folder.local_modifier.rename ("A/a1", "A/a1m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
        GLib.assert_true (number_of_put == 0);

        // Move-and-change, causing a upload and delete
        fake_folder.local_modifier.rename ("A/a2", "A/a2m");
        fake_folder.local_modifier.append_byte ("A/a2m");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
        GLib.assert_true (number_of_put == 1);
        GLib.assert_true (number_of_delete == 1);

        // Move-and-change, mtime+content only
        fake_folder.local_modifier.rename ("B/b1", "B/b1m");
        fake_folder.local_modifier.set_contents ("B/b1m", 'C');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
        GLib.assert_true (number_of_put == 2);
        GLib.assert_true (number_of_delete == 2);

        // Move-and-change, size+content only
        var mtime = fake_folder.remote_modifier ().find ("B/b2").last_modified;
        fake_folder.local_modifier.rename ("B/b2", "B/b2m");
        fake_folder.local_modifier.append_byte ("B/b2m");
        fake_folder.local_modifier.set_modification_time ("B/b2m", mtime);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
        GLib.assert_true (number_of_put == 3);
        GLib.assert_true (number_of_delete == 3);

        // Move-and-change, content only -- c1 has no checksum, so we fail to detect this!
        // Note: This is an expected failure.
        mtime = fake_folder.remote_modifier ().find ("C/c1").last_modified;
        fake_folder.local_modifier.rename ("C/c1", "C/c1m");
        fake_folder.local_modifier.set_contents ("C/c1m", 'C');
        fake_folder.local_modifier.set_modification_time ("C/c1m", mtime);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 3);
        GLib.assert_true (number_of_delete == 3);
        GLib.assert_true (! (fake_folder.current_local_state () == remote_info));

        // on_signal_cleanup, and upload a file that will have a checksum in the database
        fake_folder.local_modifier.remove ("C/c1m");
        fake_folder.local_modifier.insert ("C/c3");
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
        GLib.assert_true (number_of_put == 4);
        GLib.assert_true (number_of_delete == 4);

        // Move-and-change, content only, this time while having a checksum
        mtime = fake_folder.remote_modifier ().find ("C/c3").last_modified;
        fake_folder.local_modifier.rename ("C/c3", "C/c3m");
        fake_folder.local_modifier.set_contents ("C/c3m", 'C');
        fake_folder.local_modifier.set_modification_time ("C/c3m", mtime);
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (number_of_put == 5);
        GLib.assert_true (number_of_delete == 5);
        GLib.assert_true (fake_folder.current_local_state () == remote_info);
        GLib.assert_true (print_database_data (fake_folder.database_state ()) == print_database_data (remote_info));
    }


    /***********************************************************
    ***********************************************************/
    private Soup.Reply override_delegate_local_move_detection (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.PutOperation)
            ++number_of_put;
        if (operation == Soup.DeleteOperation)
            ++number_of_delete;
        return null;
    }

} // class TestLocalMoveDetection

} // namespace Testing
} // namespace Occ
