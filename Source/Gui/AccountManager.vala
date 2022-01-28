/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <theme.h>
// #include <creds/credentialsfactory.h>
// #include <creds/abstractcredentials.h>
// #include <cookiejar.h>
// #include <QSettings>
// #include <QDir>
// #include <QNetworkAccessManager>
// #include <QMessageBox>

// #pragma once

namespace Occ {

namespace {
    static const char url_c[] = "url";
    static const char auth_type_c[] = "auth_type";
    static const char user_c[] = "user";
    static const char http_user_c[] = "http_user";
    static const char dav_user_c[] = "dav_user";
    static const char ca_certs_key_c[] = "CaCertificates";
    static const char accounts_c[] = "Accounts";
    static const char version_c[] = "version";
    static const char server_version_c[] = "server_version";

    // The maximum versions that this client can read
    static const int max_accounts_version = 2;
    static const int max_account_version = 1;
    }

/***********************************************************
@brief The AccountManager class
@ingroup gui
***********************************************************/
class AccountManager : GLib.Object {

    public static AccountManager instance ();
    ~AccountManager () override = default;


    /***********************************************************
    Saves the accounts to a given settings file
    ***********************************************************/
    public void save (bool save_credentials = true);


    /***********************************************************
    Creates account objects from a given settings file.

    Returns false if there was an error reading the settings,
    but note that settings not existing is not an error.
    ***********************************************************/
    public bool restore ();


    /***********************************************************
    Add this account in the list of saved accounts.
    Typically called from the wizard
    ***********************************************************/
    public AccountState add_account (AccountPtr &new_account);


    /***********************************************************
    remove all accounts
    ***********************************************************/
    public void shutdown ();


    /***********************************************************
    Return a list of all accounts.
    (this is a list of unowned for internal reasons, one should
    normally not keep a copy of them)
    ***********************************************************/
    public GLib.List<AccountStatePtr> accounts ();


    /***********************************************************
    Return the account state pointer for an account identified
    by its display name
    ***********************************************************/
    public AccountStatePtr account (string name);


    /***********************************************************
    Delete the AccountState
    ***********************************************************/
    public void delete_account (AccountState account);


    /***********************************************************
    Creates an account and sets up some basic handlers.
    Does not* add the account to the account manager just yet.
    ***********************************************************/
    public static AccountPtr create_account ();


    /***********************************************************
    Returns the list of settings keys that can't be read because
    they are from the future.
    ***********************************************************/
    public static void backward_migration_settings_keys (string[] *delete_keys, string[] *ignore_keys);


    // saving and loading Account to settings
    private void save_account_helper (Account account, QSettings &settings, bool save_credentials = true);
    private AccountPtr load_account_helper (QSettings &settings);

    private bool restore_from_legacy_settings ();

    private bool is_account_id_available (string id);
    private string generate_free_account_id ();

    // Adds an account to the tracked list, emitting on_account_added ()
    private void add_account_state (AccountState account_state);

    private AccountManager () = default;
    private GLib.List<AccountStatePtr> _accounts;
    /// Account ids from settings that weren't read
    private QSet<string> _additional_blocked_account_ids;


    /// Saves account data, not including the credentials
    public void on_save_account (Account a);

    /// Saves account state data, not including the account
    public void on_save_account_state (AccountState a);

    /// Display a Box with the mnemonic so the user can copy it to a safe place.
    public static void on_display_mnemonic (string& mnemonic);

signals:
    void on_account_added (AccountState account);
    void on_account_removed (AccountState account);
    void account_sync_connection_removed (AccountState account);
    void remove_account_folders (AccountState account);
};



    AccountManager *AccountManager.instance () {
        static AccountManager instance;
        return &instance;
    }

    bool AccountManager.restore () {
        string[] skip_settings_keys;
        backward_migration_settings_keys (&skip_settings_keys, &skip_settings_keys);

        var settings = ConfigFile.settings_with_group (QLatin1String (accounts_c));
        if (settings.status () != QSettings.NoError || !settings.is_writable ()) {
            q_c_warning (lc_account_manager) << "Could not read settings from" << settings.file_name ()
                                        << settings.status ();
            return false;
        }

        if (skip_settings_keys.contains (settings.group ())) {
            // Should not happen : bad container keys should have been deleted
            q_c_warning (lc_account_manager) << "Accounts structure is too new, ignoring";
            return true;
        }

        // If there are no accounts, check the old format.
        if (settings.child_groups ().is_empty ()
            && !settings.contains (QLatin1String (version_c))) {
            restore_from_legacy_settings ();
            return true;
        }

        for (var &account_id : settings.child_groups ()) {
            settings.begin_group (account_id);
            if (!skip_settings_keys.contains (settings.group ())) {
                if (var acc = load_account_helper (*settings)) {
                    acc._id = account_id;
                    if (var acc_state = AccountState.load_from_settings (acc, *settings)) {
                        var jar = qobject_cast<CookieJar> (acc._am.cookie_jar ());
                        ASSERT (jar);
                        if (jar)
                            jar.restore (acc.cookie_jar_path ());
                        add_account_state (acc_state);
                    }
                }
            } else {
                q_c_info (lc_account_manager) << "Account" << account_id << "is too new, ignoring";
                _additional_blocked_account_ids.insert (account_id);
            }
            settings.end_group ();
        }

        return true;
    }

    void AccountManager.backward_migration_settings_keys (string[] *delete_keys, string[] *ignore_keys) {
        var settings = ConfigFile.settings_with_group (QLatin1String (accounts_c));
        const int accounts_version = settings.value (QLatin1String (version_c)).to_int ();
        if (accounts_version <= max_accounts_version) {
            foreach (var &account_id, settings.child_groups ()) {
                settings.begin_group (account_id);
                const int account_version = settings.value (QLatin1String (version_c), 1).to_int ();
                if (account_version > max_account_version) {
                    ignore_keys.append (settings.group ());
                }
                settings.end_group ();
            }
        } else {
            delete_keys.append (settings.group ());
        }
    }

    bool AccountManager.restore_from_legacy_settings () {
        q_c_info (lc_account_manager) << "Migrate : restore_from_legacy_settings, checking settings group"
                                 << Theme.instance ().app_name ();

        // try to open the correctly themed settings
        var settings = ConfigFile.settings_with_group (Theme.instance ().app_name ());

        // if the settings file could not be opened, the child_keys list is empty
        // then try to load settings from a very old place
        if (settings.child_keys ().is_empty ()) {
            // Now try to open the original own_cloud settings to see if they exist.
            string o_c_cfg_file = QDir.from_native_separators (settings.file_name ());
            // replace the last two segments with own_cloud/owncloud.cfg
            o_c_cfg_file = o_c_cfg_file.left (o_c_cfg_file.last_index_of ('/'));
            o_c_cfg_file = o_c_cfg_file.left (o_c_cfg_file.last_index_of ('/'));
            o_c_cfg_file += QLatin1String ("/own_cloud/owncloud.cfg");

            q_c_info (lc_account_manager) << "Migrate : checking old config " << o_c_cfg_file;

            QFileInfo fi (o_c_cfg_file);
            if (fi.is_readable ()) {
                std.unique_ptr<QSettings> o_c_settings (new QSettings (o_c_cfg_file, QSettings.IniFormat));
                o_c_settings.begin_group (QLatin1String ("own_cloud"));

                // Check the theme url to see if it is the same url that the o_c config was for
                string override_url = Theme.instance ().override_server_url ();
                if (!override_url.is_empty ()) {
                    if (override_url.ends_with ('/')) {
                        override_url.chop (1);
                    }
                    string o_c_url = o_c_settings.value (QLatin1String (url_c)).to_string ();
                    if (o_c_url.ends_with ('/')) {
                        o_c_url.chop (1);
                    }

                    // in case the urls are equal reset the settings object to read from
                    // the own_cloud settings object
                    q_c_info (lc_account_manager) << "Migrate o_c config if " << o_c_url << " == " << override_url << ":"
                                             << (o_c_url == override_url ? "Yes" : "No");
                    if (o_c_url == override_url) {
                        settings = std.move (o_c_settings);
                    }
                }
            }
        }

        // Try to load the single account.
        if (!settings.child_keys ().is_empty ()) {
            if (var acc = load_account_helper (*settings)) {
                add_account (acc);
                return true;
            }
        }
        return false;
    }

    void AccountManager.save (bool save_credentials) {
        var settings = ConfigFile.settings_with_group (QLatin1String (accounts_c));
        settings.set_value (QLatin1String (version_c), max_accounts_version);
        for (var &acc : q_as_const (_accounts)) {
            settings.begin_group (acc.account ().id ());
            save_account_helper (acc.account ().data (), *settings, save_credentials);
            acc.write_to_settings (*settings);
            settings.end_group ();
        }

        settings.sync ();
        q_c_info (lc_account_manager) << "Saved all account settings, status:" << settings.status ();
    }

    void AccountManager.on_save_account (Account a) {
        q_c_debug (lc_account_manager) << "Saving account" << a.url ().to_string ();
        var settings = ConfigFile.settings_with_group (QLatin1String (accounts_c));
        settings.begin_group (a.id ());
        save_account_helper (a, *settings, false); // don't save credentials they might not have been loaded yet
        settings.end_group ();

        settings.sync ();
        q_c_debug (lc_account_manager) << "Saved account settings, status:" << settings.status ();
    }

    void AccountManager.on_save_account_state (AccountState a) {
        q_c_debug (lc_account_manager) << "Saving account state" << a.account ().url ().to_string ();
        var settings = ConfigFile.settings_with_group (QLatin1String (accounts_c));
        settings.begin_group (a.account ().id ());
        a.write_to_settings (*settings);
        settings.end_group ();

        settings.sync ();
        q_c_debug (lc_account_manager) << "Saved account state settings, status:" << settings.status ();
    }

    void AccountManager.save_account_helper (Account acc, QSettings &settings, bool save_credentials) {
        settings.set_value (QLatin1String (version_c), max_account_version);
        settings.set_value (QLatin1String (url_c), acc._url.to_string ());
        settings.set_value (QLatin1String (dav_user_c), acc._dav_user);
        settings.set_value (QLatin1String (server_version_c), acc._server_version);
        if (acc._credentials) {
            if (save_credentials) {
                // Only persist the credentials if the parameter is set, on migration from 1.8.x
                // we want to save the accounts but not overwrite the credentials
                // (This is easier than asynchronously fetching the credentials from keychain and then
                // re-persisting them)
                acc._credentials.persist ();
            }
            for (var &key : acc._settings_map.keys ()) {
                settings.set_value (key, acc._settings_map.value (key));
            }
            settings.set_value (QLatin1String (auth_type_c), acc._credentials.auth_type ());

            // HACK : Save http_user also as user
            if (acc._settings_map.contains (http_user_c))
                settings.set_value (user_c, acc._settings_map.value (http_user_c));
        }

        // Save accepted certificates.
        settings.begin_group (QLatin1String ("General"));
        q_c_info (lc_account_manager) << "Saving " << acc.approved_certs ().count () << " unknown certs.";
        GLib.ByteArray certs;
        for (var &cert : acc.approved_certs ()) {
            certs += cert.to_pem () + '\n';
        }
        if (!certs.is_empty ()) {
            settings.set_value (QLatin1String (ca_certs_key_c), certs);
        }
        settings.end_group ();

        // Save cookies.
        if (acc._am) {
            var jar = qobject_cast<CookieJar> (acc._am.cookie_jar ());
            if (jar) {
                q_c_info (lc_account_manager) << "Saving cookies." << acc.cookie_jar_path ();
                if (!jar.save (acc.cookie_jar_path ())) {
                    q_c_warning (lc_account_manager) << "Failed to save cookies to" << acc.cookie_jar_path ();
                }
            }
        }
    }

    AccountPtr AccountManager.load_account_helper (QSettings &settings) {
        var url_config = settings.value (QLatin1String (url_c));
        if (!url_config.is_valid ()) {
            // No URL probably means a corrupted entry in the account settings
            q_c_warning (lc_account_manager) << "No URL for account " << settings.group ();
            return AccountPtr ();
        }

        var acc = create_account ();

        string auth_type = settings.value (QLatin1String (auth_type_c)).to_string ();

        // There was an account-type saving bug when 'skip folder config' was used
        // See #5408. This attempts to fix up the "dummy" auth_type
        if (auth_type == QLatin1String ("dummy")) {
            if (settings.contains (QLatin1String ("http_user"))) {
                auth_type = "http";
            } else if (settings.contains (QLatin1String ("shibboleth_shib_user"))) {
                auth_type = "shibboleth";
            }
        }

        string override_url = Theme.instance ().override_server_url ();
        string force_auth = Theme.instance ().force_config_auth_type ();
        if (!force_auth.is_empty () && !override_url.is_empty ()) {
            // If force_auth is set, this might also mean the override_uRL has changed.
            // See enterprise issues #1126
            acc.set_url (override_url);
            auth_type = force_auth;
        } else {
            acc.set_url (url_config.to_url ());
        }

        // Migrate to webflow
        if (auth_type == QLatin1String ("http")) {
            auth_type = "webflow";
            settings.set_value (QLatin1String (auth_type_c), auth_type);

            for (string key : settings.child_keys ()) {
                if (!key.starts_with ("http_"))
                    continue;
                var newkey = string.from_latin1 ("webflow_").append (key.mid (5));
                settings.set_value (newkey, settings.value ( (key)));
                settings.remove (key);
            }
        }

        q_c_info (lc_account_manager) << "Account for" << acc.url () << "using auth type" << auth_type;

        acc._server_version = settings.value (QLatin1String (server_version_c)).to_string ();
        acc._dav_user = settings.value (QLatin1String (dav_user_c), "").to_string ();

        // We want to only restore settings for that auth type and the user value
        acc._settings_map.insert (QLatin1String (user_c), settings.value (user_c));
        string auth_type_prefix = auth_type + "_";
        for (var &key : settings.child_keys ()) {
            if (!key.starts_with (auth_type_prefix))
                continue;
            acc._settings_map.insert (key, settings.value (key));
        }

        acc.set_credentials (CredentialsFactory.create (auth_type));

        // now the server cert, it is in the general group
        settings.begin_group (QLatin1String ("General"));
        const var certs = QSslCertificate.from_data (settings.value (ca_certs_key_c).to_byte_array ());
        q_c_info (lc_account_manager) << "Restored : " << certs.count () << " unknown certs.";
        acc.set_approved_certs (certs);
        settings.end_group ();

        return acc;
    }

    AccountStatePtr AccountManager.account (string name) {
        const var it = std.find_if (_accounts.cbegin (), _accounts.cend (), [name] (var &acc) {
            return acc.account ().display_name () == name;
        });
        return it != _accounts.cend () ? *it : AccountStatePtr ();
    }

    AccountState *AccountManager.add_account (AccountPtr &new_account) {
        var id = new_account.id ();
        if (id.is_empty () || !is_account_id_available (id)) {
            id = generate_free_account_id ();
        }
        new_account._id = id;

        var new_account_state = new AccountState (new_account);
        add_account_state (new_account_state);
        return new_account_state;
    }

    void AccountManager.delete_account (AccountState account) {
        var it = std.find (_accounts.begin (), _accounts.end (), account);
        if (it == _accounts.end ()) {
            return;
        }
        var copy = *it; // keep a reference to the shared pointer so it does not delete it just yet
        _accounts.erase (it);

        // Forget account credentials, cookies
        account.account ().credentials ().forget_sensitive_data ();
        QFile.remove (account.account ().cookie_jar_path ());

        var settings = ConfigFile.settings_with_group (QLatin1String (accounts_c));
        settings.remove (account.account ().id ());

        // Forget E2E keys
        account.account ().e2e ().forget_sensitive_data (account.account ());

        account.account ().delete_app_token ();

        emit account_sync_connection_removed (account);
        emit account_removed (account);
    }

    AccountPtr AccountManager.create_account () {
        AccountPtr acc = Account.create ();
        acc.set_ssl_error_handler (new SslDialogErrorHandler);
        connect (acc.data (), &Account.proxy_authentication_required,
            ProxyAuthHandler.instance (), &ProxyAuthHandler.on_handle_proxy_authentication_required);

        return acc;
    }

    void AccountManager.on_display_mnemonic (string& mnemonic) {
        var widget = new Gtk.Dialog;
        Ui_Dialog ui;
        ui.setup_ui (widget);
        widget.set_window_title (tr ("End to end encryption mnemonic"));
        ui.label.on_set_text (tr ("To protect your Cryptographic Identity, we encrypt it with a mnemonic of 12 dictionary words. "
                             "Please note these down and keep them safe. "
                             "They will be needed to add other devices to your account (like your mobile phone or laptop)."));
        ui.text_edit.on_set_text (mnemonic);
        ui.text_edit.focus_widget ();
        ui.text_edit.select_all ();
        ui.text_edit.set_alignment (Qt.AlignCenter);
        widget.exec ();
        widget.resize (widget.size_hint ());
    }

    void AccountManager.shutdown () {
        const var accounts_copy = _accounts;
        _accounts.clear ();
        for (var &acc : accounts_copy) {
            emit account_removed (acc.data ());
            emit remove_account_folders (acc.data ());
        }
    }

    GLib.List<AccountStatePtr> AccountManager.accounts () {
         return _accounts;
    }

    bool AccountManager.is_account_id_available (string id) {
        if (_additional_blocked_account_ids.contains (id))
            return false;

        return std.none_of (_accounts.cbegin (), _accounts.cend (), [id] (var &acc) {
            return acc.account ().id () == id;
        });
    }

    string AccountManager.generate_free_account_id () {
        int i = 0;
        forever {
            string id = string.number (i);
            if (is_account_id_available (id)) {
                return id;
            }
            ++i;
        }
    }

    void AccountManager.add_account_state (AccountState account_state) {
        GLib.Object.connect (account_state.account ().data (),
            &Account.wants_account_saved,
            this, &AccountManager.on_save_account);

        AccountStatePtr ptr (account_state);
        _accounts << ptr;
        emit account_added (account_state);
    }
    }
    