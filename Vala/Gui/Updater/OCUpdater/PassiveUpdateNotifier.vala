/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

/***********************************************************
@brief AbstractUpdater that only implements notification for use in settings

The implementation does not show popups

@ingroup gui
***********************************************************/
public class PassiveUpdateNotifier : OCUpdater {

//    private string running_app_version;

//    /***********************************************************
//    ***********************************************************/
//    public PassiveUpdateNotifier (GLib.Uri url) {
//        base (url);
//        // remember the version of the currently running binary. On Linux it might happen that the
//        // package management updates the package while the app is running. This is detected in the
//        // updater slot : If the installed binary on the hd has a different version than the one
//        // running, the running app is restarted. That happens in folderman.
//        this.running_app_version = Utility.version_of_installed_binary ();
//    }

//    /***********************************************************
//    ***********************************************************/
//    public override bool handle_startup () {
//        return false;
//    }


//    /***********************************************************
//    ***********************************************************/
//    public override void on_signal_background_check_for_update () {
//        if (Utility.is_linux ()) {
//            // on linux, check if the installed binary is still the same version
//            // as the one that is running. If not, restart if possible.
//            string fs_version = Utility.version_of_installed_binary ();
//            if (! (fs_version == "" || this.running_app_version == "") && fs_version != this.running_app_version) {
//                signal_request_restart ();
//            }
//        }

//        OCUpdater.on_signal_background_check_for_update ();
//    }


//    /***********************************************************
//    ***********************************************************/
//    private override void version_info_arrived (UpdateInfo info) {
//        int64 current_ver = Helper.current_version_to_int ();
//        int64 remote_ver = Helper.string_version_to_int (info.version);

//        if (info.version == "" || current_ver >= remote_ver) {
//            GLib.info ("Client is on latest version!");
//            download_state (DownloadState.UP_TO_DATE);
//        } else {
//            download_state (DownloadState.UIPLOAD_ONLY_AVAILABLE_THROUGH_SYSTEM);
//        }
//    }

} // class PassiveUpdateNotifier

} // namespace Ui
} // namespace Occ
