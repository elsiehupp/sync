/***********************************************************
Copyright (C) by Klaas Freitag <freitag@owncloud.com>

<GPLv3-or-later-Boilerplate>
***********************************************************/

/***********************************************************
 @brief Updater that only implements notification for use in settings

 The implementation does not show popups

 @ingroup gui
***********************************************************/
class Passive_update_notifier : OCUpdater {

    /***********************************************************
    ***********************************************************/
    public Passive_update_notifier (GLib.Uri url);

    /***********************************************************
    ***********************************************************/
    public bool handle_startup () override {
        return false;
    }


    /***********************************************************
    ***********************************************************/
    public void background_check_for_update () override;


    /***********************************************************
    ***********************************************************/
    private void version_info_arrived (Update_info info) override;
    private GLib.ByteArray this.running_app_version;
}






    Passive_update_notifier.Passive_update_notifier (GLib.Uri url)
        : OCUpdater (url) {
        // remember the version of the currently running binary. On Linux it might happen that the
        // package management updates the package while the app is running. This is detected in the
        // updater slot : If the installed binary on the hd has a different version than the one
        // running, the running app is restarted. That happens in folderman.
        this.running_app_version = Utility.version_of_installed_binary ();
    }

    void Passive_update_notifier.background_check_for_update () {
        if (Utility.is_linux ()) {
            // on linux, check if the installed binary is still the same version
            // as the one that is running. If not, restart if possible.
            const GLib.ByteArray fs_version = Utility.version_of_installed_binary ();
            if (! (fs_version.is_empty () || this.running_app_version.is_empty ()) && fs_version != this.running_app_version) {
                /* emit */ request_restart ();
            }
        }

        OCUpdater.background_check_for_update ();
    }

    void Passive_update_notifier.version_info_arrived (Update_info info) {
        int64 current_ver = Helper.current_version_to_int ();
        int64 remote_ver = Helper.string_version_to_int (info.version ());

        if (info.version ().is_empty () || current_ver >= remote_ver) {
            GLib.Info (lc_updater) << "Client is on latest version!";
            set_download_state (Up_to_date);
        } else {
            set_download_state (Update_only_available_through_system);
        }
    }