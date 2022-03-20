/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Testing {

public class TestErrorEmojisNotSupportedEmitError : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestErrorEmojisNotSupportedEmitError () {
        var fake_user_status_job = new FakeUserStatusConnector ();
        fake_user_status_job.set_error_emojis_not_supported (true);
        UserStatusSelectorModel model = new UserStatusSelectorModel (fake_user_status_job);

        GLib.assert_true (model.error_message () ==
            _("Emojis feature is not supported. Some user status functionality may not work."));
    }

} // class TestErrorEmojisNotSupportedEmitError

} // namespace Testing
} // namespace Occ
