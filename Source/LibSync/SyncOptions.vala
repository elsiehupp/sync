/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QRegularExpression>

using namespace Occ;

// #pragma once

// #include <QRegularExpression>
// #include <QSharedPointer>
// #include <string>

// #include <chrono>

namespace Occ {

/***********************************************************
Value class containing the options given to the sync engine
***********************************************************/
class SyncOptions {
public:
    SyncOptions ();
    ~SyncOptions ();

    /***********************************************************
    Maximum size (in Bytes) a folder can have without asking for confirmation.
    -1 means infinite */
    int64 _newBigFolderSizeLimit = -1;

    /***********************************************************
    If a confirmation should be asked for external storages */
    bool _confirmExternalStorage = false;

    /***********************************************************
    If remotely deleted files are needed to move to trash */
    bool _moveFilesToTrash = false;

    /***********************************************************
    Create a virtual file for new files instead of downloading. May not be null */
    QSharedPointer<Vfs> _vfs;

    /***********************************************************
    The initial un-adjusted chunk size in bytes for chunked uploads, both
    for old and new chunking algorithm, which classifies the item to be chunked
    
    In chunkingNG, when dynamic chunk size adjustments are d
    starting value and is then gradually adjusted within the
     * minChunkSize / maxChunkSize bounds.
    ***********************************************************/
    int64 _initialChunkSize = 10 * 1000 * 1000; // 10MB

    /***********************************************************
    The minimum chunk size in bytes for chunked uploads */
    int64 _minChunkSize = 1 * 1000 * 1000; // 1MB

    /***********************************************************
    The maximum chunk size in bytes for chunked uploads */
    int64 _maxChunkSize = 1000 * 1000 * 1000; // 1000MB

    /***********************************************************
    The target duration of chunk uploads for dynamic chunk sizing.

    Set to 0 it will disable dynamic chunk sizing.
    ***********************************************************/
    std.chrono.milliseconds _targetChunkUploadDuration = std.chrono.minutes (1);

    /***********************************************************
    The maximum number of active jobs in parallel  */
    int _parallelNetworkJobs = 6;

    /***********************************************************
    Reads settings from env vars where available.

    Currently reads _initialChunkSize, _minChunkSize, _maxChunkSize,
    _targetChunkUploadDuration, _parallelNetworkJobs.
    ***********************************************************/
    void fillFromEnvironmentVariables ();

    /***********************************************************
    Ensure min <= initial <= max

    Previously min/max chunk size values didn't exist, so users might
    have setups where the chunk size exceeds the new min/max default
    values. To cope with this, adjust min/max to always include the
    initial chunk size value.
    ***********************************************************/
    void verifyChunkSizes ();

    /***********************************************************
    A regular expression to match file names
    If no pattern is provided the default is an invalid regular expression.
    ***********************************************************/
    QRegularExpression fileRegex ();

    /***********************************************************
    A pattern like *.txt, matching only file names
    ***********************************************************/
    void setFilePattern (string &pattern);

    /***********************************************************
    A pattern like /own.*\/.*txt matching the full path
    ***********************************************************/
    void setPathPattern (string &pattern);

private:
    /***********************************************************
    Only sync files that mathc the expression
    Invalid pattern by default.
    ***********************************************************/
    QRegularExpression _fileRegex = QRegularExpression (QStringLiteral (" ("));
};

}








SyncOptions.SyncOptions ()
    : _vfs (new VfsOff) {
}

SyncOptions.~SyncOptions () = default;

void SyncOptions.fillFromEnvironmentVariables () {
    QByteArray chunkSizeEnv = qgetenv ("OWNCLOUD_CHUNK_SIZE");
    if (!chunkSizeEnv.isEmpty ())
        _initialChunkSize = chunkSizeEnv.toUInt ();

    QByteArray minChunkSizeEnv = qgetenv ("OWNCLOUD_MIN_CHUNK_SIZE");
    if (!minChunkSizeEnv.isEmpty ())
        _minChunkSize = minChunkSizeEnv.toUInt ();

    QByteArray maxChunkSizeEnv = qgetenv ("OWNCLOUD_MAX_CHUNK_SIZE");
    if (!maxChunkSizeEnv.isEmpty ())
        _maxChunkSize = maxChunkSizeEnv.toUInt ();

    QByteArray targetChunkUploadDurationEnv = qgetenv ("OWNCLOUD_TARGET_CHUNK_UPLOAD_DURATION");
    if (!targetChunkUploadDurationEnv.isEmpty ())
        _targetChunkUploadDuration = std.chrono.milliseconds (targetChunkUploadDurationEnv.toUInt ());

    int maxParallel = qgetenv ("OWNCLOUD_MAX_PARALLEL").toInt ();
    if (maxParallel > 0)
        _parallelNetworkJobs = maxParallel;
}

void SyncOptions.verifyChunkSizes () {
    _minChunkSize = qMin (_minChunkSize, _initialChunkSize);
    _maxChunkSize = qMax (_maxChunkSize, _initialChunkSize);
}

QRegularExpression SyncOptions.fileRegex () {
    return _fileRegex;
}

void SyncOptions.setFilePattern (string &pattern) {
    // full match or a path ending with this pattern
    setPathPattern (QStringLiteral (" (^|/|\\\\)") + pattern + QLatin1Char ('$'));
}

void SyncOptions.setPathPattern (string &pattern) {
    _fileRegex.setPatternOptions (Utility.fsCasePreserving () ? QRegularExpression.CaseInsensitiveOption : QRegularExpression.NoPatternOption);
    _fileRegex.setPattern (pattern);
}
