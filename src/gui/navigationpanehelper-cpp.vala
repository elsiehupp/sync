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

// #include <QDir>
// #include <QCoreApplication>

namespace OCC {

Q_LOGGING_CATEGORY (lcNavPane, "nextcloud.gui.folder.navigationpane", QtInfoMsg)

NavigationPaneHelper.NavigationPaneHelper (FolderMan *folderMan)
    : _folderMan (folderMan) {
    ConfigFile cfg;
    _showInExplorerNavigationPane = cfg.showInExplorerNavigationPane ();

    _updateCloudStorageRegistryTimer.setSingleShot (true);
    connect (&_updateCloudStorageRegistryTimer, &QTimer.timeout, this, &NavigationPaneHelper.updateCloudStorageRegistry);

    // Ensure that the folder integration stays persistent in Explorer,
    // the uninstaller removes the folder upon updating the client.
    _showInExplorerNavigationPane = !_showInExplorerNavigationPane;
    setShowInExplorerNavigationPane (!_showInExplorerNavigationPane);
}

void NavigationPaneHelper.setShowInExplorerNavigationPane (bool show) {
    if (_showInExplorerNavigationPane == show)
        return;

    _showInExplorerNavigationPane = show;
    // Re-generate a new CLSID when enabling, possibly throwing away the old one.
    // updateCloudStorageRegistry will take care of removing any unknown CLSID our application owns from the registry.
    foreach (Folder *folder, _folderMan.map ())
        folder.setNavigationPaneClsid (show ? QUuid.createUuid () : QUuid ());

    scheduleUpdateCloudStorageRegistry ();
}

void NavigationPaneHelper.scheduleUpdateCloudStorageRegistry () {
    // Schedule the update to happen a bit later to avoid doing the update multiple times in a row.
    if (!_updateCloudStorageRegistryTimer.isActive ())
        _updateCloudStorageRegistryTimer.start (500);
}

void NavigationPaneHelper.updateCloudStorageRegistry () {
    // Start by looking at every registered namespace extension for the sidebar, and look for an "ApplicationName" value
    // that matches ours when we saved.
    QVector<QUuid> entriesToRemove;

    // Only save folder entries if the option is enabled.
    if (_showInExplorerNavigationPane) {
        // Then re-save every folder that has a valid navigationPaneClsid to the registry.
        // We currently don't distinguish between new and existing CLSIDs, if it's there we just
        // save over it. We at least need to update the tile in case we are suddently using multiple accounts.
        foreach (Folder *folder, _folderMan.map ()) {
            if (!folder.navigationPaneClsid ().isNull ()) {
                // If it already exists, unmark it for removal, this is a valid sync root.
                entriesToRemove.removeOne (folder.navigationPaneClsid ());

                QString clsidStr = folder.navigationPaneClsid ().toString ();
                QString clsidPath = QString () % R" (Software\Classes\CLSID\)" % clsidStr;
                QString clsidPathWow64 = QString () % R" (Software\Classes\Wow6432Node\CLSID\)" % clsidStr;
                QString namespacePath = QString () % R" (Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\)" % clsidStr;

                QString title = folder.shortGuiRemotePathOrAppName ();
                // Write the account name in the sidebar only when using more than one account.
                if (AccountManager.instance ().accounts ().size () > 1)
                    title = title % " - " % folder.accountState ().account ().displayName ();
                QString iconPath = QDir.toNativeSeparators (qApp.applicationFilePath ());
                QString targetFolderPath = QDir.toNativeSeparators (folder.cleanPath ());

                qCInfo (lcNavPane) << "Explorer Cloud storage provider: saving path" << targetFolderPath << "to CLSID" << clsidStr;

                // This code path should only occur on Windows (the config will be false, and the checkbox invisible on other platforms).
                // Add runtime checks rather than #ifdefing out the whole code to help catch breakages when developing on other platforms.

                // Don't crash, by any means!
                // Q_ASSERT (false);
            }
        }
    }

    // Then remove anything that isn't in our folder list anymore.
    foreach (auto &clsid, entriesToRemove) {
        QString clsidStr = clsid.toString ();
        QString clsidPath = QString () % R" (Software\Classes\CLSID\)" % clsidStr;
        QString clsidPathWow64 = QString () % R" (Software\Classes\Wow6432Node\CLSID\)" % clsidStr;
        QString namespacePath = QString () % R" (Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\)" % clsidStr;

        qCInfo (lcNavPane) << "Explorer Cloud storage provider: now unused, removing own CLSID" << clsidStr;
    }
}

} // namespace OCC
