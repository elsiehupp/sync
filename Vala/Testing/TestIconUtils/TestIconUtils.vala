/***********************************************************
@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/

//  #include <QTest>

namespace Occ {
namespace Testing {

public class TestIconUtils : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public TestIconUtils () {
        Q_INIT_RESOURCE (resources);
        Q_INIT_RESOURCE (theme);
    }


    /***********************************************************
    ***********************************************************/
    private TestDrawSvgWithCustomFillColor () {
        const string black_svg_dir_path = Theme.THEME_PREFIX + "black";
        const GLib.Dir black_svg_dir = new GLib.Dir (black_svg_dir_path);
        const string[] black_images = black_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!black_images == "");

        GLib.assert_true (!Ui.IconUtils.draw_svg_with_custom_fill_color (black_svg_dir_path + "/" + black_images.at (0), QColorConstants.Svg.red) == null);

        GLib.assert_true (!Ui.IconUtils.draw_svg_with_custom_fill_color (black_svg_dir_path + "/" + black_images.at (0), QColorConstants.Svg.green) == null);

        const string white_svg_dir_path = Theme.THEME_PREFIX + "white";
        const GLib.Dir white_svg_dir = new GLib.Dir (white_svg_dir_path);
        const string[] white_images = white_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!white_images == "");

        GLib.assert_true (!Ui.IconUtils.draw_svg_with_custom_fill_color (white_svg_dir_path + "/" + white_images.at (0), QColorConstants.Svg.blue) == null);
    }


    /***********************************************************
    ***********************************************************/
    private TestCreateSvgPixmapWithCustomColor () {
        const GLib.Dir black_svg_dir = new GLib.Dir (Theme.THEME_PREFIX + "black");
        const string[] black_images = black_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!black_images == "");

        GLib.assert_true (!Ui.IconUtils.create_svg_image_with_custom_color (black_images.at (0), QColorConstants.Svg.red) == null);

        GLib.assert_true (!Ui.IconUtils.create_svg_image_with_custom_color (black_images.at (0), QColorConstants.Svg.green) == null);

        const GLib.Dir white_svg_dir = new GLib.Dir (Theme.THEME_PREFIX + "white");
        const string[] white_images = white_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!white_images == "");

        GLib.assert_true (!Ui.IconUtils.create_svg_image_with_custom_color (white_images.at (0), QColorConstants.Svg.blue) == null);
    }


    /***********************************************************
    ***********************************************************/
    private TestPixmapForBackground () {
        const GLib.Dir black_svg_dir = new GLib.Dir (Theme.THEME_PREFIX + "black");
        const string[] black_images = black_svg_dir.entry_list ("*.svg");

        const GLib.Dir white_svg_dir = new GLib.Dir (Theme.THEME_PREFIX + "white");
        const string[] white_images = white_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!black_images == "");

        GLib.assert_true (!Ui.IconUtils.pixmap_for_background (white_images.at (0), Gtk.Color ("blue")) == null);

        GLib.assert_true (!white_images == "");

        GLib.assert_true (!Ui.IconUtils.pixmap_for_background (black_images.at (0), Gtk.Color ("yellow")) == null);
    }

} // class TestIconUtils
} // namespace Testing
} // namespace Occ
