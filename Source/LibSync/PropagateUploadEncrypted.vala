

// #include <GLib.Object>
// #include <string>
// #include <QMap>
// #include <QByteArray>
// #include <QJsonDocument>
// #include <QNetworkReply>
// #include <QFile>
// #include <QTemporaryFile>
// #include <QFileInfo>
// #include <QDir>
// #include <QUrl>
// #include <QFile>
// #include <QTemporaryFile>
// #include <QLoggingCategory>
// #include <QMimeDatabase>

namespace Occ {

  /* This class is used if the server supports end to end encryption.
It will fire for *any* folder, encrypted or not, because when the
client starts the upload request we don't know if the folder is
encrypted on the server.

emits:
finalized () if the encrypted file is ready to be
error () if there was an error with the encryption
folderNotEncrypted () if the file is within a folder that's not encrypted.

***********************************************************/

class PropagateUploadEncrypted : GLib.Object {
  Q_OBJECT
public:
    PropagateUploadEncrypted (OwncloudPropagator *propagator, string &remoteParentPath, SyncFileItemPtr item, GLib.Object *parent = nullptr);
    ~PropagateUploadEncrypted () override = default;

    void start ();

    void unlockFolder ();

    bool isUnlockRunning () { return _isUnlockRunning; }
    bool isFolderLocked () { return _isFolderLocked; }
    const QByteArray folderToken () { return _folderToken; }

private slots:
    void slotFolderEncryptedIdReceived (QStringList &list);
    void slotFolderEncryptedIdError (QNetworkReply *r);
    void slotFolderLockedSuccessfully (QByteArray& fileId, QByteArray& token);
    void slotFolderLockedError (QByteArray& fileId, int httpErrorCode);
    void slotTryLock (QByteArray& fileId);
    void slotFolderEncryptedMetadataReceived (QJsonDocument &json, int statusCode);
    void slotFolderEncryptedMetadataError (QByteArray& fileId, int httpReturnCode);
    void slotUpdateMetadataSuccess (QByteArray& fileId);
    void slotUpdateMetadataError (QByteArray& fileId, int httpReturnCode);

signals:
    // Emmited after the file is encrypted and everythign is setup.
    void finalized (string& path, string& filename, uint64 size);
    void error ();
    void folderUnlocked (QByteArray &folderId, int httpStatus);

private:
  OwncloudPropagator *_propagator;
  string _remoteParentPath;
  SyncFileItemPtr _item;

  QByteArray _folderToken;
  QByteArray _folderId;

  QElapsedTimer _folderLockFirstTry;
  bool _currentLockingInProgress = false;

  bool _isUnlockRunning = false;
  bool _isFolderLocked = false;

  QByteArray _generatedKey;
  QByteArray _generatedIv;
  FolderMetadata *_metadata;
  EncryptedFile _encryptedFile;
  string _completeFileName;
};


  PropagateUploadEncrypted.PropagateUploadEncrypted (OwncloudPropagator *propagator, string &remoteParentPath, SyncFileItemPtr item, GLib.Object *parent)
      : GLib.Object (parent)
      , _propagator (propagator)
      , _remoteParentPath (remoteParentPath)
      , _item (item)
      , _metadata (nullptr) {
  }
  
  void PropagateUploadEncrypted.start () {
      const auto rootPath = [=] () {
          const auto result = _propagator.remotePath ();
          if (result.startsWith ('/')) {
              return result.mid (1);
          } else {
              return result;
          }
      } ();
      const auto absoluteRemoteParentPath = [=]{
          auto path = string (rootPath + _remoteParentPath);
          if (path.endsWith ('/')) {
              path.chop (1);
          }
          return path;
      } ();
  
      /* If the file is in a encrypted folder, which we know, we wouldn't be here otherwise,
       * we need to do the long road:
       * find the ID of the folder.
       * lock the folder using it's id.
       * download the metadata
       * update the metadata
       * upload the file
       * upload the metadata
       * unlock the folder.
       */
      qCDebug (lcPropagateUploadEncrypted) << "Folder is encrypted, let's get the Id from it.";
      auto job = new LsColJob (_propagator.account (), absoluteRemoteParentPath, this);
      job.setProperties ({"resourcetype", "http://owncloud.org/ns:fileid"});
      connect (job, &LsColJob.directoryListingSubfolders, this, &PropagateUploadEncrypted.slotFolderEncryptedIdReceived);
      connect (job, &LsColJob.finishedWithError, this, &PropagateUploadEncrypted.slotFolderEncryptedIdError);
      job.start ();
  }
  
  /* We try to lock a folder, if it's locked we try again in one second.
  if it's still locked we try again in one second. looping untill one minute.
                                                                       . fail.
  the 'loop' :                                                         /
     slotFolderEncryptedIdReceived . slotTryLock . lockError . stillTime? . slotTryLock
  
                                          . success.
  ***********************************************************/
  
  void PropagateUploadEncrypted.slotFolderEncryptedIdReceived (QStringList &list) {
    qCDebug (lcPropagateUploadEncrypted) << "Received id of folder, trying to lock it so we can prepare the metadata";
    auto job = qobject_cast<LsColJob> (sender ());
    const auto& folderInfo = job._folderInfos.value (list.first ());
    _folderLockFirstTry.start ();
    slotTryLock (folderInfo.fileId);
  }
  
  void PropagateUploadEncrypted.slotTryLock (QByteArray& fileId) {
    auto *lockJob = new LockEncryptFolderApiJob (_propagator.account (), fileId, this);
    connect (lockJob, &LockEncryptFolderApiJob.success, this, &PropagateUploadEncrypted.slotFolderLockedSuccessfully);
    connect (lockJob, &LockEncryptFolderApiJob.error, this, &PropagateUploadEncrypted.slotFolderLockedError);
    lockJob.start ();
  }
  
  void PropagateUploadEncrypted.slotFolderLockedSuccessfully (QByteArray& fileId, QByteArray& token) {
    qCDebug (lcPropagateUploadEncrypted) << "Folder" << fileId << "Locked Successfully for Upload, Fetching Metadata";
    // Should I use a mutex here?
    _currentLockingInProgress = true;
    _folderToken = token;
    _folderId = fileId;
    _isFolderLocked = true;
  
    auto job = new GetMetadataApiJob (_propagator.account (), _folderId);
    connect (job, &GetMetadataApiJob.jsonReceived,
            this, &PropagateUploadEncrypted.slotFolderEncryptedMetadataReceived);
    connect (job, &GetMetadataApiJob.error,
            this, &PropagateUploadEncrypted.slotFolderEncryptedMetadataError);
  
    job.start ();
  }
  
  void PropagateUploadEncrypted.slotFolderEncryptedMetadataError (QByteArray& fileId, int httpReturnCode) {
      Q_UNUSED (fileId);
      Q_UNUSED (httpReturnCode);
      qCDebug (lcPropagateUploadEncrypted ()) << "Error Getting the encrypted metadata. Pretend we got empty metadata.";
      FolderMetadata emptyMetadata (_propagator.account ());
      emptyMetadata.encryptedMetadata ();
      auto json = QJsonDocument.fromJson (emptyMetadata.encryptedMetadata ());
      slotFolderEncryptedMetadataReceived (json, httpReturnCode);
  }
  
  void PropagateUploadEncrypted.slotFolderEncryptedMetadataReceived (QJsonDocument &json, int statusCode) {
    qCDebug (lcPropagateUploadEncrypted) << "Metadata Received, Preparing it for the new file." << json.toVariant ();
  
    // Encrypt File!
    _metadata = new FolderMetadata (_propagator.account (), json.toJson (QJsonDocument.Compact), statusCode);
  
    QFileInfo info (_propagator.fullLocalPath (_item._file));
    const string fileName = info.fileName ();
  
    // Find existing metadata for this file
    bool found = false;
    EncryptedFile encryptedFile;
    const QVector<EncryptedFile> files = _metadata.files ();
  
    for (EncryptedFile &file : files) {
      if (file.originalFilename == fileName) {
        encryptedFile = file;
        found = true;
      }
    }
  
    // New encrypted file so set it all up!
    if (!found) {
        encryptedFile.encryptionKey = EncryptionHelper.generateRandom (16);
        encryptedFile.encryptedFilename = EncryptionHelper.generateRandomFilename ();
        encryptedFile.initializationVector = EncryptionHelper.generateRandom (16);
        encryptedFile.fileVersion = 1;
        encryptedFile.metadataKey = 1;
        encryptedFile.originalFilename = fileName;
  
        QMimeDatabase mdb;
        encryptedFile.mimetype = mdb.mimeTypeForFile (info).name ().toLocal8Bit ();
  
        // Other clients expect "httpd/unix-directory" instead of "inode/directory"
        // Doesn't matter much for us since we don't do much about that mimetype anyway
        if (encryptedFile.mimetype == QByteArrayLiteral ("inode/directory")) {
            encryptedFile.mimetype = QByteArrayLiteral ("httpd/unix-directory");
        }
    }
  
    _item._encryptedFileName = _remoteParentPath + QLatin1Char ('/') + encryptedFile.encryptedFilename;
    _item._isEncrypted = true;
  
    qCDebug (lcPropagateUploadEncrypted) << "Creating the encrypted file.";
  
    if (info.isDir ()) {
        _completeFileName = encryptedFile.encryptedFilename;
    } else {
        QFile input (info.absoluteFilePath ());
        QFile output (QDir.tempPath () + QDir.separator () + encryptedFile.encryptedFilename);
  
        QByteArray tag;
        bool encryptionResult = EncryptionHelper.fileEncryption (
          encryptedFile.encryptionKey,
          encryptedFile.initializationVector,
          &input, &output, tag);
  
        if (!encryptionResult) {
          qCDebug (lcPropagateUploadEncrypted ()) << "There was an error encrypting the file, aborting upload.";
          connect (this, &PropagateUploadEncrypted.folderUnlocked, this, &PropagateUploadEncrypted.error);
          unlockFolder ();
          return;
        }
  
        encryptedFile.authenticationTag = tag;
        _completeFileName = output.fileName ();
    }
  
    qCDebug (lcPropagateUploadEncrypted) << "Creating the metadata for the encrypted file.";
  
    _metadata.addEncryptedFile (encryptedFile);
    _encryptedFile = encryptedFile;
  
    qCDebug (lcPropagateUploadEncrypted) << "Metadata created, sending to the server.";
  
    if (statusCode == 404) {
      auto job = new StoreMetaDataApiJob (_propagator.account (),
                                         _folderId,
                                         _metadata.encryptedMetadata ());
      connect (job, &StoreMetaDataApiJob.success, this, &PropagateUploadEncrypted.slotUpdateMetadataSuccess);
      connect (job, &StoreMetaDataApiJob.error, this, &PropagateUploadEncrypted.slotUpdateMetadataError);
      job.start ();
    } else {
      auto job = new UpdateMetadataApiJob (_propagator.account (),
                                        _folderId,
                                        _metadata.encryptedMetadata (),
                                        _folderToken);
  
      connect (job, &UpdateMetadataApiJob.success, this, &PropagateUploadEncrypted.slotUpdateMetadataSuccess);
      connect (job, &UpdateMetadataApiJob.error, this, &PropagateUploadEncrypted.slotUpdateMetadataError);
      job.start ();
    }
  }
  
  void PropagateUploadEncrypted.slotUpdateMetadataSuccess (QByteArray& fileId) {
      Q_UNUSED (fileId);
      qCDebug (lcPropagateUploadEncrypted) << "Uploading of the metadata success, Encrypting the file";
      QFileInfo outputInfo (_completeFileName);
  
      qCDebug (lcPropagateUploadEncrypted) << "Encrypted Info:" << outputInfo.path () << outputInfo.fileName () << outputInfo.size ();
      qCDebug (lcPropagateUploadEncrypted) << "Finalizing the upload part, now the actuall uploader will take over";
      emit finalized (outputInfo.path () + QLatin1Char ('/') + outputInfo.fileName (),
                     _remoteParentPath + QLatin1Char ('/') + outputInfo.fileName (),
                     outputInfo.size ());
  }
  
  void PropagateUploadEncrypted.slotUpdateMetadataError (QByteArray& fileId, int httpErrorResponse) {
    qCDebug (lcPropagateUploadEncrypted) << "Update metadata error for folder" << fileId << "with error" << httpErrorResponse;
    qCDebug (lcPropagateUploadEncrypted ()) << "Unlocking the folder.";
    connect (this, &PropagateUploadEncrypted.folderUnlocked, this, &PropagateUploadEncrypted.error);
    unlockFolder ();
  }
  
  void PropagateUploadEncrypted.slotFolderLockedError (QByteArray& fileId, int httpErrorCode) {
      Q_UNUSED (httpErrorCode);
      /* try to call the lock from 5 to 5 seconds
       * and fail if it's more than 5 minutes. */
      QTimer.singleShot (5000, this, [this, fileId]{
          if (!_currentLockingInProgress) {
              qCDebug (lcPropagateUploadEncrypted) << "Error locking the folder while no other update is locking it up.";
              qCDebug (lcPropagateUploadEncrypted) << "Perhaps another client locked it.";
              qCDebug (lcPropagateUploadEncrypted) << "Abort";
          return;
          }
  
          // Perhaps I should remove the elapsed timer if the lock is from this client?
          if (_folderLockFirstTry.elapsed () > /* five minutes */ 1000 * 60 * 5 ) {
              qCDebug (lcPropagateUploadEncrypted) << "One minute passed, ignoring more attempts to lock the folder.";
          return;
          }
          slotTryLock (fileId);
      });
  
      qCDebug (lcPropagateUploadEncrypted) << "Folder" << fileId << "Coundn't be locked.";
  }
  
  void PropagateUploadEncrypted.slotFolderEncryptedIdError (QNetworkReply *r) {
      Q_UNUSED (r);
      qCDebug (lcPropagateUploadEncrypted) << "Error retrieving the Id of the encrypted folder.";
  }
  
  void PropagateUploadEncrypted.unlockFolder () {
      ASSERT (!_isUnlockRunning);
  
      if (_isUnlockRunning) {
          qWarning () << "Double-call to unlockFolder.";
          return;
      }
  
      _isUnlockRunning = true;
  
      qDebug () << "Calling Unlock";
      auto *unlockJob = new UnlockEncryptFolderApiJob (_propagator.account (),
          _folderId, _folderToken, this);
  
      connect (unlockJob, &UnlockEncryptFolderApiJob.success, [this] (QByteArray &folderId) {
          qDebug () << "Successfully Unlocked";
          _folderToken = "";
          _folderId = "";
          _isFolderLocked = false;
  
          emit folderUnlocked (folderId, 200);
          _isUnlockRunning = false;
      });
      connect (unlockJob, &UnlockEncryptFolderApiJob.error, [this] (QByteArray &folderId, int httpStatus) {
          qDebug () << "Unlock Error";
  
          emit folderUnlocked (folderId, httpStatus);
          _isUnlockRunning = false;
      });
      unlockJob.start ();
  }
  
  } // namespace Occ
  