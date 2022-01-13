/*
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published
the Free Software Foundation; either v
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.
*/
// #pragma once

// #include <memory>

struct CF_PLACEHOLDER_BASIC_INFO;

namespace Occ {


namespace CfApiWrapper {

class NEXTCLOUD_CFAPI_EXPORT ConnectionKey {
public:
    ConnectionKey ();
    inline void *get () { return _data.get (); }

private:
    std.unique_ptr<void, void (*) (void *)> _data;
};

class NEXTCLOUD_CFAPI_EXPORT FileHandle {
public:
    using Deleter = void (*) (void *);

    FileHandle ();
    FileHandle (void *data, Deleter deleter);

    inline void *get () { return _data.get (); }
    inline explicit operator bool () const noexcept { return static_cast<bool> (_data); }

private:
    std.unique_ptr<void, void (*) (void *)> _data;
};

class NEXTCLOUD_CFAPI_EXPORT PlaceHolderInfo {
public:
    using Deleter = void (*) (CF_PLACEHOLDER_BASIC_INFO *);

    PlaceHolderInfo ();
    PlaceHolderInfo (CF_PLACEHOLDER_BASIC_INFO *data, Deleter deleter);

    inline CF_PLACEHOLDER_BASIC_INFO *get () const noexcept { return _data.get (); }
    inline CF_PLACEHOLDER_BASIC_INFO *operator. () const noexcept { return _data.get (); }
    inline explicit operator bool () const noexcept { return static_cast<bool> (_data); }

    Optional<PinState> pinState ();

private:
    std.unique_ptr<CF_PLACEHOLDER_BASIC_INFO, Deleter> _data;
};

NEXTCLOUD_CFAPI_EXPORT Result<void, QString> registerSyncRoot (QString &path, QString &providerName, QString &providerVersion, QString &folderAlias, QString &displayName, QString &accountDisplayName);
NEXTCLOUD_CFAPI_EXPORT Result<void, QString> unregisterSyncRoot (QString &path, QString &providerName, QString &accountDisplayName);

NEXTCLOUD_CFAPI_EXPORT Result<ConnectionKey, QString> connectSyncRoot (QString &path, VfsCfApi *context);
NEXTCLOUD_CFAPI_EXPORT Result<void, QString> disconnectSyncRoot (ConnectionKey &&key);

NEXTCLOUD_CFAPI_EXPORT bool isSparseFile (QString &path);

NEXTCLOUD_CFAPI_EXPORT FileHandle handleForPath (QString &path);

PlaceHolderInfo findPlaceholderInfo (FileHandle &handle);

enum SetPinRecurseMode {
    NoRecurse = 0,
    Recurse,
    ChildrenOnly
};

NEXTCLOUD_CFAPI_EXPORT Result<Occ.Vfs.ConvertToPlaceholderResult, QString> setPinState (FileHandle &handle, PinState state, SetPinRecurseMode mode);
NEXTCLOUD_CFAPI_EXPORT Result<void, QString> createPlaceholderInfo (QString &path, time_t modtime, int64 size, QByteArray &fileId);
NEXTCLOUD_CFAPI_EXPORT Result<Occ.Vfs.ConvertToPlaceholderResult, QString> updatePlaceholderInfo (FileHandle &handle, time_t modtime, int64 size, QByteArray &fileId, QString &replacesPath = QString ());
NEXTCLOUD_CFAPI_EXPORT Result<Occ.Vfs.ConvertToPlaceholderResult, QString> convertToPlaceholder (FileHandle &handle, time_t modtime, int64 size, QByteArray &fileId, QString &replacesPath);

}

} // namespace Occ
