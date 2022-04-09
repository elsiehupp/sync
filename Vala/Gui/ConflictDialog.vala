/***********************************************************
@author Kevin Ottens <kevin.ottens@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.Debug>
//  #include <GLib.DesktopServices>
//  #include <GLib.FileInfo>
//  #include <GLib.MimeDatabase>
//  #include <GLib.PushButton>
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

    private ConflictDialog instance;
    private ConflictSolver solver;

    /***********************************************************
    ***********************************************************/
    public ConflictDialog (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.instance = new ConflictDialog ();
        this.solver = new ConflictSolver (this);
        this.instance.up_ui (this);
        force_header_font (this.instance.conflict_message);
        this.instance.button_box.button (GLib.DialogButtonBox.Ok).enabled (false);
        this.instance.button_box.button (GLib.DialogButtonBox.Ok).on_signal_text (_("Keep selected version"));

        this.instance.local_version_radio.toggled.connect (
            this.update_button_states
        );
        this.instance.local_version_button.clicked.connect (
            this.on_local_version_button_clicked
        );
        this.instance.remote_version_radio.toggled.connect (
            this.update_button_states
        );
        this.instance.remote_version_button.clicked.connect (
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
        GLib.DesktopServices.open_url (GLib.Uri.from_local_file (this.solver.local_version_filename));
    }


    /***********************************************************
    ***********************************************************/
    private void on_remote_version_button_clicked () {
        GLib.DesktopServices.open_url (GLib.Uri.from_local_file (this.solver.remote_version_filename));
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_base_filename (string base_filename) {
        if (this.base_filename == base_filename) {
            return;
        }

        this.base_filename = base_filename;
        this.instance.conflict_message.on_signal_text (_("Conflicting versions of %1.").printf (this.base_filename));
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
        const var is_local_picked = this.instance.local_version_radio.is_checked ();
        const var is_remote_picked = this.instance.remote_version_radio.is_checked ();

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
        GLib.MimeDatabase mime_database;

        string local_version = this.solver.local_version_filename;
        update_group (local_version,
                    this.instance.local_version_link,
                    _("Open local version"),
                    this.instance.local_version_mtime,
                    this.instance.local_version_size,
                    this.instance.local_version_button);

        string remote_version = this.solver.remote_version_filename;
        update_group (
            remote_version,
            this.instance.remote_version_link,
            _("Open server version"),
            this.instance.remote_version_mtime,
            this.instance.remote_version_size,
            this.instance.remote_version_button
        );

        const Time local_mtime = new GLib.FileInfo (local_version).last_modified ();
        const Time remote_mtime = new GLib.FileInfo (remote_version).last_modified ();

        bold_font (this.instance.local_version_mtime, local_mtime > remote_mtime);
        bold_font (this.instance.remote_version_mtime, remote_mtime > local_mtime);
    }


    /***********************************************************
    ***********************************************************/
    private void update_group (GLib.MimeDatabase mime_database, string filename, Gtk.Label link_label, string link_text, Gtk.Label mtime_label, Gtk.Label size_label, GLib.ToolButton button) {
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
        const var is_local_picked = this.instance.local_version_radio.is_checked ();
        const var is_remote_picked = this.instance.remote_version_radio.is_checked ();
        this.instance.button_box.button (GLib.DialogButtonBox.Ok).enabled (is_local_picked || is_remote_picked);

        const var text = is_local_picked && is_remote_picked ? _("Keep both versions")
                        : is_local_picked ? _("Keep local version")
                        : is_remote_picked ? _("Keep server version")
                        : _("Keep selected version");
        this.instance.button_box.button (GLib.DialogButtonBox.Ok).on_signal_text (text);
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
