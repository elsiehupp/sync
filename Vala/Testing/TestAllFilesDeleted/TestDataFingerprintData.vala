/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDataFingerprintData : AbstractTestAllFilesDeleted {

    /***********************************************************
    ***********************************************************/
    private TestDataFingerprintData () {
        QTest.add_column<bool> ("has_initial_finger_print");
        QTest.new_row ("initial finger print") + true;
        QTest.new_row ("no initial finger print") + false;
    }

}

}
}
