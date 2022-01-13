/*
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QHash>
// #include <QPair>

namespace Occ {

/**
@brief Parser for netrc files
@ingroup cmd
*/
class NetrcParser {
public:
    using LoginPair = QPair<QString, QString>;

    NetrcParser (QString &file = QString ());
    bool parse ();
    LoginPair find (QString &machine);

private:
    void tryAddEntryAndClear (QString &machine, LoginPair &pair, bool &isDefault);
    QHash<QString, LoginPair> _entries;
    LoginPair _default;
    QString _netrcLocation;
};

} // namespace Occ
