/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestSetClearSetClearAtStage4EmitClearAtChangedAndClearAtSet : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestSetClearSetClearAtStage4EmitClearAtChangedAndClearAtSet () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);
        QSignalSpy clear_at_changed_spy = new QSignalSpy (
            model,
            UserStatusSelectorModel.clear_at_changed
        );

        var clear_at_index = 4;
        model.set_clear_at (clear_at_index);

        GLib.assert_true (clear_at_changed_spy.count () == 1);
        GLib.assert_true (model.clear_at () == _("Today"));
    }

} // class TestSetClearSetClearAtStage4EmitClearAtChangedAndClearAtSet

} // namespace Testing
} // namespace Occ
