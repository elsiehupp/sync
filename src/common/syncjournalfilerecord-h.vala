/*
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

This library is free software; you can redistribute it and
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later versi

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GN
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*/

// #include <QString>
// #include <QDateTime>

namespace Occ {


/**
@brief The SyncJournalFileRecord class
@ingroup libsync
*/
class SyncJournalFileRecord {
public:
    bool isValid () {
        return !_path.isEmpty ();
    }

    /** Returns the numeric part of the full id in _fileId.
     *
     * On the server this is sometimes known as the internal file id.
     *
     * It is used in the construction of private links.
     */
    QByteArray numericFileId ();
    QDateTime modDateTime () { return Utility.qDateTimeFromTime_t (_modtime); }

    bool isDirectory () { return _type == ItemTypeDirectory; }
    bool isFile () { return _type == ItemTypeFile || _type == ItemTypeVirtualFileDehydration; }
    bool isVirtualFile () { return _type == ItemTypeVirtualFile || _type == ItemTypeVirtualFileDownload; }
    QString path () { return QString.fromUtf8 (_path); }
    QString e2eMangledName () { return QString.fromUtf8 (_e2eMangledName); }

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
    QString _errorString;
    /// The error category. Sometimes used for special actions.
    Category _errorCategory = Category.Normal;

    int64 _lastTryModtime = 0;
    QByteArray _lastTryEtag;

    /// The last time the operation was attempted (in s since epoch).
    int64 _lastTryTime = 0;

    /// The number of seconds the file shall be ignored.
    int64 _ignoreDuration = 0;

    QString _file;
    QString _renameTarget;

    /// The last X-Request-ID of the request that failled
    QByteArray _requestId;

    bool isValid ();
};

/** Represents a conflict in the conflicts table.

In the following the "conflict file" is the file that has the conflict
tag in the filename, and the base file is the file that it's a conflict for.
So if "a/foo.txt" is the base file, its conflict file could be
"a/foo (conflicted copy 1234).txt".
*/
class ConflictRecord {
public:
    /** Path to the file with the conflict tag in the name
     *
     * The path is sync-folder relative.
     */
    QByteArray path;

    /// File id of the base file
    QByteArray baseFileId;

    /** Modtime of the base file
     *
     * may not be available and be -1
     */
    int64 baseModtime = -1;

    /** Etag of the base file
     *
     * may not be available and empty
     */
    QByteArray baseEtag;

    /**
     * The path of the original file at the time the conflict was created
     *
     * Note that in nearly all cases one should query the db by baseFileId and
     * thus retrieve the *current* base path instead!
     *
     * maybe be empty if not available
     */
    QByteArray initialBasePath;

    bool isValid () { return !path.isEmpty (); }
};
}
