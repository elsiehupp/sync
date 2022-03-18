/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QTest>

namespace Testing {

public class TestTheme : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public TestTheme () {
        Q_INIT_RESOURCE (resources);
        Q_INIT_RESOURCE (theme);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_hidpi_filename_dark_background_return_path_to_white_icon () {
        FakePaintDevice paint_device;
        const Gtk.Color background_color = new Gtk.Color ("#000000");
        const string icon_name = "icon-name";

        const string icon_path = Theme.hidpi_filename (icon_name + ".png", background_color, paint_device);

        GLib.assert_true (icon_path == ":/client/theme/white/" + icon_name + ".png");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_hidpi_filename_light_background_return_path_to_black_icon () {
        FakePaintDevice paint_device;
        const Gtk.Color background_color = new Gtk.Color ("#ffffff");
        const string icon_name = "icon-name";

        var icon_path = Theme.hidpi_filename (icon_name + ".png", background_color, paint_device);

        GLib.assert_true (icon_path == ":/client/theme/black/" + icon_name + ".png");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_hidpi_filename_hidpi_device_return_hidpi_icon_path () {
        FakePaintDevice paint_device;
        paint_device.set_hidpi (true);
        const Gtk.Color background_color = new Gtk.Color ("#000000");
        const string icon_name = "wizard-files";

        var icon_path = Theme.hidpi_filename (icon_name + ".png", background_color, paint_device);

        GLib.assert_true (icon_path == ":/client/theme/white/" + icon_name + "@2x.png");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_is_dark_color_nextcloud_blue_return_true () {
        const Gtk.Color color = new Gtk.Color (0, 130, 201);

        var result = Theme.is_dark_color (color);

        GLib.assert_true (result == true);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_is_dark_color_light_color_return_false () {
        const Gtk.Color color = new Gtk.Color (255, 255, 255);

        var result = Theme.is_dark_color (color);

        GLib.assert_true (result == false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_is_dark_color_dark_color_return_true () {
        const Gtk.Color color = new Gtk.Color (0, 0, 0);

        var result = Theme.is_dark_color (color);

        GLib.assert_true (result == true);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_is_hidpi_hidpi_return_true () {
        FakePaintDevice paint_device;
        paint_device.set_hidpi (true);

        GLib.assert_true (Theme.is_hidpi (paint_device) == true);
    }

    void test_is_hidpi_lowdpi_return_false () {
        FakePaintDevice paint_device;
        paint_device.set_hidpi (false);

        GLib.assert_true (Theme.is_hidpi (paint_device) == false);
    }
}
}
