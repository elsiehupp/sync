namespace Occ {
namespace Testing {

/***********************************************************
@class TestCreateSvgPixmapWithCustomColor

@author Oleksandr Zolotov <alex@nextcloud.com>

@copyright GPLv??? or later
***********************************************************/
public class TestCreateSvgPixmapWithCustomColor : AbstractTestIconUtils {

    /***********************************************************
    ***********************************************************/
    private TestCreateSvgPixmapWithCustomColor () {
        const GLib.Dir black_svg_dir = new GLib.Dir (Theme.THEME_PREFIX + "black");
        const GLib.List<string> black_images = black_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!black_images == "");

        GLib.assert_true (!IconUtils.create_svg_image_with_custom_color (black_images.at (0), QColorConstants.Svg.red) == null);

        GLib.assert_true (!IconUtils.create_svg_image_with_custom_color (black_images.at (0), QColorConstants.Svg.green) == null);

        const GLib.Dir white_svg_dir = new GLib.Dir (Theme.THEME_PREFIX + "white");
        const GLib.List<string> white_images = white_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!white_images == "");

        GLib.assert_true (!IconUtils.create_svg_image_with_custom_color (white_images.at (0), QColorConstants.Svg.blue) == null);
    }

} // class TestCreateSvgPixmapWithCustomColor

} // namespace Testing
} // namespace Occ
