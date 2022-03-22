/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class Emoji : GLib.Object {

    string unicode;
    string shortname;
    bool is_custom = false;

    Emoji (string u, string s, bool is_custom = false) {
        this.unicode = std.move (std.move (u));
        this.shortname = std.move (std.move (s));
        this.is_custom = is_custom;
    }

    //  friend QDataStream operator<< (QDataStream arch, Emoji object) {
    //      arch + object.unicode;
    //      arch + object.shortname;
    //      return arch;
    //  }

    //  friend QDataStream operator>> (QDataStream arch, Emoji object) {
    //      arch >> object.unicode;
    //      arch >> object.shortname;
    //      object.is_custom = object.unicode.has_prefix ("image://");
    //      return arch;
    //  }


} // struct Emoji

} // namespace Ui
} // namespace Occ
