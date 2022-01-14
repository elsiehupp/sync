/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QUrl>
// #include <QThread_pool>

// #include <GLib.Object>
// #include <QNetworkProxy>
// #include <QRunnable>
// #include <QUrl>

// #include <csync.h>

namespace Occ {


/***********************************************************
@brief The ClientProxy class
@ingroup libsync
***********************************************************/
class ClientProxy : GLib.Object {
public:
    ClientProxy (GLib.Object *parent = nullptr);

    static bool is_using_system_default ();
    static void lookup_system_proxy_async (QUrl &url, GLib.Object *dst, char *slot);

    static string print_q_network_proxy (QNetworkProxy &proxy);
    static const char *proxy_type_to_c_str (QNetworkProxy.Proxy_type type);

public slots:
    void setup_qt_proxy_from_config ();
};

class System_proxy_runnable : GLib.Object, public QRunnable {
public:
    System_proxy_runnable (QUrl &url);
    void run () override;
signals:
    void system_proxy_looked_up (QNetworkProxy &url);

private:
    QUrl _url;
};


    ClientProxy.ClientProxy (GLib.Object *parent)
        : GLib.Object (parent) {
    }
    
    static QNetworkProxy proxy_from_config (ConfigFile &cfg) {
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
    
    const char *ClientProxy.proxy_type_to_c_str (QNetworkProxy.Proxy_type type) {
        switch (type) {
        case QNetworkProxy.NoProxy:
            return "NoProxy";
        case QNetworkProxy.DefaultProxy:
            return "DefaultProxy";
        case QNetworkProxy.Socks5Proxy:
            return "Socks5Proxy";
        case QNetworkProxy.Http_proxy:
            return "Http_proxy";
        case QNetworkProxy.Http_caching_proxy:
            return "Http_caching_proxy";
        case QNetworkProxy.Ftp_caching_proxy:
            return "Ftp_caching_proxy";
        default:
            return "NoProxy";
        }
    }
    
    string ClientProxy.print_q_network_proxy (QNetworkProxy &proxy) {
        return string ("%1://%2:%3").arg (proxy_type_to_c_str (proxy.type ())).arg (proxy.host_name ()).arg (proxy.port ());
    }
    
    void ClientProxy.setup_qt_proxy_from_config () {
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
                    QNetwork_proxy_query query;
                    query.set_protocol_tag ("http");
                    query.set_query_type (QNetwork_proxy_query.Tcp_socket);
                    auto proxies = QNetworkProxyFactory.proxy_for_query (query);
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
            case QNetworkProxy.Http_proxy:
                proxy.set_type (QNetworkProxy.Http_proxy);
                q_c_info (lc_client_proxy) << "Set proxy configuration to HTTP" << print_q_network_proxy (proxy);
                QNetworkProxyFactory.set_use_system_configuration (false);
                QNetworkProxy.set_application_proxy (proxy);
                break;
            default:
                break;
        }
    }
    
    void ClientProxy.lookup_system_proxy_async (QUrl &url, GLib.Object *dst, char *slot) {
        auto *runnable = new System_proxy_runnable (url);
        GLib.Object.connect (runnable, SIGNAL (system_proxy_looked_up (QNetworkProxy)), dst, slot);
        QThread_pool.global_instance ().start (runnable); // takes ownership and deletes
    }
    
    System_proxy_runnable.System_proxy_runnable (QUrl &url)
        : GLib.Object ()
        , QRunnable ()
        , _url (url) {
    }
    
    void System_proxy_runnable.run () {
        q_register_meta_type<QNetworkProxy> ("QNetworkProxy");
        QList<QNetworkProxy> proxies = QNetworkProxyFactory.system_proxy_for_query (QNetwork_proxy_query (_url));
    
        if (proxies.is_empty ()) {
            emit system_proxy_looked_up (QNetworkProxy (QNetworkProxy.NoProxy));
        } else {
            emit system_proxy_looked_up (proxies.first ());
            // FIXME Would we really ever return more?
        }
    }
    }
    