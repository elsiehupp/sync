/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

// #include <QLoggingCategory>
// #include <QThreadPool>

// #include <QNetworkProxy>
// #include <QRunnable>

using CSync;

namespace Occ {

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