/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <limits>
//  #include <GLib.Dir>
//  #include <Gtk.MessageBox>
//  #include <QLoggingCategory>

//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

public class FolderCreationDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private string destination;

    /***********************************************************
    ***********************************************************/
    public FolderCreationDialog (string destination, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        ui = new Ui.FolderCreationDialog ();
        this.destination = destination;
        ui.up_ui (this);

        ui.label_error_message.visible (false);

        window_flags (window_flags () & ~Qt.WindowContextHelpButtonHint);

        ui.new_folder_name_edit.text_changed.connect (
            this.on_signal_new_folder_name_edit_text_edited
        );

        const string suggested_folder_name_prefix = _("New folder");

        const string new_folder_full_path = this.destination + '/' + suggested_folder_name_prefix;
        if (!GLib.Dir (new_folder_full_path).exists ()) {
            ui.new_folder_name_edit.on_signal_text (suggested_folder_name_prefix);
        } else {
            for (uint32 i = 2; i < std.numeric_limits<uint32>.max (); ++i) {
                const string suggested_postfix = string (" (%1)").printf (i);

                if (!GLib.Dir (new_folder_full_path + suggested_postfix).exists ()) {
                    ui.new_folder_name_edit.on_signal_text (suggested_folder_name_prefix + suggested_postfix);
                    break;
                }
            }
        }

        ui.new_folder_name_edit.focus ();
        ui.new_folder_name_edit.select_all ();
    }


    ~FolderCreationDialog () {
        delete ui;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_accept () {
        //  Q_ASSERT (!this.destination.ends_with ('/'));

        if (GLib.Dir (this.destination + "/" + ui.new_folder_name_edit.text ()).exists ()) {
            ui.label_error_message.visible (true);
            return;
        }

        if (!GLib.Dir (this.destination).mkdir (ui.new_folder_name_edit.text ())) {
            Gtk.MessageBox.critical (this, _("Error"), _("Could not create a folder! Check your write permissions."));
        }

        Gtk.Dialog.on_signal_accept ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_new_folder_name_edit_text_edited () {
        if (!ui.new_folder_name_edit.text () == "" && GLib.Dir (this.destination + "/" + ui.new_folder_name_edit.text ()).exists ()) {
            ui.label_error_message.visible (true);
        } else {
            ui.label_error_message.visible (false);
        }
    }

} // class FolderCreationDialog

} // namespace Ui
} // namespace Occ
