/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <folder_connection.h>
//  #include <GLib.Push
//  #include <GLib.Dir>
//  #include <qabstractbutton.h
//  #include <GLib.DialogBut
//  #include <GLib.FileInfo>
//  #include <GLib.PushButton>

//  #include <array>

//  #include <accountfwd.h>
//  #include <account.h>
//  #include <memory>

//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

public class InvalidFilenameDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private InvalidFilenameDialog instance;

    /***********************************************************
    ***********************************************************/
    private unowned Account account;
    private FolderConnection folder_connection;
    private string file_path;
    private string relative_file_path;
    private string original_filename;
    private string new_filename;

    /***********************************************************
    ***********************************************************/
    public InvalidFilenameDialog (unowned Account account, FolderConnection folder_connection, string file_path, Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.instance = new InvalidFilenameDialog ();
        this.account = account;
        this.folder_connection = folder_connection;
        this.file_path = std.move (file_path);
        //  Q_ASSERT (this.account);
        //  Q_ASSERT (this.folder_connection);

        GLib.FileInfo file_path_file_info = new GLib.FileInfo (this.file_path);
        this.relative_file_path = file_path_file_info.path + "/";
        this.relative_file_path = this.relative_file_path.replace (folder_connection.path, "");
        this.relative_file_path = this.relative_file_path == "" ? "" : this.relative_file_path + "/";

        this.original_filename = this.relative_file_path + file_path_file_info.filename ();

        this.instance.up_ui (this);
        this.instance.button_box.button (GLib.DialogButtonBox.Ok).enabled (false);
        this.instance.button_box.button (GLib.DialogButtonBox.Ok).on_signal_text (_("Rename file"));

        this.instance.description_label.on_signal_text (_("The file %1 could not be synced because the name contains characters which are not allowed on this system.").printf (this.original_filename));
        this.instance.explanation_label.on_signal_text (_("The following characters are not allowed on the system : * \" | & ? , ; : \\ / ~ < >"));
        this.instance.filename_line_edit.on_signal_text (file_path_file_info.filename ());

        this.instance.button_box.accepted.connect (
            this.accept
        );
        this.instance.button_box.rejected.connect (
            this.reject
        );
        this.instance.filename_line_edit.text_changed.connect (
            this.on_signal_filename_line_edit_text_changed
        );

        check_if_allowed_to_rename ();
    }


    /***********************************************************
    ***********************************************************/
    public override void on_signal_accept () {
        this.new_filename = this.relative_file_path + this.instance.filename_line_edit.text ().trimmed ();
        var propfind_job = new PropfindJob (this.account, GLib.Dir.clean_path (this.folder_connection.remote_path + this.new_filename));
        propfind_job.signal_result.connect (
            this.on_signal_remote_file_already_exists
        );
        propfind_job.signal_finished_with_error.connect (
            this.on_signal_remote_file_does_not_exist
        );
        propfind_job.start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_filename_line_edit_text_changed (string text) {
        bool is_new_filename_different = text != this.original_filename;
        string illegal_contained_characters = illegal_chars_from_string (text);
        bool contains_illegal_chars = !illegal_contained_characters.empty () || text.has_suffix ('.');
        bool is_text_valid = is_new_filename_different && !contains_illegal_chars;

        if (is_text_valid) {
            this.instance.error_label.on_signal_text ("");
        } else {
            this.instance.error_label.on_signal_text (_("Filename contains illegal characters : %1")
                                         .printf (illegal_character_list_to_string (illegal_contained_characters)));
        }

        this.instance.button_box.button (GLib.DialogButtonBox.Ok)
            .enabled (is_text_valid);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_move_job_finished () {
        var move_job = (MoveJob)sender ();
        var error = move_job.input_stream.error;

        if (error != GLib.InputStream.NoError) {
            this.instance.error_label.on_signal_text (_("Could not rename file. Please make sure you are connected to the server."));
            return;
        }

        Gtk.Dialog.on_signal_accept ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_remote_file_already_exists (GLib.VariantMap values) {
        //  Q_UNUSED (values);

        this.instance.error_label.on_signal_text (_("Cannot rename file because a file with the same name does already exist on the server. Please pick another name."));
        this.instance.button_box.button (GLib.DialogButtonBox.Ok).enabled (false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_remote_file_does_not_exist (GLib.InputStream reply) {
        //  Q_UNUSED (reply);

        // File does not exist. We can rename it.
        var remote_source = GLib.Dir.clean_path (this.folder_connection.remote_path + this.original_filename);
        var remote_destionation = GLib.Dir.clean_path (this.account.dav_url ().path + this.folder_connection.remote_path + this.new_filename);
        var move_job = new MoveJob (
            this.account,
            remote_source,
            remote_destionation,
            this
        );
        move_job.finished_signal.connect (
            this.on_signal_move_job_finished
        );
        move_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void check_if_allowed_to_rename () {
        var propfind_job = new PropfindJob (this.account, GLib.Dir.clean_path (this.folder_connection.remote_path + this.original_filename));
        propfind_job.properties ({
            "http://owncloud.org/ns:permissions"
        });
        propfind_job.result.connect (
            this.on_signal_propfind_permission_success
        );
        propfind_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_propfind_permission_success (GLib.VariantMap values) {
        if (!values.contains ("permissions")) {
            return;
        }
        var remote_permissions = RemotePermissions.from_server_string (values["permissions"].to_string ());
        if (!remote_permissions.has_permission (remote_permissions.Permissions.CAN_RENAME)
            || !remote_permissions.has_permission (remote_permissions.Permissions.CAN_MOVE)) {
            this.instance.error_label.on_signal_text (
                _("You don't have the permission to rename this file. Please ask the author of the file to rename it."));
            this.instance.button_box.button (GLib.DialogButtonBox.Ok).enabled (false);
            this.instance.filename_line_edit.enabled (false);
        }
    }


    /***********************************************************
    ***********************************************************/
    private const char[] illegal_characters = {
        '\\',
        "/",
        ':',
        '?',
        '*',
        '\"',
        '<',
        '>',
        '|'
    };


    /***********************************************************
    ***********************************************************/
    private static GLib.List<char> illegal_chars_from_string (string string) {
        GLib.List<char> result;
        foreach (var character in string) {
            if (std.find (illegal_characters.begin (), illegal_characters.end (), character)
                != illegal_characters.end ()) {
                result.push_back (character);
            }
        }
        return result;
    }


    /***********************************************************
    ***********************************************************/
    private static string illegal_character_list_to_string (GLib.List<char> illegal_characters) {
        string illegal_characters_string;
        if (illegal_characters.length () > 0) {
            illegal_characters_string += illegal_characters[0];
        }

        for (int i = 1; i < illegal_characters.length (); ++i) {
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
