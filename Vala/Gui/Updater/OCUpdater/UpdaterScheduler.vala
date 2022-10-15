/***********************************************************
@author Klaas Freitag <freitag@owncloud.com>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class UpdaterScheduler { //: GLib.Object {

    //  /***********************************************************
    //  Timer for the regular update check
    //  ***********************************************************/
    //  private uint update_check_timer_interval;

    //  internal signal void signal_updater_announcement (string title, string message);
    //  internal signal void signal_request_restart ();

    //  /***********************************************************
    //  ***********************************************************/
    //  public UpdaterScheduler (GLib.Object parent) {
        //  base (parent);

        //  var updater = (OCUpdater) AbstractUpdater.instance;
        //  // Note: the sparkle-updater is not an OCUpdater
        //  if (updater != null) {
        //      updater.signal_new_update_available.connect (
        //          this.on_signal_updater_announcement
        //      );
        //      updater.signal_request_restart.connect (
        //          this.on_signal_request_restart
        //      );
        //  }

        //  /***********************************************************
        //  At startup, do a check in any case.
        //  ***********************************************************/
        //  GLib.Timeout.add (
        //      3000,
        //      this.on_signal_timer_fired
        //  );
    //  }


    //  /***********************************************************
    //  ***********************************************************/
    //  private bool on_signal_timer_fired () {
        //  /***********************************************************
        //  Re-set the check interval if it changed in the config file
        //  meanwhile.
        //  ***********************************************************/
        //  uint check_interval = LibSync.ConfigFile.update_check_interval;
        //  if (check_interval != this.update_check_timer_interval) {
        //      this.update_check_timer_interval = check_interval;
        //      GLib.info ("Setting new update check interval " + check_interval);
        //  }
        //  GLib.Timeout.add (
        //      this.update_check_timer_interval,
        //      this.on_signal_timer_fired
        //  );

        //  /***********************************************************
        //  Consider the skip_update_check and !auto_update_check flags
        //  in the config.
        //  ***********************************************************/
        //  if (LibSync.ConfigFile.skip_update_check || !LibSync.ConfigFile.auto_update_check) {
        //      GLib.info ("Skipping update check because of config file.");
        //      return false; // only run once
        //  }

        //  AbstractUpdater updater = AbstractUpdater.instance;
        //  if (updater != null) {
        //      updater.on_signal_background_check_for_update ();
        //  }
        //  return false; // only run once
    //  }

} // class UpdaterScheduler

} // namespace Ui
} // namespace Occ
