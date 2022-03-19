/***********************************************************
Copyright (C) 2021 by Felix Weilbach
    <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

namespace Occ {
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
    private TestHidpiFilenameDarkBackgroundReturnPathPathToWhiteIcon () {
        FakePaintDevice paint_device;
        const Gtk.Color background_color = new Gtk.Color ("#000000");
        const string icon_name = "icon-name";

        const string icon_path = Theme.hidpi_filename (icon_name + ".png", background_color, paint_device);

        GLib.assert_true (icon_path == ":/client/theme/white/" + icon_name + ".png");
    }


    /***********************************************************
    ***********************************************************/
    private TestHidpiFilenameLightBackgroundReturnPathPathToBlackIcon () {
        FakePaintDevice paint_device;
        const Gtk.Color background_color = new Gtk.Color ("#ffffff");
        const string icon_name = "icon-name";

        var icon_path = Theme.hidpi_filename (icon_name + ".png", background_color, paint_device);

        GLib.assert_true (icon_path == ":/client/theme/black/" + icon_name + ".png");
    }


    /***********************************************************
    ***********************************************************/
    private TestHidpiFilenameHidpiDeviceReturnHidpiIconPath () {
        FakePaintDevice paint_device;
        paint_device.set_hidpi (true);
        const Gtk.Color background_color = new Gtk.Color ("#000000");
        const string icon_name = "wizard-files";

        var icon_path = Theme.hidpi_filename (icon_name + ".png", background_color, paint_device);

        GLib.assert_true (icon_path == ":/client/theme/white/" + icon_name + "@2x.png");
    }


    /***********************************************************
    ***********************************************************/
    private TestIsDarkColorNectcloudBlueReturnTrue () {
        const Gtk.Color color = new Gtk.Color (0, 130, 201);

        var result = Theme.is_dark_color (color);

        GLib.assert_true (result == true);
    }


    /***********************************************************
    ***********************************************************/
    private TestIsDarkColorLightColorReturnFalse () {
        const Gtk.Color color = new Gtk.Color (255, 255, 255);

        var result = Theme.is_dark_color (color);

        GLib.assert_true (result == false);
    }


    /***********************************************************
    ***********************************************************/
    private TestIsDarkColorDarkColorReturnTrue () {
        const Gtk.Color color = new Gtk.Color (0, 0, 0);

        var result = Theme.is_dark_color (color);

        GLib.assert_true (result == true);
    }


    /***********************************************************
    ***********************************************************/
    private TestIsHidpiHidpiReturnTrue () {
        FakePaintDevice paint_device;
        paint_device.set_hidpi (true);

        GLib.assert_true (Theme.is_hidpi (paint_device) == true);
    }


    /***********************************************************
    ***********************************************************/
    private TestIsHidpiLowpiReturnFalse () {
        FakePaintDevice paint_device;
        paint_device.set_hidpi (false);

        GLib.assert_true (Theme.is_hidpi (paint_device) == false);
    }

} // class TestTheme

} // namespace Testing
} // namespace Occ
