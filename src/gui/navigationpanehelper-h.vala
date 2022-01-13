/*
Copyright (C) by Jocelyn Turcotte <jturcotte@woboq.com>

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
// #include <QTimer>

namespace Occ {


class NavigationPaneHelper : GLib.Object {
public:
    NavigationPaneHelper (FolderMan *folderMan);

    bool showInExplorerNavigationPane () { return _showInExplorerNavigationPane; }
    void setShowInExplorerNavigationPane (bool show);

    void scheduleUpdateCloudStorageRegistry ();

private:
    void updateCloudStorageRegistry ();

    FolderMan *_folderMan;
    bool _showInExplorerNavigationPane;
    QTimer _updateCloudStorageRegistryTimer;
};

} // namespace Occ