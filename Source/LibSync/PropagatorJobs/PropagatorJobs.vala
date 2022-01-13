/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #pragma once

// #include <QFile>

namespace Occ {

/***********************************************************
Tags for checksum header.
It's here for being shared between Upload- and Download Job
***********************************************************/
static const char checkSumHeaderC[] = "OC-Checksum";
static const char contentMd5HeaderC[] = "Content-MD5";

/***********************************************************
@brief Declaration of the other propagation jobs
@ingroup libsync
***********************************************************/
class PropagateLocalRemove : PropagateItemJob {
public:
    PropagateLocalRemove (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    void start () override;

private:
    bool removeRecursively (string &path);
    string _error;
    bool _moveToTrash;
};

/***********************************************************
@brief The PropagateLocalMkdir class
@ingroup libsync
***********************************************************/
class PropagateLocalMkdir : PropagateItemJob {
public:
    PropagateLocalMkdir (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item)
        , _deleteExistingFile (false) {
    }
    void start () override;

    /***********************************************************
     * Whether an existing file with the same name may be deleted before
     * creating the directory.
     *
     * Default : false.
     */
    void setDeleteExistingFile (bool enabled);

private:
    void startLocalMkdir ();
    void startDemanglingName (string &parentPath);

    bool _deleteExistingFile;
};

/***********************************************************
@brief The PropagateLocalRename class
@ingroup libsync
***********************************************************/
class PropagateLocalRename : PropagateItemJob {
public:
    PropagateLocalRename (OwncloudPropagator *propagator, SyncFileItemPtr &item)
        : PropagateItemJob (propagator, item) {
    }
    void start () override;
    JobParallelism parallelism () override { return _item.isDirectory () ? WaitForFinished : FullParallelism; }
};
}









/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@owncloud.com>
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <qfile.h>
// #include <qdir.h>
// #include <qdiriterator.h>
// #include <qtemporaryfile.h>
// #include <qsavefile.h>
// #include <QDateTime>
// #include <qstack.h>
// #include <QCoreApplication>

// #include <ctime>

namespace Occ {

    Q_LOGGING_CATEGORY (lcPropagateLocalRemove, "nextcloud.sync.propagator.localremove", QtInfoMsg)
    Q_LOGGING_CATEGORY (lcPropagateLocalMkdir, "nextcloud.sync.propagator.localmkdir", QtInfoMsg)
    Q_LOGGING_CATEGORY (lcPropagateLocalRename, "nextcloud.sync.propagator.localrename", QtInfoMsg)
    
    QByteArray localFileIdFromFullId (QByteArray &id) {
        return id.left (8);
    }
    
    /***********************************************************
    The code will update the database in case of error.
    If everything goes well (no error, returns true), the caller is responsible for removing the entries
    in the database.  But in case of error, we need to remove the entries from the database of the files
    that were deleted.
    
    \a path is relative to propagator ()._localDir + _item._file and should start with a slash
    ***********************************************************/
    bool PropagateLocalRemove.removeRecursively (string &path) {
        string absolute = propagator ().fullLocalPath (_item._file + path);
        QStringList errors;
        QList<QPair<string, bool>> deleted;
        bool success = FileSystem.removeRecursively (
            absolute,
            [&deleted] (string &path, bool isDir) {
                // by prepending, a folder deletion may be followed by content deletions
                deleted.prepend (qMakePair (path, isDir));
            },
            &errors);
    
        if (!success) {
            // We need to delete the entries from the database now from the deleted vector.
            // Do it while avoiding redundant delete calls to the journal.
            string deletedDir;
            foreach (auto &it, deleted) {
                if (!it.first.startsWith (propagator ().localPath ()))
                    continue;
                if (!deletedDir.isEmpty () && it.first.startsWith (deletedDir))
                    continue;
                if (it.second) {
                    deletedDir = it.first;
                }
                propagator ()._journal.deleteFileRecord (it.first.mid (propagator ().localPath ().size ()), it.second);
            }
    
            _error = errors.join (", ");
        }
        return success;
    }
    
    void PropagateLocalRemove.start () {
        qCInfo (lcPropagateLocalRemove) << "Start propagate local remove job";
    
        _moveToTrash = propagator ().syncOptions ()._moveFilesToTrash;
    
        if (propagator ()._abortRequested)
            return;
    
        const string filename = propagator ().fullLocalPath (_item._file);
        qCInfo (lcPropagateLocalRemove) << "Going to delete:" << filename;
    
        if (propagator ().localFileNameClash (_item._file)) {
            done (SyncFileItem.NormalError, tr ("Could not remove %1 because of a local file name clash").arg (QDir.toNativeSeparators (filename)));
            return;
        }
    
        string removeError;
        if (_moveToTrash) {
            if ( (QDir (filename).exists () || FileSystem.fileExists (filename))
                && !FileSystem.moveToTrash (filename, &removeError)) {
                done (SyncFileItem.NormalError, removeError);
                return;
            }
        } else {
            if (_item.isDirectory ()) {
                if (QDir (filename).exists () && !removeRecursively (string ())) {
                    done (SyncFileItem.NormalError, _error);
                    return;
                }
            } else {
                if (FileSystem.fileExists (filename)
                    && !FileSystem.remove (filename, &removeError)) {
                    done (SyncFileItem.NormalError, removeError);
                    return;
                }
            }
        }
        propagator ().reportProgress (*_item, 0);
        propagator ()._journal.deleteFileRecord (_item._originalFile, _item.isDirectory ());
        propagator ()._journal.commit ("Local remove");
        done (SyncFileItem.Success);
    }
    
    void PropagateLocalMkdir.start () {
        if (propagator ()._abortRequested)
            return;
    
        startLocalMkdir ();
    }
    
    void PropagateLocalMkdir.setDeleteExistingFile (bool enabled) {
        _deleteExistingFile = enabled;
    }
    
    void PropagateLocalMkdir.startLocalMkdir () {
        QDir newDir (propagator ().fullLocalPath (_item._file));
        string newDirStr = QDir.toNativeSeparators (newDir.path ());
    
        // When turning something that used to be a file into a directory
        // we need to delete the file first.
        QFileInfo fi (newDirStr);
        if (fi.exists () && fi.isFile ()) {
            if (_deleteExistingFile) {
                string removeError;
                if (!FileSystem.remove (newDirStr, &removeError)) {
                    done (SyncFileItem.NormalError,
                        tr ("could not delete file %1, error : %2")
                            .arg (newDirStr, removeError));
                    return;
                }
            } else if (_item._instruction == CSYNC_INSTRUCTION_CONFLICT) {
                string error;
                if (!propagator ().createConflict (_item, _associatedComposite, &error)) {
                    done (SyncFileItem.SoftError, error);
                    return;
                }
            }
        }
    
        if (Utility.fsCasePreserving () && propagator ().localFileNameClash (_item._file)) {
            qCWarning (lcPropagateLocalMkdir) << "New folder to create locally already exists with different case:" << _item._file;
            done (SyncFileItem.NormalError, tr ("Attention, possible case sensitivity clash with %1").arg (newDirStr));
            return;
        }
        emit propagator ().touchedFile (newDirStr);
        QDir localDir (propagator ().localPath ());
        if (!localDir.mkpath (_item._file)) {
            done (SyncFileItem.NormalError, tr ("Could not create folder %1").arg (newDirStr));
            return;
        }
    
        // Insert the directory into the database. The correct etag will be set later,
        // once all contents have been propagated, because should_update_metadata is true.
        // Adding an entry with a dummy etag to the database still makes sense here
        // so the database is aware that this folder exists even if the sync is aborted
        // before the correct etag is stored.
        SyncFileItem newItem (*_item);
        newItem._etag = "_invalid_";
        const auto result = propagator ().updateMetadata (newItem);
        if (!result) {
            done (SyncFileItem.FatalError, tr ("Error updating metadata : %1").arg (result.error ()));
            return;
        } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
            done (SyncFileItem.SoftError, tr ("The file %1 is currently in use").arg (newItem._file));
            return;
        }
        propagator ()._journal.commit ("localMkdir");
    
        auto resultStatus = _item._instruction == CSYNC_INSTRUCTION_CONFLICT
            ? SyncFileItem.Conflict
            : SyncFileItem.Success;
        done (resultStatus);
    }
    
    void PropagateLocalRename.start () {
        if (propagator ()._abortRequested)
            return;
    
        string existingFile = propagator ().fullLocalPath (propagator ().adjustRenamedPath (_item._file));
        string targetFile = propagator ().fullLocalPath (_item._renameTarget);
    
        // if the file is a file underneath a moved dir, the _item.file is equal
        // to _item.renameTarget and the file is not moved as a result.
        if (_item._file != _item._renameTarget) {
            propagator ().reportProgress (*_item, 0);
            qCDebug (lcPropagateLocalRename) << "MOVE " << existingFile << " => " << targetFile;
    
            if (string.compare (_item._file, _item._renameTarget, Qt.CaseInsensitive) != 0
                && propagator ().localFileNameClash (_item._renameTarget)) {
                // Only use localFileNameClash for the destination if we know that the source was not
                // the one conflicting  (renaming  A.txt . a.txt is OK)
    
                // Fixme : the file that is the reason for the clash could be named here,
                // it would have to come out the localFileNameClash function
                done (SyncFileItem.NormalError,
                    tr ("File %1 cannot be renamed to %2 because of a local file name clash")
                        .arg (QDir.toNativeSeparators (_item._file))
                        .arg (QDir.toNativeSeparators (_item._renameTarget)));
                return;
            }
    
            emit propagator ().touchedFile (existingFile);
            emit propagator ().touchedFile (targetFile);
            string renameError;
            if (!FileSystem.rename (existingFile, targetFile, &renameError)) {
                done (SyncFileItem.NormalError, renameError);
                return;
            }
        }
    
        SyncJournalFileRecord oldRecord;
        propagator ()._journal.getFileRecord (_item._originalFile, &oldRecord);
        propagator ()._journal.deleteFileRecord (_item._originalFile);
    
        auto &vfs = propagator ().syncOptions ()._vfs;
        auto pinState = vfs.pinState (_item._originalFile);
        if (!vfs.setPinState (_item._originalFile, PinState.Inherited)) {
            qCWarning (lcPropagateLocalRename) << "Could not set pin state of" << _item._originalFile << "to inherited";
        }
    
        const auto oldFile = _item._file;
    
        if (!_item.isDirectory ()) { // Directories are saved at the end
            SyncFileItem newItem (*_item);
            if (oldRecord.isValid ()) {
                newItem._checksumHeader = oldRecord._checksumHeader;
            }
            const auto result = propagator ().updateMetadata (newItem);
            if (!result) {
                done (SyncFileItem.FatalError, tr ("Error updating metadata : %1").arg (result.error ()));
                return;
            } else if (*result == Vfs.ConvertToPlaceholderResult.Locked) {
                done (SyncFileItem.SoftError, tr ("The file %1 is currently in use").arg (newItem._file));
                return;
            }
        } else {
            propagator ()._renamedDirectories.insert (oldFile, _item._renameTarget);
            if (!PropagateRemoteMove.adjustSelectiveSync (propagator ()._journal, oldFile, _item._renameTarget)) {
                done (SyncFileItem.FatalError, tr ("Failed to rename file"));
                return;
            }
        }
        if (pinState && *pinState != PinState.Inherited
            && !vfs.setPinState (_item._renameTarget, *pinState)) {
            done (SyncFileItem.NormalError, tr ("Error setting pin state"));
            return;
        }
    
        propagator ()._journal.commit ("localRename");
    
        done (SyncFileItem.Success);
    }
    }
    