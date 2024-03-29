/***********************************************************
@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.DialogButtonBox>
//  #include <GLib.TreeWidget>
//  #include <qpushbutton.h>
//  #include <GLib.FileIconProvider>
//  #include <GLib.HeaderView>
//  #include <GLib.Settings>
//  #include <GLib.ScopedValueRollback>
//  #include <GLib.TreeWidgetItem>

//  #include <Gtk.Dialog>
//  #include <GLib.TreeWidget>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SelectiveSyncDialog class
@ingroup gui
***********************************************************/
public class SelectiveSyncDialog { //: Gtk.Dialog {

    //  /***********************************************************
    //  ***********************************************************/
    //  private SelectiveSyncWidget selective_sync;

    //  /***********************************************************
    //  ***********************************************************/
    //  private FolderConnection folder_connection;
    //  private GLib.PushButton ok_button;

    //  /***********************************************************
    //  Dialog for a specific folder_connection (used from the account settings button)
    //  ***********************************************************/
    //  public SelectiveSyncDialog.for_folder (LibSync.Account account, FolderConnection folder_connection, Gtk.Widget parent = null, GLib.WindowFlags window_flags = {}) {
        //  base (parent, window_flags);
        //  this.folder_connection = folder_connection;
        //  this.ok_button = null; // defined in on_signal_init ()
        //  bool ok = false;
        //  on_signal_init (account);
        //  GLib.List<string> selective_sync_list = this.folder_connection.journal_database.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
        //  if (ok) {
        //      this.selective_sync.folder_info (this.folder_connection.remote_path, this.folder_connection.alias (), selective_sync_list);
        //  } else {
        //      this.ok_button.enabled (false);
        //  }
        //  // Make sure we don't get crashes if the folder_connection is destroyed while we are still open
        //  this.folder_connection.destroyed.connect (
        //      this.delete_later
        //  );
    //  }


    //  /***********************************************************
    //  Dialog for the whole account (Used from the wizard)
    //  ***********************************************************/
    //  public SelectiveSyncDialog.for_path (LibSync.Account account, string folder_connection, GLib.List<string> blocklist, Gtk.Widget parent = null, GLib.WindowFlags window_flags = {}) {
        //  base (parent, window_flags);
        //  this.folder_connection = null;
        //  on_signal_init (account);
        //  this.selective_sync.folder_info (folder_connection, folder_connection, blocklist);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public override void on_signal_accept () {
        //  if (this.folder_connection != null) {
        //      bool ok = false;
        //      var old_block_list_set = this.folder_connection.journal_database.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok).to_set ();
        //      if (!ok) {
        //          return;
        //      }
        //      GLib.List<string> block_list = this.selective_sync.create_block_list ();
        //      this.folder_connection.journal_database.selective_sync_list (Common.SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, block_list);

        //      FolderManager folder_man = FolderManager.instance;
        //      if (this.folder_connection.is_busy ()) {
        //          this.folder_connection.on_signal_terminate_sync ();
        //      }

        //      //  The part that changed should not be read from the DB on next sync because there might be new folders
        //      // (the ones that are no longer in the blocklist)
        //      var block_list_set = block_list.to_set ();
        //      var changes = (old_block_list_set - block_list_set) + (block_list_set - old_block_list_set);
        //      foreach (var it in changes) {
        //          this.folder_connection.journal_database.schedule_path_for_remote_discovery (it);
        //          this.folder_connection.on_signal_schedule_path_for_local_discovery (it);
        //      }

        //      folder_man.schedule_folder (this.folder_connection);
        //  }
        //  Gtk.Dialog.on_signal_accept ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public GLib.List<string> create_block_list () {
        //  return this.selective_sync.create_block_list ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public GLib.List<string> old_block_list () {
        //  return this.selective_sync.old_block_list ();
    //  }


    //  /***********************************************************
    //  Estimate the size of the total of sync'ed files from the server
    //  ***********************************************************/
    //  public int64 estimated_size () {
        //  return this.selective_sync.estimated_size ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_init (LibSync.Account account) {
        //  window_title (_("Choose What to Sync"));
        //  var layout = new Gtk.Box (Gtk.Orientation.VERTICAL);

        //  this.selective_sync = new SelectiveSyncWidget (account, this);
        //  layout.add_widget (this.selective_sync);
        //  var button_box = new GLib.DialogButtonBox (GLib.Horizontal);
        //  this.ok_button = button_box.add_button (GLib.DialogButtonBox.Ok);
        //  this.ok_button.clicked.connect (
        //      this.accept
        //  );
        //  GLib.PushButton button = null;
        //  button = button_box.add_button (GLib.DialogButtonBox.Cancel);
        //  button.clicked.connect (
        //      this.reject
        //  );
        //  layout.add_widget (button_box);
    //  }

} // class SelectiveSyncDialog

} // namespace Ui
} // namespace Occ
