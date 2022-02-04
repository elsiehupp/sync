/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {

struct Emoji {
    Emoji (string u, string s, bool is_custom = false)
        : unicode (std.move (std.move (u)))
        , shortname (std.move (std.move (s)))
        , is_custom (is_custom) {
    }
    Emoji () = default;

    friend QDataStream operator<< (QDataStream arch, Emoji object) {
        arch << object.unicode;
        arch << object.shortname;
        return arch;
    }

    friend QDataStream operator>> (QDataStream arch, Emoji object) {
        arch >> object.unicode;
        arch >> object.shortname;
        object.is_custom = object.unicode.starts_with ("image://");
        return arch;
    }

    string unicode;
    string shortname;
    bool is_custom = false;

    // Q_GADGET
    //  Q_PROPERTY (string unicode MEMBER unicode)
    //  Q_PROPERTY (string shortname MEMBER shortname)
    //  Q_PROPERTY (bool is_custom MEMBER is_custom)
};