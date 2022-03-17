

namespace Testing {

// stub to prevent linker error
public class StubRemoteWipe : Occ.AccountManager {

    //  const QMetaObject static_meta_object = GLib.Object.static_meta_object;

    Occ.AccountManager instance {
        return (AccountManager) new GLib.Object ();
    }

    void save (bool value) { }

    Occ.AccountState add_account (unowned Account account) {
        return new Occ.AccountState (account);
    }

    void delete_account (AccountState state) { }

    void account_removed (Occ.AccountState state) { }

    GLib.List<unowned Occ.AccountState> accounts () {
        return new GLib.List<unowned Occ.AccountState> ();
    }

    Occ.AccountState account (string value) {
        return new AccountState ();
    }

} // class StubRemoteWipe
} // namespace Testing
