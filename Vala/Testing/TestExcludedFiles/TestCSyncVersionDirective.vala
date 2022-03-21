namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncVersionDirective

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncVersionDirective : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncVersionDirective () {
        ExcludedFiles excludes;
        excludes.set_client_version (ExcludedFiles.Version (2, 5, 0));

        GLib.List<Pair<string, bool>> tests = new GLib.List<Pair<string, bool>> (
            { "#!version == 2.5.0", true },
            { "#!version == 2.6.0", false },
            { "#!version < 2.6.0", true },
            { "#!version <= 2.6.0", true },
            { "#!version > 2.6.0", false },
            { "#!version >= 2.6.0", false },
            { "#!version < 2.4.0", false },
            { "#!version <= 2.4.0", false },
            { "#!version > 2.4.0", true },
            { "#!version >= 2.4.0", true },
            { "#!version < 2.5.0", false },
            { "#!version <= 2.5.0", true },
            { "#!version > 2.5.0", false },
            { "#!version >= 2.5.0", true }
        );
        foreach (var test in tests) {
            GLib.assert_true (excludes.version_directive_keep_next_line (test.first) == test.second);
        }
    }

} // class TestCSyncVersionDirective

} // namespace Testing
} // namespace Occ
