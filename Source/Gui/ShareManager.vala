/***********************************************************
Copyright (C) by Roeland Jago Douma <rullzer@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QUrl>
// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QJsonArray>


// #include <GLib.Object>
// #include <QDate>
// #include <string>
// #include <QList>
// #include <QSharedPointer>
// #include <QUrl>



namespace Occ {


class Share : GLib.Object {

public:
    /***********************************************************
    Possible share types
    Need to be in sync with Sharee.Type
    ***********************************************************/
    enum ShareType {
        TypeUser = Sharee.User,
        TypeGroup = Sharee.Group,
        TypeLink = 3,
        TypeEmail = Sharee.Email,
        TypeRemote = Sharee.Federated,
        TypeCircle = Sharee.Circle,
        TypeRoom = Sharee.Room
    };

    using Permissions = SharePermissions;

    /***********************************************************
    Constructor for shares
    ***********************************************************/
    Share (AccountPtr account,
        const string &id,
        const string &owner,
        const string &ownerDisplayName,
        const string &path,
        const ShareType shareType,
        bool isPasswordSet = false,
        const Permissions permissions = SharePermissionDefault,
        const QSharedPointer<Sharee> shareWith = QSharedPointer<Sharee> (nullptr));

    /***********************************************************
    The account the share is defined on.
    ***********************************************************/
    AccountPtr account ();

    string path ();

    /***********************************************************
    Get the id
    ***********************************************************/
    string getId ();

    /***********************************************************
    Get the uid_owner
    ***********************************************************/
    string getUidOwner ();

    /***********************************************************
    Get the owner display name
    ***********************************************************/
    string getOwnerDisplayName ();

    /***********************************************************
    Get the shareType
    ***********************************************************/
    ShareType getShareType ();

    /***********************************************************
    Get the shareWith
    ***********************************************************/
    QSharedPointer<Sharee> getShareWith ();

    /***********************************************************
    Get permissions
    ***********************************************************/
    Permissions getPermissions ();

    /***********************************************************
    Set the permissions of a share
    
    On success the permissionsSet signal is emitted
    In case of a server error the serverError signal is emitted.
    ***********************************************************/
    void setPermissions (Permissions permissions);

    /***********************************************************
    Set the password for remote share
    
    On success the passwordSet signal is emitted
    In case of a server error the passwordSetError signal is emitted.
    ***********************************************************/
    void setPassword (string &password);

    bool isPasswordSet ();

    /***********************************************************
    Deletes a share
    
    On success the shareDeleted signal is emitted
    In case of a server error the serverError signal is emitted.
    ***********************************************************/
    void deleteShare ();

     /***********************************************************
    Is it a share with a user or group (local or remote)
    ***********************************************************/
    static bool isShareTypeUserGroupEmailRoomOrRemote (ShareType type);

signals:
    void permissionsSet ();
    void shareDeleted ();
    void serverError (int code, string &message);
    void passwordSet ();
    void passwordSetError (int statusCode, string &message);

protected:
    AccountPtr _account;
    string _id;
    string _uidowner;
    string _ownerDisplayName;
    string _path;
    ShareType _shareType;
    bool _isPasswordSet;
    Permissions _permissions;
    QSharedPointer<Sharee> _shareWith;

protected slots:
    void slotOcsError (int statusCode, string &message);
    void slotPasswordSet (QJsonDocument &, QVariant &value);
    void slotSetPasswordError (int statusCode, string &message);

private slots:
    void slotDeleted ();
    void slotPermissionsSet (QJsonDocument &, QVariant &value);
};

/***********************************************************
A Link share is just like a regular share but then slightly different.
There are several methods in the API that either work differently for
link shares or are only available to link shares.
***********************************************************/
class LinkShare : Share {
public:
    LinkShare (AccountPtr account,
        const string &id,
        const string &uidowner,
        const string &ownerDisplayName,
        const string &path,
        const string &name,
        const string &token,
        const Permissions permissions,
        bool isPasswordSet,
        const QUrl &url,
        const QDate &expireDate,
        const string &note,
        const string &label);

    /***********************************************************
    Get the share link
    ***********************************************************/
    QUrl getLink ();

    /***********************************************************
    The share's link for direct downloading.
    ***********************************************************/
    QUrl getDirectDownloadLink ();

    /***********************************************************
    Get the publicUpload status of this share
    ***********************************************************/
    bool getPublicUpload ();

    /***********************************************************
    Whether directory listings are available (READ permission)
    ***********************************************************/
    bool getShowFileListing ();

    /***********************************************************
    Returns the name of the link share. Can be empty.
    ***********************************************************/
    string getName ();

    /***********************************************************
    Returns the note of the link share.
    ***********************************************************/
    string getNote ();

    /***********************************************************
    Returns the label of the link share.
    ***********************************************************/
    string getLabel ();

    /***********************************************************
    Set the name of the link share.
    
    Emits either nameSet () or serverError ().
    ***********************************************************/
    void setName (string &name);

    /***********************************************************
    Set the note of the link share.
    ***********************************************************/
    void setNote (string &note);

    /***********************************************************
    Returns the token of the link share.
    ***********************************************************/
    string getToken ();

    /***********************************************************
    Get the expiration date
    ***********************************************************/
    QDate getExpireDate ();

    /***********************************************************
    Set the expiration date
    
    On success the expireDateSet signal is emitted
    In case of a server error the serverError signal is emitted.
    ***********************************************************/
    void setExpireDate (QDate &expireDate);

    /***********************************************************
    Set the label of the share link.
    ***********************************************************/
    void setLabel (string &label);

    /***********************************************************
    Create OcsShareJob and connect to signal/slots
    ***********************************************************/
    template <typename LinkShareSlot>
    OcsShareJob *createShareJob (LinkShareSlot slotFunction);

signals:
    void expireDateSet ();
    void noteSet ();
    void nameSet ();
    void labelSet ();

private slots:
    void slotNoteSet (QJsonDocument &, QVariant &value);
    void slotExpireDateSet (QJsonDocument &reply, QVariant &value);
    void slotNameSet (QJsonDocument &, QVariant &value);
    void slotLabelSet (QJsonDocument &, QVariant &value);

private:
    string _name;
    string _token;
    string _note;
    QDate _expireDate;
    QUrl _url;
    string _label;
};

class UserGroupShare : Share {
public:
    UserGroupShare (AccountPtr account,
        const string &id,
        const string &owner,
        const string &ownerDisplayName,
        const string &path,
        const ShareType shareType,
        bool isPasswordSet,
        const Permissions permissions,
        const QSharedPointer<Sharee> shareWith,
        const QDate &expireDate,
        const string &note);

    void setNote (string &note);

    string getNote ();

    void slotNoteSet (QJsonDocument &, QVariant &note);

    void setExpireDate (QDate &date);

    QDate getExpireDate ();

    void slotExpireDateSet (QJsonDocument &reply, QVariant &value);

signals:
    void noteSet ();
    void noteSetError ();
    void expireDateSet ();

private:
    string _note;
    QDate _expireDate;
};

/***********************************************************
The share manager allows for creating, retrieving and deletion
of shares. It abstracts away from the OCS Share API, all the usages
shares should talk to this manager and not use OCS Share Job directly
***********************************************************/
class ShareManager : GLib.Object {
public:
    ShareManager (AccountPtr _account, GLib.Object *parent = nullptr);

    /***********************************************************
    Tell the manager to create a link share
    
    @param path The path of the linkshare relative to the u
    @param name The name of the created share, may be empty
    @param password The password of the share, may be
    
    On success the signal linkShareCreated is emitted
    For older server the linkShareRequiresPassword signal is emitted when it seems appropiate
    In case of a server error the serverError signal is emitted
    ***********************************************************/
    void createLinkShare (string &path,
        const string &name,
        const string &password);

    /***********************************************************
    Tell the manager to create a new share
    
    @param path The path of the share relative to the user folder on the
    @param shareType The type of share (TypeU
    @param Permissions The share permissions
    
    On success the signal shareCreated is emitted
    In case of a server error the serverError signal is emitted
    ***********************************************************/
    void createShare (string &path,
        const Share.ShareType shareType,
        const string shareWith,
        const Share.Permissions permissions,
        const string &password = "");

    /***********************************************************
    Fetch all the shares for path
    
    @param path The path to get the shares for rel
    
    On success the sharesFetched signal is emitted
    In case of a server error the serverError signal is emitted
    ***********************************************************/
    void fetchShares (string &path);

signals:
    void shareCreated (QSharedPointer<Share> &share);
    void linkShareCreated (QSharedPointer<LinkShare> &share);
    void sharesFetched (QList<QSharedPointer<Share>> &shares);
    void serverError (int code, string &message);

    /***********************************************************
    Emitted when creating a link share with password fails.

    @param message the error message reported by the server
    
    See createLinkShare ().
    ***********************************************************/
    void linkShareRequiresPassword (string &message);

private slots:
    void slotSharesFetched (QJsonDocument &reply);
    void slotLinkShareCreated (QJsonDocument &reply);
    void slotShareCreated (QJsonDocument &reply);
    void slotOcsError (int statusCode, string &message);
private:
    QSharedPointer<LinkShare> parseLinkShare (QJsonObject &data);
    QSharedPointer<UserGroupShare> parseUserGroupShare (QJsonObject &data);
    QSharedPointer<Share> parseShare (QJsonObject &data);

    AccountPtr _account;
};


/***********************************************************
When a share is modified, we need to tell the folders so they can adjust overlay icons
***********************************************************/
static void updateFolder (AccountPtr &account, string &path) {
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
    const string &id,
    const string &uidowner,
    const string &ownerDisplayName,
    const string &path,
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

string Share.path () {
    return _path;
}

string Share.getId () {
    return _id;
}

string Share.getUidOwner () {
    return _uidowner;
}

string Share.getOwnerDisplayName () {
    return _ownerDisplayName;
}

Share.ShareType Share.getShareType () {
    return _shareType;
}

QSharedPointer<Sharee> Share.getShareWith () {
    return _shareWith;
}

void Share.setPassword (string &password) {
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

void Share.slotOcsError (int statusCode, string &message) {
    emit serverError (statusCode, message);
}

void Share.slotPasswordSet (QJsonDocument &, QVariant &value) {
    _isPasswordSet = !value.toString ().isEmpty ();
    emit passwordSet ();
}

void Share.slotSetPasswordError (int statusCode, string &message) {
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
    const string &id,
    const string &uidowner,
    const string &ownerDisplayName,
    const string &path,
    const string &name,
    const string &token,
    Permissions permissions,
    bool isPasswordSet,
    const QUrl &url,
    const QDate &expireDate,
    const string &note,
    const string &label)
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

string LinkShare.getName () {
    return _name;
}

string LinkShare.getNote () {
    return _note;
}

string LinkShare.getLabel () {
    return _label;
}

void LinkShare.setName (string &name) {
    createShareJob (&LinkShare.slotNameSet).setName (getId (), name);
}

void LinkShare.setNote (string &note) {
    createShareJob (&LinkShare.slotNoteSet).setNote (getId (), note);
}

void LinkShare.slotNoteSet (QJsonDocument &, QVariant &note) {
    _note = note.toString ();
    emit noteSet ();
}

string LinkShare.getToken () {
    return _token;
}

void LinkShare.setExpireDate (QDate &date) {
    createShareJob (&LinkShare.slotExpireDateSet).setExpireDate (getId (), date);
}

void LinkShare.setLabel (string &label) {
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

    /***********************************************************
    If the reply provides a data back (more REST style)
    they use this date.
    ***********************************************************/
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
    const string &id,
    const string &owner,
    const string &ownerDisplayName,
    const string &path,
    const ShareType shareType,
    bool isPasswordSet,
    const Permissions permissions,
    const QSharedPointer<Sharee> shareWith,
    const QDate &expireDate,
    const string &note)
    : Share (account, id, owner, ownerDisplayName, path, shareType, isPasswordSet, permissions, shareWith)
    , _note (note)
    , _expireDate (expireDate) {
    Q_ASSERT (Share.isShareTypeUserGroupEmailRoomOrRemote (shareType));
    Q_ASSERT (shareWith);
}

void UserGroupShare.setNote (string &note) {
    auto *job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, &UserGroupShare.slotNoteSet);
    connect (job, &OcsJob.ocsError, this, &UserGroupShare.noteSetError);
    job.setNote (getId (), note);
}

string UserGroupShare.getNote () {
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

    /***********************************************************
    If the reply provides a data back (more REST style)
    they use this date.
    ***********************************************************/
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

void ShareManager.createLinkShare (string &path,
    const string &name,
    const string &password) {
    auto *job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, &ShareManager.slotLinkShareCreated);
    connect (job, &OcsJob.ocsError, this, &ShareManager.slotOcsError);
    job.createLinkShare (path, name, password);
}

void ShareManager.slotLinkShareCreated (QJsonDocument &reply) {
    string message;
    int code = OcsShareJob.getJsonReturnCode (reply, message);

    /***********************************************************
    Before we had decent sharing capabilities on the server a 403 "generally"
    meant that a share was password protected
    ***********************************************************/
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

void ShareManager.createShare (string &path,
    const Share.ShareType shareType,
    const string shareWith,
    const Share.Permissions desiredPermissions,
    const string &password) {
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

void ShareManager.fetchShares (string &path) {
    auto *job = new OcsShareJob (_account);
    connect (job, &OcsShareJob.shareJobFinished, this, &ShareManager.slotSharesFetched);
    connect (job, &OcsJob.ocsError, this, &ShareManager.slotOcsError);
    job.getShares (path);
}

void ShareManager.slotSharesFetched (QJsonDocument &reply) {
    auto tmpShares = reply.object ().value ("ocs").toObject ().value ("data").toArray ();
    const string versionString = _account.serverVersion ();
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

    string note;
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

    string note;
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

void ShareManager.slotOcsError (int statusCode, string &message) {
    emit serverError (statusCode, message);
}
}
