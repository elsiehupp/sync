namespace Occ {
namespace Testing {

/***********************************************************
@class TestVirtualFileLifecycleData

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestVirtualFileLifecycleData : AbstractTestSyncVirtualFiles {

    /***********************************************************
    ***********************************************************/
    private TestVirtualFileLifecycleData () {
        QTest.add_column<bool> ("do_local_discovery");

        QTest.new_row ("full local discovery") + true;
        QTest.new_row ("skip local discovery") + false;
    }

} // class TestVirtualFileLifecycleData

} // namespace Testing
} // namespace Occ
