/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestAllFilesDeletedKeepData : AbstractTestAllFilesDeleted {

    /***********************************************************
    ***********************************************************/
    private TestAllFilesDeletedKeepData () {
        QTest.add_column<bool> ("delete_on_remote");
        QTest.new_row ("local") + false;
        QTest.new_row ("remote") + true;
    }

}

}
}
