namespace Occ {
namespace Testing {

/***********************************************************
@class TestCreateFileWithTrailingSpacesLocalTrimmedDoesExistDontRenameAndUploadFile

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCreateFileWithTrailingSpacesLocalTrimmedDoesExistDontRenameAndUploadFile : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestCreateFileWithTrailingSpacesLocalTrimmedDoesExistDontRenameAndUploadFile () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        const string file_with_spaces = " foo";
        const string file_trimmed = "foo";

        fake_folder.local_modifier.insert (file_trimmed);
        GLib.assert_true (fake_folder.sync_once ());
        fake_folder.local_modifier.insert (file_with_spaces);
        GLib.assert_true (!fake_folder.sync_once ());

        GLib.assert_true (fake_folder.current_remote_state ().find (file_trimmed));
        GLib.assert_true (!fake_folder.current_remote_state ().find (file_with_spaces));
        GLib.assert_true (fake_folder.current_local_state ().find (file_with_spaces));
        GLib.assert_true (fake_folder.current_local_state ().find (file_trimmed));
    }

} // class TestCreateFileWithTrailingSpacesLocalTrimmedDoesExistDontRenameAndUploadFile

} // namespace Testing
} // namespace Occ
