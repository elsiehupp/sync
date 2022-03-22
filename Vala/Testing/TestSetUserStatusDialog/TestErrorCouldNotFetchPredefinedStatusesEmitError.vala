/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestErrorCouldNotFetchPredefinedStatusesEmitError : GLib.Object {
 /***********************************************************
    ***********************************************************/
    private TestErrorCouldNotFetchPredefinedStatusesEmitError () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.could_not_fetch_predefined_user_statuses (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.error_message () ==
            _("Could not fetch predefined statuses. Make sure you are connected to the server."));
    }

} // class TestErrorCouldNotFetchPredefinedStatusesEmitError

} // namespace Testing
} // namespace Occ
