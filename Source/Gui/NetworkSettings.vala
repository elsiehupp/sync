/***********************************************************
Copyright (C) by Daniel Molkentin <danimo@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QNetworkProxy>
// #include <string>
// #include <GLib.List>

// #include <Gtk.Widget>

namespace Occ {

namespace Ui {
    class Network_settings;
}

/***********************************************************
@brief The Network_settings class
@ingroup gui
***********************************************************/
class Network_settings : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    public Network_settings (Gtk.Widget parent = nullptr);
    ~Network_settings () override;
    public QSize size_hint () override;


    /***********************************************************
    ***********************************************************/
    private void on_save_proxy_settings ();
    private void on_save_bw_limit_settings ();

    /// Red marking of host field if empty and enabled
    private void on_check_empty_proxy_host ();

    /***********************************************************
    ***********************************************************/
    private void on_check_account_localhost ();


    protected void show_event (QShow_event event) override;


    /***********************************************************
    ***********************************************************/
    private void load_proxy_settings ();

    /***********************************************************
    ***********************************************************/
    private 
    private Ui.Network_settings _ui;
};

    Network_settings.Network_settings (Gtk.Widget parent)
        : Gtk.Widget (parent)
        , _ui (new Ui.Network_settings) {
        _ui.setup_ui (this);

        _ui.host_line_edit.set_placeholder_text (_("Hostname of proxy server"));
        _ui.user_line_edit.set_placeholder_text (_("Username for proxy server"));
        _ui.password_line_edit.set_placeholder_text (_("Password for proxy server"));

        _ui.type_combo_box.add_item (_("HTTP (S) proxy"), QNetworkProxy.HttpProxy);
        _ui.type_combo_box.add_item (_("SOCKS5 proxy"), QNetworkProxy.Socks5Proxy);

        _ui.auth_requiredcheck_box.set_enabled (true);

        // Explicitly set up the enabled status of the proxy auth widgets to ensure
        // toggling the parent enables/disables the children
        _ui.user_line_edit.set_enabled (true);
        _ui.password_line_edit.set_enabled (true);
        _ui.auth_widgets.set_enabled (_ui.auth_requiredcheck_box.is_checked ());
        connect (_ui.auth_requiredcheck_box, &QAbstractButton.toggled,
            _ui.auth_widgets, &Gtk.Widget.set_enabled);

        connect (_ui.manual_proxy_radio_button, &QAbstractButton.toggled,
            _ui.manual_settings, &Gtk.Widget.set_enabled);
        connect (_ui.manual_proxy_radio_button, &QAbstractButton.toggled,
            _ui.type_combo_box, &Gtk.Widget.set_enabled);
        connect (_ui.manual_proxy_radio_button, &QAbstractButton.toggled,
            this, &Network_settings.on_check_account_localhost);

        load_proxy_settings ();
        load_bWLimit_settings ();

        // proxy
        connect (_ui.type_combo_box, static_cast<void (QCombo_box.*) (int)> (&QCombo_box.current_index_changed), this, &Network_settings.on_save_proxy_settings);
        connect (_ui.proxy_button_group, static_cast<void (QButton_group.*) (int)> (&QButton_group.button_clicked), this, &Network_settings.on_save_proxy_settings);
        connect (_ui.host_line_edit, &QLineEdit.editing_finished, this, &Network_settings.on_save_proxy_settings);
        connect (_ui.user_line_edit, &QLineEdit.editing_finished, this, &Network_settings.on_save_proxy_settings);
        connect (_ui.password_line_edit, &QLineEdit.editing_finished, this, &Network_settings.on_save_proxy_settings);
        connect (_ui.port_spin_box, &QAbstract_spin_box.editing_finished, this, &Network_settings.on_save_proxy_settings);
        connect (_ui.auth_requiredcheck_box, &QAbstractButton.toggled, this, &Network_settings.on_save_proxy_settings);

        connect (_ui.upload_limit_radio_button, &QAbstractButton.clicked, this, &Network_settings.on_save_bw_limit_settings);
        connect (_ui.no_upload_limit_radio_button, &QAbstractButton.clicked, this, &Network_settings.on_save_bw_limit_settings);
        connect (_ui.auto_upload_limit_radio_button, &QAbstractButton.clicked, this, &Network_settings.on_save_bw_limit_settings);
        connect (_ui.download_limit_radio_button, &QAbstractButton.clicked, this, &Network_settings.on_save_bw_limit_settings);
        connect (_ui.no_download_limit_radio_button, &QAbstractButton.clicked, this, &Network_settings.on_save_bw_limit_settings);
        connect (_ui.auto_download_limit_radio_button, &QAbstractButton.clicked, this, &Network_settings.on_save_bw_limit_settings);
        connect (_ui.download_spin_box, static_cast<void (QSpin_box.*) (int)> (&QSpin_box.value_changed), this, &Network_settings.on_save_bw_limit_settings);
        connect (_ui.upload_spin_box, static_cast<void (QSpin_box.*) (int)> (&QSpin_box.value_changed), this, &Network_settings.on_save_bw_limit_settings);

        // Warn about empty proxy host
        connect (_ui.host_line_edit, &QLineEdit.text_changed, this, &Network_settings.on_check_empty_proxy_host);
        on_check_empty_proxy_host ();
        on_check_account_localhost ();
    }

    Network_settings.~Network_settings () {
        delete _ui;
    }

    QSize Network_settings.size_hint () {
        return {
            OwncloudGui.settings_dialog_size ().width (),
            Gtk.Widget.size_hint ().height ()
        };
    }

    void Network_settings.load_proxy_settings () {
        if (Theme.instance ().force_system_network_proxy ()) {
            _ui.system_proxy_radio_button.set_checked (true);
            _ui.proxy_group_box.set_enabled (false);
            return;
        }
        // load current proxy settings
        Occ.ConfigFile cfg_file;
        int type = cfg_file.proxy_type ();
        switch (type) {
        case QNetworkProxy.NoProxy:
            _ui.no_proxy_radio_button.set_checked (true);
            break;
        case QNetworkProxy.DefaultProxy:
            _ui.system_proxy_radio_button.set_checked (true);
            break;
        case QNetworkProxy.Socks5Proxy:
        case QNetworkProxy.HttpProxy:
            _ui.type_combo_box.set_current_index (_ui.type_combo_box.find_data (type));
            _ui.manual_proxy_radio_button.set_checked (true);
            break;
        default:
            break;
        }

        _ui.host_line_edit.on_set_text (cfg_file.proxy_host_name ());
        int port = cfg_file.proxy_port ();
        if (port == 0)
            port = 8080;
        _ui.port_spin_box.set_value (port);
        _ui.auth_requiredcheck_box.set_checked (cfg_file.proxy_needs_auth ());
        _ui.user_line_edit.on_set_text (cfg_file.proxy_user ());
        _ui.password_line_edit.on_set_text (cfg_file.proxy_password ());
    }

    void Network_settings.load_bWLimit_settings () {
        ConfigFile cfg_file;

        int use_download_limit = cfg_file.use_download_limit ();
        if (use_download_limit >= 1) {
            _ui.download_limit_radio_button.set_checked (true);
        } else if (use_download_limit == 0) {
            _ui.no_download_limit_radio_button.set_checked (true);
        } else {
            _ui.auto_download_limit_radio_button.set_checked (true);
        }
        _ui.download_spin_box.set_value (cfg_file.download_limit ());

        int use_upload_limit = cfg_file.use_upload_limit ();
        if (use_upload_limit >= 1) {
            _ui.upload_limit_radio_button.set_checked (true);
        } else if (use_upload_limit == 0) {
            _ui.no_upload_limit_radio_button.set_checked (true);
        } else {
            _ui.auto_upload_limit_radio_button.set_checked (true);
        }
        _ui.upload_spin_box.set_value (cfg_file.upload_limit ());
    }

    void Network_settings.on_save_proxy_settings () {
        ConfigFile cfg_file;

        on_check_empty_proxy_host ();
        if (_ui.no_proxy_radio_button.is_checked ()) {
            cfg_file.set_proxy_type (QNetworkProxy.NoProxy);
        } else if (_ui.system_proxy_radio_button.is_checked ()) {
            cfg_file.set_proxy_type (QNetworkProxy.DefaultProxy);
        } else if (_ui.manual_proxy_radio_button.is_checked ()) {
            int type = _ui.type_combo_box.item_data (_ui.type_combo_box.current_index ()).to_int ();
            string host = _ui.host_line_edit.text ();
            if (host.is_empty ())
                type = QNetworkProxy.NoProxy;
            bool needs_auth = _ui.auth_requiredcheck_box.is_checked ();
            string user = _ui.user_line_edit.text ();
            string pass = _ui.password_line_edit.text ();
            cfg_file.set_proxy_type (type, _ui.host_line_edit.text (),
                _ui.port_spin_box.value (), needs_auth, user, pass);
        }

        ClientProxy proxy;
        proxy.on_setup_qt_proxy_from_config (); // Refresh the Qt proxy settings as the
        // quota check can happen all the time.

        // ...and set the folders dirty, they refresh their proxy next time they
        // on_start the sync.
        FolderMan.instance ().set_dirty_proxy ();

        const var accounts = AccountManager.instance ().accounts ();
        for (var account : accounts) {
            account.fresh_connection_attempt ();
        }
    }

    void Network_settings.on_save_bw_limit_settings () {
        ConfigFile cfg_file;
        if (_ui.download_limit_radio_button.is_checked ()) {
            cfg_file.set_use_download_limit (1);
        } else if (_ui.no_download_limit_radio_button.is_checked ()) {
            cfg_file.set_use_download_limit (0);
        } else if (_ui.auto_download_limit_radio_button.is_checked ()) {
            cfg_file.set_use_download_limit (-1);
        }
        cfg_file.set_download_limit (_ui.download_spin_box.value ());

        if (_ui.upload_limit_radio_button.is_checked ()) {
            cfg_file.set_use_upload_limit (1);
        } else if (_ui.no_upload_limit_radio_button.is_checked ()) {
            cfg_file.set_use_upload_limit (0);
        } else if (_ui.auto_upload_limit_radio_button.is_checked ()) {
            cfg_file.set_use_upload_limit (-1);
        }
        cfg_file.set_upload_limit (_ui.upload_spin_box.value ());

        FolderMan.instance ().set_dirty_network_limits ();
    }

    void Network_settings.on_check_empty_proxy_host () {
        if (_ui.host_line_edit.is_enabled () && _ui.host_line_edit.text ().is_empty ()) {
            _ui.host_line_edit.set_style_sheet ("border : 1px solid red");
        } else {
            _ui.host_line_edit.set_style_sheet ("");
        }
    }

    void Network_settings.show_event (QShow_event event) {
        if (!event.spontaneous ()
            && _ui.manual_proxy_radio_button.is_checked ()
            && _ui.host_line_edit.text ().is_empty ()) {
            _ui.no_proxy_radio_button.set_checked (true);
            on_check_empty_proxy_host ();
            on_save_proxy_settings ();
        }
        on_check_account_localhost ();

        Gtk.Widget.show_event (event);
    }

    void Network_settings.on_check_account_localhost () {
        bool visible = false;
        if (_ui.manual_proxy_radio_button.is_checked ()) {
            // Check if at least one account is using localhost, because Qt proxy settings have no
            // effect for localhost (#7169)
            for (var &account : AccountManager.instance ().accounts ()) {
                const var host = account.account ().url ().host ();
                // Some typical url for localhost
                if (host == "localhost" || host.starts_with ("127.") || host == "[.1]")
                    visible = true;
            }
        }
        _ui.label_localhost.set_visible (visible);
    }

    } // namespace Occ
    