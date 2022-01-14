/***********************************************************
Copyright (C) by Michael Schuster <michael@schuster.ms>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QApplication>

using namespace QKeychain;

// #pragma once

// #include <GLib.Object>
// #include <qt5keychain/keychain.h>

// We don't support insecure fallback
// const int KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK

namespace Occ {

namespace KeychainChunk {

/***********************************************************
* Workaround for Windows:
*
* Split the keychain entry's data into chunks of 2048 bytes,
* to allow 4k (4096 bit) keys / large certs to be saved (see limits in webflowcredentials.h)
***********************************************************/
static constexpr int Chunk_size = 2048;
static constexpr int Max_chunks = 10;

/***********************************************************
@brief : Abstract base class for KeychainChunk jobs.
***********************************************************/
class Job : GLib.Object {
public:
    Job (GLib.Object *parent = nullptr);

    ~Job () override;

    QKeychain.Error error ();
    string error_string ();

    QByteArray binary_data ();
    string text_data ();

    bool insecure_fallback ();

// If we use it but don't support insecure fallback, give us nice compilation errors ;p
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    void set_insecure_fallback (bool insecure_fallback);
#endif

    /***********************************************************
    @return Whether this job autodeletes itself once finished () has been emitted. Default is true.
    @see set_auto_delete ()
    ***********************************************************/
    bool auto_delete ();

    /***********************************************************
    Set whether this job should autodelete itself once finished () has been emitted.
    @see auto_delete ()
    ***********************************************************/
    void set_auto_delete (bool auto_delete);

protected:
    string _service_name;
    Account *_account;
    string _key;
    bool _insecure_fallback = false;
    bool _auto_delete = true;
    bool _keychain_migration = false;

    QKeychain.Error _error = QKeychain.NoError;
    string _error_string;

    int _chunk_count = 0;
    QByteArray _chunk_buffer;
}; // class Job

/***********************************************************
* @brief : Simple wrapper class for QKeychain.WritePasswordJob, splits too large keychain entry's data into chunks on Windows
***********************************************************/
class WriteJob : KeychainChunk.Job {
public:
    WriteJob (Account *account, string &key, QByteArray &data, GLib.Object *parent = nullptr);
    WriteJob (string &key, QByteArray &data, GLib.Object *parent = nullptr);

    /***********************************************************
    Call this method to start the job (async).
    You should connect some slot to the finished () signal first.
    
    @see QKeychain.Job.start ()
    ***********************************************************/
    void start ();

    /***********************************************************
    Call this method to start the job synchronously.
    Awaits completion with no need to connect some slot to the finished () signal first.
    
    @return Returns true on succeess (QKeychain.NoError).
    ***********************************************************/
    bool exec ();

signals:
    void finished (KeychainChunk.WriteJob *incoming_job);

private slots:
    void slot_write_job_done (QKeychain.Job *incoming_job);
}; // class WriteJob

/***********************************************************
* @brief : Simple wrapper class for QKeychain.ReadPasswordJob, splits too large keychain entry's data into chunks on Windows
***********************************************************/
class ReadJob : KeychainChunk.Job {
public:
    ReadJob (Account *account, string &key, bool keychain_migration, GLib.Object *parent = nullptr);
    ReadJob (string &key, GLib.Object *parent = nullptr);

    /***********************************************************
    Call this method to start the job (async).
    You should connect some slot to the finished () signal first.
    
    @see QKeychain.Job.start ()
    ***********************************************************/
    void start ();

    /***********************************************************
    Call this method to start the job synchronously.
    Awaits completion with no need to connect some slot to the finished () signal first.
    
    @return Returns true on succeess (QKeychain.NoError).
    ***********************************************************/
    bool exec ();

signals:
    void finished (KeychainChunk.ReadJob *incoming_job);

private slots:
    void slot_read_job_done (QKeychain.Job *incoming_job);

private:
    bool _retry_on_key_chain_error = true; // true if we haven't done yet any reading from keychain
}; // class ReadJob

/***********************************************************
* @brief : Simple wrapper class for QKeychain.DeletePasswordJob
***********************************************************/
class DeleteJob : KeychainChunk.Job {
public:
    DeleteJob (Account *account, string &key, bool keychain_migration, GLib.Object *parent = nullptr);
    DeleteJob (string &key, GLib.Object *parent = nullptr);

    /***********************************************************
    Call this method to start the job (async).
    You should connect some slot to the finished () signal first.
    
    @see QKeychain.Job.start ()
    ***********************************************************/
    void start ();

    /***********************************************************
    Call this method to start the job synchronously.
    Awaits completion with no need to connect some slot to the finished () signal first.
    
    @return Returns true on succeess (QKeychain.NoError).
    ***********************************************************/
    bool exec ();

signals:
    void finished (KeychainChunk.DeleteJob *incoming_job);

private slots:
    void slot_delete_job_done (QKeychain.Job *incoming_job);
}; // class DeleteJob



#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
static void add_settings_to_job (Account *account, QKeychain.Job *job) {
    Q_UNUSED (account)
    auto settings = ConfigFile.settings_with_group (Theme.instance ().app_name ());
    settings.set_parent (job); // make the job parent to make setting deleted properly
    job.set_settings (settings.release ());
}
#endif

/***********************************************************
Job
***********************************************************/
Job.Job (GLib.Object *parent)
    : GLib.Object (parent) {
    _service_name = Theme.instance ().app_name ();
}

Job.~Job () {
    _chunk_count = 0;
    _chunk_buffer.clear ();
}

QKeychain.Error Job.error () {
    return _error;
}

string Job.error_string () {
    return _error_string;
}

QByteArray Job.binary_data () {
    return _chunk_buffer;
}

string Job.text_data () {
    return _chunk_buffer;
}

bool Job.insecure_fallback () {
    return _insecure_fallback;
}

#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
void Job.set_insecure_fallback (bool insecure_fallback) {
    _insecure_fallback = insecure_fallback;
}
#endif

bool Job.auto_delete () {
    return _auto_delete;
}

void Job.set_auto_delete (bool auto_delete) {
    _auto_delete = auto_delete;
}

/***********************************************************
* WriteJob
***********************************************************/
WriteJob.WriteJob (Account *account, string &key, QByteArray &data, GLib.Object *parent)
    : Job (parent) {
    _account = account;
    _key = key;

    // Windows workaround : Split the private key into chunks of 2048 bytes,
    // to allow 4k (4096 bit) keys to be saved (obey Windows's limits)
    _chunk_buffer = data;
    _chunk_count = 0;
}

WriteJob.WriteJob (string &key, QByteArray &data, GLib.Object *parent)
    : WriteJob (nullptr, key, data, parent) {
}

void WriteJob.start () {
    _error = QKeychain.NoError;

    slot_write_job_done (nullptr);
}

bool WriteJob.exec () {
    start ();

    QEvent_loop wait_loop;
    connect (this, &WriteJob.finished, &wait_loop, &QEvent_loop.quit);
    wait_loop.exec ();

    if (error () != NoError) {
        q_c_warning (lc_keychain_chunk) << "WritePasswordJob failed with" << error_string ();
        return false;
    }

    return true;
}

void WriteJob.slot_write_job_done (QKeychain.Job *incoming_job) {
    auto write_job = qobject_cast<QKeychain.WritePasswordJob> (incoming_job);

    // Errors? (write_job can be nullptr here, see : WriteJob.start)
    if (write_job) {
        _error = write_job.error ();
        _error_string = write_job.error_string ();

        if (write_job.error () != NoError) {
            q_c_warning (lc_keychain_chunk) << "Error while writing" << write_job.key () << "chunk" << write_job.error_string ();
            _chunk_buffer.clear ();
        }
    }

    // write a chunk if there is any in the buffer
    if (!_chunk_buffer.is_empty ()) {
        // write full data in one chunk on non-Windows, as usual
        auto chunk = _chunk_buffer;

        _chunk_buffer.clear ();

        auto index = (_chunk_count++);

        // keep the limit
        if (_chunk_count > KeychainChunk.Max_chunks) {
            q_c_warning (lc_keychain_chunk) << "Maximum chunk count exceeded while writing" << write_job.key () << "chunk" << string.number (index) << "cutting off after" << string.number (KeychainChunk.Max_chunks) << "chunks";

            write_job.delete_later ();

            _chunk_buffer.clear ();

            emit finished (this);

            if (_auto_delete) {
                delete_later ();
            }
            return;
        }

        const string key_with_index = _key + (index > 0 ? (string (".") + string.number (index)) : string ());
        const string kck = _account ? AbstractCredentials.keychain_key (
                _account.url ().to_string (),
                key_with_index,
                _account.id ()
            ) : key_with_index;

        auto job = new QKeychain.WritePasswordJob (_service_name, this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
        add_settings_to_job (_account, job);
#endif
        job.set_insecure_fallback (_insecure_fallback);
        connect (job, &QKeychain.Job.finished, this, &KeychainChunk.WriteJob.slot_write_job_done);
        // only add the key's (sub)"index" after the first element, to stay compatible with older versions and non-Windows
        job.set_key (kck);
        job.set_binary_data (chunk);
        job.start ();

        chunk.clear ();
    } else {
        emit finished (this);

        if (_auto_delete) {
            delete_later ();
        }
    }

    write_job.delete_later ();
}

/***********************************************************
* ReadJob
***********************************************************/
ReadJob.ReadJob (Account *account, string &key, bool keychain_migration, GLib.Object *parent)
    : Job (parent) {
    _account = account;
    _key = key;

    _keychain_migration = keychain_migration;

    _chunk_count = 0;
    _chunk_buffer.clear ();
}

ReadJob.ReadJob (string &key, GLib.Object *parent)
    : ReadJob (nullptr, key, false, parent) {
}

void ReadJob.start () {
    _chunk_count = 0;
    _chunk_buffer.clear ();
    _error = QKeychain.NoError;

    const string kck = _account ? AbstractCredentials.keychain_key (
            _account.url ().to_string (),
            _key,
            _keychain_migration ? string () : _account.id ()
        ) : _key;

    auto job = new QKeychain.ReadPasswordJob (_service_name, this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    add_settings_to_job (_account, job);
#endif
    job.set_insecure_fallback (_insecure_fallback);
    job.set_key (kck);
    connect (job, &QKeychain.Job.finished, this, &KeychainChunk.ReadJob.slot_read_job_done);
    job.start ();
}

bool ReadJob.exec () {
    start ();

    QEvent_loop wait_loop;
    connect (this, &ReadJob.finished, &wait_loop, &QEvent_loop.quit);
    wait_loop.exec ();

    if (error () == NoError) {
        return true;
    }

    _chunk_count = 0;
    _chunk_buffer.clear ();
    if (error () != EntryNotFound) {
        q_c_warning (lc_keychain_chunk) << "ReadPasswordJob failed with" << error_string ();
    }
    return false;
}

void ReadJob.slot_read_job_done (QKeychain.Job *incoming_job) {
    // Errors or next chunk?
    auto read_job = qobject_cast<QKeychain.ReadPasswordJob> (incoming_job);
    Q_ASSERT (read_job);

    if (read_job.error () == NoError && !read_job.binary_data ().is_empty ()) {
        _chunk_buffer.append (read_job.binary_data ());
        _chunk_count++;
    } else {
        if (!read_job.insecure_fallback ()) { // If insecure_fallback is set, the next test would be pointless
            if (_retry_on_key_chain_error && (read_job.error () == QKeychain.No_backend_available
                    || read_job.error () == QKeychain.Other_error)) {
                // Could be that the backend was not yet available. Wait some extra seconds.
                // (Issues #4274 and #6522)
                // (For kwallet, the error is Other_error instead of No_backend_available, maybe a bug in QtKeychain)
                q_c_info (lc_keychain_chunk) << "Backend unavailable (yet?) Retrying in a few seconds." << read_job.error_string ();
                QTimer.single_shot (10000, this, &ReadJob.start);
                _retry_on_key_chain_error = false;
                read_job.delete_later ();
                return;
            }
            _retry_on_key_chain_error = false;
        }
        if (read_job.error () != QKeychain.EntryNotFound ||
            ( (read_job.error () == QKeychain.EntryNotFound) && _chunk_count == 0)) {
            _error = read_job.error ();
            _error_string = read_job.error_string ();
            q_c_warning (lc_keychain_chunk) << "Unable to read" << read_job.key () << "chunk" << string.number (_chunk_count) << read_job.error_string ();
        }
    }

    read_job.delete_later ();

    emit finished (this);

    if (_auto_delete) {
        delete_later ();
    }
}

/***********************************************************
* DeleteJob
***********************************************************/
DeleteJob.DeleteJob (Account *account, string &key, bool keychain_migration, GLib.Object *parent)
    : Job (parent) {
    _account = account;
    _key = key;

    _keychain_migration = keychain_migration;
}

DeleteJob.DeleteJob (string &key, GLib.Object *parent)
    : DeleteJob (nullptr, key, false, parent) {
}

void DeleteJob.start () {
    _chunk_count = 0;
    _error = QKeychain.NoError;

    const string kck = _account ? AbstractCredentials.keychain_key (
            _account.url ().to_string (),
            _key,
            _keychain_migration ? string () : _account.id ()
        ) : _key;

    auto job = new QKeychain.DeletePasswordJob (_service_name, this);
#if defined (KEYCHAINCHUNK_ENABLE_INSECURE_FALLBACK)
    add_settings_to_job (_account, job);
#endif
    job.set_insecure_fallback (_insecure_fallback);
    job.set_key (kck);
    connect (job, &QKeychain.Job.finished, this, &KeychainChunk.DeleteJob.slot_delete_job_done);
    job.start ();
}

bool DeleteJob.exec () {
    start ();

    QEvent_loop wait_loop;
    connect (this, &DeleteJob.finished, &wait_loop, &QEvent_loop.quit);
    wait_loop.exec ();

    if (error () == NoError) {
        return true;
    }

    _chunk_count = 0;
    if (error () != EntryNotFound) {
        q_c_warning (lc_keychain_chunk) << "DeletePasswordJob failed with" << error_string ();
    }
    return false;
}

void DeleteJob.slot_delete_job_done (QKeychain.Job *incoming_job) {
    // Errors or next chunk?
    auto delete_job = qobject_cast<QKeychain.DeletePasswordJob> (incoming_job);
    Q_ASSERT (delete_job);

    if (delete_job.error () == NoError) {
        _chunk_count++;
    } else {
        if (delete_job.error () != QKeychain.EntryNotFound ||
            ( (delete_job.error () == QKeychain.EntryNotFound) && _chunk_count == 0)) {
            _error = delete_job.error ();
            _error_string = delete_job.error_string ();
            q_c_warning (lc_keychain_chunk) << "Unable to delete" << delete_job.key () << "chunk" << string.number (_chunk_count) << delete_job.error_string ();
        }
    }

    delete_job.delete_later ();

    emit finished (this);

    if (_auto_delete) {
        delete_later ();
    }
}

} // namespace KeychainChunk

} // namespace Occ
