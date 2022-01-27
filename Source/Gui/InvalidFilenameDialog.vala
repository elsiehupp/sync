/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <folder.h>

// #include <QPushButton>
// #include <QDir>
// #include <qabstractbutton.h>
// #include <QDialogButtonBox>
// #include <QFileInfo>
// #include <QPushButton>

// #include <array>

// #pragma once

// #include <accountfwd.h>
// #include <account.h>

// #include <memory>

// #include <Gtk.Dialog>

namespace {
    constexpr std.array<QChar, 9> illegal_characters ({
        '\\', '/', ':', '?', '*', '\"', '<', '>', '|'
    });

    QVector<QChar> get_illegal_chars_from_string (string string) {
        QVector<QChar> result;
        for (auto &character : string) {
            if (std.find (illegal_characters.begin (), illegal_characters.end (), character)
                != illegal_characters.end ()) {
                result.push_back (character);
            }
        }
        return result;
    }

    string illegal_character_list_to_string (QVector<QChar> &illegal_characters) {
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
}

namespace Occ {


namespace Ui {
    class Invalid_filename_dialog;
}

class Invalid_filename_dialog : Gtk.Dialog {

    public Invalid_filename_dialog (AccountPtr account, Folder *folder, string file_path, Gtk.Widget *parent = nullptr);

    ~Invalid_filename_dialog () override;

    public void on_accept () override;


    private std.unique_ptr<Ui.Invalid_filename_dialog> _ui;

    private AccountPtr _account;
    private Folder _folder;
    private string _file_path;
    private string _relative_file_path;
    private string _original_file_name;
    private string _new_filename;

    private void on_filename_line_edit_text_changed (string text);
    private void on_move_job_finished ();
    private void on_remote_file_already_exists (QVariantMap &values);
    private void on_remote_file_does_not_exist (QNetworkReply *reply);
    private void check_if_allowed_to_rename ();
    private void on_propfind_permission_success (QVariantMap &values);
};


    Invalid_filename_dialog.Invalid_filename_dialog (AccountPtr account, Folder *folder, string file_path, Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , _ui (new Ui.Invalid_filename_dialog)
        , _account (account)
        , _folder (folder)
        , _file_path (std.move (file_path)) {
        Q_ASSERT (_account);
        Q_ASSERT (_folder);

        const auto file_path_file_info = QFileInfo (_file_path);
        _relative_file_path = file_path_file_info.path () + QStringLiteral ("/");
        _relative_file_path = _relative_file_path.replace (folder.path (), QStringLiteral (""));
        _relative_file_path = _relative_file_path.is_empty () ? QStringLiteral ("") : _relative_file_path + QStringLiteral ("/");

        _original_file_name = _relative_file_path + file_path_file_info.file_name ();

        _ui.setup_ui (this);
        _ui.button_box.button (QDialogButtonBox.Ok).set_enabled (false);
        _ui.button_box.button (QDialogButtonBox.Ok).on_set_text (tr ("Rename file"));

        _ui.description_label.on_set_text (tr ("The file %1 could not be synced because the name contains characters which are not allowed on this system.").arg (_original_file_name));
        _ui.explanation_label.on_set_text (tr ("The following characters are not allowed on the system : * \" | & ? , ; : \\ / ~ < >"));
        _ui.filename_line_edit.on_set_text (file_path_file_info.file_name ());

        connect (_ui.button_box, &QDialogButtonBox.accepted, this, &Gtk.Dialog.accept);
        connect (_ui.button_box, &QDialogButtonBox.rejected, this, &Gtk.Dialog.reject);

        connect (_ui.filename_line_edit, &QLineEdit.text_changed, this,
            &Invalid_filename_dialog.on_filename_line_edit_text_changed);

        check_if_allowed_to_rename ();
    }

    Invalid_filename_dialog.~Invalid_filename_dialog () = default;

    void Invalid_filename_dialog.check_if_allowed_to_rename () {
        const auto propfind_job = new PropfindJob (_account, QDir.clean_path (_folder.remote_path () + _original_file_name));
        propfind_job.set_properties ({
            "http://owncloud.org/ns:permissions"
        });
        connect (propfind_job, &PropfindJob.result, this, &Invalid_filename_dialog.on_propfind_permission_success);
        propfind_job.on_start ();
    }

    void Invalid_filename_dialog.on_propfind_permission_success (QVariantMap &values) {
        if (!values.contains ("permissions")) {
            return;
        }
        const auto remote_permissions = RemotePermissions.from_server_string (values["permissions"].to_string ());
        if (!remote_permissions.has_permission (remote_permissions.Can_rename)
            || !remote_permissions.has_permission (remote_permissions.Can_move)) {
            _ui.error_label.on_set_text (
                tr ("You don't have the permission to rename this file. Please ask the author of the file to rename it."));
            _ui.button_box.button (QDialogButtonBox.Ok).set_enabled (false);
            _ui.filename_line_edit.set_enabled (false);
        }
    }

    void Invalid_filename_dialog.on_accept () {
        _new_filename = _relative_file_path + _ui.filename_line_edit.text ().trimmed ();
        const auto propfind_job = new PropfindJob (_account, QDir.clean_path (_folder.remote_path () + _new_filename));
        connect (propfind_job, &PropfindJob.result, this, &Invalid_filename_dialog.on_remote_file_already_exists);
        connect (propfind_job, &PropfindJob.finished_with_error, this, &Invalid_filename_dialog.on_remote_file_does_not_exist);
        propfind_job.on_start ();
    }

    void Invalid_filename_dialog.on_filename_line_edit_text_changed (string text) {
        const auto is_new_file_name_different = text != _original_file_name;
        const auto illegal_contained_characters = get_illegal_chars_from_string (text);
        const auto contains_illegal_chars = !illegal_contained_characters.empty () || text.ends_with (QLatin1Char ('.'));
        const auto is_text_valid = is_new_file_name_different && !contains_illegal_chars;

        if (is_text_valid) {
            _ui.error_label.on_set_text ("");
        } else {
            _ui.error_label.on_set_text (tr ("Filename contains illegal characters : %1")
                                         .arg (illegal_character_list_to_string (illegal_contained_characters)));
        }

        _ui.button_box.button (QDialogButtonBox.Ok)
            .set_enabled (is_text_valid);
    }

    void Invalid_filename_dialog.on_move_job_finished () {
        const auto job = qobject_cast<Move_job> (sender ());
        const auto error = job.reply ().error ();

        if (error != QNetworkReply.NoError) {
            _ui.error_label.on_set_text (tr ("Could not rename file. Please make sure you are connected to the server."));
            return;
        }

        Gtk.Dialog.on_accept ();
    }

    void Invalid_filename_dialog.on_remote_file_already_exists (QVariantMap &values) {
        Q_UNUSED (values);

        _ui.error_label.on_set_text (tr ("Cannot rename file because a file with the same name does already exist on the server. Please pick another name."));
        _ui.button_box.button (QDialogButtonBox.Ok).set_enabled (false);
    }

    void Invalid_filename_dialog.on_remote_file_does_not_exist (QNetworkReply *reply) {
        Q_UNUSED (reply);

        // File does not exist. We can rename it.
        const auto remote_source = QDir.clean_path (_folder.remote_path () + _original_file_name);
        const auto remote_destionation = QDir.clean_path (_account.dav_url ().path () + _folder.remote_path () + _new_filename);
        const auto move_job = new Move_job (_account, remote_source, remote_destionation, this);
        connect (move_job, &Move_job.finished_signal, this, &Invalid_filename_dialog.on_move_job_finished);
        move_job.on_start ();
    }
    }
    