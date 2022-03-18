

namespace Testing {

// stub to prevent linker error
public class StubFolderMan : AccountManager {

    //  const QMetaObject static_meta_object = GLib.Object.static_meta_object;

    AccountManager instance {
        return (AccountManager) dummy ();
    }

    void save (bool value) { }

    void save_account_state (AccountState state) { }

    void delete_account (AccountState state) { }

    void account_removed (AccountState state) { }

    GLib.List<unowned AccountState> accounts () {
        return GLib.List<unowned AccountState> ();
    }

    AccountState account (string value) {
        return AccountState ();
    }

    void remove_account_folders (AccountState state) { }


    // From StubRemoteWipe ???
    //
    //  FolderMan *FolderMan.instance { return static_cast<FolderMan> (new GLib.Object); }
    //  void FolderMan.wipe_done (AccountState*, bool) { }
    //  Folder* FolderMan.add_folder (AccountState*, FolderDefinition const &) { return null; }
    //  void FolderMan.on_signal_wipe_folder_for_account (AccountState*) { }
    //  string FolderMan.unescape_alias (string const&) { return ""; }
    //  string FolderMan.escape_alias (string const&) { return ""; }
    //  void FolderMan.schedule_folder (Folder*) { }
    //  SocketApi *FolderMan.socket_api () { return new SocketApi;  }
    //  const Folder.Map &FolderMan.map () { return Folder.Map (); }
    //  void FolderMan.set_sync_enabled (bool) { }
    //  void FolderMan.on_signal_sync_once_file_unlocks (string const&) { }
    //  void FolderMan.on_signal_schedule_etag_job (string const&, RequestEtagJob*) { }
    //  Folder *FolderMan.folder_for_path (string const&) { return null; }
    //  Folder* FolderMan.folder_by_alias (string const&) { return null; }
    //  void FolderMan.folder_sync_state_change (Folder*) { }
    //  const QMetaObject FolderMan.static_meta_object = GLib.Object.static_meta_object;



} // class StubFolderMan
} // namespace Testing
