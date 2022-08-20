namespace Occ {
namespace Testing {

/***********************************************************
@class TestShouldSymmetricEncryptStrings

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestShouldSymmetricEncryptStrings : AbstractTestClientSideEncryption {

//    /***********************************************************
//    ***********************************************************/
//    private TestShouldSymmetricEncryptStrings () {
//        // GIVEN
//        var encryption_key = "foo";
//        var data = "bar";

//        // WHEN
//        var cipher = EncryptionHelper.encrypt_string_symmetric (encryption_key, data);

//        // THEN
//        var parts = cipher.split ('|');
//        GLib.assert_true (parts.size () == 2);

//        var encrypted_data = string.from_base64 (parts[0]);
//        var initialization_vector = string.from_base64 (parts[1]);

//        // We're not here to check the merits of the encryption but at least make sure it's been
//        // somewhat ciphered
//        GLib.assert_true (!encrypted_data == "");
//        GLib.assert_true (encrypted_data != data);

//        GLib.assert_true (!initialization_vector == "");
//    }

} // class TestShouldSymmetricEncryptStrings

} // namespace Testing
} // namespace Occ
