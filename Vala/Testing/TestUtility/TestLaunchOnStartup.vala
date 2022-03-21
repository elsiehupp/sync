namespace Occ {
namespace Testing {

/***********************************************************
@class TestLaunchOnStartup

This software is in the public domain, furnished "as is",
without technical support, and with no warranty, express or
implied, as to its usefulness for any purpose.
***********************************************************/
public class TestLaunchOnStartup : AbstractTestUtility {

    /***********************************************************
    ***********************************************************/
    private TestLaunchOnStartup () {
        string postfix = Utility.rand ().to_string ();

        const string app_name = "TestLaunchOnStartup.%1".printf (postfix);
        const string gui_name = "LaunchOnStartup GUI Name";

        GLib.assert_true (has_launch_on_startup (app_name) == false);
        set_launch_on_startup (app_name, gui_name, true);
        GLib.assert_true (has_launch_on_startup (app_name) == true);
        set_launch_on_startup (app_name, gui_name, false);
        GLib.assert_true (has_launch_on_startup (app_name) == false);
    }

} // class TestLaunchOnStartup

} // namespace Testing
} // namespace Occ
