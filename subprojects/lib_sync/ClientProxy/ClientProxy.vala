namespace Occ {
namespace LibSync {

/***********************************************************
@class ClientProxy

@brief The ClientProxy class

@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class ClientProxy { //: GLib.Object {

    /***********************************************************
    ***********************************************************/
    public ClientProxy (GLib.Object parent = new GLib.Object ()) {
        //  base (parent);
    }


    /***********************************************************
    ***********************************************************/
    public static bool is_using_system_default () {
        //  ConfigFile config;

        //  // if there is no config file, default to system proxy.
        //  if (config.exists) {
        //      return config.proxy_type () == Soup.ProxyResolverDefault.DefaultProxy;
        //  }

        //  return true;
    }


    delegate void DestinationDelegate ();


    /***********************************************************
    ***********************************************************/
    public void lookup_system_proxy_async (GLib.Uri url, GLib.Object destination, DestinationDelegate destination_delegate) {
        //  SystemProxyRunnable system_proxy_runnable = new SystemProxyRunnable (url);
        //  system_proxy_runnable.signal_system_proxy_looked_up.connect (
        //      destination.destination_delegate
        //  );
        //  GLib.ThreadPool.global_instance.start (system_proxy_runnable); // takes ownership and deletes
    }


    /***********************************************************
    ***********************************************************/
    private string print_q_network_proxy (Soup.ProxyResolverDefault proxy) {
        //  return "%1://%2:%3".printf (proxy_type_to_c_str (proxy.type ())).printf (proxy.host_name ()).printf (proxy.port ());
    }


    /***********************************************************
    ***********************************************************/
    private static Soup.ProxyResolverDefault proxy_from_config (ConfigFile config) {
        //  Soup.ProxyResolverDefault proxy;

        //  if (config.proxy_host_name () == "") {
        //      return new Soup.ProxyResolverDefault ();
        //  }

        //  proxy.host_name (config.proxy_host_name ());
        //  proxy.port (config.proxy_port ());
        //  if (config.proxy_needs_auth ()) {
        //      proxy.user (config.proxy_user ());
        //      proxy.password (config.proxy_password ());
        //  }
        //  return proxy;
    }


    /***********************************************************
    ***********************************************************/
    public static string proxy_type_to_c_str (Soup.ProxyResolverDefault.ProxyType type) {
        //  switch (type) {
        //  case Soup.ProxyResolverDefault.NoProxy:
        //      return "NoProxy";
        //  case Soup.ProxyResolverDefault.DefaultProxy:
        //      return "DefaultProxy";
        //  case Soup.ProxyResolverDefault.Socks5Proxy:
        //      return "Socks5Proxy";
        //  case Soup.ProxyResolverDefault.HttpProxy:
        //      return "HttpProxy";
        //  case Soup.ProxyResolverDefault.HttpCachingProxy:
        //      return "HttpCachingProxy";
        //  case Soup.ProxyResolverDefault.FtpCachingProxy:
        //      return "FtpCachingProxy";
        //  default:
        //      return "NoProxy";
        //  }
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_setup_qt_proxy_from_config () {
        //  ConfigFile config;
        //  int proxy_type = Soup.ProxyResolverDefault.DefaultProxy;
        //  Soup.ProxyResolverDefault proxy;

        //  // if there is no config file, default to system proxy.
        //  if (config.exists) {
        //      proxy_type = config.proxy_type ();
        //      proxy = proxy_from_config (config);
        //  }

        //  switch (proxy_type) {
        //      case Soup.ProxyResolverDefault.NoProxy:
        //          GLib.info ("Set proxy configuration to use NO proxy.");
        //          Soup.NetworkProxyFactory.use_system_configuration (false);
        //          Soup.ProxyResolverDefault.application_proxy (Soup.ProxyResolverDefault.NoProxy);
        //          break;
        //      case Soup.ProxyResolverDefault.DefaultProxy:
        //          GLib.info ("Set proxy configuration to use the preferred system proxy for http tcp connections."); {
        //              GLib.NetworkProxyQuery query;
        //              query.protocol_tag ("http");
        //              query.query_type (GLib.NetworkProxyQuery.TcpSocket);
        //              var proxies = Soup.NetworkProxyFactory.proxy_for_query (query);
        //              proxy = proxies.nth_data (0);
        //          }
        //          Soup.NetworkProxyFactory.use_system_configuration (false);
        //          Soup.ProxyResolverDefault.application_proxy (proxy);
        //          break;
        //      case Soup.ProxyResolverDefault.Socks5Proxy:
        //          proxy.type (Soup.ProxyResolverDefault.Socks5Proxy);
        //          GLib.info ("Set proxy configuration to SOCKS5 " + print_q_network_proxy (proxy));
        //          Soup.NetworkProxyFactory.use_system_configuration (false);
        //          Soup.ProxyResolverDefault.application_proxy (proxy);
        //          break;
        //      case Soup.ProxyResolverDefault.HttpProxy:
        //          proxy.type (Soup.ProxyResolverDefault.HttpProxy);
        //          GLib.info ("Set proxy configuration to HTTP " + print_q_network_proxy (proxy));
        //          Soup.NetworkProxyFactory.use_system_configuration (false);
        //          Soup.ProxyResolverDefault.application_proxy (proxy);
        //          break;
        //      default:
        //          break;
        //  }
    }

} // class ClientProxy

} // namespace LibSync
} // namespace Occ
    