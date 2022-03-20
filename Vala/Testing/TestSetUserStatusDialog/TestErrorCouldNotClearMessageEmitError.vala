/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestErrorCouldNotClearMessageEmitError : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestErrorCouldNotClearMessageEmitError () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_could_not_clear_user_status_message (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        model.clear_user_status ();

        GLib.assert_true (model.error_message () ==
            _("Could not clear user status message. Make sure you are connected to the server."));
    }

} // class TestErrorCouldNotClearMessageEmitError

} // namespace Testing
} // namespace Occ
