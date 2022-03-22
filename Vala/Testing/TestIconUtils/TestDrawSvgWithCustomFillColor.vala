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
        const string black_svg_dir_path = Theme.THEME_PREFIX + "black";
        const GLib.Dir black_svg_dir = new GLib.Dir (black_svg_dir_path);
        const string[] black_images = black_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!black_images == "");

        GLib.assert_true (!IconUtils.draw_svg_with_custom_fill_color (black_svg_dir_path + "/" + black_images.at (0), QColorConstants.Svg.red) == null);

        GLib.assert_true (!IconUtils.draw_svg_with_custom_fill_color (black_svg_dir_path + "/" + black_images.at (0), QColorConstants.Svg.green) == null);

        const string white_svg_dir_path = Theme.THEME_PREFIX + "white";
        const GLib.Dir white_svg_dir = new GLib.Dir (white_svg_dir_path);
        const string[] white_images = white_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!white_images == "");

        GLib.assert_true (!IconUtils.draw_svg_with_custom_fill_color (white_svg_dir_path + "/" + white_images.at (0), QColorConstants.Svg.blue) == null);
    }

} // class TestDrawSvgWithCustomFillColor

} // namespace Testing
} // namespace Occ
