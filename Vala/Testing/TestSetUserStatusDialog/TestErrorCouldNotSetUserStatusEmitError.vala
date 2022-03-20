/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestErrorCouldNotSetUserStatusEmitError : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestErrorCouldNotSetUserStatusEmitError () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_could_not_set_user_status_message (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        model.set_user_status ();

        GLib.assert_true (model.error_message () ==
            _("Could not set user status. Make sure you are connected to the server."));
    }

} // class TestErrorCouldNotSetUserStatusEmitError

} // namespace Testing
} // namespace Occ
