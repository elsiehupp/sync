/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <limits>
//  #include <GLib.Dir>
//  #include <Gtk.MessageBox>

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
        instance = new FolderCreationDialog ();
        this.destination = destination;
        instance.up_ui (this);

        instance.label_error_message.visible (false);

        window_flags (window_flags () & ~GLib.WindowContextHelpButtonHint);

        instance.new_folder_name_edit.text_changed.connect (
            this.on_signal_new_folder_name_edit_text_edited
        );

        string suggested_folder_name_prefix = _("New folder");

        string new_folder_full_path = this.destination + "/" + suggested_folder_name_prefix;
        if (!new GLib.Dir (new_folder_full_path).exists ()) {
            instance.new_folder_name_edit.on_signal_text (suggested_folder_name_prefix);
        } else {
            for (uint32 i = 2; i < std.numeric_limits<uint32>.max (); ++i) {
                string suggested_postfix = " (%1)".printf (i);

                if (!new GLib.Dir (new_folder_full_path + suggested_postfix).exists ()) {
                    instance.new_folder_name_edit.on_signal_text (suggested_folder_name_prefix + suggested_postfix);
                    break;
                }
            }
        }

        instance.new_folder_name_edit.focus ();
        instance.new_folder_name_edit.select_all ();
    }


    ~FolderCreationDialog () {
        //  delete this.instance;
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_accept () {
        //  Q_ASSERT (!this.destination.has_suffix ("/"));

        if (new GLib.Dir (this.destination + "/" + instance.new_folder_name_edit.text ()).exists ()) {
            instance.label_error_message.visible (true);
            return;
        }

        if (!new GLib.Dir (this.destination).mkdir (instance.new_folder_name_edit.text ())) {
            Gtk.MessageBox.critical (this, _("Error"), _("Could not create a folder! Check your write permissions."));
        }

        Gtk.Dialog.on_signal_accept ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_new_folder_name_edit_text_edited () {
        if (!instance.new_folder_name_edit.text () == "" && new GLib.Dir (this.destination + "/" + instance.new_folder_name_edit.text ()).exists ()) {
            instance.label_error_message.visible (true);
        } else {
            instance.label_error_message.visible (false);
        }
    }

} // class FolderCreationDialog

} // namespace Ui
} // namespace Occ
