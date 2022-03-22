/***********************************************************
@author Felix Weilbach <felix.weilbach@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class FileActivityListModel : ActivityListModel {

    /***********************************************************
    ***********************************************************/
    private string file_id;

    /***********************************************************
    ***********************************************************/
    public FileActivityListModel (GLib.Object parent = new GLib.Object ()) {
        base (null, parent);
        display_actions (false);
    }

    /***********************************************************
    ***********************************************************/
    public void on_signal_load (AccountState account_state, string file_id) {
        //  Q_ASSERT (account_state);
        if (!account_state || currently_fetching ()) {
            return;
        }
        account_state (account_state);

        const var folder = FolderManager.instance.folder_for_path (local_path);
        if (!folder) {
            return;
        }

        const var file = folder.file_from_local_path (local_path);
        SyncJournalFileRecord file_record;
        if (!folder.journal_database ().file_record (file, file_record) || !file_record.is_valid ()) {
            return;
        }

        this.file_id = file_record.file_id;
        on_signal_refresh_activity ();
    }


    /***********************************************************
    ***********************************************************/
    protected override void start_fetch_job () {
        if (!account_state.is_connected) {
            return;
        }
        currently_fetching (true);

        const string url = "ocs/v2.php/apps/activity/api/v2/activity/filter";
        var json_api_job = new JsonApiJob (account_state.account, url, this);
        json_api_job.json_received.connect (
            this.activities_received
        );

        QUrlQuery parameters;
        parameters.add_query_item ("sort", "asc");
        parameters.add_query_item ("object_type", "files");
        parameters.add_query_item ("object_id", this.file_id);
        json_api_job.add_query_params (parameters);
        done_fetching (true);
        hide_old_activities (true);
        json_api_job.on_signal_start ();
    }

} // class FileActivityListModel

} // namespace Ui
} // namespace Occ
