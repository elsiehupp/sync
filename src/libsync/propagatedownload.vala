/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
// #pragma once

// #include <QBuffer>
// #include <QFile>

namespace Occ {

/***********************************************************
@brief The GETFileJob class
@ingroup libsync
***********************************************************/
class GETFileJob : AbstractNetworkJob {
    QIODevice *_device;
    QMap<QByteArray, QByteArray> _headers;
    string _errorString;
    QByteArray _expectedEtagForResume;
    int64 _expectedContentLength;
    int64 _resumeStart;
    SyncFileItem.Status _errorStatus;
    QUrl _directDownloadUrl;
    QByteArray _etag;
    bool _bandwidthLimited; // if _bandwidthQuota will be used
    bool _bandwidthChoked; // if download is paused (won't read on readyRead ())
    int64 _bandwidthQuota;
    QPointer<BandwidthManager> _bandwidthManager;
    bool _hasEmittedFinishedSignal;
    time_t _lastModified;

    /// Will be set to true once we've seen a 2xx response header
    bool _saveBodyToFile = false;

protected:
    int64 _contentLength;

public:
    // DOES NOT take ownership of the device.
    GETFileJob (AccountPtr account, string &path, QIODevice *device,
        const QMap<QByteArray, QByteArray> &headers, QByteArray &expectedEtagForResume,
        int64 resumeStart, GLib.Object *parent = nullptr);
    // For directDownloadUrl:
    GETFileJob (AccountPtr account, QUrl &url, QIODevice *device,
        const QMap<QByteArray, QByteArray> &headers, QByteArray &expectedEtagForResume,
        int64 resumeStart, GLib.Object *parent = nullptr);
    ~GETFileJob () override {
        if (_bandwidthManager) {
            _bandwidthManager.unregisterDownloadJob (this);
        }
    }

    void start () override;
    bool finished () override {
        if (_saveBodyToFile && reply ().bytesAvailable ()) {
            return false;
        } else {
            if (_bandwidthManager) {
                _bandwidthManager.unregisterDownloadJob (this);
            }
            if (!_hasEmittedFinishedSignal) {
                emit finishedSignal ();
            }
            _hasEmittedFinishedSignal = true;
            return true; // discard
        }
    }

    void cancel ();

    void newReplyHook (QNetworkReply *reply) override;

    void setBandwidthManager (BandwidthManager *bwm);
    void setChoked (bool c);
    void setBandwidthLimited (bool b);
    void giveBandwidthQuota (int64 q);
    int64 currentDownloadPosition ();

    string errorString () const override;
    void setErrorString (string &s) { _errorString = s; }

    SyncFileItem.Status errorStatus () { return _errorStatus; }
    void setErrorStatus (SyncFileItem.Status &s) { _errorStatus = s; }

    void onTimedOut () override;

    QByteArray &etag () { return _etag; }
    int64 resumeStart () { return _resumeStart; }
    time_t lastModified () { return _lastModified; }

    int64 contentLength () { return _contentLength; }
    int64 expectedContentLength () { return _expectedContentLength; }
    void setExpectedContentLength (int64 size) { _expectedContentLength = size; }

protected:
    virtual int64 writeToDevice (QByteArray &data);

signals:
    void finishedSignal ();
    void downloadProgress (int64, int64);
private slots:
    void slotReadyRead ();
    void slotMetaDataChanged ();
};

/***********************************************************
@brief The GETEncryptedFileJob class that provides file decryption on the fly while the download is running
@ingroup libsync
***********************************************************/
class GETEncryptedFileJob : GETFileJob {

public:
    // DOES NOT take ownership of the device.
    GETEncryptedFileJob (AccountPtr account, string &path, QIODevice *device,
        const QMap<QByteArray, QByteArray> &headers, QByteArray &expectedEtagForResume,
        int64 resumeStart, EncryptedFile encryptedInfo, GLib.Object *parent = nullptr);
    GETEncryptedFileJob (AccountPtr account, QUrl &url, QIODevice *device,
        const QMap<QByteArray, QByteArray> &headers, QByteArray &expectedEtagForResume,
        int64 resumeStart, EncryptedFile encryptedInfo, GLib.Object *parent = nullptr);
    ~GETEncryptedFileJob () override = default;

protected:
    int64 writeToDevice (QByteArray &data) override;

private:
    QSharedPointer<EncryptionHelper.StreamingDecryptor> _decryptor;
    EncryptedFile _encryptedFileInfo = {};
    QByteArray _pendingBytes;
    int64 _processedSoFar = 0;
};

/***********************************************************
@brief The PropagateDownloadFile class
@ingroup libsync

This is the flow:

\code{.unparsed}
  start ()
    |
    | deleteExistingFolder () if enabled
    |
    +-. mtime and size identical?
    |    then compute the local checksum
    |                               done?. conflictChecksumComputed ()
    |                                              |
    |                         checksum differs?    |
    +. startDownload () <--------------------------+
          |                                        |
          +. run a GETFileJob                     | checksum identical?
                                                   |
      done?. slotGetFinished ()                    |
                |                                  |
                +. validate checksum header       |
                                                   |
      done?. transmissionChecksumValidated ()      |
                |                                  |
                +. compute the content checksum   |
                                                   |
      done?. contentChecksumComputed ()            |
                |                                  |
                +. downloadFinished ()             |
                       |                           |
    +------------------+                           |
    |                                              |
    +. updateMetadata () <-------------------------+

\endcode
***********************************************************/
class PropagateDownloadFile : PropagateItemJob {
public:
    PropagateDownloadFile (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item)
        , _resumeStart (0)
        , _downloadProgress (0)
        , _deleteExisting (false) {
    }
    void start () override;
    int64 committedDiskSpace () const override;

    // We think it might finish quickly because it is a small file.
    bool isLikelyFinishedQuickly () override { return _item._size < propagator ().smallFileSize (); }

    /***********************************************************
     * Whether an existing folder with the same name may be deleted before
     * the download.
     *
     * If it's a non-empty folder, it'll be renamed to a conflict-style name
     * to preserve any non-synced content that may be inside.
     *
     * Default : false.
     */
    void setDeleteExistingFolder (bool enabled);

private slots:
    /// Called when ComputeChecksum on the local file finishes,
    /// maybe the local and remote checksums are identical?
    void conflictChecksumComputed (QByteArray &checksumType, QByteArray &checksum);
    /// Called to start downloading the remote file
    void startDownload ();
    /// Called when the GETFileJob finishes
    void slotGetFinished ();
    /// Called when the download's checksum header was validated
    void transmissionChecksumValidated (QByteArray &checksumType, QByteArray &checksum);
    /// Called when the download's checksum computation is done
    void contentChecksumComputed (QByteArray &checksumType, QByteArray &checksum);
    void downloadFinished ();
    /// Called when it's time to update the db metadata
    void updateMetadata (bool isConflict);

    void abort (PropagatorJob.AbortType abortType) override;
    void slotDownloadProgress (int64, int64);
    void slotChecksumFail (string &errMsg);

private:
    void startAfterIsEncryptedIsChecked ();
    void deleteExistingFolder ();

    int64 _resumeStart;
    int64 _downloadProgress;
    QPointer<GETFileJob> _job;
    QFile _tmpFile;
    bool _deleteExisting;
    bool _isEncrypted = false;
    EncryptedFile _encryptedInfo;
    ConflictRecord _conflictRecord;

    QElapsedTimer _stopwatch;

    PropagateDownloadEncrypted *_downloadEncryptedHelper = nullptr;
};
}
