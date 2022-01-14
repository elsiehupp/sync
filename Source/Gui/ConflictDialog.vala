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
// #include <QUrl>

// #include <Gtk.Dialog>

namespace Occ {


namespace Ui {
    class ConflictDialog;
}

class ConflictDialog : Gtk.Dialog {
public:
    ConflictDialog (Gtk.Widget *parent = nullptr);
    ~ConflictDialog () override;

    string base_filename ();
    string local_version_filename ();
    string remote_version_filename ();

public slots:
    void set_base_filename (string &base_filename);
    void set_local_version_filename (string &local_version_filename);
    void set_remote_version_filename (string &remote_version_filename);

    void accept () override;

private:
    void update_widgets ();
    void update_button_states ();

    string _base_filename;
    QScopedPointer<Ui.ConflictDialog> _ui;
    ConflictSolver *_solver;
};

} // namespace Occ



namespace {
    void force_header_font (Gtk.Widget *widget) {
        auto font = widget.font ();
        font.set_point_size_f (font.point_size_f () * 1.5);
        widget.set_font (font);
    }
    
    void set_bold_font (Gtk.Widget *widget, bool bold) {
        auto font = widget.font ();
        font.set_bold (bold);
        widget.set_font (font);
    }

    
    ConflictDialog.ConflictDialog (Gtk.Widget *parent)
        : Gtk.Dialog (parent)
        , _ui (new Ui.ConflictDialog)
        , _solver (new ConflictSolver (this)) {
        _ui.setup_ui (this);
        force_header_font (_ui.conflict_message);
        _ui.button_box.button (QDialogButtonBox.Ok).set_enabled (false);
        _ui.button_box.button (QDialogButtonBox.Ok).set_text (tr ("Keep selected version"));
    
        connect (_ui.local_version_radio, &QCheckBox.toggled, this, &ConflictDialog.update_button_states);
        connect (_ui.local_version_button, &QToolButton.clicked, this, [=] {
            QDesktopServices.open_url (QUrl.from_local_file (_solver.local_version_filename ()));
        });
    
        connect (_ui.remote_version_radio, &QCheckBox.toggled, this, &ConflictDialog.update_button_states);
        connect (_ui.remote_version_button, &QToolButton.clicked, this, [=] {
            QDesktopServices.open_url (QUrl.from_local_file (_solver.remote_version_filename ()));
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
    
    void ConflictDialog.set_base_filename (string &base_filename) {
        if (_base_filename == base_filename) {
            return;
        }
    
        _base_filename = base_filename;
        _ui.conflict_message.set_text (tr ("Conflicting versions of %1.").arg (_base_filename));
    }
    
    void ConflictDialog.set_local_version_filename (string &local_version_filename) {
        _solver.set_local_version_filename (local_version_filename);
    }
    
    void ConflictDialog.set_remote_version_filename (string &remote_version_filename) {
        _solver.set_remote_version_filename (remote_version_filename);
    }
    
    void ConflictDialog.accept () {
        const auto is_local_picked = _ui.local_version_radio.is_checked ();
        const auto is_remote_picked = _ui.remote_version_radio.is_checked ();
    
        Q_ASSERT (is_local_picked || is_remote_picked);
        if (!is_local_picked && !is_remote_picked) {
            return;
        }
    
        const auto solution = is_local_picked && is_remote_picked ? ConflictSolver.KeepBothVersions
                            : is_local_picked ? ConflictSolver.KeepLocalVersion
                            : ConflictSolver.KeepRemoteVersion;
        if (_solver.exec (solution)) {
            Gtk.Dialog.accept ();
        }
    }
    
    void ConflictDialog.update_widgets () {
        QMimeDatabase mime_db;
    
        const auto update_group = [this, &mime_db] (string &filename, QLabel *link_label, string &link_text, QLabel *mtime_label, QLabel *size_label, QToolButton *button) {
            const auto file_url = QUrl.from_local_file (filename).to_string ();
            link_label.set_text (QStringLiteral ("<a href='%1'>%2</a>").arg (file_url).arg (link_text));
    
            const auto info = QFileInfo (filename);
            mtime_label.set_text (info.last_modified ().to_string ());
            size_label.set_text (locale ().formatted_data_size (info.size ()));
    
            const auto mime = mime_db.mime_type_for_file (filename);
            if (QIcon.has_theme_icon (mime.icon_name ())) {
                button.set_icon (QIcon.from_theme (mime.icon_name ()));
            } else {
                button.set_icon (QIcon (":/qt-project.org/styles/commonstyle/images/file-128.png"));
            }
        };
    
        const auto local_version = _solver.local_version_filename ();
        update_group (local_version,
                    _ui.local_version_link,
                    tr ("Open local version"),
                    _ui.local_version_mtime,
                    _ui.local_version_size,
                    _ui.local_version_button);
    
        const auto remote_version = _solver.remote_version_filename ();
        update_group (remote_version,
                    _ui.remote_version_link,
                    tr ("Open server version"),
                    _ui.remote_version_mtime,
                    _ui.remote_version_size,
                    _ui.remote_version_button);
    
        const auto local_mtime = QFileInfo (local_version).last_modified ();
        const auto remote_mtime = QFileInfo (remote_version).last_modified ();
    
        set_bold_font (_ui.local_version_mtime, local_mtime > remote_mtime);
        set_bold_font (_ui.remote_version_mtime, remote_mtime > local_mtime);
    }
    
    void ConflictDialog.update_button_states () {
        const auto is_local_picked = _ui.local_version_radio.is_checked ();
        const auto is_remote_picked = _ui.remote_version_radio.is_checked ();
        _ui.button_box.button (QDialogButtonBox.Ok).set_enabled (is_local_picked || is_remote_picked);
    
        const auto text = is_local_picked && is_remote_picked ? tr ("Keep both versions")
                        : is_local_picked ? tr ("Keep local version")
                        : is_remote_picked ? tr ("Keep server version")
                        : tr ("Keep selected version");
        _ui.button_box.button (QDialogButtonBox.Ok).set_text (text);
    }
    
    } // namespace Occ
    