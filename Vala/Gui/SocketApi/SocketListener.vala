/***********************************************************
@author Dominik Schmidt <dev@dominik-schmidt.de>
@author Klaas Freitag <freitag@owncloud.com>
@author Roeland Jago Douma <roeland@famdouma.nl>

@copyright GPLv3 or Later
***********************************************************/

namespace Occ {
namespace Ui {

public class SocketListener : GLib.Object {

    public GLib.OutputStream socket;

    private BloomFilter monitored_directories_bloom_filter;

    public SocketListener (GLib.OutputStream socket) {
        this.socket = socket;
    }


    /***********************************************************
    ***********************************************************/
    public void on_signal_send_message (string message, bool do_wait = false);


    /***********************************************************
    ***********************************************************/
    public void send_warning (string message, bool do_wait = false) {
        on_signal_send_message ("WARNING:" + message, do_wait);
    }


    /***********************************************************
    ***********************************************************/
    public void send_error (string message, bool do_wait = false) {
        on_signal_send_message ("ERROR:" + message, do_wait);
    }


    /***********************************************************
    ***********************************************************/
    public void send_message_if_directory_monitored (string message, uint32 system_directory_hash) {
        if (this.monitored_directories_bloom_filter.is_hash_maybe_stored (system_directory_hash))
            on_signal_send_message (message, false);
    }


    /***********************************************************
    ***********************************************************/
    public void register_monitored_directory (uint32 system_directory_hash) {
        this.monitored_directories_bloom_filter.store_hash (system_directory_hash);
    }

}

} // namespace Testing
} // namespace Occ
