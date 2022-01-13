/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QFile>

namespace xattr {
using namespace Occ.XAttrWrapper;
}

namespace Occ {

VfsXAttr.VfsXAttr (GLib.Object *parent)
    : Vfs (parent) {
}

VfsXAttr.~VfsXAttr () = default;

Vfs.Mode VfsXAttr.mode () {
    return XAttr;
}

string VfsXAttr.fileSuffix () {
    return string ();
}

void VfsXAttr.startImpl (VfsSetupParams &) {
}

void VfsXAttr.stop () {
}

void VfsXAttr.unregisterFolder () {
}

bool VfsXAttr.socketApiPinStateActionsShown () {
    return true;
}

bool VfsXAttr.isHydrating () {
    return false;
}

Result<void, string> VfsXAttr.updateMetadata (string &filePath, time_t modtime, int64, QByteArray &) {
    if (modtime <= 0) {
        return {tr ("Error updating metadata due to invalid modified time")};
    }

    FileSystem.setModTime (filePath, modtime);
    return {};
}

Result<void, string> VfsXAttr.createPlaceholder (SyncFileItem &item) {
    if (item._modtime <= 0) {
        return {tr ("Error updating metadata due to invalid modified time")};
    }

    const auto path = string (_setupParams.filesystemPath + item._file);
    QFile file (path);
    if (file.exists () && file.size () > 1
        && !FileSystem.verifyFileUnchanged (path, item._size, item._modtime)) {
        return QStringLiteral ("Cannot create a placeholder because a file with the placeholder name already exist");
    }

    if (!file.open (QFile.ReadWrite | QFile.Truncate)) {
        return file.errorString ();
    }

    file.write (" ");
    file.close ();
    FileSystem.setModTime (path, item._modtime);
    return xattr.addNextcloudPlaceholderAttributes (path);
}

Result<void, string> VfsXAttr.dehydratePlaceholder (SyncFileItem &item) {
    const auto path = string (_setupParams.filesystemPath + item._file);
    QFile file (path);
    if (!file.remove ()) {
        return QStringLiteral ("Couldn't remove the original file to dehydrate");
    }
    auto r = createPlaceholder (item);
    if (!r) {
        return r;
    }

    // Ensure the pin state isn't contradictory
    const auto pin = pinState (item._file);
    if (pin && *pin == PinState.AlwaysLocal) {
        setPinState (item._renameTarget, PinState.Unspecified);
    }
    return {};
}

Result<Vfs.ConvertToPlaceholderResult, string> VfsXAttr.convertToPlaceholder (string &, SyncFileItem &, string &) {
    // Nothing necessary
    return {ConvertToPlaceholderResult.Ok};
}

bool VfsXAttr.needsMetadataUpdate (SyncFileItem &) {
    return false;
}

bool VfsXAttr.isDehydratedPlaceholder (string &filePath) {
    const auto fi = QFileInfo (filePath);
    return fi.exists () &&
            xattr.hasNextcloudPlaceholderAttributes (filePath);
}

bool VfsXAttr.statTypeVirtualFile (csync_file_stat_t *stat, void *statData) {
    if (stat.type == ItemTypeDirectory) {
        return false;
    }

    const auto parentPath = static_cast<QByteArray> (statData);
    Q_ASSERT (!parentPath.endsWith ('/'));
    Q_ASSERT (!stat.path.startsWith ('/'));

    const auto path = QByteArray (*parentPath + '/' + stat.path);
    const auto pin = [=] {
        const auto absolutePath = string.fromUtf8 (path);
        Q_ASSERT (absolutePath.startsWith (params ().filesystemPath.toUtf8 ()));
        const auto folderPath = absolutePath.mid (params ().filesystemPath.length ());
        return pinState (folderPath);
    } ();

    if (xattr.hasNextcloudPlaceholderAttributes (path)) {
        const auto shouldDownload = pin && (*pin == PinState.AlwaysLocal);
        stat.type = shouldDownload ? ItemTypeVirtualFileDownload : ItemTypeVirtualFile;
        return true;
    } else {
        const auto shouldDehydrate = pin && (*pin == PinState.OnlineOnly);
        if (shouldDehydrate) {
            stat.type = ItemTypeVirtualFileDehydration;
            return true;
        }
    }
    return false;
}

bool VfsXAttr.setPinState (string &folderPath, PinState state) {
    return setPinStateInDb (folderPath, state);
}

Optional<PinState> VfsXAttr.pinState (string &folderPath) {
    return pinStateInDb (folderPath);
}

Vfs.AvailabilityResult VfsXAttr.availability (string &folderPath) {
    return availabilityInDb (folderPath);
}

void VfsXAttr.fileStatusChanged (string &, SyncFileStatus) {
}

} // namespace Occ
