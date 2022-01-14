/***********************************************************
Copyright (C) by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #pragma once

namespace Occ {

class FileActivityListModel : ActivityListModel {

    public FileActivityListModel (GLib.Object *parent = nullptr);

public slots:
    void load (AccountState *account_state, string &file_id);

protected:
    void start_fetch_job () override;

private:
    string _file_id;
};
    FileActivityListModel.FileActivityListModel (GLib.Object *parent)
        : ActivityListModel (nullptr, parent) {
        set_display_actions (false);
    }

    void FileActivityListModel.load (AccountState *account_state, string &local_path) {
        Q_ASSERT (account_state);
        if (!account_state || currently_fetching ()) {
            return;
        }
        set_account_state (account_state);

        const auto folder = FolderMan.instance ().folder_for_path (local_path);
        if (!folder) {
            return;
        }

        const auto file = folder.file_from_local_path (local_path);
        SyncJournalFileRecord file_record;
        if (!folder.journal_db ().get_file_record (file, &file_record) || !file_record.is_valid ()) {
            return;
        }

        _file_id = file_record._file_id;
        slot_refresh_activity ();
    }

    void FileActivityListModel.start_fetch_job () {
        if (!account_state ().is_connected ()) {
            return;
        }
        set_currently_fetching (true);

        const string url (QStringLiteral ("ocs/v2.php/apps/activity/api/v2/activity/filter"));
        auto job = new JsonApiJob (account_state ().account (), url, this);
        GLib.Object.connect (job, &JsonApiJob.json_received,
            this, &FileActivityListModel.activities_received);

        QUrlQuery params;
        params.add_query_item (QStringLiteral ("sort"), QStringLiteral ("asc"));
        params.add_query_item (QStringLiteral ("object_type"), "files");
        params.add_query_item (QStringLiteral ("object_id"), _file_id);
        job.add_query_params (params);
        set_done_fetching (true);
        set_hide_old_activities (true);
        job.start ();
    }
    }
    