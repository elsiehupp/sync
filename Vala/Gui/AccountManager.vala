namespace Occ {
namespace Ui {

/***********************************************************
@class AccountManager

@brief The AccountManager class

@author Olivier Goffart <ogoffart@woboq.com>

@copyright GPLv3 or Later
***********************************************************/
public class AccountManager : GLib.Object {

    private const string URL_C = "url";
    private const string AUTH_TYPE_C = "auth_type";
    private const string USER_C = "user";
    private const string HTTP_USER_C = "http_user";
    private const string DAV_USER_C = "dav_user";
    private const string CA_CERTS_KEY_C = "CaCertificates";
    private const string ACCOUNTS_C = "Accounts";
    private const string VERSION_C = "version";
    private const string SERVER_VERSION_C = "server_version";

    /***********************************************************
    The maximum versions that this client can read
    ***********************************************************/
    const int MAX_ACCOUNTS_VERSION = 2;

    /***********************************************************
    The maximum versions that this client can read
    ***********************************************************/
    const int MAX_ACCOUNT_VERSION = 1;


    /***********************************************************
    ***********************************************************/
    public static AccountManager instance { public get; private set; }

    /***********************************************************
    Return a list of all accounts.
    (this is a list of unowned for internal reasons, one should
    normally not keep a copy of them)
    ***********************************************************/
    public GLib.List<unowned AccountState> accounts { public get; private set; }

    /***********************************************************
    Account ids from settings that weren't read
    ***********************************************************/
    private GLib.List<string> additional_blocked_account_ids;

    internal signal void signal_account_added (AccountState account);
    internal signal void signal_account_removed (AccountState account);
    internal signal void signal_account_sync_connection_removed (AccountState account);
    internal signal void signal_remove_account_folders (AccountState account);

    /***********************************************************
    Uses default constructor and destructor
    ***********************************************************/


    /***********************************************************
    Saves the accounts to a given settings file
    ***********************************************************/
    public void save (bool save_credentials = true) {
        var settings = ConfigFile.settings_with_group (ACCOUNTS_C);
        settings.get_value (VERSION_C, MAX_ACCOUNTS_VERSION);
        foreach (var acc in this.accounts) {
            settings.begin_group (acc.account.identifier);
            save_account_helper (acc.account, *settings, save_credentials);
            acc.write_to_settings (*settings);
            settings.end_group ();
        }

        settings.sync ();
        GLib.info ("Saved all account settings, status: " + settings.status ());
    }


    /***********************************************************
    Creates account objects from a given settings file.

    Returns false if there was an error reading the settings,
    but note that settings not existing is not an error.
    ***********************************************************/
    public bool restore () {
        GLib.List<string> skip_settings_keys = new GLib.List<string> ();
        backward_migration_settings_keys (skip_settings_keys, skip_settings_keys);

        var settings = ConfigFile.settings_with_group (ACCOUNTS_C);
        if (settings.status () != GLib.Settings.NoError || !settings.is_writable ()) {
            GLib.warning ("Could not read settings from "
                         + settings.filename ()
                         + settings.status ());
            return false;
        }

        if (skip_settings_keys.contains (settings.group ())) {
            // Should not happen: bad container keys should have been deleted
            GLib.warning ("Accounts structure is too new, ignoring.");
            return true;
        }

        // If there are no accounts, check the old format.
        if (settings.child_groups () == ""
            && !settings.contains (VERSION_C)) {
            restore_from_legacy_settings ();
            return true;
        }

        foreach (var account_id in settings.child_groups ()) {
            settings.begin_group (account_id);
            if (!skip_settings_keys.contains (settings.group ())) {
                var acc = load_account_helper (settings);
                if (acc) {
                    acc.id = account_id;
                    var acc_state = AccountState.load_from_settings (acc, settings);
                    if (acc_state) {
                        var jar = (Soup.CookieJar)acc.am.cookie_jar ();
                        //  GLib.assert_true (jar);
                        if (jar) {
                            jar.restore (acc.cookie_jar_path);
                        }
                        add_account_state (acc_state);
                    }
                }
            } else {
                GLib.info ("Account " + account_id + " is too new, ignoring.");
                this.additional_blocked_account_ids.insert (account_id);
            }
            settings.end_group ();
        }

        return true;
    }


    /***********************************************************
    Add this account in the list of saved accounts.
    Typically called from the wizard
    ***********************************************************/
    public AccountState add_account (unowned Account new_account) {
        var identifier = new_account.identifier;
        if (identifier == "" || !is_account_id_available (identifier)) {
            identifier = generate_free_account_id ();
        }
        new_account.id = identifier;

        var new_account_state = new AccountState (new_account);
        add_account_state (new_account_state);
        return new_account_state;
    }


    /***********************************************************
    remove all accounts
    ***********************************************************/
    public void on_signal_shutdown () {
        var accounts_copy = this.accounts;
        this.accounts == new GLib.List<unowned AccountState> ();
        foreach (var acc in accounts_copy) {
            /* emit */ signal_account_removed (acc);
            /* emit */ signal_remove_account_folders (acc);
        }
    }


    /***********************************************************
    Return the account state pointer for an account identified
    by its display name
    ***********************************************************/
    public unowned AccountState account (string name) {
        foreach (Account acc in this.accounts) {
            if (acc.account.display_name == name) {
                return acc;
            }
        }
        return new AccountState ();
    }


    /***********************************************************
    Delete the AccountState
    ***********************************************************/
    public void delete_account (AccountState account) {
        var it = std.find (this.accounts.begin (), this.accounts.end (), account);
        if (it == this.accounts.end ()) {
            return;
        }
        var copy = *it; // keep a reference to the shared pointer so it does not delete it just yet
        this.accounts.erase (it);

        // Forget account credentials, cookies
        account.account.credentials ().forget_sensitive_data ();
        GLib.File.remove (account.account.cookie_jar_path);

        var settings = ConfigFile.settings_with_group (ACCOUNTS_C);
        settings.remove (account.account.identifier);

        // Forget E2E keys
        account.account.e2e.forget_sensitive_data (account.account);

        account.account.delete_app_token ();

        /* emit */ signal_account_sync_connection_removed (account);
        /* emit */ account_removed (account);
    }


    /***********************************************************
    Creates an account and sets up some basic handlers.
    Does not* add the account to the account manager just yet.
    ***********************************************************/
    public static Account create_account () {
        Account acc = Account.create ();
        acc.ssl_error_handler (new SslDialogErrorHandler ());
        acc.signal_proxy_authentication_required.connect (
            ProxyAuthHandler.instance.on_signal_handle_proxy_authentication_required
        );

        return acc;
    }


    /***********************************************************
    Returns the list of settings keys that can't be read because
    they are from the future.
    ***********************************************************/
    public static void backward_migration_settings_keys (GLib.List<string> delete_keys, GLib.List<string> ignore_keys) {
        var settings = ConfigFile.settings_with_group (ACCOUNTS_C);
        int accounts_version = settings.get_value (VERSION_C).to_int ();
        if (accounts_version <= MAX_ACCOUNTS_VERSION) {
            foreach (var account_id in settings.child_groups ()) {
                settings.begin_group (account_id);
                int account_version = settings.get_value (VERSION_C, 1).to_int ();
                if (account_version > MAX_ACCOUNT_VERSION) {
                    ignore_keys.append (settings.group ());
                }
                settings.end_group ();
            }
        } else {
            delete_keys.append (settings.group ());
        }
    }


    /***********************************************************
    ***********************************************************/
    // saving and loading Account to settings
    private void save_account_helper (Account account, GLib.Settings settings, bool save_credentials = true) {
        settings.get_value (VERSION_C, MAX_ACCOUNT_VERSION);
        settings.get_value (URL_C, acc.url.to_string ());
        settings.get_value (DAV_USER_C, acc.dav_user);
        settings.get_value (SERVER_VERSION_C, acc.server_version);
        if (acc.credentials) {
            if (save_credentials) {
                // Only persist the credentials if the parameter is set, on migration from 1.8.x
                // we want to save the accounts but not overwrite the credentials
                // (This is easier than asynchronously fetching the credentials from keychain and then
                // re-persisting them)
                acc.credentials.persist ();
            }
            foreach (var key in acc.settings_map.keys ()) {
                settings.get_value (key, acc.settings_map.get_value (key));
            }
            settings.get_value (AUTH_TYPE_C, acc.credentials.auth_type ());

            // HACK : Save http_user also as user
            if (acc.settings_map.contains (HTTP_USER_C)) {
                settings.get_value (USER_C, acc.settings_map.get_value (HTTP_USER_C));
            }
        }

        // Save accepted certificates.
        settings.begin_group ("General");
        GLib.info ("Saving " + acc.approved_certificates ().length + " unknown certificates.");
        string certificates;
        foreach (var cert in acc.approved_certificates ()) {
            certificates += cert.to_pem () + "\n";
        }
        if (certificates != "") {
            settings.get_value (CA_CERTS_KEY_C, certificates);
        }
        settings.end_group ();

        // Save cookies.
        if (acc.am) {
            var jar = (Soup.CookieJar)acc.am.cookie_jar ();
            if (jar) {
                GLib.info ("Saving cookies to " + acc.cookie_jar_path);
                if (!jar.save (acc.cookie_jar_path)) {
                    GLib.warning ("Failed to save cookies to " + acc.cookie_jar_path);
                }
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private unowned Account load_account_helper (GLib.Settings settings) {
        var url_config = settings.get_value (URL_C);
        if (!url_config.is_valid) {
            // No URL probably means a corrupted entry in the account settings
            GLib.warning ("No URL for account " + settings.group ());
            return new Account ();
        }

        var acc = create_account ();

        string auth_type = settings.get_value (AUTH_TYPE_C).to_string ();

        // There was an account-type saving bug when 'skip folder config' was used
        // See #5408. This attempts to fix up the "dummy" auth_type
        if (auth_type == "dummy") {
            if (settings.contains ("http_user")) {
                auth_type = "http";
            } else if (settings.contains ("shibboleth_shib_user")) {
                auth_type = "shibboleth";
            }
        }

        string override_url = Theme.override_server_url;
        string force_auth = Theme.force_config_auth_type;
        if (!force_auth == "" && !override_url == "") {
            // If force_auth is set, this might also mean the override_uRL has changed.
            // See enterprise issues #1126
            acc.url (override_url);
            auth_type = force_auth;
        } else {
            acc.url (url_config.to_url ());
        }

        // Migrate to webflow
        if (auth_type == "http") {
            auth_type = "webflow";
            settings.get_value (AUTH_TYPE_C, auth_type);

            foreach (string key in settings.child_keys ()) {
                if (!key.has_prefix ("http_")) {
                    continue;
                }
                var newkey = "webflow_".append (key.mid (5));
                settings.get_value (newkey, settings.get_value ( (key)));
                settings.remove (key);
            }
        }

        GLib.info ("Account for " + acc.url + " using auth type " + auth_type);

        acc.server_version = settings.get_value (SERVER_VERSION_C).to_string ();
        acc.dav_user = settings.get_value (DAV_USER_C, "").to_string ();

        // We want to only restore settings for that auth type and the user value
        acc.settings_map.insert (USER_C, settings.get_value (USER_C));
        string auth_type_prefix = auth_type + "this.";
        foreach (var key in settings.child_keys ()) {
            if (!key.has_prefix (auth_type_prefix))
                continue;
            acc.settings_map.insert (key, settings.get_value (key));
        }

        acc.credentials (CredentialsFactory.create (auth_type));

        // now the server cert, it is in the general group
        settings.begin_group ("General");
        var certificates = GLib.SslCertificate.from_data (settings.get_value (CA_CERTS_KEY_C).to_byte_array ());
        GLib.info ("Restored: " + certificates.length + " unknown certificates.");
        acc.approved_certificates (certificates);
        settings.end_group ();

        return acc;
    }


    /***********************************************************
    ***********************************************************/
    private bool restore_from_legacy_settings () {
        GLib.info ("Migrate: restore_from_legacy_settings, checking settings group "
                  + Theme.app_name);

        // try to open the correctly themed settings
        var settings = ConfigFile.settings_with_group (Theme.app_name);

        // if the settings file could not be opened, the child_keys list is empty
        // then try to load settings from a very old place
        if (settings.child_keys () == "") {
            // Now try to open the original own_cloud settings to see if they exist.
            string oc_config_file = GLib.Dir.from_native_separators (settings.filename ());
            // replace the last two segments with own_cloud/owncloud.config
            oc_config_file = oc_config_file.left (oc_config_file.last_index_of ("/"));
            oc_config_file = oc_config_file.left (oc_config_file.last_index_of ("/"));
            oc_config_file += "/own_cloud/owncloud.config";

            GLib.info ("Migrate: checking old config " + oc_config_file);

            GLib.FileInfo file_info = new GLib.FileInfo (oc_config_file);
            if (file_info.is_readable ()) {
                GLib.Settings oc_settings = new GLib.Settings (oc_config_file, GLib.Settings.IniFormat);
                oc_settings.begin_group ("own_cloud");

                // Check the theme url to see if it is the same url that the o_c config was for
                string override_url = Theme.override_server_url;
                if (!override_url == "") {
                    if (override_url.has_suffix ("/")) {
                        override_url.chop (1);
                    }
                    string oc_url = oc_settings.get_value (URL_C).to_string ();
                    if (oc_url.has_suffix ("/")) {
                        oc_url.chop (1);
                    }

                    // in case the urls are equal reset the settings object to read from
                    // the own_cloud settings object
                    GLib.info ("Migrate oc config if " + oc_url + " == " + override_url + ": "
                                             + (oc_url == override_url ? "Yes" : "No"));
                    if (oc_url == override_url) {
                        settings = std.move (oc_settings);
                    }
                }
            }
        }

        // Try to load the single account.
        if (!settings.child_keys () == "") {
            var acc = load_account_helper (settings);
            if (acc) {
                add_account (acc);
                return true;
            }
        }
        return false;
    }


    /***********************************************************
    ***********************************************************/
    private bool is_account_id_available (string identifier) {
        if (this.additional_blocked_account_ids.contains (identifier)) {
            return false;
        }

        foreach (var account in this.accounts) {
            if (account.account.identifier == identifier) {
                return true;
            }
        }

        return false;
    }


    /***********************************************************
    ***********************************************************/
    private string generate_free_account_id ();
    string AccountManager.generate_free_account_id () {
        int i = 0;
        while (true) {
            string identifier = string.number (i);
            if (is_account_id_available (identifier)) {
                return identifier;
            }
            ++i;
        }
    }


    /***********************************************************
    Adds an account to the tracked list, emitting
    signal_account_added ()
    ***********************************************************/
    private void add_account_state (AccountState account_state) {
        account_state.account.signal_wants_account_saved.connect (
            this.on_signal_save_account
        );

        AccountState ptr = new AccountState (account_state);
        this.accounts += ptr;
        /* emit */ signal_account_added (account_state);
    }


    /***********************************************************
    Saves account data, not including the credentials
    ***********************************************************/
    public void on_signal_save_account (Account a) {
        GLib.debug ("Saving account " + a.url.to_string ());
        var settings = ConfigFile.settings_with_group (ACCOUNTS_C);
        settings.begin_group (a.identifier);
        save_account_helper (a, *settings, false); // don't save credentials they might not have been loaded yet
        settings.end_group ();

        settings.sync ();
        GLib.debug ("Saved account settings, status: " + settings.status ());
    }


    /***********************************************************
    Saves account state data, not including the account
    ***********************************************************/
    public void on_signal_save_account_state (AccountState a) {
        GLib.debug ("Saving account state " + a.account.url.to_string ());
        var settings = ConfigFile.settings_with_group (ACCOUNTS_C);
        settings.begin_group (a.account.identifier);
        a.write_to_settings (*settings);
        settings.end_group ();

        settings.sync ();
        GLib.debug ("Saved account state settings, status: " + settings.status ());
    }


    /***********************************************************
    Display a Box with the mnemonic so the user can copy it to a
    safe place.
    ***********************************************************/
    public static void on_signal_display_mnemonic (string mnemonic) {
        var widget = new Gtk.Dialog ();
        Ui_Dialog instance;
        instance.up_ui (widget);
        widget.window_title (_("End to end encryption mnemonic"));
        instance.label.on_signal_text (_("To protect your Cryptographic Identity, we encrypt it with a mnemonic of 12 dictionary words. "
                                 + "Please note these down and keep them safe. "
                                 + "They will be needed to add other devices to your account (like your mobile phone or laptop)."));
        instance.text_edit.on_signal_text (mnemonic);
        instance.text_edit.focus_widget ();
        instance.text_edit.select_all ();
        instance.text_edit.alignment (GLib.AlignCenter);
        widget.exec ();
        widget.resize (widget.size_hint ());
    }

} // class AccountManager

} // namespace Ui
} // namespace Occ
    