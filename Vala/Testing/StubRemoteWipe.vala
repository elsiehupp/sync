

namespace Testing {

// stub to prevent linker error
class StubRemoteWipe : Occ.AccountManager {

    //  const QMetaObject static_meta_object = GLib.Object.static_meta_object;

    Occ.AccountManager instance () {
        return (AccountManager) new GLib.Object ();
    }

    void save (bool value) { }

    Occ.AccountState add_account (AccountPointer account) {
        return new Occ.AccountState (account);
    }

    void delete_account (AccountState state) { }

    void account_removed (Occ.AccountState state) { }

    GLib.List<Occ.AccountStatePtr> accounts () {
        return new GLib.List<Occ.AccountStatePtr> ();
    }

    Occ.AccountStatePtr account (string value) {
        return AccountStatePtr ();
    }

} // class StubRemoteWipe
} // namespace Testing
