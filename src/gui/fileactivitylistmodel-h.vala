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

// #pragma once

namespace Occ {

class FileActivityListModel : ActivityListModel {

public:
    FileActivityListModel (GLib.Object *parent = nullptr);

public slots:
    void load (AccountState *accountState, QString &fileId);

protected:
    void startFetchJob () override;

private:
    QString _fileId;
};
}
