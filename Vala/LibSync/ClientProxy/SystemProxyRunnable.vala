namespace Occ {
namespace LibSync {

/***********************************************************
@class SystemProxyRunnable

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class SystemProxyRunnable : GLib.Object /*, QRunnable*/ {

    /***********************************************************
    ***********************************************************/
    private GLib.Uri url;

    /***********************************************************
    ***********************************************************/
    internal signal void system_proxy_looked_up (Soup.ProxyResolverDefault url);

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
            /* emit */ system_proxy_looked_up (new Soup.ProxyResolverDefault (Soup.ProxyResolverDefault.NoProxy));
        } else {
            /* emit */ system_proxy_looked_up (proxies.first ());
            // FIXME Would we really ever return more?
        }
    }

} // class SystemProxyRunnable

} // namespace LibSync
} // namespace Occ
