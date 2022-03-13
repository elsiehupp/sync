/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDialogButtonBox>
//  #include <QVBoxLayout>
//  #include <QTreeWidget>
//  #include <qpushbutton.h>
//  #include <QFileIconProvider>
//  #include <QHeaderView>
//  #include <QSettings>
//  #include <QScopedValueRollback>
//  #include <QTreeWidgetItem>
//  #include <QVBoxLayout>

//  #include <Gtk.Dialog>
//  #include <QTreeWidget>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The SelectiveSyncDialog class
@ingroup gui
***********************************************************/
public class SelectiveSyncDialog : Gtk.Dialog {

    /***********************************************************
    ***********************************************************/
    private SelectiveSyncWidget selective_sync;

    /***********************************************************
    ***********************************************************/
    private Folder folder;
    private QPushButton ok_button;

    /***********************************************************
    Dialog for a specific folder (used from the account settings button)
    ***********************************************************/
    public SelectiveSyncDialog.for_folder (unowned Account account, Folder folder, Gtk.Widget parent = null, Qt.Window_flags f = {}) {
        base (parent, f);
        this.folder = folder;
        this.ok_button = null; // defined in on_signal_init ()
        bool ok = false;
        on_signal_init (account);
        string[] selective_sync_list = this.folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
        if (ok) {
            this.selective_sync.folder_info (this.folder.remote_path (), this.folder.alias (), selective_sync_list);
        } else {
            this.ok_button.enabled (false);
        }
        // Make sure we don't get crashes if the folder is destroyed while we are still open
        connect (this.folder, GLib.Object.destroyed, this, GLib.Object.delete_later);
    }


    /***********************************************************
    Dialog for the whole account (Used from the wizard)
    ***********************************************************/
    public SelectiveSyncDialog.for_path (unowned Account account, string folder, string[] blocklist, Gtk.Widget parent = null, Qt.Window_flags f = {}) {
        base (parent, f);
        this.folder = null;
        on_signal_init (account);
        this.selective_sync.folder_info (folder, folder, blocklist);
    }


    /***********************************************************
    ***********************************************************/
    public override void on_signal_accept () {
        if (this.folder) {
            bool ok = false;
            var old_block_list_set = this.folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok).to_set ();
            if (!ok) {
                return;
            }
            string[] block_list = this.selective_sync.create_block_list ();
            this.folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, block_list);

            FolderMan folder_man = FolderMan.instance ();
            if (this.folder.is_busy ()) {
                this.folder.on_signal_terminate_sync ();
            }

            //The part that changed should not be read from the DB on next sync because there might be new folders
            // (the ones that are no longer in the blocklist)
            var block_list_set = block_list.to_set ();
            var changes = (old_block_list_set - block_list_set) + (block_list_set - old_block_list_set);
            foreach (var it in changes) {
                this.folder.journal_database ().schedule_path_for_remote_discovery (it);
                this.folder.on_signal_schedule_path_for_local_discovery (it);
            }

            folder_man.schedule_folder (this.folder);
        }
        Gtk.Dialog.on_signal_accept ();
    }


    /***********************************************************
    ***********************************************************/
    public string[] create_block_list () {
        return this.selective_sync.create_block_list ();
    }


    /***********************************************************
    ***********************************************************/
    public string[] old_block_list () {
        return this.selective_sync.old_block_list ();
    }


    /***********************************************************
    Estimate the size of the total of sync'ed files from the server
    ***********************************************************/
    public int64 estimated_size () {
        return this.selective_sync.estimated_size ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_init (unowned Account account) {
        window_title (_("Choose What to Sync"));
        var layout = new QVBoxLayout (this);
        this.selective_sync = new SelectiveSyncWidget (account, this);
        layout.add_widget (this.selective_sync);
        var button_box = new QDialogButtonBox (Qt.Horizontal);
        this.ok_button = button_box.add_button (QDialogButtonBox.Ok);
        connect (this.ok_button, QPushButton.clicked, this, SelectiveSyncDialog.accept);
        QPushButton button = null;
        button = button_box.add_button (QDialogButtonBox.Cancel);
        connect (button, QAbstractButton.clicked, this, Gtk.Dialog.reject);
        layout.add_widget (button_box);
    }

} // class SelectiveSyncDialog

} // namespace Ui
} // namespace Occ
