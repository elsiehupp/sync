/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QTest>

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
    private void test_draw_svg_with_custom_fill_color () {
        const string black_svg_dir_path = Occ.Theme.THEME_PREFIX + "black";
        const GLib.Dir black_svg_dir = new GLib.Dir (black_svg_dir_path);
        const string[] black_images = black_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!black_images == "");

        GLib.assert_true (!Occ.Ui.IconUtils.draw_svg_with_custom_fill_color (black_svg_dir_path + "/" + black_images.at (0), QColorConstants.Svg.red).is_null ());

        GLib.assert_true (!Occ.Ui.IconUtils.draw_svg_with_custom_fill_color (black_svg_dir_path + "/" + black_images.at (0), QColorConstants.Svg.green).is_null ());

        const string white_svg_dir_path = Occ.Theme.THEME_PREFIX + "white";
        const GLib.Dir white_svg_dir = new GLib.Dir (white_svg_dir_path);
        const string[] white_images = white_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!white_images == "");

        GLib.assert_true (!Occ.Ui.IconUtils.draw_svg_with_custom_fill_color (white_svg_dir_path + "/" + white_images.at (0), QColorConstants.Svg.blue).is_null ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_create_svg_pixmap_with_custom_color () {
        const GLib.Dir black_svg_dir = new GLib.Dir (Occ.Theme.THEME_PREFIX + "black");
        const string[] black_images = black_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!black_images == "");

        GLib.assert_true (!Occ.Ui.IconUtils.create_svg_image_with_custom_color (black_images.at (0), QColorConstants.Svg.red).is_null ());

        GLib.assert_true (!Occ.Ui.IconUtils.create_svg_image_with_custom_color (black_images.at (0), QColorConstants.Svg.green).is_null ());

        const GLib.Dir white_svg_dir = new GLib.Dir (Occ.Theme.THEME_PREFIX + "white");
        const string[] white_images = white_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!white_images == "");

        GLib.assert_true (!Occ.Ui.IconUtils.create_svg_image_with_custom_color (white_images.at (0), QColorConstants.Svg.blue).is_null ());
    }


    /***********************************************************
    ***********************************************************/
    private void test_pixmap_for_background () {
        const GLib.Dir black_svg_dir = new GLib.Dir (Occ.Theme.THEME_PREFIX + "black");
        const string[] black_images = black_svg_dir.entry_list ("*.svg");

        const GLib.Dir white_svg_dir = new GLib.Dir (Occ.Theme.THEME_PREFIX + "white");
        const string[] white_images = white_svg_dir.entry_list ("*.svg");

        GLib.assert_true (!black_images == "");

        GLib.assert_true (!Occ.Ui.IconUtils.pixmap_for_background (white_images.at (0), Gtk.Color ("blue")).is_null ());

        GLib.assert_true (!white_images == "");

        GLib.assert_true (!Occ.Ui.IconUtils.pixmap_for_background (black_images.at (0), Gtk.Color ("yellow")).is_null ());
    }

} // class TestIconUtils
} // namespace Testing
