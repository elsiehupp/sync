

namespace Occ {
namespace Testing {

public class TestShareDefaultPermissions_DefaultSharePermissionsNotInCapabilitiesReturnZero : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestShareDefaultPermissions_DefaultSharePermissionsNotInCapabilitiesReturnZero () {
        GLib.VariantMap file_sharing_map;
        file_sharing_map["api_enabled"] = false;

        GLib.VariantMap capabilities_map;
        capabilities_map["files_sharing"] = file_sharing_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);
        var default_share_permissions_not_in_capabilities = capabilities.share_default_permissions ();

        GLib.assert_true (default_share_permissions_not_in_capabilities == {});
    }

} // class TestShareDefaultPermissions_DefaultSharePermissionsNotInCapabilitiesReturnZero

} // namespace Testing
} // namespace Occ
