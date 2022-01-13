#ifndef PROPAGATEDOWNLOADENCRYPTED_H
const int PROPAGATEDOWNLOADENCRYPTED_H

// #include <GLib.Object>
// #include <QFileInfo>


namespace Occ {

class PropagateDownloadEncrypted : GLib.Object {
  Q_OBJECT
public:
  PropagateDownloadEncrypted (OwncloudPropagator *propagator, QString &localParentPath, SyncFileItemPtr item, GLib.Object *parent = nullptr);
  void start ();
  bool decryptFile (QFile& tmpFile);
  QString errorString ();

public slots:
  void checkFolderId (QStringList &list);
  void checkFolderEncryptedMetadata (QJsonDocument &json);
  void folderIdError ();
  void folderEncryptedMetadataError (QByteArray &fileId, int httpReturnCode);

signals:
  void fileMetadataFound ();
  void failed ();

  void decryptionFinished ();

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
