/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QFileDialog>
//  #include <Gtk.MessageBox>

namespace Occ {
namespace Ui {

public class ConflictSolver : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public enum Solution {
        KEEP_LOCAL_VERSION,
        KEEP_REMOTE_VERSION,
        KEEP_BOTH_VERSION
    }


    /***********************************************************
    ***********************************************************/
    private Gtk.Widget parent_widget;
    string local_version_filename {
        public get {
            return this.local_version_filename;
        }
        private set {
            this.local_version_filename = value;
        }
    }
    string remote_version_filename {
        public get {
            return this.remote_version_filename;
        }
        private set {
            this.remote_version_filename = value;
        }
    }


    internal signal void signal_local_version_filename_changed ();
    internal signal void signal_remote_version_filename_changed ();


    /***********************************************************
    ***********************************************************/
    public ConflictSolver (Gtk.Widget parent_widget = null) {
        base (parent_widget);
        this.parent_widget = parent_widget;
    }


    /***********************************************************
    ***********************************************************/
    public bool exec (ConflictSolver.Solution solution) {
        switch (solution) {
        case Solution.KEEP_LOCAL_VERSION:
            return overwrite_remote_version ();
        case Solution.KEEP_REMOTE_VERSION:
            return delete_local_version ();
        case Solution.KEEP_BOTH_VERSION:
            return rename_local_version ();
        }
        GLib.assert_not_reached ();
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_local_version_filename (string local_version_filename) {
        if (this.local_version_filename == local_version_filename) {
            return;
        }

        this.local_version_filename = local_version_filename;
        /* emit */ signal_local_version_filename_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_remote_version_filename (string remote_version_filename) {
        if (this.remote_version_filename == remote_version_filename) {
            return;
        }

        this.remote_version_filename = remote_version_filename;
        /* emit */ signal_remote_version_filename_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private bool delete_local_version () {
        if (this.local_version_filename == "") {
            return false;
        }

        GLib.FileInfo info = new GLib.FileInfo (this.local_version_filename);
        if (!info.exists ()) {
            return false;
        }

        const string message = info.is_dir () ? _("Do you want to delete the directory <i>%1</i> and all its contents permanently?").printf (info.directory ().dir_name ())
                                          : _("Do you want to delete the file <i>%1</i> permanently?").printf (info.filename ());
        if (Gtk.MessageBox.question (this.parent_widget, _("Confirm deletion"), message, Gtk.MessageBox.Yes, Gtk.MessageBox.No) != Gtk.MessageBox.Yes) {
            return false;
        }

        if (info.is_dir ()) {
            return FileSystem.remove_recursively (this.local_version_filename);
        } else {
            return GLib.File (this.local_version_filename).remove ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private bool rename_local_version () {
        if (this.local_version_filename == "") {
            return false;
        }

        GLib.FileInfo info = new GLib.FileInfo (this.local_version_filename);
        if (!info.exists ()) {
            return false;
        }

        string error;
        if (FileSystem.unchecked_rename_replace (this.local_version_filename, target_filename, error)) {
            return true;
        } else {
            GLib.warning ("Rename error: " + error);
            Gtk.MessageBox.warning (this.parent_widget, _("Error"), _("Moving file failed:\n\n%1").printf (error));
            return false;
        }
    }


    /***********************************************************
    ***********************************************************/
    private string rename_pattern () {
        string result = Utility.conflict_file_base_name_from_pattern (this.local_version_filename.to_utf8 ());
        const string dot_index = result.last_index_of ('.');
        return result.left (dot_index) + "this.%1" + result.mid (dot_index);
    }


    /***********************************************************
    ***********************************************************/
    private string target_filename () {
        uint32 i = 1;
        var result = rename_pattern ().printf (i);
        while (GLib.FileInfo.exists (result)) {
            //  Q_ASSERT (i > 0);
            i++;
            result = rename_pattern ().printf (i);
        }
        return result;
    }


    /***********************************************************
    ***********************************************************/
    private bool overwrite_remote_version () {
        if (this.local_version_filename == "") {
            return false;
        }

        if (this.remote_version_filename == "") {
            return false;
        }

        GLib.FileInfo info = new GLib.FileInfo (this.local_version_filename);
        if (!info.exists ()) {
            return false;
        }

        string error;
        if (FileSystem.unchecked_rename_replace (this.local_version_filename, this.remote_version_filename, error)) {
            return true;
        } else {
            GLib.warning ("Rename error: " + error);
            Gtk.MessageBox.warning (this.parent_widget, _("Error"), _("Moving file failed:\n\n%1").printf (error));
            return false;
        }
    }

} // class ConflictSolver

} // namespace Ui
} // namespace Occ
