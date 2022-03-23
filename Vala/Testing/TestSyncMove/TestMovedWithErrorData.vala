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
        QTest.add_column<Common.VfsMode> ("vfs_mode");

        QTest.new_row ("AbstractVfs.Off") + AbstractVfs.Off;
        QTest.new_row ("AbstractVfs.WithSuffix") + AbstractVfs.WithSuffix;
    }

} // class TestMovedWithErrorData

} // namespace Testing
} // namespace Occ
