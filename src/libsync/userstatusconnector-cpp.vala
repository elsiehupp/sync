/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {

UserStatus.UserStatus () = default;

UserStatus.UserStatus (
    const string &id, string &message, string &icon,
    OnlineStatus state, bool messagePredefined, Optional<ClearAt> &clearAt)
    : _id (id)
    , _message (message)
    , _icon (icon)
    , _state (state)
    , _messagePredefined (messagePredefined)
    , _clearAt (clearAt) {
}

string UserStatus.id () {
    return _id;
}

string UserStatus.message () {
    return _message;
}

string UserStatus.icon () {
    return _icon;
}

auto UserStatus.state () const . OnlineStatus {
    return _state;
}

bool UserStatus.messagePredefined () {
    return _messagePredefined;
}

QUrl UserStatus.stateIcon () {
    switch (_state) {
    case UserStatus.OnlineStatus.Away:
        return Theme.instance ().statusAwayImageSource ();

    case UserStatus.OnlineStatus.DoNotDisturb:
        return Theme.instance ().statusDoNotDisturbImageSource ();

    case UserStatus.OnlineStatus.Invisible:
    case UserStatus.OnlineStatus.Offline:
        return Theme.instance ().statusInvisibleImageSource ();

    case UserStatus.OnlineStatus.Online:
        return Theme.instance ().statusOnlineImageSource ();
    }

    Q_UNREACHABLE ();
}

Optional<ClearAt> UserStatus.clearAt () {
    return _clearAt;
}

void UserStatus.setId (string &id) {
    _id = id;
}

void UserStatus.setMessage (string &message) {
    _message = message;
}

void UserStatus.setState (OnlineStatus state) {
    _state = state;
}

void UserStatus.setIcon (string &icon) {
    _icon = icon;
}

void UserStatus.setMessagePredefined (bool value) {
    _messagePredefined = value;
}

void UserStatus.setClearAt (Optional<ClearAt> &dateTime) {
    _clearAt = dateTime;
}

UserStatusConnector.UserStatusConnector (GLib.Object *parent)
    : GLib.Object (parent) {
}

UserStatusConnector.~UserStatusConnector () = default;
}
