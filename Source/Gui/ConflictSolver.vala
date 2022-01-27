/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QFileDialog>
// #include <QMessageBox>

namespace Occ {

class ConflictSolver : GLib.Object {
    Q_PROPERTY (string local_version_filename READ local_version_filename WRITE on_set_local_version_filename NOTIFY local_version_filename_changed)
    Q_PROPERTY (string remote_version_filename READ remote_version_filename WRITE on_set_remote_version_filename NOTIFY remote_version_filename_changed)

    public enum Solution {
        KeepLocalVersion,
        KeepRemoteVersion,
        KeepBothVersions
    };

    public ConflictSolver (Gtk.Widget *parent = nullptr);

    public string local_version_filename ();
    public string remote_version_filename ();

    public bool exec (Solution solution);


    public void on_set_local_version_filename (string local_version_filename);
    public void on_set_remote_version_filename (string remote_version_filename);

signals:
    void local_version_filename_changed ();
    void remote_version_filename_changed ();


    private bool delete_local_version ();
    private bool rename_local_version ();
    private bool overwrite_remote_version ();

    private Gtk.Widget _parent_widget;
    private string _local_version_filename;
    private string _remote_version_filename;
};

    ConflictSolver.ConflictSolver (Gtk.Widget *parent)
        : GLib.Object (parent)
        , _parent_widget (parent) {
    }

    string ConflictSolver.local_version_filename () {
        return _local_version_filename;
    }

    string ConflictSolver.remote_version_filename () {
        return _remote_version_filename;
    }

    bool ConflictSolver.exec (ConflictSolver.Solution solution) {
        switch (solution) {
        case KeepLocalVersion:
            return overwrite_remote_version ();
        case KeepRemoteVersion:
            return delete_local_version ();
        case KeepBothVersions:
            return rename_local_version ();
        }
        Q_UNREACHABLE ();
        return false;
    }

    void ConflictSolver.on_set_local_version_filename (string local_version_filename) {
        if (_local_version_filename == local_version_filename) {
            return;
        }

        _local_version_filename = local_version_filename;
        emit local_version_filename_changed ();
    }

    void ConflictSolver.on_set_remote_version_filename (string remote_version_filename) {
        if (_remote_version_filename == remote_version_filename) {
            return;
        }

        _remote_version_filename = remote_version_filename;
        emit remote_version_filename_changed ();
    }

    bool ConflictSolver.delete_local_version () {
        if (_local_version_filename.is_empty ()) {
            return false;
        }

        QFileInfo info (_local_version_filename);
        if (!info.exists ()) {
            return false;
        }

        const auto message = info.is_dir () ? tr ("Do you want to delete the directory <i>%1</i> and all its contents permanently?").arg (info.dir ().dir_name ())
                                          : tr ("Do you want to delete the file <i>%1</i> permanently?").arg (info.file_name ());
        const auto result = QMessageBox.question (_parent_widget, tr ("Confirm deletion"), message, QMessageBox.Yes, QMessageBox.No);
        if (result != QMessageBox.Yes)
            return false;

        if (info.is_dir ()) {
            return FileSystem.remove_recursively (_local_version_filename);
        } else {
            return QFile (_local_version_filename).remove ();
        }
    }

    bool ConflictSolver.rename_local_version () {
        if (_local_version_filename.is_empty ()) {
            return false;
        }

        QFileInfo info (_local_version_filename);
        if (!info.exists ()) {
            return false;
        }

        const auto rename_pattern = [=] {
            auto result = string.from_utf8 (Occ.Utility.conflict_file_base_name_from_pattern (_local_version_filename.to_utf8 ()));
            const auto dot_index = result.last_index_of ('.');
            return string (result.left (dot_index) + "_%1" + result.mid (dot_index));
        } ();

        const auto target_filename = [=] {
            uint i = 1;
            auto result = rename_pattern.arg (i);
            while (QFileInfo.exists (result)) {
                Q_ASSERT (i > 0);
                i++;
                result = rename_pattern.arg (i);
            }
            return result;
        } ();

        string error;
        if (FileSystem.unchecked_rename_replace (_local_version_filename, target_filename, &error)) {
            return true;
        } else {
            q_c_warning (lc_conflict) << "Rename error:" << error;
            QMessageBox.warning (_parent_widget, tr ("Error"), tr ("Moving file failed:\n\n%1").arg (error));
            return false;
        }
    }

    bool ConflictSolver.overwrite_remote_version () {
        if (_local_version_filename.is_empty ()) {
            return false;
        }

        if (_remote_version_filename.is_empty ()) {
            return false;
        }

        QFileInfo info (_local_version_filename);
        if (!info.exists ()) {
            return false;
        }

        string error;
        if (FileSystem.unchecked_rename_replace (_local_version_filename, _remote_version_filename, &error)) {
            return true;
        } else {
            q_c_warning (lc_conflict) << "Rename error:" << error;
            QMessageBox.warning (_parent_widget, tr ("Error"), tr ("Moving file failed:\n\n%1").arg (error));
            return false;
        }
    }

    } // namespace Occ
    