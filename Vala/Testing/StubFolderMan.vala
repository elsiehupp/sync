

namespace Testing {

// stub to prevent linker error
class StubFolderMan : Occ.AccountManager {

    //  const QMetaObject staticMetaObject = GLib.Object.staticMetaObject;

    Occ.AccountManager instance () {
        return (AccountManager) dummy ();
    }

    void save (bool value) { }

    void save_account_state (AccountState state) { }

    void delete_account (AccountState state) { }

    void account_removed (Occ.AccountState state) { }

    GLib.List<Occ.AccountStatePtr> accounts () {
        return GLib.List<Occ.AccountStatePtr> ();
    }

    Occ.AccountStatePtr account (string value) {
        return AccountStatePtr ();
    }

    void remove_account_folders (Occ.AccountState state) { }


    // From StubRemoteWipe ???
    //
    //  Occ.FolderMan *Occ.FolderMan.instance () { return static_cast<FolderMan> (new GLib.Object); }
    //  void Occ.FolderMan.wipeDone (Occ.AccountState*, bool) { }
    //  Occ.Folder* Occ.FolderMan.addFolder (Occ.AccountState*, Occ.FolderDefinition const &) { return null; }
    //  void Occ.FolderMan.slotWipeFolderForAccount (Occ.AccountState*) { }
    //  string Occ.FolderMan.unescapeAlias (string const&) { return ""; }
    //  string Occ.FolderMan.escapeAlias (string const&) { return ""; }
    //  void Occ.FolderMan.scheduleFolder (Occ.Folder*) { }
    //  Occ.SocketApi *Occ.FolderMan.socketApi () { return new SocketApi;  }
    //  const Occ.Folder.Map &Occ.FolderMan.map () { return Occ.Folder.Map (); }
    //  void Occ.FolderMan.setSyncEnabled (bool) { }
    //  void Occ.FolderMan.slotSyncOnceFileUnlocks (string const&) { }
    //  void Occ.FolderMan.slotScheduleETagJob (string const&, Occ.RequestEtagJob*) { }
    //  Occ.Folder *Occ.FolderMan.folderForPath (string const&) { return null; }
    //  Occ.Folder* Occ.FolderMan.folder_by_alias (string const&) { return null; }
    //  void Occ.FolderMan.folderSyncStateChange (Occ.Folder*) { }
    //  const QMetaObject Occ.FolderMan.staticMetaObject = GLib.Object.staticMetaObject;



} // class StubFolderMan
} // namespace Testing
