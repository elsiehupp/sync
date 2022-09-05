/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestFakeConflictData : AbstractTestSyncEngine {

    //  /***********************************************************
    //  ***********************************************************/
    //  private TestFakeConflictData () {
    //      GLib.Test.add_column<bool> ("same_mtime");
    //      GLib.Test.add_column<string> ("checksums");

    //      GLib.Test.add_column<int> ("expected_get");

    //      GLib.Test.new_row ("Same mtime, but no server checksum . ignored in reconcile")
    //          + true + ""
    //          << 0;

    //      GLib.Test.new_row ("Same mtime, weak server checksum differ . downloaded")
    //          + true + "Adler32:bad"
    //          << 1;

    //      GLib.Test.new_row ("Same mtime, matching weak checksum . skipped")
    //          + true + "Adler32:2a2010d"
    //          << 0;

    //      GLib.Test.new_row ("Same mtime, strong server checksum differ . downloaded")
    //          + true + "SHA1:bad"
    //          << 1;

    //      GLib.Test.new_row ("Same mtime, matching strong checksum . skipped")
    //          + true + "SHA1:56900fb1d337cf7237ff766276b9c1e8ce507427"
    //          << 0;

    //      GLib.Test.new_row ("mtime changed, but no server checksum . download")
    //          + false + ""
    //          << 1;

    //      GLib.Test.new_row ("mtime changed, weak checksum match . download anyway")
    //          + false + "Adler32:2a2010d"
    //          << 1;

    //      GLib.Test.new_row ("mtime changed, strong checksum match . skip")
    //          + false + "SHA1:56900fb1d337cf7237ff766276b9c1e8ce507427"
    //          << 0;
    //  }

} // class TestFakeConflictData

} // namespace Testing
} // namespace Occ
