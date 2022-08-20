/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv3 or Later
***********************************************************/

//  #include <GLib.QuickImageProvider>

namespace Occ {
namespace Ui {

public class SvgImageProvider { //: GLib.QuickImageProvider {

//    /***********************************************************
//    ***********************************************************/
//    public SvgImageProvider () {
//        base (GLib.QuickImageProvider.Image);
//    }


//    /***********************************************************
//    ***********************************************************/
//    public Gtk.Image request_image (string identifier, Gdk.Rectangle size, Gdk.Rectangle requested_size) {
//        //  GLib.assert_true (!identifier == "");

//        var id_split = identifier.split ("/", GLib.SkipEmptyParts);

//        if (id_split == "") {
//            GLib.warning ("Image identifier is incorrect!");
//            return {};
//        }

//        var pixmap_name = id_split.at (0);
//        var pixmap_color = id_split.size () > 1 ? Gdk.RGBA (id_split.at (1)) { //: GLib.Color_constants.Svg.black;

//        if (pixmap_name == "" || !pixmap_color.is_valid) {
//            GLib.warning ("Image identifier is incorrect!");
//            return {};
//        }

//        return IconUtils.create_svg_image_with_custom_color (pixmap_name, pixmap_color, size, requested_size);
//    }

} // class SvgImageProvider

} // namespace Ui
} // namespace Occ
