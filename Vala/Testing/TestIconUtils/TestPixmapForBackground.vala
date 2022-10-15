namespace Occ {
namespace Testing {

/***********************************************************
@class TestPixmapForBackground

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestPixmapForBackground : AbstractTestIconUtils {

    /***********************************************************
    ***********************************************************/
    private TestPixmapForBackground () {
        //  GLib.Dir black_svg_dir = new GLib.Dir (LibSync.Theme.THEME_PREFIX + "black");
        //  GLib.List<string> black_images = black_svg_dir.entry_list ("*.svg");

        //  GLib.Dir white_svg_dir = new GLib.Dir (LibSync.Theme.THEME_PREFIX + "white");
        //  GLib.List<string> white_images = white_svg_dir.entry_list ("*.svg");

        //  GLib.assert_true (!black_images == "");

        //  GLib.assert_true (!IconUtils.pixmap_for_background (white_images.at (0), Gdk.RGBA ("blue")) == null);

        //  GLib.assert_true (!white_images == "");

        //  GLib.assert_true (!IconUtils.pixmap_for_background (black_images.at (0), Gdk.RGBA ("yellow")) == null);
    }

} // class TestPixmapForBackground

} // namespace Testing
} // namespace Occ
