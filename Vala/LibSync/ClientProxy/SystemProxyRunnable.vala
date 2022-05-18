namespace Occ {
namespace LibSync {

/***********************************************************
@class SystemProxyRunnable

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class SystemProxyRunnable : GLib.Object /*, GLib.Runnable*/ {

    /***********************************************************
    ***********************************************************/
    private GLib.Uri url;

    /***********************************************************
    ***********************************************************/
    internal signal void signal_system_proxy_looked_up (Soup.ProxyResolverDefault url);

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
        GLib.List<Soup.ProxyResolverDefault> proxies = Soup.NetworkProxyFactory.system_proxy_for_query (GLib.NetworkProxyQuery (this.url));

        if (proxies == "") {
            signal_system_proxy_looked_up (new Soup.ProxyResolverDefault (Soup.ProxyResolverDefault.NoProxy));
        } else {
            signal_system_proxy_looked_up (proxies.nth_data (0));
            // FIXME Would we really ever return more?
        }
    }

} // class SystemProxyRunnable

} // namespace LibSync
} // namespace Occ
