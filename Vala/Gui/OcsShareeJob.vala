/***********************************************************
@author Roeland Jago Douma <roeland@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.JsonDocument>

namespace Occ {
namespace Ui {

/***********************************************************
@brief The OcsShareeJob class
@ingroup gui

Fetching sharees from the OCS Sharee API
***********************************************************/
public class OcsShareeJob : OcsJob {

    //  /***********************************************************
    //  Result of the OCS request

    //  @param reply The reply
    //  ***********************************************************/
    //  internal signal void signal_sharee_job_finished (GLib.JsonDocument reply);

    //  /***********************************************************
    //  ***********************************************************/
    //  public OcsShareeJob (LibSync.Account account) {
    //      base (account);
    //      path ("ocs/v2.php/apps/files_sharing/api/v1/sharees");
    //      this.signal_job_finished.connect (
    //          this.on_signal_job_finished
    //      );
    //  }


    //  /***********************************************************
    //  Get a list of sharees

    //  @param path Path to request shares for (default all shares)
    //  ***********************************************************/
    //  public void sharees (string search, string item_type, int page = 1, int per_page = 50, bool lookup = false) {
    //      verb ("GET");

    //      add_param ("search", search);
    //      add_param ("item_type", item_type);
    //      add_param ("page", string.number (page));
    //      add_param ("per_page", string.number (per_page));
    //      add_param ("lookup", GLib.Variant (lookup).to_string ());

    //      on_signal_start ();
    //  }



    //  /***********************************************************
    //  ***********************************************************/
    //  private void on_signal_job_finished (GLib.JsonDocument reply) {
    //      signal_sharee_job_finished (reply);
    //  }

} // class OcsShareeJob

} // namespace Ui
} // namespace Occ
