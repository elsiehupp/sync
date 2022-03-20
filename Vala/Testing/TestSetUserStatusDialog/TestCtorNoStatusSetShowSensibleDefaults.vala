/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestCtorNoStatusSetShowSensibleDefaults : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestCtorNoStatusSetShowSensibleDefaults () {
        UserStatusSelectorModel model = new UserStatusSelectorModel (null, null);

        GLib.assert_true (model.user_status_message () == "");
        GLib.assert_true (model.user_status_emoji () == "😀");
        GLib.assert_true (model.clear_at () == _("Don't clear"));
    }

} // class TestCtorNoStatusSetShowSensibleDefaults

} // namespace Testing
} // namespace Occ
