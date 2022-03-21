namespace Occ {
namespace Testing {

/***********************************************************
@class TestShouldSymmetricDecryptStringsInOldStorageFormat

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestShouldSymmetricDecryptStringsInOldStorageFormat : AbstractTestClientSideEncryption {

    /***********************************************************
    ***********************************************************/
    private TestShouldSymmetricDecryptStringsInOldStorageFormat () {
        // GIVEN
        var encryption_key = "foo";
        var original_data = "bar";
        var cipher = convert_to_old_storage_format (EncryptionHelper.encrypt_string_symmetric (encryption_key, original_data));

        // WHEN
        var data = EncryptionHelper.decrypt_string_symmetric (encryption_key, cipher);

        // THEN
        GLib.assert_true (data == original_data);
    }

} // class TestShouldSymmetricDecryptStringsInOldStorageFormat

} // namespace Testing
} // namespace Occ
