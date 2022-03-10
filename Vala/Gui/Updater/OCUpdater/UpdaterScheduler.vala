/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

namespace Occ {
namespace Ui {

class UpdaterScheduler : GLib.Object {

    /***********************************************************
    Timer for the regular update check
    ***********************************************************/
    private QTimer update_check_timer;

    signal void signal_updater_announcement (string title, string message);
    signal void signal_request_restart ();

    /***********************************************************
    ***********************************************************/
    public UpdaterScheduler (GLib.Object parent) {
        base (parent);
        connect (
            this.update_check_timer,
            QTimer.timeout,
            this,
            UpdaterScheduler.on_signal_timer_fired
        );

        // Note: the sparkle-updater is not an OCUpdater
        if (var updater = qobject_cast<OCUpdater> (Updater.instance ())) {
            connect (
                updater,
                OCUpdater.signal_new_update_available,
                this,
                UpdaterScheduler.signal_updater_announcement
            );
            connect (
                updater,
                OCUpdater.signal_request_restart,
                this,
                UpdaterScheduler.signal_request_restart
            );
        }

        // at startup, do a check in any case.
        QTimer.single_shot (3000, this, &UpdaterScheduler.on_signal_timer_fired);

        ConfigFile config;
        var check_interval = config.update_check_interval ();
        this.update_check_timer.on_signal_start (std.chrono.milliseconds (check_interval).count ());
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_timer_fired () {
        ConfigFile config;

        // re-set the check interval if it changed in the config file meanwhile
        var check_interval = std.chrono.milliseconds (config.update_check_interval ()).count ();
        if (check_interval != this.update_check_timer.interval ()) {
            this.update_check_timer.interval (check_interval);
            GLib.info ("Setting new update check interval " + check_interval;
        }

        // consider the skip_update_check and !auto_update_check flags in the config.
        if (config.skip_update_check () || !config.auto_update_check ()) {
            GLib.info ("Skipping update check because of config file";
            return;
        }

        Updater updater = Updater.instance ();
        if (updater) {
            updater.on_signal_background_check_for_update ();
        }
    }

} // class UpdaterScheduler

} // namespace Ui
} // namespace Occ
