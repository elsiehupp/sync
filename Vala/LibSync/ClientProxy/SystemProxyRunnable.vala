/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

//  #include <QLoggingCategory>
//  #include <QThreadPool>

//  #include <Soup.ProxyResolverDefault>
//  #include <QRunnable>

using CSync;

namespace Occ {
namespace LibSync {

public class SystemProxyRunnable : GLib.Object /*, QRunnable*/ {

    /***********************************************************
    ***********************************************************/
    private GLib.Uri url;

    /***********************************************************
    ***********************************************************/
    signal void system_proxy_looked_up (Soup.ProxyResolverDefault url);

    /***********************************************************
    ***********************************************************/
    public SystemProxyRunnable (GLib.Uri url) {
        base ();
        this.url = url;
    }


    /***********************************************************
    ***********************************************************/
    public void run () {
        q_register_meta_type<Soup.ProxyResolverDefault> ("Soup.ProxyResolverDefault");
        GLib.List<Soup.ProxyResolverDefault> proxies = QNetworkProxyFactory.system_proxy_for_query (QNetworkProxyQuery (this.url));

        if (proxies == "") {
            /* emit */ system_proxy_looked_up (Soup.ProxyResolverDefault (Soup.ProxyResolverDefault.NoProxy));
        } else {
            /* emit */ system_proxy_looked_up (proxies.first ());
            // FIXME Would we really ever return more?
        }
    }

} // class SystemProxyRunnable

} // namespace LibSync
} // namespace Occ
