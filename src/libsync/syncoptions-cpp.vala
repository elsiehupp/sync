/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QRegularExpression>

using namespace Occ;

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
