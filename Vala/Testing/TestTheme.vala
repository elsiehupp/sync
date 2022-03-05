/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

//  #include <QTest>

namespace Testing {

class TestTheme : GLib.Object {

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

        const string icon_path = Occ.Theme.hidpiFileName (icon_name + ".png", background_color, paint_device);

        //  QCOMPARE (icon_path, ":/client/theme/white/" + icon_name + ".png");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_hidpi_filename_light_background_return_path_to_black_icon () {
        FakePaintDevice paint_device;
        const Gtk.Color background_color = new Gtk.Color ("#ffffff");
        const string icon_name = "icon-name";

        const var icon_path = Occ.Theme.hidpiFileName (icon_name + ".png", background_color, paint_device);

        //  QCOMPARE (icon_path, ":/client/theme/black/" + icon_name + ".png");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_hidpi_filename_hidpi_device_return_hidpi_icon_path () {
        FakePaintDevice paint_device;
        paint_device.set_hidpi (true);
        const Gtk.Color background_color = new Gtk.Color ("#000000");
        const string icon_name = "wizard-files";

        const var icon_path = Occ.Theme.hidpiFileName (icon_name + ".png", background_color, paint_device);

        //  QCOMPARE (icon_path, ":/client/theme/white/" + icon_name + "@2x.png");
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_is_dark_color_nextcloud_blue_return_true () {
        const Gtk.Color color = new Gtk.Color (0, 130, 201);

        const var result = Occ.Theme.isDarkColor (color);

        //  QCOMPARE (result, true);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_is_dark_color_light_color_return_false () {
        const Gtk.Color color = new Gtk.Color (255, 255, 255);

        const var result = Occ.Theme.isDarkColor (color);

        //  QCOMPARE (result, false);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_is_dark_color_dark_color_return_true () {
        const Gtk.Color color = new Gtk.Color (0, 0, 0);

        const var result = Occ.Theme.isDarkColor (color);

        //  QCOMPARE (result, true);
    }


    /***********************************************************
    ***********************************************************/
    private void on_signal_test_is_hidpi_hidpi_return_true () {
        FakePaintDevice paint_device;
        paint_device.set_hidpi (true);

        //  QCOMPARE (Occ.Theme.isHidpi (&paint_device), true);
    }

    void testIsHidpi_lowdpi_returnFalse () {
        FakePaintDevice paint_device;
        paint_device.set_hidpi (false);

        //  QCOMPARE (Occ.Theme.isHidpi (&paint_device), false);
    }
}
}
