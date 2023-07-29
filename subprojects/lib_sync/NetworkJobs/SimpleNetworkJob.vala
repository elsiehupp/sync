namespace Occ {
namespace LibSync {

/***********************************************************
@class SimpleNetworkJob

@brief A basic job around a network request without extra
funtionality

Primarily adds timeout and redirection handling.

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class SimpleNetworkJob : AbstractNetworkJob {

    internal signal void signal_finished (GLib.InputStream reply);


    /***********************************************************
    ***********************************************************/
    public SimpleNetworkJob.for_account (Account account) {
        //  base (account, "");
    }


    /***********************************************************
    ***********************************************************/
    public GLib.InputStream start_request (
        //  string verb,
        //  GLib.Uri url,
        //  Soup.Request request,
        //  GLib.OutputStream request_body
    ) {
        //  var reply = send_request (verb, url, request, request_body);
        //  start ();
        //  return reply;
    }



    /***********************************************************
    ***********************************************************/
    private bool on_signal_finished () {
        //  signal_finished (this.reply);
        //  return true;
    }

} // class SimpleNetworkJob

} // namespace LibSync
} // namespace Occ
