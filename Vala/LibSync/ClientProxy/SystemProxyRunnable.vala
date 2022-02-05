/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QThreadPool>

//  #include <QNetworkProxy>
//  #include <QRunnable>

using CSync;

namespace Occ {

class SystemProxyRunnable : GLib.Object, QRunnable {

    /***********************************************************
    ***********************************************************/
    private GLib.Uri url;

    /***********************************************************
    ***********************************************************/
    signal void system_proxy_looked_up (QNetworkProxy url);

    /***********************************************************
    ***********************************************************/
    public SystemProxyRunnable (GLib.Uri url) {
        base ();
        this.url = url;
    }


    /***********************************************************
    ***********************************************************/
    public void run () {
        q_register_meta_type<QNetworkProxy> ("QNetworkProxy");
        GLib.List<QNetworkProxy> proxies = QNetworkProxyFactory.system_proxy_for_query (QNetworkProxyQuery (this.url));

        if (proxies.is_empty ()) {
            /* emit */ system_proxy_looked_up (QNetworkProxy (QNetworkProxy.NoProxy));
        } else {
            /* emit */ system_proxy_looked_up (proxies.first ());
            // FIXME Would we really ever return more?
        }
    }
} // class SystemProxyRunnable

} // namespace Occ
