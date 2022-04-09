/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSetOnlineStatusEmitOnlineStatusChanged : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestSetOnlineStatusEmitOnlineStatusChanged () {
        const LibSync.UserStatus.OnlineStatus online_status = LibSync.UserStatus.OnlineStatus.Invisible;
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        GLib.SignalSpy online_status_changed_spy = new GLib.SignalSpy (
            model,
            UserStatusSelectorModel.online_status_changed
        );

        model.set_online_status (online_status);

        GLib.assert_true (online_status_changed_spy.length == 1);
    }

} // class TestSetOnlineStatusEmitOnlineStatusChanged

} // namespace Testing
} // namespace Occ
