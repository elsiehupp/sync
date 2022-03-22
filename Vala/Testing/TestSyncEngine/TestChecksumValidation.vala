/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestChecksumValidation : AbstractTestSyncEngine {

    /***********************************************************
    Checks whether downloads with bad checksums are accepted
    ***********************************************************/
    private TestChecksumValidation () {
        FakeFolder fake_folder = new FakeFolder (FileInfo.A12_B12_C12_S12 ());
        GLib.Object parent;

        string checksum_value;
        string content_md5_value;

        fake_folder.set_server_override (this.override_delegate_checksum_validation);

        // Basic case
        fake_folder.remote_modifier ().create ("A/a3", 16, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Bad OC-Checksum
        checksum_value = "SHA1:bad";
        fake_folder.remote_modifier ().create ("A/a4", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ());

        // Good OC-Checksum
        checksum_value = "SHA1:19b1928d58a2030d08023f3d7054516dbc186f20"; // printf 'A%.0s' {1..16} | sha1sum -
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
        checksum_value = "";

        // Bad Content-MD5
        content_md5_value = "bad";
        fake_folder.remote_modifier ().create ("A/a5", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ());

        // Good Content-MD5
        content_md5_value = "d8a73157ce10cd94a91c2079fc9a92c8"; // printf 'A%.0s' {1..16} | md5sum -
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // Invalid OC-Checksum is ignored
        checksum_value = "garbage";
        // content_md5_value is still good
        fake_folder.remote_modifier ().create ("A/a6", 16, 'A');
        GLib.assert_true (fake_folder.sync_once ());
        content_md5_value = "bad";
        fake_folder.remote_modifier ().create ("A/a7", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ());
        content_md5_value == "";
        GLib.assert_true (fake_folder.sync_once ());
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());

        // OC-Checksum contains Unsupported checksums
        checksum_value = "Unsupported:XXXX SHA1:invalid Invalid:XxX";
        fake_folder.remote_modifier ().create ("A/a8", 16, 'A');
        GLib.assert_true (!fake_folder.sync_once ()); // Since the supported SHA1 checksum is invalid, no download
        checksum_value =  "Unsupported:XXXX SHA1:19b1928d58a2030d08023f3d7054516dbc186f20 Invalid:XxX";
        GLib.assert_true (fake_folder.sync_once ()); // The supported SHA1 checksum is valid now, so the file are downloaded
        GLib.assert_true (fake_folder.current_local_state () == fake_folder.current_remote_state ());
    }


    private GLib.InputStream override_delegate_checksum_validation (Soup.Operation operation, Soup.Request request, QIODevice device) {
        if (operation == Soup.GetOperation) {
            var reply = new FakeGetReply (fake_folder.remote_modifier (), operation, request, parent);
            if (!checksum_value == null)
                reply.set_raw_header ("OC-Checksum", checksum_value);
            if (!content_md5_value == null)
                reply.set_raw_header ("Content-MD5", content_md5_value);
            return reply;
        }
        return null;
    }

} // class TestChecksumValidation

} // namespace Testing
} // namespace Occ
