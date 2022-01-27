/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <limits>

// #include <QDir>
// #include <QMessageBox>
// #include <QLoggingCategory>

// #include <Gtk.Dialog>

namespace Occ {

namespace Ui {
}

class FolderCreationDialog : Gtk.Dialog {

    public FolderCreationDialog (string destination, Gtk.Widget *parent = nullptr);
    ~FolderCreationDialog () override;


    private void on_accept () override;

    private void on_new_folder_name_edit_text_edited ();


    private Ui.FolderCreationDialog *ui;

    private string _destination;
};


    FolderCreationDialog.FolderCreationDialog (string destination, Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , ui (new Ui.FolderCreationDialog)
        , _destination (destination) {
        ui.setup_ui (this);

        ui.label_error_message.set_visible (false);

        set_window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);

        connect (ui.new_folder_name_edit, &QLineEdit.text_changed, this, &FolderCreationDialog.on_new_folder_name_edit_text_edited);

        const string suggested_folder_name_prefix = GLib.Object.tr ("New folder");

        const string new_folder_full_path = _destination + QLatin1Char ('/') + suggested_folder_name_prefix;
        if (!QDir (new_folder_full_path).exists ()) {
            ui.new_folder_name_edit.on_set_text (suggested_folder_name_prefix);
        } else {
            for (unsigned int i = 2; i < std.numeric_limits<unsigned int>.max (); ++i) {
                const string suggested_postfix = string (" (%1)").arg (i);

                if (!QDir (new_folder_full_path + suggested_postfix).exists ()) {
                    ui.new_folder_name_edit.on_set_text (suggested_folder_name_prefix + suggested_postfix);
                    break;
                }
            }
        }

        ui.new_folder_name_edit.set_focus ();
        ui.new_folder_name_edit.select_all ();
    }

    FolderCreationDialog.~FolderCreationDialog () {
        delete ui;
    }

    void FolderCreationDialog.on_accept () {
        Q_ASSERT (!_destination.ends_with ('/'));

        if (QDir (_destination + "/" + ui.new_folder_name_edit.text ()).exists ()) {
            ui.label_error_message.set_visible (true);
            return;
        }

        if (!QDir (_destination).mkdir (ui.new_folder_name_edit.text ())) {
            QMessageBox.critical (this, tr ("Error"), tr ("Could not create a folder! Check your write permissions."));
        }

        Gtk.Dialog.on_accept ();
    }

    void FolderCreationDialog.on_new_folder_name_edit_text_edited () {
        if (!ui.new_folder_name_edit.text ().is_empty () && QDir (_destination + "/" + ui.new_folder_name_edit.text ()).exists ()) {
            ui.label_error_message.set_visible (true);
        } else {
            ui.label_error_message.set_visible (false);
        }
    }

    }
    