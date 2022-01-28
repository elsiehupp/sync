/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QTest>

class TestTheme : GLib.Object {

    public TestTheme () {
        Q_INIT_RESOURCE (resources);
        Q_INIT_RESOURCE (theme);
    }

    private void on_test_hidpi_file_name_dark_background_return_path_to_white_icon () {
        FakePaintDevice paintDevice;
        const QColor backgroundColor ("#000000");
        const string iconName ("icon-name");

        const var iconPath = Occ.Theme.hidpiFileName (iconName + ".png", backgroundColor, &paintDevice);

        QCOMPARE (iconPath, ":/client/theme/white/" + iconName + ".png");
    }

    private void on_test_hidpi_file_name_light_background_return_path_to_black_icon () {
        FakePaintDevice paintDevice;
        const QColor backgroundColor ("#ffffff");
        const string iconName ("icon-name");

        const var iconPath = Occ.Theme.hidpiFileName (iconName + ".png", backgroundColor, &paintDevice);

        QCOMPARE (iconPath, ":/client/theme/black/" + iconName + ".png");
    }

    private void on_test_hidpi_file_name_hidpi_device_return_hidpi_icon_path () {
        FakePaintDevice paintDevice;
        paintDevice.setHidpi (true);
        const QColor backgroundColor ("#000000");
        const string iconName ("wizard-files");

        const var iconPath = Occ.Theme.hidpiFileName (iconName + ".png", backgroundColor, &paintDevice);

        QCOMPARE (iconPath, ":/client/theme/white/" + iconName + "@2x.png");
    }

    private void on_test_is_dark_color_nextcloud_blue_return_true () {
        const QColor color (0, 130, 201);

        const var result = Occ.Theme.isDarkColor (color);

        QCOMPARE (result, true);
    }

    private void on_test_is_dark_color_light_color_return_false () {
        const QColor color (255, 255, 255);

        const var result = Occ.Theme.isDarkColor (color);

        QCOMPARE (result, false);
    }

    private void on_test_is_dark_color_dark_color_return_true () {
        const QColor color (0, 0, 0);

        const var result = Occ.Theme.isDarkColor (color);

        QCOMPARE (result, true);
    }

    private void on_test_is_hidpi_hidpi_return_true () {
        FakePaintDevice paintDevice;
        paintDevice.setHidpi (true);

        QCOMPARE (Occ.Theme.isHidpi (&paintDevice), true);
    }

    void testIsHidpi_lowdpi_returnFalse () {
        FakePaintDevice paintDevice;
        paintDevice.setHidpi (false);

        QCOMPARE (Occ.Theme.isHidpi (&paintDevice), false);
    }
};

QTEST_GUILESS_MAIN (TestTheme)
