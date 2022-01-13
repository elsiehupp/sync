/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <string>
// #include <QDateTime>

namespace Occ {


/***********************************************************
@brief The SyncJournalFileRecord class
@ingroup libsync
***********************************************************/
class SyncJournalFileRecord {
public:
    bool isValid () {
        return !_path.isEmpty ();
    }

    /***********************************************************
    Returns the numeric part of the full id in _fileId.

    On the server this is sometimes known as the internal file id.
    
     * It is used in the construction of private links.
    ***********************************************************/
    QByteArray numericFileId ();
    QDateTime modDateTime () { return Utility.qDateTimeFromTime_t (_modtime); }

    bool isDirectory () { return _type == ItemTypeDirectory; }
    bool isFile () { return _type == ItemTypeFile || _type == ItemTypeVirtualFileDehydration; }
    bool isVirtualFile () { return _type == ItemTypeVirtualFile || _type == ItemTypeVirtualFileDownload; }
    string path () { return string.fromUtf8 (_path); }
    string e2eMangledName () { return string.fromUtf8 (_e2eMangledName); }

    QByteArray _path;
    uint64 _inode = 0;
    int64 _modtime = 0;
    ItemType _type = ItemTypeSkip;
    QByteArray _etag;
    QByteArray _fileId;
    int64 _fileSize = 0;
    RemotePermissions _remotePerm;
    bool _serverHasIgnoredFiles = false;
    QByteArray _checksumHeader;
    QByteArray _e2eMangledName;
    bool _isE2eEncrypted = false;
};

bool OCSYNC_EXPORT
operator== (SyncJournalFileRecord &lhs,
    const SyncJournalFileRecord &rhs);

class SyncJournalErrorBlacklistRecord {
public:
    enum Category {
        /// Normal errors have no special behavior
        Normal = 0,
        /// These get a special summary message
        InsufficientRemoteStorage
    };

    /// The number of times the operation was unsuccessful so far.
    int _retryCount = 0;

    /// The last error string.
    string _errorString;
    /// The error category. Sometimes used for special actions.
    Category _errorCategory = Category.Normal;

    int64 _lastTryModtime = 0;
    QByteArray _lastTryEtag;

    /// The last time the operation was attempted (in s since epoch).
    int64 _lastTryTime = 0;

    /// The number of seconds the file shall be ignored.
    int64 _ignoreDuration = 0;

    string _file;
    string _renameTarget;

    /// The last X-Request-ID of the request that failled
    QByteArray _requestId;

    bool isValid ();
};

/***********************************************************
Represents a conflict in the conflicts table.

In the following the "conflict file" is the file that has the conflict
tag in the filename, and the base file is the file that it's a conflict for.
So if "a/foo.txt" is the base file, its conflict file could be
"a/foo (conflicted copy 1234).txt".
***********************************************************/
class ConflictRecord {
public:
    /***********************************************************
    Path to the file with the conflict tag in the name

    The path is sync-folder relative.
    ***********************************************************/
    QByteArray path;

    /// File id of the base file
    QByteArray baseFileId;

    /***********************************************************
    Modtime of the base file

    may not be available and be -1
    ***********************************************************/
    int64 baseModtime = -1;

    /***********************************************************
    Etag of the base file

    may not be available and empty
    ***********************************************************/
    QByteArray baseEtag;

    /***********************************************************
    The path of the original file at the time the conflict was created
    
    Note that in nearly all cases one should query 
    thus retrieve the *current* base path instead!

     * maybe be empty if not available
    ***********************************************************/
    QByteArray initialBasePath;

    bool isValid () { return !path.isEmpty (); }
};


    QByteArray SyncJournalFileRecord.numericFileId () {
        // Use the id up until the first non-numeric character
        for (int i = 0; i < _fileId.size (); ++i) {
            if (_fileId[i] < '0' || _fileId[i] > '9') {
                return _fileId.left (i);
            }
        }
        return _fileId;
    }
    
    bool SyncJournalErrorBlacklistRecord.isValid () {
        return !_file.isEmpty ()
            && (!_lastTryEtag.isEmpty () || _lastTryModtime != 0)
            && _lastTryTime > 0;
    }
    
    bool operator== (SyncJournalFileRecord &lhs,
        const SyncJournalFileRecord &rhs) {
        return lhs._path == rhs._path
            && lhs._inode == rhs._inode
            && lhs._modtime == rhs._modtime
            && lhs._type == rhs._type
            && lhs._etag == rhs._etag
            && lhs._fileId == rhs._fileId
            && lhs._fileSize == rhs._fileSize
            && lhs._remotePerm == rhs._remotePerm
            && lhs._serverHasIgnoredFiles == rhs._serverHasIgnoredFiles
            && lhs._checksumHeader == rhs._checksumHeader;
    }
    }
    