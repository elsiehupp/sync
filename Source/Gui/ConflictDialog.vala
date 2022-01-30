/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QDateTime>
// #include <QDebug>
// #include <QDesktopServices>
// #include <QFileInfo>
// #include <QMimeDatabase>
// #include <QPushButton>
// #include <GLib.Uri>

// #include <Gtk.Dialog>

namespace Occ {


namespace Ui {
    class ConflictDialog;
}

class ConflictDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public ConflictDialog (Gtk.Widget parent = nullptr);

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public string local_version_filename ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public void on_set_base_filename (string base_filename);


    public void on_set_local_version_filename (string local_version_filename);


    public void on_set_remote_version_filename (string remote_version_filename);

    void on_accept () override;


    /***********************************************************
    ***********************************************************/
    private void update_widgets ();

    /***********************************************************
    ***********************************************************/
    private 
    private string _base_filename;
    private QScopedPointer<Ui.ConflictDialog> _ui;
    private ConflictSolver _solver;
};

} // namespace Occ



namespace {
    void force_header_font (Gtk.Widget widget) {
        var font = widget.font ();
        font.set_point_size_f (font.point_size_f () * 1.5);
        widget.set_font (font);
    }

    void set_bold_font (Gtk.Widget widget, bool bold) {
        var font = widget.font ();
        font.set_bold (bold);
        widget.set_font (font);
    }


    ConflictDialog.ConflictDialog (Gtk.Widget parent)
        : Gtk.Dialog (parent)
        , _ui (new Ui.ConflictDialog)
        , _solver (new ConflictSolver (this)) {
        _ui.setup_ui (this);
        force_header_font (_ui.conflict_message);
        _ui.button_box.button (QDialogButtonBox.Ok).set_enabled (false);
        _ui.button_box.button (QDialogButtonBox.Ok).on_set_text (_("Keep selected version"));

        connect (_ui.local_version_radio, &QCheckBox.toggled, this, &ConflictDialog.update_button_states);
        connect (_ui.local_version_button, &QToolButton.clicked, this, [=] {
            QDesktopServices.open_url (GLib.Uri.from_local_file (_solver.local_version_filename ()));
        });

        connect (_ui.remote_version_radio, &QCheckBox.toggled, this, &ConflictDialog.update_button_states);
        connect (_ui.remote_version_button, &QToolButton.clicked, this, [=] {
            QDesktopServices.open_url (GLib.Uri.from_local_file (_solver.remote_version_filename ()));
        });

        connect (_solver, &ConflictSolver.local_version_filename_changed, this, &ConflictDialog.update_widgets);
        connect (_solver, &ConflictSolver.remote_version_filename_changed, this, &ConflictDialog.update_widgets);
    }

    string ConflictDialog.base_filename () {
        return _base_filename;
    }

    ConflictDialog.~ConflictDialog () = default;

    string ConflictDialog.local_version_filename () {
        return _solver.local_version_filename ();
    }

    string ConflictDialog.remote_version_filename () {
        return _solver.remote_version_filename ();
    }

    void ConflictDialog.on_set_base_filename (string base_filename) {
        if (_base_filename == base_filename) {
            return;
        }

        _base_filename = base_filename;
        _ui.conflict_message.on_set_text (_("Conflicting versions of %1.").arg (_base_filename));
    }

    void ConflictDialog.on_set_local_version_filename (string local_version_filename) {
        _solver.on_set_local_version_filename (local_version_filename);
    }

    void ConflictDialog.on_set_remote_version_filename (string remote_version_filename) {
        _solver.on_set_remote_version_filename (remote_version_filename);
    }

    void ConflictDialog.on_accept () {
        const var is_local_picked = _ui.local_version_radio.is_checked ();
        const var is_remote_picked = _ui.remote_version_radio.is_checked ();

        Q_ASSERT (is_local_picked || is_remote_picked);
        if (!is_local_picked && !is_remote_picked) {
            return;
        }

        const var solution = is_local_picked && is_remote_picked ? ConflictSolver.KeepBothVersions
                            : is_local_picked ? ConflictSolver.KeepLocalVersion
                            : ConflictSolver.KeepRemoteVersion;
        if (_solver.exec (solution)) {
            Gtk.Dialog.on_accept ();
        }
    }

    void ConflictDialog.update_widgets () {
        QMimeDatabase mime_database;

        const var update_group = [this, &mime_database] (string filename, QLabel link_label, string link_text, QLabel mtime_label, QLabel size_label, QToolButton button) {
            const var file_url = GLib.Uri.from_local_file (filename).to_"";
            link_label.on_set_text ("<a href='%1'>%2</a>".arg (file_url).arg (link_text));

            const var info = QFileInfo (filename);
            mtime_label.on_set_text (info.last_modified ().to_"");
            size_label.on_set_text (locale ().formatted_data_size (info.size ()));

            const var mime = mime_database.mime_type_for_file (filename);
            if (QIcon.has_theme_icon (mime.icon_name ())) {
                button.set_icon (QIcon.from_theme (mime.icon_name ()));
            } else {
                button.set_icon (QIcon (":/qt-project.org/styles/commonstyle/images/file-128.png"));
            }
        };

        const var local_version = _solver.local_version_filename ();
        update_group (local_version,
                    _ui.local_version_link,
                    _("Open local version"),
                    _ui.local_version_mtime,
                    _ui.local_version_size,
                    _ui.local_version_button);

        const var remote_version = _solver.remote_version_filename ();
        update_group (remote_version,
                    _ui.remote_version_link,
                    _("Open server version"),
                    _ui.remote_version_mtime,
                    _ui.remote_version_size,
                    _ui.remote_version_button);

        const var local_mtime = QFileInfo (local_version).last_modified ();
        const var remote_mtime = QFileInfo (remote_version).last_modified ();

        set_bold_font (_ui.local_version_mtime, local_mtime > remote_mtime);
        set_bold_font (_ui.remote_version_mtime, remote_mtime > local_mtime);
    }

    void ConflictDialog.update_button_states () {
        const var is_local_picked = _ui.local_version_radio.is_checked ();
        const var is_remote_picked = _ui.remote_version_radio.is_checked ();
        _ui.button_box.button (QDialogButtonBox.Ok).set_enabled (is_local_picked || is_remote_picked);

        const var text = is_local_picked && is_remote_picked ? _("Keep both versions")
                        : is_local_picked ? _("Keep local version")
                        : is_remote_picked ? _("Keep server version")
                        : _("Keep selected version");
        _ui.button_box.button (QDialogButtonBox.Ok).on_set_text (text);
    }

    } // namespace Occ
    