/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestErrorUserStatusNotSupportedEmitError : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestErrorUserStatusNotSupportedEmitError () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_user_status_not_supported (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.error_message () ==
            _("User status feature is not supported. You will not be able to set your user status."));
    }

} // class TestErrorUserStatusNotSupportedEmitError

} // namespace Testing
} // namespace Occ
