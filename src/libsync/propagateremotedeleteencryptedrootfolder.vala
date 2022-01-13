/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QMap>

namespace Occ {

class PropagateRemoteDeleteEncryptedRootFolder : AbstractPropagateRemoteDeleteEncrypted {
public:
    PropagateRemoteDeleteEncryptedRootFolder (OwncloudPropagator *propagator, SyncFileItemPtr item, GLib.Object *parent);

    void start () override;

private:
    void slotFolderUnLockedSuccessfully (QByteArray &folderId) override;
    void slotFolderEncryptedMetadataReceived (QJsonDocument &json, int statusCode) override;
    void slotDeleteNestedRemoteItemFinished ();

    void deleteNestedRemoteItem (string &filename);
    void decryptAndRemoteDelete ();

    QMap<string, Occ.SyncJournalFileRecord> _nestedItems; // Nested files and folders
};

}
