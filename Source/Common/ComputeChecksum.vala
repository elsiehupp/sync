/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<LGPLv2.1-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <qtconcurrentrun.h>
// #include <QCryptographicHash>

#ifdef ZLIB_FOUND
// #include <zlib.h>
#endif

/***********************************************************
\file checksums.cpp

\brief Computing and validating file checksums

Overview
--------

Checksums are used in two

- to guard uploads and downloads against data corr
  (transmission checksum)
- to quickly check whether the content of a file has changed
  to avoid redundant uploads (content checksum)

In principle both are ind
algorithms can be used. To avoid redundant computations, it can
make sense to use the same checksum algorithm though.

Transmission Checksums
----------------------

The usage of transmission checksums is currently optional and need
to be explic
the '[General]' section of the config file.

When enabled, the
the server in the OC

On download, the header with the same name is read and if the
received data does not have the expected checksum, the download is
rejected.

Transmission checks
in the database.

Conte
------

Sometimes the metadata of a local file changes while the content stays
unchanged. Content checksums allow the sync client to avoid uploading
the same data again by comparing the file's actual checksum to the
checksum stored in the database.

Content checksums a

Checksum Algorithms
-----

- Adler3
- MD5
- SHA1
- SHA256
- SHA3-256 (requires Qt 5.9)

***********************************************************/

// #pragma once

// #include <GLib.Object>
// #include <QByteArray>
// #include <QFuture_watcher>

// #include <memory>


namespace Occ {

/***********************************************************
Tags for checksum headers values.
They are here for being shared between Upload- and Download Job
***********************************************************/
static const char check_sum_mD5C[] = "MD5";
static const char check_sum_sHA1C[] = "SHA1";
static const char check_sum_sHA2C[] = "SHA256";
static const char check_sum_sHA3C[] = "SHA3-256";
static const char check_sum_adler_c[] = "Adler32";


/***********************************************************
Returns the highest-quality checksum in a 'checksums'
property retrieved from the server.

Example : "ADLER32:1231 SHA1:ab124124 MD5:2131affa21"
      . "SHA1:ab124124"
***********************************************************/
OCSYNC_EXPORT QByteArray find_best_checksum (QByteArray &checksums);

/// Creates a checksum header from type and value.
OCSYNC_EXPORT QByteArray make_checksum_header (QByteArray &checksum_type, QByteArray &checksum);

/// Parses a checksum header
OCSYNC_EXPORT bool parse_checksum_header (QByteArray &header, QByteArray *type, QByteArray *checksum);

/// Convenience for getting the type from a checksum header, null if none
OCSYNC_EXPORT QByteArray parse_checksum_header_type (QByteArray &header);

/// Checks OWNCLOUD_DISABLE_CHECKSUM_UPLOAD
OCSYNC_EXPORT bool upload_checksum_enabled ();

// Exported functions for the tests.
QByteArray OCSYNC_EXPORT calc_md5 (QIODevice *device);
QByteArray OCSYNC_EXPORT calc_sha1 (QIODevice *device);
#ifdef ZLIB_FOUND
QByteArray OCSYNC_EXPORT calc_adler32 (QIODevice *device);
#endif

/***********************************************************
Computes the checksum of a file.
\ingroup libsync
***********************************************************/
class ComputeChecksum : GLib.Object {

    public ComputeChecksum (GLib.Object *parent = nullptr);
    public ~ComputeChecksum () override;

    /***********************************************************
    Sets the checksum type to be used. The default is empty.
    ***********************************************************/
    public void set_checksum_type (QByteArray &type);

    public QByteArray checksum_type ();

    /***********************************************************
    Computes the checksum for the given file path.
    
    done () is emitted when the calculation finishes.
    ***********************************************************/
    public void start (string &file_path);

    /***********************************************************
    Computes the checksum for the given device.
    
    done () is emitted when the calculation finishes.
    
    The device ownership transfers into the thread that
    will compute the checksum. It must not have a parent.
    ***********************************************************/
    public void start (std.unique_ptr<QIODevice> device);

    /***********************************************************
    Computes the checksum synchronously.
    ***********************************************************/
    public static QByteArray compute_now (QIODevice *device, QByteArray &checksum_type);

    /***********************************************************
    Computes the checksum synchronously on file. Convenience wrapper for compute_now ().
    ***********************************************************/
    public static QByteArray compute_now_on_file (string &file_path, QByteArray &checksum_type);

signals:
    void done (QByteArray &checksum_type, QByteArray &checksum);

private slots:
    void slot_calculation_done ();

private:
    void start_impl (std.unique_ptr<QIODevice> device);

    QByteArray _checksum_type;

    // watcher for the checksum calculation thread
    QFuture_watcher<QByteArray> _watcher;
};

/***********************************************************
Checks whether a file's checksum matches the expected value.
@ingroup libsync
***********************************************************/
class Validate_checksum_header : GLib.Object {

    public Validate_checksum_header (GLib.Object *parent = nullptr);

    /***********************************************************
    Check a file's actual checksum against the provided checksum_header
    
    If no checksum is there, or if a correct checksum is there, the signal validated (
    will be emitted. In case of any kind of error, the signal validation_failed () will
    be emitted.
    ***********************************************************/
    public void start (string &file_path, QByteArray &checksum_header);

    /***********************************************************
    Check a device's actual checksum against the provided checksum_header
    
    Like the other start () but works on an device.
    
    The device ownership transfers into the thread that
    will compute the checksum. It must not have a parent.
    ***********************************************************/
    public void start (std.unique_ptr<QIODevice> device, QByteArray &checksum_header);

signals:
    void validated (QByteArray &checksum_type, QByteArray &checksum);
    void validation_failed (string &err_msg);

private slots:
    void slot_checksum_calculated (QByteArray &checksum_type, QByteArray &checksum);

private:
    ComputeChecksum *prepare_start (QByteArray &checksum_header);

    QByteArray _expected_checksum_type;
    QByteArray _expected_checksum;
};

/***********************************************************
Hooks checksum computations into csync.
@ingroup libsync
***********************************************************/
class CSyncChecksumHook : GLib.Object {

    public CSyncChecksumHook ();

    /***********************************************************
    Returns the checksum value for \a path that is comparable to \a other_checksum.
    
    Called from csync, whe
    to be set as userdata.
    The return value will be owned by csync.
    ***********************************************************/
    public static QByteArray hook (QByteArray &path, QByteArray &other_checksum_header, void *this_obj);
};



const int BUFSIZE int64 (500 * 1024) // 500 Ki_b

static QByteArray calc_crypto_hash (QIODevice *device, QCryptographicHash.Algorithm algo) {
    QByteArray arr;
    QCryptographicHash crypto ( algo );

    if (crypto.add_data (device)) {
        arr = crypto.result ().to_hex ();
    }
    return arr;
}

QByteArray calc_md5 (QIODevice *device) {
    return calc_crypto_hash (device, QCryptographicHash.Md5);
}

QByteArray calc_sha1 (QIODevice *device) {
    return calc_crypto_hash (device, QCryptographicHash.Sha1);
}

#ifdef ZLIB_FOUND
QByteArray calc_adler32 (QIODevice *device) { {f (device.size () == 0)
    {
        return QByteArray ();
    }
    QByteArray buf (BUFSIZE, Qt.Uninitialized);

    unsigned int adler = adler32 (0L, Z_NULL, 0);
    int64 size = 0;
    while (!device.at_end ()) {
        size = device.read (buf.data (), BUFSIZE);
        if (size > 0)
            adler = adler32 (adler, (Bytef *)buf.data (), size);
    }

    return QByteArray.number (adler, 16);
}
#endif

QByteArray make_checksum_header (QByteArray &checksum_type, QByteArray &checksum) {
    if (checksum_type.is_empty () || checksum.is_empty ())
        return QByteArray ();
    QByteArray header = checksum_type;
    header.append (':');
    header.append (checksum);
    return header;
}

QByteArray find_best_checksum (QByteArray &_checksums) {
    if (_checksums.is_empty ()) {
        return {};
    }
    const auto checksums = string.from_utf8 (_checksums);
    int i = 0;
    // The order of the searches here defines the preference ordering.
    if (-1 != (i = checksums.index_of (QLatin1String ("SHA3-256:"), 0, Qt.CaseInsensitive))
        || -1 != (i = checksums.index_of (QLatin1String ("SHA256:"), 0, Qt.CaseInsensitive))
        || -1 != (i = checksums.index_of (QLatin1String ("SHA1:"), 0, Qt.CaseInsensitive))
        || -1 != (i = checksums.index_of (QLatin1String ("MD5:"), 0, Qt.CaseInsensitive))
        || -1 != (i = checksums.index_of (QLatin1String ("ADLER32:"), 0, Qt.CaseInsensitive))) {
        // Now i is the start of the best checksum
        // Grab it until the next space or end of xml or end of string.
        int end = _checksums.index_of (' ', i);
        // workaround for https://github.com/owncloud/core/pull/38304
        if (end == -1) {
            end = _checksums.index_of ('<', i);
        }
        return _checksums.mid (i, end - i);
    }
    q_c_warning (lc_checksums) << "Failed to parse" << _checksums;
    return {};
}

bool parse_checksum_header (QByteArray &header, QByteArray *type, QByteArray *checksum) {
    if (header.is_empty ()) {
        type.clear ();
        checksum.clear ();
        return true;
    }

    const auto idx = header.index_of (':');
    if (idx < 0) {
        return false;
    }

    *type = header.left (idx);
    *checksum = header.mid (idx + 1);
    return true;
}

QByteArray parse_checksum_header_type (QByteArray &header) {
    const auto idx = header.index_of (':');
    if (idx < 0) {
        return QByteArray ();
    }
    return header.left (idx);
}

bool upload_checksum_enabled () {
    static bool enabled = q_environment_variable_is_empty ("OWNCLOUD_DISABLE_CHECKSUM_UPLOAD");
    return enabled;
}

static bool checksum_computation_enabled () {
    static bool enabled = q_environment_variable_is_empty ("OWNCLOUD_DISABLE_CHECKSUM_COMPUTATIONS");
    return enabled;
}

ComputeChecksum.ComputeChecksum (GLib.Object *parent)
    : GLib.Object (parent) {
}

ComputeChecksum.~ComputeChecksum () = default;

void ComputeChecksum.set_checksum_type (QByteArray &type) {
    _checksum_type = type;
}

QByteArray ComputeChecksum.checksum_type () {
    return _checksum_type;
}

void ComputeChecksum.start (string &file_path) {
    q_c_info (lc_checksums) << "Computing" << checksum_type () << "checksum of" << file_path << "in a thread";
    start_impl (std.make_unique<QFile> (file_path));
}

void ComputeChecksum.start (std.unique_ptr<QIODevice> device) {
    ENFORCE (device);
    q_c_info (lc_checksums) << "Computing" << checksum_type () << "checksum of device" << device.get () << "in a thread";
    ASSERT (!device.parent ());

    start_impl (std.move (device));
}

void ComputeChecksum.start_impl (std.unique_ptr<QIODevice> device) {
    connect (&_watcher, &QFuture_watcher_base.finished,
        this, &ComputeChecksum.slot_calculation_done,
        Qt.UniqueConnection);

    // We'd prefer to move the unique_ptr into the lambda, but that's
    // awkward with the C++ standard we're on
    auto shared_device = QSharedPointer<QIODevice> (device.release ());

    // Bug : The thread will keep running even if ComputeChecksum is deleted.
    auto type = checksum_type ();
    _watcher.set_future (Qt_concurrent.run ([shared_device, type] () {
        if (!shared_device.open (QIODevice.Read_only)) {
            if (auto file = qobject_cast<QFile> (shared_device.data ())) {
                q_c_warning (lc_checksums) << "Could not open file" << file.file_name ()
                        << "for reading to compute a checksum" << file.error_string ();
            } else {
                q_c_warning (lc_checksums) << "Could not open device" << shared_device.data ()
                        << "for reading to compute a checksum" << shared_device.error_string ();
            }
            return QByteArray ();
        }
        auto result = ComputeChecksum.compute_now (shared_device.data (), type);
        shared_device.close ();
        return result;
    }));
}

QByteArray ComputeChecksum.compute_now_on_file (string &file_path, QByteArray &checksum_type) {
    QFile file (file_path);
    if (!file.open (QIODevice.Read_only)) {
        q_c_warning (lc_checksums) << "Could not open file" << file_path << "for reading and computing checksum" << file.error_string ();
        return QByteArray ();
    }

    return compute_now (&file, checksum_type);
}

QByteArray ComputeChecksum.compute_now (QIODevice *device, QByteArray &checksum_type) {
    if (!checksum_computation_enabled ()) {
        q_c_warning (lc_checksums) << "Checksum computation disabled by environment variable";
        return QByteArray ();
    }

    if (checksum_type == check_sum_mD5C) {
        return calc_md5 (device);
    } else if (checksum_type == check_sum_sHA1C) {
        return calc_sha1 (device);
    } else if (checksum_type == check_sum_sHA2C) {
        return calc_crypto_hash (device, QCryptographicHash.Sha256);
    }
#if QT_VERSION >= QT_VERSION_CHECK (5, 9, 0)
    else if (checksum_type == check_sum_sHA3C) {
        return calc_crypto_hash (device, QCryptographicHash.Sha3_256);
    }
#endif
#ifdef ZLIB_FOUND
    else if (checksum_type == check_sum_adler_c) {
        return calc_adler32 (device);
    }
#endif
    // for an unknown checksum or no checksum, we're done right now
    if (!checksum_type.is_empty ()) {
        q_c_warning (lc_checksums) << "Unknown checksum type:" << checksum_type;
    }
    return QByteArray ();
}

void ComputeChecksum.slot_calculation_done () {
    QByteArray checksum = _watcher.future ().result ();
    if (!checksum.is_null ()) {
        emit done (_checksum_type, checksum);
    } else {
        emit done (QByteArray (), QByteArray ());
    }
}

Validate_checksum_header.Validate_checksum_header (GLib.Object *parent)
    : GLib.Object (parent) {
}

ComputeChecksum *Validate_checksum_header.prepare_start (QByteArray &checksum_header) {
    // If the incoming header is empty no validation can happen. Just continue.
    if (checksum_header.is_empty ()) {
        emit validated (QByteArray (), QByteArray ());
        return nullptr;
    }

    if (!parse_checksum_header (checksum_header, &_expected_checksum_type, &_expected_checksum)) {
        q_c_warning (lc_checksums) << "Checksum header malformed:" << checksum_header;
        emit validation_failed (tr ("The checksum header is malformed."));
        return nullptr;
    }

    auto calculator = new ComputeChecksum (this);
    calculator.set_checksum_type (_expected_checksum_type);
    connect (calculator, &ComputeChecksum.done,
        this, &Validate_checksum_header.slot_checksum_calculated);
    return calculator;
}

void Validate_checksum_header.start (string &file_path, QByteArray &checksum_header) {
    if (auto calculator = prepare_start (checksum_header))
        calculator.start (file_path);
}

void Validate_checksum_header.start (std.unique_ptr<QIODevice> device, QByteArray &checksum_header) {
    if (auto calculator = prepare_start (checksum_header))
        calculator.start (std.move (device));
}

void Validate_checksum_header.slot_checksum_calculated (QByteArray &checksum_type,
    const QByteArray &checksum) {
    if (checksum_type != _expected_checksum_type) {
        emit validation_failed (tr ("The checksum header contained an unknown checksum type \"%1\"").arg (string.from_latin1 (_expected_checksum_type)));
        return;
    }
    if (checksum != _expected_checksum) {
        emit validation_failed (tr (R" (The downloaded file does not match the checksum, it will be resumed. "%1" != "%2")").arg (string.from_utf8 (_expected_checksum), string.from_utf8 (checksum)));
        return;
    }
    emit validated (checksum_type, checksum);
}

CSyncChecksumHook.CSyncChecksumHook () = default;

QByteArray CSyncChecksumHook.hook (QByteArray &path, QByteArray &other_checksum_header, void * /*this_obj*/) {
    QByteArray type = parse_checksum_header_type (QByteArray (other_checksum_header));
    if (type.is_empty ())
        return nullptr;

    q_c_info (lc_checksums) << "Computing" << type << "checksum of" << path << "in the csync hook";
    QByteArray checksum = ComputeChecksum.compute_now_on_file (string.from_utf8 (path), type);
    if (checksum.is_null ()) {
        q_c_warning (lc_checksums) << "Failed to compute checksum" << type << "for" << path;
        return nullptr;
    }

    return make_checksum_header (type, checksum);
}

}
