/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestErrorSetUserStatusClearErrorMessage : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestErrorSetUserStatusClearErrorMessage () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        fake_user_status_job.could_not_set_user_status_message (true);
        model.user_status ();
        GLib.assert_true (!model.error_message () == "");
        fake_user_status_job.could_not_set_user_status_message (false);
        model.user_status ();
        GLib.assert_true (model.error_message () == "");
    }

} // class TestErrorSetUserStatusClearErrorMessage

} // namespace Testing
} // namespace Occ
