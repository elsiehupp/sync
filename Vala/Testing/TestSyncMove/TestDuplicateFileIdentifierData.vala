/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestDuplicateFileIdentifierData : AbstractTestSyncMove {

    /***********************************************************
    ***********************************************************/
    private TestDuplicateFileIdentifierData () {
        GLib.Test.add_column<string> ("prefix");

        // There have been bugs related to how the original
        // folder and the folder with the duplicate tree are
        // ordered. Test both cases here.
        GLib.Test.new_row ("first ordering") + "O"; // "O" > "A"
        GLib.Test.new_row ("second ordering") + "0"; // "0" < "A"
    }

} // class TestDuplicateFileIdentifierData

} // namespace Testing
} // namespace Occ
