/*
 * Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>
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

// #include <QObject>
// #include <QString>
// #include <QNetworkReply>

namespace OCC {

class OwncloudPropagator;
/**
 * @brief The AbstractPropagateRemoteDeleteEncrypted class is the base class for Propagate Remote Delete Encrypted jobs
 * @ingroup libsync
 */
class AbstractPropagateRemoteDeleteEncrypted : public QObject {
public:
    AbstractPropagateRemoteDeleteEncrypted (OwncloudPropagator *propagator, SyncFileItemPtr item, QObject *parent);
    ~AbstractPropagateRemoteDeleteEncrypted () override = default;

    QNetworkReply.NetworkError networkError () const;
    QString errorString () const;

    virtual void start () = 0;

signals:
    void finished (bool success);

protected:
    void storeFirstError (QNetworkReply.NetworkError err);
    void storeFirstErrorString (QString &errString);

    void startLsColJob (QString &path);
    void slotFolderEncryptedIdReceived (QStringList &list);
    void slotTryLock (QByteArray &folderId);
    void slotFolderLockedSuccessfully (QByteArray &folderId, QByteArray &token);
    virtual void slotFolderUnLockedSuccessfully (QByteArray &folderId);
    virtual void slotFolderEncryptedMetadataReceived (QJsonDocument &json, int statusCode) = 0;
    void slotDeleteRemoteItemFinished ();

    void deleteRemoteItem (QString &filename);
    void unlockFolder ();
    void taskFailed ();

protected:
    OwncloudPropagator *_propagator = nullptr;
    SyncFileItemPtr _item;
    QByteArray _folderToken;
    QByteArray _folderId;
    bool _folderLocked = false;
    bool _isTaskFailed = false;
    QNetworkReply.NetworkError _networkError = QNetworkReply.NoError;
    QString _errorString;
};

}
