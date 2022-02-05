/***********************************************************
Copyright (C) by Olivier Goffart <ogoffart@woboq.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <theme.h>
//  #include <creds/credentialsfactory.h>
//  #include <creds/abstractcredentials.h>
//  #include <cookiejar.h>
//  #include <QSettings>
//  #include <QDir>
//  #include <QNetworkAccessManager>
//  #include <QMessageBox>

//  #pragma once

namespace Occ {

/***********************************************************
@brief The AccountManager class
@ingroup gui
***********************************************************/
class AccountManager : GLib.Object {

    const string URL_C = "url";
    const string AUTH_TYPE_C = "auth_type";
    const string USER_C = "user";
    const string HTTP_USER_C = "http_user";
    const string DAV_USER_C = "dav_user";
    const string CA_CERTS_KEY_C = "CaCertificates";
    const string ACCOUNTS_C = "Accounts";
    const string VERSION_C = "version";
    const string SERVER_VERSION_C = "server_version";

    /***********************************************************
    ***********************************************************/
    // The maximum versions that this client can read
    const int MAX_ACCOUNTS_VERSION = 2;
    const int MAX_ACCOUNT_VERSION = 1;


    /***********************************************************
    ***********************************************************/
    private static AccountManager instance;

    /***********************************************************
    ***********************************************************/
    private GLib.List<AccountStatePtr> accounts;

    /***********************************************************
    Account ids from settings that weren't read
    ***********************************************************/
    private GLib.Set<string> additional_blocked_account_ids;


    signal void on_account_added (AccountState account);
    signal void on_account_removed (AccountState account);
    signal void account_sync_connection_removed (AccountState account);
    signal void remove_account_folders (AccountState account);


    /***********************************************************
    ***********************************************************/
    private AccountManager () = default;

    ~AccountManager () = default;

    /***********************************************************
    ***********************************************************/
    public static AccountManager instance () {
        return instance;
    }


    /***********************************************************
    Saves the accounts to a given settings file
    ***********************************************************/
    public void save (bool save_credentials = true) {
        var settings = ConfigFile.settings_with_group (QLatin1String (ACCOUNTS_C));
        settings.set_value (QLatin1String (VERSION_C), MAX_ACCOUNTS_VERSION);
        for (var acc : q_as_const (this.accounts)) {
            settings.begin_group (acc.account ().identifier ());
            save_account_helper (acc.account ().data (), *settings, save_credentials);
            acc.write_to_settings (*settings);
            settings.end_group ();
        }

        settings.sync ();
        GLib.info (lc_account_manager) << "Saved all account settings, status:" << settings.status ();
    }


    /***********************************************************
    Creates account objects from a given settings file.

    Returns false if there was an error reading the settings,
    but note that settings not existing is not an error.
    ***********************************************************/
    public bool restore () {
        string[] skip_settings_keys;
        backward_migration_settings_keys (&skip_settings_keys, skip_settings_keys);

        var settings = ConfigFile.settings_with_group (QLatin1String (ACCOUNTS_C));
        if (settings.status () != QSettings.NoError || !settings.is_writable ()) {
            GLib.warn (lc_account_manager) << "Could not read settings from" << settings.filename ()
                                        << settings.status ();
            return false;
        }

        if (skip_settings_keys.contains (settings.group ())) {
            // Should not happen : bad container keys should have been deleted
            GLib.warn (lc_account_manager) << "Accounts structure is too new, ignoring";
            return true;
        }

        // If there are no accounts, check the old format.
        if (settings.child_groups ().is_empty ()
            && !settings.contains (QLatin1String (VERSION_C))) {
            restore_from_legacy_settings ();
            return true;
        }

        foreach (var account_id in settings.child_groups ()) {
            settings.begin_group (account_id);
            if (!skip_settings_keys.contains (settings.group ())) {
                if (var acc = load_account_helper (*settings)) {
                    acc.id = account_id;
                    if (var acc_state = AccountState.load_from_settings (acc, *settings)) {
                        var jar = qobject_cast<CookieJar> (acc.am.cookie_jar ());
                        //  ASSERT (jar);
                        if (jar)
                            jar.restore (acc.cookie_jar_path ());
                        add_account_state (acc_state);
                    }
                }
            } else {
                GLib.info (lc_account_manager) << "Account" << account_id << "is too new, ignoring";
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
    public AccountState add_account (AccountPointer new_account) {
        var identifier = new_account.identifier ();
        if (identifier.is_empty () || !is_account_id_available (identifier)) {
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
    public AccountStatePtr account (string name) {
        const var it = std.find_if (this.accounts.cbegin (), this.accounts.cend (), [name] (var acc) {
            return acc.account ().display_name () == name;
        });
        return it != this.accounts.cend () ? *it : AccountStatePtr ();
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
        account.account ().credentials ().forget_sensitive_data ();
        GLib.File.remove (account.account ().cookie_jar_path ());

        var settings = ConfigFile.settings_with_group (QLatin1String (ACCOUNTS_C));
        settings.remove (account.account ().identifier ());

        // Forget E2E keys
        account.account ().e2e ().forget_sensitive_data (account.account ());

        account.account ().delete_app_token ();

        /* emit */ account_sync_connection_removed (account);
        /* emit */ account_removed (account);
    }


    /***********************************************************
    Creates an account and sets up some basic handlers.
    Does not* add the account to the account manager just yet.
    ***********************************************************/
    public static AccountPointer create_account () {
        AccountPointer acc = Account.create ();
        acc.set_ssl_error_handler (new SslDialogErrorHandler);
        connect (acc.data (), &Account.proxy_authentication_required,
            ProxyAuthHandler.instance (), &ProxyAuthHandler.on_handle_proxy_authentication_required);

        return acc;
    }


    /***********************************************************
    Returns the list of settings keys that can't be read because
    they are from the future.
    ***********************************************************/
    public static void backward_migration_settings_keys (string[] delete_keys, string[] ignore_keys) {
        var settings = ConfigFile.settings_with_group (QLatin1String (ACCOUNTS_C));
        const int accounts_version = settings.value (QLatin1String (VERSION_C)).to_int ();
        if (accounts_version <= MAX_ACCOUNTS_VERSION) {
            foreach (var account_id in settings.child_groups ()) {
                settings.begin_group (account_id);
                const int account_version = settings.value (QLatin1String (VERSION_C), 1).to_int ();
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
    private void save_account_helper (Account account, QSettings settings, bool save_credentials = true) {
        settings.set_value (QLatin1String (VERSION_C), MAX_ACCOUNT_VERSION);
        settings.set_value (QLatin1String (URL_C), acc.url.to_string ());
        settings.set_value (QLatin1String (DAV_USER_C), acc.dav_user);
        settings.set_value (QLatin1String (SERVER_VERSION_C), acc.server_version);
        if (acc.credentials) {
            if (save_credentials) {
                // Only persist the credentials if the parameter is set, on migration from 1.8.x
                // we want to save the accounts but not overwrite the credentials
                // (This is easier than asynchronously fetching the credentials from keychain and then
                // re-persisting them)
                acc.credentials.persist ();
            }
            for (var key : acc.settings_map.keys ()) {
                settings.set_value (key, acc.settings_map.value (key));
            }
            settings.set_value (QLatin1String (AUTH_TYPE_C), acc.credentials.auth_type ());

            // HACK : Save http_user also as user
            if (acc.settings_map.contains (HTTP_USER_C))
                settings.set_value (USER_C, acc.settings_map.value (HTTP_USER_C));
        }

        // Save accepted certificates.
        settings.begin_group (QLatin1String ("General"));
        GLib.info (lc_account_manager) << "Saving " << acc.approved_certificates ().count () << " unknown certificates.";
        GLib.ByteArray certificates;
        foreach (var cert in acc.approved_certificates ()) {
            certificates += cert.to_pem () + '\n';
        }
        if (!certificates.is_empty ()) {
            settings.set_value (QLatin1String (CA_CERTS_KEY_C), certificates);
        }
        settings.end_group ();

        // Save cookies.
        if (acc.am) {
            var jar = qobject_cast<CookieJar> (acc.am.cookie_jar ());
            if (jar) {
                GLib.info (lc_account_manager) << "Saving cookies." << acc.cookie_jar_path ();
                if (!jar.save (acc.cookie_jar_path ())) {
                    GLib.warn (lc_account_manager) << "Failed to save cookies to" << acc.cookie_jar_path ();
                }
            }
        }
    }


    /***********************************************************
    ***********************************************************/
    private AccountPointer load_account_helper (QSettings settings) {
        var url_config = settings.value (QLatin1String (URL_C));
        if (!url_config.is_valid ()) {
            // No URL probably means a corrupted entry in the account settings
            GLib.warn (lc_account_manager) << "No URL for account " << settings.group ();
            return AccountPointer ();
        }

        var acc = create_account ();

        string auth_type = settings.value (QLatin1String (AUTH_TYPE_C)).to_string ();

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
            settings.set_value (QLatin1String (AUTH_TYPE_C), auth_type);

            foreach (string key in settings.child_keys ()) {
                if (!key.starts_with ("http_"))
                    continue;
                var newkey = string.from_latin1 ("webflow_").append (key.mid (5));
                settings.set_value (newkey, settings.value ( (key)));
                settings.remove (key);
            }
        }

        GLib.info (lc_account_manager) << "Account for" << acc.url () << "using auth type" << auth_type;

        acc.server_version = settings.value (QLatin1String (SERVER_VERSION_C)).to_string ();
        acc.dav_user = settings.value (QLatin1String (DAV_USER_C), "").to_string ();

        // We want to only restore settings for that auth type and the user value
        acc.settings_map.insert (QLatin1String (USER_C), settings.value (USER_C));
        string auth_type_prefix = auth_type + "this.";
        foreach (var key in settings.child_keys ()) {
            if (!key.starts_with (auth_type_prefix))
                continue;
            acc.settings_map.insert (key, settings.value (key));
        }

        acc.set_credentials (CredentialsFactory.create (auth_type));

        // now the server cert, it is in the general group
        settings.begin_group (QLatin1String ("General"));
        const var certificates = QSslCertificate.from_data (settings.value (CA_CERTS_KEY_C).to_byte_array ());
        GLib.info (lc_account_manager) << "Restored : " << certificates.count () << " unknown certificates.";
        acc.set_approved_certificates (certificates);
        settings.end_group ();

        return acc;
    }


    /***********************************************************
    ***********************************************************/
    private bool restore_from_legacy_settings () {
        GLib.info (lc_account_manager) << "Migrate : restore_from_legacy_settings, checking settings group"
                                 << Theme.instance ().app_name ();

        // try to open the correctly themed settings
        var settings = ConfigFile.settings_with_group (Theme.instance ().app_name ());

        // if the settings file could not be opened, the child_keys list is empty
        // then try to load settings from a very old place
        if (settings.child_keys ().is_empty ()) {
            // Now try to open the original own_cloud settings to see if they exist.
            string o_c_cfg_file = QDir.from_native_separators (settings.filename ());
            // replace the last two segments with own_cloud/owncloud.config
            o_c_cfg_file = o_c_cfg_file.left (o_c_cfg_file.last_index_of ('/'));
            o_c_cfg_file = o_c_cfg_file.left (o_c_cfg_file.last_index_of ('/'));
            o_c_cfg_file += QLatin1String ("/own_cloud/owncloud.config");

            GLib.info (lc_account_manager) << "Migrate : checking old config " << o_c_cfg_file;

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
                    string o_c_url = o_c_settings.value (QLatin1String (URL_C)).to_string ();
                    if (o_c_url.ends_with ('/')) {
                        o_c_url.chop (1);
                    }

                    // in case the urls are equal reset the settings object to read from
                    // the own_cloud settings object
                    GLib.info (lc_account_manager) << "Migrate o_c config if " << o_c_url << " == " << override_url << ":"
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


    /***********************************************************
    ***********************************************************/
    private bool is_account_id_available (string identifier);

    /***********************************************************
    ***********************************************************/
    private string generate_free_account_id ();


    /***********************************************************
    Adds an account to the tracked list, emitting on_account_added ()
    ***********************************************************/
    private void add_account_state (AccountState account_state);


    /***********************************************************
    Saves account data, not including the credentials
    ***********************************************************/
    public void on_save_account (Account a) {
        GLib.debug (lc_account_manager) << "Saving account" << a.url ().to_string ();
        var settings = ConfigFile.settings_with_group (QLatin1String (ACCOUNTS_C));
        settings.begin_group (a.identifier ());
        save_account_helper (a, *settings, false); // don't save credentials they might not have been loaded yet
        settings.end_group ();

        settings.sync ();
        GLib.debug (lc_account_manager) << "Saved account settings, status:" << settings.status ();
    }


    /***********************************************************
    Saves account state data, not including the account
    ***********************************************************/
    public void on_save_account_state (AccountState a) {
        GLib.debug (lc_account_manager) << "Saving account state" << a.account ().url ().to_string ();
        var settings = ConfigFile.settings_with_group (QLatin1String (ACCOUNTS_C));
        settings.begin_group (a.account ().identifier ());
        a.write_to_settings (*settings);
        settings.end_group ();

        settings.sync ();
        GLib.debug (lc_account_manager) << "Saved account state settings, status:" << settings.status ();
    }

    /***********************************************************
    Display a Box with the mnemonic so the user can copy it to a
    safe place.
    ***********************************************************/
    public static void on_display_mnemonic (string mnemonic);


}
















    void AccountManager.on_display_mnemonic (string mnemonic) {
        var widget = new Gtk.Dialog;
        Ui_Dialog ui;
        ui.set_up_ui (widget);
        widget.set_window_title (_("End to end encryption mnemonic"));
        ui.label.on_set_text (_("To protect your Cryptographic Identity, we encrypt it with a mnemonic of 12 dictionary words. "
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
        const var accounts_copy = this.accounts;
        this.accounts.clear ();
        for (var acc : accounts_copy) {
            /* emit */ account_removed (acc.data ());
            /* emit */ remove_account_folders (acc.data ());
        }
    }

    GLib.List<AccountStatePtr> AccountManager.accounts () {
         return this.accounts;
    }

    bool AccountManager.is_account_id_available (string identifier) {
        if (this.additional_blocked_account_ids.contains (identifier))
            return false;

        return std.none_of (this.accounts.cbegin (), this.accounts.cend (), [identifier] (var acc) {
            return acc.account ().identifier () == identifier;
        });
    }

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

    void AccountManager.add_account_state (AccountState account_state) {
        GLib.Object.connect (account_state.account ().data (),
            &Account.wants_account_saved,
            this, &AccountManager.on_save_account);

        AccountStatePtr ptr (account_state);
        this.accounts << ptr;
        /* emit */ account_added (account_state);
    }
    }
    