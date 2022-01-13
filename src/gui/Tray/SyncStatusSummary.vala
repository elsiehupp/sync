/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <theme.h>
// #include <folder.h>

// #include <GLib.Object>

namespace Occ {

class SyncStatusSummary : GLib.Object {

    Q_PROPERTY (double syncProgress READ syncProgress NOTIFY syncProgressChanged)
    Q_PROPERTY (QUrl syncIcon READ syncIcon NOTIFY syncIconChanged)
    Q_PROPERTY (bool syncing READ syncing NOTIFY syncingChanged)
    Q_PROPERTY (string syncStatusString READ syncStatusString NOTIFY syncStatusStringChanged)
    Q_PROPERTY (string syncStatusDetailString READ syncStatusDetailString NOTIFY syncStatusDetailStringChanged)

public:
    SyncStatusSummary (GLib.Object *parent = nullptr);

    double syncProgress ();
    QUrl syncIcon ();
    bool syncing ();
    string syncStatusString ();
    string syncStatusDetailString ();

signals:
    void syncProgressChanged ();
    void syncIconChanged ();
    void syncingChanged ();
    void syncStatusStringChanged ();
    void syncStatusDetailStringChanged ();

public slots:
    void load ();

private:
    void connectToFoldersProgress (Folder.Map &map);

    void onFolderListChanged (Occ.Folder.Map &folderMap);
    void onFolderProgressInfo (ProgressInfo &progress);
    void onFolderSyncStateChanged (Folder *folder);
    void onIsConnectedChanged ();

    void setSyncStateForFolder (Folder *folder);
    void markFolderAsError (Folder *folder);
    void markFolderAsSuccess (Folder *folder);
    bool folderErrors ();
    bool folderError (Folder *folder) const;
    void clearFolderErrors ();
    void setSyncStateToConnectedState ();
    bool reloadNeeded (AccountState *accountState) const;
    void initSyncState ();

    void setSyncProgress (double value);
    void setSyncing (bool value);
    void setSyncStatusString (string &value);
    void setSyncStatusDetailString (string &value);
    void setSyncIcon (QUrl &value);
    void setAccountState (AccountStatePtr accountState);

    AccountStatePtr _accountState;
    std.set<string> _foldersWithErrors;

    QUrl _syncIcon = Theme.instance ().syncStatusOk ();
    double _progress = 1.0;
    bool _isSyncing = false;
    string _syncStatusString = tr ("All synced!");
    string _syncStatusDetailString;
};
}









/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <theme.h>

namespace {

    Occ.SyncResult.Status determineSyncStatus (Occ.SyncResult &syncResult) {
        const auto status = syncResult.status ();
    
        if (status == Occ.SyncResult.Success || status == Occ.SyncResult.Problem) {
            if (syncResult.hasUnresolvedConflicts ()) {
                return Occ.SyncResult.Problem;
            }
            return Occ.SyncResult.Success;
        } else if (status == Occ.SyncResult.SyncPrepare || status == Occ.SyncResult.Undefined) {
            return Occ.SyncResult.SyncRunning;
        }
        return status;
    }
    }
    
    namespace Occ {
    
    Q_LOGGING_CATEGORY (lcSyncStatusModel, "nextcloud.gui.syncstatusmodel", QtInfoMsg)
    
    SyncStatusSummary.SyncStatusSummary (GLib.Object *parent)
        : GLib.Object (parent) {
        const auto folderMan = FolderMan.instance ();
        connect (folderMan, &FolderMan.folderListChanged, this, &SyncStatusSummary.onFolderListChanged);
        connect (folderMan, &FolderMan.folderSyncStateChange, this, &SyncStatusSummary.onFolderSyncStateChanged);
    }
    
    bool SyncStatusSummary.reloadNeeded (AccountState *accountState) {
        if (_accountState.data () == accountState) {
            return false;
        }
        return true;
    }
    
    void SyncStatusSummary.load () {
        const auto currentUser = UserModel.instance ().currentUser ();
        if (!currentUser) {
            return;
        }
        setAccountState (currentUser.accountState ());
        clearFolderErrors ();
        connectToFoldersProgress (FolderMan.instance ().map ());
        initSyncState ();
    }
    
    double SyncStatusSummary.syncProgress () {
        return _progress;
    }
    
    QUrl SyncStatusSummary.syncIcon () {
        return _syncIcon;
    }
    
    bool SyncStatusSummary.syncing () {
        return _isSyncing;
    }
    
    void SyncStatusSummary.onFolderListChanged (Occ.Folder.Map &folderMap) {
        connectToFoldersProgress (folderMap);
    }
    
    void SyncStatusSummary.markFolderAsError (Folder *folder) {
        _foldersWithErrors.insert (folder.alias ());
    }
    
    void SyncStatusSummary.markFolderAsSuccess (Folder *folder) {
        _foldersWithErrors.erase (folder.alias ());
    }
    
    bool SyncStatusSummary.folderErrors () {
        return _foldersWithErrors.size () != 0;
    }
    
    bool SyncStatusSummary.folderError (Folder *folder) {
        return _foldersWithErrors.find (folder.alias ()) != _foldersWithErrors.end ();
    }
    
    void SyncStatusSummary.clearFolderErrors () {
        _foldersWithErrors.clear ();
    }
    
    void SyncStatusSummary.setSyncStateForFolder (Folder *folder) {
        if (_accountState && !_accountState.isConnected ()) {
            setSyncing (false);
            setSyncStatusString (tr ("Offline"));
            setSyncStatusDetailString ("");
            setSyncIcon (Theme.instance ().folderOffline ());
            return;
        }
    
        const auto state = determineSyncStatus (folder.syncResult ());
    
        switch (state) {
        case SyncResult.Success:
        case SyncResult.SyncPrepare:
            // Success should only be shown if all folders were fine
            if (!folderErrors () || folderError (folder)) {
                setSyncing (false);
                setSyncStatusString (tr ("All synced!"));
                setSyncStatusDetailString ("");
                setSyncIcon (Theme.instance ().syncStatusOk ());
                markFolderAsSuccess (folder);
            }
            break;
        case SyncResult.Error:
        case SyncResult.SetupError:
            setSyncing (false);
            setSyncStatusString (tr ("Some files couldn't be synced!"));
            setSyncStatusDetailString (tr ("See below for errors"));
            setSyncIcon (Theme.instance ().syncStatusError ());
            markFolderAsError (folder);
            break;
        case SyncResult.SyncRunning:
        case SyncResult.NotYetStarted:
            setSyncing (true);
            setSyncStatusString (tr ("Syncing"));
            setSyncStatusDetailString ("");
            setSyncIcon (Theme.instance ().syncStatusRunning ());
            break;
        case SyncResult.Paused:
        case SyncResult.SyncAbortRequested:
            setSyncing (false);
            setSyncStatusString (tr ("Sync paused"));
            setSyncStatusDetailString ("");
            setSyncIcon (Theme.instance ().syncStatusPause ());
            break;
        case SyncResult.Problem:
        case SyncResult.Undefined:
            setSyncing (false);
            setSyncStatusString (tr ("Some files could not be synced!"));
            setSyncStatusDetailString (tr ("See below for warnings"));
            setSyncIcon (Theme.instance ().syncStatusWarning ());
            markFolderAsError (folder);
            break;
        }
    }
    
    void SyncStatusSummary.onFolderSyncStateChanged (Folder *folder) {
        if (!folder) {
            return;
        }
    
        if (!_accountState || folder.accountState () != _accountState.data ()) {
            return;
        }
    
        setSyncStateForFolder (folder);
    }
    
    constexpr double calculateOverallPercent (
        int64 totalFileCount, int64 completedFile, int64 totalSize, int64 completedSize) {
        int overallPercent = 0;
        if (totalFileCount > 0) {
            // Add one 'byte' for each file so the percentage is moving when deleting or renaming files
            overallPercent = qRound (double (completedSize + completedFile) / double (totalSize + totalFileCount) * 100.0);
        }
        overallPercent = qBound (0, overallPercent, 100);
        return overallPercent / 100.0;
    }
    
    void SyncStatusSummary.onFolderProgressInfo (ProgressInfo &progress) {
        const int64 completedSize = progress.completedSize ();
        const int64 currentFile = progress.currentFile ();
        const int64 completedFile = progress.completedFiles ();
        const int64 totalSize = qMax (completedSize, progress.totalSize ());
        const int64 totalFileCount = qMax (currentFile, progress.totalFiles ());
    
        setSyncProgress (calculateOverallPercent (totalFileCount, completedFile, totalSize, completedSize));
    
        if (totalSize > 0) {
            const auto completedSizeString = Utility.octetsToString (completedSize);
            const auto totalSizeString = Utility.octetsToString (totalSize);
    
            if (progress.trustEta ()) {
                setSyncStatusDetailString (
                    tr ("%1 of %2 · %3 left")
                        .arg (completedSizeString, totalSizeString)
                        .arg (Utility.durationToDescriptiveString1 (progress.totalProgress ().estimatedEta)));
            } else {
                setSyncStatusDetailString (tr ("%1 of %2").arg (completedSizeString, totalSizeString));
            }
        }
    
        if (totalFileCount > 0) {
            setSyncStatusString (tr ("Syncing file %1 of %2").arg (currentFile).arg (totalFileCount));
        }
    }
    
    void SyncStatusSummary.setSyncing (bool value) {
        if (value == _isSyncing) {
            return;
        }
    
        _isSyncing = value;
        emit syncingChanged ();
    }
    
    void SyncStatusSummary.setSyncProgress (double value) {
        if (_progress == value) {
            return;
        }
    
        _progress = value;
        emit syncProgressChanged ();
    }
    
    void SyncStatusSummary.setSyncStatusString (string &value) {
        if (_syncStatusString == value) {
            return;
        }
    
        _syncStatusString = value;
        emit syncStatusStringChanged ();
    }
    
    string SyncStatusSummary.syncStatusString () {
        return _syncStatusString;
    }
    
    string SyncStatusSummary.syncStatusDetailString () {
        return _syncStatusDetailString;
    }
    
    void SyncStatusSummary.setSyncIcon (QUrl &value) {
        if (_syncIcon == value) {
            return;
        }
    
        _syncIcon = value;
        emit syncIconChanged ();
    }
    
    void SyncStatusSummary.setSyncStatusDetailString (string &value) {
        if (_syncStatusDetailString == value) {
            return;
        }
    
        _syncStatusDetailString = value;
        emit syncStatusDetailStringChanged ();
    }
    
    void SyncStatusSummary.connectToFoldersProgress (Folder.Map &folderMap) {
        for (auto &folder : folderMap) {
            if (folder.accountState () == _accountState.data ()) {
                connect (
                    folder, &Folder.progressInfo, this, &SyncStatusSummary.onFolderProgressInfo, Qt.UniqueConnection);
            } else {
                disconnect (folder, &Folder.progressInfo, this, &SyncStatusSummary.onFolderProgressInfo);
            }
        }
    }
    
    void SyncStatusSummary.onIsConnectedChanged () {
        setSyncStateToConnectedState ();
    }
    
    void SyncStatusSummary.setSyncStateToConnectedState () {
        setSyncing (false);
        setSyncStatusDetailString ("");
        if (_accountState && !_accountState.isConnected ()) {
            setSyncStatusString (tr ("Offline"));
            setSyncIcon (Theme.instance ().folderOffline ());
        } else {
            setSyncStatusString (tr ("All synced!"));
            setSyncIcon (Theme.instance ().syncStatusOk ());
        }
    }
    
    void SyncStatusSummary.setAccountState (AccountStatePtr accountState) {
        if (!reloadNeeded (accountState.data ())) {
            return;
        }
        if (_accountState) {
            disconnect (
                _accountState.data (), &AccountState.isConnectedChanged, this, &SyncStatusSummary.onIsConnectedChanged);
        }
        _accountState = accountState;
        connect (_accountState.data (), &AccountState.isConnectedChanged, this, &SyncStatusSummary.onIsConnectedChanged);
    }
    
    void SyncStatusSummary.initSyncState () {
        auto syncStateFallbackNeeded = true;
        for (auto &folder : FolderMan.instance ().map ()) {
            onFolderSyncStateChanged (folder);
            syncStateFallbackNeeded = false;
        }
    
        if (syncStateFallbackNeeded) {
            setSyncStateToConnectedState ();
        }
    }
    }
    