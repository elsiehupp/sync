/*
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

namespace Occ {

UserStatus.UserStatus () = default;

UserStatus.UserStatus (
    const QString &id, QString &message, QString &icon,
    OnlineStatus state, bool messagePredefined, Optional<ClearAt> &clearAt)
    : _id (id)
    , _message (message)
    , _icon (icon)
    , _state (state)
    , _messagePredefined (messagePredefined)
    , _clearAt (clearAt) {
}

QString UserStatus.id () {
    return _id;
}

QString UserStatus.message () {
    return _message;
}

QString UserStatus.icon () {
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

void UserStatus.setId (QString &id) {
    _id = id;
}

void UserStatus.setMessage (QString &message) {
    _message = message;
}

void UserStatus.setState (OnlineStatus state) {
    _state = state;
}

void UserStatus.setIcon (QString &icon) {
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
