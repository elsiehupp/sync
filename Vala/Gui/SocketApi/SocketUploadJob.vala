/***********************************************************
@author Hannah von Reth <hannah.vonreth@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.FileInfo>
//  #include <GLib.JsonArray>
//  #include <GLib.Regex>
//  #include <GLib.TemporaryFile>

namespace Occ {
namespace Ui {

public class SocketUploadJob { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    private unowned SocketApiJobV2 api_job;
    private string local_path;
    private string remote_path;
    private string pattern;
    private GLib.TemporaryFile temporary;
    private Common.SyncJournalDb database;
    private LibSync.SyncEngine sync_engine;
    private GLib.List<string> synced_files = new GLib.List<string> ();

    /***********************************************************
    ***********************************************************/
    public SocketUploadJob (SocketApiJobV2 socket_api_v2_job) {
        //  this.api_job = socket_api_v2_job;
        //  socket_api_v2_job.signal_finished.connect (
        //      this.delete_later
        //  );

        //  this.local_path = this.api_job.arguments ()["local_path"].to_string ();
        //  this.remote_path = this.api_job.arguments ()["remote_path"].to_string ();
        //  if (!this.remote_path.has_prefix ("/")) {
        //      this.remote_path = "/" + this.remote_path;
        //  }

        //  this.pattern = socket_api_v2_job.arguments ()["pattern"].to_string ();
        //  // TODO: use uuid
        //  var accname = socket_api_v2_job.arguments ()["account"]["name"].to_string ();
        //  var account = AccountManager.instance.account (accname);

        //  if (!new GLib.FileInfo (this.local_path).is_absolute ()) {
        //      socket_api_v2_job.failure ("Local path must be a an absolute path");
        //      return;
        //  }
        //  if (!this.temporary.open ()) {
        //      socket_api_v2_job.failure ("Failed to create temporary database");
        //      return;
        //  }

        //  this.database = new Common.SyncJournalDb (this.temporary.filename (), this);
        //  this.sync_engine = new LibSync.SyncEngine (account.account, this.local_path.has_suffix ("/") ? this.local_path : this.local_path + "/", this.remote_path, this.database);
        //  this.sync_engine.parent (this.database);

        //  this.sync_engine.signal_item_completed.connect (
        //      this.on_signal_sync_engine_item_completed
        //  );

        //  this.sync_engine.signal_finished.connect (
        //      this.on_signal_sync_engine_finished
        //  );
        //  this.sync_engine.signal_sync_error.connect (
        //      this.on_signal_sync_engine_sync_error
        //  );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_engine_item_completed (LibSync.SyncFileItem item) {
        //  this.synced_files.append (item.file);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_engine_finished (bool ok) {
        //  if (ok) {
        //      this.api_job.on_signal_success (
        //          {
        //              {
        //                  "local_path",
        //                  this.local_path
        //              },
        //              {
        //                  "synced_files",
        //                  GLib.JsonArray.from_string_list (this.synced_files)
        //              }
        //          }
        //      );
        //  }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_sync_engine_sync_error (string error, LibSync.ErrorCategory category) {
        //  this.api_job.failure (error);
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_start () {
        //  var opt = this.sync_engine.sync_options ();
        //  opt.file_pattern (this.pattern);
        //  if (!opt.file_regex ().is_valid) {
        //      this.api_job.failure (opt.file_regex ().error_string);
        //      return;
        //  }
        //  this.sync_engine.sync_options (opt);

        //  // create the directory, fail if it already exists
        //  var mkcol_job = new MkColJob (this.sync_engine.account, this.remote_path);
        //  mkcol_job.signal_finished_without_error.connect (
        //      this.sync_engine,
        //      LibSync.SyncEngine.on_signal_start_sync
        //  );
        //  mkcol_job.signal_finished_with_error.connect (
        //      this.on_signal_mkcol_job_finished_with_error
        //  );
        //  mkcol_job.on_signal_start ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_mkcol_job_finished_with_error (GLib.InputStream reply) {
        //  if (reply.error == 202) {
        //      this.api_job.failure ("Destination %1 already exists".printf (this.remote_path));
        //  } else {
        //      this.api_job.failure (reply.error_string);
        //  }
    }

} // class SocketUploadJob

} // namespace Ui
} // namespace Occ
