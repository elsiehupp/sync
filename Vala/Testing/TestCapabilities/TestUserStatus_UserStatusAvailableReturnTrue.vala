

namespace Occ {
namespace Testing {

public class TestUserStatus_UserStatusAvailableReturnTrue : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestUserStatus_UserStatusAvailableReturnTrue () {
        GLib.HashMap user_status_map;
        user_status_map["enabled"] = true;

        GLib.HashMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (capabilities.user_status ());
    }

} // class TestUserStatus_UserStatusAvailableReturnTrue

} // namespace Testing
} // namespace Occ
