/***********************************************************
Copyright (C) 2021 by Felix Weilbach <felix.weilbach@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QTest>

class TestTheme : GLib.Object {

public:
    TestTheme () {
        Q_INIT_RESOURCE (resources);
        Q_INIT_RESOURCE (theme);
    }

private slots:
    void testHidpiFileName_darkBackground_returnPathToWhiteIcon () {
        FakePaintDevice paintDevice;
        const QColor backgroundColor ("#000000");
        const string iconName ("icon-name");

        const auto iconPath = Occ.Theme.hidpiFileName (iconName + ".png", backgroundColor, &paintDevice);

        QCOMPARE (iconPath, ":/client/theme/white/" + iconName + ".png");
    }

    void testHidpiFileName_lightBackground_returnPathToBlackIcon () {
        FakePaintDevice paintDevice;
        const QColor backgroundColor ("#ffffff");
        const string iconName ("icon-name");

        const auto iconPath = Occ.Theme.hidpiFileName (iconName + ".png", backgroundColor, &paintDevice);

        QCOMPARE (iconPath, ":/client/theme/black/" + iconName + ".png");
    }

    void testHidpiFileName_hidpiDevice_returnHidpiIconPath () {
        FakePaintDevice paintDevice;
        paintDevice.setHidpi (true);
        const QColor backgroundColor ("#000000");
        const string iconName ("wizard-files");

        const auto iconPath = Occ.Theme.hidpiFileName (iconName + ".png", backgroundColor, &paintDevice);

        QCOMPARE (iconPath, ":/client/theme/white/" + iconName + "@2x.png");
    }

    void testIsDarkColor_nextcloudBlue_returnTrue () {
        const QColor color (0, 130, 201);

        const auto result = Occ.Theme.isDarkColor (color);

        QCOMPARE (result, true);
    }

    void testIsDarkColor_lightColor_returnFalse () {
        const QColor color (255, 255, 255);

        const auto result = Occ.Theme.isDarkColor (color);

        QCOMPARE (result, false);
    }

    void testIsDarkColor_darkColor_returnTrue () {
        const QColor color (0, 0, 0);

        const auto result = Occ.Theme.isDarkColor (color);

        QCOMPARE (result, true);
    }

    void testIsHidpi_hidpi_returnTrue () {
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
#include "testtheme.moc"
