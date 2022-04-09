

namespace Occ {
namespace Testing {

public class TestUserStatusSupportsEmoji_SupportsEmojiNotAvailableReturnFalse : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestUserStatusSupportsEmoji_SupportsEmojiNotAvailableReturnFalse () {
        GLib.VariantMap user_status_map;
        user_status_map["enabled"] = true;
        user_status_map["supports_emoji"] = false;

        GLib.VariantMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (!capabilities.user_status_supports_emoji ());
    }

} // class TestUserStatusSupportsEmoji_SupportsEmojiNotAvailableReturnFalse

} // namespace Testing
} // namespace Occ
