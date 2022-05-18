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
            if (this.account_state != null) {
                this.account_state.signal_is_connected_changed.disconnect (
                    this.on_signal_is_connected_changed
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
            signal_sync_icon_changed ();
        }
    }

    bool syncing {
        public get {
            return this.syncing;
        }
        private set {
            if (value == this.syncing) {
                return;
            }

            this.syncing = value;
            signal_syncing_changed ();
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
            signal_sync_status_string_changed ();
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
            signal_sync_status_detail_string_changed ();
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
            signal_sync_progress_changed ();
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
        FolderManager folder_man = FolderManager.instance;
        this.syncing = false;
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
    private LibSync.SyncResult.Status determine_sync_status (LibSync.SyncResult sync_result) {
        var status = sync_result.status ();

        if (status == LibSync.SyncResult.Status.SUCCESS || status == LibSync.SyncResult.Status.PROBLEM) {
            if (sync_result.has_unresolved_conflicts) {
                return LibSync.SyncResult.Status.PROBLEM;
            }
            return LibSync.SyncResult.Status.SUCCESS;
        } else if (status == LibSync.SyncResult.Status.SYNC_PREPARE || status == LibSync.SyncResult.Status.UNDEFINED) {
            return LibSync.SyncResult.Status.SYNC_RUNNING;
        }
        return status;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_load () {
        if (UserModel.current_user != null) {
            UserModel.account_state = UserModel.current_user.account_state;
            UserModel.clear_folder_errors ();
            UserModel.connect_to_folders_progress (FolderManager.instance.map ());
            UserModel.init_sync_state ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void connect_to_folders_progress (FolderConnection.Map map) {
        foreach (FolderConnection folder_connection in folder_map) {
            if (folder_connection.account_state == this.account_state) {
                folder_connection.signal_progress_info.connect (
                    this.on_signal_folder_progress_info // GLib.UniqueConnection
                );
            } else {
                disconnect (
                    folder_connection,
                    FolderConnection.signal_progress_info,
                    this,
                    SyncStatusSummary.on_signal_folder_progress_info
                );
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_list_changed (FolderConnection.Map folder_map) {
        connect_to_folders_progress (folder_map);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_progress_info (ProgressInfo progress) {
        int64 completed_size = progress.completed_size ();
        int64 current_file = progress.current_file ();
        int64 completed_file = progress.completed_files ();
        int64 total_size = int64.max (completed_size, progress.total_size ());
        int64 total_file_count = int64.max (current_file, progress.total_files ());

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
    private void on_signal_folder_sync_state_changed (FolderConnection folder_connection) {

        if (this.account_state == null || folder_connection.account_state != this.account_state) {
            return;
        }

        sync_state_for_folder (folder_connection);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_is_connected_changed () {
        sync_state_to_connected_state ();
    }


    /***********************************************************
    ***********************************************************/
    private void sync_state_for_folder (FolderConnection folder_connection) {
        if (this.account_state != null && !this.account_state.is_connected) {
            this.syncing = false;
            this.sync_status_string = _("Offline");
            this.sync_status_detail_string = "";
            this.sync_icon = Theme.folder_offline;
            return;
        }

        var state = determine_sync_status (folder_connection.sync_result);

        switch (state) {
        case LibSync.SyncResult.Status.SUCCESS:
        case LibSync.SyncResult.Status.SYNC_PREPARE:
            // Success should only be shown if all folders were fine
            if (!folder_errors () || folder_error (folder_connection)) {
                syncing (false);
                sync_status_string (_("All synced!"));
                sync_status_detail_string ("");
                sync_icon (Theme.sync_status_ok);
                mark_folder_as_success (folder_connection);
            }
            break;
        case LibSync.SyncResult.Status.ERROR:
        case LibSync.SyncResult.Status.SETUP_ERROR:
            syncing (false);
            sync_status_string (_("Some files couldn't be synced!"));
            sync_status_detail_string (_("See below for errors"));
            sync_icon (Theme.sync_status_error);
            mark_folder_as_error (folder_connection);
            break;
        case LibSync.SyncResult.Status.SYNC_RUNNING:
        case LibSync.SyncResult.Status.NOT_YET_STARTED:
            syncing (true);
            sync_status_string (_("Syncing"));
            sync_status_detail_string ("");
            sync_icon (Theme.sync_status_running ());
            break;
        case LibSync.SyncResult.Status.PAUSED:
        case LibSync.SyncResult.Status.SYNC_ABORT_REQUESTED:
            syncing (false);
            sync_status_string (_("Sync paused"));
            sync_status_detail_string ("");
            sync_icon (Theme.sync_status_pause ());
            break;
        case LibSync.SyncResult.Status.PROBLEM:
        case LibSync.SyncResult.Status.UNDEFINED:
            syncing (false);
            sync_status_string (_("Some files could not be synced!"));
            sync_status_detail_string (_("See below for warnings"));
            sync_icon (Theme.sync_status_warning ());
            mark_folder_as_error (folder_connection);
            break;
        }
    }


    /***********************************************************
    ***********************************************************/
    private void mark_folder_as_error (FolderConnection folder_connection) {
        this.folders_with_errors.insert (folder_connection.alias ());
    }


    /***********************************************************
    ***********************************************************/
    private void mark_folder_as_success (FolderConnection folder_connection) {
        this.folders_with_errors.erase (folder_connection.alias ());
    }


    /***********************************************************
    ***********************************************************/
    private bool folder_errors () {
        return this.folders_with_errors.size () != 0;
    }


    /***********************************************************
    ***********************************************************/
    private bool folder_error (FolderConnection folder_connection) {
        return this.folders_with_errors.find (folder_connection.alias ()) != this.folders_with_errors.end ();
    }


    /***********************************************************
    ***********************************************************/
    private void clear_folder_errors () {
        this.folders_with_errors = "";
    }


    /***********************************************************
    ***********************************************************/
    private void sync_state_to_connected_state () {
        this.syncing = false;
        this.sync_status_detail_string = "";
        if (this.account_state != null && !this.account_state.is_connected) {
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
        foreach (FolderConnection folder_connection in FolderManager.instance.map ()) {
            on_signal_folder_sync_state_changed (folder_connection);
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
