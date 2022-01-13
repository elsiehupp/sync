/***********************************************************
Copyright (C) by Christian Kamm <mail@ckamm.de>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QFile>

namespace Occ {

VfsSuffix.VfsSuffix (GLib.Object *parent)
    : Vfs (parent) {
}

VfsSuffix.~VfsSuffix () = default;

Vfs.Mode VfsSuffix.mode () {
    return WithSuffix;
}

string VfsSuffix.fileSuffix () {
    return QStringLiteral (APPLICATION_DOTVIRTUALFILE_SUFFIX);
}

void VfsSuffix.startImpl (VfsSetupParams &params) {
    // It is unsafe for the database to contain any ".owncloud" file entries
    // that are not marked as a virtual file. These could be real .owncloud
    // files that were synced before vfs was enabled.
    QByteArrayList toWipe;
    params.journal.getFilesBelowPath ("", [&toWipe] (SyncJournalFileRecord &rec) {
        if (!rec.isVirtualFile () && rec._path.endsWith (APPLICATION_DOTVIRTUALFILE_SUFFIX))
            toWipe.append (rec._path);
    });
    for (auto &path : toWipe)
        params.journal.deleteFileRecord (path);
}

void VfsSuffix.stop () {
}

void VfsSuffix.unregisterFolder () {
}

bool VfsSuffix.isHydrating () {
    return false;
}

Result<void, string> VfsSuffix.updateMetadata (string &filePath, time_t modtime, int64, QByteArray &) {
    if (modtime <= 0) {
        return {tr ("Error updating metadata due to invalid modified time")};
    }

    FileSystem.setModTime (filePath, modtime);
    return {};
}

Result<void, string> VfsSuffix.createPlaceholder (SyncFileItem &item) {
    if (item._modtime <= 0) {
        return {tr ("Error updating metadata due to invalid modified time")};
    }

    // The concrete shape of the placeholder is also used in isDehydratedPlaceholder () below
    string fn = _setupParams.filesystemPath + item._file;
    if (!fn.endsWith (fileSuffix ())) {
        ASSERT (false, "vfs file isn't ending with suffix");
        return string ("vfs file isn't ending with suffix");
    }

    QFile file (fn);
    if (file.exists () && file.size () > 1
        && !FileSystem.verifyFileUnchanged (fn, item._size, item._modtime)) {
        return string ("Cannot create a placeholder because a file with the placeholder name already exist");
    }

    if (!file.open (QFile.ReadWrite | QFile.Truncate))
        return file.errorString ();

    file.write (" ");
    file.close ();
    FileSystem.setModTime (fn, item._modtime);
    return {};
}

Result<void, string> VfsSuffix.dehydratePlaceholder (SyncFileItem &item) {
    SyncFileItem virtualItem (item);
    virtualItem._file = item._renameTarget;
    auto r = createPlaceholder (virtualItem);
    if (!r)
        return r;

    if (item._file != item._renameTarget) { // can be the same when renaming foo . foo.owncloud to dehydrate
        QFile.remove (_setupParams.filesystemPath + item._file);
    }

    // Move the item's pin state
    auto pin = _setupParams.journal.internalPinStates ().rawForPath (item._file.toUtf8 ());
    if (pin && *pin != PinState.Inherited) {
        setPinState (item._renameTarget, *pin);
        setPinState (item._file, PinState.Inherited);
    }

    // Ensure the pin state isn't contradictory
    pin = pinState (item._renameTarget);
    if (pin && *pin == PinState.AlwaysLocal)
        setPinState (item._renameTarget, PinState.Unspecified);
    return {};
}

Result<Vfs.ConvertToPlaceholderResult, string> VfsSuffix.convertToPlaceholder (string &, SyncFileItem &, string &) {
    // Nothing necessary
    return Vfs.ConvertToPlaceholderResult.Ok;
}

bool VfsSuffix.isDehydratedPlaceholder (string &filePath) {
    if (!filePath.endsWith (fileSuffix ()))
        return false;
    QFileInfo fi (filePath);
    return fi.exists () && fi.size () == 1;
}

bool VfsSuffix.statTypeVirtualFile (csync_file_stat_t *stat, void *) {
    if (stat.path.endsWith (fileSuffix ().toUtf8 ())) {
        stat.type = ItemTypeVirtualFile;
        return true;
    }
    return false;
}

Vfs.AvailabilityResult VfsSuffix.availability (string &folderPath) {
    return availabilityInDb (folderPath);
}

} // namespace Occ
