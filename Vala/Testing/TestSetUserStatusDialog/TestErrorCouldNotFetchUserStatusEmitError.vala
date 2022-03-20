/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestErrorCouldNotFetchUserStatusEmitError : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestErrorCouldNotFetchUserStatusEmitError () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_could_not_fetch_user_status (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.error_message () ==
            _("Could not fetch user status. Make sure you are connected to the server."));
    }

} // class TestErrorCouldNotFetchUserStatusEmitError

} // namespace Testing
} // namespace Occ
