namespace Occ {
namespace Testing {

/***********************************************************
@class TestShouldSymmetricDecryptStrings

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestShouldSymmetricDecryptStrings : AbstractTestClientSideEncryption {

    /***********************************************************
    ***********************************************************/
    private TestShouldSymmetricDecryptStrings () {
        // GIVEN
        var encryption_key = "foo";
        var original_data = "bar";
        var cipher = EncryptionHelper.encrypt_string_symmetric (encryption_key, original_data);

        // WHEN
        var data = EncryptionHelper.decrypt_string_symmetric (encryption_key, cipher);

        // THEN
        GLib.assert_true (data == original_data);
    }

} // class TestShouldSymmetricDecryptStrings

} // namespace Testing
} // namespace Occ
