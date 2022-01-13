/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/
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

NEXTCLOUD_CFAPI_EXPORT Result<void, string> registerSyncRoot (string &path, string &providerName, string &providerVersion, string &folderAlias, string &displayName, string &accountDisplayName);
NEXTCLOUD_CFAPI_EXPORT Result<void, string> unregisterSyncRoot (string &path, string &providerName, string &accountDisplayName);

NEXTCLOUD_CFAPI_EXPORT Result<ConnectionKey, string> connectSyncRoot (string &path, VfsCfApi *context);
NEXTCLOUD_CFAPI_EXPORT Result<void, string> disconnectSyncRoot (ConnectionKey &&key);

NEXTCLOUD_CFAPI_EXPORT bool isSparseFile (string &path);

NEXTCLOUD_CFAPI_EXPORT FileHandle handleForPath (string &path);

PlaceHolderInfo findPlaceholderInfo (FileHandle &handle);

enum SetPinRecurseMode {
    NoRecurse = 0,
    Recurse,
    ChildrenOnly
};

NEXTCLOUD_CFAPI_EXPORT Result<Occ.Vfs.ConvertToPlaceholderResult, string> setPinState (FileHandle &handle, PinState state, SetPinRecurseMode mode);
NEXTCLOUD_CFAPI_EXPORT Result<void, string> createPlaceholderInfo (string &path, time_t modtime, int64 size, QByteArray &fileId);
NEXTCLOUD_CFAPI_EXPORT Result<Occ.Vfs.ConvertToPlaceholderResult, string> updatePlaceholderInfo (FileHandle &handle, time_t modtime, int64 size, QByteArray &fileId, string &replacesPath = string ());
NEXTCLOUD_CFAPI_EXPORT Result<Occ.Vfs.ConvertToPlaceholderResult, string> convertToPlaceholder (FileHandle &handle, time_t modtime, int64 size, QByteArray &fileId, string &replacesPath);

}

} // namespace Occ
