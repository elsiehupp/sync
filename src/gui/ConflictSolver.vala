/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <GLib.Object>


namespace Occ {

class ConflictSolver : GLib.Object {
    Q_PROPERTY (string localVersionFilename READ localVersionFilename WRITE setLocalVersionFilename NOTIFY localVersionFilenameChanged)
    Q_PROPERTY (string remoteVersionFilename READ remoteVersionFilename WRITE setRemoteVersionFilename NOTIFY remoteVersionFilenameChanged)
public:
    enum Solution {
        KeepLocalVersion,
        KeepRemoteVersion,
        KeepBothVersions
    };

    ConflictSolver (Gtk.Widget *parent = nullptr);

    string localVersionFilename ();
    string remoteVersionFilename ();

    bool exec (Solution solution);

public slots:
    void setLocalVersionFilename (string &localVersionFilename);
    void setRemoteVersionFilename (string &remoteVersionFilename);

signals:
    void localVersionFilenameChanged ();
    void remoteVersionFilenameChanged ();

private:
    bool deleteLocalVersion ();
    bool renameLocalVersion ();
    bool overwriteRemoteVersion ();

    Gtk.Widget *_parentWidget;
    string _localVersionFilename;
    string _remoteVersionFilename;
};

} // namespace Occ





/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QFileDialog>
// #include <QMessageBox>

namespace Occ {

    Q_LOGGING_CATEGORY (lcConflict, "nextcloud.gui.conflictsolver", QtInfoMsg)
    
    ConflictSolver.ConflictSolver (Gtk.Widget *parent)
        : GLib.Object (parent)
        , _parentWidget (parent) {
    }
    
    string ConflictSolver.localVersionFilename () {
        return _localVersionFilename;
    }
    
    string ConflictSolver.remoteVersionFilename () {
        return _remoteVersionFilename;
    }
    
    bool ConflictSolver.exec (ConflictSolver.Solution solution) {
        switch (solution) {
        case KeepLocalVersion:
            return overwriteRemoteVersion ();
        case KeepRemoteVersion:
            return deleteLocalVersion ();
        case KeepBothVersions:
            return renameLocalVersion ();
        }
        Q_UNREACHABLE ();
        return false;
    }
    
    void ConflictSolver.setLocalVersionFilename (string &localVersionFilename) {
        if (_localVersionFilename == localVersionFilename) {
            return;
        }
    
        _localVersionFilename = localVersionFilename;
        emit localVersionFilenameChanged ();
    }
    
    void ConflictSolver.setRemoteVersionFilename (string &remoteVersionFilename) {
        if (_remoteVersionFilename == remoteVersionFilename) {
            return;
        }
    
        _remoteVersionFilename = remoteVersionFilename;
        emit remoteVersionFilenameChanged ();
    }
    
    bool ConflictSolver.deleteLocalVersion () {
        if (_localVersionFilename.isEmpty ()) {
            return false;
        }
    
        QFileInfo info (_localVersionFilename);
        if (!info.exists ()) {
            return false;
        }
    
        const auto message = info.isDir () ? tr ("Do you want to delete the directory <i>%1</i> and all its contents permanently?").arg (info.dir ().dirName ())
                                          : tr ("Do you want to delete the file <i>%1</i> permanently?").arg (info.fileName ());
        const auto result = QMessageBox.question (_parentWidget, tr ("Confirm deletion"), message, QMessageBox.Yes, QMessageBox.No);
        if (result != QMessageBox.Yes)
            return false;
    
        if (info.isDir ()) {
            return FileSystem.removeRecursively (_localVersionFilename);
        } else {
            return QFile (_localVersionFilename).remove ();
        }
    }
    
    bool ConflictSolver.renameLocalVersion () {
        if (_localVersionFilename.isEmpty ()) {
            return false;
        }
    
        QFileInfo info (_localVersionFilename);
        if (!info.exists ()) {
            return false;
        }
    
        const auto renamePattern = [=] {
            auto result = string.fromUtf8 (Occ.Utility.conflictFileBaseNameFromPattern (_localVersionFilename.toUtf8 ()));
            const auto dotIndex = result.lastIndexOf ('.');
            return string (result.left (dotIndex) + "_%1" + result.mid (dotIndex));
        } ();
    
        const auto targetFilename = [=] {
            uint i = 1;
            auto result = renamePattern.arg (i);
            while (QFileInfo.exists (result)) {
                Q_ASSERT (i > 0);
                i++;
                result = renamePattern.arg (i);
            }
            return result;
        } ();
    
        string error;
        if (FileSystem.uncheckedRenameReplace (_localVersionFilename, targetFilename, &error)) {
            return true;
        } else {
            qCWarning (lcConflict) << "Rename error:" << error;
            QMessageBox.warning (_parentWidget, tr ("Error"), tr ("Moving file failed:\n\n%1").arg (error));
            return false;
        }
    }
    
    bool ConflictSolver.overwriteRemoteVersion () {
        if (_localVersionFilename.isEmpty ()) {
            return false;
        }
    
        if (_remoteVersionFilename.isEmpty ()) {
            return false;
        }
    
        QFileInfo info (_localVersionFilename);
        if (!info.exists ()) {
            return false;
        }
    
        string error;
        if (FileSystem.uncheckedRenameReplace (_localVersionFilename, _remoteVersionFilename, &error)) {
            return true;
        } else {
            qCWarning (lcConflict) << "Rename error:" << error;
            QMessageBox.warning (_parentWidget, tr ("Error"), tr ("Moving file failed:\n\n%1").arg (error));
            return false;
        }
    }
    
    } // namespace Occ
    