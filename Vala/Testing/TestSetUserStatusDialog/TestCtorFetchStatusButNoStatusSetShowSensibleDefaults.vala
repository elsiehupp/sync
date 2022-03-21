/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestCtorFetchStatusButNoStatusSetShowSensibleDefaults : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestCtorFetchStatusButNoStatusSetShowSensibleDefaults () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_fake_user_status ({ "", "", "",
            UserStatus.OnlineStatus.Offline, false, {} });
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.online_status () == UserStatus.OnlineStatus.Online);
        GLib.assert_true (model.user_status_message () == "");
        GLib.assert_true (model.user_status_emoji () == "😀");
        GLib.assert_true (model.clear_at () == _("Don't clear"));
    }

} // class TestCtorFetchStatusButNoStatusSetShowSensibleDefaults

} // namespace Testing
} // namespace Occ
