#ifndef CLIENTSIDEENCRYPTIONJOBS_H
const int CLIENTSIDEENCRYPTIONJOBS_H

// #include <QString>
// #include <QJsonDocument>

namespace Occ {
/* Here are all of the network jobs for the client side encryption.
anything that goes thru the server and expects a response, is here.
*/

/*
@brief Job to sigh the CSR that return JSON

To be
\code
_job = new SignPubli
_job.setCsr ( csr
connect (_job.
_job.start
\encode

@ingroup libsync
*/
class OWNCLOUDSYNC_EXPORT SignPublicKeyApiJob : AbstractNetworkJob {
public:
    SignPublicKeyApiJob (AccountPtr &account, QString &path, GLib.Object *parent = nullptr);

    /**
     * @brief setCsr - the CSR with the public key.
     * This function needs to be called before start () obviously.
     */
    void setCsr (QByteArray& csr);

public slots:
    void start () override;

protected:
    bool finished () override;
signals:

    /**
     * @brief jsonReceived - signal to report the json answer from ocs
     * @param json - the parsed json document
     * @param statusCode - the OCS status code : 100 (!) for success
     */
    void jsonReceived (QJsonDocument &json, int statusCode);

private:
    QBuffer _csr;
};

/*
@brief Job to upload the PrivateKey that return JSON

To be
\code
_job = new StorePrivateKeyApiJo
_job.setPrivateKey
connect (_job.
_job.start
\encode

@ingroup libsync
*/
class OWNCLOUDSYNC_EXPORT StorePrivateKeyApiJob : AbstractNetworkJob {
public:
    StorePrivateKeyApiJob (AccountPtr &account, QString &path, GLib.Object *parent = nullptr);

    /**
     * @brief setCsr - the CSR with the public key.
     * This function needs to be called before start () obviously.
     */
    void setPrivateKey (QByteArray& privateKey);

public slots:
    void start () override;

protected:
    bool finished () override;
signals:

    /**
     * @brief jsonReceived - signal to report the json answer from ocs
     * @param json - the parsed json document
     * @param statusCode - the OCS status code : 100 (!) for success
     */
    void jsonReceived (QJsonDocument &json, int statusCode);

private:
    QBuffer _privKey;
};

/*
@brief Job to mark a folder as encrypted JSON

To be
\code
_job = new Set
 connect (
_job.start ();
\encode

@ingroup libsync
*/
class OWNCLOUDSYNC_EXPORT SetEncryptionFlagApiJob : AbstractNetworkJob {
public:
    enum FlagAction {
        Clear = 0,
        Set = 1
    };

    SetEncryptionFlagApiJob (AccountPtr &account, QByteArray &fileId, FlagAction flagAction = Set, GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray &fileId);
    void error (QByteArray &fileId, int httpReturnCode);

private:
    QByteArray _fileId;
    FlagAction _flagAction = Set;
};

class OWNCLOUDSYNC_EXPORT LockEncryptFolderApiJob : AbstractNetworkJob {
public:
    LockEncryptFolderApiJob (AccountPtr &account, QByteArray& fileId, GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& fileId, QByteArray& token);
    void error (QByteArray& fileId, int httpdErrorCode);

private:
    QByteArray _fileId;
};

class OWNCLOUDSYNC_EXPORT UnlockEncryptFolderApiJob : AbstractNetworkJob {
public:
    UnlockEncryptFolderApiJob (
        const AccountPtr &account,
        const QByteArray& fileId,
        const QByteArray& token,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& fileId);
    void error (QByteArray& fileId, int httpReturnCode);

private:
    QByteArray _fileId;
    QByteArray _token;
    QBuffer *_tokenBuf;
};

class OWNCLOUDSYNC_EXPORT StoreMetaDataApiJob : AbstractNetworkJob {
public:
    StoreMetaDataApiJob (
        const AccountPtr &account,
        const QByteArray& fileId,
        const QByteArray& b64Metadata,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& fileId);
    void error (QByteArray& fileId, int httpReturnCode);

private:
    QByteArray _fileId;
    QByteArray _b64Metadata;
};

class OWNCLOUDSYNC_EXPORT UpdateMetadataApiJob : AbstractNetworkJob {
public:
    UpdateMetadataApiJob (
        const AccountPtr &account,
        const QByteArray& fileId,
        const QByteArray& b64Metadata,
        const QByteArray& lockedToken,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& fileId);
    void error (QByteArray& fileId, int httpReturnCode);

private:
    QByteArray _fileId;
    QByteArray _b64Metadata;
    QByteArray _token;
};

class OWNCLOUDSYNC_EXPORT GetMetadataApiJob : AbstractNetworkJob {
public:
    GetMetadataApiJob (
        const AccountPtr &account,
        const QByteArray& fileId,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void jsonReceived (QJsonDocument &json, int statusCode);
    void error (QByteArray& fileId, int httpReturnCode);

private:
    QByteArray _fileId;
};

class OWNCLOUDSYNC_EXPORT DeleteMetadataApiJob : AbstractNetworkJob {
public:
    DeleteMetadataApiJob (
        const AccountPtr &account,
        const QByteArray& fileId,
        GLib.Object *parent = nullptr);

public slots:
    void start () override;

protected:
    bool finished () override;

signals:
    void success (QByteArray& fileId);
    void error (QByteArray& fileId, int httpErrorCode);

private:
    QByteArray _fileId;
};

}
#endif
