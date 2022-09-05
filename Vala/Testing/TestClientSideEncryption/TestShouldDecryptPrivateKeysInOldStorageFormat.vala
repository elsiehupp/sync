namespace Occ {
namespace Testing {

/***********************************************************
@class TestShouldDecryptPrivateKeysInOldStorageFormat

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestShouldDecryptPrivateKeysInOldStorageFormat : AbstractTestClientSideEncryption {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestShouldDecryptPrivateKeysInOldStorageFormat () {
    //      // GIVEN
    //      var encryption_key = "foo";
    //      var original_private_key = "bar";
    //      var original_salt = "baz";
    //      var cipher = convert_to_old_storage_format (EncryptionHelper.encrypt_private_key (encryption_key, original_private_key, original_salt));

    //      // WHEN
    //      var private_key = EncryptionHelper.decrypt_private_key (encryption_key, cipher);
    //      var salt = EncryptionHelper.extract_private_key_salt (cipher);

    //      // THEN
    //      GLib.assert_true (private_key == original_private_key);
    //      GLib.assert_true (salt == original_salt);
    //  }

} // class TestShouldDecryptPrivateKeysInOldStorageFormat

} // namespace Testing
} // namespace Occ
