

namespace Occ {
namespace Testing {

public class TestUserStatusSupportsEmoji_SupportsEmojiAvailableReturnTrue : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestUserStatusSupportsEmoji_SupportsEmojiAvailableReturnTrue () {
        GLib.VariantMap user_status_map;
        user_status_map["enabled"] = true;
        user_status_map["supports_emoji"] = true;

        GLib.VariantMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        const Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (capabilities.user_status ());
    }

} // class TestUserStatusSupportsEmoji_SupportsEmojiAvailableReturnTrue

} // namespace Testing
} // namespace Occ
