namespace Occ {
namespace Testing {

/***********************************************************
@class TestShouldEncryptPrivateKeys

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestShouldEncryptPrivateKeys : AbstractTestClientSideEncryption {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestShouldEncryptPrivateKeys () {
    //      // GIVEN
    //      var encryption_key = "foo";
    //      var private_key = "bar";
    //      var original_salt = "baz";

    //      // WHEN
    //      var cipher = EncryptionHelper.encrypt_private_key (encryption_key, private_key, original_salt);

    //      // THEN
    //      var parts = cipher.split ('|');
    //      GLib.assert_true (parts.size () == 3);

    //      var encrypted_key = parts[0].to_string ();
    //      var initialization_vector = parts[1].to_string ();
    //      var salt = parts[2].to_string ();

    //      // We're not here to check the merits of the encryption but at least make sure it's been
    //      // somewhat ciphered
    //      GLib.assert_true (encrypted_key != "");
    //      GLib.assert_true (encrypted_key != private_key);

    //      GLib.assert_true (initialization_vector != "");
    //      GLib.assert_true (salt == original_salt);
    //  }

} // class TestShouldEncryptPrivateKeys

} // namespace Testing
} // namespace Occ
