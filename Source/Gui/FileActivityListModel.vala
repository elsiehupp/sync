/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

namespace Occ {

class FileActivityListModel : ActivityListModel {

public:
    FileActivityListModel (GLib.Object *parent = nullptr);

public slots:
    void load (AccountState *accountState, string &fileId);

protected:
    void startFetchJob () override;

private:
    string _fileId;
};
    FileActivityListModel.FileActivityListModel (GLib.Object *parent)
        : ActivityListModel (nullptr, parent) {
        setDisplayActions (false);
    }
    
    void FileActivityListModel.load (AccountState *accountState, string &localPath) {
        Q_ASSERT (accountState);
        if (!accountState || currentlyFetching ()) {
            return;
        }
        setAccountState (accountState);
    
        const auto folder = FolderMan.instance ().folderForPath (localPath);
        if (!folder) {
            return;
        }
    
        const auto file = folder.fileFromLocalPath (localPath);
        SyncJournalFileRecord fileRecord;
        if (!folder.journalDb ().getFileRecord (file, &fileRecord) || !fileRecord.isValid ()) {
            return;
        }
    
        _fileId = fileRecord._fileId;
        slotRefreshActivity ();
    }
    
    void FileActivityListModel.startFetchJob () {
        if (!accountState ().isConnected ()) {
            return;
        }
        setCurrentlyFetching (true);
    
        const string url (QStringLiteral ("ocs/v2.php/apps/activity/api/v2/activity/filter"));
        auto job = new JsonApiJob (accountState ().account (), url, this);
        GLib.Object.connect (job, &JsonApiJob.jsonReceived,
            this, &FileActivityListModel.activitiesReceived);
    
        QUrlQuery params;
        params.addQueryItem (QStringLiteral ("sort"), QStringLiteral ("asc"));
        params.addQueryItem (QStringLiteral ("object_type"), "files");
        params.addQueryItem (QStringLiteral ("object_id"), _fileId);
        job.addQueryParams (params);
        setDoneFetching (true);
        setHideOldActivities (true);
        job.start ();
    }
    }
    