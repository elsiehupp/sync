/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <Gtk.Image>
//  #include <GLib.Painter>
//  #include <GLib.SvgRenderer>
//  #include <QtCore>
//  #include <GLib.QuickImageProvider>

namespace Occ {
namespace Ui {

public class AsyncImageResponse : GLib.QuickImageResponse {

    Gtk.Image image;
    GLib.List<string> image_paths;
    Gdk.Rectangle requested_image_size;
    int index = 0;

    public AsyncImageResponse (string identifier, Gdk.Rectangle requested_size) {
        if (identifier == "") {
            image_and_emit_finished ();
            return;
        }

        this.image_paths = identifier.split (';', GLib.SkipEmptyParts);
        this.requested_image_size = requested_size;

        if (this.image_paths == "") {
            image_and_emit_finished ();
        } else {
            process_next_image ();
        }
    }


    /***********************************************************
    ***********************************************************/
    public void image_and_emit_finished (Gtk.Image image = {}) {
        this.image = image;
        /* emit */ signal_finished ();
    }


    /***********************************************************
    ***********************************************************/
    public override GLib.QuickTextureFactory texture_factory () {
        return GLib.QuickTextureFactory.texture_factory_for_image (this.image);
    }


    /***********************************************************
    ***********************************************************/
    private void process_next_image () {
        if (this.index < 0 || this.index >= this.image_paths.size ()) {
            image_and_emit_finished ();
            return;
        }

        if (this.image_paths.at (this.index).has_prefix (":/client")) {
            image_and_emit_finished (Gtk.Icon (this.image_paths.at (this.index)).pixmap (this.requested_image_size).to_image ());
            return;
        }

        var current_user = UserModel.instance.is_current_user ();
        if (current_user && current_user.account) {
            GLib.Uri icon_url = new GLib.Uri (this.image_paths.at (this.index));
            if (icon_url.is_valid && !icon_url.scheme () == "") {
                // fetch the remote resource
                var reply = current_user.account.send_raw_request ("GET", icon_url);
                reply.signal_finished.connect (
                    this.on_signal_process_network_reply
                );
                ++this.index;
                return;
            }
        }

        image_and_emit_finished ();
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_process_network_input_stream {
        var reply = (GLib.InputStream)sender ();
        if (!reply) {
            image_and_emit_finished ();
            return;
        }

        string image_data = reply.read_all ();
        // server returns "[]" for some some file previews (have no idea why), so, we use another image
        // from the list if available
        if (image_data == "" || image_data == "[]") {
            process_next_image ();
        } else {
            if (image_data.has_prefix ("<svg")) {
                // SVG image needs proper scaling, let's do it with GLib.Painter and GLib.SvgRenderer
                GLib.SvgRenderer svg_renderer;
                if (svg_renderer.on_signal_load (image_data)) {
                    Gtk.Image scaled_svg = new Gtk.Image (this.requested_image_size, Gtk.Image.FormatARGB32);
                    scaled_svg.fill ("transparent");
                    GLib.Painter painter_for_svg = new GLib.Painter (scaled_svg);
                    svg_renderer.render (painter_for_svg);
                    image_and_emit_finished (scaled_svg);
                    return;
                } else {
                    process_next_image ();
                }
            } else {
                image_and_emit_finished (Gtk.Image.from_data (image_data));
            }
        }
    }

} // class AsyncImageResponse

} // namespace Ui
} // namespace Occ
    