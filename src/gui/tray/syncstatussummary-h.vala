/*
 * Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>
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

// #pragma once

// #include <theme.h>
// #include <folder.h>

// #include <QObject>

namespace OCC {

class SyncStatusSummary : public QObject {

    Q_PROPERTY(double syncProgress READ syncProgress NOTIFY syncProgressChanged)
    Q_PROPERTY(QUrl syncIcon READ syncIcon NOTIFY syncIconChanged)
    Q_PROPERTY(bool syncing READ syncing NOTIFY syncingChanged)
    Q_PROPERTY(QString syncStatusString READ syncStatusString NOTIFY syncStatusStringChanged)
    Q_PROPERTY(QString syncStatusDetailString READ syncStatusDetailString NOTIFY syncStatusDetailStringChanged)

public:
    explicit SyncStatusSummary(QObject *parent = nullptr);

    double syncProgress() const;
    QUrl syncIcon() const;
    bool syncing() const;
    QString syncStatusString() const;
    QString syncStatusDetailString() const;

signals:
    void syncProgressChanged();
    void syncIconChanged();
    void syncingChanged();
    void syncStatusStringChanged();
    void syncStatusDetailStringChanged();

public slots:
    void load();

private:
    void connectToFoldersProgress(Folder::Map &map);

    void onFolderListChanged(OCC::Folder::Map &folderMap);
    void onFolderProgressInfo(ProgressInfo &progress);
    void onFolderSyncStateChanged(Folder *folder);
    void onIsConnectedChanged();

    void setSyncStateForFolder(Folder *folder);
    void markFolderAsError(Folder *folder);
    void markFolderAsSuccess(Folder *folder);
    bool folderErrors() const;
    bool folderError(Folder *folder) const;
    void clearFolderErrors();
    void setSyncStateToConnectedState();
    bool reloadNeeded(AccountState *accountState) const;
    void initSyncState();

    void setSyncProgress(double value);
    void setSyncing(bool value);
    void setSyncStatusString(QString &value);
    void setSyncStatusDetailString(QString &value);
    void setSyncIcon(QUrl &value);
    void setAccountState(AccountStatePtr accountState);

    AccountStatePtr _accountState;
    std::set<QString> _foldersWithErrors;

    QUrl _syncIcon = Theme::instance()->syncStatusOk();
    double _progress = 1.0;
    bool _isSyncing = false;
    QString _syncStatusString = tr("All synced!");
    QString _syncStatusDetailString;
};
}
