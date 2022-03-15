

namespace Testing {

// stub to prevent linker error
public class StubFolderMan : Occ.AccountManager {

    //  const QMetaObject static_meta_object = GLib.Object.static_meta_object;

    Occ.AccountManager instance () {
        return (AccountManager) dummy ();
    }

    void save (bool value) { }

    void save_account_state (AccountState state) { }

    void delete_account (AccountState state) { }

    void account_removed (Occ.AccountState state) { }

    GLib.List<unowned Occ.AccountState> accounts () {
        return GLib.List<unowned Occ.AccountState> ();
    }

    Occ.AccountState account (string value) {
        return AccountState ();
    }

    void remove_account_folders (Occ.AccountState state) { }


    // From StubRemoteWipe ???
    //
    //  Occ.FolderMan *Occ.FolderMan.instance () { return static_cast<FolderMan> (new GLib.Object); }
    //  void Occ.FolderMan.wipe_done (Occ.AccountState*, bool) { }
    //  Occ.Folder* Occ.FolderMan.add_folder (Occ.AccountState*, Occ.FolderDefinition const &) { return null; }
    //  void Occ.FolderMan.slot_wipe_folder_for_account (Occ.AccountState*) { }
    //  string Occ.FolderMan.unescape_alias (string const&) { return ""; }
    //  string Occ.FolderMan.escape_alias (string const&) { return ""; }
    //  void Occ.FolderMan.schedule_folder (Occ.Folder*) { }
    //  Occ.SocketApi *Occ.FolderMan.socket_api () { return new SocketApi;  }
    //  const Occ.Folder.Map &Occ.FolderMan.map () { return Occ.Folder.Map (); }
    //  void Occ.FolderMan.set_sync_enabled (bool) { }
    //  void Occ.FolderMan.slot_sync_once_file_unlocks (string const&) { }
    //  void Occ.FolderMan.slot_schedule_etag_job (string const&, Occ.RequestEtagJob*) { }
    //  Occ.Folder *Occ.FolderMan.folder_for_path (string const&) { return null; }
    //  Occ.Folder* Occ.FolderMan.folder_by_alias (string const&) { return null; }
    //  void Occ.FolderMan.folder_sync_state_change (Occ.Folder*) { }
    //  const QMetaObject Occ.FolderMan.static_meta_object = GLib.Object.static_meta_object;



} // class StubFolderMan
} // namespace Testing
