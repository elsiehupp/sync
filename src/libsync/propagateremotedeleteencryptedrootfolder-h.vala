/*
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

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

    void deleteNestedRemoteItem (QString &filename);
    void decryptAndRemoteDelete ();

    QMap<QString, Occ.SyncJournalFileRecord> _nestedItems; // Nested files and folders
};

}
