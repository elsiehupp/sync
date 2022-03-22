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
        const GLib.Dir black_svg_dir = new GLib.Dir (Theme.THEME_PREFIX + "black");
        const string[] black_images = black_svg_dir.entry_list ("*.svg");

        const GLib.Dir white_svg_dir = new GLib.Dir (Theme.THEME_PREFIX + "white");
        const string[] white_images = white_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!black_images == "");

        GLib.assert_true (!IconUtils.pixmap_for_background (white_images.at (0), Gtk.Color ("blue")) == null);

        GLib.assert_true (!white_images == "");

        GLib.assert_true (!IconUtils.pixmap_for_background (black_images.at (0), Gtk.Color ("yellow")) == null);
    }

} // class TestPixmapForBackground

} // namespace Testing
} // namespace Occ
