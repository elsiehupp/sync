

namespace Occ {
namespace Testing {

public class TestUserStatus_UserStatusAvailableReturnTrue : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestUserStatus_UserStatusAvailableReturnTrue () {
        QVariantMap user_status_map;
        user_status_map["enabled"] = true;

        QVariantMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (capabilities.user_status ());
    }

} // class TestUserStatus_UserStatusAvailableReturnTrue

} // namespace Testing
} // namespace Occ
