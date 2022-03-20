/***********************************************************
@author Daniel Molkentin <danimo@owncloud.com>
@copyright GPLv3 or Later
***********************************************************/

//  #include <QNetworkProxy>
//  #include <Gtk.Widget>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The NetworkSettings class
@ingroup gui
***********************************************************/
public class NetworkSettings : Gtk.Widget {

    /***********************************************************
    ***********************************************************/
    private Ui.NetworkSettings ui;

    /***********************************************************
    ***********************************************************/
    public NetworkSettings (Gtk.Widget parent = new Gtk.Widget ()) {
        base (parent);
        this.ui = new Ui.NetworkSettings ();
        this.ui.up_ui (this);

        this.ui.host_line_edit.placeholder_text (_("Hostname of proxy server"));
        this.ui.user_line_edit.placeholder_text (_("Username for proxy server"));
        this.ui.password_line_edit.placeholder_text (_("Password for proxy server"));

        this.ui.type_combo_box.add_item (_("HTTP (S) proxy"), QNetworkProxy.HttpProxy);
        this.ui.type_combo_box.add_item (_("SOCKS5 proxy"), QNetworkProxy.Socks5Proxy);

        this.ui.auth_requiredcheck_box.enabled (true);

        // Explicitly set up the enabled status of the proxy auth widgets to ensure
        // toggling the parent enables/disables the children
        this.ui.user_line_edit.enabled (true);
        this.ui.password_line_edit.enabled (true);
        this.ui.auth_widgets.enabled (this.ui.auth_requiredcheck_box.is_checked ());
        this.ui.auth_requiredcheck_box.toggled.connect (
            this.ui.auth_widgets.enabled
        );
        this.ui.manual_proxy_radio_button.toggled.connect (
            this.ui.manual_settings.enabled
        );
        this.ui.manual_proxy_radio_button.toggled.connect (
            this.ui.type_combo_box.enabled
        );
        this.ui.manual_proxy_radio_button.toggled.connect (
            this.on_signal_check_account_localhost
        );

        load_proxy_settings ();
        load_bandwidth_limit_settings ();

        // proxy
        this.ui.type_combo_box.current_index_changed.connect (
            this.on_signal_save_proxy_settings
        );
        this.ui.proxy_button_group.button_clicked.connect (
            this.on_signal_save_proxy_settings
        );
        this.ui.host_line_edit.editing_finished.connect (
            this.on_signal_save_proxy_settings
        );
        this.ui.user_line_edit.editing_finished.connect (
            this.on_signal_save_proxy_settings
        );
        this.ui.password_line_edit.editing_finished.connect (
            this.on_signal_save_proxy_settings
        );
        this.ui.port_spin_box.editing_finished.connect (
            this.on_signal_save_proxy_settings
        );
        this.ui.auth_requiredcheck_box.toggled.connect (
            this.on_signal_save_proxy_settings
        );

        // Limits
        this.ui.upload_limit_radio_button.clicked.connect (
            this.on_signal_save_bandwidth_limit_settings
        );
        this.ui.no_upload_limit_radio_button.clicked.connect (
            this.on_signal_save_bandwidth_limit_settings
        );
        this.ui.auto_upload_limit_radio_button.clicked.connect (
            this.on_signal_save_bandwidth_limit_settings
        );
        this.ui.download_limit_radio_button.clicked.connect (
            this.on_signal_save_bandwidth_limit_settings
        );
        this.ui.no_download_limit_radio_button.clicked.connect (
            this.on_signal_save_bandwidth_limit_settings
        );
        this.ui.auto_download_limit_radio_button.clicked.connect (
            this.on_signal_save_bandwidth_limit_settings
        );
        this.ui.download_spin_box.value_changed.connect (
            this.on_signal_save_bandwidth_limit_settings
        );
        this.ui.upload_spin_box.value_changed.connect (
            this.on_signal_save_bandwidth_limit_settings
        );

        // Warn about empty proxy host
        this.ui.host_line_edit.text_changed.connect (
            this.on_signal_check_empty_proxy_host
        );
        on_signal_check_empty_proxy_host ();
        on_signal_check_account_localhost ();
    }


    private delegate void CurrentIndexChanged (QComboBox box, int index);
    private delegate void ProxyButtonGroupClicked (QButtonGroup group, int index);
    private delegate void DownloadSpinBoxValueChanged (QSpinBox spin_box, int value);
    private delegate void UploadSpinBoxValueChanged (QSpinBox spin_box, int value);


    override ~NetworkSettings () {
        delete this.ui;
    }


    /***********************************************************
    ***********************************************************/
    public override QSize size_hint () {
        return new QSize (
            OwncloudGui.settings_dialog_size ().width (),
            Gtk.Widget.size_hint ().height ()
        );
    }


    /***********************************************************
    ***********************************************************/
    private void load_bandwidth_limit_settings () {
        ConfigFile config_file;

        int use_download_limit = config_file.use_download_limit ();
        if (use_download_limit >= 1) {
            this.ui.download_limit_radio_button.checked (true);
        } else if (use_download_limit == 0) {
            this.ui.no_download_limit_radio_button.checked (true);
        } else {
            this.ui.auto_download_limit_radio_button.checked (true);
        }
        this.ui.download_spin_box.value (config_file.download_limit ());

        int use_upload_limit = config_file.use_upload_limit ();
        if (use_upload_limit >= 1) {
            this.ui.upload_limit_radio_button.checked (true);
        } else if (use_upload_limit == 0) {
            this.ui.no_upload_limit_radio_button.checked (true);
        } else {
            this.ui.auto_upload_limit_radio_button.checked (true);
        }
        this.ui.upload_spin_box.value (config_file.upload_limit ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_save_proxy_settings () {
        ConfigFile config_file;

        on_signal_check_empty_proxy_host ();
        if (this.ui.no_proxy_radio_button.is_checked ()) {
            config_file.proxy_type (QNetworkProxy.NoProxy);
        } else if (this.ui.system_proxy_radio_button.is_checked ()) {
            config_file.proxy_type (QNetworkProxy.DefaultProxy);
        } else if (this.ui.manual_proxy_radio_button.is_checked ()) {
            int type = this.ui.type_combo_box.item_data (this.ui.type_combo_box.current_index ()).to_int ();
            string host = this.ui.host_line_edit.text ();
            if (host == "")
                type = QNetworkProxy.NoProxy;
            bool needs_auth = this.ui.auth_requiredcheck_box.is_checked ();
            string user = this.ui.user_line_edit.text ();
            string pass = this.ui.password_line_edit.text ();
            config_file.proxy_type (type, this.ui.host_line_edit.text (),
                this.ui.port_spin_box.value (), needs_auth, user, pass);
        }

        ClientProxy proxy;
        proxy.on_signal_setup_qt_proxy_from_config (); // Refresh the Qt proxy settings as the
        // quota check can happen all the time.

        // ...and set the folders dirty, they refresh their proxy next time they
        // on_signal_start the sync.
        FolderMan.instance.dirty_proxy ();

        const var accounts = AccountManager.instance.accounts;
        foreach (var account in accounts) {
            account.fresh_connection_attempt ();
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_save_bandwidth_limit_settings () {
        ConfigFile config_file;
        if (this.ui.download_limit_radio_button.is_checked ()) {
            config_file.use_download_limit (1);
        } else if (this.ui.no_download_limit_radio_button.is_checked ()) {
            config_file.use_download_limit (0);
        } else if (this.ui.auto_download_limit_radio_button.is_checked ()) {
            config_file.use_download_limit (-1);
        }
        config_file.download_limit (this.ui.download_spin_box.value ());

        if (this.ui.upload_limit_radio_button.is_checked ()) {
            config_file.use_upload_limit (1);
        } else if (this.ui.no_upload_limit_radio_button.is_checked ()) {
            config_file.use_upload_limit (0);
        } else if (this.ui.auto_upload_limit_radio_button.is_checked ()) {
            config_file.use_upload_limit (-1);
        }
        config_file.upload_limit (this.ui.upload_spin_box.value ());

        FolderMan.instance.dirty_network_limits ();
    }


    /***********************************************************
    Red marking of host field if empty and enabled
    ***********************************************************/
    private void on_signal_check_empty_proxy_host () {
        if (this.ui.host_line_edit.is_enabled () && this.ui.host_line_edit.text () == "") {
            this.ui.host_line_edit.style_sheet ("border : 1px solid red");
        } else {
            this.ui.host_line_edit.style_sheet ("");
        }
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_check_account_localhost () {
        bool visible = false;
        if (this.ui.manual_proxy_radio_button.is_checked ()) {
            // Check if at least one account is using localhost, because Qt proxy settings have no
            // effect for localhost (#7169)
            foreach (var account in AccountManager.instance.accounts) {
                const var host = account.account.url.host ();
                // Some typical url for localhost
                if (host == "localhost" || host.starts_with ("127.") || host == "[.1]") {
                    visible = true;
                }
            }
        }
        this.ui.label_localhost.visible (visible);
    }


    /***********************************************************
    ***********************************************************/
    protected override void show_event (QShowEvent event) {
        if (!event.spontaneous ()
            && this.ui.manual_proxy_radio_button.is_checked ()
            && this.ui.host_line_edit.text () == "") {
            this.ui.no_proxy_radio_button.checked (true);
            on_signal_check_empty_proxy_host ();
            on_signal_save_proxy_settings ();
        }
        on_signal_check_account_localhost ();

        Gtk.Widget.show_event (event);
    }


    /***********************************************************
    ***********************************************************/
    private void load_proxy_settings () {
        if (Theme.force_system_network_proxy) {
            this.ui.system_proxy_radio_button.checked (true);
            this.ui.proxy_group_box.enabled (false);
            return;
        }
        // load current proxy settings
        ConfigFile config_file;
        int type = config_file.proxy_type ();
        switch (type) {
        case QNetworkProxy.NoProxy:
            this.ui.no_proxy_radio_button.checked (true);
            break;
        case QNetworkProxy.DefaultProxy:
            this.ui.system_proxy_radio_button.checked (true);
            break;
        case QNetworkProxy.Socks5Proxy:
        case QNetworkProxy.HttpProxy:
            this.ui.type_combo_box.current_index (this.ui.type_combo_box.find_data (type));
            this.ui.manual_proxy_radio_button.checked (true);
            break;
        default:
            break;
        }

        this.ui.host_line_edit.on_signal_text (config_file.proxy_host_name ());
        int port = config_file.proxy_port ();
        if (port == 0)
            port = 8080;
        this.ui.port_spin_box.value (port);
        this.ui.auth_requiredcheck_box.checked (config_file.proxy_needs_auth ());
        this.ui.user_line_edit.on_signal_text (config_file.proxy_user ());
        this.ui.password_line_edit.on_signal_text (config_file.proxy_password ());
    }

} // class NetworkSettings

} // namespace Ui
} // namespace Occ
