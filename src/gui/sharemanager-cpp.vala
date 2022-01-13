/*
Copyright (C) by Roeland Jago Douma <rullzer@owncloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QUrl>
// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QJsonArray>

Q_LOGGING_CATEGORY (lcUserGroupShare, "nextcloud.gui.usergroupshare", QtInfoMsg)

namespace Occ {

/**
When a share is modified, we need to tell the folders so they can adjust overlay icons
*/
static void updateFolder (AccountPtr &account, QString &path) {
    foreach (Folder *f, FolderMan.instance ().map ()) {
        if (f.accountState ().account () != account)
            continue;
        auto folderPath = f.remotePath ();
        if (path.startsWith (folderPath) && (path == folderPath || folderPath.endsWith ('/') || path[folderPath.size ()] == '/')) {
            // Workaround the fact that the server does not invalidate the etags of parent directories
            // when something is shared.
            auto relative = path.midRef (f.remotePathTrailingSlash ().length ());
            f.journalDb ().schedulePathForRemoteDiscovery (relative.toString ());

            // Schedule a sync so it can update the remote permission flag and let the socket API
            // know about the shared icon.
            f.scheduleThisFolderSoon ();
        }
    }
}

Share.Share (AccountPtr account,
    const QString &id,
    const QString &uidowner,
    const QString &ownerDisplayName,
    const QString &path,
    const ShareType shareType,
    bool isPasswordSet,
    const Permissions permissions,
    const QSharedPointer<Sharee> shareWith)
    : _account (account)
    , _id (id)
    , _uidowner (uidowner)
    , _ownerDisplayName (ownerDisplayName)
    , _path (path)
    , _shareType (shareType)
    , _isPasswordSet (isPasswordSet)
    , _permissions (permissions)
    , _shareWith (shareWith) {
}

AccountPtr Share.account () {
    return _account;
}

QString Share.path () {
    return _path;
}

QString Share.getId () {
    return _id;
}

QString Share.getUidOwner () {
    return _uidowner;
}

QString Share.getOwnerDisplayName () {
    return _ownerDisplayName;
}

Share.ShareType Share.getShareType () {
    return _shareType;
}

QSharedPointer<Sharee> Share.getShareWith () {
    return _shareWith;
}

void Share.setPassword (QString &password) {
    auto * const job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, &Share.slotPasswordSet);
    connect (job, &OcsJob.ocsError, this, &Share.slotSetPasswordError);
    job.setPassword (getId (), password);
}

bool Share.isPasswordSet () {
    return _isPasswordSet;
}

void Share.setPermissions (Permissions permissions) {
    auto *job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, &Share.slotPermissionsSet);
    connect (job, &OcsJob.ocsError, this, &Share.slotOcsError);
    job.setPermissions (getId (), permissions);
}

void Share.slotPermissionsSet (QJsonDocument &, QVariant &value) {
    _permissions = (Permissions)value.toInt ();
    emit permissionsSet ();
}

Share.Permissions Share.getPermissions () {
    return _permissions;
}

void Share.deleteShare () {
    auto *job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, &Share.slotDeleted);
    connect (job, &OcsJob.ocsError, this, &Share.slotOcsError);
    job.deleteShare (getId ());
}

bool Share.isShareTypeUserGroupEmailRoomOrRemote (ShareType type) {
    return (type == Share.TypeUser || type == Share.TypeGroup || type == Share.TypeEmail || type == Share.TypeRoom
        || type == Share.TypeRemote);
}

void Share.slotDeleted () {
    updateFolder (_account, _path);
    emit shareDeleted ();
}

void Share.slotOcsError (int statusCode, QString &message) {
    emit serverError (statusCode, message);
}

void Share.slotPasswordSet (QJsonDocument &, QVariant &value) {
    _isPasswordSet = !value.toString ().isEmpty ();
    emit passwordSet ();
}

void Share.slotSetPasswordError (int statusCode, QString &message) {
    emit passwordSetError (statusCode, message);
}

QUrl LinkShare.getLink () {
    return _url;
}

QUrl LinkShare.getDirectDownloadLink () {
    QUrl url = _url;
    url.setPath (url.path () + "/download");
    return url;
}

QDate LinkShare.getExpireDate () {
    return _expireDate;
}

LinkShare.LinkShare (AccountPtr account,
    const QString &id,
    const QString &uidowner,
    const QString &ownerDisplayName,
    const QString &path,
    const QString &name,
    const QString &token,
    Permissions permissions,
    bool isPasswordSet,
    const QUrl &url,
    const QDate &expireDate,
    const QString &note,
    const QString &label)
    : Share (account, id, uidowner, ownerDisplayName, path, Share.TypeLink, isPasswordSet, permissions)
    , _name (name)
    , _token (token)
    , _note (note)
    , _expireDate (expireDate)
    , _url (url)
    , _label (label) {
}

bool LinkShare.getPublicUpload () {
    return _permissions & SharePermissionCreate;
}

bool LinkShare.getShowFileListing () {
    return _permissions & SharePermissionRead;
}

QString LinkShare.getName () {
    return _name;
}

QString LinkShare.getNote () {
    return _note;
}

QString LinkShare.getLabel () {
    return _label;
}

void LinkShare.setName (QString &name) {
    createShareJob (&LinkShare.slotNameSet).setName (getId (), name);
}

void LinkShare.setNote (QString &note) {
    createShareJob (&LinkShare.slotNoteSet).setNote (getId (), note);
}

void LinkShare.slotNoteSet (QJsonDocument &, QVariant &note) {
    _note = note.toString ();
    emit noteSet ();
}

QString LinkShare.getToken () {
    return _token;
}

void LinkShare.setExpireDate (QDate &date) {
    createShareJob (&LinkShare.slotExpireDateSet).setExpireDate (getId (), date);
}

void LinkShare.setLabel (QString &label) {
    createShareJob (&LinkShare.slotLabelSet).setLabel (getId (), label);
}

template <typename LinkShareSlot>
OcsShareJob *LinkShare.createShareJob (LinkShareSlot slotFunction) {
    auto *job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, slotFunction);
    connect (job, &OcsJob.ocsError, this, &LinkShare.slotOcsError);
    return job;
}

void LinkShare.slotExpireDateSet (QJsonDocument &reply, QVariant &value) {
    auto data = reply.object ().value ("ocs").toObject ().value ("data").toObject ();

    /*
     * If the reply provides a data back (more REST style)
     * they use this date.
     */
    if (data.value ("expiration").isString ()) {
        _expireDate = QDate.fromString (data.value ("expiration").toString (), "yyyy-MM-dd 00:00:00");
    } else {
        _expireDate = value.toDate ();
    }
    emit expireDateSet ();
}

void LinkShare.slotNameSet (QJsonDocument &, QVariant &value) {
    _name = value.toString ();
    emit nameSet ();
}

void LinkShare.slotLabelSet (QJsonDocument &, QVariant &label) {
    if (_label != label.toString ()) {
        _label = label.toString ();
        emit labelSet ();
    }
}

UserGroupShare.UserGroupShare (AccountPtr account,
    const QString &id,
    const QString &owner,
    const QString &ownerDisplayName,
    const QString &path,
    const ShareType shareType,
    bool isPasswordSet,
    const Permissions permissions,
    const QSharedPointer<Sharee> shareWith,
    const QDate &expireDate,
    const QString &note)
    : Share (account, id, owner, ownerDisplayName, path, shareType, isPasswordSet, permissions, shareWith)
    , _note (note)
    , _expireDate (expireDate) {
    Q_ASSERT (Share.isShareTypeUserGroupEmailRoomOrRemote (shareType));
    Q_ASSERT (shareWith);
}

void UserGroupShare.setNote (QString &note) {
    auto *job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, &UserGroupShare.slotNoteSet);
    connect (job, &OcsJob.ocsError, this, &UserGroupShare.noteSetError);
    job.setNote (getId (), note);
}

QString UserGroupShare.getNote () {
    return _note;
}

void UserGroupShare.slotNoteSet (QJsonDocument &, QVariant &note) {
    _note = note.toString ();
    emit noteSet ();
}

QDate UserGroupShare.getExpireDate () {
    return _expireDate;
}

void UserGroupShare.setExpireDate (QDate &date) {
    if (_expireDate == date) {
        emit expireDateSet ();
        return;
    }

    auto *job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, &UserGroupShare.slotExpireDateSet);
    connect (job, &OcsJob.ocsError, this, &UserGroupShare.slotOcsError);
    job.setExpireDate (getId (), date);
}

void UserGroupShare.slotExpireDateSet (QJsonDocument &reply, QVariant &value) {
    auto data = reply.object ().value ("ocs").toObject ().value ("data").toObject ();

    /*
     * If the reply provides a data back (more REST style)
     * they use this date.
     */
    if (data.value ("expiration").isString ()) {
        _expireDate = QDate.fromString (data.value ("expiration").toString (), "yyyy-MM-dd 00:00:00");
    } else {
        _expireDate = value.toDate ();
    }
    emit expireDateSet ();
}

ShareManager.ShareManager (AccountPtr account, GLib.Object *parent)
    : GLib.Object (parent)
    , _account (account) {
}

void ShareManager.createLinkShare (QString &path,
    const QString &name,
    const QString &password) {
    auto *job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, &ShareManager.slotLinkShareCreated);
    connect (job, &OcsJob.ocsError, this, &ShareManager.slotOcsError);
    job.createLinkShare (path, name, password);
}

void ShareManager.slotLinkShareCreated (QJsonDocument &reply) {
    QString message;
    int code = OcsShareJob.getJsonReturnCode (reply, message);

    /*
     * Before we had decent sharing capabilities on the server a 403 "generally"
     * meant that a share was password protected
     */
    if (code == 403) {
        emit linkShareRequiresPassword (message);
        return;
    }

    //Parse share
    auto data = reply.object ().value ("ocs").toObject ().value ("data").toObject ();
    QSharedPointer<LinkShare> share (parseLinkShare (data));

    emit linkShareCreated (share);

    updateFolder (_account, share.path ());
}

void ShareManager.createShare (QString &path,
    const Share.ShareType shareType,
    const QString shareWith,
    const Share.Permissions desiredPermissions,
    const QString &password) {
    auto job = new OcsShareJob (_account);
    connect (job, &OcsJob.ocsError, this, &ShareManager.slotOcsError);
    connect (job, &OcsShareJob.shareJobFinished, this,
        [=] (QJsonDocument &reply) {
            // Find existing share permissions (if this was shared with us)
            Share.Permissions existingPermissions = SharePermissionDefault;
            foreach (QJsonValue &element, reply.object ()["ocs"].toObject ()["data"].toArray ()) {
                auto map = element.toObject ();
                if (map["file_target"] == path)
                    existingPermissions = Share.Permissions (map["permissions"].toInt ());
            }

            // Limit the permissions we request for a share to the ones the item
            // was shared with initially.
            auto validPermissions = desiredPermissions;
            if (validPermissions == SharePermissionDefault) {
                validPermissions = existingPermissions;
            }
            if (existingPermissions != SharePermissionDefault) {
                validPermissions &= existingPermissions;
            }

            auto *job = new OcsShareJob (_account);
            connect (job, &OcsShareJob.shareJobFinished, this, &ShareManager.slotShareCreated);
            connect (job, &OcsJob.ocsError, this, &ShareManager.slotOcsError);
            job.createShare (path, shareType, shareWith, validPermissions, password);
        });
    job.getSharedWithMe ();
}

void ShareManager.slotShareCreated (QJsonDocument &reply) {
    //Parse share
    auto data = reply.object ().value ("ocs").toObject ().value ("data").toObject ();
    QSharedPointer<Share> share (parseShare (data));

    emit shareCreated (share);

    updateFolder (_account, share.path ());
}

void ShareManager.fetchShares (QString &path) {
    auto *job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, &ShareManager.slotSharesFetched);
    connect (job, &OcsJob.ocsError, this, &ShareManager.slotOcsError);
    job.getShares (path);
}

void ShareManager.slotSharesFetched (QJsonDocument &reply) {
    auto tmpShares = reply.object ().value ("ocs").toObject ().value ("data").toArray ();
    const QString versionString = _account.serverVersion ();
    qCDebug (lcSharing) << versionString << "Fetched" << tmpShares.count () << "shares";

    QList<QSharedPointer<Share>> shares;

    foreach (auto &share, tmpShares) {
        auto data = share.toObject ();

        auto shareType = data.value ("share_type").toInt ();

        QSharedPointer<Share> newShare;

        if (shareType == Share.TypeLink) {
            newShare = parseLinkShare (data);
        } else if (Share.isShareTypeUserGroupEmailRoomOrRemote (static_cast <Share.ShareType> (shareType))) {
            newShare = parseUserGroupShare (data);
        } else {
            newShare = parseShare (data);
        }

        shares.append (QSharedPointer<Share> (newShare));
    }

    qCDebug (lcSharing) << "Sending " << shares.count () << "shares";
    emit sharesFetched (shares);
}

QSharedPointer<UserGroupShare> ShareManager.parseUserGroupShare (QJsonObject &data) {
    QSharedPointer<Sharee> sharee (new Sharee (data.value ("share_with").toString (),
        data.value ("share_with_displayname").toString (),
        static_cast<Sharee.Type> (data.value ("share_type").toInt ())));

    QDate expireDate;
    if (data.value ("expiration").isString ()) {
        expireDate = QDate.fromString (data.value ("expiration").toString (), "yyyy-MM-dd 00:00:00");
    }

    QString note;
    if (data.value ("note").isString ()) {
        note = data.value ("note").toString ();
    }

    return QSharedPointer<UserGroupShare> (new UserGroupShare (_account,
        data.value ("id").toVariant ().toString (), // "id" used to be an integer, support both
        data.value ("uid_owner").toVariant ().toString (),
        data.value ("displayname_owner").toVariant ().toString (),
        data.value ("path").toString (),
        static_cast<Share.ShareType> (data.value ("share_type").toInt ()),
        !data.value ("password").toString ().isEmpty (),
        static_cast<Share.Permissions> (data.value ("permissions").toInt ()),
        sharee,
        expireDate,
        note));
}

QSharedPointer<LinkShare> ShareManager.parseLinkShare (QJsonObject &data) {
    QUrl url;

    // From ownCloud server 8.2 the url field is always set for public shares
    if (data.contains ("url")) {
        url = QUrl (data.value ("url").toString ());
    } else if (_account.serverVersionInt () >= Account.makeServerVersion (8, 0, 0)) {
        // From ownCloud server version 8 on, a different share link scheme is used.
        url = QUrl (Utility.concatUrlPath (_account.url (), QLatin1String ("index.php/s/") + data.value ("token").toString ())).toString ();
    } else {
        QUrlQuery queryArgs;
        queryArgs.addQueryItem (QLatin1String ("service"), QLatin1String ("files"));
        queryArgs.addQueryItem (QLatin1String ("t"), data.value ("token").toString ());
        url = QUrl (Utility.concatUrlPath (_account.url (), QLatin1String ("public.php"), queryArgs).toString ());
    }

    QDate expireDate;
    if (data.value ("expiration").isString ()) {
        expireDate = QDate.fromString (data.value ("expiration").toString (), "yyyy-MM-dd 00:00:00");
    }

    QString note;
    if (data.value ("note").isString ()) {
        note = data.value ("note").toString ();
    }

    return QSharedPointer<LinkShare> (new LinkShare (_account,
        data.value ("id").toVariant ().toString (), // "id" used to be an integer, support both
        data.value ("uid_owner").toString (),
        data.value ("displayname_owner").toString (),
        data.value ("path").toString (),
        data.value ("name").toString (),
        data.value ("token").toString (),
        (Share.Permissions)data.value ("permissions").toInt (),
        data.value ("share_with").isString (), // has password?
        url,
        expireDate,
        note,
        data.value ("label").toString ()));
}

QSharedPointer<Share> ShareManager.parseShare (QJsonObject &data) {
    QSharedPointer<Sharee> sharee (new Sharee (data.value ("share_with").toString (),
        data.value ("share_with_displayname").toString (),
        (Sharee.Type)data.value ("share_type").toInt ()));

    return QSharedPointer<Share> (new Share (_account,
        data.value ("id").toVariant ().toString (), // "id" used to be an integer, support both
        data.value ("uid_owner").toVariant ().toString (),
        data.value ("displayname_owner").toVariant ().toString (),
        data.value ("path").toString (),
        (Share.ShareType)data.value ("share_type").toInt (),
        !data.value ("password").toString ().isEmpty (),
        (Share.Permissions)data.value ("permissions").toInt (),
        sharee));
}

void ShareManager.slotOcsError (int statusCode, QString &message) {
    emit serverError (statusCode, message);
}
}
