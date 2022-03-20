/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestErrorClearUserStatusClearErrorMessage : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestErrorClearUserStatusClearErrorMessage () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        fake_user_status_job.set_error_could_not_set_user_status_message (true);
        model.set_user_status ();
        GLib.assert_true (!model.error_message () == "");
        fake_user_status_job.set_error_could_not_set_user_status_message (false);
        model.clear_user_status ();
        GLib.assert_true (model.error_message () == "");
    }

} // class TestErrorClearUserStatusClearErrorMessage

} // namespace Testing
} // namespace Occ
