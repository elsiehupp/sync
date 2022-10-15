
namespace Occ {
namespace Ui {

public class ImageProvider { //: GLib.QuickImageProvider {

    /***********************************************************
    ***********************************************************/
    public ImageProvider () {
        //  base (GLib.QuickImageProvider.Image);
    }


    /***********************************************************
    ***********************************************************/
    public Gtk.Image request_image (string identifier, Gdk.Rectangle size, Gdk.Rectangle requested_size) {
        //  //  Q_UNUSED (size)
        //  //  Q_UNUSED (requested_size)

        //  if (identifier == "fallback_white") {
        //      return make_icon (":/client/theme/white/user.svg");
        //  }

        //  if (identifier == "fallback_black") {
        //      return make_icon (":/client/theme/black/user.svg");
        //  }

        //  int uid = identifier.to_int ();
        //  return UserModel.instance.avatar_by_identifier (uid);
    }


    /***********************************************************
    ***********************************************************/
    private static Gtk.Image make_icon (string path) {
        //  Gtk.Image image = new Gtk.Image (128, 128, Gtk.Image.FormatARGB32);
        //  image.fill (GLib.GlobalColor.transparent);
        //  GLib.Painter painter = new GLib.Painter (image);
        //  GLib.SvgRenderer renderer = new GLib.SvgRenderer (path);
        //  renderer.render (painter);
        //  return image;
    }

} // class ImageProvider

} // namespace Ui
} // namespace Occ
