/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDeepHierarchyData : AbstractTestSyncMove {

    /***********************************************************
    ***********************************************************/
    private TestDeepHierarchyData () {
        QTest.add_column<bool> ("local");
        QTest.new_row ("remote") + false;
        QTest.new_row ("local") + true;
    }

} // class TestDeepHierarchyData

} // namespace Testing
} // namespace Occ
