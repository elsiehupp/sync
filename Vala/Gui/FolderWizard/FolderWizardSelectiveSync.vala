/***********************************************************
Copyright (C) by Duncan Mac-Vicar P. <duncan@kde.org>

<GPLv3-or-later-Boilerplate>
***********************************************************/

using Soup;

namespace Occ {
namespace Ui {

/***********************************************************
@brief The FolderWizardSelectiveSync class
@ingroup gui
***********************************************************/
public class FolderWizardSelectiveSync : QWizardPage {

    /***********************************************************
    ***********************************************************/
    private SelectiveSyncWidget selective_sync;
    private QCheckBox virtual_files_check_box = null;

    /***********************************************************
    ***********************************************************/
    public FolderWizardSelectiveSync (unowned Account account) {
        var layout = new QVBoxLayout (this);
        this.selective_sync = new SelectiveSyncWidget (account, this);
        layout.add_widget (this.selective_sync);

        if (Theme.instance ().show_virtual_files_option () && best_available_vfs_mode () != Vfs.Off) {
            this.virtual_files_check_box = new QCheckBox (_("Use virtual files instead of downloading content immediately %1").printf (best_available_vfs_mode () == Vfs.WindowsCfApi ? "" : _(" (experimental)")));
            connect (
                this.virtual_files_check_box,
                QCheckBox.clicked,
                this,
                FolderWizardSelectiveSync.on_signal_virtual_files_checkbox_clicked
            );
            connect (
                this.virtual_files_check_box,
                QCheckBox.state_changed,
                this,
                this.on_virtual_files_check_box_state_changed
            );
            this.virtual_files_check_box.checked (best_available_vfs_mode () == Vfs.WindowsCfApi);
            layout.add_widget (this.virtual_files_check_box);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_virtual_files_check_box_state_changed (int state) {
        this.selective_sync.enabled (state == Qt.Unchecked);
    }


    /***********************************************************
    ***********************************************************/
    public bool validate_page () {
        const bool use_virtual_files = this.virtual_files_check_box && this.virtual_files_check_box.is_checked ();
        if (use_virtual_files) {
            const var availability = Vfs.check_availability (wizard ().field ("source_folder").to_string ());
            if (!availability) {
                var message = new QMessageBox (QMessageBox.Warning, _("Virtual files are not available for the selected folder"), availability.error (), QMessageBox.Ok, this);
                message.attribute (Qt.WA_DeleteOnClose);
                message.open ();
                return false;
            }
        }
        wizard ().property ("selective_sync_block_list", use_virtual_files ? GLib.Variant () : GLib.Variant (this.selective_sync.create_block_list ()));
        wizard ().property ("use_virtual_files", GLib.Variant (use_virtual_files));
        return true;
    }


    /***********************************************************
    ***********************************************************/
    public override void initialize_page () {
        string target_path = wizard ().property ("target_path").to_string ();
        if (target_path.starts_with ('/')) {
            target_path = target_path.mid (1);
        }
        string alias = GLib.FileInfo (target_path).filename ();
        if (alias == "")
            alias = Theme.instance ().app_name ();
        string[] initial_blocklist;
        if (Theme.instance ().wizard_selective_sync_default_nothing ()) {
            initial_blocklist = { "/" };
        }
        this.selective_sync.folder_info (target_path, alias, initial_blocklist);

        if (this.virtual_files_check_box) {
            // TODO: remove when UX decision is made
            if (Utility.is_path_windows_drive_partition_root (wizard ().field ("source_folder").to_string ())) {
                this.virtual_files_check_box.checked (false);
                this.virtual_files_check_box.enabled (false);
                this.virtual_files_check_box.on_signal_text (_("Virtual files are not supported for Windows partition roots as local folder. Please choose a valid subfolder under drive letter."));
            } else {
                this.virtual_files_check_box.checked (best_available_vfs_mode () == Vfs.WindowsCfApi);
                this.virtual_files_check_box.enabled (true);
                this.virtual_files_check_box.on_signal_text (_("Use virtual files instead of downloading content immediately %1").printf (best_available_vfs_mode () == Vfs.WindowsCfApi ? "" : _(" (experimental)")));

                if (Theme.instance ().enforce_virtual_files_sync_folder ()) {
                    this.virtual_files_check_box.checked (true);
                    this.virtual_files_check_box.disabled (true);
                }
            }
            //
        }

        QWizardPage.initialize_page ();
    }


    /***********************************************************
    ***********************************************************/
    public override void clean_up_page () {
        string target_path = wizard ().property ("target_path").to_string ();
        string alias = GLib.FileInfo (target_path).filename ();
        if (alias == "")
            alias = Theme.instance ().app_name ();
        this.selective_sync.folder_info (target_path, alias);
        QWizardPage.clean_up_page ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_virtual_files_checkbox_clicked () {
        // The click has already had an effect on the box, so if it's
        // checked it was newly activated.
        if (this.virtual_files_check_box.is_checked ()) {
            OwncloudWizard.ask_experimental_virtual_files_feature (
                this,
                this.on_experimental_virtual_files_feature_enabled
            );
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_experimental_virtual_files_feature_enabled (bool enable) {
        if (!enable) {
            this.virtual_files_check_box.checked (false);
        }
    }

} // class FolderWizardSelectiveSync

} // namespace Ui
} // namespace Occ
