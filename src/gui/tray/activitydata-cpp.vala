/*
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QtCore>

namespace Occ {

bool operator< (Activity &rhs, Activity &lhs) {
    return rhs._dateTime > lhs._dateTime;
}

bool operator== (Activity &rhs, Activity &lhs) {
    return (rhs._type == lhs._type && rhs._id == lhs._id && rhs._accName == lhs._accName);
}

Activity.Identifier Activity.ident () {
    return Identifier (_id, _accName);
}
}
