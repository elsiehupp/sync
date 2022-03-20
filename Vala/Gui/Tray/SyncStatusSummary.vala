/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>
@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class SyncStatusSummary : GLib.Object {

    /***********************************************************
    ***********************************************************/
    unowned AccountState account_state {
        private get {
            return this.account_state;
        }
        private set {
            if (!reload_needed (value)) {
                return;
            }
            if (this.account_state) {
                disconnect (
                    this.account_state,
                    AccountState.signal_is_connected_changed,
                    this,
                    SyncStatusSummary.on_signal_is_connected_changed
                );
            }
            this.account_state = value;
            this.account_state.signal_is_connected_changed.connect (
                this.on_signal_is_connected_changed
            );
        }
    }

    /***********************************************************
    ***********************************************************/
    private double progress = 1.0;

    GLib.Uri sync_icon {
        public get {
            return this.sync_icon;
        }
        private set {
            if (this.sync_icon == value) {
                return;
            }

            this.sync_icon = value;
            /* emit */ signal_sync_icon_changed ();
        }
    }

    bool syncing {
        public get {
            return this.is_syncing;
        }
        private set {
            if (value == this.is_syncing) {
                return;
            }

            this.is_syncing = value;
            /* emit */ signal_syncing_changed ();
        }
    }

    string sync_status_string {
        public get {
            return this.sync_status_string;
        }
        private set {
            if (this.sync_status_string == value) {
                return;
            }

            this.sync_status_string = value;
            /* emit */ signal_sync_status_string_changed ();
        }
    }

    string sync_status_detail_string {
        public get {
            return this.sync_status_detail_string;
        }
        private set {
            if (this.sync_status_detail_string == value) {
                return;
            }

            this.sync_status_detail_string = value;
            /* emit */ signal_sync_status_detail_string_changed ();
        }
    }

    double sync_progress {
        public get {
            return this.progress;
        }
        private set {
            if (this.progress == value) {
                return;
            }

            this.progress = value;
            /* emit */ signal_sync_progress_changed ();
        }
    }


    internal signal void signal_sync_progress_changed ();
    internal signal void signal_sync_icon_changed ();
    internal signal void signal_syncing_changed ();
    internal signal void signal_sync_status_string_changed ();
    internal signal void signal_sync_status_detail_string_changed ();


    /***********************************************************
    ***********************************************************/
    public SyncStatusSummary (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        FolderMan folder_man = FolderMan.instance;
        this.is_syncing = false;
        this.sync_icon = Theme.sync_status_ok;
        this.sync_status_string = _("All synced!");
        folder_man.signal_folder_list_changed.connect (
            this.on_signal_folder_list_changed
        );
        folder_man.signal_folder_sync_state_change.connect (
            this.on_signal_folder_sync_state_changed
        );
    }


    /***********************************************************
    ***********************************************************/
    private SyncResult.Status determine_sync_status (SyncResult sync_result) {
        const var status = sync_result.status ();

        if (status == SyncResult.Status.SUCCESS || status == SyncResult.Status.PROBLEM) {
            if (sync_result.has_unresolved_conflicts) {
                return SyncResult.Status.PROBLEM;
            }
            return SyncResult.Status.SUCCESS;
        } else if (status == SyncResult.Status.SYNC_PREPARE || status == SyncResult.Status.UNDEFINED) {
            return SyncResult.Status.SYNC_RUNNING;
        }
        return status;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_load () {
        var current_user = UserModel.instance.is_current_user ();
        if (!current_user) {
            return;
        }
        this.account_state = current_user.account_state;
        this.clear_folder_errors ();
        this.connect_to_folders_progress (FolderMan.instance.map ());
        this.init_sync_state ();
    }


    /***********************************************************
    ***********************************************************/
    private void connect_to_folders_progress (Folder.Map map) {
        foreach (Folder folder in folder_map) {
            if (folder.account_state == this.account_state) {
                folder.signal_progress_info.connect (
                    this.on_signal_folder_progress_info // Qt.UniqueConnection
                );
            } else {
                disconnect (
                    folder,
                    Folder.signal_progress_info,
                    this,
                    SyncStatusSummary.on_signal_folder_progress_info
                );
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_list_changed (Folder.Map folder_map) {
        connect_to_folders_progress (folder_map);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_progress_info (ProgressInfo progress) {
        const int64 completed_size = progress.completed_size ();
        const int64 current_file = progress.current_file ();
        const int64 completed_file = progress.completed_files ();
        const int64 total_size = q_max (completed_size, progress.total_size ());
        const int64 total_file_count = q_max (current_file, progress.total_files ());

        this.sync_progress = calculate_overall_percent (total_file_count, completed_file, total_size, completed_size);

        if (total_size > 0) {
            string completed_size_string = Utility.octets_to_string (completed_size);
            string total_size_string = Utility.octets_to_string (total_size);

            if (progress.trust_eta ()) {
                this.sync_status_detail_string =
                    _("%1 of %2 · %3 left")
                        .printf (completed_size_string, total_size_string)
                        .printf (Utility.duration_to_descriptive_string1 (progress.total_progress ().estimated_eta));
            } else {
                this.sync_status_detail_string = _("%1 of %2").printf (completed_size_string, total_size_string);
            }
        }

        if (total_file_count > 0) {
            this.sync_status_string = _("Syncing file %1 of %2").printf (current_file).printf (total_file_count);
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_sync_state_changed (Folder folder) {
        if (!folder) {
            return;
        }

        if (!this.account_state || folder.account_state != this.account_state) {
            return;
        }

        sync_state_for_folder (folder);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_is_connected_changed () {
        sync_state_to_connected_state ();
    }


    /***********************************************************
    ***********************************************************/
    private void sync_state_for_folder (Folder folder) {
        if (this.account_state && !this.account_state.is_connected) {
            this.is_syncing = false;
            this.sync_status_string = _("Offline");
            this.sync_status_detail_string = "";
            this.sync_icon = Theme.folder_offline;
            return;
        }

        const var state = determine_sync_status (folder.sync_result);

        switch (state) {
        case SyncResult.Status.SUCCESS:
        case SyncResult.Status.SYNC_PREPARE:
            // Success should only be shown if all folders were fine
            if (!folder_errors () || folder_error (folder)) {
                is_syncing (false);
                sync_status_string (_("All synced!"));
                sync_status_detail_string ("");
                sync_icon (Theme.sync_status_ok);
                mark_folder_as_success (folder);
            }
            break;
        case SyncResult.Status.ERROR:
        case SyncResult.Status.SETUP_ERROR:
            is_syncing (false);
            sync_status_string (_("Some files couldn't be synced!"));
            sync_status_detail_string (_("See below for errors"));
            sync_icon (Theme.sync_status_error);
            mark_folder_as_error (folder);
            break;
        case SyncResult.Status.SYNC_RUNNING:
        case SyncResult.Status.NOT_YET_STARTED:
            is_syncing (true);
            sync_status_string (_("Syncing"));
            sync_status_detail_string ("");
            sync_icon (Theme.sync_status_running ());
            break;
        case SyncResult.Status.PAUSED:
        case SyncResult.Status.SYNC_ABORT_REQUESTED:
            is_syncing (false);
            sync_status_string (_("Sync paused"));
            sync_status_detail_string ("");
            sync_icon (Theme.sync_status_pause ());
            break;
        case SyncResult.Status.PROBLEM:
        case SyncResult.Status.UNDEFINED:
            is_syncing (false);
            sync_status_string (_("Some files could not be synced!"));
            sync_status_detail_string (_("See below for warnings"));
            sync_icon (Theme.sync_status_warning ());
            mark_folder_as_error (folder);
            break;
        }
    }


    /***********************************************************
    ***********************************************************/
    private void mark_folder_as_error (Folder folder) {
        this.folders_with_errors.insert (folder.alias ());
    }


    /***********************************************************
    ***********************************************************/
    private void mark_folder_as_success (Folder folder) {
        this.folders_with_errors.erase (folder.alias ());
    }


    /***********************************************************
    ***********************************************************/
    private bool folder_errors () {
        return this.folders_with_errors.size () != 0;
    }


    /***********************************************************
    ***********************************************************/
    private bool folder_error (Folder folder) {
        return this.folders_with_errors.find (folder.alias ()) != this.folders_with_errors.end ();
    }


    /***********************************************************
    ***********************************************************/
    private void clear_folder_errors () {
        this.folders_with_errors.clear ();
    }


    /***********************************************************
    ***********************************************************/
    private void sync_state_to_connected_state () {
        this.is_syncing = false;
        this.sync_status_detail_string = "";
        if (this.account_state && !this.account_state.is_connected) {
            this.sync_status_string = _("Offline");
            this.sync_icon = Theme.folder_offline;
        } else {
            this.sync_status_string = _("All synced!");
            this.sync_icon = Theme.sync_status_ok;
        }
    }


    /***********************************************************
    ***********************************************************/
    private bool reload_needed (AccountState account_state) {
        if (this.account_state == account_state) {
            return false;
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void init_sync_state () {
        var sync_state_fallback_needed = true;
        foreach (Folder folder in FolderMan.instance.map ()) {
            on_signal_folder_sync_state_changed (folder);
            sync_state_fallback_needed = false;
        }

        if (sync_state_fallback_needed) {
            sync_state_to_connected_state ();
        }
    }


    private static double calculate_overall_percent (
        int64 total_file_count, int64 completed_file, int64 total_size, int64 completed_size) {
        int overall_percent = 0;
        if (total_file_count > 0) {
            // Add one 'byte' for each file so the percentage is moving when deleting or renaming files
            overall_percent = q_round (double (completed_size + completed_file) / double (total_size + total_file_count) * 100.0);
        }
        overall_percent = q_bound (0, overall_percent, 100);
        return overall_percent / 100.0;
    }

} // class SyncStatusSummary

} // namespace Ui
} // namespace Occ
