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
// #include <QFutureWatcher>

// #include <memory>


namespace Occ {

/***********************************************************
Tags for checksum headers values.
They are here for being shared between Upload- and Download Job
***********************************************************/
static const char checkSumMD5C[] = "MD5";
static const char checkSumSHA1C[] = "SHA1";
static const char checkSumSHA2C[] = "SHA256";
static const char checkSumSHA3C[] = "SHA3-256";
static const char checkSumAdlerC[] = "Adler32";


/***********************************************************
Returns the highest-quality checksum in a 'checksums'
property retrieved from the server.

Example : "ADLER32:1231 SHA1:ab124124 MD5:2131affa21"
      . "SHA1:ab124124"
***********************************************************/
OCSYNC_EXPORT QByteArray findBestChecksum (QByteArray &checksums);

/// Creates a checksum header from type and value.
OCSYNC_EXPORT QByteArray makeChecksumHeader (QByteArray &checksumType, QByteArray &checksum);

/// Parses a checksum header
OCSYNC_EXPORT bool parseChecksumHeader (QByteArray &header, QByteArray *type, QByteArray *checksum);

/// Convenience for getting the type from a checksum header, null if none
OCSYNC_EXPORT QByteArray parseChecksumHeaderType (QByteArray &header);

/// Checks OWNCLOUD_DISABLE_CHECKSUM_UPLOAD
OCSYNC_EXPORT bool uploadChecksumEnabled ();

// Exported functions for the tests.
QByteArray OCSYNC_EXPORT calcMd5 (QIODevice *device);
QByteArray OCSYNC_EXPORT calcSha1 (QIODevice *device);
#ifdef ZLIB_FOUND
QByteArray OCSYNC_EXPORT calcAdler32 (QIODevice *device);
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
    public void setChecksumType (QByteArray &type);

    public QByteArray checksumType ();

    /***********************************************************
    Computes the checksum for the given file path.
    
    done () is emitted when the calculation finishes.
    ***********************************************************/
    public void start (string &filePath);

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
    public static QByteArray computeNow (QIODevice *device, QByteArray &checksumType);

    /***********************************************************
    Computes the checksum synchronously on file. Convenience wrapper for computeNow ().
    ***********************************************************/
    public static QByteArray computeNowOnFile (string &filePath, QByteArray &checksumType);

signals:
    void done (QByteArray &checksumType, QByteArray &checksum);

private slots:
    void slotCalculationDone ();

private:
    void startImpl (std.unique_ptr<QIODevice> device);

    QByteArray _checksumType;

    // watcher for the checksum calculation thread
    QFutureWatcher<QByteArray> _watcher;
};

/***********************************************************
Checks whether a file's checksum matches the expected value.
@ingroup libsync
***********************************************************/
class ValidateChecksumHeader : GLib.Object {

    public ValidateChecksumHeader (GLib.Object *parent = nullptr);

    /***********************************************************
    Check a file's actual checksum against the provided checksumHeader
    
    If no checksum is there, or if a correct checksum is there, the signal validated (
    will be emitted. In case of any kind of error, the signal validationFailed () will
    be emitted.
    ***********************************************************/
    public void start (string &filePath, QByteArray &checksumHeader);

    /***********************************************************
    Check a device's actual checksum against the provided checksumHeader
    
    Like the other start () but works on an device.
    
    The device ownership transfers into the thread that
    will compute the checksum. It must not have a parent.
    ***********************************************************/
    public void start (std.unique_ptr<QIODevice> device, QByteArray &checksumHeader);

signals:
    void validated (QByteArray &checksumType, QByteArray &checksum);
    void validationFailed (string &errMsg);

private slots:
    void slotChecksumCalculated (QByteArray &checksumType, QByteArray &checksum);

private:
    ComputeChecksum *prepareStart (QByteArray &checksumHeader);

    QByteArray _expectedChecksumType;
    QByteArray _expectedChecksum;
};

/***********************************************************
Hooks checksum computations into csync.
@ingroup libsync
***********************************************************/
class CSyncChecksumHook : GLib.Object {

    public CSyncChecksumHook ();

    /***********************************************************
    Returns the checksum value for \a path that is comparable to \a otherChecksum.
    
    Called from csync, whe
    to be set as userdata.
    The return value will be owned by csync.
    ***********************************************************/
    public static QByteArray hook (QByteArray &path, QByteArray &otherChecksumHeader, void *this_obj);
};



const int BUFSIZE int64 (500 * 1024) // 500 KiB

static QByteArray calcCryptoHash (QIODevice *device, QCryptographicHash.Algorithm algo) {
    QByteArray arr;
    QCryptographicHash crypto ( algo );

    if (crypto.addData (device)) {
        arr = crypto.result ().toHex ();
    }
    return arr;
}

QByteArray calcMd5 (QIODevice *device) {
    return calcCryptoHash (device, QCryptographicHash.Md5);
}

QByteArray calcSha1 (QIODevice *device) {
    return calcCryptoHash (device, QCryptographicHash.Sha1);
}

#ifdef ZLIB_FOUND
QByteArray calcAdler32 (QIODevice *device) { {f (device.size () == 0)
    {
        return QByteArray ();
    }
    QByteArray buf (BUFSIZE, Qt.Uninitialized);

    unsigned int adler = adler32 (0L, Z_NULL, 0);
    int64 size = 0;
    while (!device.atEnd ()) {
        size = device.read (buf.data (), BUFSIZE);
        if (size > 0)
            adler = adler32 (adler, (Bytef *)buf.data (), size);
    }

    return QByteArray.number (adler, 16);
}
#endif

QByteArray makeChecksumHeader (QByteArray &checksumType, QByteArray &checksum) {
    if (checksumType.isEmpty () || checksum.isEmpty ())
        return QByteArray ();
    QByteArray header = checksumType;
    header.append (':');
    header.append (checksum);
    return header;
}

QByteArray findBestChecksum (QByteArray &_checksums) {
    if (_checksums.isEmpty ()) {
        return {};
    }
    const auto checksums = string.fromUtf8 (_checksums);
    int i = 0;
    // The order of the searches here defines the preference ordering.
    if (-1 != (i = checksums.indexOf (QLatin1String ("SHA3-256:"), 0, Qt.CaseInsensitive))
        || -1 != (i = checksums.indexOf (QLatin1String ("SHA256:"), 0, Qt.CaseInsensitive))
        || -1 != (i = checksums.indexOf (QLatin1String ("SHA1:"), 0, Qt.CaseInsensitive))
        || -1 != (i = checksums.indexOf (QLatin1String ("MD5:"), 0, Qt.CaseInsensitive))
        || -1 != (i = checksums.indexOf (QLatin1String ("ADLER32:"), 0, Qt.CaseInsensitive))) {
        // Now i is the start of the best checksum
        // Grab it until the next space or end of xml or end of string.
        int end = _checksums.indexOf (' ', i);
        // workaround for https://github.com/owncloud/core/pull/38304
        if (end == -1) {
            end = _checksums.indexOf ('<', i);
        }
        return _checksums.mid (i, end - i);
    }
    qCWarning (lcChecksums) << "Failed to parse" << _checksums;
    return {};
}

bool parseChecksumHeader (QByteArray &header, QByteArray *type, QByteArray *checksum) {
    if (header.isEmpty ()) {
        type.clear ();
        checksum.clear ();
        return true;
    }

    const auto idx = header.indexOf (':');
    if (idx < 0) {
        return false;
    }

    *type = header.left (idx);
    *checksum = header.mid (idx + 1);
    return true;
}

QByteArray parseChecksumHeaderType (QByteArray &header) {
    const auto idx = header.indexOf (':');
    if (idx < 0) {
        return QByteArray ();
    }
    return header.left (idx);
}

bool uploadChecksumEnabled () {
    static bool enabled = qEnvironmentVariableIsEmpty ("OWNCLOUD_DISABLE_CHECKSUM_UPLOAD");
    return enabled;
}

static bool checksumComputationEnabled () {
    static bool enabled = qEnvironmentVariableIsEmpty ("OWNCLOUD_DISABLE_CHECKSUM_COMPUTATIONS");
    return enabled;
}

ComputeChecksum.ComputeChecksum (GLib.Object *parent)
    : GLib.Object (parent) {
}

ComputeChecksum.~ComputeChecksum () = default;

void ComputeChecksum.setChecksumType (QByteArray &type) {
    _checksumType = type;
}

QByteArray ComputeChecksum.checksumType () {
    return _checksumType;
}

void ComputeChecksum.start (string &filePath) {
    qCInfo (lcChecksums) << "Computing" << checksumType () << "checksum of" << filePath << "in a thread";
    startImpl (std.make_unique<QFile> (filePath));
}

void ComputeChecksum.start (std.unique_ptr<QIODevice> device) {
    ENFORCE (device);
    qCInfo (lcChecksums) << "Computing" << checksumType () << "checksum of device" << device.get () << "in a thread";
    ASSERT (!device.parent ());

    startImpl (std.move (device));
}

void ComputeChecksum.startImpl (std.unique_ptr<QIODevice> device) {
    connect (&_watcher, &QFutureWatcherBase.finished,
        this, &ComputeChecksum.slotCalculationDone,
        Qt.UniqueConnection);

    // We'd prefer to move the unique_ptr into the lambda, but that's
    // awkward with the C++ standard we're on
    auto sharedDevice = QSharedPointer<QIODevice> (device.release ());

    // Bug : The thread will keep running even if ComputeChecksum is deleted.
    auto type = checksumType ();
    _watcher.setFuture (QtConcurrent.run ([sharedDevice, type] () {
        if (!sharedDevice.open (QIODevice.ReadOnly)) {
            if (auto file = qobject_cast<QFile> (sharedDevice.data ())) {
                qCWarning (lcChecksums) << "Could not open file" << file.fileName ()
                        << "for reading to compute a checksum" << file.errorString ();
            } else {
                qCWarning (lcChecksums) << "Could not open device" << sharedDevice.data ()
                        << "for reading to compute a checksum" << sharedDevice.errorString ();
            }
            return QByteArray ();
        }
        auto result = ComputeChecksum.computeNow (sharedDevice.data (), type);
        sharedDevice.close ();
        return result;
    }));
}

QByteArray ComputeChecksum.computeNowOnFile (string &filePath, QByteArray &checksumType) {
    QFile file (filePath);
    if (!file.open (QIODevice.ReadOnly)) {
        qCWarning (lcChecksums) << "Could not open file" << filePath << "for reading and computing checksum" << file.errorString ();
        return QByteArray ();
    }

    return computeNow (&file, checksumType);
}

QByteArray ComputeChecksum.computeNow (QIODevice *device, QByteArray &checksumType) {
    if (!checksumComputationEnabled ()) {
        qCWarning (lcChecksums) << "Checksum computation disabled by environment variable";
        return QByteArray ();
    }

    if (checksumType == checkSumMD5C) {
        return calcMd5 (device);
    } else if (checksumType == checkSumSHA1C) {
        return calcSha1 (device);
    } else if (checksumType == checkSumSHA2C) {
        return calcCryptoHash (device, QCryptographicHash.Sha256);
    }
#if QT_VERSION >= QT_VERSION_CHECK (5, 9, 0)
    else if (checksumType == checkSumSHA3C) {
        return calcCryptoHash (device, QCryptographicHash.Sha3_256);
    }
#endif
#ifdef ZLIB_FOUND
    else if (checksumType == checkSumAdlerC) {
        return calcAdler32 (device);
    }
#endif
    // for an unknown checksum or no checksum, we're done right now
    if (!checksumType.isEmpty ()) {
        qCWarning (lcChecksums) << "Unknown checksum type:" << checksumType;
    }
    return QByteArray ();
}

void ComputeChecksum.slotCalculationDone () {
    QByteArray checksum = _watcher.future ().result ();
    if (!checksum.isNull ()) {
        emit done (_checksumType, checksum);
    } else {
        emit done (QByteArray (), QByteArray ());
    }
}

ValidateChecksumHeader.ValidateChecksumHeader (GLib.Object *parent)
    : GLib.Object (parent) {
}

ComputeChecksum *ValidateChecksumHeader.prepareStart (QByteArray &checksumHeader) {
    // If the incoming header is empty no validation can happen. Just continue.
    if (checksumHeader.isEmpty ()) {
        emit validated (QByteArray (), QByteArray ());
        return nullptr;
    }

    if (!parseChecksumHeader (checksumHeader, &_expectedChecksumType, &_expectedChecksum)) {
        qCWarning (lcChecksums) << "Checksum header malformed:" << checksumHeader;
        emit validationFailed (tr ("The checksum header is malformed."));
        return nullptr;
    }

    auto calculator = new ComputeChecksum (this);
    calculator.setChecksumType (_expectedChecksumType);
    connect (calculator, &ComputeChecksum.done,
        this, &ValidateChecksumHeader.slotChecksumCalculated);
    return calculator;
}

void ValidateChecksumHeader.start (string &filePath, QByteArray &checksumHeader) {
    if (auto calculator = prepareStart (checksumHeader))
        calculator.start (filePath);
}

void ValidateChecksumHeader.start (std.unique_ptr<QIODevice> device, QByteArray &checksumHeader) {
    if (auto calculator = prepareStart (checksumHeader))
        calculator.start (std.move (device));
}

void ValidateChecksumHeader.slotChecksumCalculated (QByteArray &checksumType,
    const QByteArray &checksum) {
    if (checksumType != _expectedChecksumType) {
        emit validationFailed (tr ("The checksum header contained an unknown checksum type \"%1\"").arg (string.fromLatin1 (_expectedChecksumType)));
        return;
    }
    if (checksum != _expectedChecksum) {
        emit validationFailed (tr (R" (The downloaded file does not match the checksum, it will be resumed. "%1" != "%2")").arg (string.fromUtf8 (_expectedChecksum), string.fromUtf8 (checksum)));
        return;
    }
    emit validated (checksumType, checksum);
}

CSyncChecksumHook.CSyncChecksumHook () = default;

QByteArray CSyncChecksumHook.hook (QByteArray &path, QByteArray &otherChecksumHeader, void * /*this_obj*/) {
    QByteArray type = parseChecksumHeaderType (QByteArray (otherChecksumHeader));
    if (type.isEmpty ())
        return nullptr;

    qCInfo (lcChecksums) << "Computing" << type << "checksum of" << path << "in the csync hook";
    QByteArray checksum = ComputeChecksum.computeNowOnFile (string.fromUtf8 (path), type);
    if (checksum.isNull ()) {
        qCWarning (lcChecksums) << "Failed to compute checksum" << type << "for" << path;
        return nullptr;
    }

    return makeChecksumHeader (type, checksum);
}

}
