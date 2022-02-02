/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <GLib.Uri>
// #include <QThreadPool>

// #include <QNetworkProxy>
// #include <QRunnable>
// #include <GLib.Uri>

using CSync;

namespace Occ {


/***********************************************************
@brief The ClientProxy class
@ingroup libsync
***********************************************************/
class ClientProxy : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public ClientProxy (GLib.Object parent = new GLib.Object ());

    /***********************************************************
    ***********************************************************/
    public static bool is_using_system_default ();

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public 

    /***********************************************************
    ***********************************************************/
    public static const char proxy_type_to_c_str (QNetworkProxy.ProxyType type);


    public void on_setup_qt_proxy_from_config ();
};

class SystemProxyRunnable : GLib.Object, public QRunnable {

    /***********************************************************
    ***********************************************************/
    public SystemProxyRunnable (GLib.Uri url);

    /***********************************************************
    ***********************************************************/
    public 
    public void run () override;
signals:
    void system_proxy_looked_up (QNetworkProxy url);


    /***********************************************************
    ***********************************************************/
    private GLib.Uri this.url;
};


    ClientProxy.ClientProxy (GLib.Object parent) {
        base (parent);
    }

    /***********************************************************
    ***********************************************************/
    static QNetworkProxy proxy_from_config (ConfigFile cfg) {
        QNetworkProxy proxy;

        if (cfg.proxy_host_name ().is_empty ())
            return QNetworkProxy ();

        proxy.set_host_name (cfg.proxy_host_name ());
        proxy.set_port (cfg.proxy_port ());
        if (cfg.proxy_needs_auth ()) {
            proxy.set_user (cfg.proxy_user ());
            proxy.set_password (cfg.proxy_password ());
        }
        return proxy;
    }

    bool ClientProxy.is_using_system_default () {
        Occ.ConfigFile cfg;

        // if there is no config file, default to system proxy.
        if (cfg.exists ()) {
            return cfg.proxy_type () == QNetworkProxy.DefaultProxy;
        }

        return true;
    }

    const char *ClientProxy.proxy_type_to_c_str (QNetworkProxy.ProxyType type) {
        switch (type) {
        case QNetworkProxy.NoProxy:
            return "NoProxy";
        case QNetworkProxy.DefaultProxy:
            return "DefaultProxy";
        case QNetworkProxy.Socks5Proxy:
            return "Socks5Proxy";
        case QNetworkProxy.HttpProxy:
            return "HttpProxy";
        case QNetworkProxy.HttpCachingProxy:
            return "HttpCachingProxy";
        case QNetworkProxy.FtpCachingProxy:
            return "FtpCachingProxy";
        default:
            return "NoProxy";
        }
    }

    string ClientProxy.print_q_network_proxy (QNetworkProxy proxy) {
        return string ("%1://%2:%3").arg (proxy_type_to_c_str (proxy.type ())).arg (proxy.host_name ()).arg (proxy.port ());
    }

    void ClientProxy.on_setup_qt_proxy_from_config () {
        Occ.ConfigFile cfg;
        int proxy_type = QNetworkProxy.DefaultProxy;
        QNetworkProxy proxy;

        // if there is no config file, default to system proxy.
        if (cfg.exists ()) {
            proxy_type = cfg.proxy_type ();
            proxy = proxy_from_config (cfg);
        }

        switch (proxy_type) {
            case QNetworkProxy.NoProxy:
                q_c_info (lc_client_proxy) << "Set proxy configuration to use NO proxy";
                QNetworkProxyFactory.set_use_system_configuration (false);
                QNetworkProxy.set_application_proxy (QNetworkProxy.NoProxy);
                break;
            case QNetworkProxy.DefaultProxy:
                q_c_info (lc_client_proxy) << "Set proxy configuration to use the preferred system proxy for http tcp connections"; {
                    QNetworkProxyQuery query;
                    query.set_protocol_tag ("http");
                    query.set_query_type (QNetworkProxyQuery.TcpSocket);
                    var proxies = QNetworkProxyFactory.proxy_for_query (query);
                    proxy = proxies.first ();
                }
                QNetworkProxyFactory.set_use_system_configuration (false);
                QNetworkProxy.set_application_proxy (proxy);
                break;
            case QNetworkProxy.Socks5Proxy:
                proxy.set_type (QNetworkProxy.Socks5Proxy);
                q_c_info (lc_client_proxy) << "Set proxy configuration to SOCKS5" << print_q_network_proxy (proxy);
                QNetworkProxyFactory.set_use_system_configuration (false);
                QNetworkProxy.set_application_proxy (proxy);
                break;
            case QNetworkProxy.HttpProxy:
                proxy.set_type (QNetworkProxy.HttpProxy);
                q_c_info (lc_client_proxy) << "Set proxy configuration to HTTP" << print_q_network_proxy (proxy);
                QNetworkProxyFactory.set_use_system_configuration (false);
                QNetworkProxy.set_application_proxy (proxy);
                break;
            default:
                break;
        }
    }

    void ClientProxy.lookup_system_proxy_async (GLib.Uri url, GLib.Object dst, char slot) {
        var runnable = new SystemProxyRunnable (url);
        GLib.Object.connect (runnable, SIGNAL (system_proxy_looked_up (QNetworkProxy)), dst, slot);
        QThreadPool.global_instance ().on_start (runnable); // takes ownership and deletes
    }

    SystemProxyRunnable.SystemProxyRunnable (GLib.Uri url)
        : GLib.Object ()
        , QRunnable ()
        , this.url (url) {
    }

    void SystemProxyRunnable.run () {
        q_register_meta_type<QNetworkProxy> ("QNetworkProxy");
        GLib.List<QNetworkProxy> proxies = QNetworkProxyFactory.system_proxy_for_query (QNetworkProxyQuery (this.url));

        if (proxies.is_empty ()) {
            /* emit */ system_proxy_looked_up (QNetworkProxy (QNetworkProxy.NoProxy));
        } else {
            /* emit */ system_proxy_looked_up (proxies.first ());
            // FIXME Would we really ever return more?
        }
    }
    }
    