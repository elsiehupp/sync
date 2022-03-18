/***********************************************************
Copyright (C) by Kevin Ottens <kevin.ottens@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDebug>
//  #include <QDesktopServices>
//  #include <GLib.FileInfo>
//  #include <QMimeDatabase>
//  #include <QPushButton>
//  #include <Gtk.Dialog>

namespace Occ {
namespace Ui {

public class ConflictDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    public string base_filename { public get; private set; }


    /***********************************************************
    ***********************************************************/
    public string local_version_filename {
        public get {
            return this.solver.local_version_filename;
        }
    }


    /***********************************************************
    ***********************************************************/
    public string remote_version_filename {
        public get {
            return this.solver.remote_version_filename;
        }
    }

    private QScopedPointer<Ui.ConflictDialog> ui;
    private ConflictSolver solver;

    /***********************************************************
    ***********************************************************/
    public ConflictDialog (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.ui = new Ui.ConflictDialog ();
        this.solver = new ConflictSolver (this);
        this.ui.up_ui (this);
        force_header_font (this.ui.conflict_message);
        this.ui.button_box.button (QDialogButtonBox.Ok).enabled (false);
        this.ui.button_box.button (QDialogButtonBox.Ok).on_signal_text (_("Keep selected version"));

        this.ui.local_version_radio.toggled.connect (
            this.update_button_states
        );
        this.ui.local_version_button.clicked.connect (
            this.on_local_version_button_clicked
        );
        this.ui.remote_version_radio.toggled.connect (
            this.update_button_states
        );
        this.ui.remote_version_button.clicked.connect (
            this.on_remote_version_button_clicked
        );
        this.solver.signal_local_version_filename_changed.connect (
            this.update_widgets
        );
        this.solver.signal_remote_version_filename_changed.connect (
            this.update_widgets
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_local_version_button_clicked () {
        QDesktopServices.open_url (GLib.Uri.from_local_file (this.solver.local_version_filename));
    }


    /***********************************************************
    ***********************************************************/
    private void on_remote_version_button_clicked () {
        QDesktopServices.open_url (GLib.Uri.from_local_file (this.solver.remote_version_filename));
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_base_filename (string base_filename) {
        if (this.base_filename == base_filename) {
            return;
        }

        this.base_filename = base_filename;
        this.ui.conflict_message.on_signal_text (_("Conflicting versions of %1.").printf (this.base_filename));
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_local_version_filename (string local_version_filename) {
        this.solver.on_signal_local_version_filename (local_version_filename);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_remote_version_filename (string remote_version_filename) {
        this.solver.on_signal_remote_version_filename (remote_version_filename);
    }


    /***********************************************************
    ***********************************************************/
    private override void on_signal_accept () {
        const var is_local_picked = this.ui.local_version_radio.is_checked ();
        const var is_remote_picked = this.ui.remote_version_radio.is_checked ();

        //  Q_ASSERT (is_local_picked || is_remote_picked);
        if (!is_local_picked && !is_remote_picked) {
            return;
        }

        const var solution = is_local_picked && is_remote_picked ? ConflictSolver.Solution.KEEP_BOTH_VERSION
                            : is_local_picked ? ConflictSolver.Solution.KEEP_LOCAL_VERSION
                            : ConflictSolver.Solution.KEEP_REMOTE_VERSION;
        if (this.solver.exec (solution)) {
            Gtk.Dialog.on_signal_accept ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void update_widgets () {
        QMimeDatabase mime_database;

        const var local_version = this.solver.local_version_filename;
        update_group (local_version,
                    this.ui.local_version_link,
                    _("Open local version"),
                    this.ui.local_version_mtime,
                    this.ui.local_version_size,
                    this.ui.local_version_button);

        const string remote_version = this.solver.remote_version_filename;
        update_group (remote_version,
                    this.ui.remote_version_link,
                    _("Open server version"),
                    this.ui.remote_version_mtime,
                    this.ui.remote_version_size,
                    this.ui.remote_version_button
                );

        const Time local_mtime = GLib.FileInfo (local_version).last_modified ();
        const Time remote_mtime = GLib.FileInfo (remote_version).last_modified ();

        bold_font (this.ui.local_version_mtime, local_mtime > remote_mtime);
        bold_font (this.ui.remote_version_mtime, remote_mtime > local_mtime);
    }


    /***********************************************************
    ***********************************************************/
    private void update_group (QMimeDatabase mime_database, string filename, Gtk.Label link_label, string link_text, Gtk.Label mtime_label, Gtk.Label size_label, QToolButton button) {
        const string file_url = GLib.Uri.from_local_file (filename).to_string ();
        link_label.on_signal_text ("<a href='%1'>%2</a>".printf (file_url).printf (link_text));

        const GLib.FileInfo info = new GLib.FileInfo (filename);
        mtime_label.on_signal_text (info.last_modified ().to_string ());
        size_label.on_signal_text (locale ().formatted_data_size (info.size ()));

        const string mime = mime_database.mime_type_for_file (filename);
        if (Gtk.Icon.has_theme_icon (mime.icon_name ())) {
            button.icon (Gtk.Icon.from_theme (mime.icon_name ()));
        } else {
            button.icon (Gtk.Icon (":/qt-project.org/styles/commonstyle/images/file-128.png"));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void update_button_states () {
        const var is_local_picked = this.ui.local_version_radio.is_checked ();
        const var is_remote_picked = this.ui.remote_version_radio.is_checked ();
        this.ui.button_box.button (QDialogButtonBox.Ok).enabled (is_local_picked || is_remote_picked);

        const var text = is_local_picked && is_remote_picked ? _("Keep both versions")
                        : is_local_picked ? _("Keep local version")
                        : is_remote_picked ? _("Keep server version")
                        : _("Keep selected version");
        this.ui.button_box.button (QDialogButtonBox.Ok).on_signal_text (text);
    }


    /***********************************************************
    ***********************************************************/
    private static void force_header_font (Gtk.Widget widget) {
        var font = widget.font ();
        font.point_size_f (font.point_size_f () * 1.5);
        widget.font (font);
    }


    /***********************************************************
    ***********************************************************/
    private static void bold_font (Gtk.Widget widget, bool bold) {
        var font = widget.font ();
        font.bold (bold);
        widget.font (font);
    }

} // class ConflictDialog

} // namespace Ui
} // namespace Occ
