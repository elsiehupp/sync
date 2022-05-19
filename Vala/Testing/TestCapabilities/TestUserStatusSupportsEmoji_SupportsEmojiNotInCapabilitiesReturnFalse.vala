

namespace Occ {
namespace Testing {

public class TestUserStatusSupportsEmoji_SupportsEmojiNotInCapabilitiesReturnFalse : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private TestUserStatusSupportsEmoji_SupportsEmojiNotInCapabilitiesReturnFalse () {
        GLib.HashMap user_status_map;
        user_status_map["enabled"] = true;

        GLib.HashMap capabilities_map;
        capabilities_map["user_status"] = user_status_map;

        Capabilities capabilities = new Capabilities (capabilities_map);

        GLib.assert_true (!capabilities.user_status_supports_emoji ());
    }

} // class TestUserStatusSupportsEmoji_SupportsEmojiNotInCapabilitiesReturnFalse

} // namespace Testing
} // namespace Occ
