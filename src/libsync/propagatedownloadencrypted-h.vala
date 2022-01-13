#ifndef PROPAGATEDOWNLOADENCRYPTED_H
#define PROPAGATEDOWNLOADENCRYPTED_H

// #include <QObject>
// #include <QFileInfo>

class QJsonDocument;

namespace OCC {

class PropagateDownloadEncrypted : public QObject {
  Q_OBJECT
public:
  PropagateDownloadEncrypted(OwncloudPropagator *propagator, QString &localParentPath, SyncFileItemPtr item, QObject *parent = nullptr);
  void start();
  bool decryptFile(QFile& tmpFile);
  QString errorString() const;

public slots:
  void checkFolderId(QStringList &list);
  void checkFolderEncryptedMetadata(QJsonDocument &json);
  void folderIdError();
  void folderEncryptedMetadataError(QByteArray &fileId, int httpReturnCode);

signals:
  void fileMetadataFound();
  void failed();

  void decryptionFinished();

private:
  OwncloudPropagator *_propagator;
  QString _localParentPath;
  SyncFileItemPtr _item;
  QFileInfo _info;
  EncryptedFile _encryptedInfo;
  QString _errorString;
};

}
#endif
