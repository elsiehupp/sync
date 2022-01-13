// stub to prevent linker error

Q_GLOBAL_STATIC (GLib.Object, dummy)

Occ.AccountManager *Occ.AccountManager.instance () { return static_cast<AccountManager> (dummy ()); }
void Occ.AccountManager.save (bool) { }
void Occ.AccountManager.saveAccountState (AccountState *) { }
void Occ.AccountManager.deleteAccount (AccountState *) { }
void Occ.AccountManager.accountRemoved (Occ.AccountState*) { }
QList<Occ.AccountStatePtr> Occ.AccountManager.accounts () { return QList<Occ.AccountStatePtr> (); }
Occ.AccountStatePtr Occ.AccountManager.account (string &){ return AccountStatePtr (); }
void Occ.AccountManager.removeAccountFolders (Occ.AccountState*) { }
const QMetaObject Occ.AccountManager.staticMetaObject = GLib.Object.staticMetaObject;
