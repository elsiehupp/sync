/***********************************************************
@author Duncan Mac-Vicar P. <duncan@kde.org>

@copyright GPLv3 or Later
***********************************************************/

using Soup;

namespace Occ {
namespace Ui {

/***********************************************************
@brief Page to ask for the local source folder
@ingroup gui
***********************************************************/
public class FolderWizardLocalPath : FormatWarningsWizardPage {

    /***********************************************************
    ***********************************************************/
    private Ui_Folder_wizard_source_page ui;

    Folder.Map folder_map { private get; public set; }

    private unowned Account account;

    /***********************************************************
    ***********************************************************/
    public FolderWizardLocalPath (Account account) {
        base ();
        this.account = account;
        this.ui.up_ui (this);
        register_field ("source_folder*", this.ui.local_folder_line_edit);
        this.ui.local_folder_choose_btn.clicked.connect (
            this.on_signal_choose_local_folder
        );
        this.ui.local_folder_choose_btn.tool_tip (_("Click to select a local folder to sync."));

        GLib.Uri server_url = this.account.url;
        server_url.user_name (this.account.credentials ().user ());
        string default_path = GLib.Dir.home_path + '/' + Theme.app_name;
        default_path = FolderMan.instance.find_good_path_for_new_sync_folder (default_path, server_url);
        this.ui.local_folder_line_edit.on_signal_text (GLib.Dir.to_native_separators (default_path));
        this.ui.local_folder_line_edit.tool_tip (_("Enter the path to the local folder."));

        this.ui.warn_label.text_format (Qt.RichText);
        this.ui.warn_label.hide ();
    }


    /***********************************************************
    ***********************************************************/
    public override bool is_complete {
        GLib.Uri server_url = this.account.url;
        server_url.user_name (this.account.credentials ().user ());

        string error_str = FolderMan.instance.check_path_validity_for_new_folder (
            GLib.Dir.from_native_separators (this.ui.local_folder_line_edit.text ()), server_url);

        bool is_ok = error_str == "";
        string[] warn_strings;
        if (!is_ok) {
            warn_strings += error_str;
        }

        this.ui.warn_label.word_wrap (true);
        if (is_ok) {
            this.ui.warn_label.hide ();
            this.ui.warn_label.clear ();
        } else {
            this.ui.warn_label.show ();
            string warnings = format_warnings (warn_strings);
            this.ui.warn_label.on_signal_text (warnings);
        }
        return is_ok;
    }


    /***********************************************************
    ***********************************************************/
    public override void initialize_page () {
        this.ui.warn_label.hide ();
    }


    /***********************************************************
    ***********************************************************/
    public override void clean_up_page () {
        this.ui.warn_label.hide ();
    }


    /***********************************************************
    ***********************************************************/
    protected void on_signal_choose_local_folder () {
        string sf = QStandardPaths.writable_location (QStandardPaths.HomeLocation);
        GLib.Dir d = new GLib.Dir (sf);

        // open the first entry of the home directory. Otherwise the directory picker comes
        // up with the closed home directory icon, stupid Qt default...
        string[] dirs = d.entry_list (GLib.Dir.Dirs | GLib.Dir.NoDotAndDotDot | GLib.Dir.No_sym_links,
            GLib.Dir.Dirs_first | GLib.Dir.Name);

        if (dirs.count () > 0)
            sf += "/" + dirs.at (0); // Take the first directory in home directory.

        string directory = QFileDialog.existing_directory (this,
            _("Select the source folder"),
            sf);
        if (!directory == "") {
            // set the last directory component name as alias
            this.ui.local_folder_line_edit.on_signal_text (GLib.Dir.to_native_separators (directory));
        }
        /* emit */ complete_changed ();
    }

} // class FolderWizardLocalPath

} // namespace Ui
} // namespace Occ
