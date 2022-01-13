/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
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

    /** Whether an abort is currently ongoing.
     *
     * Important to avoid duplicate aborts since each finishing PUTFileJob might
     * trigger an abort on error.
     */
    bool _aborting BITFIELD (1);

    /* This is a minified version of the SyncFileItem,
     * that holds only the specifics about the file that's
     * being uploaded.
     *
     * This is needed if we wanna apply changes on the file
     * that's being uploaded while keeping the original on disk.
     */
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
     * Whether an existing entity with the same name may be deleted before
     * the upload.
     *
     * Default : false.
     */
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
     * Aborts all running network jobs, except for the ones that mayAbortJob
     * returns false on and, for async aborts, emits abortFinished when done.
     */
    void abortNetworkJobs (
        AbortType abortType,
        const std.function<bool (AbstractNetworkJob *job)> &mayAbortJob);

    /***********************************************************
     * Checks whether the current error is one that should reset the whole
     * transfer if it happens too often. If so : Bump UploadInfo.errorCount
     * and maybe perform the reset.
     */
    void checkResettingErrors ();

    /***********************************************************
     * Error handling functionality that is shared between jobs.
     */
    void commonErrorHandling (AbstractNetworkJob *job);

    /***********************************************************
     * Increases the timeout for the final MOVE/PUT for large files.
     *
     * This is an unfortunate workaround since the drawback is not being able to
     * detect real disconnects in a timely manner. Shall go away when the server
     * response starts coming quicker, or there is some sort of async api.
     *
     * See #6527, enterprise#2480
     */
    static void adjustLastJobTimeout (AbstractNetworkJob *job, int64 fileSize);

    /** Bases headers that need to be sent on the PUT, or in the MOVE for chunking-ng */
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
     * That's the start chunk that was stored in the database for resuming.
     * In the non-resuming case it is 0.
     * If we are resuming, this is the first chunk we need to send
     */
    int _startChunk = 0;
    /***********************************************************
     * This is the next chunk that we need to send. Starting from 0 even if _startChunk != 0
     * (In other words,  _startChunk + _currentChunk is really the number of the chunk we need to send next)
     * (In other words, _currentChunk is the number of the chunk that we already sent or started sending)
     */
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
     * Return the URL of a chunk.
     * If chunk == -1, returns the URL of the parent folder containing the chunks
     */
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
}
