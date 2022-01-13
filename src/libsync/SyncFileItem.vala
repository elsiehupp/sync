/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QVector>
// #include <string>
// #include <QDateTime>
// #include <QMetaType>
// #include <QSharedPointer>

// #include <csync.h>

// #include <owncloudlib.h>

namespace Occ {

using SyncFileItemPtr = QSharedPointer<SyncFileItem>;

/***********************************************************
@brief The SyncFileItem class
@ingroup libsync
***********************************************************/
class SyncFileItem {
    Q_GADGET
public:
    enum Direction {
        None = 0,
        Up,
        Down
    };
    Q_ENUM (Direction)

    enum Status { // stored in 4 bits
        NoStatus,

        FatalError, ///< Error that causes the sync to stop
        NormalError, ///< Error attached to a particular file
        SoftError, ///< More like an information

        Success, ///< The file was properly synced

        /** Marks a conflict, old or new.
         *
         * With instruction:IGNORE : detected an old unresolved old conflict
         * With instruction:CONFLICT : a new conflict this sync run
         */
        Conflict,

        FileIgnored, ///< The file is in the ignored list (or blacklisted with no retries left)
        FileLocked, ///< The file is locked
        Restoration, ///< The file was restored because what should have been done was not allowed

        /***********************************************************
         * The filename is invalid on this platform and could not created.
         */
        FileNameInvalid,

        /** For errors that should only appear in the error view.
         *
         * Some errors also produce a summary message. Usually displaying that message is
         * sufficient, but the individual errors should still appear in the issues tab.
         *
         * These errors do cause the sync to fail.
         *
         * A NormalError that isn't as prominent.
         */
        DetailError,

        /** For files whose errors were blacklisted
         *
         * If an file is blacklisted due to an error it isn't even reattempted. These
         * errors should appear in the issues tab but should be silent otherwise.
         *
         * A SoftError caused by blacklisting.
         */
        BlacklistedError
    };
    Q_ENUM (Status)

    SyncJournalFileRecord toSyncJournalFileRecordWithInode (string &localFileName) const;

    /** Creates a basic SyncFileItem from a DB record
     *
     * This is intended in particular for read-update-write cycles that need
     * to go through a a SyncFileItem, like PollJob.
     */
    static SyncFileItemPtr fromSyncJournalFileRecord (SyncJournalFileRecord &rec);

    SyncFileItem ()
        : _type (ItemTypeSkip)
        , _direction (None)
        , _serverHasIgnoredFiles (false)
        , _hasBlacklistEntry (false)
        , _errorMayBeBlacklisted (false)
        , _status (NoStatus)
        , _isRestoration (false)
        , _isSelectiveSync (false)
        , _isEncrypted (false) {
    }

    friend bool operator== (SyncFileItem &item1, SyncFileItem &item2) {
        return item1._originalFile == item2._originalFile;
    }

    friend bool operator< (SyncFileItem &item1, SyncFileItem &item2) {
        // Sort by destination
        auto d1 = item1.destination ();
        auto d2 = item2.destination ();

        // But this we need to order it so the slash come first. It should be this order:
        //  "foo", "foo/bar", "foo-bar"
        // This is important since we assume that the contents of a folder directly follows
        // its contents

        auto data1 = d1.constData ();
        auto data2 = d2.constData ();

        // Find the length of the largest prefix
        int prefixL = 0;
        auto minSize = std.min (d1.size (), d2.size ());
        while (prefixL < minSize && data1[prefixL] == data2[prefixL]) {
            prefixL++;
        }

        if (prefixL == d2.size ())
            return false;
        if (prefixL == d1.size ())
            return true;

        if (data1[prefixL] == '/')
            return true;
        if (data2[prefixL] == '/')
            return false;

        return data1[prefixL] < data2[prefixL];
    }

    string destination () {
        if (!_renameTarget.isEmpty ()) {
            return _renameTarget;
        }
        return _file;
    }

    bool isEmpty () {
        return _file.isEmpty ();
    }

    bool isDirectory () {
        return _type == ItemTypeDirectory;
    }

    /***********************************************************
     * True if the item had any kind of error.
     */
    bool hasErrorStatus () {
        return _status == SyncFileItem.SoftError
            || _status == SyncFileItem.NormalError
            || _status == SyncFileItem.FatalError
            || !_errorString.isEmpty ();
    }

    /***********************************************************
     * Whether this item should appear on the issues tab.
     */
    bool showInIssuesTab () {
        return hasErrorStatus () || _status == SyncFileItem.Conflict;
    }

    /***********************************************************
     * Whether this item should appear on the protocol tab.
     */
    bool showInProtocolTab () {
        return (!showInIssuesTab () || _status == SyncFileItem.Restoration)
            // Don't show conflicts that were resolved as "not a conflict after all"
            && ! (_instruction == CSYNC_INSTRUCTION_CONFLICT && _status == SyncFileItem.Success);
    }

    // Variables useful for everybody

    /** The syncfolder-relative filesystem path that the operation is about
     *
     * For rename operation this is the rename source and the target is in _renameTarget.
     */
    string _file;

    /** for renames : the name _file should be renamed to
     * for dehydrations : the name _file should become after dehydration (like adding a suffix)
     * otherwise empty. Use destination () to find the sync target.
     */
    string _renameTarget;

    /** The db-path of this item.
     *
     * This can easily differ from _file and _renameTarget if parts of the path were renamed.
     */
    string _originalFile;

    /// Whether there's end to end encryption on this file.
    /// If the file is encrypted, the _encryptedFilename is
    /// the encrypted name on the server.
    string _encryptedFileName;

    ItemType _type BITFIELD (3);
    Direction _direction BITFIELD (3);
    bool _serverHasIgnoredFiles BITFIELD (1);

    /// Whether there's an entry in the blacklist table.
    /// Note : that entry may have retries left, so this can be true
    /// without the status being FileIgnored.
    bool _hasBlacklistEntry BITFIELD (1);

    /** If true and NormalError, this error may be blacklisted
     *
     * Note that non-local errors (httpErrorCode!=0) may also be
     * blacklisted independently of this flag.
     */
    bool _errorMayBeBlacklisted BITFIELD (1);

    // Variables useful to report to the user
    Status _status BITFIELD (4);
    bool _isRestoration BITFIELD (1); // The original operation was forbidden, and this is a restoration
    bool _isSelectiveSync BITFIELD (1); // The file is removed or ignored because it is in the selective sync list
    bool _isEncrypted BITFIELD (1); // The file is E2EE or the content of the directory should be E2EE
    uint16 _httpErrorCode = 0;
    RemotePermissions _remotePerm;
    string _errorString; // Contains a string only in case of error
    QByteArray _responseTimeStamp;
    QByteArray _requestId; // X-Request-Id of the failed request
    uint32 _affectedItems = 1; // the number of affected items by the operation on this item.
    // usually this value is 1, but for removes on dirs, it might be much higher.

    // Variables used by the propagator
    SyncInstructions _instruction = CSYNC_INSTRUCTION_NONE;
    time_t _modtime = 0;
    QByteArray _etag;
    int64 _size = 0;
    uint64 _inode = 0;
    QByteArray _fileId;

    // This is the value for the 'new' side, matching with _size and _modtime.
    //
    // When is this set, and is it the local or the remote checksum?
    // - if mtime or size changed locally for *.eml files (local checksum)
    // - for potential renames of local files (local checksum)
    // - for conflicts (remote checksum)
    QByteArray _checksumHeader;

    // The size and modtime of the file getting overwritten (on the disk for downloads, on the server for uploads).
    int64 _previousSize = 0;
    time_t _previousModtime = 0;

    string _directDownloadUrl;
    string _directDownloadCookies;
};

inline bool operator< (SyncFileItemPtr &item1, SyncFileItemPtr &item2) {
    return *item1 < *item2;
}

using SyncFileItemVector = QVector<SyncFileItemPtr>;
}

Q_DECLARE_METATYPE (Occ.SyncFileItem)
Q_DECLARE_METATYPE (Occ.SyncFileItemPtr)








/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>

namespace Occ {

    Q_LOGGING_CATEGORY (lcFileItem, "nextcloud.sync.fileitem", QtInfoMsg)
    
    SyncJournalFileRecord SyncFileItem.toSyncJournalFileRecordWithInode (string &localFileName) {
        SyncJournalFileRecord rec;
        rec._path = destination ().toUtf8 ();
        rec._modtime = _modtime;
    
        // Some types should never be written to the database when propagation completes
        rec._type = _type;
        if (rec._type == ItemTypeVirtualFileDownload)
            rec._type = ItemTypeFile;
        if (rec._type == ItemTypeVirtualFileDehydration)
            rec._type = ItemTypeVirtualFile;
    
        rec._etag = _etag;
        rec._fileId = _fileId;
        rec._fileSize = _size;
        rec._remotePerm = _remotePerm;
        rec._serverHasIgnoredFiles = _serverHasIgnoredFiles;
        rec._checksumHeader = _checksumHeader;
        rec._e2eMangledName = _encryptedFileName.toUtf8 ();
        rec._isE2eEncrypted = _isEncrypted;
    
        // Update the inode if possible
        rec._inode = _inode;
        if (FileSystem.getInode (localFileName, &rec._inode)) {
            qCDebug (lcFileItem) << localFileName << "Retrieved inode " << rec._inode << " (previous item inode : " << _inode << ")";
        } else {
            // use the "old" inode coming with the item for the case where the
            // filesystem stat fails. That can happen if the the file was removed
            // or renamed meanwhile. For the rename case we still need the inode to
            // detect the rename though.
            qCWarning (lcFileItem) << "Failed to query the 'inode' for file " << localFileName;
        }
        return rec;
    }
    
    SyncFileItemPtr SyncFileItem.fromSyncJournalFileRecord (SyncJournalFileRecord &rec) {
        auto item = SyncFileItemPtr.create ();
        item._file = rec.path ();
        item._inode = rec._inode;
        item._modtime = rec._modtime;
        item._type = rec._type;
        item._etag = rec._etag;
        item._fileId = rec._fileId;
        item._size = rec._fileSize;
        item._remotePerm = rec._remotePerm;
        item._serverHasIgnoredFiles = rec._serverHasIgnoredFiles;
        item._checksumHeader = rec._checksumHeader;
        item._encryptedFileName = rec.e2eMangledName ();
        item._isEncrypted = rec._isE2eEncrypted;
        return item;
    }
    
    }
    