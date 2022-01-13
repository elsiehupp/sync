/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QNetworkAccessManager>
// #include <QFileInfo>
// #include <QDir>
// #include <QJsonDocument>
// #include <QJsonObject>
// #include <QFileInfo>

// #include <cmath>
// #include <cstring>
// #pragma once

// #include <QBuffer>
// #include <QFile>
// #include <QElapsedTimer>

namespace Occ {

Q_DECLARE_LOGGING_CATEGORY (lcPutJob)
Q_DECLARE_LOGGING_CATEGORY (lcPropagateUpload)
Q_DECLARE_LOGGING_CATEGORY (lcPropagateUploadV1)
Q_DECLARE_LOGGING_CATEGORY (lcPropagateUploadNG)


/***********************************************************
@brief The UploadDevice class
@ingroup libsync
***********************************************************/
class UploadDevice : QIODevice {
public:
    UploadDevice (string &fileName, int64 start, int64 size, BandwidthManager *bwm);
    ~UploadDevice () override;

    bool open (QIODevice.OpenMode mode) override;
    void close () override;

    int64 writeData (char *, int64) override;
    int64 readData (char *data, int64 maxlen) override;
    bool atEnd () const override;
    int64 size () const override;
    int64 bytesAvailable () const override;
    bool isSequential () const override;
    bool seek (int64 pos) override;

    void setBandwidthLimited (bool);
    bool isBandwidthLimited () { return _bandwidthLimited; }
    void setChoked (bool);
    bool isChoked () { return _choked; }
    void giveBandwidthQuota (int64 bwq);

signals:

private:
    /// The local file to read data from
    QFile _file;

    /// Start of the file data to use
    int64 _start = 0;
    /// Amount of file data after _start to use
    int64 _size = 0;
    /// Position between _start and _start+_size
    int64 _read = 0;

    // Bandwidth manager related
    QPointer<BandwidthManager> _bandwidthManager;
    int64 _bandwidthQuota = 0;
    int64 _readWithProgress = 0;
    bool _bandwidthLimited = false; // if _bandwidthQuota will be used
    bool _choked = false; // if upload is paused (readData () will return 0)
    friend class BandwidthManager;
public slots:
    void slotJobUploadProgress (int64 sent, int64 t);
};

/***********************************************************
@brief The PUTFileJob class
@ingroup libsync
***********************************************************/
class PUTFileJob : AbstractNetworkJob {

private:
    QIODevice *_device;
    QMap<QByteArray, QByteArray> _headers;
    string _errorString;
    QUrl _url;
    QElapsedTimer _requestTimer;

public:
    // Takes ownership of the device
    PUTFileJob (AccountPtr account, string &path, std.unique_ptr<QIODevice> device,
        const QMap<QByteArray, QByteArray> &headers, int chunk, GLib.Object *parent = nullptr)
        : AbstractNetworkJob (account, path, parent)
        , _device (device.release ())
        , _headers (headers)
        , _chunk (chunk) {
        _device.setParent (this);
    }
    PUTFileJob (AccountPtr account, QUrl &url, std.unique_ptr<QIODevice> device,
        const QMap<QByteArray, QByteArray> &headers, int chunk, GLib.Object *parent = nullptr)
        : AbstractNetworkJob (account, string (), parent)
        , _device (device.release ())
        , _headers (headers)
        , _url (url)
        , _chunk (chunk) {
        _device.setParent (this);
    }
    ~PUTFileJob () override;

    int _chunk;

    void start () override;

    bool finished () override;

    QIODevice *device () {
        return _device;
    }

    string errorString () const override {
        return _errorString.isEmpty () ? AbstractNetworkJob.errorString () : _errorString;
    }

    std.chrono.milliseconds msSinceStart () {
        return std.chrono.milliseconds (_requestTimer.elapsed ());
    }

signals:
    void finishedSignal ();
    void uploadProgress (int64, int64);

};

/***********************************************************
@brief This job implements the asynchronous PUT

If the server replies
replies with an etag.
@ingroup libsync
***********************************************************/
class PollJob : AbstractNetworkJob {
    SyncJournalDb *_journal;
    string _localPath;

public:
    SyncFileItemPtr _item;
    // Takes ownership of the device
    PollJob (AccountPtr account, string &path, SyncFileItemPtr &item,
        SyncJournalDb *journal, string &localPath, GLib.Object *parent)
        : AbstractNetworkJob (account, path, parent)
        , _journal (journal)
        , _localPath (localPath)
        , _item (item) {
    }

    void start () override;
    bool finished () override;

signals:
    void finishedSignal ();
};


/***********************************************************
@brief The PropagateUploadFileCommon class is the code common between all chunking algorithms
@ingroup libsync

State Machine:

  +--. start ()  -. (delete job) -------+
  |
  +-. slotComputeCo
                  |

   slotCo
        |
        v
   slotStartUpload ()  . doStartUp
                                 .
                                 .
                                 v
       finalize () or abortWithError ()  or startPollJob ()
***********************************************************/
class PropagateUploadFileCommon : PropagateItemJob {

    struct UploadStatus {
        SyncFileItem.Status status = SyncFileItem.NoStatus;
        string message;
    };

protected:
    QVector<AbstractNetworkJob> _jobs; /// network jobs that are currently in transit
    bool _finished BITFIELD (1); /// Tells that all the jobs have been finished
    bool _deleteExisting BITFIELD (1);

    /***********************************************************
    Whether an abort is currently ongoing.

    Important to avoid duplicate aborts since each finishing PUTFileJob might
    trigger an abort on error.
    ***********************************************************/
    bool _aborting BITFIELD (1);

    /* This is a minified version of the SyncFileItem,
    that holds only the specifics about the file that's
    being uploaded.
    
    This is needed if we wanna apply changes on the file
     * that's being uploaded while keeping the original on disk.
    ***********************************************************/
    struct UploadFileInfo {
      string _file; /// I'm still unsure if I should use a SyncFilePtr here.
      string _path; /// the full path on disk.
      int64 _size;
    };
    UploadFileInfo _fileToUpload;
    QByteArray _transmissionChecksumHeader;

public:
    PropagateUploadFileCommon (OwncloudPropagator *propagator, SyncFileItemPtr &item);

    /***********************************************************
    Whether an existing entity with the same name may be deleted before
    the upload.
    
     * Default : false.
    ***********************************************************/
    void setDeleteExisting (bool enabled);

    /* start should setup the file, path and size that will be send to the server */
    void start () override;
    void setupEncryptedFile (string& path, string& filename, uint64 size);
    void setupUnencryptedFile ();
    void startUploadFile ();
    void callUnlockFolder ();
    bool isLikelyFinishedQuickly () override { return _item._size < propagator ().smallFileSize (); }

private slots:
    void slotComputeContentChecksum ();
    // Content checksum computed, compute the transmission checksum
    void slotComputeTransmissionChecksum (QByteArray &contentChecksumType, QByteArray &contentChecksum);
    // transmission checksum computed, prepare the upload
    void slotStartUpload (QByteArray &transmissionChecksumType, QByteArray &transmissionChecksum);
    // invoked when encrypted folder lock has been released
    void slotFolderUnlocked (QByteArray &folderId, int httpReturnCode);
    // invoked on internal error to unlock a folder and faile
    void slotOnErrorStartFolderUnlock (SyncFileItem.Status status, string &errorString);

public:
    virtual void doStartUpload () = 0;

    void startPollJob (string &path);
    void finalize ();
    void abortWithError (SyncFileItem.Status status, string &error);

public slots:
    void slotJobDestroyed (GLib.Object *job);

private slots:
    void slotPollFinished ();

protected:
    void done (SyncFileItem.Status status, string &errorString = string ()) override;

    /***********************************************************
    Aborts all running network jobs, except for the ones that mayAbortJob
    returns false on and, for async aborts, emits abortFinished when done.
    ***********************************************************/
    void abortNetworkJobs (
        AbortType abortType,
        const std.function<bool (AbstractNetworkJob *job)> &mayAbortJob);

    /***********************************************************
    Checks whether the current error is one that should reset the whole
    transfer if it happens too often. If so : Bump UploadInfo.errorCount
    and maybe perform the reset.
    ***********************************************************/
    void checkResettingErrors ();

    /***********************************************************
    Error handling functionality that is shared between jobs.
    ***********************************************************/
    void commonErrorHandling (AbstractNetworkJob *job);

    /***********************************************************
    Increases the timeout for the final MOVE/PUT for large files.
    
    This is an unfortunate workaround since the drawback is not being able to
    detect real disconnects in a timely manner. Shall go away when the s
    response starts coming quicker, or there is some sort of async api.

     * See #6527, enterprise#2480
    ***********************************************************/
    static void adjustLastJobTimeout (AbstractNetworkJob *job, int64 fileSize);

    /***********************************************************
    Bases headers that need to be sent on the PUT, or in the MOVE for chunking-ng */
    QMap<QByteArray, QByteArray> headers ();
private:
  PropagateUploadEncrypted *_uploadEncryptedHelper;
  bool _uploadingEncrypted;
  UploadStatus _uploadStatus;
};

/***********************************************************
@ingroup libsync

Propagation job, impementing the old chunking agorithm

***********************************************************/
class PropagateUploadFileV1 : PropagateUploadFileCommon {

private:
    /***********************************************************
    That's the start chunk that was stored in the database for resuming.
    In the non-resuming case it is 0.
    If we are resuming, this is the first chunk we need to send
    ***********************************************************/
    int _startChunk = 0;
    /***********************************************************
    This is the next chunk that we need to send. Starting from 0 even if _startChunk != 0
    (In other words,  _startChunk + _currentChunk is really the number of the chunk we need to send next)
    (In other words, _currentChunk is the number of the chunk that we already sent or started sending)
    ***********************************************************/
    int _currentChunk = 0;
    int _chunkCount = 0; /// Total number of chunks for this file
    uint _transferId = 0; /// transfer id (part of the url)

    int64 chunkSize () {
        // Old chunking does not use dynamic chunking algorithm, and does not adjusts the chunk size respectively,
        // thus this value should be used as the one classifing item to be chunked
        return propagator ().syncOptions ()._initialChunkSize;
    }

public:
    PropagateUploadFileV1 (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateUploadFileCommon (propagator, item) {
    }

    void doStartUpload () override;
public slots:
    void abort (PropagatorJob.AbortType abortType) override;
private slots:
    void startNextChunk ();
    void slotPutFinished ();
    void slotUploadProgress (int64, int64);
};

/***********************************************************
@ingroup libsync

Propagation job, impementing the new chunking agorithm

***********************************************************/
class PropagateUploadFileNG : PropagateUploadFileCommon {
private:
    int64 _sent = 0; /// amount of data (bytes) that was already sent
    uint _transferId = 0; /// transfer id (part of the url)
    int _currentChunk = 0; /// Id of the next chunk that will be sent
    int64 _currentChunkSize = 0; /// current chunk size
    bool _removeJobError = false; /// If not null, there was an error removing the job

    // Map chunk number with its size  from the PROPFIND on resume.
    // (Only used from slotPropfindIterate/slotPropfindFinished because the LsColJob use signals to report data.)
    struct ServerChunkInfo {
        int64 size;
        string originalName;
    };
    QMap<int64, ServerChunkInfo> _serverChunks;

    /***********************************************************
    Return the URL of a chunk.
    If chunk == -1, returns the URL of the parent folder containing the chunks
    ***********************************************************/
    QUrl chunkUrl (int chunk = -1);

public:
    PropagateUploadFileNG (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateUploadFileCommon (propagator, item) {
    }

    void doStartUpload () override;

private:
    void startNewUpload ();
    void startNextChunk ();
public slots:
    void abort (AbortType abortType) override;
private slots:
    void slotPropfindFinished ();
    void slotPropfindFinishedWithError ();
    void slotPropfindIterate (string &name, QMap<string, string> &properties);
    void slotDeleteJobFinished ();
    void slotMkColFinished ();
    void slotPutFinished ();
    void slotMoveJobFinished ();
    void slotUploadProgress (int64, int64);
};

    PUTFileJob.~PUTFileJob () {
        // Make sure that we destroy the QNetworkReply before our _device of which it keeps an internal pointer.
        setReply (nullptr);
    }
    
    void PUTFileJob.start () {
        QNetworkRequest req;
        for (QMap<QByteArray, QByteArray>.const_iterator it = _headers.begin (); it != _headers.end (); ++it) {
            req.setRawHeader (it.key (), it.value ());
        }
    
        req.setPriority (QNetworkRequest.LowPriority); // Long uploads must not block non-propagation jobs.
    
        if (_url.isValid ()) {
            sendRequest ("PUT", _url, req, _device);
        } else {
            sendRequest ("PUT", makeDavUrl (path ()), req, _device);
        }
    
        if (reply ().error () != QNetworkReply.NoError) {
            qCWarning (lcPutJob) << " Network error : " << reply ().errorString ();
        }
    
        connect (reply (), &QNetworkReply.uploadProgress, this, &PUTFileJob.uploadProgress);
        connect (this, &AbstractNetworkJob.networkActivity, account ().data (), &Account.propagatorNetworkActivity);
        _requestTimer.start ();
        AbstractNetworkJob.start ();
    }
    
    bool PUTFileJob.finished () {
        _device.close ();
    
        qCInfo (lcPutJob) << "PUT of" << reply ().request ().url ().toString () << "FINISHED WITH STATUS"
                         << replyStatusString ()
                         << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute)
                         << reply ().attribute (QNetworkRequest.HttpReasonPhraseAttribute);
    
        emit finishedSignal ();
        return true;
    }
    
    void PollJob.start () {
        setTimeout (120 * 1000);
        QUrl accountUrl = account ().url ();
        QUrl finalUrl = QUrl.fromUserInput (accountUrl.scheme () + QLatin1String ("://") + accountUrl.authority ()
            + (path ().startsWith ('/') ? QLatin1String ("") : QLatin1String ("/")) + path ());
        sendRequest ("GET", finalUrl);
        connect (reply (), &QNetworkReply.downloadProgress, this, &AbstractNetworkJob.resetTimeout, Qt.UniqueConnection);
        AbstractNetworkJob.start ();
    }
    
    bool PollJob.finished () {
        QNetworkReply.NetworkError err = reply ().error ();
        if (err != QNetworkReply.NoError) {
            _item._httpErrorCode = reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt ();
            _item._requestId = requestId ();
            _item._status = classifyError (err, _item._httpErrorCode);
            _item._errorString = errorString ();
    
            if (_item._status == SyncFileItem.FatalError || _item._httpErrorCode >= 400) {
                if (_item._status != SyncFileItem.FatalError
                    && _item._httpErrorCode != 503) {
                    SyncJournalDb.PollInfo info;
                    info._file = _item._file;
                    // no info._url removes it from the database
                    _journal.setPollInfo (info);
                    _journal.commit ("remove poll info");
                }
                emit finishedSignal ();
                return true;
            }
            QTimer.singleShot (8 * 1000, this, &PollJob.start);
            return false;
        }
    
        QByteArray jsonData = reply ().readAll ().trimmed ();
        QJsonParseError jsonParseError;
        QJsonObject json = QJsonDocument.fromJson (jsonData, &jsonParseError).object ();
        qCInfo (lcPollJob) << ">" << jsonData << "<" << reply ().attribute (QNetworkRequest.HttpStatusCodeAttribute).toInt () << json << jsonParseError.errorString ();
        if (jsonParseError.error != QJsonParseError.NoError) {
            _item._errorString = tr ("Invalid JSON reply from the poll URL");
            _item._status = SyncFileItem.NormalError;
            emit finishedSignal ();
            return true;
        }
    
        auto status = json["status"].toString ();
        if (status == QLatin1String ("init") || status == QLatin1String ("started")) {
            QTimer.singleShot (5 * 1000, this, &PollJob.start);
            return false;
        }
    
        _item._responseTimeStamp = responseTimestamp ();
        _item._httpErrorCode = json["errorCode"].toInt ();
    
        if (status == QLatin1String ("finished")) {
            _item._status = SyncFileItem.Success;
            _item._fileId = json["fileId"].toString ().toUtf8 ();
            _item._etag = parseEtag (json["ETag"].toString ().toUtf8 ());
        } else { // error
            _item._status = classifyError (QNetworkReply.UnknownContentError, _item._httpErrorCode);
            _item._errorString = json["errorMessage"].toString ();
        }
    
        SyncJournalDb.PollInfo info;
        info._file = _item._file;
        // no info._url removes it from the database
        _journal.setPollInfo (info);
        _journal.commit ("remove poll info");
    
        emit finishedSignal ();
        return true;
    }
    
    PropagateUploadFileCommon.PropagateUploadFileCommon (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item)
        , _finished (false)
        , _deleteExisting (false)
        , _aborting (false)
        , _uploadEncryptedHelper (nullptr)
        , _uploadingEncrypted (false) {
        const auto path = _item._file;
        const auto slashPosition = path.lastIndexOf ('/');
        const auto parentPath = slashPosition >= 0 ? path.left (slashPosition) : string ();
    
        SyncJournalFileRecord parentRec;
        bool ok = propagator._journal.getFileRecord (parentPath, &parentRec);
        if (!ok) {
            return;
        }
    }
    
    void PropagateUploadFileCommon.setDeleteExisting (bool enabled) {
        _deleteExisting = enabled;
    }
    
    void PropagateUploadFileCommon.start () {
        const auto path = _item._file;
        const auto slashPosition = path.lastIndexOf ('/');
        const auto parentPath = slashPosition >= 0 ? path.left (slashPosition) : string ();
    
        if (!_item._renameTarget.isEmpty () && _item._file != _item._renameTarget) {
            // Try to rename the file
            const auto originalFilePathAbsolute = propagator ().fullLocalPath (_item._file);
            const auto newFilePathAbsolute = propagator ().fullLocalPath (_item._renameTarget);
            const auto renameSuccess = QFile.rename (originalFilePathAbsolute, newFilePathAbsolute);
            if (!renameSuccess) {
                done (SyncFileItem.NormalError, "File contains trailing spaces and couldn't be renamed");
                return;
            }
            _item._file = _item._renameTarget;
            _item._modtime = FileSystem.getModTime (newFilePathAbsolute);
            Q_ASSERT (_item._modtime > 0);
            if (_item._modtime <= 0) {
                qCWarning (lcPropagateUpload ()) << "invalid modified time" << _item._file << _item._modtime;
                slotOnErrorStartFolderUnlock (SyncFileItem.NormalError, tr ("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.toNativeSeparators (_item._file)));
                return;
            }
        }
    
        SyncJournalFileRecord parentRec;
        bool ok = propagator ()._journal.getFileRecord (parentPath, &parentRec);
        if (!ok) {
            done (SyncFileItem.NormalError);
            return;
        }
    
        const auto account = propagator ().account ();
    
        if (!account.capabilities ().clientSideEncryptionAvailable () ||
            !parentRec.isValid () ||
            !parentRec._isE2eEncrypted) {
            setupUnencryptedFile ();
            return;
        }
    
        const auto remoteParentPath = parentRec._e2eMangledName.isEmpty () ? parentPath : parentRec._e2eMangledName;
        _uploadEncryptedHelper = new PropagateUploadEncrypted (propagator (), remoteParentPath, _item, this);
        connect (_uploadEncryptedHelper, &PropagateUploadEncrypted.finalized,
                this, &PropagateUploadFileCommon.setupEncryptedFile);
        connect (_uploadEncryptedHelper, &PropagateUploadEncrypted.error, [this] {
            qCDebug (lcPropagateUpload) << "Error setting up encryption.";
            done (SyncFileItem.FatalError, tr ("Failed to upload encrypted file."));
        });
        _uploadEncryptedHelper.start ();
    }
    
    void PropagateUploadFileCommon.setupEncryptedFile (string& path, string& filename, uint64 size) {
        qCDebug (lcPropagateUpload) << "Starting to upload encrypted file" << path << filename << size;
        _uploadingEncrypted = true;
        _fileToUpload._path = path;
        _fileToUpload._file = filename;
        _fileToUpload._size = size;
        startUploadFile ();
    }
    
    void PropagateUploadFileCommon.setupUnencryptedFile () {
        _uploadingEncrypted = false;
        _fileToUpload._file = _item._file;
        _fileToUpload._size = _item._size;
        _fileToUpload._path = propagator ().fullLocalPath (_fileToUpload._file);
        startUploadFile ();
    }
    
    void PropagateUploadFileCommon.startUploadFile () {
        if (propagator ()._abortRequested) {
            return;
        }
    
        // Check if the specific file can be accessed
        if (propagator ().hasCaseClashAccessibilityProblem (_fileToUpload._file)) {
            done (SyncFileItem.NormalError, tr ("File %1 cannot be uploaded because another file with the same name, differing only in case, exists").arg (QDir.toNativeSeparators (_item._file)));
            return;
        }
    
        // Check if we believe that the upload will fail due to remote quota limits
        const int64 quotaGuess = propagator ()._folderQuota.value (
            QFileInfo (_fileToUpload._file).path (), std.numeric_limits<int64>.max ());
        if (_fileToUpload._size > quotaGuess) {
            // Necessary for blacklisting logic
            _item._httpErrorCode = 507;
            emit propagator ().insufficientRemoteStorage ();
            done (SyncFileItem.DetailError, tr ("Upload of %1 exceeds the quota for the folder").arg (Utility.octetsToString (_fileToUpload._size)));
            return;
        }
    
        propagator ()._activeJobList.append (this);
    
        if (!_deleteExisting) {
            qDebug () << "Running the compute checksum";
            return slotComputeContentChecksum ();
        }
    
        qDebug () << "Deleting the current";
        auto job = new DeleteJob (propagator ().account (),
            propagator ().fullRemotePath (_fileToUpload._file),
            this);
        _jobs.append (job);
        connect (job, &DeleteJob.finishedSignal, this, &PropagateUploadFileCommon.slotComputeContentChecksum);
        connect (job, &GLib.Object.destroyed, this, &PropagateUploadFileCommon.slotJobDestroyed);
        job.start ();
    }
    
    void PropagateUploadFileCommon.slotComputeContentChecksum () {
        qDebug () << "Trying to compute the checksum of the file";
        qDebug () << "Still trying to understand if this is the local file or the uploaded one";
        if (propagator ()._abortRequested) {
            return;
        }
    
        const string filePath = propagator ().fullLocalPath (_item._file);
    
        // remember the modtime before checksumming to be able to detect a file
        // change during the checksum calculation - This goes inside of the _item._file
        // and not the _fileToUpload because we are checking the original file, not there
        // probably temporary one.
        _item._modtime = FileSystem.getModTime (filePath);
        if (_item._modtime <= 0) {
            slotOnErrorStartFolderUnlock (SyncFileItem.NormalError, tr ("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.toNativeSeparators (_item._file)));
            return;
        }
    
        const QByteArray checksumType = propagator ().account ().capabilities ().preferredUploadChecksumType ();
    
        // Maybe the discovery already computed the checksum?
        // Should I compute the checksum of the original (_item._file)
        // or the maybe-modified? (_fileToUpload._file) ?
    
        QByteArray existingChecksumType, existingChecksum;
        parseChecksumHeader (_item._checksumHeader, &existingChecksumType, &existingChecksum);
        if (existingChecksumType == checksumType) {
            slotComputeTransmissionChecksum (checksumType, existingChecksum);
            return;
        }
    
        // Compute the content checksum.
        auto computeChecksum = new ComputeChecksum (this);
        computeChecksum.setChecksumType (checksumType);
    
        connect (computeChecksum, &ComputeChecksum.done,
            this, &PropagateUploadFileCommon.slotComputeTransmissionChecksum);
        connect (computeChecksum, &ComputeChecksum.done,
            computeChecksum, &GLib.Object.deleteLater);
        computeChecksum.start (_fileToUpload._path);
    }
    
    void PropagateUploadFileCommon.slotComputeTransmissionChecksum (QByteArray &contentChecksumType, QByteArray &contentChecksum) {
        _item._checksumHeader = makeChecksumHeader (contentChecksumType, contentChecksum);
    
        // Reuse the content checksum as the transmission checksum if possible
        const auto supportedTransmissionChecksums =
            propagator ().account ().capabilities ().supportedChecksumTypes ();
        if (supportedTransmissionChecksums.contains (contentChecksumType)) {
            slotStartUpload (contentChecksumType, contentChecksum);
            return;
        }
    
        // Compute the transmission checksum.
        auto computeChecksum = new ComputeChecksum (this);
        if (uploadChecksumEnabled ()) {
            computeChecksum.setChecksumType (propagator ().account ().capabilities ().uploadChecksumType ());
        } else {
            computeChecksum.setChecksumType (QByteArray ());
        }
    
        connect (computeChecksum, &ComputeChecksum.done,
            this, &PropagateUploadFileCommon.slotStartUpload);
        connect (computeChecksum, &ComputeChecksum.done,
            computeChecksum, &GLib.Object.deleteLater);
        computeChecksum.start (_fileToUpload._path);
    }
    
    void PropagateUploadFileCommon.slotStartUpload (QByteArray &transmissionChecksumType, QByteArray &transmissionChecksum) {
        // Remove ourselfs from the list of active job, before any posible call to done ()
        // When we start chunks, we will add it again, once for every chunks.
        propagator ()._activeJobList.removeOne (this);
    
        _transmissionChecksumHeader = makeChecksumHeader (transmissionChecksumType, transmissionChecksum);
    
        // If no checksum header was not set, reuse the transmission checksum as the content checksum.
        if (_item._checksumHeader.isEmpty ()) {
            _item._checksumHeader = _transmissionChecksumHeader;
        }
    
        const string fullFilePath = _fileToUpload._path;
        const string originalFilePath = propagator ().fullLocalPath (_item._file);
    
        if (!FileSystem.fileExists (fullFilePath)) {
            return slotOnErrorStartFolderUnlock (SyncFileItem.SoftError, tr ("File Removed (start upload) %1").arg (fullFilePath));
        }
        if (_item._modtime <= 0) {
            slotOnErrorStartFolderUnlock (SyncFileItem.NormalError, tr ("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.toNativeSeparators (_item._file)));
            return;
        }
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            qCWarning (lcPropagateUpload ()) << "invalid modified time" << _item._file << _item._modtime;
        }
        time_t prevModtime = _item._modtime; // the _item value was set in PropagateUploadFile.start ()
        // but a potential checksum calculation could have taken some time during which the file could
        // have been changed again, so better check again here.
    
        _item._modtime = FileSystem.getModTime (originalFilePath);
        if (_item._modtime <= 0) {
            slotOnErrorStartFolderUnlock (SyncFileItem.NormalError, tr ("File %1 has invalid modified time. Do not upload to the server.").arg (QDir.toNativeSeparators (_item._file)));
            return;
        }
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            qCWarning (lcPropagateUpload ()) << "invalid modified time" << _item._file << _item._modtime;
        }
        if (prevModtime != _item._modtime) {
            propagator ()._anotherSyncNeeded = true;
            qDebug () << "prevModtime" << prevModtime << "Curr" << _item._modtime;
            return slotOnErrorStartFolderUnlock (SyncFileItem.SoftError, tr ("Local file changed during syncing. It will be resumed."));
        }
    
        _fileToUpload._size = FileSystem.getSize (fullFilePath);
        _item._size = FileSystem.getSize (originalFilePath);
    
        // But skip the file if the mtime is too close to 'now'!
        // That usually indicates a file that is still being changed
        // or not yet fully copied to the destination.
        if (fileIsStillChanging (*_item)) {
            propagator ()._anotherSyncNeeded = true;
            return slotOnErrorStartFolderUnlock (SyncFileItem.SoftError, tr ("Local file changed during sync."));
        }
    
        doStartUpload ();
    }
    
    void PropagateUploadFileCommon.slotFolderUnlocked (QByteArray &folderId, int httpReturnCode) {
        qDebug () << "Failed to unlock encrypted folder" << folderId;
        if (_uploadStatus.status == SyncFileItem.NoStatus && httpReturnCode != 200) {
            done (SyncFileItem.FatalError, tr ("Failed to unlock encrypted folder."));
        } else {
            done (_uploadStatus.status, _uploadStatus.message);
        }
    }
    
    void PropagateUploadFileCommon.slotOnErrorStartFolderUnlock (SyncFileItem.Status status, string &errorString) {
        if (_uploadingEncrypted) {
            _uploadStatus = { status, errorString };
            connect (_uploadEncryptedHelper, &PropagateUploadEncrypted.folderUnlocked, this, &PropagateUploadFileCommon.slotFolderUnlocked);
            _uploadEncryptedHelper.unlockFolder ();
        } else {
            done (status, errorString);
        }
    }
    
    UploadDevice.UploadDevice (string &fileName, int64 start, int64 size, BandwidthManager *bwm)
        : _file (fileName)
        , _start (start)
        , _size (size)
        , _bandwidthManager (bwm) {
        _bandwidthManager.registerUploadDevice (this);
    }
    
    UploadDevice.~UploadDevice () {
        if (_bandwidthManager) {
            _bandwidthManager.unregisterUploadDevice (this);
        }
    }
    
    bool UploadDevice.open (QIODevice.OpenMode mode) {
        if (mode & QIODevice.WriteOnly)
            return false;
    
        // Get the file size now : _file.fileName () is no longer reliable
        // on all platforms after openAndSeekFileSharedRead ().
        auto fileDiskSize = FileSystem.getSize (_file.fileName ());
    
        string openError;
        if (!FileSystem.openAndSeekFileSharedRead (&_file, &openError, _start)) {
            setErrorString (openError);
            return false;
        }
    
        _size = qBound (0ll, _size, fileDiskSize - _start);
        _read = 0;
    
        return QIODevice.open (mode);
    }
    
    void UploadDevice.close () {
        _file.close ();
        QIODevice.close ();
    }
    
    int64 UploadDevice.writeData (char *, int64) {
        ASSERT (false, "write to read only device");
        return 0;
    }
    
    int64 UploadDevice.readData (char *data, int64 maxlen) {
        if (_size - _read <= 0) {
            // at end
            if (_bandwidthManager) {
                _bandwidthManager.unregisterUploadDevice (this);
            }
            return -1;
        }
        maxlen = qMin (maxlen, _size - _read);
        if (maxlen <= 0) {
            return 0;
        }
        if (isChoked ()) {
            return 0;
        }
        if (isBandwidthLimited ()) {
            maxlen = qMin (maxlen, _bandwidthQuota);
            if (maxlen <= 0) { // no quota
                return 0;
            }
            _bandwidthQuota -= maxlen;
        }
    
        auto c = _file.read (data, maxlen);
        if (c < 0) {
            setErrorString (_file.errorString ());
            return -1;
        }
        _read += c;
        return c;
    }
    
    void UploadDevice.slotJobUploadProgress (int64 sent, int64 t) {
        if (sent == 0 || t == 0) {
            return;
        }
        _readWithProgress = sent;
    }
    
    bool UploadDevice.atEnd () {
        return _read >= _size;
    }
    
    int64 UploadDevice.size () {
        return _size;
    }
    
    int64 UploadDevice.bytesAvailable () {
        return _size - _read + QIODevice.bytesAvailable ();
    }
    
    // random access, we can seek
    bool UploadDevice.isSequential () {
        return false;
    }
    
    bool UploadDevice.seek (int64 pos) {
        if (!QIODevice.seek (pos)) {
            return false;
        }
        if (pos < 0 || pos > _size) {
            return false;
        }
        _read = pos;
        _file.seek (_start + pos);
        return true;
    }
    
    void UploadDevice.giveBandwidthQuota (int64 bwq) {
        if (!atEnd ()) {
            _bandwidthQuota = bwq;
            QMetaObject.invokeMethod (this, "readyRead", Qt.QueuedConnection); // tell QNAM that we have quota
        }
    }
    
    void UploadDevice.setBandwidthLimited (bool b) {
        _bandwidthLimited = b;
        QMetaObject.invokeMethod (this, "readyRead", Qt.QueuedConnection);
    }
    
    void UploadDevice.setChoked (bool b) {
        _choked = b;
        if (!_choked) {
            QMetaObject.invokeMethod (this, "readyRead", Qt.QueuedConnection);
        }
    }
    
    void PropagateUploadFileCommon.startPollJob (string &path) {
        auto *job = new PollJob (propagator ().account (), path, _item,
            propagator ()._journal, propagator ().localPath (), this);
        connect (job, &PollJob.finishedSignal, this, &PropagateUploadFileCommon.slotPollFinished);
        SyncJournalDb.PollInfo info;
        info._file = _item._file;
        info._url = path;
        info._modtime = _item._modtime;
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            qCWarning (lcPropagateUpload ()) << "invalid modified time" << _item._file << _item._modtime;
        }
        info._fileSize = _item._size;
        propagator ()._journal.setPollInfo (info);
        propagator ()._journal.commit ("add poll info");
        propagator ()._activeJobList.append (this);
        job.start ();
    }
    
    void PropagateUploadFileCommon.slotPollFinished () {
        auto *job = qobject_cast<PollJob> (sender ());
        ASSERT (job);
    
        propagator ()._activeJobList.removeOne (this);
    
        if (job._item._status != SyncFileItem.Success) {
            done (job._item._status, job._item._errorString);
            return;
        }
    
        finalize ();
    }
    
    void PropagateUploadFileCommon.done (SyncFileItem.Status status, string &errorString) {
        _finished = true;
        PropagateItemJob.done (status, errorString);
    }
    
    void PropagateUploadFileCommon.checkResettingErrors () {
        if (_item._httpErrorCode == 412
            || propagator ().account ().capabilities ().httpErrorCodesThatResetFailingChunkedUploads ().contains (_item._httpErrorCode)) {
            auto uploadInfo = propagator ()._journal.getUploadInfo (_item._file);
            uploadInfo._errorCount += 1;
            if (uploadInfo._errorCount > 3) {
                qCInfo (lcPropagateUpload) << "Reset transfer of" << _item._file
                                          << "due to repeated error" << _item._httpErrorCode;
                uploadInfo = SyncJournalDb.UploadInfo ();
            } else {
                qCInfo (lcPropagateUpload) << "Error count for maybe-reset error" << _item._httpErrorCode
                                          << "on file" << _item._file
                                          << "is" << uploadInfo._errorCount;
            }
            propagator ()._journal.setUploadInfo (_item._file, uploadInfo);
            propagator ()._journal.commit ("Upload info");
        }
    }
    
    void PropagateUploadFileCommon.commonErrorHandling (AbstractNetworkJob *job) {
        QByteArray replyContent;
        string errorString = job.errorStringParsingBody (&replyContent);
        qCDebug (lcPropagateUpload) << replyContent; // display the XML error in the debug
    
        if (_item._httpErrorCode == 412) {
            // Precondition Failed : Either an etag or a checksum mismatch.
    
            // Maybe the bad etag is in the database, we need to clear the
            // parent folder etag so we won't read from DB next sync.
            propagator ()._journal.schedulePathForRemoteDiscovery (_item._file);
            propagator ()._anotherSyncNeeded = true;
        }
    
        // Ensure errors that should eventually reset the chunked upload are tracked.
        checkResettingErrors ();
    
        SyncFileItem.Status status = classifyError (job.reply ().error (), _item._httpErrorCode,
            &propagator ()._anotherSyncNeeded, replyContent);
    
        // Insufficient remote storage.
        if (_item._httpErrorCode == 507) {
            // Update the quota expectation
            /* store the quota for the real local file using the information
             * on the file to upload, that could have been modified by
             * filters or something. */
            const auto path = QFileInfo (_item._file).path ();
            auto quotaIt = propagator ()._folderQuota.find (path);
            if (quotaIt != propagator ()._folderQuota.end ()) {
                quotaIt.value () = qMin (quotaIt.value (), _fileToUpload._size - 1);
            } else {
                propagator ()._folderQuota[path] = _fileToUpload._size - 1;
            }
    
            // Set up the error
            status = SyncFileItem.DetailError;
            errorString = tr ("Upload of %1 exceeds the quota for the folder").arg (Utility.octetsToString (_fileToUpload._size));
            emit propagator ().insufficientRemoteStorage ();
        }
    
        abortWithError (status, errorString);
    }
    
    void PropagateUploadFileCommon.adjustLastJobTimeout (AbstractNetworkJob *job, int64 fileSize) {
        constexpr double threeMinutes = 3.0 * 60 * 1000;
    
        job.setTimeout (qBound (
            job.timeoutMsec (),
            // Calculate 3 minutes for each gigabyte of data
            qRound64 (threeMinutes * fileSize / 1e9),
            // Maximum of 30 minutes
            static_cast<int64> (30 * 60 * 1000)));
    }
    
    void PropagateUploadFileCommon.slotJobDestroyed (GLib.Object *job) {
        _jobs.erase (std.remove (_jobs.begin (), _jobs.end (), job), _jobs.end ());
    }
    
    // This function is used whenever there is an error occuring and jobs might be in progress
    void PropagateUploadFileCommon.abortWithError (SyncFileItem.Status status, string &error) {
        if (_aborting)
            return;
        abort (AbortType.Synchronous);
        done (status, error);
    }
    
    QMap<QByteArray, QByteArray> PropagateUploadFileCommon.headers () {
        QMap<QByteArray, QByteArray> headers;
        headers[QByteArrayLiteral ("Content-Type")] = QByteArrayLiteral ("application/octet-stream");
        Q_ASSERT (_item._modtime > 0);
        if (_item._modtime <= 0) {
            qCWarning (lcPropagateUpload ()) << "invalid modified time" << _item._file << _item._modtime;
        }
        headers[QByteArrayLiteral ("X-OC-Mtime")] = QByteArray.number (int64 (_item._modtime));
        if (qEnvironmentVariableIntValue ("OWNCLOUD_LAZYOPS"))
            headers[QByteArrayLiteral ("OC-LazyOps")] = QByteArrayLiteral ("true");
    
        if (_item._file.contains (QLatin1String (".sys.admin#recall#"))) {
            // This is a file recall triggered by the admin.  Note : the
            // recall list file created by the admin and downloaded by the
            // client (.sys.admin#recall#) also falls into this category
            // (albeit users are not supposed to mess up with it)
    
            // We use a special tag header so that the server may decide to store this file away in some admin stage area
            // And not directly in the user's area (which would trigger redownloads etc).
            headers["OC-Tag"] = ".sys.admin#recall#";
        }
    
        if (!_item._etag.isEmpty () && _item._etag != "empty_etag"
            && _item._instruction != CSYNC_INSTRUCTION_NEW // On new files never send a If-Match
            && _item._instruction != CSYNC_INSTRUCTION_TYPE_CHANGE
            && !_deleteExisting) {
            // We add quotes because the owncloud server always adds quotes around the etag, and
            //  csync_owncloud.c's owncloud_file_id always strips the quotes.
            headers[QByteArrayLiteral ("If-Match")] = '"' + _item._etag + '"';
        }
    
        // Set up a conflict file header pointing to the original file
        auto conflictRecord = propagator ()._journal.conflictRecord (_item._file.toUtf8 ());
        if (conflictRecord.isValid ()) {
            headers[QByteArrayLiteral ("OC-Conflict")] = "1";
            if (!conflictRecord.initialBasePath.isEmpty ())
                headers[QByteArrayLiteral ("OC-ConflictInitialBasePath")] = conflictRecord.initialBasePath;
            if (!conflictRecord.baseFileId.isEmpty ())
                headers[QByteArrayLiteral ("OC-ConflictBaseFileId")] = conflictRecord.baseFileId;
            if (conflictRecord.baseModtime != -1)
                headers[QByteArrayLiteral ("OC-ConflictBaseMtime")] = QByteArray.number (conflictRecord.baseModtime);
            if (!conflictRecord.baseEtag.isEmpty ())
                headers[QByteArrayLiteral ("OC-ConflictBaseEtag")] = conflictRecord.baseEtag;
        }
    
        if (_uploadEncryptedHelper && !_uploadEncryptedHelper.folderToken ().isEmpty ()) {
            headers.insert ("e2e-token", _uploadEncryptedHelper.folderToken ());
        }
    
        return headers;
    }
    
    void PropagateUploadFileCommon.finalize () {
        // Update the quota, if known
        auto quotaIt = propagator ()._folderQuota.find (QFileInfo (_item._file).path ());
        if (quotaIt != propagator ()._folderQuota.end ())
            quotaIt.value () -= _fileToUpload._size;
    
        // Update the database entry
        const auto result = propagator ().updateMetadata (*_item);
        if (!result) {
            done (SyncFileItem.FatalError, tr ("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            done (SyncFileItem.SoftError, tr ("The file %1 is currently in use").arg (_item._file));
            return;
        }
    
        // Files that were new on the remote shouldn't have online-only pin state
        // even if their parent folder is online-only.
        if (_item._instruction == CSYNC_INSTRUCTION_NEW
            || _item._instruction == CSYNC_INSTRUCTION_TYPE_CHANGE) {
            auto &vfs = propagator ().syncOptions ()._vfs;
            const auto pin = vfs.pinState (_item._file);
            if (pin && *pin == PinState.OnlineOnly) {
                if (!vfs.setPinState (_item._file, PinState.Unspecified)) {
                    qCWarning (lcPropagateUpload) << "Could not set pin state of" << _item._file << "to unspecified";
                }
            }
        }
    
        // Remove from the progress database:
        propagator ()._journal.setUploadInfo (_item._file, SyncJournalDb.UploadInfo ());
        propagator ()._journal.commit ("upload file start");
    
        if (_uploadingEncrypted) {
            _uploadStatus = { SyncFileItem.Success, string () };
            connect (_uploadEncryptedHelper, &PropagateUploadEncrypted.folderUnlocked, this, &PropagateUploadFileCommon.slotFolderUnlocked);
            _uploadEncryptedHelper.unlockFolder ();
        } else {
            done (SyncFileItem.Success);
        }
    }
    
    void PropagateUploadFileCommon.abortNetworkJobs (
        PropagatorJob.AbortType abortType,
        const std.function<bool (AbstractNetworkJob *)> &mayAbortJob) {
        if (_aborting)
            return;
        _aborting = true;
    
        // Count the number of jobs that need aborting, and emit the overall
        // abort signal when they're all done.
        QSharedPointer<int> runningCount (new int (0));
        auto oneAbortFinished = [this, runningCount] () {
            (*runningCount)--;
            if (*runningCount == 0) {
                emit this.abortFinished ();
            }
        };
    
        // Abort all running jobs, except for explicitly excluded ones
        foreach (AbstractNetworkJob *job, _jobs) {
            auto reply = job.reply ();
            if (!reply || !reply.isRunning ())
                continue;
    
            (*runningCount)++;
    
            // If a job should not be aborted that means we'll never abort before
            // the hard abort timeout signal comes as runningCount will never go to
            // zero.
            // We may however finish before that if the un-abortable job completes
            // normally.
            if (!mayAbortJob (job))
                continue;
    
            // Abort the job
            if (abortType == AbortType.Asynchronous) {
                // Connect to finished signal of job reply to asynchonously finish the abort
                connect (reply, &QNetworkReply.finished, this, oneAbortFinished);
            }
            reply.abort ();
        }
    
        if (*runningCount == 0 && abortType == AbortType.Asynchronous)
            emit abortFinished ();
    }
    }
    