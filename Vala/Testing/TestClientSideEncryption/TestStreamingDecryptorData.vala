namespace Occ {
namespace Testing {

/***********************************************************
@class TestStreamingDecryptorData

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestStreamingDecryptorData : AbstractTestClientSideEncryption {

    /***********************************************************
    ***********************************************************/
    private TestStreamingDecryptorData () {
        QTest.add_column<int> ("total_bytes");
        QTest.add_column<int> ("bytes_to_read");

        QTest.new_row ("data1") << 64  << 2;
        QTest.new_row ("data2") << 32  << 8;
        QTest.new_row ("data3") << 76  << 64;
        QTest.new_row ("data4") << 272 << 256;
    }

} // class TestStreamingDecryptorData

} // namespace Testing
} // namespace Occ
