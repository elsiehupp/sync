/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestClearUserStatus : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestClearUserStatus () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        model.clear_user_status ();

        GLib.assert_true (fake_user_status_job.message_cleared ());
    }

} // class TestClearUserStatus

} // namespace Testing
} // namespace Occ
