/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QThreadPool>
//  #include
//  #include <QNetworkProxy>
//  #include <QRunnable>

using CSync;

namespace Occ {

/***********************************************************
@brief The ClientProxy class
@ingroup libsync
***********************************************************/
class ClientProxy : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public ClientProxy (GLib.Object parent = new GLib.Object ()) {
        base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public static bool is_using_system_default () {
        Occ.ConfigFile config;

        // if there is no config file, default to system proxy.
        if (config.exists ()) {
            return config.proxy_type () == QNetworkProxy.DefaultProxy;
        }

        return true;
    }


    /***********************************************************
    ***********************************************************/
    public void lookup_system_proxy_async (GLib.Uri url, GLib.Object dst, char slot) {
        var runnable = new SystemProxyRunnable (url);
        GLib.Object.connect (runnable, SIGNAL (system_proxy_looked_up (QNetworkProxy)), dst, slot);
        QThreadPool.global_instance ().on_start (runnable); // takes ownership and deletes
    }


    /***********************************************************
    ***********************************************************/
    private string print_q_network_proxy (QNetworkProxy proxy) {
        return string ("%1://%2:%3").arg (proxy_type_to_c_str (proxy.type ())).arg (proxy.host_name ()).arg (proxy.port ());
    }


    /***********************************************************
    ***********************************************************/
    private static QNetworkProxy proxy_from_config (ConfigFile config) {
        QNetworkProxy proxy;

        if (config.proxy_host_name ().is_empty ())
            return QNetworkProxy ();

        proxy.set_host_name (config.proxy_host_name ());
        proxy.set_port (config.proxy_port ());
        if (config.proxy_needs_auth ()) {
            proxy.set_user (config.proxy_user ());
            proxy.set_password (config.proxy_password ());
        }
        return proxy;
    }


    /***********************************************************
    ***********************************************************/
    public static const char proxy_type_to_c_str (QNetworkProxy.ProxyType type) {
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


    /***********************************************************
    ***********************************************************/
    public void on_setup_qt_proxy_from_config () {
        Occ.ConfigFile config;
        int proxy_type = QNetworkProxy.DefaultProxy;
        QNetworkProxy proxy;

        // if there is no config file, default to system proxy.
        if (config.exists ()) {
            proxy_type = config.proxy_type ();
            proxy = proxy_from_config (config);
        }

        switch (proxy_type) {
            case QNetworkProxy.NoProxy:
                GLib.Info (lc_client_proxy) << "Set proxy configuration to use NO proxy";
                QNetworkProxyFactory.set_use_system_configuration (false);
                QNetworkProxy.set_application_proxy (QNetworkProxy.NoProxy);
                break;
            case QNetworkProxy.DefaultProxy:
                GLib.Info (lc_client_proxy) << "Set proxy configuration to use the preferred system proxy for http tcp connections"; {
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
                GLib.Info (lc_client_proxy) << "Set proxy configuration to SOCKS5" << print_q_network_proxy (proxy);
                QNetworkProxyFactory.set_use_system_configuration (false);
                QNetworkProxy.set_application_proxy (proxy);
                break;
            case QNetworkProxy.HttpProxy:
                proxy.set_type (QNetworkProxy.HttpProxy);
                GLib.Info (lc_client_proxy) << "Set proxy configuration to HTTP" << print_q_network_proxy (proxy);
                QNetworkProxyFactory.set_use_system_configuration (false);
                QNetworkProxy.set_application_proxy (proxy);
                break;
            default:
                break;
        }
    }
} // class ClientProxy

} // namespace Occ
    