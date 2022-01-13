/***********************************************************
Copyright (C) by Roeland Jago Douma <roeland@famdouma.nl>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QVariantMap>
// #include <QLoggingCategory>
// #include <QUrl>

// #include <QDebug>

// #include <QVariantMap>
// #include <QStringList>
// #include <QMimeDatabase>

namespace Occ {


enum PushNotificationType {
    None = 0,
    Files = 1,
    Activities = 2,
    Notifications = 4
};
Q_DECLARE_FLAGS (PushNotificationTypes, PushNotificationType)
Q_DECLARE_OPERATORS_FOR_FLAGS (PushNotificationTypes)

/***********************************************************
@brief The Capabilities class represents the capabilities of an ownCloud
server
@ingroup libsync
***********************************************************/
class Capabilities {
public:
    Capabilities (QVariantMap &capabilities);

    bool shareAPI ();
    bool shareEmailPasswordEnabled ();
    bool shareEmailPasswordEnforced ();
    bool sharePublicLink ();
    bool sharePublicLinkAllowUpload ();
    bool sharePublicLinkSupportsUploadOnly ();
    bool sharePublicLinkAskOptionalPassword ();
    bool sharePublicLinkEnforcePassword ();
    bool sharePublicLinkEnforceExpireDate ();
    int sharePublicLinkExpireDateDays ();
    bool shareInternalEnforceExpireDate ();
    int shareInternalExpireDateDays ();
    bool shareRemoteEnforceExpireDate ();
    int shareRemoteExpireDateDays ();
    bool sharePublicLinkMultiple ();
    bool shareResharing ();
    int shareDefaultPermissions ();
    bool chunkingNg ();
    bool bulkUpload ();
    bool userStatus ();
    bool userStatusSupportsEmoji ();

    /// Returns which kind of push notfications are available
    PushNotificationTypes availablePushNotifications ();

    /// Websocket url for files push notifications if available
    QUrl pushNotificationsWebSocketUrl ();

    /// disable parallel upload in chunking
    bool chunkingParallelUploadDisabled ();

    /// Whether the "privatelink" DAV property is available
    bool privateLinkPropertyAvailable ();

    /// returns true if the capabilities report notifications
    bool notificationsAvailable ();

    /// returns true if the server supports client side encryption
    bool clientSideEncryptionAvailable ();

    /// returns true if the capabilities are loaded already.
    bool isValid ();

    /// return true if the activity app is enabled
    bool hasActivities ();

    /***********************************************************
    Returns the checksum types the server understands.
    
    When the client uses one of these checksumming algorithms in
    the OC-Checksum header of a file upload, the server 
    it to validate that data was tr
    
    Path : checksums/supportedTypes
    Default : []
    Possible entries : "Adler32", "MD5", "SHA1"
    ***********************************************************/
    QList<QByteArray> supportedChecksumTypes ();

    /***********************************************************
    The checksum algorithm that the server recommends for file uploads.
    This is just a preference, any algorithm listed in supportedTypes may be used.
    
    Path : checksums/preferredUploadType
    Default : empty, meaning "no preference"
    Possible values : empty or any of the supportedTypes
    ***********************************************************/
    QByteArray preferredUploadChecksumType ();

    /***********************************************************
    Helper that returns the preferredUploadChecksumType () if set, or one
    of the supportedChecksumTypes () if it isn't. May return an empty
    QByteArray if no checksum types are supported.
    ***********************************************************/
    QByteArray uploadChecksumType ();

    /***********************************************************
    List of HTTP error codes should be guaranteed to eventually reset
    failing chunked uploads.
    
    The resetting works by tracking UploadInfo.errorCount.
    
    Note that other error codes than the ones listed here may reset the
    upload as well.
    
    Motivation : See #5344. They should always be reset on 
    checksum err
    unusual error codes such as 503.

    Path : dav/httpErrorCodesThatResetFailingChunkedUploads
    Default : []
    Example : [503, 500]
    ***********************************************************/
    QList<int> httpErrorCodesThatResetFailingChunkedUploads ();

    /***********************************************************
    Regex that, if contained in a filename, will result in it not being uploaded.
    
    For servers older than 8.1.0 it defaults to [\\:?*"<>|]
    For servers >= that version, it defaults to the empty rege
    will indicate invalid characters through an upload error)

    Note that it just needs to be contained. The regex [ab] is contained in "car".
    ***********************************************************/
    string invalidFilenameRegex ();

    /***********************************************************
    return the list of filename that should not be uploaded
    ***********************************************************/
    QStringList blacklistedFiles ();

    /***********************************************************
    Whether conflict files should remain local (default) or should be uploaded.
    ***********************************************************/
    bool uploadConflictFiles ();

    // Direct Editing
    void addDirectEditor (DirectEditor* directEditor);
    DirectEditor* getDirectEditorForMimetype (QMimeType &mimeType);
    DirectEditor* getDirectEditorForOptionalMimetype (QMimeType &mimeType);

private:
    QVariantMap _capabilities;

    QList<DirectEditor> _directEditors;
};

/*-------------------------------------------------------------------------------------*/

class DirectEditor : GLib.Object {
public:
    DirectEditor (string &id, string &name, GLib.Object* parent = nullptr);

    void addMimetype (QByteArray &mimeType);
    void addOptionalMimetype (QByteArray &mimeType);

    bool hasMimetype (QMimeType &mimeType);
    bool hasOptionalMimetype (QMimeType &mimeType);

    string id ();
    string name ();

    QList<QByteArray> mimeTypes ();
    QList<QByteArray> optionalMimeTypes ();

private:
    string _id;
    string _name;

    QList<QByteArray> _mimeTypes;
    QList<QByteArray> _optionalMimeTypes;
};

    Capabilities.Capabilities (QVariantMap &capabilities)
        : _capabilities (capabilities) {
    }
    
    bool Capabilities.shareAPI () {
        if (_capabilities["files_sharing"].toMap ().contains ("api_enabled")) {
            return _capabilities["files_sharing"].toMap ()["api_enabled"].toBool ();
        } else {
            // This was later added so if it is not present just assume the API is enabled.
            return true;
        }
    }
    
    bool Capabilities.shareEmailPasswordEnabled () {
        return _capabilities["files_sharing"].toMap ()["sharebymail"].toMap ()["password"].toMap ()["enabled"].toBool ();
    }
    
    bool Capabilities.shareEmailPasswordEnforced () {
        return _capabilities["files_sharing"].toMap ()["sharebymail"].toMap ()["password"].toMap ()["enforced"].toBool ();
    }
    
    bool Capabilities.sharePublicLink () {
        if (_capabilities["files_sharing"].toMap ().contains ("public")) {
            return shareAPI () && _capabilities["files_sharing"].toMap ()["public"].toMap ()["enabled"].toBool ();
        } else {
            // This was later added so if it is not present just assume that link sharing is enabled.
            return true;
        }
    }
    
    bool Capabilities.sharePublicLinkAllowUpload () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["upload"].toBool ();
    }
    
    bool Capabilities.sharePublicLinkSupportsUploadOnly () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["supports_upload_only"].toBool ();
    }
    
    bool Capabilities.sharePublicLinkAskOptionalPassword () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["password"].toMap ()["askForOptionalPassword"].toBool ();
    }
    
    bool Capabilities.sharePublicLinkEnforcePassword () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["password"].toMap ()["enforced"].toBool ();
    }
    
    bool Capabilities.sharePublicLinkEnforceExpireDate () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["expire_date"].toMap ()["enforced"].toBool ();
    }
    
    int Capabilities.sharePublicLinkExpireDateDays () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["expire_date"].toMap ()["days"].toInt ();
    }
    
    bool Capabilities.shareInternalEnforceExpireDate () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["expire_date_internal"].toMap ()["enforced"].toBool ();
    }
    
    int Capabilities.shareInternalExpireDateDays () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["expire_date_internal"].toMap ()["days"].toInt ();
    }
    
    bool Capabilities.shareRemoteEnforceExpireDate () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["expire_date_remote"].toMap ()["enforced"].toBool ();
    }
    
    int Capabilities.shareRemoteExpireDateDays () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["expire_date_remote"].toMap ()["days"].toInt ();
    }
    
    bool Capabilities.sharePublicLinkMultiple () {
        return _capabilities["files_sharing"].toMap ()["public"].toMap ()["multiple"].toBool ();
    }
    
    bool Capabilities.shareResharing () {
        return _capabilities["files_sharing"].toMap ()["resharing"].toBool ();
    }
    
    int Capabilities.shareDefaultPermissions () {
        if (_capabilities["files_sharing"].toMap ().contains ("default_permissions")) {
            return _capabilities["files_sharing"].toMap ()["default_permissions"].toInt ();
        }
    
        return {};
    }
    
    bool Capabilities.clientSideEncryptionAvailable () {
        auto it = _capabilities.constFind (QStringLiteral ("end-to-end-encryption"));
        if (it == _capabilities.constEnd ()) {
            return false;
        }
    
        const auto properties = (*it).toMap ();
        const auto enabled = properties.value (QStringLiteral ("enabled"), false).toBool ();
        if (!enabled) {
            return false;
        }
    
        const auto version = properties.value (QStringLiteral ("api-version"), "1.0").toByteArray ();
        qCInfo (lcServerCapabilities) << "E2EE API version:" << version;
        const auto splittedVersion = version.split ('.');
    
        bool ok = false;
        const auto major = !splittedVersion.isEmpty () ? splittedVersion.at (0).toInt (&ok) : 0;
        if (!ok) {
            qCWarning (lcServerCapabilities) << "Didn't understand version scheme (major), E2EE disabled";
            return false;
        }
    
        ok = false;
        const auto minor = splittedVersion.size () > 1 ? splittedVersion.at (1).toInt (&ok) : 0;
        if (!ok) {
            qCWarning (lcServerCapabilities) << "Didn't understand version scheme (minor), E2EE disabled";
            return false;
        }
    
        return major == 1 && minor >= 1;
    }
    
    bool Capabilities.notificationsAvailable () {
        // We require the OCS style API in 9.x, can't deal with the REST one only found in 8.2
        return _capabilities.contains ("notifications") && _capabilities["notifications"].toMap ().contains ("ocs-endpoints");
    }
    
    bool Capabilities.isValid () {
        return !_capabilities.isEmpty ();
    }
    
    bool Capabilities.hasActivities () {
        return _capabilities.contains ("activity");
    }
    
    QList<QByteArray> Capabilities.supportedChecksumTypes () {
        QList<QByteArray> list;
        foreach (auto &t, _capabilities["checksums"].toMap ()["supportedTypes"].toList ()) {
            list.push_back (t.toByteArray ());
        }
        return list;
    }
    
    QByteArray Capabilities.preferredUploadChecksumType () {
        return qEnvironmentVariable ("OWNCLOUD_CONTENT_CHECKSUM_TYPE",
                                    _capabilities.value (QStringLiteral ("checksums")).toMap ()
                                    .value (QStringLiteral ("preferredUploadType"), QStringLiteral ("SHA1")).toString ()).toUtf8 ();
    }
    
    QByteArray Capabilities.uploadChecksumType () {
        QByteArray preferred = preferredUploadChecksumType ();
        if (!preferred.isEmpty ())
            return preferred;
        QList<QByteArray> supported = supportedChecksumTypes ();
        if (!supported.isEmpty ())
            return supported.first ();
        return QByteArray ();
    }
    
    bool Capabilities.chunkingNg () {
        static const auto chunkng = qgetenv ("OWNCLOUD_CHUNKING_NG");
        if (chunkng == "0")
            return false;
        if (chunkng == "1")
            return true;
        return _capabilities["dav"].toMap ()["chunking"].toByteArray () >= "1.0";
    }
    
    bool Capabilities.bulkUpload () {
        return _capabilities["dav"].toMap ()["bulkupload"].toByteArray () >= "1.0";
    }
    
    bool Capabilities.userStatus () {
        if (!_capabilities.contains ("user_status")) {
            return false;
        }
        const auto userStatusMap = _capabilities["user_status"].toMap ();
        return userStatusMap.value ("enabled", false).toBool ();
    }
    
    bool Capabilities.userStatusSupportsEmoji () {
        if (!userStatus ()) {
            return false;
        }
        const auto userStatusMap = _capabilities["user_status"].toMap ();
        return userStatusMap.value ("supports_emoji", false).toBool ();
    }
    
    PushNotificationTypes Capabilities.availablePushNotifications () {
        if (!_capabilities.contains ("notify_push")) {
            return PushNotificationType.None;
        }
    
        const auto types = _capabilities["notify_push"].toMap ()["type"].toStringList ();
        PushNotificationTypes pushNotificationTypes;
    
        if (types.contains ("files")) {
            pushNotificationTypes.setFlag (PushNotificationType.Files);
        }
    
        if (types.contains ("activities")) {
            pushNotificationTypes.setFlag (PushNotificationType.Activities);
        }
    
        if (types.contains ("notifications")) {
            pushNotificationTypes.setFlag (PushNotificationType.Notifications);
        }
    
        return pushNotificationTypes;
    }
    
    QUrl Capabilities.pushNotificationsWebSocketUrl () {
        const auto websocket = _capabilities["notify_push"].toMap ()["endpoints"].toMap ()["websocket"].toString ();
        return QUrl (websocket);
    }
    
    bool Capabilities.chunkingParallelUploadDisabled () {
        return _capabilities["dav"].toMap ()["chunkingParallelUploadDisabled"].toBool ();
    }
    
    bool Capabilities.privateLinkPropertyAvailable () {
        return _capabilities["files"].toMap ()["privateLinks"].toBool ();
    }
    
    QList<int> Capabilities.httpErrorCodesThatResetFailingChunkedUploads () {
        QList<int> list;
        foreach (auto &t, _capabilities["dav"].toMap ()["httpErrorCodesThatResetFailingChunkedUploads"].toList ()) {
            list.push_back (t.toInt ());
        }
        return list;
    }
    
    string Capabilities.invalidFilenameRegex () {
        return _capabilities[QStringLiteral ("dav")].toMap ()[QStringLiteral ("invalidFilenameRegex")].toString ();
    }
    
    bool Capabilities.uploadConflictFiles () {
        static auto envIsSet = !qEnvironmentVariableIsEmpty ("OWNCLOUD_UPLOAD_CONFLICT_FILES");
        static int envValue = qEnvironmentVariableIntValue ("OWNCLOUD_UPLOAD_CONFLICT_FILES");
        if (envIsSet)
            return envValue != 0;
    
        return _capabilities[QStringLiteral ("uploadConflictFiles")].toBool ();
    }
    
    QStringList Capabilities.blacklistedFiles () {
        return _capabilities["files"].toMap ()["blacklisted_files"].toStringList ();
    }
    
    /*-------------------------------------------------------------------------------------*/
    
    // Direct Editing
    void Capabilities.addDirectEditor (DirectEditor* directEditor) {
        if (directEditor)
            _directEditors.append (directEditor);
    }
    
    DirectEditor* Capabilities.getDirectEditorForMimetype (QMimeType &mimeType) {
        foreach (DirectEditor* editor, _directEditors) {
            if (editor.hasMimetype (mimeType))
                return editor;
        }
    
        return nullptr;
    }
    
    DirectEditor* Capabilities.getDirectEditorForOptionalMimetype (QMimeType &mimeType) {
        foreach (DirectEditor* editor, _directEditors) {
            if (editor.hasOptionalMimetype (mimeType))
                return editor;
        }
    
        return nullptr;
    }
    
    /*-------------------------------------------------------------------------------------*/
    
    DirectEditor.DirectEditor (string &id, string &name, GLib.Object* parent)
        : GLib.Object (parent)
        , _id (id)
        , _name (name) {
    }
    
    string DirectEditor.id () {
        return _id;
    }
    
    string DirectEditor.name () {
        return _name;
    }
    
    void DirectEditor.addMimetype (QByteArray &mimeType) {
        _mimeTypes.append (mimeType);
    }
    
    void DirectEditor.addOptionalMimetype (QByteArray &mimeType) {
        _optionalMimeTypes.append (mimeType);
    }
    
    QList<QByteArray> DirectEditor.mimeTypes () {
        return _mimeTypes;
    }
    
    QList<QByteArray> DirectEditor.optionalMimeTypes () {
        return _optionalMimeTypes;
    }
    
    bool DirectEditor.hasMimetype (QMimeType &mimeType) {
        return _mimeTypes.contains (mimeType.name ().toLatin1 ());
    }
    
    bool DirectEditor.hasOptionalMimetype (QMimeType &mimeType) {
        return _optionalMimeTypes.contains (mimeType.name ().toLatin1 ());
    }
    
    /*-------------------------------------------------------------------------------------*/
    
    }
    