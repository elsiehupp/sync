

namespace Testing {

// stub to prevent linker error
class StubRemoteWipe : Occ.AccountManager {

    //  const QMetaObject staticMetaObject = GLib.Object.staticMetaObject;

    Occ.AccountManager instance () {
        return (AccountManager) new GLib.Object ();
    }

    void save (bool value) { }

    Occ.AccountState addAccount (AccountPointer account) {
        return new Occ.AccountState (account);
    }

    void deleteAccount (AccountState state) { }

    void accountRemoved (Occ.AccountState state) { }

    GLib.List<Occ.AccountStatePtr> accounts () {
        return new GLib.List<Occ.AccountStatePtr> ();
    }

    Occ.AccountStatePtr account (string value) {
        return AccountStatePtr ();
    }

} // class StubRemoteWipe
} // namespace Testing
