/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

namespace Occ {

class FileActivityListModel : ActivityListModel {

    /***********************************************************
    ***********************************************************/
    public FileActivityListModel (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public 
    public void on_load (AccountState account_state, string file_id);


    protected void start_fetch_job () override;


    /***********************************************************
    ***********************************************************/
    private string this.file_id;
};
    FileActivityListModel.FileActivityListModel (GLib.Object parent)
        : ActivityListModel (nullptr, parent) {
        set_display_actions (false);
    }

    void FileActivityListModel.on_load (AccountState account_state, string local_path) {
        Q_ASSERT (account_state);
        if (!account_state || currently_fetching ()) {
            return;
        }
        set_account_state (account_state);

        const var folder = FolderMan.instance ().folder_for_path (local_path);
        if (!folder) {
            return;
        }

        const var file = folder.file_from_local_path (local_path);
        SyncJournalFileRecord file_record;
        if (!folder.journal_database ().get_file_record (file, file_record) || !file_record.is_valid ()) {
            return;
        }

        this.file_id = file_record._file_id;
        on_refresh_activity ();
    }

    void FileActivityListModel.start_fetch_job () {
        if (!account_state ().is_connected ()) {
            return;
        }
        set_currently_fetching (true);

        const string url (QStringLiteral ("ocs/v2.php/apps/activity/api/v2/activity/filter"));
        var job = new JsonApiJob (account_state ().account (), url, this);
        GLib.Object.connect (job, &JsonApiJob.json_received,
            this, &FileActivityListModel.activities_received);

        QUrlQuery parameters;
        parameters.add_query_item (QStringLiteral ("sort"), QStringLiteral ("asc"));
        parameters.add_query_item (QStringLiteral ("object_type"), "files");
        parameters.add_query_item (QStringLiteral ("object_id"), this.file_id);
        job.add_query_params (parameters);
        set_done_fetching (true);
        set_hide_old_activities (true);
        job.on_start ();
    }
    }
    