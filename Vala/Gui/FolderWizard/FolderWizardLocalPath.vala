/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using Soup;

namespace Occ {

/***********************************************************
@brief Page to ask for the local source folder
@ingroup gui
***********************************************************/
class Folder_wizard_local_path : Format_warnings_wizard_page {

    /***********************************************************
    ***********************************************************/
    public Folder_wizard_local_path (AccountPointer account);

    /***********************************************************
    ***********************************************************/
    public bool is_complete () override;
    public void initialize_page () override;
    public void cleanup_page () override;

    /***********************************************************
    ***********************************************************/
    public void folder_map (Folder.Map fm) {
        this.folder_map = fm;
    }
protected slots:
    void on_choose_local_folder ();


    /***********************************************************
    ***********************************************************/
    private Ui_Folder_wizard_source_page this.ui;
    private Folder.Map this.folder_map;
    private AccountPointer this.account;
}





    Folder_wizard_local_path.Folder_wizard_local_path (AccountPointer account)
        : Format_warnings_wizard_page ()
        this.account (account) {
        this.ui.up_ui (this);
        register_field (QLatin1String ("source_folder*"), this.ui.local_folder_line_edit);
        connect (this.ui.local_folder_choose_btn, &QAbstractButton.clicked, this, &Folder_wizard_local_path.on_choose_local_folder);
        this.ui.local_folder_choose_btn.tool_tip (_("Click to select a local folder to sync."));

        GLib.Uri server_url = this.account.url ();
        server_url.user_name (this.account.credentials ().user ());
        string default_path = QDir.home_path () + '/' + Theme.instance ().app_name ();
        default_path = FolderMan.instance ().find_good_path_for_new_sync_folder (default_path, server_url);
        this.ui.local_folder_line_edit.on_text (QDir.to_native_separators (default_path));
        this.ui.local_folder_line_edit.tool_tip (_("Enter the path to the local folder."));

        this.ui.warn_label.text_format (Qt.RichText);
        this.ui.warn_label.hide ();
    }

    Folder_wizard_local_path.~Folder_wizard_local_path () = default;

    void Folder_wizard_local_path.initialize_page () {
        this.ui.warn_label.hide ();
    }

    void Folder_wizard_local_path.cleanup_page () {
        this.ui.warn_label.hide ();
    }

    bool Folder_wizard_local_path.is_complete () {
        GLib.Uri server_url = this.account.url ();
        server_url.user_name (this.account.credentials ().user ());

        string error_str = FolderMan.instance ().check_path_validity_for_new_folder (
            QDir.from_native_separators (this.ui.local_folder_line_edit.text ()), server_url);

        bool is_ok = error_str.is_empty ();
        string[] warn_strings;
        if (!is_ok) {
            warn_strings << error_str;
        }

        this.ui.warn_label.word_wrap (true);
        if (is_ok) {
            this.ui.warn_label.hide ();
            this.ui.warn_label.clear ();
        } else {
            this.ui.warn_label.show ();
            string warnings = format_warnings (warn_strings);
            this.ui.warn_label.on_text (warnings);
        }
        return is_ok;
    }

    void Folder_wizard_local_path.on_choose_local_folder () {
        string sf = QStandardPaths.writable_location (QStandardPaths.Home_location);
        QDir d (sf);

        // open the first entry of the home dir. Otherwise the dir picker comes
        // up with the closed home dir icon, stupid Qt default...
        string[] dirs = d.entry_list (QDir.Dirs | QDir.NoDotAndDotDot | QDir.No_sym_links,
            QDir.Dirs_first | QDir.Name);

        if (dirs.count () > 0)
            sf += "/" + dirs.at (0); // Take the first dir in home dir.

        string dir = QFileDialog.get_existing_directory (this,
            _("Select the source folder"),
            sf);
        if (!dir.is_empty ()) {
            // set the last directory component name as alias
            this.ui.local_folder_line_edit.on_text (QDir.to_native_separators (dir));
        }
        /* emit */ complete_changed ();
    }