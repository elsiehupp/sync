/*
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

This library is free software; you can redistribute it and
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later versi

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GN
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*/

// #pragma once

// #include <GLib.Object>
// #include <QByteArray>
// #include <QFutureWatcher>

// #include <memory>


namespace Occ {

/**
Tags for checksum headers values.
They are here for being shared between Upload- and Download Job
*/
static const char checkSumMD5C[] = "MD5";
static const char checkSumSHA1C[] = "SHA1";
static const char checkSumSHA2C[] = "SHA256";
static const char checkSumSHA3C[] = "SHA3-256";
static const char checkSumAdlerC[] = "Adler32";


/**
Returns the highest-quality checksum in a 'checksums'
property retrieved from the server.

Example : "ADLER32:1231 SHA1:ab124124 MD5:2131affa21"
      . "SHA1:ab124124"
*/
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

/**
Computes the checksum of a file.
\ingroup libsync
*/
class ComputeChecksum : GLib.Object {
public:
    ComputeChecksum (GLib.Object *parent = nullptr);
    ~ComputeChecksum () override;

    /**
     * Sets the checksum type to be used. The default is empty.
     */
    void setChecksumType (QByteArray &type);

    QByteArray checksumType ();

    /**
     * Computes the checksum for the given file path.
     *
     * done () is emitted when the calculation finishes.
     */
    void start (QString &filePath);

    /**
     * Computes the checksum for the given device.
     *
     * done () is emitted when the calculation finishes.
     *
     * The device ownership transfers into the thread that
     * will compute the checksum. It must not have a parent.
     */
    void start (std.unique_ptr<QIODevice> device);

    /**
     * Computes the checksum synchronously.
     */
    static QByteArray computeNow (QIODevice *device, QByteArray &checksumType);

    /**
     * Computes the checksum synchronously on file. Convenience wrapper for computeNow ().
     */
    static QByteArray computeNowOnFile (QString &filePath, QByteArray &checksumType);

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

/**
Checks whether a file's checksum matches the expected value.
@ingroup libsync
*/
class ValidateChecksumHeader : GLib.Object {
public:
    ValidateChecksumHeader (GLib.Object *parent = nullptr);

    /**
     * Check a file's actual checksum against the provided checksumHeader
     *
     * If no checksum is there, or if a correct checksum is there, the signal validated ()
     * will be emitted. In case of any kind of error, the signal validationFailed () will
     * be emitted.
     */
    void start (QString &filePath, QByteArray &checksumHeader);

    /**
     * Check a device's actual checksum against the provided checksumHeader
     *
     * Like the other start () but works on an device.
     *
     * The device ownership transfers into the thread that
     * will compute the checksum. It must not have a parent.
     */
    void start (std.unique_ptr<QIODevice> device, QByteArray &checksumHeader);

signals:
    void validated (QByteArray &checksumType, QByteArray &checksum);
    void validationFailed (QString &errMsg);

private slots:
    void slotChecksumCalculated (QByteArray &checksumType, QByteArray &checksum);

private:
    ComputeChecksum *prepareStart (QByteArray &checksumHeader);

    QByteArray _expectedChecksumType;
    QByteArray _expectedChecksum;
};

/**
Hooks checksum computations into csync.
@ingroup libsync
*/
class CSyncChecksumHook : GLib.Object {
public:
    CSyncChecksumHook ();

    /**
     * Returns the checksum value for \a path that is comparable to \a otherChecksum.
     *
     * Called from csync, where a instance of CSyncChecksumHook has
     * to be set as userdata.
     * The return value will be owned by csync.
     */
    static QByteArray hook (QByteArray &path, QByteArray &otherChecksumHeader, void *this_obj);
};
}
