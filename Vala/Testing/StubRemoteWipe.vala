

namespace Testing {

// stub to prevent linker error
public class StubRemoteWipe : AccountManager {

    //  const QMetaObject static_meta_object = GLib.Object.static_meta_object;

    AccountManager instance {
        return (AccountManager) new GLib.Object ();
    }

    void save (bool value) { }

    AccountState add_account (unowned Account account) {
        return new AccountState (account);
    }

    void delete_account (AccountState state) { }

    void account_removed (AccountState state) { }

    GLib.List<unowned AccountState> accounts () {
        return new GLib.List<unowned AccountState> ();
    }

    AccountState account (string value) {
        return new AccountState ();
    }

} // class StubRemoteWipe
} // namespace Testing
