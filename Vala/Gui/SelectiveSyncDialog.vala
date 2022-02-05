/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QDialogButtonBox>
//  #include <QVBoxLayout>
//  #include <QTree_widget>
//  #include <qpushbutton.h>
//  #include <QFile_icon_provider>
//  #include <QHeaderView>
//  #include <QSettings>
//  #include <QScoped_value_rollback>
//  #include <QTree_widget_item>
//  #include <QLabel>
//  #include <QVBoxLayout>

//  #include <Gtk.Dialog>
//  #include <QTree_widget>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The Selective_sync_dialog class
@ingroup gui
***********************************************************/
class Selective_sync_dialog : Gtk.Dialog {

    // Dialog for a specific folder (used from the account settings button)
    public Selective_sync_dialog (AccountPointer account, Folder folder, Gtk.Widget parent = null, Qt.Window_flags f = {});

    // Dialog for the whole account (Used from the wizard)
    public Selective_sync_dialog (AccountPointer account, string folder, string[] blocklist, Gtk.Widget parent = null, Qt.Window_flags f = {});

    /***********************************************************
    ***********************************************************/
    public void on_accept () override;

    /***********************************************************
    ***********************************************************/
    public string[] create_block_list ();

    /***********************************************************
    ***********************************************************/
    public string[] old_block_list ();

    // Estimate the size of the total of sync'ed files from the server
    public int64 estimated_size ();


    /***********************************************************
    ***********************************************************/
    private void on_init (AccountPointer account);

    /***********************************************************
    ***********************************************************/
    private Selective_sync_widget this.selective_sync;

    /***********************************************************
    ***********************************************************/
    private Folder this.folder;
    private QPushButton this.ok_button;
}


    Selective_sync_dialog.Selective_sync_dialog (AccountPointer account, Folder folder, Gtk.Widget parent, Qt.Window_flags f)
        : Gtk.Dialog (parent, f)
        this.folder (folder)
        this.ok_button (null) // defined in on_init () {
        bool ok = false;
        on_init (account);
        string[] selective_sync_list = this.folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok);
        if (ok) {
            this.selective_sync.folder_info (this.folder.remote_path (), this.folder.alias (), selective_sync_list);
        } else {
            this.ok_button.enabled (false);
        }
        // Make sure we don't get crashes if the folder is destroyed while we are still open
        connect (this.folder, &GLib.Object.destroyed, this, &GLib.Object.delete_later);
    }

    Selective_sync_dialog.Selective_sync_dialog (AccountPointer account, string folder,
        const string[] blocklist, Gtk.Widget parent, Qt.Window_flags f)
        : Gtk.Dialog (parent, f)
        this.folder (null) {
        on_init (account);
        this.selective_sync.folder_info (folder, folder, blocklist);
    }

    void Selective_sync_dialog.on_init (AccountPointer account) {
        window_title (_("Choose What to Sync"));
        var layout = new QVBoxLayout (this);
        this.selective_sync = new Selective_sync_widget (account, this);
        layout.add_widget (this.selective_sync);
        var button_box = new QDialogButtonBox (Qt.Horizontal);
        this.ok_button = button_box.add_button (QDialogButtonBox.Ok);
        connect (this.ok_button, &QPushButton.clicked, this, &Selective_sync_dialog.accept);
        QPushButton button = null;
        button = button_box.add_button (QDialogButtonBox.Cancel);
        connect (button, &QAbstractButton.clicked, this, &Gtk.Dialog.reject);
        layout.add_widget (button_box);
    }

    void Selective_sync_dialog.on_accept () {
        if (this.folder) {
            bool ok = false;
            var old_block_list_set = this.folder.journal_database ().get_selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, ok).to_set ();
            if (!ok) {
                return;
            }
            string[] block_list = this.selective_sync.create_block_list ();
            this.folder.journal_database ().selective_sync_list (SyncJournalDb.SelectiveSyncListType.SELECTIVE_SYNC_BLOCKLIST, block_list);

            FolderMan folder_man = FolderMan.instance ();
            if (this.folder.is_busy ()) {
                this.folder.on_terminate_sync ();
            }

            //The part that changed should not be read from the DB on next sync because there might be new folders
            // (the ones that are no longer in the blocklist)
            var block_list_set = block_list.to_set ();
            var changes = (old_block_list_set - block_list_set) + (block_list_set - old_block_list_set);
            foreach (var it, changes) {
                this.folder.journal_database ().schedule_path_for_remote_discovery (it);
                this.folder.on_schedule_path_for_local_discovery (it);
            }

            folder_man.schedule_folder (this.folder);
        }
        Gtk.Dialog.on_accept ();
    }

    string[] Selective_sync_dialog.create_block_list () {
        return this.selective_sync.create_block_list ();
    }

    string[] Selective_sync_dialog.old_block_list () {
        return this.selective_sync.old_block_list ();
    }

    int64 Selective_sync_dialog.estimated_size () {
        return this.selective_sync.estimated_size ();
    }
    }
    