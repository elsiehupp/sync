namespace Occ {
namespace Testing {

/***********************************************************
@class TestDrawSvgWithCustomFillColor

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestDrawSvgWithCustomFillColor : AbstractTestIconUtils {

    /***********************************************************
    ***********************************************************/
    private TestDrawSvgWithCustomFillColor () {
        string black_svg_dir_path = LibSync.Theme.THEME_PREFIX + "black";
        GLib.Dir black_svg_dir = new GLib.Dir (black_svg_dir_path);
        GLib.List<string> black_images = black_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!black_images == "");

        GLib.assert_true (!IconUtils.draw_svg_with_custom_fill_color (black_svg_dir_path + "/" + black_images.at (0), GLib.ColorConstants.Svg.red) == null);

        GLib.assert_true (!IconUtils.draw_svg_with_custom_fill_color (black_svg_dir_path + "/" + black_images.at (0), GLib.ColorConstants.Svg.green) == null);

        string white_svg_dir_path = LibSync.Theme.THEME_PREFIX + "white";
        GLib.Dir white_svg_dir = new GLib.Dir (white_svg_dir_path);
        GLib.List<string> white_images = white_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!white_images == "");

        GLib.assert_true (!IconUtils.draw_svg_with_custom_fill_color (white_svg_dir_path + "/" + white_images.at (0), GLib.ColorConstants.Svg.blue) == null);
    }

} // class TestDrawSvgWithCustomFillColor

} // namespace Testing
} // namespace Occ
