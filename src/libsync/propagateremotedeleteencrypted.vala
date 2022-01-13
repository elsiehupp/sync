/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

namespace Occ {

class PropagateRemoteDeleteEncrypted : AbstractPropagateRemoteDeleteEncrypted {
public:
    PropagateRemoteDeleteEncrypted (OwncloudPropagator *propagator, SyncFileItemPtr item, GLib.Object *parent);

    void start () override;

private:
    void slotFolderUnLockedSuccessfully (QByteArray &folderId) override;
    void slotFolderEncryptedMetadataReceived (QJsonDocument &json, int statusCode) override;
};

}
