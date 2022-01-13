#ifndef CLIENTSIDEENCRYPTION_H
#define CLIENTSIDEENCRYPTION_H

// #include <QString>
// #include <QObject>
// #include <QJsonDocument>
// #include <QSslCertificate>
// #include <QSslKey>
// #include <QFile>
// #include <QVector>
// #include <QMap>

// #include <openssl/evp.h>

namespace QKeychain {
class Job;
class WritePasswordJob;
class ReadPasswordJob;
}

namespace OCC {

QString e2eeBaseUrl ();

namespace EncryptionHelper {
    QByteArray generateRandomFilename ();
    OWNCLOUDSYNC_EXPORT QByteArray generateRandom (int size);
    QByteArray generatePassword (QString &wordlist, QByteArray& salt);
    OWNCLOUDSYNC_EXPORT QByteArray encryptPrivateKey (
            const QByteArray& key,
            const QByteArray& privateKey,
            const QByteArray &salt
    );
    OWNCLOUDSYNC_EXPORT QByteArray decryptPrivateKey (
            const QByteArray& key,
            const QByteArray& data
    );
    OWNCLOUDSYNC_EXPORT QByteArray extractPrivateKeySalt (QByteArray &data);
    OWNCLOUDSYNC_EXPORT QByteArray encryptStringSymmetric (
            const QByteArray& key,
            const QByteArray& data
    );
    OWNCLOUDSYNC_EXPORT QByteArray decryptStringSymmetric (
            const QByteArray& key,
            const QByteArray& data
    );

    QByteArray privateKeyToPem (QByteArray key);

    //TODO: change those two EVP_PKEY into QSslKey.
    QByteArray encryptStringAsymmetric (
            EVP_PKEY *publicKey,
            const QByteArray& data
    );
    QByteArray decryptStringAsymmetric (
            EVP_PKEY *privateKey,
            const QByteArray& data
    );

    OWNCLOUDSYNC_EXPORT bool fileEncryption (QByteArray &key, QByteArray &iv,
                      QFile *input, QFile *output, QByteArray& returnTag);

    OWNCLOUDSYNC_EXPORT bool fileDecryption (QByteArray &key, QByteArray &iv,
                               QFile *input, QFile *output);

//
// Simple classes for safe (RAII) handling of OpenSSL
// data structures
//
class CipherCtx {
public:
    CipherCtx () : _ctx (EVP_CIPHER_CTX_new ()) {
    }

    ~CipherCtx () {
        EVP_CIPHER_CTX_free (_ctx);
    }

    operator EVP_CIPHER_CTX* () {
        return _ctx;
    }

private:
    Q_DISABLE_COPY (CipherCtx)
    EVP_CIPHER_CTX *_ctx;
};

class OWNCLOUDSYNC_EXPORT StreamingDecryptor {
public:
    StreamingDecryptor (QByteArray &key, QByteArray &iv, uint64 totalSize);
    ~StreamingDecryptor () = default;

    QByteArray chunkDecryption (char *input, uint64 chunkSize);

    bool isInitialized () const;
    bool isFinished () const;

private:
    Q_DISABLE_COPY (StreamingDecryptor)

    CipherCtx _ctx;
    bool _isInitialized = false;
    bool _isFinished = false;
    uint64 _decryptedSoFar = 0;
    uint64 _totalSize = 0;
};
}

class OWNCLOUDSYNC_EXPORT ClientSideEncryption : public QObject {
public:
    ClientSideEncryption ();
    void initialize (AccountPtr &account);

private:
    void generateKeyPair (AccountPtr &account);
    void generateCSR (AccountPtr &account, EVP_PKEY *keyPair);
    void encryptPrivateKey (AccountPtr &account);

public:
    void forgetSensitiveData (AccountPtr &account);

    bool newMnemonicGenerated () const;

public slots:
    void slotRequestMnemonic ();

private slots:
    void publicKeyFetched (QKeychain.Job *incoming);
    void privateKeyFetched (QKeychain.Job *incoming);
    void mnemonicKeyFetched (QKeychain.Job *incoming);

signals:
    void initializationFinished ();
    void mnemonicGenerated (QString& mnemonic);
    void showMnemonic (QString& mnemonic);

private:
    void getPrivateKeyFromServer (AccountPtr &account);
    void getPublicKeyFromServer (AccountPtr &account);
    void fetchAndValidatePublicKeyFromServer (AccountPtr &account);
    void decryptPrivateKey (AccountPtr &account, QByteArray &key);

    void fetchFromKeyChain (AccountPtr &account);

    bool checkPublicKeyValidity (AccountPtr &account) const;
    bool checkServerPublicKeyValidity (QByteArray &serverPublicKeyString) const;
    void writePrivateKey (AccountPtr &account);
    void writeCertificate (AccountPtr &account);
    void writeMnemonic (AccountPtr &account);

    bool isInitialized = false;

public:
    //QSslKey _privateKey;
    QByteArray _privateKey;
    QSslKey _publicKey;
    QSslCertificate _certificate;
    QString _mnemonic;
    bool _newMnemonicGenerated = false;
};

/* Generates the Metadata for the folder */
struct EncryptedFile {
    QByteArray encryptionKey;
    QByteArray mimetype;
    QByteArray initializationVector;
    QByteArray authenticationTag;
    QString encryptedFilename;
    QString originalFilename;
    int fileVersion;
    int metadataKey;
};

class OWNCLOUDSYNC_EXPORT FolderMetadata {
public:
    FolderMetadata (AccountPtr account, QByteArray& metadata = QByteArray (), int statusCode = -1);
    QByteArray encryptedMetadata ();
    void addEncryptedFile (EncryptedFile& f);
    void removeEncryptedFile (EncryptedFile& f);
    void removeAllEncryptedFiles ();
    QVector<EncryptedFile> files () const;

private:
    /* Use std.string and std.vector internally on this class
     * to ease the port to Nlohmann Json API
     */
    void setupEmptyMetadata ();
    void setupExistingMetadata (QByteArray& metadata);

    QByteArray encryptMetadataKey (QByteArray& metadataKey) const;
    QByteArray decryptMetadataKey (QByteArray& encryptedKey) const;

    QByteArray encryptJsonObject (QByteArray& obj, QByteArray pass) const;
    QByteArray decryptJsonObject (QByteArray& encryptedJsonBlob, QByteArray& pass) const;

    QVector<EncryptedFile> _files;
    QMap<int, QByteArray> _metadataKeys;
    AccountPtr _account;
    QVector<QPair<QString, QString>> _sharing;
};

} // namespace OCC
#endif
