namespace Occ {
namespace LibSync {

/***********************************************************
@class EntityExistsJob

@brief The EntityExistsJob class

@author Klaas Freitag <freitag@owncloud.com>
@author Daniel Molkentin <danimo@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/
public class EntityExistsJob : AbstractNetworkJob {

    //  internal signal void signal_exists (GLib.InputStream reply);

    //  /***********************************************************
    //  ***********************************************************/
    //  public EntityExistsJob.for_account (Account account, string path, GLib.Object parent = new GLib.Object ()) {
    //      base (account, path, parent);
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  public new void start () {
    //      send_request ("HEAD", make_account_url (path));
    //      AbstractNetworkJob.start ();
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private bool on_signal_finished () {
    //      signal_exists (this.reply);
    //      return true;
    //  }

} // class EntityExistsJob

} // namespace LibSync
} // namespace Occ
