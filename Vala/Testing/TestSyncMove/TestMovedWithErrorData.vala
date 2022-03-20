/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestMovedWithErrorData : AbstractTestSyncMove {

    /***********************************************************
    ***********************************************************/
    private TestMovedWithErrorData () {
        QTest.add_column<AbstractVfs.Mode> ("vfs_mode");

        QTest.new_row ("Vfs.Off") + Vfs.Off;
        QTest.new_row ("Vfs.WithSuffix") + Vfs.WithSuffix;
    }

} // class TestMovedWithErrorData

} // namespace Testing
} // namespace Occ
