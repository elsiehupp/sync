namespace Occ {
namespace LibSync {

/***********************************************************
@class IconJob

@brief Job to fetch a icon

@author Camila Ayres <hello@camila.codes>

@copyright GPLv3 or Later
***********************************************************/
public class IconJob : GLib.Object {

    internal signal void signal_job_finished (string icon_data);
    internal signal void signal_error (GLib.InputStream.NetworkError error_type);


    /***********************************************************
    ***********************************************************/
    public IconJob.for_account (Account account, GLib.Uri url, GLib.Object parent = new GLib.Object ()) {
        base (parent);
        Soup.Request request = new Soup.Request (url);
        request.attribute (Soup.Request.FollowRedirectsAttribute, true);
        var reply = account.send_raw_request ("GET", url, request);
        reply.signal_finished.connect (
            this.on_signal_finished
        );
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_finished () {
        var reply = (GLib.InputStream)sender ();
        if (!reply) {
            return;
        }
        delete_later ();

        var network_error = reply.error;
        if (network_error != GLib.InputStream.NoError) {
            /* emit */ signal_error (signal_network_error);
            return;
        }

        /* emit */ signal_job_finished (reply.read_all ());
    }

} // class IconJob

} // namespace LibSync
} // namespace Occ
