/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSetOnlineStatusEmitOnlineStatusChanged : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestSetOnlineStatusEmitOnlineStatusChanged () {
        const UserStatus.OnlineStatus online_status = UserStatus.OnlineStatus.Invisible;
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy online_status_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.online_status_changed
        );

        model.set_online_status (online_status);

        GLib.assert_true (online_status_changed_spy.count () == 1);
    }

} // class TestSetOnlineStatusEmitOnlineStatusChanged

} // namespace Testing
} // namespace Occ
