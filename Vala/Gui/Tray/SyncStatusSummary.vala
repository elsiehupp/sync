/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

class SyncStatusSummary : GLib.Object {

    /***********************************************************
    ***********************************************************/
    private AccountStatePtr account_state;

    /***********************************************************
    ***********************************************************/
    private GLib.Uri sync_icon = Theme.instance ().sync_status_ok ();
    private double progress = 1.0;
    private bool is_syncing = false;
    private string sync_status_string = _("All synced!");
    private string sync_status_detail_string;


    signal void signal_sync_progress_changed ();
    signal void signal_sync_icon_changed ();
    signal void signal_syncing_changed ();
    signal void signal_sync_status_string_changed ();
    signal void signal_sync_status_detail_string_changed ();


    /***********************************************************
    ***********************************************************/
    public SyncStatusSummary (GLib.Object parent = new GLib.Object ()) {
        base (parent);
        const var folder_man = FolderMan.instance ();
        connect (folder_man, &FolderMan.folder_list_changed, this, &SyncStatusSummary.on_signal_folder_list_changed);
        connect (folder_man, &FolderMan.folder_sync_state_change, this, &SyncStatusSummary.on_signal_folder_sync_state_changed);
    }

    /***********************************************************
    ***********************************************************/
    public double sync_progress () {
        return this.progress;
    }


    /***********************************************************
    ***********************************************************/
    private void sync_progress (double value) {
        if (this.progress == value) {
            return;
        }

        this.progress = value;
        /* emit */ signal_sync_progress_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private Occ.SyncResult.Status determine_sync_status (Occ.SyncResult sync_result) {
        const var status = sync_result.status ();

        if (status == Occ.SyncResult.Status.SUCCESS || status == Occ.SyncResult.Status.PROBLEM) {
            if (sync_result.has_unresolved_conflicts ()) {
                return Occ.SyncResult.Status.PROBLEM;
            }
            return Occ.SyncResult.Status.SUCCESS;
        } else if (status == Occ.SyncResult.Status.SYNC_PREPARE || status == Occ.SyncResult.Status.UNDEFINED) {
            return Occ.SyncResult.Status.SYNC_RUNNING;
        }
        return status;
    }

    /***********************************************************
    ***********************************************************/
    public bool syncing () {
        return this.is_syncing;
    }

    /***********************************************************
    ***********************************************************/
    public bool syncing (bool value) {
        if (value == this.is_syncing) {
            return;
        }

        this.is_syncing = value;
        /* emit */ signal_syncing_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public string sync_status_string ();
    string SyncStatusSummary.sync_status_string () {
        return this.sync_status_string;
    }


    /***********************************************************
    ***********************************************************/
    private void sync_status_string (string value);
    void SyncStatusSummary.sync_status_string (string value) {
        if (this.sync_status_string == value) {
            return;
        }

        this.sync_status_string = value;
        /* emit */ signal_sync_status_string_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public string sync_status_detail_string ();
    string SyncStatusSummary.sync_status_detail_string () {
        return this.sync_status_detail_string;
    }


    /***********************************************************
    ***********************************************************/
    private void sync_status_detail_string (string value);
    void SyncStatusSummary.sync_status_detail_string (string value) {
        if (this.sync_status_detail_string == value) {
            return;
        }

        this.sync_status_detail_string = value;
        /* emit */ signal_sync_status_detail_string_changed ();
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_load () {
        const var current_user = UserModel.instance ().is_current_user ();
        if (!current_user) {
            return;
        }
        account_state (current_user.account_state ());
        clear_folder_errors ();
        connect_to_folders_progress (FolderMan.instance ().map ());
        init_sync_state ();
    }


    /***********************************************************
    ***********************************************************/
    private void connect_to_folders_progress (Folder.Map map) {
        for (var folder : folder_map) {
            if (folder.account_state () == this.account_state.data ()) {
                connect (
                    folder, &Folder.progress_info, this, &SyncStatusSummary.on_signal_folder_progress_info, Qt.UniqueConnection);
            } else {
                disconnect (folder, &Folder.progress_info, this, &SyncStatusSummary.on_signal_folder_progress_info);
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_list_changed (Occ.Folder.Map folder_map) {
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

        sync_progress (calculate_overall_percent (total_file_count, completed_file, total_size, completed_size));

        if (total_size > 0) {
            const var completed_size_string = Utility.octets_to_string (completed_size);
            const var total_size_string = Utility.octets_to_string (total_size);

            if (progress.trust_eta ()) {
                sync_status_detail_string (
                    _("%1 of %2 · %3 left")
                        .arg (completed_size_string, total_size_string)
                        .arg (Utility.duration_to_descriptive_string1 (progress.total_progress ().estimated_eta)));
            } else {
                sync_status_detail_string (_("%1 of %2").arg (completed_size_string, total_size_string));
            }
        }

        if (total_file_count > 0) {
            sync_status_string (_("Syncing file %1 of %2").arg (current_file).arg (total_file_count));
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_folder_sync_state_changed (Folder folder) {
        if (!folder) {
            return;
        }

        if (!this.account_state || folder.account_state () != this.account_state.data ()) {
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
        if (this.account_state && !this.account_state.is_connected ()) {
            syncing (false);
            sync_status_string (_("Offline"));
            sync_status_detail_string ("");
            sync_icon (Theme.instance ().folder_offline ());
            return;
        }

        const var state = determine_sync_status (folder.sync_result ());

        switch (state) {
        case SyncResult.Status.SUCCESS:
        case SyncResult.Status.SYNC_PREPARE:
            // Success should only be shown if all folders were fine
            if (!folder_errors () || folder_error (folder)) {
                syncing (false);
                sync_status_string (_("All synced!"));
                sync_status_detail_string ("");
                sync_icon (Theme.instance ().sync_status_ok ());
                mark_folder_as_success (folder);
            }
            break;
        case SyncResult.Status.ERROR:
        case SyncResult.Status.SETUP_ERROR:
            syncing (false);
            sync_status_string (_("Some files couldn't be synced!"));
            sync_status_detail_string (_("See below for errors"));
            sync_icon (Theme.instance ().sync_status_error ());
            mark_folder_as_error (folder);
            break;
        case SyncResult.Status.SYNC_RUNNING:
        case SyncResult.Status.NOT_YET_STARTED:
            syncing (true);
            sync_status_string (_("Syncing"));
            sync_status_detail_string ("");
            sync_icon (Theme.instance ().sync_status_running ());
            break;
        case SyncResult.Status.PAUSED:
        case SyncResult.Status.SYNC_ABORT_REQUESTED:
            syncing (false);
            sync_status_string (_("Sync paused"));
            sync_status_detail_string ("");
            sync_icon (Theme.instance ().sync_status_pause ());
            break;
        case SyncResult.Status.PROBLEM:
        case SyncResult.Status.UNDEFINED:
            syncing (false);
            sync_status_string (_("Some files could not be synced!"));
            sync_status_detail_string (_("See below for warnings"));
            sync_icon (Theme.instance ().sync_status_warning ());
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
    private void mark_folder_as_success (Folder folder);
    void SyncStatusSummary.mark_folder_as_success (Folder folder) {
        this.folders_with_errors.erase (folder.alias ());
    }


    /***********************************************************
    ***********************************************************/
    private bool folder_errors ();
    bool SyncStatusSummary.folder_errors () {
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
        syncing (false);
        sync_status_detail_string ("");
        if (this.account_state && !this.account_state.is_connected ()) {
            sync_status_string (_("Offline"));
            sync_icon (Theme.instance ().folder_offline ());
        } else {
            sync_status_string (_("All synced!"));
            sync_icon (Theme.instance ().sync_status_ok ());
        }
    }


    /***********************************************************
    ***********************************************************/
    private bool reload_needed (AccountState account_state) {
        if (this.account_state.data () == account_state) {
            return false;
        }
        return true;
    }


    /***********************************************************
    ***********************************************************/
    private void init_sync_state () {
        var sync_state_fallback_needed = true;
        for (var folder : FolderMan.instance ().map ()) {
            on_signal_folder_sync_state_changed (folder);
            sync_state_fallback_needed = false;
        }

        if (sync_state_fallback_needed) {
            sync_state_to_connected_state ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void syncing (bool value);


    /***********************************************************
    ***********************************************************/
    GLib.Uri SyncStatusSummary.sync_icon () {
        return this.sync_icon;
    }


    /***********************************************************
    ***********************************************************/
    private void sync_icon (GLib.Uri value);
    void SyncStatusSummary.sync_icon (GLib.Uri value) {
        if (this.sync_icon == value) {
            return;
        }

        this.sync_icon = value;
        /* emit */ signal_sync_icon_changed ();
    }


    /***********************************************************
    ***********************************************************/
    private void account_state (AccountStatePtr account_state) {
        if (!reload_needed (account_state.data ())) {
            return;
        }
        if (this.account_state) {
            disconnect (
                this.account_state.data (), &AccountState.is_connected_changed, this, &SyncStatusSummary.on_signal_is_connected_changed);
        }
        this.account_state = account_state;
        connect (this.account_state.data (), &AccountState.is_connected_changed, this, &SyncStatusSummary.on_signal_is_connected_changed);
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