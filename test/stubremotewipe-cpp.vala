// stub to prevent linker error

Occ.AccountManager *Occ.AccountManager.instance () { return static_cast<AccountManager> (new GLib.Object); }
void Occ.AccountManager.save (bool) { }
Occ.AccountState *Occ.AccountManager.addAccount (AccountPtr& ac) { return new Occ.AccountState (ac); }
void Occ.AccountManager.deleteAccount (AccountState *) { }
void Occ.AccountManager.accountRemoved (Occ.AccountState*) { }
QList<Occ.AccountStatePtr> Occ.AccountManager.accounts () { return QList<Occ.AccountStatePtr> (); }
Occ.AccountStatePtr Occ.AccountManager.account (string &){ return AccountStatePtr (); }
const QMetaObject Occ.AccountManager.staticMetaObject = GLib.Object.staticMetaObject;

Occ.FolderMan *Occ.FolderMan.instance () { return static_cast<FolderMan> (new GLib.Object); }
void Occ.FolderMan.wipeDone (Occ.AccountState*, bool) { }
Occ.Folder* Occ.FolderMan.addFolder (Occ.AccountState*, Occ.FolderDefinition const &) { return nullptr; }
void Occ.FolderMan.slotWipeFolderForAccount (Occ.AccountState*) { }
string Occ.FolderMan.unescapeAlias (string const&){ return string (); }
string Occ.FolderMan.escapeAlias (string const&){ return string (); }
void Occ.FolderMan.scheduleFolder (Occ.Folder*){ }
Occ.SocketApi *Occ.FolderMan.socketApi (){ return new SocketApi;  }
const Occ.Folder.Map &Occ.FolderMan.map () { return Occ.Folder.Map (); }
void Occ.FolderMan.setSyncEnabled (bool) { }
void Occ.FolderMan.slotSyncOnceFileUnlocks (string const&) { }
void Occ.FolderMan.slotScheduleETagJob (string const&, Occ.RequestEtagJob*){ }
Occ.Folder *Occ.FolderMan.folderForPath (string const&) { return nullptr; }
Occ.Folder* Occ.FolderMan.folder (string const&) { return nullptr; }
void Occ.FolderMan.folderSyncStateChange (Occ.Folder*) { }
const QMetaObject Occ.FolderMan.staticMetaObject = GLib.Object.staticMetaObject;
