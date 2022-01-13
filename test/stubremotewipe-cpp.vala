// stub to prevent linker error

Occ.AccountManager *Occ.AccountManager.instance () { return static_cast<AccountManager> (new GLib.Object); }
void Occ.AccountManager.save (bool) { }
Occ.AccountState *Occ.AccountManager.addAccount (AccountPtr& ac) { return new Occ.AccountState (ac); }
void Occ.AccountManager.deleteAccount (AccountState *) { }
void Occ.AccountManager.accountRemoved (Occ.AccountState*) { }
QList<Occ.AccountStatePtr> Occ.AccountManager.accounts () { return QList<Occ.AccountStatePtr> (); }
Occ.AccountStatePtr Occ.AccountManager.account (QString &){ return AccountStatePtr (); }
const QMetaObject Occ.AccountManager.staticMetaObject = GLib.Object.staticMetaObject;

Occ.FolderMan *Occ.FolderMan.instance () { return static_cast<FolderMan> (new GLib.Object); }
void Occ.FolderMan.wipeDone (Occ.AccountState*, bool) { }
Occ.Folder* Occ.FolderMan.addFolder (Occ.AccountState*, Occ.FolderDefinition const &) { return nullptr; }
void Occ.FolderMan.slotWipeFolderForAccount (Occ.AccountState*) { }
QString Occ.FolderMan.unescapeAlias (QString const&){ return QString (); }
QString Occ.FolderMan.escapeAlias (QString const&){ return QString (); }
void Occ.FolderMan.scheduleFolder (Occ.Folder*){ }
Occ.SocketApi *Occ.FolderMan.socketApi (){ return new SocketApi;  }
const Occ.Folder.Map &Occ.FolderMan.map () { return Occ.Folder.Map (); }
void Occ.FolderMan.setSyncEnabled (bool) { }
void Occ.FolderMan.slotSyncOnceFileUnlocks (QString const&) { }
void Occ.FolderMan.slotScheduleETagJob (QString const&, Occ.RequestEtagJob*){ }
Occ.Folder *Occ.FolderMan.folderForPath (QString const&) { return nullptr; }
Occ.Folder* Occ.FolderMan.folder (QString const&) { return nullptr; }
void Occ.FolderMan.folderSyncStateChange (Occ.Folder*) { }
const QMetaObject Occ.FolderMan.staticMetaObject = GLib.Object.staticMetaObject;
