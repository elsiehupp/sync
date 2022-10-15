/***********************************************************
This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/

namespace Occ {
namespace Testing {

public class TestConflictFileBaseNameData : AbstractTestSyncConflict {

    /***********************************************************
    ***********************************************************/
    private TestConflictFileBaseNameData () {
        //  GLib.Test.add_column<string> ("input");
        //  GLib.Test.add_column<string> ("output");

        //  GLib.Test.new_row ("nomatch1")
        //      + "a/b/foo"
        //      + "";
        //  GLib.Test.new_row ("nomatch2")
        //      + "a/b/foo.txt"
        //      + "";
        //  GLib.Test.new_row ("nomatch3")
        //      + "a/b/foo_conflict"
        //      + "";
        //  GLib.Test.new_row ("nomatch4")
        //      + "a/b/foo_conflict.txt"
        //      + "";

        //  GLib.Test.new_row ("match1")
        //      + "a/b/foo_conflict-123.txt"
        //      + "a/b/foo.txt";
        //  GLib.Test.new_row ("match2")
        //      + "a/b/foo_conflict-foo-123.txt"
        //      + "a/b/foo.txt";

        //  GLib.Test.new_row ("match3")
        //      + "a/b/foo_conflict-123"
        //      + "a/b/foo";
        //  GLib.Test.new_row ("match4")
        //      + "a/b/foo_conflict-foo-123"
        //      + "a/b/foo";

        //  // new style
        //  GLib.Test.new_row ("newmatch1")
        //      + "a/b/foo (conflicted copy 123).txt"
        //      + "a/b/foo.txt";
        //  GLib.Test.new_row ("newmatch2")
        //      + "a/b/foo (conflicted copy foo 123).txt"
        //      + "a/b/foo.txt";

        //  GLib.Test.new_row ("newmatch3")
        //      + "a/b/foo (conflicted copy 123)"
        //      + "a/b/foo";
        //  GLib.Test.new_row ("newmatch4")
        //      + "a/b/foo (conflicted copy foo 123)"
        //      + "a/b/foo";

        //  GLib.Test.new_row ("newmatch5")
        //      + "a/b/foo (conflicted copy foo 123) bla"
        //      + "a/b/foo bla";

        //  GLib.Test.new_row ("newmatch6")
        //      + "a/b/foo (conflicted copy foo.bar 123)"
        //      + "a/b/foo";

        //  // double conflict files
        //  GLib.Test.new_row ("double1")
        //      + "a/b/foo_conflict-123_conflict-456.txt"
        //      + "a/b/foo_conflict-123.txt";
        //  GLib.Test.new_row ("double2")
        //      + "a/b/foo_conflict-foo-123_conflict-bar-456.txt"
        //      + "a/b/foo_conflict-foo-123.txt";
        //  GLib.Test.new_row ("double3")
        //      + "a/b/foo (conflicted copy 123) (conflicted copy 456).txt"
        //      + "a/b/foo (conflicted copy 123).txt";
        //  GLib.Test.new_row ("double4")
        //      + "a/b/foo (conflicted copy 123)this.conflict-456.txt"
        //      + "a/b/foo (conflicted copy 123).txt";
        //  GLib.Test.new_row ("double5")
        //      + "a/b/foo_conflict-123 (conflicted copy 456).txt"
        //      + "a/b/foo_conflict-123.txt";
    }

} // class TestConflictFileBaseNameData

} // namespace Testing
} // namespace Occ
