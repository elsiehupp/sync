/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSetClearSetClearAtStage5EmitClearAtChangedAndClearAtSet : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestSetClearSetClearAtStage5EmitClearAtChangedAndClearAtSet () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        GLib.SignalSpy clear_at_changed_spy = new GLib.SignalSpy (
            model,
            UserStatusSelectorModel.signal_clear_at_changed
        );

        var clear_at_index = 5;
        model.set_clear_at (clear_at_index);

        GLib.assert_true (clear_at_changed_spy.length == 1);
        GLib.assert_true (model.clear_at () == _("This week"));
    }

} // class TestSetClearSetClearAtStage5EmitClearAtChangedAndClearAtSet

} // namespace Testing
} // namespace Occ
