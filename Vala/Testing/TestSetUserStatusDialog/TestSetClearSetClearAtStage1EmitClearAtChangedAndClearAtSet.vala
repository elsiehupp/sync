/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSetClearSetClearAtStage1EmitClearAtChangedAndClearAtSet : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestSetClearSetClearAtStage1EmitClearAtChangedAndClearAtSet () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy clear_at_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.clear_at_changed
        );

        var clear_at_index = 1;
        model.set_clear_at (clear_at_index);

        GLib.assert_true (clear_at_changed_spy.count () == 1);
        GLib.assert_true (model.clear_at () == _("30 minutes"));
    }

} // class TestSetClearSetClearAtStage1EmitClearAtChangedAndClearAtSet

} // namespace Testing
} // namespace Occ
