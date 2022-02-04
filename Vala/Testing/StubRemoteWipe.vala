// stub to prevent linker error

Occ.AccountManager *Occ.AccountManager.instance () { return static_cast<AccountManager> (new GLib.Object); }
void Occ.AccountManager.save (bool) { }
Occ.AccountState *Occ.AccountManager.addAccount (AccountPointer& ac) { return new Occ.AccountState (ac); }
void Occ.AccountManager.deleteAccount (AccountState *) { }
void Occ.AccountManager.accountRemoved (Occ.AccountState*) { }
GLib.List<Occ.AccountStatePtr> Occ.AccountManager.accounts () { return GLib.List<Occ.AccountStatePtr> (); }
Occ.AccountStatePtr Occ.AccountManager.account (string ){ return AccountStatePtr (); }
const QMetaObject Occ.AccountManager.staticMetaObject = GLib.Object.staticMetaObject;

Occ.FolderMan *Occ.FolderMan.instance () { return static_cast<FolderMan> (new GLib.Object); }
void Occ.FolderMan.wipeDone (Occ.AccountState*, bool) { }
Occ.Folder* Occ.FolderMan.addFolder (Occ.AccountState*, Occ.FolderDefinition const &) { return null; }
void Occ.FolderMan.slotWipeFolderForAccount (Occ.AccountState*) { }
string Occ.FolderMan.unescapeAlias (string const&){ return ""; }
string Occ.FolderMan.escapeAlias (string const&){ return ""; }
void Occ.FolderMan.scheduleFolder (Occ.Folder*){ }
Occ.SocketApi *Occ.FolderMan.socketApi (){ return new SocketApi;  }
const Occ.Folder.Map &Occ.FolderMan.map () { return Occ.Folder.Map (); }
void Occ.FolderMan.setSyncEnabled (bool) { }
void Occ.FolderMan.slotSyncOnceFileUnlocks (string const&) { }
void Occ.FolderMan.slotScheduleETagJob (string const&, Occ.RequestEtagJob*){ }
Occ.Folder *Occ.FolderMan.folderForPath (string const&) { return null; }
Occ.Folder* Occ.FolderMan.folder (string const&) { return null; }
void Occ.FolderMan.folderSyncStateChange (Occ.Folder*) { }
const QMetaObject Occ.FolderMan.staticMetaObject = GLib.Object.staticMetaObject;
