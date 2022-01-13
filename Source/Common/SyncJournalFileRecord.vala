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

    public bool isValid () {
        return !_path.isEmpty ();
    }

    /***********************************************************
    Returns the numeric part of the full id in _fileId.

    On the server this is sometimes known as the internal file id.
    
    It is used in the construction of private links.
    ***********************************************************/
    public QByteArray numericFileId ();
    public QDateTime modDateTime () { return Utility.qDateTimeFromTime_t (_modtime); }

    public bool isDirectory () { return _type == ItemTypeDirectory; }
    public bool isFile () { return _type == ItemTypeFile || _type == ItemTypeVirtualFileDehydration; }
    public bool isVirtualFile () { return _type == ItemTypeVirtualFile || _type == ItemTypeVirtualFileDownload; }
    public string path () { return string.fromUtf8 (_path); }
    public string e2eMangledName () { return string.fromUtf8 (_e2eMangledName); }

    public QByteArray _path;
    public uint64 _inode = 0;
    public int64 _modtime = 0;
    public ItemType _type = ItemTypeSkip;
    public QByteArray _etag;
    public QByteArray _fileId;
    public int64 _fileSize = 0;
    public RemotePermissions _remotePerm;
    public bool _serverHasIgnoredFiles = false;
    public QByteArray _checksumHeader;
    public QByteArray _e2eMangledName;
    public bool _isE2eEncrypted = false;
};

bool OCSYNC_EXPORT
operator== (SyncJournalFileRecord &lhs,
    const SyncJournalFileRecord &rhs);

class SyncJournalErrorBlacklistRecord {

    public enum Category {
        /// Normal errors have no special behavior
        Normal = 0,
        /// These get a special summary message
        InsufficientRemoteStorage
    };

    /// The number of times the operation was unsuccessful so far.
    public int _retryCount = 0;

    /// The last error string.
    public string _errorString;
    /// The error category. Sometimes used for special actions.
    public Category _errorCategory = Category.Normal;

    public int64 _lastTryModtime = 0;
    public QByteArray _lastTryEtag;

    /// The last time the operation was attempted (in s since epoch).
    public int64 _lastTryTime = 0;

    /// The number of seconds the file shall be ignored.
    public int64 _ignoreDuration = 0;

    public string _file;
    public string _renameTarget;

    /// The last X-Request-ID of the request that failled
    public QByteArray _requestId;

    public bool isValid ();
};

/***********************************************************
Represents a conflict in the conflicts table.

In the following the "conflict file" is the file that has the conflict
tag in the filename, and the base file is the file that it's a conflict for.
So if "a/foo.txt" is the base file, its conflict file could be
"a/foo (conflicted copy 1234).txt".
***********************************************************/
class ConflictRecord {

    /***********************************************************
    Path to the file with the conflict tag in the name

    The path is sync-folder relative.
    ***********************************************************/
    public QByteArray path;

    /// File id of the base file
    public QByteArray baseFileId;

    /***********************************************************
    Modtime of the base file

    may not be available and be -1
    ***********************************************************/
    public int64 baseModtime = -1;

    /***********************************************************
    Etag of the base file

    may not be available and empty
    ***********************************************************/
    public QByteArray baseEtag;

    /***********************************************************
    The path of the original file at the time the conflict was created
    
    Note that in nearly all cases one should query 
    thus retrieve the *current* base path instead!

    maybe be empty if not available
    ***********************************************************/
    public QByteArray initialBasePath;

    public bool isValid () { return !path.isEmpty (); }
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
    