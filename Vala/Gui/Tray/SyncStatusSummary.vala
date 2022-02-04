/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <theme.h>

//  #pragma once

//  #include <theme.h>
//  #include <folder.h>


namespace Occ {

class Sync_status_summary : GLib.Object {

    //  Q_PROPERTY (double sync_progress READ sync_progress NOTIFY sync_progress_changed)
    //  Q_PROPERTY (GLib.Uri sync_icon READ sync_icon NOTIFY sync_icon_changed)
    //  Q_PROPERTY (bool syncing READ syncing NOTIFY syncing_changed)
    //  Q_PROPERTY (string sync_status_string READ sync_status_string NOTIFY sync_status_string_changed)
    //  Q_PROPERTY (string sync_status_detail_string READ sync_status_detail_string NOTIFY sync_status_detail_string_changed)

    /***********************************************************
    ***********************************************************/
    public Sync_status_summary (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public double sync_progress ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public bool syncing ();

    /***********************************************************
    ***********************************************************/
    public string sync_status_"";


    public string sync_status_detail_"";

signals:
    void sync_progress_changed ();
    void sync_icon_changed ();
    void syncing_changed ();
    void sync_status_string_changed ();
    void sync_status_detail_string_changed ();


    /***********************************************************
    ***********************************************************/
    public void on_load ();


    /***********************************************************
    ***********************************************************/
    private void connect_to_folders_progress (Folder.Map map);

    /***********************************************************
    ***********************************************************/
    private void on_folder_list_changed (Occ.Folder.Map folder_map);
    private void on_folder_progress_info (ProgressInfo progress);
    private void on_folder_sync_state_changed (Folder folder);
    private void on_is_connected_changed ();

    /***********************************************************
    ***********************************************************/
    private void set_sync_state_for_folder (Folder folder);
    private void mark_folder_as_error (Folder folder);
    private void mark_folder_as_success (Folder folder);
    private bool folder_errors ();
    private bool folder_error (Folder folder);
    private void clear_folder_errors ();
    private void set_sync_state_to_connected_state ();
    private bool reload_needed (AccountState account_state);
    private void init_sync_state ();

    /***********************************************************
    ***********************************************************/
    private void set_sync_progress (double value);
    private void set_syncing (bool value);
    private void set_sync_status_string (string value);
    private void set_sync_status_detail_string (string value);
    private void set_sync_icon (GLib.Uri value);
    private void set_account_state (AccountStatePtr account_state);

    /***********************************************************
    ***********************************************************/
    private AccountStatePtr this.account_state;

    /***********************************************************
    ***********************************************************/
    private 
    private GLib.Uri this.sync_icon = Theme.instance ().sync_status_ok ();
    private double this.progress = 1.0;
    private bool this.is_syncing = false;
    private string this.sync_status_string = _("All synced!");
    private string this.sync_status_detail_string;
}
}










namespace {

    Occ.SyncResult.Status determine_sync_status (Occ.SyncResult sync_result) {
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

    Sync_status_summary.Sync_status_summary (GLib.Object parent) {
        base (parent);
        const var folder_man = FolderMan.instance ();
        connect (folder_man, &FolderMan.folder_list_changed, this, &Sync_status_summary.on_folder_list_changed);
        connect (folder_man, &FolderMan.folder_sync_state_change, this, &Sync_status_summary.on_folder_sync_state_changed);
    }

    bool Sync_status_summary.reload_needed (AccountState account_state) {
        if (this.account_state.data () == account_state) {
            return false;
        }
        return true;
    }

    void Sync_status_summary.on_load () {
        const var current_user = User_model.instance ().current_user ();
        if (!current_user) {
            return;
        }
        set_account_state (current_user.account_state ());
        clear_folder_errors ();
        connect_to_folders_progress (FolderMan.instance ().map ());
        init_sync_state ();
    }

    double Sync_status_summary.sync_progress () {
        return this.progress;
    }

    GLib.Uri Sync_status_summary.sync_icon () {
        return this.sync_icon;
    }

    bool Sync_status_summary.syncing () {
        return this.is_syncing;
    }

    void Sync_status_summary.on_folder_list_changed (Occ.Folder.Map folder_map) {
        connect_to_folders_progress (folder_map);
    }

    void Sync_status_summary.mark_folder_as_error (Folder folder) {
        this.folders_with_errors.insert (folder.alias ());
    }

    void Sync_status_summary.mark_folder_as_success (Folder folder) {
        this.folders_with_errors.erase (folder.alias ());
    }

    bool Sync_status_summary.folder_errors () {
        return this.folders_with_errors.size () != 0;
    }

    bool Sync_status_summary.folder_error (Folder folder) {
        return this.folders_with_errors.find (folder.alias ()) != this.folders_with_errors.end ();
    }

    void Sync_status_summary.clear_folder_errors () {
        this.folders_with_errors.clear ();
    }

    void Sync_status_summary.set_sync_state_for_folder (Folder folder) {
        if (this.account_state && !this.account_state.is_connected ()) {
            set_syncing (false);
            set_sync_status_string (_("Offline"));
            set_sync_status_detail_string ("");
            set_sync_icon (Theme.instance ().folder_offline ());
            return;
        }

        const var state = determine_sync_status (folder.sync_result ());

        switch (state) {
        case SyncResult.Status.SUCCESS:
        case SyncResult.Status.SYNC_PREPARE:
            // Success should only be shown if all folders were fine
            if (!folder_errors () || folder_error (folder)) {
                set_syncing (false);
                set_sync_status_string (_("All synced!"));
                set_sync_status_detail_string ("");
                set_sync_icon (Theme.instance ().sync_status_ok ());
                mark_folder_as_success (folder);
            }
            break;
        case SyncResult.Status.ERROR:
        case SyncResult.Status.SETUP_ERROR:
            set_syncing (false);
            set_sync_status_string (_("Some files couldn't be synced!"));
            set_sync_status_detail_string (_("See below for errors"));
            set_sync_icon (Theme.instance ().sync_status_error ());
            mark_folder_as_error (folder);
            break;
        case SyncResult.Status.SYNC_RUNNING:
        case SyncResult.Status.NOT_YET_STARTED:
            set_syncing (true);
            set_sync_status_string (_("Syncing"));
            set_sync_status_detail_string ("");
            set_sync_icon (Theme.instance ().sync_status_running ());
            break;
        case SyncResult.Status.PAUSED:
        case SyncResult.Status.SYNC_ABORT_REQUESTED:
            set_syncing (false);
            set_sync_status_string (_("Sync paused"));
            set_sync_status_detail_string ("");
            set_sync_icon (Theme.instance ().sync_status_pause ());
            break;
        case SyncResult.Status.PROBLEM:
        case SyncResult.Status.UNDEFINED:
            set_syncing (false);
            set_sync_status_string (_("Some files could not be synced!"));
            set_sync_status_detail_string (_("See below for warnings"));
            set_sync_icon (Theme.instance ().sync_status_warning ());
            mark_folder_as_error (folder);
            break;
        }
    }

    void Sync_status_summary.on_folder_sync_state_changed (Folder folder) {
        if (!folder) {
            return;
        }

        if (!this.account_state || folder.account_state () != this.account_state.data ()) {
            return;
        }

        set_sync_state_for_folder (folder);
    }

    constexpr double calculate_overall_percent (
        int64 total_file_count, int64 completed_file, int64 total_size, int64 completed_size) {
        int overall_percent = 0;
        if (total_file_count > 0) {
            // Add one 'byte' for each file so the percentage is moving when deleting or renaming files
            overall_percent = q_round (double (completed_size + completed_file) / double (total_size + total_file_count) * 100.0);
        }
        overall_percent = q_bound (0, overall_percent, 100);
        return overall_percent / 100.0;
    }

    void Sync_status_summary.on_folder_progress_info (ProgressInfo progress) {
        const int64 completed_size = progress.completed_size ();
        const int64 current_file = progress.current_file ();
        const int64 completed_file = progress.completed_files ();
        const int64 total_size = q_max (completed_size, progress.total_size ());
        const int64 total_file_count = q_max (current_file, progress.total_files ());

        set_sync_progress (calculate_overall_percent (total_file_count, completed_file, total_size, completed_size));

        if (total_size > 0) {
            const var completed_size_string = Utility.octets_to_string (completed_size);
            const var total_size_string = Utility.octets_to_string (total_size);

            if (progress.trust_eta ()) {
                set_sync_status_detail_string (
                    _("%1 of %2 · %3 left")
                        .arg (completed_size_string, total_size_string)
                        .arg (Utility.duration_to_descriptive_string1 (progress.total_progress ().estimated_eta)));
            } else {
                set_sync_status_detail_string (_("%1 of %2").arg (completed_size_string, total_size_string));
            }
        }

        if (total_file_count > 0) {
            set_sync_status_string (_("Syncing file %1 of %2").arg (current_file).arg (total_file_count));
        }
    }

    void Sync_status_summary.set_syncing (bool value) {
        if (value == this.is_syncing) {
            return;
        }

        this.is_syncing = value;
        /* emit */ syncing_changed ();
    }

    void Sync_status_summary.set_sync_progress (double value) {
        if (this.progress == value) {
            return;
        }

        this.progress = value;
        /* emit */ sync_progress_changed ();
    }

    void Sync_status_summary.set_sync_status_string (string value) {
        if (this.sync_status_string == value) {
            return;
        }

        this.sync_status_string = value;
        /* emit */ sync_status_string_changed ();
    }

    string Sync_status_summary.sync_status_"" {
        return this.sync_status_string;
    }

    string Sync_status_summary.sync_status_detail_"" {
        return this.sync_status_detail_string;
    }

    void Sync_status_summary.set_sync_icon (GLib.Uri value) {
        if (this.sync_icon == value) {
            return;
        }

        this.sync_icon = value;
        /* emit */ sync_icon_changed ();
    }

    void Sync_status_summary.set_sync_status_detail_string (string value) {
        if (this.sync_status_detail_string == value) {
            return;
        }

        this.sync_status_detail_string = value;
        /* emit */ sync_status_detail_string_changed ();
    }

    void Sync_status_summary.connect_to_folders_progress (Folder.Map folder_map) {
        for (var folder : folder_map) {
            if (folder.account_state () == this.account_state.data ()) {
                connect (
                    folder, &Folder.progress_info, this, &Sync_status_summary.on_folder_progress_info, Qt.UniqueConnection);
            } else {
                disconnect (folder, &Folder.progress_info, this, &Sync_status_summary.on_folder_progress_info);
            }
        }
    }

    void Sync_status_summary.on_is_connected_changed () {
        set_sync_state_to_connected_state ();
    }

    void Sync_status_summary.set_sync_state_to_connected_state () {
        set_syncing (false);
        set_sync_status_detail_string ("");
        if (this.account_state && !this.account_state.is_connected ()) {
            set_sync_status_string (_("Offline"));
            set_sync_icon (Theme.instance ().folder_offline ());
        } else {
            set_sync_status_string (_("All synced!"));
            set_sync_icon (Theme.instance ().sync_status_ok ());
        }
    }

    void Sync_status_summary.set_account_state (AccountStatePtr account_state) {
        if (!reload_needed (account_state.data ())) {
            return;
        }
        if (this.account_state) {
            disconnect (
                this.account_state.data (), &AccountState.is_connected_changed, this, &Sync_status_summary.on_is_connected_changed);
        }
        this.account_state = account_state;
        connect (this.account_state.data (), &AccountState.is_connected_changed, this, &Sync_status_summary.on_is_connected_changed);
    }

    void Sync_status_summary.init_sync_state () {
        var sync_state_fallback_needed = true;
        for (var folder : FolderMan.instance ().map ()) {
            on_folder_sync_state_changed (folder);
            sync_state_fallback_needed = false;
        }

        if (sync_state_fallback_needed) {
            set_sync_state_to_connected_state ();
        }
    }
    }
    