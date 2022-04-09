namespace Occ {
namespace Testing {

/***********************************************************
@class TestCreateFileWithTrailingSpacesLocalAndRemoteTrimmedDoNotExistRenameAndUploadFile

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCreateFileWithTrailingSpacesLocalAndRemoteTrimmedDoNotExistRenameAndUploadFile : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestCreateFileWithTrailingSpacesLocalAndRemoteTrimmedDoNotExistRenameAndUploadFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        string file_with_spaces_1 = " foo";
        string file_with_spaces_2 = " bar  ";
        string file_with_spaces_3 = "bla ";
        string file_with_spaces_4 = "A/ foo";
        string file_with_spaces_5 = "A/ bar  ";
        string file_with_spaces_6 = "A/bla ";

        fake_folder.local_modifier.insert (file_with_spaces_1);
        fake_folder.local_modifier.insert (file_with_spaces_2);
        fake_folder.local_modifier.insert (file_with_spaces_3);
        fake_folder.local_modifier.insert (file_with_spaces_4);
        fake_folder.local_modifier.insert (file_with_spaces_5);
        fake_folder.local_modifier.insert (file_with_spaces_6);

        GLib.assert_true (fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find (file_with_spaces_1.trimmed ()));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_1));
        GLib.assert_true (fake_folder.current_local_state ().find (file_with_spaces_1.trimmed ()));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_1));

        GLib.assert_true (fake_folder.current_remote_state ().find (file_with_spaces_2.trimmed ()));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_2));
        GLib.assert_true (fake_folder.current_local_state ().find (file_with_spaces_2.trimmed ()));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_2));

        GLib.assert_true (fake_folder.current_remote_state ().find (file_with_spaces_3.trimmed ()));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_3));
        GLib.assert_true (fake_folder.current_local_state ().find (file_with_spaces_3.trimmed ()));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_3));

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/foo"));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_4));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/foo"));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_4));

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/bar"));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_5));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/bar"));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_5));

        GLib.assert_true (fake_folder.current_remote_state ().find ("A/bla"));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces_6));
        GLib.assert_true (fake_folder.current_local_state ().find ("A/bla"));
        GLib.assert_true (!fake_folder.current_local_state ().find (file_with_spaces_6));
    }

} // class TestCreateFileWithTrailingSpacesLocalAndRemoteTrimmedDoNotExistRenameAndUploadFile

} // namespace Testing
} // namespace Occ
