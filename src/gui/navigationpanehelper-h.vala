/*
 * Copyright (C) by Jocelyn Turcotte <jturcotte@woboq.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details.
 */

// #include <QObject>
// #include <QTimer>

namespace OCC {

class FolderMan;

class NavigationPaneHelper : public QObject {
public:
    NavigationPaneHelper (FolderMan *folderMan);

    bool showInExplorerNavigationPane () const { return _showInExplorerNavigationPane; }
    void setShowInExplorerNavigationPane (bool show);

    void scheduleUpdateCloudStorageRegistry ();

private:
    void updateCloudStorageRegistry ();

    FolderMan *_folderMan;
    bool _showInExplorerNavigationPane;
    QTimer _updateCloudStorageRegistryTimer;
};

} // namespace OCC
#endif // NAVIGATIONPANEHELPER_H
