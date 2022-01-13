/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QUrl>
// #include <QThreadPool>

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

    static bool isUsingSystemDefault ();
    static void lookupSystemProxyAsync (QUrl &url, GLib.Object *dst, char *slot);

    static string printQNetworkProxy (QNetworkProxy &proxy);
    static const char *proxyTypeToCStr (QNetworkProxy.ProxyType type);

public slots:
    void setupQtProxyFromConfig ();
};

class SystemProxyRunnable : GLib.Object, public QRunnable {
public:
    SystemProxyRunnable (QUrl &url);
    void run () override;
signals:
    void systemProxyLookedUp (QNetworkProxy &url);

private:
    QUrl _url;
};


    ClientProxy.ClientProxy (GLib.Object *parent)
        : GLib.Object (parent) {
    }
    
    static QNetworkProxy proxyFromConfig (ConfigFile &cfg) {
        QNetworkProxy proxy;
    
        if (cfg.proxyHostName ().isEmpty ())
            return QNetworkProxy ();
    
        proxy.setHostName (cfg.proxyHostName ());
        proxy.setPort (cfg.proxyPort ());
        if (cfg.proxyNeedsAuth ()) {
            proxy.setUser (cfg.proxyUser ());
            proxy.setPassword (cfg.proxyPassword ());
        }
        return proxy;
    }
    
    bool ClientProxy.isUsingSystemDefault () {
        Occ.ConfigFile cfg;
    
        // if there is no config file, default to system proxy.
        if (cfg.exists ()) {
            return cfg.proxyType () == QNetworkProxy.DefaultProxy;
        }
    
        return true;
    }
    
    const char *ClientProxy.proxyTypeToCStr (QNetworkProxy.ProxyType type) {
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
    
    string ClientProxy.printQNetworkProxy (QNetworkProxy &proxy) {
        return string ("%1://%2:%3").arg (proxyTypeToCStr (proxy.type ())).arg (proxy.hostName ()).arg (proxy.port ());
    }
    
    void ClientProxy.setupQtProxyFromConfig () {
        Occ.ConfigFile cfg;
        int proxyType = QNetworkProxy.DefaultProxy;
        QNetworkProxy proxy;
    
        // if there is no config file, default to system proxy.
        if (cfg.exists ()) {
            proxyType = cfg.proxyType ();
            proxy = proxyFromConfig (cfg);
        }
    
        switch (proxyType) {
            case QNetworkProxy.NoProxy:
                qCInfo (lcClientProxy) << "Set proxy configuration to use NO proxy";
                QNetworkProxyFactory.setUseSystemConfiguration (false);
                QNetworkProxy.setApplicationProxy (QNetworkProxy.NoProxy);
                break;
            case QNetworkProxy.DefaultProxy:
                qCInfo (lcClientProxy) << "Set proxy configuration to use the preferred system proxy for http tcp connections"; {
                    QNetworkProxyQuery query;
                    query.setProtocolTag ("http");
                    query.setQueryType (QNetworkProxyQuery.TcpSocket);
                    auto proxies = QNetworkProxyFactory.proxyForQuery (query);
                    proxy = proxies.first ();
                }
                QNetworkProxyFactory.setUseSystemConfiguration (false);
                QNetworkProxy.setApplicationProxy (proxy);
                break;
            case QNetworkProxy.Socks5Proxy:
                proxy.setType (QNetworkProxy.Socks5Proxy);
                qCInfo (lcClientProxy) << "Set proxy configuration to SOCKS5" << printQNetworkProxy (proxy);
                QNetworkProxyFactory.setUseSystemConfiguration (false);
                QNetworkProxy.setApplicationProxy (proxy);
                break;
            case QNetworkProxy.HttpProxy:
                proxy.setType (QNetworkProxy.HttpProxy);
                qCInfo (lcClientProxy) << "Set proxy configuration to HTTP" << printQNetworkProxy (proxy);
                QNetworkProxyFactory.setUseSystemConfiguration (false);
                QNetworkProxy.setApplicationProxy (proxy);
                break;
            default:
                break;
        }
    }
    
    void ClientProxy.lookupSystemProxyAsync (QUrl &url, GLib.Object *dst, char *slot) {
        auto *runnable = new SystemProxyRunnable (url);
        GLib.Object.connect (runnable, SIGNAL (systemProxyLookedUp (QNetworkProxy)), dst, slot);
        QThreadPool.globalInstance ().start (runnable); // takes ownership and deletes
    }
    
    SystemProxyRunnable.SystemProxyRunnable (QUrl &url)
        : GLib.Object ()
        , QRunnable ()
        , _url (url) {
    }
    
    void SystemProxyRunnable.run () {
        qRegisterMetaType<QNetworkProxy> ("QNetworkProxy");
        QList<QNetworkProxy> proxies = QNetworkProxyFactory.systemProxyForQuery (QNetworkProxyQuery (_url));
    
        if (proxies.isEmpty ()) {
            emit systemProxyLookedUp (QNetworkProxy (QNetworkProxy.NoProxy));
        } else {
            emit systemProxyLookedUp (proxies.first ());
            // FIXME Would we really ever return more?
        }
    }
    }
    