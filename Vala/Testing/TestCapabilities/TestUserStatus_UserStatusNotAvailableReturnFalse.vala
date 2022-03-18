

namespace Occ {
namespace Testing {

public class TestUserStatus_UserStatusNotAvailableReturnFalse : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestUserStatus_UserStatusNotAvailableReturnFalse () {
        QVariantMap user_status_map;
        user_status_map["enabled"] = false;

        QVariantMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (!capabilities.user_status ());
    }

} // class TestUserStatus_UserStatusNotAvailableReturnFalse

} // namespace Testing
} // namespace Occ
