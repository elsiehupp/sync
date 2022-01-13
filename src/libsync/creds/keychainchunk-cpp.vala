/*
Copyright (C) by Michael Schuster <michael@schuster.ms>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/

// #include <QApplication>

using namespace QKeychain;

namespace Occ {

Q_LOGGING_CATEGORY (lcKeychainChunk, "nextcloud.sync.credentials.keychainchunk", QtInfoMsg)

namespace KeychainChunk {

#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
static void addSettingsToJob (Account *account, QKeychain.Job *job) {
    Q_UNUSED (account)
    auto settings = ConfigFile.settingsWithGroup (Theme.instance ().appName ());
    settings.setParent (job); // make the job parent to make setting deleted properly
    job.setSettings (settings.release ());
}
#endif

/*
* Job
*/
Job.Job (GLib.Object *parent)
    : GLib.Object (parent) {
    _serviceName = Theme.instance ().appName ();
}

Job.~Job () {
    _chunkCount = 0;
    _chunkBuffer.clear ();
}

QKeychain.Error Job.error () {
    return _error;
}

QString Job.errorString () {
    return _errorString;
}

QByteArray Job.binaryData () {
    return _chunkBuffer;
}

QString Job.textData () {
    return _chunkBuffer;
}

bool Job.insecureFallback () {
    return _insecureFallback;
}

#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
void Job.setInsecureFallback (bool insecureFallback) {
    _insecureFallback = insecureFallback;
}
#endif

bool Job.autoDelete () {
    return _autoDelete;
}

void Job.setAutoDelete (bool autoDelete) {
    _autoDelete = autoDelete;
}

/*
* WriteJob
*/
WriteJob.WriteJob (Account *account, QString &key, QByteArray &data, GLib.Object *parent)
    : Job (parent) {
    _account = account;
    _key = key;

    // Windows workaround : Split the private key into chunks of 2048 bytes,
    // to allow 4k (4096 bit) keys to be saved (obey Windows's limits)
    _chunkBuffer = data;
    _chunkCount = 0;
}

WriteJob.WriteJob (QString &key, QByteArray &data, GLib.Object *parent)
    : WriteJob (nullptr, key, data, parent) {
}

void WriteJob.start () {
    _error = QKeychain.NoError;

    slotWriteJobDone (nullptr);
}

bool WriteJob.exec () {
    start ();

    QEventLoop waitLoop;
    connect (this, &WriteJob.finished, &waitLoop, &QEventLoop.quit);
    waitLoop.exec ();

    if (error () != NoError) {
        qCWarning (lcKeychainChunk) << "WritePasswordJob failed with" << errorString ();
        return false;
    }

    return true;
}

void WriteJob.slotWriteJobDone (QKeychain.Job *incomingJob) {
    auto writeJob = qobject_cast<QKeychain.WritePasswordJob> (incomingJob);

    // Errors? (writeJob can be nullptr here, see : WriteJob.start)
    if (writeJob) {
        _error = writeJob.error ();
        _errorString = writeJob.errorString ();

        if (writeJob.error () != NoError) {
            qCWarning (lcKeychainChunk) << "Error while writing" << writeJob.key () << "chunk" << writeJob.errorString ();
            _chunkBuffer.clear ();
        }
    }

    // write a chunk if there is any in the buffer
    if (!_chunkBuffer.isEmpty ()) {
        // write full data in one chunk on non-Windows, as usual
        auto chunk = _chunkBuffer;

        _chunkBuffer.clear ();

        auto index = (_chunkCount++);

        // keep the limit
        if (_chunkCount > KeychainChunk.MaxChunks) {
            qCWarning (lcKeychainChunk) << "Maximum chunk count exceeded while writing" << writeJob.key () << "chunk" << QString.number (index) << "cutting off after" << QString.number (KeychainChunk.MaxChunks) << "chunks";

            writeJob.deleteLater ();

            _chunkBuffer.clear ();

            emit finished (this);

            if (_autoDelete) {
                deleteLater ();
            }
            return;
        }

        const QString keyWithIndex = _key + (index > 0 ? (QString (".") + QString.number (index)) : QString ());
        const QString kck = _account ? AbstractCredentials.keychainKey (
                _account.url ().toString (),
                keyWithIndex,
                _account.id ()
            ) : keyWithIndex;

        auto job = new QKeychain.WritePasswordJob (_serviceName, this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
        addSettingsToJob (_account, job);
#endif
        job.setInsecureFallback (_insecureFallback);
        connect (job, &QKeychain.Job.finished, this, &KeychainChunk.WriteJob.slotWriteJobDone);
        // only add the key's (sub)"index" after the first element, to stay compatible with older versions and non-Windows
        job.setKey (kck);
        job.setBinaryData (chunk);
        job.start ();

        chunk.clear ();
    } else {
        emit finished (this);

        if (_autoDelete) {
            deleteLater ();
        }
    }

    writeJob.deleteLater ();
}

/*
* ReadJob
*/
ReadJob.ReadJob (Account *account, QString &key, bool keychainMigration, GLib.Object *parent)
    : Job (parent) {
    _account = account;
    _key = key;

    _keychainMigration = keychainMigration;

    _chunkCount = 0;
    _chunkBuffer.clear ();
}

ReadJob.ReadJob (QString &key, GLib.Object *parent)
    : ReadJob (nullptr, key, false, parent) {
}

void ReadJob.start () {
    _chunkCount = 0;
    _chunkBuffer.clear ();
    _error = QKeychain.NoError;

    const QString kck = _account ? AbstractCredentials.keychainKey (
            _account.url ().toString (),
            _key,
            _keychainMigration ? QString () : _account.id ()
        ) : _key;

    auto job = new QKeychain.ReadPasswordJob (_serviceName, this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    addSettingsToJob (_account, job);
#endif
    job.setInsecureFallback (_insecureFallback);
    job.setKey (kck);
    connect (job, &QKeychain.Job.finished, this, &KeychainChunk.ReadJob.slotReadJobDone);
    job.start ();
}

bool ReadJob.exec () {
    start ();

    QEventLoop waitLoop;
    connect (this, &ReadJob.finished, &waitLoop, &QEventLoop.quit);
    waitLoop.exec ();

    if (error () == NoError) {
        return true;
    }

    _chunkCount = 0;
    _chunkBuffer.clear ();
    if (error () != EntryNotFound) {
        qCWarning (lcKeychainChunk) << "ReadPasswordJob failed with" << errorString ();
    }
    return false;
}

void ReadJob.slotReadJobDone (QKeychain.Job *incomingJob) {
    // Errors or next chunk?
    auto readJob = qobject_cast<QKeychain.ReadPasswordJob> (incomingJob);
    Q_ASSERT (readJob);

    if (readJob.error () == NoError && !readJob.binaryData ().isEmpty ()) {
        _chunkBuffer.append (readJob.binaryData ());
        _chunkCount++;
    } else {
        if (!readJob.insecureFallback ()) { // If insecureFallback is set, the next test would be pointless
            if (_retryOnKeyChainError && (readJob.error () == QKeychain.NoBackendAvailable
                    || readJob.error () == QKeychain.OtherError)) {
                // Could be that the backend was not yet available. Wait some extra seconds.
                // (Issues #4274 and #6522)
                // (For kwallet, the error is OtherError instead of NoBackendAvailable, maybe a bug in QtKeychain)
                qCInfo (lcKeychainChunk) << "Backend unavailable (yet?) Retrying in a few seconds." << readJob.errorString ();
                QTimer.singleShot (10000, this, &ReadJob.start);
                _retryOnKeyChainError = false;
                readJob.deleteLater ();
                return;
            }
            _retryOnKeyChainError = false;
        }
        if (readJob.error () != QKeychain.EntryNotFound ||
            ( (readJob.error () == QKeychain.EntryNotFound) && _chunkCount == 0)) {
            _error = readJob.error ();
            _errorString = readJob.errorString ();
            qCWarning (lcKeychainChunk) << "Unable to read" << readJob.key () << "chunk" << QString.number (_chunkCount) << readJob.errorString ();
        }
    }

    readJob.deleteLater ();

    emit finished (this);

    if (_autoDelete) {
        deleteLater ();
    }
}

/*
* DeleteJob
*/
DeleteJob.DeleteJob (Account *account, QString &key, bool keychainMigration, GLib.Object *parent)
    : Job (parent) {
    _account = account;
    _key = key;

    _keychainMigration = keychainMigration;
}

DeleteJob.DeleteJob (QString &key, GLib.Object *parent)
    : DeleteJob (nullptr, key, false, parent) {
}

void DeleteJob.start () {
    _chunkCount = 0;
    _error = QKeychain.NoError;

    const QString kck = _account ? AbstractCredentials.keychainKey (
            _account.url ().toString (),
            _key,
            _keychainMigration ? QString () : _account.id ()
        ) : _key;

    auto job = new QKeychain.DeletePasswordJob (_serviceName, this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    addSettingsToJob (_account, job);
#endif
    job.setInsecureFallback (_insecureFallback);
    job.setKey (kck);
    connect (job, &QKeychain.Job.finished, this, &KeychainChunk.DeleteJob.slotDeleteJobDone);
    job.start ();
}

bool DeleteJob.exec () {
    start ();

    QEventLoop waitLoop;
    connect (this, &DeleteJob.finished, &waitLoop, &QEventLoop.quit);
    waitLoop.exec ();

    if (error () == NoError) {
        return true;
    }

    _chunkCount = 0;
    if (error () != EntryNotFound) {
        qCWarning (lcKeychainChunk) << "DeletePasswordJob failed with" << errorString ();
    }
    return false;
}

void DeleteJob.slotDeleteJobDone (QKeychain.Job *incomingJob) {
    // Errors or next chunk?
    auto deleteJob = qobject_cast<QKeychain.DeletePasswordJob> (incomingJob);
    Q_ASSERT (deleteJob);

    if (deleteJob.error () == NoError) {
        _chunkCount++;
    } else {
        if (deleteJob.error () != QKeychain.EntryNotFound ||
            ( (deleteJob.error () == QKeychain.EntryNotFound) && _chunkCount == 0)) {
            _error = deleteJob.error ();
            _errorString = deleteJob.errorString ();
            qCWarning (lcKeychainChunk) << "Unable to delete" << deleteJob.key () << "chunk" << QString.number (_chunkCount) << deleteJob.errorString ();
        }
    }

    deleteJob.deleteLater ();

    emit finished (this);

    if (_autoDelete) {
        deleteLater ();
    }
}

} // namespace KeychainChunk

} // namespace Occ
