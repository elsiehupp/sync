/***********************************************************
Copyright (C) by Oleksandr Zolotov <alex@nextcloud.com>

<GPLv???-or-later-Boilerplate>
***********************************************************/

// #include <QTest>

class TestIconUtils : GLib.Object {

    /***********************************************************
    ***********************************************************/
    public TestIconUtils () {
        Q_INIT_RESOURCE (resources);
        Q_INIT_RESOURCE (theme);
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testDrawSvgWithCustomFillColor () {
        const string blackSvgDirPath{string{Occ.Theme.themePrefix} + QStringLiteral ("black")};
        const QDir blackSvgDir (blackSvgDirPath);
        const string[] blackImages = blackSvgDir.entryList (string[] ("*.svg"));

        Q_ASSERT (!blackImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (blackSvgDirPath + QStringLiteral ("/") + blackImages.at (0), QColorConstants.Svg.red).isNull ());

        QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (blackSvgDirPath + QStringLiteral ("/") + blackImages.at (0), QColorConstants.Svg.green).isNull ());

        const string whiteSvgDirPath{string{Occ.Theme.themePrefix} + QStringLiteral ("white")};
        const QDir whiteSvgDir (whiteSvgDirPath);
        const string[] whiteImages = whiteSvgDir.entryList (string[] ("*.svg"));

        Q_ASSERT (!whiteImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.drawSvgWithCustomFillColor (whiteSvgDirPath + QStringLiteral ("/") + whiteImages.at (0), QColorConstants.Svg.blue).isNull ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testCreateSvgPixmapWithCustomColor () {
        const QDir blackSvgDir (string (string{Occ.Theme.themePrefix}) + QStringLiteral ("black"));
        const string[] blackImages = blackSvgDir.entryList (string[] ("*.svg"));

        QVERIFY (!blackImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (blackImages.at (0), QColorConstants.Svg.red).isNull ());

        QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (blackImages.at (0), QColorConstants.Svg.green).isNull ());

        const QDir whiteSvgDir (string (string{Occ.Theme.themePrefix}) + QStringLiteral ("white"));
        const string[] whiteImages = whiteSvgDir.entryList (string[] ("*.svg"));

        QVERIFY (!whiteImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.createSvgImageWithCustomColor (whiteImages.at (0), QColorConstants.Svg.blue).isNull ());
    }


    /***********************************************************
    ***********************************************************/
    private on_ void testPixmapForBackground () {
        const QDir blackSvgDir (string (string{Occ.Theme.themePrefix}) + QStringLiteral ("black"));
        const string[] blackImages = blackSvgDir.entryList (string[] ("*.svg"));

        const QDir whiteSvgDir (string (string{Occ.Theme.themePrefix}) + QStringLiteral ("white"));
        const string[] whiteImages = whiteSvgDir.entryList (string[] ("*.svg"));

        QVERIFY (!blackImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.pixmapForBackground (whiteImages.at (0), Gtk.Color ("blue")).isNull ());

        QVERIFY (!whiteImages.isEmpty ());

        QVERIFY (!Occ.Ui.IconUtils.pixmapForBackground (blackImages.at (0), Gtk.Color ("yellow")).isNull ());
    }
};

QTEST_MAIN (TestIconUtils)
#include "testiconutils.moc"
