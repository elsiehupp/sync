/*
Copyright (C) by Julius Härtl <jus@bitgrid.net>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <GLib.Object>

using namespace Occ;


class CloudProviderManager : GLib.Object {
public:
    CloudProviderManager (GLib.Object *parent = nullptr);
    void registerSignals ();

signals:

public slots:
    void slotFolderListChanged (Folder.Map &folderMap);

private:
    QMap<QString, CloudProviderWrapper> _map;
    unsigned int _folder_index;
};
