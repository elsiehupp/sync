/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <folder.h>
//  #include <QPush
//  #include <QDir>
//  #include <qabstractbutton.h
//  #include <QDialogBut
//  #include <GLib.FileInfo>
//  #include <QPushButton>

//  #include <array>

//  #include <accountfwd.h>
//  #include <account.h>
//  #include <memory>

//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

class InvalidFilenameDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private std.unique_ptr<Ui.InvalidFilenameDialog> ui;

    /***********************************************************
    ***********************************************************/
    private AccountPointer account;
    private Folder folder;
    private string file_path;
    private string relative_file_path;
    private string original_filename;
    private string new_filename;

    /***********************************************************
    ***********************************************************/
    public InvalidFilenameDialog (AccountPointer account, Folder folder, string file_path, Gtk.Widget parent = null);
    InvalidFilenameDialog.InvalidFilenameDialog (AccountPointer account, Folder folder, string file_path, Gtk.Widget parent)
        : Gtk.Dialog (parent)
        this.ui (new Ui.InvalidFilenameDialog)
        this.account (account)
        this.folder (folder)
        this.file_path (std.move (file_path)) {
        //  Q_ASSERT (this.account);
        //  Q_ASSERT (this.folder);

        const var file_path_file_info = GLib.FileInfo (this.file_path);
        this.relative_file_path = file_path_file_info.path () + "/";
        this.relative_file_path = this.relative_file_path.replace (folder.path (), "");
        this.relative_file_path = this.relative_file_path.is_empty () ? "" : this.relative_file_path + "/";

        this.original_filename = this.relative_file_path + file_path_file_info.filename ();

        this.ui.up_ui (this);
        this.ui.button_box.button (QDialogButtonBox.Ok).enabled (false);
        this.ui.button_box.button (QDialogButtonBox.Ok).on_signal_text (_("Rename file"));

        this.ui.description_label.on_signal_text (_("The file %1 could not be synced because the name contains characters which are not allowed on this system.").arg (this.original_filename));
        this.ui.explanation_label.on_signal_text (_("The following characters are not allowed on the system : * \" | & ? , ; : \\ / ~ < >"));
        this.ui.filename_line_edit.on_signal_text (file_path_file_info.filename ());

        connect (this.ui.button_box, QDialogButtonBox.accepted, this, Gtk.Dialog.accept);
        connect (this.ui.button_box, QDialogButtonBox.rejected, this, Gtk.Dialog.reject);

        connect (this.ui.filename_line_edit, QLineEdit.text_changed, this,
            &InvalidFilenameDialog.on_signal_filename_line_edit_text_changed);

        check_if_allowed_to_rename ();
    }


    /***********************************************************
    ***********************************************************/
    public void override on_signal_accept () {
        this.new_filename = this.relative_file_path + this.ui.filename_line_edit.text ().trimmed ();
        const var propfind_job = new PropfindJob (this.account, QDir.clean_path (this.folder.remote_path () + this.new_filename));
        connect (propfind_job, PropfindJob.result, this, InvalidFilenameDialog.on_signal_remote_file_already_exists);
        connect (propfind_job, PropfindJob.finished_with_error, this, InvalidFilenameDialog.on_signal_remote_file_does_not_exist);
        propfind_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_filename_line_edit_text_changed (string text) {
        const var is_new_filename_different = text != this.original_filename;
        const var illegal_contained_characters = get_illegal_chars_from_string (text);
        const var contains_illegal_chars = !illegal_contained_characters.empty () || text.ends_with ('.');
        const var is_text_valid = is_new_filename_different && !contains_illegal_chars;

        if (is_text_valid) {
            this.ui.error_label.on_signal_text ("");
        } else {
            this.ui.error_label.on_signal_text (_("Filename contains illegal characters : %1")
                                         .arg (illegal_character_list_to_string (illegal_contained_characters)));
        }

        this.ui.button_box.button (QDialogButtonBox.Ok)
            .enabled (is_text_valid);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_move_job_finished () {
        const var job = qobject_cast<MoveJob> (sender ());
        const var error = job.reply ().error ();

        if (error != Soup.Reply.NoError) {
            this.ui.error_label.on_signal_text (_("Could not rename file. Please make sure you are connected to the server."));
            return;
        }

        Gtk.Dialog.on_signal_accept ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_remote_file_already_exists (QVariantMap values) {
        //  Q_UNUSED (values);

        this.ui.error_label.on_signal_text (_("Cannot rename file because a file with the same name does already exist on the server. Please pick another name."));
        this.ui.button_box.button (QDialogButtonBox.Ok).enabled (false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_remote_file_does_not_exist (Soup.Reply reply) {
        //  Q_UNUSED (reply);

        // File does not exist. We can rename it.
        const var remote_source = QDir.clean_path (this.folder.remote_path () + this.original_filename);
        const var remote_destionation = QDir.clean_path (this.account.dav_url ().path () + this.folder.remote_path () + this.new_filename);
        const var move_job = new MoveJob (this.account, remote_source, remote_destionation, this);
        connect (move_job, MoveJob.finished_signal, this, InvalidFilenameDialog.on_signal_move_job_finished);
        move_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void check_if_allowed_to_rename () {
        const var propfind_job = new PropfindJob (this.account, QDir.clean_path (this.folder.remote_path () + this.original_filename));
        propfind_job.properties ({
            "http://owncloud.org/ns:permissions"
        });
        connect (propfind_job, PropfindJob.result, this, InvalidFilenameDialog.on_signal_propfind_permission_success);
        propfind_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_propfind_permission_success (QVariantMap values) {
        if (!values.contains ("permissions")) {
            return;
        }
        const var remote_permissions = RemotePermissions.from_server_string (values["permissions"].to_string ());
        if (!remote_permissions.has_permission (remote_permissions.Permissions.CAN_RENAME)
            || !remote_permissions.has_permission (remote_permissions.Permissions.CAN_MOVE)) {
            this.ui.error_label.on_signal_text (
                _("You don't have the permission to rename this file. Please ask the author of the file to rename it."));
            this.ui.button_box.button (QDialogButtonBox.Ok).enabled (false);
            this.ui.filename_line_edit.enabled (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    private static constexpr std.array<char, 9> illegal_characters ({
        '\\', '/', ':', '?', '*', '\"', '<', '>', '|'
    });


    /***********************************************************
    ***********************************************************/
    private static GLib.Vector<char> get_illegal_chars_from_string (string string) {
        GLib.Vector<char> result;
        for (var character : string) {
            if (std.find (illegal_characters.begin (), illegal_characters.end (), character)
                != illegal_characters.end ()) {
                result.push_back (character);
            }
        }
        return result;
    }


    /***********************************************************
    ***********************************************************/
    private static string illegal_character_list_to_string (GLib.Vector<char> illegal_characters) {
        string illegal_characters_string;
        if (illegal_characters.size () > 0) {
            illegal_characters_string += illegal_characters[0];
        }

        for (int i = 1; i < illegal_characters.count (); ++i) {
            if (illegal_characters_string.contains (illegal_characters[i])) {
                continue;
            }
            illegal_characters_string += " " + illegal_characters[i];
        }
        return illegal_characters_string;
    }

} // class InvalidFilenameDialog

} // namespace Ui
} // namespace Occ
