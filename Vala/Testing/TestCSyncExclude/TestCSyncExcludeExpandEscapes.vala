namespace Occ {
namespace Testing {

/***********************************************************
@class TestCSyncExcludeExpandEscapes

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestCSyncExcludeExpandEscapes : AbstractTestCSyncExclude {

    /***********************************************************
    ***********************************************************/
    private TestCSyncExcludeExpandEscapes () {
        //  //  extern void csync_exclude_expand_escapes (string input);

        //  string line = " (keep \' \" ? \\ a \b \f \n \r \t \v z #)";
        //  csync_exclude_expand_escapes (line);
        //  GLib.assert_true (0 == strcmp (line.const_data (), "keep ' \" ? \\\\ \a \b \f \n \r \t \v \\z #"));

        //  line = "";
        //  csync_exclude_expand_escapes (line);
        //  GLib.assert_true (0 == strcmp (line.const_data (), ""));

        //  line = "\\";
        //  csync_exclude_expand_escapes (line);
        //  GLib.assert_true (0 == strcmp (line.const_data (), "\\"));
    }

} // class TestCSyncExcludeExpandEscapes

} // namespace Testing
} // namespace Occ
